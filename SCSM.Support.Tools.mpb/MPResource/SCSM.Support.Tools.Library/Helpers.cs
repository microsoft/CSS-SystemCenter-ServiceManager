using Microsoft.EnterpriseManagement.UI.Extensions.Shared;
using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Forms;
using System.Xml;

namespace SCSM.Support.Tools.Library
{
    public static class Helpers
    {
        #region Calculation of MP element Guid
        // equivalent of SQL:    select cast( HashBytes('SHA1', N'AstringHere') AS uniqueidentifier)
        private static Guid SMSpecific_ConvertStringToGuid(string s)
        {
            var sha1 = System.Security.Cryptography.SHA1.Create();
            byte[] hashBytes = sha1.ComputeHash(System.Text.Encoding.Unicode.GetBytes(s));
            byte[] bytesResult = Array.CreateInstance(typeof(byte), 16) as byte[];
            Array.Copy(hashBytes, 0, bytesResult, 0, 16);
            return new System.Guid(bytesResult);
        }

        // equivalent of fn_MPId in SM DB
        public static Guid fn_MPId(string MPName, string MPKeyToken)
        {
            if (MPKeyToken == null)
            {
                return SMSpecific_ConvertStringToGuid(string.Format("MPName={0}", MPName));
            }
            return SMSpecific_ConvertStringToGuid(string.Format("MPName={0},KeyToken={1}", MPName, MPKeyToken));
        }

        // equivalent of fn_MPObjectId in SM DB
        public static Guid fn_MPObjectId(string MPName, string MPKeyToken, string ObjectName)
        {

            if (MPName == null)
            {
                return SMSpecific_ConvertStringToGuid(string.Format("ObjectId={0}", ObjectName));
            }
            if (MPName == ObjectName)
            {
                return fn_MPId(MPName, MPKeyToken);
            }
            if (MPKeyToken == null)
            {
                return SMSpecific_ConvertStringToGuid(string.Format("MPName={0},ObjectId={1}", MPName, ObjectName));
            }
            return SMSpecific_ConvertStringToGuid(string.Format("MPName={0},KeyToken={1},ObjectId={2}", MPName, MPKeyToken, ObjectName));
        }

        // equivalent of fn_MPObjectOrGuidId in SM DB
        public static Guid fn_MPObjectOrGuidId(string MPName, string MPKeyToken, string ObjectName)
        {
            if (ObjectName.IndexOf('-') > 0)
            {
                return new Guid(ObjectName);
            }
            return fn_MPObjectId(MPName, MPKeyToken, ObjectName);
        }
        #endregion

        #region Exception Handling
        private const string event_logName = "Application";
        private const string event_Source = "Application";
        private const int event_ID = 2222;
        private const short event_category = 0;
        private const EventLogEntryType event_type = EventLogEntryType.Error;
        private const string gitHub_IssuesUrl = "https://github.com/microsoft/CSS-SystemCenter-ServiceManager/issues";

        private static void LogException(Exception ex, string additionalInfo = "")
        {
            var currentModuleInfo = string.Format("{0} {1}", GetLibraryAssemblyModule().FullName, GetLibraryAssemblyModule().Location);

            string event_message = string.Format("{0} \r\n------- \r\n{1} ", ex.ToString(), currentModuleInfo);
            if (!string.IsNullOrWhiteSpace(additionalInfo))
            {
                event_message += string.Format("\r\n------ \r\nAdditional Info: {0}", additionalInfo);
            }

            using (EventLog eventLog = new EventLog(event_logName))
            {
                eventLog.Source = event_Source;
                eventLog.WriteEntry(event_message, event_type, event_ID, event_category);
            }
        }

        public static void OnlyLogException(Exception ex, string additionalInfo = "")
        {
            LogException(ex, additionalInfo);
        }
        public static void LogAndShowException(Exception ex, string additionalInfo = "")
        {
            LogException(ex, additionalInfo);

            string message = string.Format("SCSM Support Tools encountered an error. Please retry. If error rehappens, please check the {0} event log with event Id {1} for more details. If you want, you can log an Issue at GitHub {2}. Thank you.", event_logName, event_ID, gitHub_IssuesUrl);
            ConsoleContextHelper.Instance.ShowErrorDialog(ex, message, Microsoft.EnterpriseManagement.ConsoleFramework.ConsoleJobExceptionSeverity.Error);
        }
        #endregion

