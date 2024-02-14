using Microsoft.EnterpriseManagement.Configuration;
using Microsoft.EnterpriseManagement.UI.Extensions.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using SCSM.Support.Tools.Library;
using Microsoft.EnterpriseManagement;
using Microsoft.EnterpriseManagement.UI.DataModel;
using System.ComponentModel.Design;
using Microsoft.EnterpriseManagement.ConsoleFramework;
using Microsoft.EnterpriseManagement.UI.Core.Connection;
using System.Xml;

namespace SCSM.Support.Tools.HealthStatus.Presentation
{
    /// <summary>
    /// Interaction logic for Dashboard.xaml
    /// </summary>
    public partial class Dashboard : UserControl
    {
        public Dashboard()
        {
            InitializeComponent();
        }

        private string subscriptionMpName = "SCSM.Support.Tools.HealthStatus.Notification.Subscription";
        private string subscriptionMpDisplayName = "SCSM Support Tools - Health Status (Notification) Subscription";
        private string subscriptionName = "SCSM.Support.Tools.HealthStatus.Notification.ChangedSubscription";
        private string subscriptionMpResourceName = "SCSM.Support.Tools.HealthStatus.Notification.Subscription.Resource";
        private string class_HealthStatus_WF = "SCSM.Support.Tools.HealthStatus.WF";
        private string class_HealthStatus_DW = "SCSM.Support.Tools.HealthStatus.DW";
        private string notifMpName = "SCSM.Support.Tools.HealthStatus.Notification";
        private static string MpKeyToken = "31bf3856ad364e35";

        private void EditSubscriptionMP_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                IServiceContainer container = (IServiceContainer)FrameworkServices.GetService(typeof(IServiceContainer));
                IManagementGroupSession curSession = (IManagementGroupSession)container.GetService(typeof(IManagementGroupSession));
                EnterpriseManagementGroup Emg = curSession.ManagementGroup;

                #region import unsealed Subscriptions MP if not exist
                if (Emg.ManagementPacks.GetManagementPacks().Where(mp => mp.Name == subscriptionMpName).FirstOrDefault() == null)
                {

                    var notifMP = Emg.ManagementPacks.GetManagementPacks().Where(mp => mp.Name == notifMpName).FirstOrDefault();
                    var resource_subsMP = Emg.Resources.GetResource<ManagementPackResource>(subscriptionMpResourceName, notifMP);
                    var streamSubs = Emg.Resources.GetResourceData(resource_subsMP);
                    var tmpFileFullPath = ConsoleContextHelper.Instance.WriteStreamToTempFile(subscriptionMpName, ".xml", streamSubs);

                    var newMP = new ManagementPack(tmpFileFullPath);
                    Emg.ManagementPacks.ImportManagementPack(newMP);
                }
                #endregion

