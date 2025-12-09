using System.ComponentModel.DataAnnotations;
using UKHO.test_app.Api.Attributes;

namespace UKHO.test_app.Api.Options;

public class CorsOptions
{
    [Required]
    [CorsOption(@"^(http|https)://.*", ErrorMessage = "Invalid values: {0}")]
    public string[] AllowedOrigins { get; set; } = [];
    
    public string[] AllowedHeaders { get; set; } = [];
    
    [Required]
    [CorsOption(@"^(GET|POST|PUT|DELETE|OPTIONS)$", ErrorMessage = "Invalid values: {0}")]
    public string[] AllowedMethods { get; set; } = [];
}