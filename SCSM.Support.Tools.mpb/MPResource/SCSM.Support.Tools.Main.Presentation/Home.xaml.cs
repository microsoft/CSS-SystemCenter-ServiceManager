using Microsoft.EnterpriseManagement.UI.Extensions.Shared;
using SCSM.Support.Tools.Library;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
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
using System.Xml;

namespace SCSM.Support.Tools.Main.Presentation
{
    /// <summary>
    /// Interaction logic for Home.xaml
    /// </summary>
    public partial class Home : UserControl
    {
        public Home()
        {
            InitializeComponent();
        }

        private void Hyperlink_RequestNavigate(object sender, RequestNavigateEventArgs e)
        {
            try
            {
                Hyperlink hl = (Hyperlink)sender;
                string navigateUri = hl.NavigateUri.ToString();
                Process.Start(new ProcessStartInfo(navigateUri));

                Telemetry.SendAsync(
                    operationType: "LinkClicked",
                    props: new Dictionary<string, string>() {
                        { "InView", "SCSM.Support.Tools.Main.Presentation.Home" },
                        { "LinkUrl", navigateUri}
                    }
                );
            }
            catch (Exception ex)
            {
                Helpers.LogAndShowException(ex);
            }
            e.Handled = true;
        }

        private static string MpKeyToken = "31bf3856ad364e35";

        public static string VersionOfCore
        {
            get
            {
                var result = "";
                try
                {
                    string coreMpName = "SCSM.Support.Tools.Main.Core";
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

        private const string prefix_Nav = "msscnav://root/Windows/Window/ConsoleDisplay";

        public static Uri NavUri_HealthStatus
        {
            get
            {
                var result = new Uri(prefix_Nav);
                try
                {
                    string navUri = prefix_Nav
                    + "/Folder." + Helpers.fn_MPObjectId("Microsoft.EnterpriseManagement.ServiceManager.UI.Administration", MpKeyToken, "Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Folder")
                    + "/Folder." + Helpers.fn_MPObjectId("Microsoft.EnterpriseManagement.ServiceManager.UI.Administration", MpKeyToken, "Microsoft.EnterpriseManagement.ServiceManager.UI.Administration.Folder.Root")
                    + "/Folder." + Helpers.fn_MPObjectId("SCSM.Support.Tools.Main.Presentation", MpKeyToken, "SCSM.Support.Tools.Main.Presentation.Folder.Root")
                    + "/View." + Helpers.fn_MPObjectId("SCSM.Support.Tools.HealthStatus.Presentation", MpKeyToken, "SCSM.Support.Tools.HealthStatus.Presentation.View.Dashboard");
                    return new Uri(navUri);
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
            duration_View.Stop();

            Telemetry.SendAsync(
                operationType: "ViewOpened",
                props: new Dictionary<string, string>() {
                        { "Name", "SCSM.Support.Tools.Main.Presentation.Home" },
                        { "DurationMsecs", duration_View.ElapsedMilliseconds.ToString() }
                }
            );
        }
    }
}
