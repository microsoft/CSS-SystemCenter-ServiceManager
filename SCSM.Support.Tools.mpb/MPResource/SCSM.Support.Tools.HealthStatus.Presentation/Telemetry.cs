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
       
        protected override string ModuleName { get { return "HealthStatus"; } }

        protected override async Task InitializeAsync()
        {
            await base.InitializeAsync();
            //todo: some other attribs could be set initially like below. Then, if they change later then be set wtih SetModuleSpecificInfoAsync....
            // subscriptionMPCreated At
            // subscriptionExists
            // Recipient is set in subscription

        }        
    }
}
