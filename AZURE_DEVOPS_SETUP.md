# Azure DevOps Pipeline Setup Guide

## Overview

This pipeline automates the complete VM deployment:
1. **Terraform** - Provisions Azure VM infrastructure
2. **Wait** - Ensures SSH connectivity
3. **Ansible** - Configures VM and deploys applications
4. **Verify** - Validates deployment success
5. **Destroy** (optional) - Manual approval to tear down

---

## Prerequisites

### 1. Azure DevOps Organization Access

You need access to an Azure DevOps organization. Check if HUB has one:
- Visit: https://dev.azure.com/hubinternational (or similar)
- Or create your own: https://dev.azure.com

### 2. Create Azure DevOps Project

1. Go to Azure DevOps
2. Click **+ New Project**
3. Name: `VM-IaC-Recovery`
4. Visibility: Private
5. Click **Create**

### 3. Create Azure Repos Repository

**Option A: Import from Local**
1. In your project, go to **Repos**
2. Click **Import a repository**
3. Clone type: Git
4. Or manually push your code:

```powershell
cd "C:\Users\chris.hess\OneDrive - HUB International Limited\Documents\GitHub\vm-iac-recovery"

# Initialize git if not done
git init
git add .
git commit -m "Initial commit: Terraform + Ansible for VM recovery"

# Add Azure DevOps remote
git remote add origin https://dev.azure.com/<your-org>/<your-project>/_git/vm-iac-recovery

# Push
git push -u origin main
```

**Option B: Use GitHub Mirror**
1. Keep code in GitHub
2. Set up Azure DevOps to sync from GitHub
3. Pipeline runs from Azure DevOps, code stays in GitHub

---

## Azure DevOps Configuration

### Step 1: Create Service Connection to Azure

1. Go to **Project Settings** (bottom left)
2. Click **Service connections**
3. Click **New service connection**
4. Select **Azure Resource Manager**
5. Authentication method: **Service principal (automatic)**
6. Scope level: **Subscription**
7. Subscription: Select your Azure subscription
8. Resource group: `viu-itsm-eastus2-rg` (or leave empty for subscription)
9. Service connection name: `Azure-Service-Connection`
10. Check **Grant access permission to all pipelines**
11. Click **Save**

**IMPORTANT:** Note the service connection name - update it in `azure-pipelines.yml` line 87 and 158.

---

### Step 2: Create Variable Group for Secrets

1. Go to **Pipelines** → **Library**
2. Click **+ Variable group**
3. Name: `vm-iac-secrets`
4. Add these variables (click **+ Add** for each):

| Variable Name | Value | Secret? |
|---------------|-------|---------|
| `SSH_PUBLIC_KEY` | Your SSH public key content | No |
| `SSH_PRIVATE_KEY` | Your SSH private key content | ✅ Yes |
| `DYNATRACE_API_TOKEN` | Your Dynatrace API token | ✅ Yes |
| `DYNATRACE_TENANT_TOKEN` | Your Dynatrace PaaS token | ✅ Yes |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | ✅ Yes |
| `MYSQL_PASSWORD` | MySQL app password | ✅ Yes |

**To get your SSH keys:**

```powershell
# Public key
Get-Content $env:USERPROFILE\.ssh\id_rsa.pub

# Private key (mark as secret in Azure DevOps)
Get-Content $env:USERPROFILE\.ssh\id_rsa
```

5. Click **Save**

---

### Step 3: Create Pipeline

1. Go to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git** (or GitHub if using mirror)
4. Select your repository: `vm-iac-recovery`
5. Select **Existing Azure Pipelines YAML file**
6. Path: `/azure-pipelines.yml`
7. Click **Continue**
8. Review the pipeline
9. Click **Run**

---

## Pipeline Stages Explained

### Stage 1: Terraform
- **TerraformPlan** - Validates and plans infrastructure changes
- **TerraformApply** - Provisions the VM
- **Outputs** - Captures VM IP address and name

### Stage 2: WaitForVM
- Polls SSH connectivity (30 attempts, 10 sec intervals)
- Ensures VM is fully booted before Ansible runs

### Stage 3: Ansible
- **Install Ansible** - Sets up Ansible on the agent
- **Prepare Environment** - Creates dynamic inventory with VM IP
- **Test Connection** - Verifies SSH connectivity
- **Deploy Base** - Runs base-system, docker, k3s roles
- **Deploy Dynatrace** - Installs OneAgent and ActiveGate
- **Deploy Apps** - Deploys MySQL, Flask, generators
- **Verify** - Checks all pods are running

