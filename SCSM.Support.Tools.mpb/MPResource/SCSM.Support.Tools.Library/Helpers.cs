using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SCSM.Support.Tools.Library
{
    public class Helpers
    {
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

        public static string GetUserFriendlyDateTime(DateTime dateTime)
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

        public static bool IsEulaApproved() {
            // get from MT
            return true;
        }
    }
}
