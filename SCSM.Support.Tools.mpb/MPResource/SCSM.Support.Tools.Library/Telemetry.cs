using Microsoft.EnterpriseManagement.UI.Extensions.Shared;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Xml;

namespace SCSM.Support.Tools.Library
{
    /// <summary>
    /// this class is Singleton & with async initialization, that prevents blocking of caller UI thread. 
    /// Because even UI calls "static async SendAsync" method (which would normally not block the UI), BUT before entering that method, 
    /// first static fields (e.g. the "instance") are initialized and static ctor will be run BUT in caller's thread (= UI) and will block the UI.
    /// Therefore async/await pattern also used in the "static" places. Using Task<Telemetry> as return type is your friend!
    /// </summary>
    public class Telemetry
    {
        /// <summary>
        /// static ctor. runs only once when a static member is refd. use this for setting common telemetry,but independent from Modules
        /// </summary>
        static Telemetry()
        {
            instance = InitializeField_instance_Async();
        }

        /// <summary>
        ///  instance ctor. runs only once when an instance member is refd. use for what?
        /// </summary>
        private Telemetry()
        {

        }

        /// <summary>
        /// could be here initialized as  =InitializeField_instance_Async();  but I prefer it to be done in static ctor.
        /// </summary>
        private static readonly Task<Telemetry> instance;

        /// <summary>
        /// here we use the chance to do the "initialization" stuff
        /// </summary>
        /// <returns></returns>
        private static async Task<Telemetry> InitializeField_instance_Async()
        {
            var instance = new Telemetry();
            await instance.InitializeCommonTelemetryInfo();
            return instance;
        }

        /// <summary>
        /// Members should not be static and should be accessed over this static Instance, e.g. XmlTelemetry.
        /// </summary>
        public static Task<Telemetry> InstanceAsync { get { return instance; } }

        /// <summary>
        /// runs only once. use this for common telemetry, but independent from Modules. This is the part where static initialization goes to a separate thread!
        /// </summary>
        /// <returns></returns>
        private async Task InitializeCommonTelemetryInfo()
        {
            await Task.Run(() =>
            {
                XmlTelemetry = new XmlDocument();
                XmlTelemetry.AppendChild(XmlTelemetry.CreateNode(XmlNodeType.Element, "SmstTelemetry", null)); //creates the root element
                var rootNode = XmlTelemetry.DocumentElement;

                #region Library=root node               
                rootNode.SetAttribute("LibraryVersion", Helpers.GetLibraryVersion());
                rootNode.SetAttribute("SessionId", Guid.NewGuid().ToString());
                rootNode.SetAttribute("SequenceId", "0");
                //note that the below are actually from Main module, but we want them always in Telemetry, therefore set here.
                rootNode.SetAttribute("FirstImportedAt", SMST.FirstImportedAt.ToStringWithTz());
                rootNode.SetAttribute("LastImportedAt", SMST.LastImportedAt.ToStringWithTz());
                rootNode.SetAttribute("EulaAcceptedAt", EulaStatus.EulaAccepted ? EulaStatus.EulaAcceptedAt.Value.ToStringWithTz() : "");
                #endregion
                #region SM node
                var smNode = rootNode.AppendChild(XmlTelemetry.CreateNode(XmlNodeType.Element, "SM", null)) as XmlElement;
                smNode.SetAttribute("SDKVersion", SM.Emg.Version.ToString());
                smNode.SetAttribute("ConsoleVersion", Application.ProductVersion);
                smNode.SetAttribute("OriginalCountryCode", SM.Emg.OriginalCountryCode);
                smNode.SetAttribute("CurrentCountryCode", SM.Emg.CurrentCountryCode);
                smNode.SetAttribute("IsThisMgmtServer", Helpers.IsSameAsHostname(SM.Emg.ConnectionSettings.ServerName).ToString());
                smNode.SetAttribute("MGId", SM.Emg.Id.ToString());
                smNode.SetAttribute("UserRoles", Helpers.MemberOfUserRoles(ConsoleContextHelper.Instance.UserRoleHelper));
                smNode.SetAttribute("DWMGId", SM.Emg.DataWarehouse.GetDataWarehouseConfiguration() == null ? "" : SM.Emg.DataWarehouse.GetDataWarehouseConfiguration().ManagementGroupId.ToString());
                #endregion
                #region OS node
                var osNode = rootNode.AppendChild(XmlTelemetry.CreateNode(XmlNodeType.Element, "OS", null)) as XmlElement;
                osNode.SetAttribute("Version", Helpers.GetOSVersionString());
                osNode.SetAttribute("Name", Helpers.GetOSName());
                osNode.SetAttribute("Locale", Thread.CurrentThread.CurrentUICulture.DisplayName);
                osNode.SetAttribute("InternetAvailable", Helpers.IsConnectedToInternet().ToString());
                osNode.SetAttribute("WebProxy", Helpers.IsWebProxyNeeded().ToString());
                osNode.SetAttribute("ComputerNameGuidHash", Helpers.GetHashStringFromString(Helpers.GetCurrentComputerGuidFromAd().ToString().ToLower()));
                osNode.SetAttribute("DomainUserNameGuidHash", Helpers.GetHashStringFromString(Helpers.GetCurrentUserGuidFromAd().ToString().ToLower()));
                osNode.SetAttribute("DomainGuidHash", Helpers.GetHashStringFromString(Helpers.GetComputerDomainGuid().ToString().ToLower()));
                osNode.SetAttribute("IsRunningAs64bit", Helpers.IsRunningAs64bit().ToString());
                osNode.SetAttribute("DisplayScale", Helpers.GetWindowsScaling().ToString());
                osNode.SetAttribute("DisplayResolution", Helpers.GetDisplayResolution().ToString());
                #endregion
            });
        }

