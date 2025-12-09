using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace UKHO.test_app.Api.Attributes;

public sealed class CorsOptionAttribute(string pattern) : ValidationAttribute
{
    protected override ValidationResult IsValid(object? value, ValidationContext validationContext)
    {
        if (value is not string[] options)
        {
            throw new NotSupportedException("Unexpected object type");
        }

        var regex = new Regex(pattern, RegexOptions.None, TimeSpan.FromMilliseconds(1000));
        ErrorMessage = string.Empty;
        var errorMessage = options.Where(item => !regex.IsMatch(item)).Aggregate(string.Empty, (current, item) => current + ErrorMessage.Replace("{0}", item));
        var validationResult = new ValidationResult(errorMessage);

        return (!string.IsNullOrEmpty(validationResult.ErrorMessage) ? validationResult : ValidationResult.Success)!;
    }
}