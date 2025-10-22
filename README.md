# VM Infrastructure as Code Recovery Project

This project provides automated disaster recovery for the Ubuntu VM running k3s, MySQL, Flask apps, and Dynatrace.

## Project Structure

```
vm-iac-recovery/
├── terraform/
│   ├── modules/
│   │   └── vm/           # Reusable VM module
│   └── environments/
│       └── test/         # Test environment configuration
├── ansible/
│   └── roles/            # Configuration management roles (Phase 3)
├── .github/
│   └── workflows/        # CI/CD pipelines (Phase 4)
└── README.md
```

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** >= 1.0 installed
3. **SSH Key Pair** at `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`
4. **Azure Storage Account** for Terraform state

## Phase 1: Completed ✓
- Discovery script executed on existing VM
- Configuration data extracted
- Network and service details documented

## Phase 2: Terraform Setup (Current Phase)

### Step 1: Create Azure Storage Account for Terraform State

```powershell
# Login to Azure
az login

# Create storage account (use a unique name)
az storage account create `
  --name viutfstate001 `
  --resource-group viu-itsm-eastus2-rg `
  --location eastus2 `
  --sku Standard_LRS `
  --kind StorageV2

# Create container for Terraform state
az storage container create `
  --name tfstate `
  --account-name viutfstate001
```

### Step 2: Initialize Terraform

```powershell
cd terraform/environments/test

# Initialize Terraform (downloads providers and sets up backend)
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan
```

### Step 3: Deploy Test VM

```powershell
# Apply the configuration
terraform apply

# Note the outputs (VM IP address, SSH command)
terraform output
```

## Current VM Configuration

- **VM Size**: Standard_B4as_v2
- **OS**: Ubuntu 22.04 LTS
- **Location**: East US 2 (Zone 1)
- **Resource Group**: viu-itsm-eastus2-rg
- **VNet**: vnet-showcase
- **Subnet**: snet-general
- **OS Disk**: 30GB Premium_LRS

## Applications Running

- **k3s** (Kubernetes)
- **MySQL** (in k3s with persistent volumes)
- **Flask applications** (in k3s namespace: flask-app)
- **Dynatrace OneAgent** (monitoring)
- **Dynatrace ActiveGate** (data forwarding)
- **MySQL Order Generator** (data generation service)
- **MySQL-to-SQL Server Sync** (CDC service)

## Next Steps

- **Phase 3**: Create Ansible playbooks for application configuration
- **Phase 4**: Set up GitHub Actions for automated deployment

## Important Notes

- This test environment uses the name `viu-ubuntu-test-vm` to avoid conflicts
- The production VM is `vm-showcase-01` and should not be modified
- Storage account name in `main.tf` must match the actual created storage account
- SSH public key path assumes `~/.ssh/id_rsa.pub` - update if different

## Troubleshooting

### Terraform Init Fails
- Verify storage account name in `main.tf` matches actual storage account
- Ensure you're logged into Azure: `az login`
- Check network connectivity through corporate firewall

### SSH Key Not Found
- Update `ssh_public_key` path in `terraform/environments/test/main.tf`
- Generate new key pair: `ssh-keygen -t rsa -b 4096`

### VM Deployment Fails
- Check Azure quotas for VM size in region
- Verify subnet has available IP addresses
- Review NSG rules if connectivity issues occur