### Stage 4: Destroy (Optional)
- Manual approval required
- Runs `terraform destroy`
- Only runs if triggered manually

---

## Running the Pipeline

### Manual Run

1. Go to **Pipelines** → **Pipelines**
2. Select your pipeline
3. Click **Run pipeline**
4. Select branch: `main`
5. Click **Run**

### Automatic Run (on Git Push)

```powershell
cd "C:\Users\chris.hess\OneDrive - HUB International Limited\Documents\GitHub\vm-iac-recovery"

# Make a change
echo "# Update" >> README.md

# Commit and push
git add .
git commit -m "Update configuration"
git push origin main
```

The pipeline will automatically trigger.

---

## Monitoring Pipeline Execution

1. Click on the running pipeline
2. View stages and jobs in real-time
3. Click on any task to see detailed logs
4. Download logs for troubleshooting

### Expected Timeline
- **Terraform** - 3-5 minutes
- **Wait for VM** - 1-3 minutes
- **Ansible** - 15-20 minutes
- **Total** - ~25 minutes

---

## Troubleshooting

### Service Connection Fails
- Verify service principal has Contributor role on resource group
- Check subscription is correct
- Ensure service connection name matches pipeline YAML

### SSH Connection Fails
- Verify SSH_PRIVATE_KEY is correct (entire key including headers)
- Check NSG rules allow SSH (port 22)
- Verify VM has public IP

### Terraform Backend Fails
- Ensure storage account exists: `viutfstate001`
- Verify container exists: `tfstate`
- Check service principal has Storage Blob Data Contributor role

### Ansible Fails
- Check variable group `vm-iac-secrets` exists
- Verify all secrets are populated
- Check Dynatrace tokens have correct scopes

### Variables Not Passing Between Stages
- Ensure output variables use correct syntax: `##vso[task.setvariable...]`
- Check dependencies between stages

---

## Advanced Features

### Run Specific Stages Only

Edit the pipeline run and select stages to run:
- Run only Terraform (skip Ansible)
- Run only Ansible (if VM already exists)

### Parallel Deployments

Modify to deploy multiple environments:
```yaml
strategy:
  matrix:
    test:
      environment: 'test'
    staging:
      environment: 'staging'
```

### Notifications

Add email/Slack notifications on success/failure:
```yaml
- task: SendEmail@1
  condition: failed()
  inputs:
    to: 'your-email@hubinternational.com'
    subject: 'VM Deployment Failed'
```

---

## Security Best Practices

1. ✅ **Use variable groups** for secrets (not hardcoded)
2. ✅ **Mark sensitive variables** as secret (locks icon)
3. ✅ **Limit service connection** to specific resource group
4. ✅ **Use SSH keys** (not passwords)
5. ✅ **Enable approval gates** for production deployments

---

## Cost Management

### Destroy Test VMs When Not Needed

Run the pipeline with destroy stage:
1. **Pipelines** → Select pipeline → **Run pipeline**
2. **Stages to run** → Select **Destroy**
3. Approve the manual intervention
4. VM is destroyed, saving ~$100/month

### Automated Cleanup

Add a scheduled destroy (weekends):
```yaml
schedules:
  - cron: "0 18 * * 5"  # Every Friday at 6 PM
    displayName: Weekend cleanup
    branches:
      include:
        - main
    always: false
```

---

## What's Next?

After pipeline is configured:

1. **Test the full pipeline** - Deploy from scratch
2. **Verify all applications** work
3. **Test disaster recovery** - Destroy and redeploy
4. **Document for team** - Share access and procedures
5. **Create production environment** - Clone for prod deployment

---

## Comparison: Azure DevOps vs GitHub Actions

**Azure DevOps Advantages:**
- ✅ Native Azure integration (service connections)
- ✅ Visual pipeline designer
- ✅ Built-in artifact management
- ✅ Advanced approval workflows
- ✅ Better for enterprise governance

**GitHub Actions Advantages:**
- ✅ Simpler YAML syntax
- ✅ Larger marketplace
- ✅ Better for open-source
- ✅ Integrated with GitHub features

**For your use case:** Azure DevOps is excellent because:
1. You're 100% in Azure
2. Likely corporate standard
3. Better compliance/audit trails
4. Native service principal integration

---

## Next Steps

1. **Create Azure DevOps project**
2. **Push code to Azure Repos**
3. **Configure service connection**
4. **Create variable group**
5. **Run the pipeline**

**Do you have access to an Azure DevOps organization, or do you need help creating one?**
