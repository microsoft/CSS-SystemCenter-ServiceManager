using Microsoft.EnterpriseManagement.Configuration;
using Microsoft.EnterpriseManagement.Subscriptions;
using Microsoft.EnterpriseManagement.UI.Extensions.Shared;
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
        //private static Guid subscriptionId = Helpers.fn_MPObjectId(subscriptionMpName, null, subscriptionName);

        public static ManagementPack GetSubscriptionMP()
        {
            return SM.GetMP(subscriptionMpName);
        }
        public static ManagementPackRule GetSubscription()
        {
            return SM.GetRule(subscriptionName);
        }
        public static int GetSubscriptionRecipientsCount(ManagementPackRule subscription)
        {
            int result = -1;
            if (subscription != null)
            {
                IWorkflowParameters subscriptionParameters = SM.Emg.Subscription.GetSubscriptionById(subscription.Id).Parameters;
                if (subscriptionParameters.ContainsKey("PrimaryUserList"))
                {
                    var recipients = (subscriptionParameters["PrimaryUserList"] as WorkflowArrayParameterValue);
                    if (recipients == null)
                    {
                        result = 0;
                    }
                    else
                    {
                        result = recipients.Values.Count;
                    }
                }
                else
                {
                    result = 0;
                }
            }
            return result;
        }
        public static ManagementPackMonitoringLevel IsSubscriptionEnabled(ManagementPackRule subscription)
        {
            return subscription.Enabled;
        }

        public static async void SetSubscriptionSpecificTelemetryInfoAsync()
        {
            try
            {
                await Task.Run(() =>
                {
                    #region Unsealed subscription MP
                    string subscriptionMPCreatedAt = "";
                    var subscriptionMP = Info.GetSubscriptionMP();
                    if (subscriptionMP != null)
                    {
                        subscriptionMPCreatedAt = subscriptionMP.TimeCreated.ToStringWithTz();
                    }
                    Telemetry.SetInfoAsync("SubscriptionMPCreatedAt", subscriptionMPCreatedAt);
                    #endregion

                    #region Subscription
                    var subscription = Info.GetSubscription();
                    if (subscription == null)
                    {
                        Telemetry.SetInfoAsync("SubscriptionExists", false.ToString());
                        Telemetry.SetInfoAsync("SubscriptionRecipientCount", "-1");
                        Telemetry.SetInfoAsync("SubscriptionIsEnabled", "");
                    }
                    else
                    {
                        Telemetry.SetInfoAsync("SubscriptionExists", true.ToString());
                        Telemetry.SetInfoAsync("SubscriptionRecipientCount", Info.GetSubscriptionRecipientsCount(subscription).ToString());
                        Telemetry.SetInfoAsync("SubscriptionIsEnabled", Info.IsSubscriptionEnabled(subscription).ToString());
                    }
                    #endregion
                });
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }
    }
}
