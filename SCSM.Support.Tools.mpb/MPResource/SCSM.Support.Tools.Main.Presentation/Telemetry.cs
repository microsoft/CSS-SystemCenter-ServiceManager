using SCSM.Support.Tools.Library;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SCSM.Support.Tools.Main.Presentation
{
    class Telemetry : TelemetrySingletonBase<Telemetry>
    {
        protected override string ModuleName { get { return "Main"; } }        
    }
}
