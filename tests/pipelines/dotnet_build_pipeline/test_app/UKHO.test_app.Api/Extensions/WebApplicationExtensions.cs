namespace UKHO.test_app.Api.Extensions;

public static class WebApplicationExtensions
{
    internal static void UseSwaggerInDevelopment(this WebApplication self)
    {
        if (self.Environment.IsDevelopment())
        {
            self.UseSwagger();
            self.UseSwaggerUI();
        }
    }
}