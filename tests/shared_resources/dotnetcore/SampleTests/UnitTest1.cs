namespace SampleTests;

public class Tests
{
  [Test, Category("Unit")]
  public void FormatsGreeting()
  {
    Assert.That(Greeting.For("Ada"), Is.EqualTo("Hello, Ada!"));
  }

  [Test, Category("Integration")]
  public void OutputContainsTheGreeting()
  {
    using var output = new StringWriter();
    output.WriteLine(Greeting.For("CI"));
    Assert.That(output.ToString().TrimEnd(), Is.EqualTo("Hello, CI!"));
  }
}
