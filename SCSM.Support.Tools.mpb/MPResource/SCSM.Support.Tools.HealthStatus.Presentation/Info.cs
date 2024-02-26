using Microsoft.EnterpriseManagement.Configuration;
using SCSM.Support.Tools.Library;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SCSM.Support.Tools.HealthStatus.Presentation
{
    public class Info
    {
        public static string subscriptionMpName = "SCSM.Support.Tools.HealthStatus.Notification.Subscription";
        private static string subscriptionName = "SCSM.Support.Tools.HealthStatus.Notification.ChangedSubscription";

        public static ManagementPack GetSubscriptionMP()
        {
            return SM.GetMP(subscriptionMpName);
        }
        public static ManagementPackRule GetSubscription()
        {
            return SM.GetRule(subscriptionName);
        }
    }
}