        #region Misc
        public const string PublicKeyToken = "31bf3856ad364e35";
        public static string ToStringWithTz(this DateTime dateTime)
        {
            return dateTime.ToString("yyyy-MM-dd__HH:mm.ss.fff zzz");
        }
        public static byte[] GetHashBytesFromString(string s)
        {
            return SHA256.Create().ComputeHash(Encoding.UTF8.GetBytes(s));
        }
        public static string GetHashStringFromString(string s)
        {
            var hash = GetHashBytesFromString(s);
            var sb = new StringBuilder(hash.Length * 2);
            foreach (byte b in hash)
            {
                sb.Append(b.ToString("X2"));
            }
            return sb.ToString();
        }
        public static string GetUserFriendlyTimeSpan(DateTime dateTime)
        {
            string result = "";

            var elapsedTime = DateTime.Now.Subtract(dateTime);
            if (elapsedTime.Days > 0)
            {
                result = string.Format("{0} day{1} ago", elapsedTime.Days, (elapsedTime.Days > 1) ? "s" : "");
            }
            else if (elapsedTime.Hours > 0)
            {
                result = string.Format("{0} hour{1} ago", elapsedTime.Hours, (elapsedTime.Hours > 1) ? "s" : "");
            }
            else if (elapsedTime.Minutes > 0)
            {
                result = string.Format("{0} minute{1} ago", elapsedTime.Minutes, (elapsedTime.Minutes > 1) ? "s" : "");
            }
            else
            {
                result = "A few seconds ago";
            }

            return result;
        }
        //public static bool IsUserMemberOfLocalAdminsGroup()
        //{
        //    var identity = System.Security.Principal.WindowsIdentity.GetCurrent();
        //    var principal = new System.Security.Principal.WindowsPrincipal(identity);
        //    return principal.IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator);
        //}
        [DllImport("shell32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool IsUserAnAdmin();

        public static bool IsRunningAs64bit()
        {
            return Environment.Is64BitOperatingSystem;
        }
        public static int GetWindowsScaling()
        {
            return (int)(100 * Screen.PrimaryScreen.Bounds.Width / SystemParameters.PrimaryScreenWidth);
        }
        public static string GetDisplayResolution()
        {
            return string.Format("{0}x{1}", Screen.PrimaryScreen.Bounds.Width, Screen.PrimaryScreen.Bounds.Height);
            //float dpiX, dpiY;
            //Graphics graphics = this.CreateGraphics();
            //dpiX = graphics.DpiX;
            //dpiY = graphics.DpiY;
        }
        private static Assembly libraryAssemblyModule;
        public static Assembly GetSmConsoleAssembly()
        {
            return Assembly.GetExecutingAssembly();
        }

        public static Assembly GetAssemblyModule(string moduleNameWithExtension)
        {
            var modules = System.AppDomain.CurrentDomain.GetAssemblies();
            foreach (var module in modules)
            {
                if (module.ManifestModule.Name == moduleNameWithExtension)
                {
                    return module;
                }
            }
            return null;
        }
        public static string GetModuleVersion(string moduleNameWithExtension)
        {
            var location = GetAssemblyModule(moduleNameWithExtension).Location;
            FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(location);
            return fvi.FileVersion;
        }
        public static string GetModuleVersion(Assembly module)
        {
            var location = module.Location;
            FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(location);
            return fvi.FileVersion;
        }

        public static Assembly GetLibraryAssemblyModule()
        {
            if (libraryAssemblyModule == null)
            {
                libraryAssemblyModule = GetAssemblyModule("SCSM.Support.Tools.Library.dll");
            }
            return libraryAssemblyModule;
        }
        public static string GetLibraryVersion()
        {
            return GetModuleVersion(GetLibraryAssemblyModule());
        }

        public static string MemberOfUserRoles(UserRoleHelper userRoleHelper)
        {
            if (userRoleHelper.IsUserAdministrator) { return "Administrator"; }

            string result = string.Empty;
            if (userRoleHelper.IsUserAdvancedOperator) { result += ",AdvancedOperator"; }
            if (userRoleHelper.IsUserAuthor) { result += ",Author"; }
            if (userRoleHelper.IsUserChangeManager) { result += ",ChangeManager"; }
            if (userRoleHelper.IsUserReleaseManager) { result += ",ReleaseManager"; }
            return result.Substring(1);
        }
        public static string GetOSVersionString()
        {
            var registryKey = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion");
            return string.Format("{0}.{1}.{2}.{3}", registryKey.GetValue("CurrentMajorVersionNumber"), registryKey.GetValue("CurrentMinorVersionNumber"), registryKey.GetValue("CurrentBuild"), registryKey.GetValue("UBR"));
        }
        public static string GetOSName()
        {
            var registryKey = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion");
            return registryKey.GetValue("ProductName").ToString();
        }
        public static bool IsSameAsHostname(string givenString)
        {
            bool result = false;
            givenString = givenString.Trim();
            string envCOMPUTERNAME = Environment.GetEnvironmentVariable("COMPUTERNAME");
            if (givenString == envCOMPUTERNAME) { return true; }
            if (givenString == System.Net.Dns.GetHostEntry(givenString).HostName) { return true; }
            var parts = givenString.Split('.');
            if (parts.Length > 0)
            {
                if (givenString == parts[0]) { return true; }
            }
            return result;
        }
        public static bool IsConnectedToInternet()
        {
            bool result = false;
            Uri uri = new Uri("https://forms.office.com/formapi/api");
            HttpResponseMessage httpResult = new HttpResponseMessage();
            try
            {
                httpResult = GetHttpClient_WithProxy(uri, 60).GetAsync(uri).Result;
                result = true;
            }
            catch { }
            return result;
        }
        public static bool IsWebProxyNeeded()
        {
            Uri uri = new Uri("https://forms.office.com/formapi/api");
            Uri webProxyServer = null;
            var proxyUseDefaultCredentials = true;
            GetProxy(uri, ref webProxyServer, ref proxyUseDefaultCredentials);
            return (webProxyServer != null);
        }
        public static HttpClient GetHttpClient_WithProxy(Uri uri, int timeoutSec = 0)
        {
            System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls12;
            Uri webProxyServer = null;
            var proxyUseDefaultCredentials = true;
            GetProxy(uri, ref webProxyServer, ref proxyUseDefaultCredentials);
            var proxyHttpClientHandler = new HttpClientHandler
            {
                AllowAutoRedirect = false
            };
            if (webProxyServer != null && proxyUseDefaultCredentials)
            {
                var webProxy = new WebProxy(webProxyServer);
                webProxy.UseDefaultCredentials = proxyUseDefaultCredentials;
                proxyHttpClientHandler.Proxy = webProxy;
                proxyHttpClientHandler.UseProxy = true;
            }

            var httpClient = new HttpClient(proxyHttpClientHandler);
            httpClient.Timeout = new TimeSpan(0, 0, timeoutSec);
            return httpClient;
        }

        private static void GetProxy(Uri uri, ref Uri webProxyServer, ref bool proxyUseDefaultCredentials)
        { //https://learn.microsoft.com/en-us/dotnet/api/system.net.iwebproxy.getproxy?view=netframework-4.8.1#examples
            var wpi = System.Net.WebRequest.GetSystemWebProxy();
            wpi.Credentials = System.Net.CredentialCache.DefaultNetworkCredentials;

            webProxyServer = null;

            if (!wpi.IsBypassed(uri))
            {
                webProxyServer = wpi.GetProxy(uri);

                if (webProxyServer != null && webProxyServer == uri)
                {
                    webProxyServer = null;
                }
            }
            proxyUseDefaultCredentials = (webProxyServer != null);
        }
        #endregion
    }


}

