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
    public static class SMST
    {
        private const string MP_Main_Core = "SCSM.Support.Tools.Main.Core";
        //private const string class_Main_Data = "SCSM.Support.Tools.Main.Data";
        //private static readonly IDataItem mainDataAsIDataItem = ConsoleContextHelper.Instance.GetClassType(class_Main_Data);
        //private static readonly ManagementPackClass mainDataClassType = mainDataAsIDataItem["UnderlyingObject"] as ManagementPackClass;

        public static DateTime FirstImportedAt
        {
            get
            {
                return SM.Emg.GetManagementPack(MP_Main_Core, Helpers.PublicKeyToken, null).TimeCreated;
            }

        }
        public static DateTime LastImportedAt
        {
            get
            {
                return SM.Emg.GetManagementPack(MP_Main_Core, Helpers.PublicKeyToken, null).LastModified;
            }

        }
        public static Version Version
        {
            get
            {
                return SM.Emg.GetManagementPack(MP_Main_Core, Helpers.PublicKeyToken, null).Version;
            }
        }

    }
}
