using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;

namespace SCSM.Support.Tools.Library
{
    public abstract class TelemetryBaseForModules
    {
        protected abstract string ModuleName { get; }

        protected virtual async Task InitializeAsync()
        {
            var xmlTelemetry = (await Library.Telemetry.InstanceAsync()).XmlTelemetry;
            var telemetryNode = xmlTelemetry.DocumentElement.AppendChild(xmlTelemetry.CreateNode(XmlNodeType.Element, ModuleName, null)) as XmlElement;
            telemetryNode.SetAttribute("PresentationVersion", Helpers.GetModuleVersion(string.Format("SCSM.Support.Tools.{0}.Presentation.dll", ModuleName)));
        }
        protected virtual async Task SendAsync(string operationType, Dictionary<string, string> props)
        {
            await
                (await Library.Telemetry.InstanceAsync())
                .SendAsync(
                    moduleName: ModuleName,
                    operationType: operationType,
                    props: props
                );
        }
        protected virtual async Task SetModuleSpecificInfoAsync(string attribName, string attribValue)
        {
            var xmlTelemetry = (await Library.Telemetry.InstanceAsync())
                                    .XmlTelemetry;
            var telemetryNode = xmlTelemetry.DocumentElement.GetElementsByTagName(ModuleName)[0] as XmlElement;
            telemetryNode.SetAttribute(attribName, attribValue);
        }
    }
}
