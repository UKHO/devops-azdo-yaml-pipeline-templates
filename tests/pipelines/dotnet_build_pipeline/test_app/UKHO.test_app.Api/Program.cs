using UKHO.test_app.Api.Extensions;
using UKHO.test_app.Api.Options;

const string specifiedOriginPolicy = "SpecifiedOrigin";

var builder = WebApplication.CreateBuilder(args);

/* Use Settings */
builder.Services.AddOptions<CorsOptions>()
    .Bind(builder.Configuration.GetSection("Cors"))
    .ValidateDataAnnotations()
    .ValidateOnStart();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

if (builder.Environment.IsProduction())
{
    builder.Services.AddAllElasticApm();
    builder.Services.AddDebugAndEventHubLogging(builder.Configuration);
}

/*Configure Cors and Restrictions as Required*/
builder.Services.AddCors(options =>
{
    var corsOptions = builder.Configuration.GetSection("Cors").Get<CorsOptions>();
    options.AddPolicy(name: specifiedOriginPolicy,
                          policy =>
                          {
                            policy.WithOrigins(corsOptions.AllowedOrigins)
                                .WithExposedHeaders(corsOptions.AllowedHeaders)
                                .WithMethods(corsOptions.AllowedMethods);
                          });
});

var app = builder.Build();
app.UseCors(specifiedOriginPolicy);
app.UseSwaggerInDevelopment();
app.UseHttpsRedirection();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot",
    "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
    {
        var forecast = Enumerable.Range(1, 5).Select(index =>
                new WeatherForecast
                (
                    DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                    Random.Shared.Next(-20, 55),
                    summaries[Random.Shared.Next(summaries.Length)]
                ))
            .ToArray();
        return forecast;
    })
    .WithName("GetWeatherForecast")
    .WithOpenApi();

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}