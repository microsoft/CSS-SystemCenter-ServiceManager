using Microsoft.EnterpriseManagement;
using Microsoft.EnterpriseManagement.Configuration;
using Microsoft.EnterpriseManagement.ConsoleFramework;
using Microsoft.EnterpriseManagement.Internal;
using Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Notification.Subscription;
using Microsoft.EnterpriseManagement.UI.Core.Connection;
using Microsoft.EnterpriseManagement.UI.DataModel;
using Microsoft.EnterpriseManagement.UI.Extensions.Shared;
using Microsoft.EnterpriseManagement.UI.SdkDataAccess.DataAdapters;
using SCSM.Support.Tools.Library;
using System;
using System.Collections.Generic;
using System.ComponentModel.Design;
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


namespace SCSM.Support.Tools.HealthStatus
{
    public partial class DailySubscription : UserControl
    {

        public DailySubscription()
        {
            InitializeComponent();
        }

        private EnterpriseManagementGroup _emg = null;
        private EnterpriseManagementGroup Emg
        {
            get
            {
                if (_emg == null)
                {
                    IServiceContainer container = (IServiceContainer)FrameworkServices.GetService(typeof(IServiceContainer));
                    IManagementGroupSession curSession = (IManagementGroupSession)container.GetService(typeof(IManagementGroupSession));
                    _emg = curSession.ManagementGroup;
                }
                return _emg;
            }
        }

        private string subscriptionMpName = "SCSM.Support.Tools.HealthStatus.Notification.Subscriptions";
        private string subscriptionMpResourceName = "SCSM.Support.Tools.HealthStatus.Notification.Subscriptions.Resource";
        private string subscriptionName = "SCSM.Support.Tools.HealthStatus.Notification.DailySubscription";

        //private string notifTemplateId = "c2b84f4d-a448-73e2-7a3e-f774d91f5f84"; //todo to be generated !!!  /////////////////////////
        //private string notifTemplateName = "SCSM.Support.Tools.HealthStatus.Notification.Template"; 
        //private string notifMpKeyToken = "2975db379ccb9e66"; // todo MSPublicKeyToken
        private string notifMpName = "SCSM.Support.Tools.HealthStatus.Notifications";


        void CreateSubscriptionMP_IfNotExist()
        {
            if (GetManagementPack_Subscriptions() != null) { return; }

            var notifMP = Emg.ManagementPacks.GetManagementPacks().Where(mp => mp.Name == notifMpName).FirstOrDefault();
            var resource_subsMP = Emg.Resources.GetResource<ManagementPackResource>(subscriptionMpResourceName, notifMP);
            var streamSubs = Emg.Resources.GetResourceData(resource_subsMP);
            var tmpFileFullPath = ConsoleContextHelper.Instance.WriteStreamToTempFile(subscriptionMpName, ".xml", streamSubs);
            //todo   EDIT notifTemplateId here in the file  ///////////////////////////////////////////////////////////////////////////////////////////////////////
            //string notifTemplateId = IdUtil.GetGuidFromString(string.Format(@"MPName={0},KeyToken={1},ObjectId={2}", notifMpName, notifMpKeyToken, notifTemplateName)).ToString();

            var newMP = new ManagementPack(tmpFileFullPath);
            Emg.ManagementPacks.ImportManagementPack(newMP);
        }

        private void EditSubscriptionMP_Click(object sender, RoutedEventArgs e)
        {   
            var subscriptionId= Emg.Monitoring.GetRules().Where(r => r.Name == subscriptionName).FirstOrDefault().Id;
            IDataItem subscriptionDataItem = ConsoleContextHelper.Instance.GetWorkflowSubscriptionRule(subscriptionId);
            var commandHandler = new Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Notification.Subscription.SubscriptionCommandHandler();
            commandHandler.EditSubscription(subscriptionDataItem, true); 
        }


        private void Grid_Loaded(object sender, RoutedEventArgs e)
        {
            CreateSubscriptionMP_IfNotExist();

            //todo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            #region MyRegion
            /*insert 2 rows 

            INSERT INTO ExcludedRelatedEntityChangeLog(RelationshipTypeId, TargetTypeId) VALUES
                ('06fb902d-54d4-d6fc-f67d-5f11321d1abc', '618ab3c4-135e-92d6-7d30-823f17a3e156')
                ,('f79759b6-56cb-c9da-1f91-808ee5bd54cd', '3ace4a03-e2fd-1978-ec2e-981d5c5f174c')

            */
            #endregion
        }

        private IDataItem GetManagementPack_Subscriptions()
        {
            var x = ConsoleContextHelper.Instance.GetManagementPack(Helpers.fn_MPId(subscriptionMpName, null));
            return x;
            //return Emg.ManagementPacks.GetManagementPacks().Where(mp => mp.Name == subscriptionMpName).FirstOrDefault(); //returns null if not exist
        }
    }
}
