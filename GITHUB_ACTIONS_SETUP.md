# GitHub Actions Setup Guide

## Overview

This workflow automates VM deployment using GitHub Actions with the same Terraform + Ansible approach.

---

## Prerequisites

### 1. GitHub Repository

Push your code to GitHub:

```powershell
cd "C:\Users\chris.hess\OneDrive - HUB International Limited\Documents\GitHub\vm-iac-recovery"

# Initialize git (if not already done)
git init
git add .
git commit -m "Initial commit: IaC VM recovery with Terraform and Ansible"

# Create repository on GitHub (https://github.com/new)
# Then add remote and push:
git remote add origin https://github.com/<your-username>/vm-iac-recovery.git
git branch -M main
git push -u origin main
```

---

## GitHub Configuration

### Step 1: Create Azure Service Principal

You need Azure credentials for GitHub Actions to authenticate:

```powershell
# Login to Azure
az login

# Get subscription ID
az account show --query id -o tsv

# Create service principal with Contributor role on resource group
az ad sp create-for-rbac \
  --name "github-actions-vm-iac" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/viu-itsm-eastus2-rg \
  --sdk-auth
```

**Copy the entire JSON output** - you'll need it for GitHub secrets.

Example output:
```json
{
  "clientId": "xxxxx-xxxxx-xxxxx-xxxxx",
  "clientSecret": "xxxxx-xxxxx-xxxxx-xxxxx",
  "subscriptionId": "f63f9a17-0d56-454f-9b5e-f270a13f9858",
  "tenantId": "xxxxx-xxxxx-xxxxx-xxxxx",
  ...
}
```

---

### Step 2: Add Secrets to GitHub

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add these secrets:

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `AZURE_CREDENTIALS` | JSON from service principal creation | Output from `az ad sp create-for-rbac` |
| `SSH_PUBLIC_KEY` | Your SSH public key | `Get-Content $env:USERPROFILE\.ssh\id_rsa.pub` |
| `SSH_PRIVATE_KEY` | Your SSH private key | `Get-Content $env:USERPROFILE\.ssh\id_rsa` |
| `DYNATRACE_TENANT_TOKEN` | Dynatrace PaaS token | From Dynatrace console |
| `DYNATRACE_API_TOKEN` | Dynatrace API token | From Dynatrace console |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | Choose a secure password |
| `MYSQL_PASSWORD` | MySQL app password | Choose a secure password |

**For each secret:**
- Click **New repository secret**
- Name: (from table above)
- Value: (paste the value)
- Click **Add secret**

---

## Running the Workflow

### Option 1: Manual Trigger (Recommended for Testing)

1. Go to **Actions** tab in GitHub
2. Click **Deploy VM Infrastructure** workflow
3. Click **Run workflow**
4. Select branch: `main`
5. Environment: `test`
6. Destroy after: `false` (or `true` to auto-cleanup)
7. Click **Run workflow**

### Option 2: Automatic Trigger (on Git Push)

```powershell
cd "C:\Users\chris.hess\OneDrive - HUB International Limited\Documents\GitHub\vm-iac-recovery"

# Make a change
echo "# Update" >> README.md

# Commit and push
git add .
git commit -m "Trigger deployment"
git push origin main
```

The workflow automatically runs when you push changes to `terraform/`, `ansible/`, or workflow files.

---

## Workflow Stages

### 1. **Terraform** (3-5 minutes)
- Provisions VM infrastructure
- Captures VM IP and name as outputs

### 2. **Wait for VM** (1-3 minutes)
- Polls SSH connectivity
- Ensures VM is fully booted

### 3. **Ansible** (15-20 minutes)
- Configures base system
- Installs Docker and k3s
- Deploys Dynatrace
- Deploys all applications

### 4. **Verify**
- Checks k3s version
- Lists all pods
- Displays deployments

### 5. **Destroy** (optional)
- Only runs if manual trigger with destroy=true
- Requires environment approval
- Tears down infrastructure

---

## Monitoring Workflow Execution

1. Go to **Actions** tab
2. Click on the running workflow
3. See real-time logs for each job
4. Click on individual steps to see details

### View Logs
- Green checkmark ✅ = Success
- Red X ❌ = Failed
- Yellow dot 🟡 = In progress

---

## Advanced Configuration

### Add Slack Notifications

Install Slack GitHub app, then add to workflow:

```yaml
- name: Notify Slack
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "VM Deployment Failed: ${{ github.repository }}"
      }
```

### Add Approval for Destroy

Create a GitHub Environment:
1. **Settings** → **Environments**
2. Click **New environment**
3. Name: `destruction-approval`
4. Add **Required reviewers** (your email)
5. Click **Save**

Now destroy jobs require manual approval.

### Cache Terraform Providers

Speed up runs by caching:

```yaml
- name: Cache Terraform
  uses: actions/cache@v3
  with:
    path: terraform/environments/test/.terraform
    key: terraform-${{ hashFiles('**/*.tf') }}
```

---

## Troubleshooting

### Azure Login Fails
- Verify `AZURE_CREDENTIALS` secret contains valid JSON
- Check service principal has permissions on resource group
- Try: `az login --service-principal --username <clientId> --password <clientSecret> --tenant <tenantId>`

### Terraform Backend Fails
- Ensure storage account exists
- Verify service principal has "Storage Blob Data Contributor" role
- Check firewall rules on storage account

### SSH Connection Fails
- Verify `SSH_PRIVATE_KEY` includes header/footer:
  ```
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...key content...
  -----END OPENSSH PRIVATE KEY-----
  ```
- Check NSG allows SSH from GitHub Actions IPs
- Verify public key in terraform.tfvars matches private key

### Ansible Fails
- Check all secrets are populated in GitHub
- Verify Dynatrace tokens have correct scopes
- Review Ansible logs in workflow output

---

## GitHub vs Azure DevOps Secrets

### GitHub Secrets
- Repository → Settings → Secrets and variables → Actions
- Organization-level secrets available
- Encrypted at rest
- Masked in logs

### Azure DevOps Variable Groups
- Pipelines → Library → Variable groups
- Can link to Azure Key Vault
- Project or organization scope
- Secret variables locked

---

## Cost Considerations

### GitHub Actions Minutes

**Free tier:**
- Public repos: Unlimited
- Private repos: 2,000 minutes/month (GitHub Free)
- Private repos: 3,000 minutes/month (GitHub Pro)

**This pipeline uses:** ~25 minutes per run
- Free tier: 80 runs/month (Free), 120 runs/month (Pro)

### Azure DevOps Minutes

**Free tier:**
- 1,800 minutes/month (Microsoft-hosted)
- Unlimited (self-hosted agents)

**This pipeline uses:** ~25 minutes per run
- Free tier: 72 runs/month

---

## What's Included

✅ **Workflow file** - `.github/workflows/deploy-vm.yml`  
✅ **Manual trigger** - Run on demand with parameters  
✅ **Auto trigger** - Run on push to main  
✅ **Multi-job** - Terraform → Wait → Ansible → Verify  
✅ **Outputs** - VM IP passed between jobs  
✅ **Destroy option** - Optional cleanup with approval  

---

## Next Steps

1. **Push code to GitHub**
2. **Create service principal** for Azure auth
3. **Add secrets to GitHub** repository
4. **Run the workflow** manually first
5. **Verify deployment** completes successfully
6. **Set up auto-trigger** for continuous deployment

---

**Ready to push to GitHub and set up the secrets?**

Or would you like to focus on **Azure DevOps** first and do GitHub Actions later?
