# PR 34 — HashiCorp AzureRM: Application Insights JS source-map blob URL

**Company:** HashiCorp (Azure provider — critical Azure IaC surface)  
**Issue:** https://github.com/hashicorp/terraform-provider-azurerm/issues/13255  
**Impact (profound):** Teams cannot configure Application Insights **JavaScript source map blob storage** via Terraform. Without it, production minified JS stack traces stay opaque in App Insights — a real observability gap. Workarounds via magic tags are fragile and undocumented as first-class IaC.  
**Resource:** `azurerm_application_insights` (service/application-insights)

## Claim
I'll take this — adding first-class support for the JS source-map storage container URL on `azurerm_application_insights` (replacing the brittle hidden-link tag workaround).

## Approach
1. Confirm Azure API / portal property for Insights source-map storage (hidden-link tag `Insights.Sourcemap.Storage` JSON `Uri` is the known workaround).
2. Add schema field (e.g. `javascript_source_map_storage_uri` or nested block) on `azurerm_application_insights`.
3. Wire create/update/read in the Go resource; document in website docs; acceptance test if credentials available (otherwise unit + docs).
4. Follow azurerm contributing + CLA.

## Competing PRs
None open when drafted (issue still labeled good first issue / enhancement).