                var subscription = Emg.Monitoring.GetRules().Where(r => r.Name == subscriptionName).FirstOrDefault();
                if (subscription == null)
                {
                    MessageBox.Show(string.Format("Looks like the Daily Subscription has been removed from the unsealed MP named '{0}'.\n\nIn order to re-create this daily subscription, this unsealed MP has to be deleted first.\nPlease ensure to export it before deleting.", subscriptionMpDisplayName), "SCSM Support Tools - Warning", MessageBoxButton.OK, MessageBoxImage.Warning);
                    return;
                }
                IDataItem subscriptionDataItem = ConsoleContextHelper.Instance.GetWorkflowSubscriptionRule(subscription.Id);
                var commandHandler = new Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Notification.Subscription.SubscriptionCommandHandler();
                commandHandler.EditSubscription(subscriptionDataItem, true);
            }
            catch (Exception ex)
            {
                Helpers.LogAndShowException(ex);
            }
        }

        private void Component_WF_Initialized(object sender, EventArgs e)
        {
            try
            {
                Component_WForDW_Initialized(sender, e);
            }
            catch (Exception ex)
            {
                Helpers.LogAndShowException(ex);
            }
        }
        private void Component_DW_Initialized(object sender, EventArgs e)
        {
            try
            {
                Component_WForDW_Initialized(sender, e);
            }
            catch (Exception ex)
            {
                Helpers.LogAndShowException(ex);
            }
        }
        
        private void Component_WForDW_Initialized(object sender, EventArgs e)
        {
            Border component = sender as Border;
            Image severityIcon = null;
            TextBlock lastRunFriendly = null;
            IDataItem healthStatus = null;

            if (component.Name.EndsWith("WF"))
            {
                healthStatus = GetHealthStatus_WForDW(class_HealthStatus_WF);
                severityIcon = MaxSeverity_WF;
                lastRunFriendly = LastRunFriendly_WF;
            }
            else if (component.Name.EndsWith("DW"))
            {
                healthStatus = GetHealthStatus_WForDW(class_HealthStatus_DW);
                severityIcon = MaxSeverity_DW;
                lastRunFriendly = LastRunFriendly_DW;
            }
            else
            {
                throw new Exception("sender in Component_WForDW_Initialized is neither WF or DW."); //this should never happen
            }

            component.DataContext = healthStatus;
            if (healthStatus != null && healthStatus["MaxSeverity"] != null)
            {
                var maxSeverity_Name = (healthStatus["MaxSeverity"] as IDataItem)["Name"].ToString();
                SetPerSeverity(component, severityIcon, maxSeverity_Name);
                SetLastRunFriendly(healthStatus["LastRun"], lastRunFriendly);
            }
        }
        private IDataItem GetHealthStatus_WForDW(string class_HealthStatus)
        {
            var mpClassId = (Guid)ConsoleContextHelper.Instance.GetClassType(class_HealthStatus)["Id"];
            var healthStatus = ConsoleContextHelper.Instance.GetAllInstances(mpClassId).First();
            return healthStatus;
        }
        private void SetLastRunFriendly(object lastRunObj, TextBlock lastRunFriendly)
        {
            try
            {
                DateTime lastRun = (DateTime)lastRunObj;
                lastRunFriendly.Text = string.Format("({0})", Helpers.GetUserFriendlyTimeSpan(lastRun));
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }
        private void SetPerSeverity(Border component, Image severityIcon, string maxSeverity_Name)
        {
            #region Set Severity Icon and Border color
            string ImageSource_refix = "pack://application:,,,/";
            if (maxSeverity_Name == "SCSM.Support.Tools.HealthStatus.Enum.Severity.Critical")
            {
                severityIcon.Source = new BitmapImage(new Uri(ImageSource_refix + "Microsoft.EnterpriseManagement.ServiceManager.Application.Common;component/administration/resources/smallerrorimage.png"));
                component.BorderBrush = Brushes.Red;
            }
            else if (maxSeverity_Name == "SCSM.Support.Tools.HealthStatus.Enum.Severity.Error")
            {
                severityIcon.Source = new BitmapImage(new Uri(ImageSource_refix + "Microsoft.EnterpriseManagement.UI.Controls;component/muxshared/resources/graphics/warning16.png"));
                component.BorderBrush = Brushes.DarkOrange;
            }
            else if (maxSeverity_Name == "SCSM.Support.Tools.HealthStatus.Enum.Severity.Warning")
            {
                severityIcon.Source = new BitmapImage(new Uri(ImageSource_refix + "Microsoft.EnterpriseManagement.ServiceManager.Application.Common;component/commonactivitytab/images/onhold_16.png"));
                component.BorderBrush = Brushes.LightBlue;
            }
            else if (maxSeverity_Name == "SCSM.Support.Tools.HealthStatus.Enum.Severity.Good")
            {
                severityIcon.Source = new BitmapImage(new Uri(ImageSource_refix + "Microsoft.EnterpriseManagement.ServiceManager.Application.Common;component/administration/resources/smallsuccessimage.png"));
                component.BorderBrush = Brushes.Green;
            }
            else if (maxSeverity_Name == "SCSM.Support.Tools.HealthStatus.Enum.Severity.Unknown")
            {
                severityIcon.Source = new BitmapImage(new Uri(ImageSource_refix + "Microsoft.EnterpriseManagement.ServiceManager.Application.Common;component/commonactivitytab/images/cancelled_16.png"));
                component.BorderBrush = Brushes.LightYellow;
            }
            #endregion
        }

        public static string VersionOfCore
        {
            get
            {
                var result = "";
                try
                {
                    string coreMpName = "SCSM.Support.Tools.HealthStatus.Core";
                    var mpCore = ConsoleContextHelper.Instance.GetManagementPack(Helpers.fn_MPId(coreMpName, MpKeyToken));
                    var version = new Version(mpCore["Version"].ToString());
                    result = version.ToString();
                }
                catch (Exception ex)
                {
                    Helpers.LogAndShowException(ex);
                }
                return result;
            }
        }
    }
}
