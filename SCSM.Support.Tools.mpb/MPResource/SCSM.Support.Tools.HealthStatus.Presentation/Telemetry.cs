using SCSM.Support.Tools.Library;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SCSM.Support.Tools.HealthStatus.Presentation
{
    class Telemetry : TelemetrySingletonBaseForModules<Telemetry>
    {
        public Telemetry() { }

        protected override string ModuleName { get { return "HealthStatus"; } }
        protected override async Task InitializeModuleSpecificCommonTelemetryInfo()
        {
            await base.InitializeModuleSpecificCommonTelemetryInfo();

            Info.SetSubscriptionSpecificTelemetryInfoAsync();
        }
       
}
}
