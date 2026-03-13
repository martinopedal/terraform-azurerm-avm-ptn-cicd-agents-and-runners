---
description: 'AVM Pattern Module - Self-Hosted CI/CD Agents and Runners'
applyTo: '**/*.tf, **/*.tfvars, **/*.md'
---

# Copilot Instructions - terraform-azurerm-avm-ptn-cicd-agents-and-runners

## What This Module Is

An Azure Verified Module (AVM) pattern module that deploys self-hosted **GitHub Actions Runners** and **Azure DevOps Agents** on Azure using **Container Apps** (KEDA-scaled) or **Container Instances** (static count).

Supports:
- GitHub runners with PAT or GitHub App authentication
- Azure DevOps agents with PAT or UAMI (Managed Identity) authentication
- Private or public networking
- Bring-your-own VNet, DNS zone, NAT Gateway, or let the module create them

## Module Structure

```
.
├── modules/
│   ├── container-app-job/     # ACA Job (KEDA-scaled runner/agent)
│   ├── container-instance/    # ACI (static runner/agent)
│   └── container-registry/    # ACR + image build tasks
├── examples/
│   ├── azure_devops_*/        # Azure DevOps examples (PAT, UAMI, BYO VNet, etc.)
│   ├── github_*/              # GitHub examples (PAT, App auth, BYO VNet, etc.)
│   └── multi_region/          # Multi-region deployment
├── locals.tf                          # Core locals (resource IDs, names, image config)
├── locals.container.app.job.tf        # KEDA metadata, env vars, secrets for GitHub/AzDO
├── locals.container.instance.tf       # ACI env vars and secrets
├── local.virtual.network.tf           # Subnet CIDR calculations
├── main.tf                            # Resource group + lock
├── main.container.app.environment.tf  # ACA Environment
├── main.container.app.job.tf          # Root → container-app-job submodule
├── main.container.instance.tf         # Root → container-instance submodule
├── main.container.registry.tf         # Root → container-registry submodule
├── main.log.analytics.workspace.tf    # Log Analytics (AVM module)
├── main.user.assigned.managed.identity.tf  # UAMI (AVM module)
├── main.virtual.network.tf            # VNet, DNS zones, NAT GW, Public IP
├── main.telemetry.tf                  # AVM telemetry
├── variables.tf                       # Core variables
├── variables.version.control.system.tf    # GitHub/AzDO auth config
├── variables.container.app.tf         # ACA job sizing, scaling, timeouts
├── variables.container.instance.tf    # ACI sizing and count
├── variables.container.registry.tf    # ACR + image build config
├── variables.log.analytics.workspace.tf
├── variables.user.assigned.managed.identity.tf
├── variables.virtual.network.tf       # VNet/subnet/NAT/PIP config
├── outputs.tf
└── terraform.tf
```

## Authentication - Three Separate Layers

Code touches authentication in multiple places. Keep them distinct.

### Layer 1: Terraform → Azure

Handled outside this module. The caller sets `ARM_*` env vars or uses `az login`. This module does not manage it.

### Layer 2: Runner/Agent → VCS Platform

Configured by `version_control_system_authentication_method`. These credentials are stored as Container App secrets and used at runtime by the runner to register and poll for jobs:

- GitHub `pat` → `ACCESS_TOKEN` secret, KEDA uses `personalAccessToken`
- GitHub `github_app` → `APP_PRIVATE_KEY` secret, KEDA uses `appKey` + `applicationID` + `installationID`
- AzDO `pat` → `AZP_TOKEN` secret, KEDA uses `personalAccessToken`
- AzDO `uami` → `AZP_URL` + `USRMI_ID` secrets, KEDA uses `organizationURL` with managed identity

The relevant code paths are in `locals.container.app.job.tf` (for ACA) and `locals.container.instance.tf` (for ACI).

### Layer 3: Runner UAMI → Azure Resources

