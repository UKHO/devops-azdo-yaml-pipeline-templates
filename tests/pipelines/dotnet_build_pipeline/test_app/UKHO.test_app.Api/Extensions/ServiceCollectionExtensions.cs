using UKHO.Logging.EventHubLogProvider;

namespace UKHO.test_app.Api.Extensions;

internal static class ServiceCollectionExtensions
{
    public static void AddDebugAndEventHubLogging(
        this IServiceCollection services, IConfiguration configuration)
    {
        services.AddLogging(loggingBuilder =>
        {
            loggingBuilder.AddConfiguration(
                configuration.GetSection("Logging"));
            loggingBuilder.AddDebug();
            loggingBuilder.AddEventHub(options =>
                configuration.Bind("EventHubLoggingConfiguration", options));
        });
    }
}