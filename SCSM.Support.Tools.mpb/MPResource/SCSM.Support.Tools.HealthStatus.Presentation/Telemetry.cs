using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Xml;
using SCSM.Support.Tools.Library;

namespace SCSM.Support.Tools.HealthStatus.Presentation
{
    class Telemetry : TelemetryBaseForModules
    {
        protected override string ModuleName { get { return "HealthStatus"; } }

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
            //todo: some other attribs could be set initially like below. Then, if they change later then be set wtih SetModuleSpecificInfoAsync....
            // subscriptionMPCreated At
            // subscriptionExists
            // Recipient is set in subscription

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
