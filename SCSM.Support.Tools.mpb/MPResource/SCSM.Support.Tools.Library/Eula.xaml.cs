using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Forms;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using Microsoft.EnterpriseManagement.Configuration;
using Microsoft.EnterpriseManagement.UI.DataModel;
using Microsoft.EnterpriseManagement.UI.Extensions.Shared;


namespace SCSM.Support.Tools.Library
{
    public partial class Eula : System.Windows.Controls.UserControl
    {
        public Eula()
        {
            InitializeComponent();
        }

        private void EulaAgreement_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                if (ShowEulaForm() == DialogResult.Yes)
                {
                    EulaStatus.EulaAccepted = true;
                    this.EulaAgreement.Height = 0;
                }
            }
            catch (Exception ex)
            {
                Helpers.LogAndShowException(ex);
            }
        }

        private void UserControl_Initialized(object sender, EventArgs e)
        {
            if (System.ComponentModel.DesignerProperties.GetIsInDesignMode(this)) { return; }

            try
            {
                if (EulaStatus.EulaAccepted)
                {
                    this.EulaAgreement.Height = 0;
                }
                else
                {
                    this.EulaAgreement.Height = 5000;
                }
            }
            catch (Exception ex)
            {
                Helpers.LogAndShowException(ex);
            }
        }

        private DialogResult ShowEulaForm()
        {
            var mode = 0;
            var EULA = new System.Windows.Forms.Form();
            var richTextBox1 = new System.Windows.Forms.RichTextBox();
            var btnAcknowledge = new System.Windows.Forms.Button();
            var btnCancel = new System.Windows.Forms.Button();
            EULA.SuspendLayout();
            EULA.Name = "EULA";
            EULA.Text = "SCSM Support Tools - End User License Agreement";

            richTextBox1.Anchor = System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left | System.Windows.Forms.AnchorStyles.Right;
            richTextBox1.Location = new System.Drawing.Point(12, 12);
            richTextBox1.Name = "richTextBox1";
            richTextBox1.ScrollBars = System.Windows.Forms.RichTextBoxScrollBars.Vertical;
            richTextBox1.Size = new System.Drawing.Size(776, 397);
            richTextBox1.TabIndex = 0;
            richTextBox1.ReadOnly = true;
            richTextBox1.LinkClicked += (sender, e) =>
            {
                System.Diagnostics.Process.Start(e.LinkText);
            };

            string rtfText = "";
            string name = "Eula.rtf";
            var assembly = Assembly.GetExecutingAssembly();
            string resourcePath = assembly.GetManifestResourceNames()
                .Single(str => str.EndsWith(name));

            using (Stream stream = assembly.GetManifestResourceStream(resourcePath))
            using (StreamReader reader = new StreamReader(stream))
            {
                rtfText = reader.ReadToEnd();
            }
            richTextBox1.Rtf = rtfText;

            richTextBox1.BackColor = System.Drawing.Color.White;
            btnAcknowledge.Anchor = System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right;
            btnAcknowledge.Location = new System.Drawing.Point(544, 415);
            btnAcknowledge.Name = "btnAcknowledge";
            btnAcknowledge.Size = new System.Drawing.Size(119, 23);
            btnAcknowledge.TabIndex = 1;
            btnAcknowledge.Text = "Accept";
            btnAcknowledge.UseVisualStyleBackColor = true;
            btnAcknowledge.Click += (sender, e) => { EULA.DialogResult = System.Windows.Forms.DialogResult.Yes; };

            btnCancel.Anchor = System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right;
            btnCancel.Location = new System.Drawing.Point(669, 415);
            btnCancel.Name = "btnCancel";
            btnCancel.Size = new System.Drawing.Size(119, 23);
            btnCancel.TabIndex = 2;

            if (mode != 0)
            {
                btnCancel.Text = "Close";
            }
            else
            {
                btnCancel.Text = "Decline";
            }
            btnCancel.UseVisualStyleBackColor = true;
            btnCancel.Click += (sender, e) => { EULA.DialogResult = System.Windows.Forms.DialogResult.No; };

            EULA.AutoScaleDimensions = new System.Drawing.SizeF(6, 13);
            EULA.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            EULA.ClientSize = new System.Drawing.Size(800, 450);
            EULA.Controls.Add(btnCancel);
            EULA.Controls.Add(richTextBox1);

            if (mode != 0)
            {
                EULA.AcceptButton = btnCancel;

            }
            else
            {
                EULA.Controls.Add(btnAcknowledge);
                EULA.AcceptButton = btnAcknowledge;
                EULA.CancelButton = btnCancel;

            }
            EULA.ResumeLayout(false);
            EULA.Size = new System.Drawing.Size(800, 650);

            return EULA.ShowDialog();
        }
    }
}
