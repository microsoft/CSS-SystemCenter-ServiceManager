using SCSM.Support.Tools.Library;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;

namespace SCSM.Support.Tools.Main.Presentation
{
    class Telemetry : TelemetryBaseForModules
    {
        protected override string ModuleName { get { return "Main"; } }

        Telemetry() { }
        static readonly Lazy<Task<Telemetry>> lazyInstance = new Lazy<Task<Telemetry>>(async () =>
        {
            var instance = new Telemetry();
            await instance.InitializeAsync();
            return instance;
        });
        static Task<Telemetry> InstanceAsync()
        {
            return lazyInstance.Value;
        }
        protected override async Task InitializeAsync()
        {
            await base.InitializeAsync();
            //todo: optional. if anything else needed to add to Main node initially this can be done here...
        }
        public static new async void SendAsync(string operationType, Dictionary<string, string> props)
        {
            try
            {
                await
                    (await InstanceAsync())
                    ._SendAsync(operationType, props);
            }
            catch (Exception ex)
            {
                Helpers.OnlyLogException(ex);
            }
        }
        public static new async void SetModuleSpecificInfoAsync(string attribName, string attribValue)
        {
            try
            {
                await 
                    (await InstanceAsync())
                    ._SetModuleSpecificInfoAsync(attribName, attribValue);
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
        async Task _SetModuleSpecificInfoAsync(string attribName, string attribValue)
        {
            await base.SetModuleSpecificInfoAsync(attribName, attribValue);
        }
    }
}
