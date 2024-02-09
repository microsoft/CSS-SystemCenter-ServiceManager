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

namespace SCSM.Support.Tools.Main.Presentation
{
    /// <summary>
    /// Interaction logic for Eula.xaml
    /// </summary>
    public partial class Eula : UserControl
    {
        public Eula()
        {
            InitializeComponent();
        }

        private void EulaAgreement_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Acccept Eula?", "", MessageBoxButton.YesNoCancel, MessageBoxImage.Question, MessageBoxResult.Cancel);
        }
    }
}
