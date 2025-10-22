# Ansible Configuration Guide

## Directory Structure Created

```
ansible/
├── site.yml                    # Main playbook
├── inventory/
│   └── hosts.yml              # Inventory file (update with VM IP)
├── vars/
│   ├── main.yml               # Global variables
│   └── secrets.yml            # Sensitive data (encrypt with ansible-vault)
└── roles/
    ├── base-system/           # System preparation
    ├── docker/                # Docker & containerd
    ├── k3s/                   # Kubernetes installation
    ├── dynatrace-oneagent/    # Monitoring agent
    ├── dynatrace-activegate/  # (To be completed)
    └── kubernetes-apps/       # MySQL, Flask apps (To be completed)
```

## Phase 3 Status

### ✅ Completed Files
1. **site.yml** - Main Ansible playbook orchestrating all roles
2. **inventory/hosts.yml** - Inventory with your test VM (74.249.14.98)
3. **vars/main.yml** - Global non-sensitive variables
4. **vars/secrets.yml** - Template for sensitive data (needs your tokens)
5. **roles/base-system** - System preparation and hardening
6. **roles/docker** - Docker and containerd installation
7. **roles/k3s** - k3s Kubernetes installation
8. **roles/dynatrace-oneagent** - Dynatrace monitoring agent

### 🚧 To Be Completed
9. **roles/dynatrace-activegate** - ActiveGate deployment to k3s
10. **roles/kubernetes-apps** - MySQL, Flask, order generators, sync service

## Required Actions Before Running

### 1. Update Secrets File

Edit `ansible/vars/secrets.yml` and replace placeholders:

```yaml
dynatrace_tenant_token: "YOUR_PAAS_TOKEN_HERE"
dynatrace_api_token: "YOUR_API_TOKEN_HERE"  
dynatrace_activegate_token: "YOUR_ACTIVEGATE_TOKEN_HERE"
mysql_root_password: "YourSecurePassword123!"
mysql_password: "YourAppPassword456!"
```

### 2. Encrypt Secrets (Recommended)

```bash
# Create vault password file
echo "your-vault-password" > ~/.ansible-vault-pass

# Encrypt the secrets file
ansible-vault encrypt ansible/vars/secrets.yml --vault-password-file ~/.ansible-vault-pass
```

### 3. Update Inventory

The file `ansible/inventory/hosts.yml` already has your test VM IP (74.249.14.98).
Verify the SSH key path is correct.

### 4. Test Ansible Connection

```bash
cd ansible

# Test connection
ansible -i inventory/hosts.yml ubuntu_vms -m ping

# Expected output:
# test-vm | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

## Running the Playbook

### Full Deployment

```bash
cd ansible

# Run all roles
ansible-playbook -i inventory/hosts.yml site.yml

# If using encrypted secrets:
ansible-playbook -i inventory/hosts.yml site.yml --vault-password-file ~/.ansible-vault-pass
```

### Selective Deployment (Using Tags)

```bash
# Only base system
ansible-playbook -i inventory/hosts.yml site.yml --tags base

# Only k3s
ansible-playbook -i inventory/hosts.yml site.yml --tags k3s

# Only Dynatrace
ansible-playbook -i inventory/hosts.yml site.yml --tags dynatrace

# Multiple tags
ansible-playbook -i inventory/hosts.yml site.yml --tags "base,docker,k3s"
```

## What Each Role Does

### base-system
- Updates all packages
- Installs essential tools (curl, wget, git, vim, etc.)
- Configures timezone and NTP
- Disables swap (required for Kubernetes)
- Loads kernel modules for networking
- Sets sysctl parameters for Kubernetes

### docker
- Adds Docker repository
- Installs Docker CE and containerd
- Configures containerd for k3s compatibility
- Adds azureuser to docker group
- Enables and starts services

### k3s
- Downloads and installs k3s v1.28.5
- Disables Traefik (not needed for your setup)
- Configures kubectl for azureuser
- Creates namespaces: default, mysql, flask-app, dynatrace
- Waits for cluster to be ready

### dynatrace-oneagent
- Downloads OneAgent installer from your tenant (bnh29255)
- Installs with app log access enabled
- Verifies installation and service status

## Next Steps

### Option 1: Complete Remaining Roles First
I can create the dynatrace-activegate and kubernetes-apps roles before you run anything.

### Option 2: Test What We Have
You can run the first 4 roles now to verify they work:

```bash
ansible-playbook -i inventory/hosts.yml site.yml --tags "base,docker,k3s,oneagent"
```

### Option 3: Manual Kubernetes Apps
Deploy k3s now, then manually apply your Kubernetes manifests from the original VM.

## Troubleshooting

### SSH Connection Issues
```bash
# Test SSH directly
ssh -i ~/.ssh/id_rsa azureuser@74.249.14.98

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
```

### Ansible Not Found
```bash
# Install Ansible
pip3 install ansible

# Or on Ubuntu:
sudo apt install ansible
```

### Permission Denied
Make sure you're running playbooks that use `become: yes` (they all do).

## What Would You Like Me To Do?

1. **Complete the remaining roles** (dynatrace-activegate + kubernetes-apps)
2. **Test what we have** - Run the playbook with current roles
3. **Create GitHub Actions workflow** (Phase 4) to automate everything

Let me know and I'll proceed!