The UAMI attached to the Container App Job / Container Instance can be used by workflow steps to access Azure resources via RBAC. This module only creates the identity and assigns ACR pull - the caller grants additional roles.

## Compute Types

The `compute_types` variable controls which compute backends are deployed. Values: `azure_container_app`, `azure_container_instance`, or both.

- ACA: event-driven, KEDA-scaled, scales to zero. Uses `modules/container-app-job/`.
- ACI: static count, always running. Uses `modules/container-instance/`.

The `local.deploy_container_app` and `local.deploy_container_instance` booleans gate resource creation throughout the module.

## Networking Modes

The `use_private_networking` variable controls whether resources use private endpoints and internal networking. The `virtual_network_creation_enabled` variable controls whether the module creates the VNet or expects an existing one.

Key combinations:
- `use_private_networking = true` + `virtual_network_creation_enabled = true` - module creates everything
- `use_private_networking = true` + `virtual_network_creation_enabled = false` - BYO VNet, pass subnet IDs
- `use_private_networking = false` - public networking, no VNet needed

## Submodules

### `modules/container-app-job/`

Creates two `Microsoft.App/jobs` resources via `azapi_resource`:
- **Runner job** - event-triggered (KEDA), ephemeral containers
- **Placeholder job** - manual-triggered, keeps a runner registered (AzDO only)

Uses `azapi` (not `azurerm`) for the job resources because the azurerm provider does not support all required features.

### `modules/container-instance/`

Creates `azurerm_container_group` resources for static, always-running agents.

### `modules/container-registry/`

Creates an ACR via the AVM container registry module, plus ACR Tasks that build runner images from the [Azure/avm-container-images-cicd-agents-and-runners](https://github.com/Azure/avm-container-images-cicd-agents-and-runners) repo.

## File Naming Convention

AVM dot-separated pattern:
- `variables.{concern}.tf` - e.g. `variables.container.app.tf`
- `main.{concern}.tf` - e.g. `main.container.registry.tf`
- `locals.{concern}.tf` - e.g. `locals.container.app.job.tf`
- `local.{concern}.tf` - e.g. `local.virtual.network.tf` (singular when single locals block)

## Development Workflow

### Validation

```bash
terraform fmt -recursive
terraform validate

# AVM-specific validation (run before creating PRs)
PORCH_NO_TUI=1 ./avm pre-commit
git add . && git commit -m "chore: avm pre-commit"
PORCH_NO_TUI=1 ./avm pr-check
```

The `avm.ps1` / `avm.bat` scripts run `make` targets inside a Docker container (`mcr.microsoft.com/azterraform:avm-latest`). They handle linting, formatting, and documentation generation.

### Adding a New Example

1. Create a directory under `examples/` with a descriptive name
2. Add `main.tf`, `variables.tf`, and optionally `outputs.tf`
3. Add `_header.md` and `_footer.md` for terraform-docs
4. Add `action.yml` (GitHub) or `pipeline.yml` (AzDO) for CI workflow validation
5. Run `make fmt && make docs` to generate documentation

### Modifying Submodules

Changes to `modules/container-app-job/`, `modules/container-instance/`, or `modules/container-registry/` affect all callers. Wire new submodule variables through the root module's corresponding `main.*.tf` file.

## Key Design Decisions

- Container App Jobs use `azapi_resource` (not `azurerm`) - the azurerm provider lacks support for event-triggered jobs with KEDA scaling rules
- The placeholder job (AzDO only) keeps an agent registered so Azure DevOps sees the pool as online
- GitHub runners are always ephemeral (`EPHEMERAL=true`) - one job per container, then terminate
- Images are built by ACR Tasks, not local Docker - the `context_path` in the image config points to a public GitHub repo
- Zone redundancy requires private networking because `infrastructure_subnet_id` is mandatory for zone-redundant ACA environments

## README Conventions

- The `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers are auto-generated by terraform-docs via `make docs`
- Do not manually edit content between those markers
- Only ✅ and ❌ emojis - no others
- Keep language direct and technical
