# Check for Subscription

Intended for use as an Azure DevOps Environment Gate.

This is a PowerShell Azure Function that checks to see if an Azure Subscription is available. If it is, then the *Gate* is returned confirmation to continue to the next stage.

## Prerequisites

The Azure Function uses a system assigned managed identity. This identity needs a role assignment made at the management group level in order to have visibility of created subscriptions.

## Instructions

TODO.

### Azure DevOps Approval Gate

#### The success criteria

For a really simple check, on whether the subscription was found, use this formula to check for *Subscription Found*.
```
eq(root['subfound'], 'true')
```

For a more advanced check, based on *Subscription Tag value*
```
eq(jsonpath('$.tags.Readiness'), 'Ready')
```

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://ms.portal.azure.com/?feature.customportal=false#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FGordonby%2Fazure-check-for-subscription%2Fmain%2Farm%2Farm-deploy-functionapp-wResourceGroup.json)
