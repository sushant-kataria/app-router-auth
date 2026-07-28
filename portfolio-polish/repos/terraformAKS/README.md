# Terraform AKS

Provisions an **Azure Kubernetes Service** stack with supporting resources via Terraform modules and Azure Pipelines.

## What gets created

- Resource group
- Azure Container Registry (ACR)
- Virtual network + subnets
- AKS cluster (system + user node pools)

Modules are sourced from Bitbucket (`azure-aks-modules`). Variables live in `variables.tf` / `terraform.tfvars`; remote state settings in `backend.conf`.

## Usage

```bash
terraform init -backend-config=backend.conf
terraform plan
terraform apply
```

CI/CD: see `azure-pipelines.yml` and `.pipelines/`.

## Requirements

- Azure subscription + service principal for pipelines
- Access to the Bitbucket module source referenced in `main.tf`
- Terraform CLI compatible with `versions.tf`

## Note

Draft PR #1 that replaces this repo with an unrelated PageAgent UI should **not** be merged into this infrastructure project.
