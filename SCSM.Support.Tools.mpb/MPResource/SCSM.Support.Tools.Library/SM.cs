using Microsoft.EnterpriseManagement;
using Microsoft.EnterpriseManagement.Configuration;
using Microsoft.EnterpriseManagement.ConsoleFramework;
using Microsoft.EnterpriseManagement.UI.Core.Connection;
using Microsoft.EnterpriseManagement.UI.Extensions.Shared;
using System;
using System.Collections.Generic;
using System.ComponentModel.Design;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SCSM.Support.Tools.Library
{
    public static class SM
    {
        static IServiceContainer container = (IServiceContainer)FrameworkServices.GetService(typeof(IServiceContainer));
        static IManagementGroupSession curSession = (IManagementGroupSession)container.GetService(typeof(IManagementGroupSession));

        public static EnterpriseManagementGroup Emg
        {
            get
            {
                return curSession.ManagementGroup;
            }
        }
        public static ManagementPack GetMP(string mpName)
        {
            return Emg.ManagementPacks.GetManagementPacks().Where(mp => mp.Name == mpName).FirstOrDefault();            
        }
        public static ManagementPackRule GetRule(string ruleName)
        {
            return Emg.Monitoring.GetRules().Where(r => r.Name == ruleName).FirstOrDefault();
        }
        //public static ConsoleContextHelper C
        //{
        //    get
        //    {
        //        return ConsoleContextHelper.Instance;
        //    }
        //}
    }
}
