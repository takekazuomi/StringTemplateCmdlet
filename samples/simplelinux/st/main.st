import "parameters.stg"
import "variables.stg"
import "resources.stg"
import "outputs.stg"

main(config) ::= <<
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    <parameters(config.parameters)>
  },
  "variables": {
    <variables(config.variables)>
  },
  "resources": [
    <resources(config.resources)>
  ],
  "outputs": {
    <outputs(config.outputs)>
  }
}
>>
