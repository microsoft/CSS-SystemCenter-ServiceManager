using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Xml;

namespace SCSM.Support.Tools.Library
{
    /// <summary>
    /// this class is Singleton per T & with async initialization, that prevents blocking of caller UI thread. 
    /// Because even UI calls "static async SendAsync" method (which would normally not block the UI), BUT before entering that method, 
    /// first static fields (e.g. the "instance") are initialized and static ctor will be run BUT in caller's thread (= UI) and will block the UI.
    /// Therefore async/await pattern also used in the "static" places. Using Task<T> as return type is your friend!
    /// Note: The word "Module" refers to a "Tool" bundled into SCSM.Support.Tools.mpb
    /// Every new Tool should derive from this base class and override accordingly (at least the ModuleName)
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public abstract class TelemetrySingletonBaseForModules<T> where T : TelemetrySingletonBaseForModules<T>, new()
    {
        /// <summary>
        /// base static ctor. runs only once per T when a static member is refd. use this for setting common telemetry for ALL modules
        /// </summary>
        static TelemetrySingletonBaseForModules()
        {
            instance = InitializeField_instance_Async();
        }
        /// <summary>
        /// base instance ctor. runs only once per T when an instance member is refd. use for what?
        /// </summary>
        protected TelemetrySingletonBaseForModules()
        {
        }
        /// <summary>
        /// could be here initialized as  =InitializeField_instance_Async();  but I prefer it to be done in static ctor.
        /// </summary>
        private static readonly Task<T> instance;

        /// <summary>
        /// here we use the chance to do the "initialization" stuff
        /// </summary>
        /// <returns></returns>
        private static async Task<T> InitializeField_instance_Async()
        {
            var instance = new T();
            await instance.InitializeModuleSpecificCommonTelemetryInfo();
            return instance;
        }

        /// <summary>
        /// can be public, but as we don't have instance memebers yet, I want nobody to mess around. Just let users call the public (static) members
        /// </summary>
        private static Task<T> InstanceAsync
        {
            get
            {
                return instance;
            }
        }

        /// <summary>
        /// runs only once per T. use this for common telemetry for ALL modules. This is the part where static initialization goes to a separate thread!
        /// </summary>
        /// <returns></returns>
        protected virtual async Task InitializeModuleSpecificCommonTelemetryInfo()
        {         

            var xmlTelemetry = (await Library.Telemetry.InstanceAsync).XmlTelemetry;
            await Task.Run(() =>
            {
                var telemetryNode = xmlTelemetry.DocumentElement.AppendChild(xmlTelemetry.CreateNode(XmlNodeType.Element, ModuleName, null)) as XmlElement;
                telemetryNode.SetAttribute("PresentationVersion", Helpers.GetModuleVersion(string.Format("SCSM.Support.Tools.{0}.Presentation.dll", ModuleName)));
            });
        }

        /// <summary>
        /// this must be set by module's derived class. It's the module's internal name like Main, HealthStatus ...
        /// </summary>
        protected abstract string ModuleName { get; }

        #region static helper functions that hides the async/await stuff at caller side
        /// <summary>
        /// to be easily called by Modules. The call is immediately returned to the caller (may be UI). Any slowness or exceptions does not impact the caller thread. GREAT!
        /// </summary>
        /// <param name="operationType"></param>
        /// <param name="props"></param>
        public static async void SendAsync(string operationType, Dictionary<string, string> props)
        {
            try
            {
                //the below "await" will immediately return back (before setting the local variable) to the caller (maybe UI), that's great not to eventually block the caller
                var instanceAsync = await InstanceAsync;
                //then it will continue below only if InstanceAsync has finished, which means when eventually the "Task<T> instance" static field has been initialized.
                //That's exactly I want, bcz I need to wait here until Instance is fully "asyncronously" initialized, so that I can fetch the instance's ModuleName
                Library.Telemetry.SendAsync(instanceAsync.ModuleName, operationType, props);
            }
            catch (Exception ex) //also, exceptions thrown during async initializations code will be caught here, great!
            {
                Helpers.OnlyLogException(ex);
            }
        }


        //public static async void SetInfo(string attribName, string attribValue)
        //{
        //    SetInfo(attribName, attribValue);
        //}
        public static async void SetInfoAsync(string attribName, string attribValue)
        {
            try
            {
                Library.Telemetry.SetInfoAsync((await InstanceAsync).ModuleName, attribName, attribValue);
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }
        #endregion       
    }
}
