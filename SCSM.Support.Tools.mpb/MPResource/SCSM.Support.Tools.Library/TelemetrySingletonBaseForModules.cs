using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;

namespace SCSM.Support.Tools.Library
{
    public abstract class TelemetrySingletonBaseForModules<T> where T : TelemetrySingletonBaseForModules<T>, new()
    {
        protected TelemetrySingletonBaseForModules() { }
        private static readonly Lazy<Task<T>> sInstance = new Lazy<Task<T>>(async () =>
        {
            var instance = new T();
            await instance.InitializeAsync();
            return instance;
        });
        public static Task<T> InstanceAsync { get { return sInstance.Value; } }

        protected abstract string ModuleName { get; }
        protected virtual async Task InitializeAsync()
        {
            var xmlTelemetry = (await Library.Telemetry.InstanceAsync).XmlTelemetry;
            var telemetryNode = xmlTelemetry.DocumentElement.AppendChild(xmlTelemetry.CreateNode(XmlNodeType.Element, ModuleName, null)) as XmlElement;
            telemetryNode.SetAttribute("PresentationVersion", Helpers.GetModuleVersion(string.Format("SCSM.Support.Tools.{0}.Presentation.dll", ModuleName)));
        }

       #region static helper functions that hides the async/await stuff at caller side
        public static async void SendAsync(string operationType, Dictionary<string, string> props)
        {
            try
            {
                Library.Telemetry.SendAsync((await InstanceAsync).ModuleName, operationType, props);
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }
        public static async void SetInfoAsync(string attribName, string attribValue)
        {
            try
            {
                Library.Telemetry.SetInfoAsync((await InstanceAsync).ModuleName, attribName, attribValue);
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }
        #endregion       
    }
}
