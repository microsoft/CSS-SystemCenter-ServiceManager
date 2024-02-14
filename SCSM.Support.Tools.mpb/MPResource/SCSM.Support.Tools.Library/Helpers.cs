using Microsoft.EnterpriseManagement.UI.Extensions.Shared;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;

namespace SCSM.Support.Tools.Library
{
    public class Helpers
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
            #region Module Info           
            string currentModuleInfo = "";
            var modules = System.AppDomain.CurrentDomain.GetAssemblies();
            foreach (var module in modules)
            {
                if (module.ManifestModule.Name == "SCSM.Support.Tools.Library.dll")
                {
                    currentModuleInfo = string.Format("{0} {1}", module.FullName, module.Location);
                    break;
                }
            }
            #endregion
            #region The message            
            string event_message = string.Format("{0} \r\n------- \r\n{1} ", ex.ToString(), currentModuleInfo);
            if (!string.IsNullOrWhiteSpace(additionalInfo))
            {
                event_message += string.Format("\r\n------ \r\nAdditional Info: {0}", additionalInfo);
            }
            #endregion
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
        #endregion
    }
}
