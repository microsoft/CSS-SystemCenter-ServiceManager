using Microsoft.EnterpriseManagement.Configuration;
using Microsoft.EnterpriseManagement.UI.DataModel;
using Microsoft.EnterpriseManagement.UI.Extensions.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SCSM.Support.Tools.Library
{
    public class EulaStatus
    {
        private static string class_Main_Data = "SCSM.Support.Tools.Main.Data";
        private static IDataItem mainData;
        private static ManagementPackClass mainDataClassType;

        static EulaStatus()
        {
            try
            {
                IDataItem mainDataAsIDataItem = ConsoleContextHelper.Instance.GetClassType(class_Main_Data);
                mainDataClassType = mainDataAsIDataItem["UnderlyingObject"] as ManagementPackClass;
                //var mpClassId = (Guid)ConsoleContextHelper.Instance.GetClassType(class_Main_Data)["Id"];
                var mpClassId = mainDataClassType.Id;
                mainData = ConsoleContextHelper.Instance.GetAllInstances(mpClassId).First();
            }
            catch (Exception ex)
            {
                Helpers.LogAndShowException(ex);
            }
        }

        public static bool EulaAccepted
        {
            get
            {
                if (mainData == null) { return false; }

                return (mainData["EulaApprovedAt"] != null);
            }
            internal set
            {
                if (value != true) { return; };

                mainData["EulaApprovedAt"] = DateTime.Now; //this will be converted to UTC by SDK automatically
                mainData["EulaApprovedBy"] = ConsoleContextHelper.Instance.CurrentUserName;
                ConsoleContextHelper.Instance.UpdateInstance(mainData);
            }
        }
        public static DateTime? EulaAcceptedAt
        {
            get
            {
                if (!EulaAccepted)
                {
                    return null;
                }
                else
                {
                    return (DateTime)mainData["EulaApprovedAt"];
                }
            }
        }
        public static string EulaApprovedBy
        {
            get
            {
                if (mainData == null || mainData["EulaApprovedBy"] == null) { return string.Empty; }

                return mainData["EulaApprovedBy"].ToString();
            }
        }

    }
}
