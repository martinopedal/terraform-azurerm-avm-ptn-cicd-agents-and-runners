# Third-Party Notices

This module **is itself** an [Azure Verified Modules (AVM)](https://aka.ms/avm) pattern module,
built and maintained following the AVM specification. It also depends on the Terraform providers
and AVM modules listed below.

---

## Azure Verified Modules (AVM)

- **Specification & Guidelines:** https://aka.ms/avm
- **Contributors:** Microsoft Corporation and AVM community contributors
- **Source:** https://github.com/Azure/terraform-azurerm-avm-*
- **Registry:** https://registry.terraform.io/namespaces/Azure
- **License:** MIT License

All AVM modules sourced via `source = "Azure/..."` in `registry.terraform.io` are
MIT-licensed by Microsoft Corporation and contributors. Modules are downloaded at
`terraform init` time and are not bundled in this repository.

### AVM modules used by this module

| Module source | Version | Description |
|---|---|---|
| `Azure/avm-res-network-virtualnetwork/azurerm` | 0.17.1 | Virtual Network |
| `Azure/avm-res-operationalinsights-workspace/azurerm` | 0.5.1 | Log Analytics Workspace |
| `Azure/avm-res-managedidentity-userassignedidentity/azurerm` | 0.5.0 | User Assigned Managed Identity |
| `Azure/naming/azurerm` | 0.4.2 | Azure naming convention helper *(examples only)* |
| `Azure/avm-utl-regions/azurerm` | 0.3.0 | Azure regions utility *(examples only)* |

---

## HashiCorp Terraform Providers

- **azurerm provider:** https://github.com/hashicorp/terraform-provider-azurerm — MPL-2.0
- **azapi provider:** https://github.com/Azure/terraform-provider-azapi — MPL-2.0
- **modtm provider:** https://github.com/Azure/terraform-provider-modtm — MIT
- **random provider:** https://github.com/hashicorp/terraform-provider-random — MPL-2.0
- **time provider:** https://github.com/hashicorp/terraform-provider-time — MPL-2.0
- **Providers are downloaded at `terraform init` time and are not bundled in this repository.**

> **Note on MPL-2.0:** The Mozilla Public License 2.0 is a weak copyleft license that applies
> only to the provider source files themselves, not to Terraform configurations that use the
> provider. Using these providers in your Terraform code does not impose any license requirements
> on your own configuration code.

---

## AVM Specification

- **Source:** https://azure.github.io/Azure-Verified-Modules/
- **Copyright:** Copyright (c) Microsoft Corporation
- **License:** MIT License