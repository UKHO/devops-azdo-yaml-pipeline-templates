# Azure DevOps YAML Pipeline Templates

This repository is for centralised reusable Azure DevOps (AzDO) YAML pipeline templates. The goal of these templates is to provide consistent, compliant, and well-designed pipelines for the building, testing, and deploying of software to Azure.

This repository follows [Semantic Versioning 2.0.0](https://semver.org/).

## Using the templates

To reference these templates in your repository, you will require a resource block:

```yml
resources:
  repositories:
    - repository: AzDOPipelineTemplates                 # 'PipelineTemplates' has commonly been used for https://github.com/UKHO/devops-pipelinetemplates
      type: github
      endpoint: UKHO                                    # this endpoint needs defining in your AzDO Project as a service connection to GitHub
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: refs/tags/0.0.0                              # Do consult the https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/releases for the latest version
```

Once referenced, you will be able to make use of any templates in this repository. This repository follows a 'set-menu with salad bar' approach to the availability of its templates.

- Set-Menu: These are pipeline templates that can be used out of the box; these are intended to cover the majority of use cases
- Salad bar: These are all the templates involved that make up the pipeline templates; these are intended for those with special use cases and require a custom pipeline using standard templates

For the former, there is extensive documentation with examples, see [user docs](docs/user-docs/README.md). For the latter, the templates themselves are self-documenting, see the directories: [tasks](tasks), [jobs](jobs), [stages](stages), [scripts](scripts).

## Contributing to the templates

Contributions are welcome, these templates are not possible without community support. Please see [contributing](./CONTRIBUTING.md).