        /// <summary>
        /// Concurrency is ignored...
        /// </summary>
        public XmlDocument XmlTelemetry
        {
            get;
            private set;
        }

        #region static helper functions
        public static async void SendAsync(string moduleName, string operationType, Dictionary<string, string> props)
        {
            try
            {
                (await InstanceAsync)
                    .SendTelemetry(moduleName, operationType, props);
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }

        public static async void SetInfoAsync(string moduleName, string attribName, string attribValue)
        {
            try
            {
                (await InstanceAsync)
                    .SetTelemetryInfo(moduleName, attribName, attribValue);
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }
        #endregion        

        private void SendTelemetry(string moduleName, string operationType, Dictionary<string, string> props)
        {
            int currSeq;
            int.TryParse(GetTelemetryInfo("", "SequenceId"), out currSeq);
            currSeq++;
            SetTelemetryInfo("", "SequenceId", currSeq.ToString());

            var telemetry = XmlTelemetry.Clone() as XmlDocument;
            var rootNode = telemetry.DocumentElement;

            var operationNode = rootNode.AppendChild(telemetry.CreateNode(XmlNodeType.Element, "Operation", null)) as XmlElement;
            operationNode.SetAttribute("Type", operationType);
            operationNode.SetAttribute("LocalTimeWithTZ", DateTime.Now.ToStringWithTz());
            operationNode.SetAttribute("Module", moduleName);

            foreach (var prop in props)
            {
                operationNode.AppendChild(telemetry.CreateNode(XmlNodeType.Element, prop.Key, null)).InnerText = prop.Value;
            }

            UploadTelemetry(telemetry.OuterXml);
        }
        private void UploadTelemetry(string telemetryXmlString)
        {
            try
            {
                var ms = new MemoryStream();
                var cs = new System.IO.Compression.GZipStream(ms, System.IO.Compression.CompressionMode.Compress);
                var sw = new StreamWriter(cs);
                sw.Write(telemetryXmlString);
                sw.Close();
                var statInfo = System.Convert.ToBase64String(ms.ToArray());

                Uri uri = new Uri("https://forms.office.com/formapi/api/72f988bf-86f1-41af-91ab-2d7cd011db47/groups/5ea18668-1df0-42b7-b3ef-ecdf1df4110b/forms('v4j5cvGGr0GRqy180BHbR2iGoV7wHbdCs-_s3x30EQtUMFVEME05OFBIMkRYUTNDUFk1QkxQSVNBMyQlQCN0PWcu')/responses");
                var questionIDs = new List<string>() { "r14f509ca5b734d3f9ed292e42acb011a", "rf9b227915ae54f8d93d0206ee3210fa4", "rd84c67987a6b46d1a9a63e5cc6511673", "r75eaa58db25f4de992382ccbd5ae8d29", "rf2e073ae17de40c2acfc126df96a6f12", "rad0902e642e642e7adfa57d356af4a0a", "r680f515af201463ebc6d6351d8b0f4f6", "r3b0a6b63bc0641539ac6e09ac0ca0261", "rc0adee71a32a4df0a5e6a4860e298372", "r9a610a66fbb4403198599304ef9672dd", "ra2d31dc706404b89971f6e4fdeec1660", "rcd7ef7efecbe44309604c220eaf764ae", "r681b9195ebd747678afc91ba1fca550a", "r2a5259256bd747aca01c0ef97dcb4f89", "r54744977d244425c980bcce9f9c4815e", "r32cda0df62b240559e4549de6001a5fd", "r341435b595bf4a73bd9aeb5f02f6f4c9", "rec80bae2f680412984105a1653a395be", "rf940f378876c46f88f6369fa744c6d24", "rb11cda7c23124ed1a84825b2b639cdc5", "r6aaf378ae130414ca9b82e0b962d4091", "r20e2d35ffb764da1bc6ea57ce6c719bb", "r50ad1aefa9e44974b3e68e4d37a52c82", "r2365651122d34739ab89c206cab694b1", "r61df2ecc323943d2a66ce4102e1e2589", "r8dfc22761f1d4242ba0707a6ba99616d", "r28eb66652ac445548895d9e71f385026", "rd3ba560f279746568328659639264146", "rde2045a22ca0481fb9f3fcda5f0f0e71", "r80f495dc4fa44bdabbbc81007f7ae8f5", "r4a61a52cfccd4ca084fb2bb43b303ba6", "r1276cf9ab0734434a761e86ca42cdb1e", "ra8c8729ffe3a4c38a9c61b746a70f8a5", "r30c1f9fccf034e919fdea48b2ceedd89", "r0802c6d952014ea29d80a2cc52ac6515", "r36dcbfd13526475db4795664a34998f4", "r30c43540200e4f88b5af94b5a73aa2bd", "r70b8ea90a49949e8b8fe19cca077e94c", "r7458f57b4713469fa0482f83489a0734", "raec9bf88600c4b9dbda88f954856b137", "raff6e5fcee1c45ed8485bdadb6cfaf6f", "r3df52174834e40fb9676a147aebbbfeb", "rcd0a646ec5f6455b89c9d946b3be8170", "r954183c1808a4de9966bfc18b32d6cf2", "rcd3d2c99be7642f092bd78bb2c03cd1c", "r75e14134a3b944289262907f063bac48", "r31dcecd7d60a46e8b410990d357c814f", "r3c42754a21aa4cd2981daeb73ca398ec", "r6e04640a043e4e0f89ac03a2f43c5c67", "r0d4cfd7cdc7f44f3a377558fb9195a54" };

                var maxCharsPerQuestion = 4000;
                var bodyStart = "{\"answers\":\"[";
                var startPos = 0;
                var answers = "";
                var isFirst = true;
                foreach (var questionID in questionIDs)
                {
                    var answer = "";
                    var subStringLength = maxCharsPerQuestion;
                    if (startPos + subStringLength > statInfo.Length)
                    {
                        if (startPos > statInfo.Length)
                        {
                            answer = "";
                        }
                        else
                        {
                            answer = statInfo.Substring(startPos);
                        }
                    }
                    else
                    {
                        answer = statInfo.Substring(startPos, subStringLength);
                    }
                    if (isFirst) { isFirst = false; } else { answers += ","; }
                    answers += string.Format("{{\\\"questionId\\\":\\\"{0}\\\",\\\"answer1\\\":\\\"{1}\\\"}}", questionID, answer);
                    startPos += maxCharsPerQuestion;
                }
                var bodyEnd = "]\"}";
                var body = string.Format("{0}{1}{2}", bodyStart, answers, bodyEnd);

                HttpContent payLoad = new StringContent(body, Encoding.UTF8, "application/json");
                Helpers.GetHttpClient_WithProxy(uri, 60).PostAsync(uri, payLoad);
            }
            catch { }
        }

        private void SetTelemetryInfo(string moduleName, string attribName, string attribValue)
        {
            var xmlTelemetry = XmlTelemetry;
            XmlElement telemetryNode = xmlTelemetry.DocumentElement;
            if (!string.IsNullOrEmpty(moduleName))
            {
                var moduleNode = xmlTelemetry.DocumentElement.GetElementsByTagName(moduleName);
                if (moduleNode.Count > 0)
                {
                    telemetryNode = xmlTelemetry.DocumentElement.GetElementsByTagName(moduleName)[0] as XmlElement;
                }
            }
            telemetryNode.SetAttribute(attribName, attribValue);
        }
        private string GetTelemetryInfo(string moduleName, string attribName)
        {
            var xmlTelemetry = XmlTelemetry;
            XmlElement telemetryNode = xmlTelemetry.DocumentElement;
            if (!string.IsNullOrEmpty(moduleName))
            {
                var moduleNode = xmlTelemetry.DocumentElement.GetElementsByTagName(moduleName);
                if (moduleNode.Count > 0)
                {
                    telemetryNode = xmlTelemetry.DocumentElement.GetElementsByTagName(moduleName)[0] as XmlElement;
                }
            }
            XmlAttribute attribNode = telemetryNode.GetAttributeNode(attribName);
            string result = "";
            if (attribNode != null)
            {
                result = attribNode.Value;
            }
            return result;
        }
    }
}
