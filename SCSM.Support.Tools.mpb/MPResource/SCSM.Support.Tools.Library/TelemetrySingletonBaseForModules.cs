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

        public static async void SendAsync(string operationType, Dictionary<string, string> props)
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
        //async Task _SendAsync(string operationType, Dictionary<string, string> props)
        //{
        //    await base.SendAsync(operationType, props);
        //}

        public static async void SetModuleSpecificInfoAsync(string attribName, string attribValue)
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
        //async Task _SetModuleSpecificInfoAsync(string attribName, string attribValue)
        //{
        //    await base.SetModuleSpecificInfoAsync(attribName, attribValue);
        //}

        protected virtual async Task _SendAsync(string operationType, Dictionary<string, string> props)
        {
            await
                (await Library.Telemetry.InstanceAsync)
                .SendAsync(
                    moduleName: ModuleName,
                    operationType: operationType,
                    props: props
                );
        }
        protected virtual async Task _SetModuleSpecificInfoAsync(string attribName, string attribValue)
        {
            var xmlTelemetry = (await Library.Telemetry.InstanceAsync)
                                    .XmlTelemetry;
            var telemetryNode = xmlTelemetry.DocumentElement.GetElementsByTagName(ModuleName)[0] as XmlElement;
            telemetryNode.SetAttribute(attribName, attribValue);
        }
    }
}
