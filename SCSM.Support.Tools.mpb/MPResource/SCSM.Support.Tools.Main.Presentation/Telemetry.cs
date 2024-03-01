using SCSM.Support.Tools.Library;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SCSM.Support.Tools.Main.Presentation
{
    class Telemetry : TelemetrySingletonBaseForModules<Telemetry>
    {
        /// <summary>
        /// derived static ctor. Not required to declare, but can used if necessary
        /// </summary>
        static Telemetry() { }

        /// <summary>
        /// derived instance ctor. Not required to declare, but can used if necessary
        /// </summary>
        public Telemetry() { }

        /// <summary>
        /// set the Internal name of the Module (aka Tool). This will be the node name in the Telemetry xml
        /// </summary>
        protected override string ModuleName { get { return "Main"; } }

        /// <summary>
        /// you CAN use this method for doing "Module (=Main)" (not "module common") specific telemetry stuff. 
        /// if this override is absent, then the base.virtual method will run (if called somewhere in base class)
        /// </summary>
        /// <returns></returns>
        protected override async Task InitializeModuleSpecificCommonTelemetryInfo()
        {
            // before "module common" stuff can be made here
            //...

            //"module common" can be called or even bypassed when commented (= not called)
            await base.InitializeModuleSpecificCommonTelemetryInfo();

            // after "module common" stuff can be made here
            //...
        }


    }
}
