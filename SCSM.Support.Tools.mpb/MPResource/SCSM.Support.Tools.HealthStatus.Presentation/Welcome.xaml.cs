using SCSM.Support.Tools.Library;
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

namespace SCSM.Support.Tools.HealthStatus
{
    /// <summary>
    /// Interaction logic for Welcome.xaml
    /// </summary>
    public partial class Welcome : UserControl
    {
        public Welcome()
        {
            InitializeComponent();
        }

        private const string prefix_Nav = "msscnav://root/Windows/Window/ConsoleDisplay";

        public static Uri NavUri_WF
        {
            get
            {
                string navUri = prefix_Nav
                    + "/Folder." + Helpers.fn_MPObjectId("Microsoft.EnterpriseManagement.ServiceManager.UI.Administration", "31bf3856ad364e35", "Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Folder")
                    + "/Folder." + Helpers.fn_MPObjectId("Microsoft.EnterpriseManagement.ServiceManager.UI.Administration", "31bf3856ad364e35", "Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Folder.Root")
                    + "/Folder." + Helpers.fn_MPObjectId("SCSM.Support.Tools.Core", "2975db379ccb9e66", "SCSM.Support.Tools.Folder.Root")
                    + "/Folder." + Helpers.fn_MPObjectId("SCSM.Support.Tools.HealthStatus.Views", "2975db379ccb9e66", "Folder.a6e62cefef584ca69027355829e0953d")
                    + "/View." + Helpers.fn_MPObjectId("SCSM.Support.Tools.HealthStatus.Views", "2975db379ccb9e66", "View.f1cb07d0143c4571a40f333bcfee81fe");
                return new Uri(navUri);
            }
        }
        public static Uri NavUri_DW
        {
            get
            {
                string navUri = prefix_Nav
                    + "/Folder." + Helpers.fn_MPObjectId("Microsoft.EnterpriseManagement.ServiceManager.UI.Administration", "31bf3856ad364e35", "Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Folder")
                    + "/Folder." + Helpers.fn_MPObjectId("Microsoft.EnterpriseManagement.ServiceManager.UI.Administration", "31bf3856ad364e35", "Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Folder.Root")
                    + "/Folder." + Helpers.fn_MPObjectId("SCSM.Support.Tools.Core", "2975db379ccb9e66", "SCSM.Support.Tools.Folder.Root")
                    + "/Folder." + Helpers.fn_MPObjectId("SCSM.Support.Tools.HealthStatus.Views", "2975db379ccb9e66", "Folder.a6e62cefef584ca69027355829e0953d")
                    + "/View." + Helpers.fn_MPObjectId("SCSM.Support.Tools.HealthStatus.Views", "2975db379ccb9e66", "View.00748ff8ec66473a8b45dcd59d2142ef");
                return new Uri(navUri);
            }
        }
        public static Uri NavUri_DailyEmails
        {
            get
            {
                string navUri = prefix_Nav
                    + "/Folder." + Helpers.fn_MPObjectId("Microsoft.EnterpriseManagement.ServiceManager.UI.Administration", "31bf3856ad364e35", "Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Folder")
                    + "/Folder." + Helpers.fn_MPObjectId("Microsoft.EnterpriseManagement.ServiceManager.UI.Administration", "31bf3856ad364e35", "Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Folder.Root")
                    + "/Folder." + Helpers.fn_MPObjectId("SCSM.Support.Tools.Core", "2975db379ccb9e66", "SCSM.Support.Tools.Folder.Root")
                    + "/Folder." + Helpers.fn_MPObjectId("SCSM.Support.Tools.HealthStatus.Views", "2975db379ccb9e66", "Folder.a6e62cefef584ca69027355829e0953d")
                    + "/View." + Helpers.fn_MPObjectId("SCSM.Support.Tools.HealthStatus.Views", "2975db379ccb9e66", "View.621263932b7e41bb83d41447339baac0");
                return new Uri(navUri);
            }
        }
    }
}
