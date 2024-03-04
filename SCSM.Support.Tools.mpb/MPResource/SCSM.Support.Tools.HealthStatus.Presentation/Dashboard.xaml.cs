﻿using Microsoft.EnterpriseManagement.Configuration;
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
using System.Diagnostics;
using Telemetry = SCSM.Support.Tools.HealthStatus.Presentation.Telemetry;
using System.Threading;

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

        //private string subscriptionMpName = "SCSM.Support.Tools.HealthStatus.Notification.Subscription";
        private string subscriptionMpDisplayName = "SCSM Support Tools - Health Status (Notification) Subscription";
        //private string subscriptionName = "SCSM.Support.Tools.HealthStatus.Notification.ChangedSubscription";
        private string subscriptionMpResourceName = "SCSM.Support.Tools.HealthStatus.Notification.Subscription.Resource";
        private string class_HealthStatus_WF = "SCSM.Support.Tools.HealthStatus.WF";
        private string class_HealthStatus_DW = "SCSM.Support.Tools.HealthStatus.DW";
        private string notifMpName = "SCSM.Support.Tools.HealthStatus.Notification";

        private void EditSubscriptionMP_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                #region import unsealed Subscriptions MP if not exist    
                var subscriptionMP = Info.GetSubscriptionMP();
                if (subscriptionMP == null)
                {
                    //the subscription MP does not exist. Let's get it from the Notification MP which is saved there as a resource
                    var notifMP = SM.GetMP(notifMpName);
                    var resource_subsMP = SM.Emg.Resources.GetResource<ManagementPackResource>(subscriptionMpResourceName, notifMP);
                    var streamSubs = SM.Emg.Resources.GetResourceData(resource_subsMP);
                    var tmpFileFullPath = ConsoleContextHelper.Instance.WriteStreamToTempFile(Info.subscriptionMpName, ".xml", streamSubs);
                    var newMP = new ManagementPack(tmpFileFullPath);
                    Stopwatch duration_mpImport = Stopwatch.StartNew();
                    SM.Emg.ManagementPacks.ImportManagementPack(newMP);
                    duration_mpImport.Stop();
                    
                    Info.SetSubscriptionSpecificTelemetryInfoAsync();
                    Telemetry.SendAsync(
                        operationType: "MPImported",
                        props: new Dictionary<string, string>() {
                            { "InView", "SCSM.Support.Tools.HealthStatus.Presentation.Dashboard" },
                            { "MPName", newMP.Name},
                            { "DurationMsecs", duration_mpImport.ElapsedMilliseconds.ToString() },
                        }
                    );
                }
                #endregion

                #region As we have the MP, let's check if the subscription is still there. It may have been deleted manually.
                var duration_GetSubscriptionBeforeEdit = Stopwatch.StartNew();
                var subscription = Info.GetSubscription();
                duration_GetSubscriptionBeforeEdit.Stop();

                if (subscription == null)
                {                    
                    Info.SetSubscriptionSpecificTelemetryInfoAsync();
                    Telemetry.SendAsync(
                        operationType: "MessageBoxShown",
                        props: new Dictionary<string, string>() {
                            { "InView", "SCSM.Support.Tools.HealthStatus.Presentation.Dashboard" },
                            { "Reason", "SubscriptionDoesNotExistInMP"},
                            { "DurationMsecs", duration_GetSubscriptionBeforeEdit.ElapsedMilliseconds.ToString() },
                        }
                    );

                    MessageBox.Show(string.Format("Looks like the Subscription has been removed from the unsealed MP named '{0}'.\n\nIn order to re-create this subscription, this unsealed MP has to be deleted first.\nPlease ensure to export it before deleting.", subscriptionMpDisplayName), "SCSM Support Tools - Warning", MessageBoxButton.OK, MessageBoxImage.Warning);
                    return;
                }
                #endregion

                Info.SetSubscriptionSpecificTelemetryInfoAsync();

                #region Opening the subscription so that the Recipient can be set

                var duration_RecipientsCountBeforeEdit = Stopwatch.StartNew();
                int subscriptionRecipientCountBeforeEdit = Info.GetSubscriptionRecipientsCount(subscription);
                duration_RecipientsCountBeforeEdit.Stop();

                var duration_EditSubscription = Stopwatch.StartNew();
                IDataItem subscriptionDataItem = ConsoleContextHelper.Instance.GetWorkflowSubscriptionRule(subscription.Id);
                var commandHandler = new Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Notification.Subscription.SubscriptionCommandHandler();
                var okClicked = commandHandler.EditSubscription(subscriptionDataItem, true);
                duration_EditSubscription.Stop();

                var duration_GetSubscriptionAfterEdit = Stopwatch.StartNew();
                subscription = Info.GetSubscription(); //refreshing subscription after Edit
                duration_GetSubscriptionAfterEdit.Stop();

                var duration_RecipientsCountAfterEdit = Stopwatch.StartNew();
                int subscriptionRecipientCountAfterEdit = Info.GetSubscriptionRecipientsCount(subscription);
                duration_RecipientsCountAfterEdit.Stop();

                Info.SetSubscriptionSpecificTelemetryInfoAsync();

                Telemetry.SendAsync(
                    operationType: "LinkClicked",
                    props: new Dictionary<string, string>() {
                        { "InView", "SCSM.Support.Tools.HealthStatus.Presentation.Dashboard"},
                        { "LinkUrl", "EditSubscriptionMP_Click"},

                        { "SubscriptionRecipientCountBeforeEdit", subscriptionRecipientCountBeforeEdit.ToString()},
                        { "Result_EditSubscriptionMP", okClicked ? "OKClicked":"CancelClicked"},
                        { "SubscriptionRecipientCountAfterEdit", subscriptionRecipientCountAfterEdit.ToString()},

                        { "DurationMsecs_GetSubscriptionBeforeEdit",            duration_GetSubscriptionBeforeEdit.ElapsedMilliseconds.ToString()},
                        { "DurationMsecs_SubscriptionRecipientCountBeforeEdit", duration_RecipientsCountBeforeEdit.ElapsedMilliseconds.ToString()},
                        { "DurationMsecs_EditSubscriptionMP",                   duration_EditSubscription.ElapsedMilliseconds.ToString()},
                        { "DurationMsecs_GetSubscriptionAfterEdit",             duration_GetSubscriptionAfterEdit.ElapsedMilliseconds.ToString()},
                        { "DurationMsecs_SubscriptionRecipientCountAfterEdit",  duration_RecipientsCountAfterEdit.ElapsedMilliseconds.ToString()},
                    }
                );
                #endregion
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
                Telemetry.SendAsync(
                   operationType: "ErrorHappened",
                   props: new Dictionary<string, string>() {
                        { "Name", "SCSM.Support.Tools.HealthStatus.Presentation.Dashboard" },
                        { "Reason", "Component_WForDW_Initialized is neither WF or DW" },
                   }
                );
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
        }

        public static string VersionOfCore
        {
            get
            {
                var result = "";
                try
                {
                    string coreMpName = "SCSM.Support.Tools.HealthStatus.Core";
                    var mpCore = ConsoleContextHelper.Instance.GetManagementPack(Helpers.fn_MPId(coreMpName, Helpers.PublicKeyToken));
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

        Stopwatch duration_View = Stopwatch.StartNew();
        private void UserControl_Loaded(object sender, RoutedEventArgs e)
        {        
            try
            {
                Info.SetSubscriptionSpecificTelemetryInfoAsync();

                string MaxSeverity_WF = "";
                var wfMaxSeverity = (Component_WF.DataContext as IDataItem)["MaxSeverity"];
                if (wfMaxSeverity != null) { MaxSeverity_WF = wfMaxSeverity.ToString(); }

                string MaxSeverity_DW = "";
                var dwMaxSeverity = (Component_DW.DataContext as IDataItem)["MaxSeverity"];
                if (dwMaxSeverity != null) { MaxSeverity_DW = dwMaxSeverity.ToString(); }

                #region PatchedVersion
                string PatchedVersion_WF = "";
                var wfPatchedVersion = (Component_WF.DataContext as IDataItem)["PatchedVersion"];
                if (wfPatchedVersion != null) { PatchedVersion_WF = wfPatchedVersion.ToString(); }

                string PatchedVersion_DW = "";
                var dwPatchedVersion = (Component_DW.DataContext as IDataItem)["PatchedVersion"];
                if (dwPatchedVersion != null) { PatchedVersion_DW = dwPatchedVersion.ToString(); }

                Library.Telemetry.SetInfoAsync("SM", "PatchedVersion_WF", PatchedVersion_WF);
                Library.Telemetry.SetInfoAsync("SM", "PatchedVersion_DW", PatchedVersion_DW);
                #endregion

                duration_View.Stop();
                Task.Delay(2000); // to give the above SetInfoAsync calls a bit time for saving into Telemetry xml before sending below. No worries, this is async. 
                Telemetry.SendAsync(
                    operationType: "ViewOpened",
                    props: new Dictionary<string, string>() {
                    { "Name", "SCSM.Support.Tools.HealthStatus.Presentation.Dashboard" },
                    { "MaxSeverity_WF", MaxSeverity_WF },
                    { "MaxSeverity_DW",MaxSeverity_DW },
                    { "DurationMsecs", duration_View.ElapsedMilliseconds.ToString() },
                    }
                );
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }        
    }
}
