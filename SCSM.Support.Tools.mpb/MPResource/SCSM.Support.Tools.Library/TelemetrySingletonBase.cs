using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;

namespace SCSM.Support.Tools.Library
{
    public abstract class TelemetrySingletonBase<T> : TelemetryBaseForModules where T : TelemetrySingletonBase<T>
    {
        protected TelemetrySingletonBase() { }
        private static readonly Lazy<Task<T>> sInstance = new Lazy<Task<T>>(async () =>
        {
            var instance = Activator.CreateInstance(typeof(Task<T>), true) as T;
            await instance.InitializeAsync();
            return instance;
        });
        public static Task<T> InstanceAsync { get { return sInstance.Value; } }

        protected virtual async Task InitializeAsync()
        {
            var xmlTelemetry = (await Library.Telemetry.InstanceAsync).XmlTelemetry;
            var telemetryNode = xmlTelemetry.DocumentElement.AppendChild(xmlTelemetry.CreateNode(XmlNodeType.Element, ModuleName, null)) as XmlElement;
            telemetryNode.SetAttribute("PresentationVersion", Helpers.GetModuleVersion(string.Format("SCSM.Support.Tools.{0}.Presentation.dll", ModuleName)));
        }

        public static async new void SendAsync(string operationType, Dictionary<string, string> props)
        {
            try
            {
                await
                    (await InstanceAsync)
                    ._SendAsync(operationType, props);
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }
        async Task _SendAsync(string operationType, Dictionary<string, string> props)
        {
            await base.SendAsync(operationType, props);
        }

        public static async new void SetModuleSpecificInfoAsync(string attribName, string attribValue)
        {
            try
            {
                await
                    (await InstanceAsync)
                    ._SetModuleSpecificInfoAsync(attribName, attribValue);
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }
        async Task _SetModuleSpecificInfoAsync(string attribName, string attribValue)
        {
            await base.SetModuleSpecificInfoAsync(attribName, attribValue);
        }
    }
}
