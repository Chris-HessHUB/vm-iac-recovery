# Complete Ansible Deployment Guide

## 🎉 All Roles Complete!

All 6 Ansible roles have been created:

1. ✅ **base-system** - System preparation
2. ✅ **docker** - Container runtime
3. ✅ **k3s** - Kubernetes installation
4. ✅ **dynatrace-oneagent** - Host monitoring
5. ✅ **dynatrace-activegate** - Kubernetes monitoring via Operator
6. ✅ **kubernetes-apps** - All applications (MySQL, Flask, generators)

---

## Prerequisites

### 1. Helm Installation (Required for ActiveGate)

On your test VM, Helm needs to be installed:

```bash
# SSH to VM
ssh -i ~/.ssh/id_rsa azureuser@74.249.14.98

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version

# Exit
exit
```

### 2. Update Secrets

Make sure `ansible/vars/secrets.yml` has valid values:

```yaml
dynatrace_environment_id: "bnh29255"
dynatrace_tenant_token: "YOUR_PAAS_TOKEN"
dynatrace_api_token: "YOUR_API_TOKEN"
dynatrace_activegate_token: "YOUR_ACTIVEGATE_TOKEN"
mysql_root_password: "SecurePassword123!"
mysql_database: "orders"
mysql_user: "appuser"
mysql_password: "AppPassword456!"
```

---

## Deployment Options

### Option 1: Deploy Everything (Full Stack)

```bash
cd "/mnt/c/Users/chris.hess/OneDrive - HUB International Limited/Documents/GitHub/vm-iac-recovery/ansible"

# Full deployment
ansible-playbook -i inventory/hosts.yml site.yml -v
```

**This will take 15-20 minutes** and deploy:
- Base system + Docker
- k3s Kubernetes
- Dynatrace OneAgent
- Dynatrace ActiveGate Operator
- MySQL database
- Flask applications
- Order generator
- Sync service

---

### Option 2: Deploy Incrementally (Recommended for Testing)

#### Step 1: Base Infrastructure (Already Done)
```bash
ansible-playbook -i inventory/hosts.yml site.yml --tags "base,docker,k3s" -v
```

#### Step 2: Install Helm on VM
```bash
ssh -i ~/.ssh/id_rsa azureuser@74.249.14.98 "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
```

#### Step 3: Dynatrace Monitoring
```bash
# OneAgent (already done)
ansible-playbook -i inventory/hosts.yml site.yml --tags "oneagent" -v

# ActiveGate Operator
ansible-playbook -i inventory/hosts.yml site.yml --tags "activegate" -v
```

#### Step 4: Applications
```bash
# All apps
ansible-playbook -i inventory/hosts.yml site.yml --tags "k8s-apps" -v

# Or individually:
ansible-playbook -i inventory/hosts.yml site.yml --tags "mysql" -v
ansible-playbook -i inventory/hosts.yml site.yml --tags "flask" -v
ansible-playbook -i inventory/hosts.yml site.yml --tags "order-generator" -v
ansible-playbook -i inventory/hosts.yml site.yml --tags "sync-service" -v
```

---

## Verification Commands

### After Full Deployment

```bash
# SSH to VM
ssh -i ~/.ssh/id_rsa azureuser@74.249.14.98

# Check all pods
kubectl get pods -A

# Check deployments
kubectl get deployments -A

# Check services
kubectl get svc -A

# Check Dynatrace
kubectl get pods -n dynatrace
kubectl get dynakube -n dynatrace

# Check MySQL
kubectl exec -it -n mysql statefulset/mysql-statefulset -- mysql -u root -p

# Check Flask app
kubectl port-forward -n flask-app svc/flask-service 8080:80
# Then visit: http://localhost:8080/health

# View Order Generator logs
kubectl logs -n default -l app=order-generator --tail=50

# View Sync Service logs
kubectl logs -n default -l app=sync-service --tail=50
```

---

## Expected Results

### Namespaces
- `default` - Order generator, sync service
- `mysql` - MySQL StatefulSet
- `flask-app` - Flask applications (2 replicas)
- `dynatrace` - OneAgent DaemonSet, ActiveGate, Operator

### Pods
- `mysql-statefulset-0` (mysql namespace)
- `flask-deployment-xxxxx` x2 (flask-app namespace)
- `mysql-order-generator-xxxxx` x2 (default namespace)
- `mysql-sqlserver-sync-xxxxx` (default namespace)
- `dynatrace-operator-xxxxx` (dynatrace namespace)
- `default-activegate-0` (dynatrace namespace)
- `dynatrace-oneagent-xxxxx` (dynatrace namespace)

### In Dynatrace Console
Visit: https://bnh29255.live.dynatrace.com

- **Hosts** → See your VM with OneAgent installed
- **Kubernetes** → See k3s cluster with workloads
- **Applications** → See instrumented Flask apps
- **Databases** → See MySQL connections

---

## Troubleshooting

### Helm Not Found
```bash
# On VM
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### ActiveGate Not Starting
```bash
kubectl describe pod -n dynatrace -l app.kubernetes.io/component=activegate
kubectl logs -n dynatrace -l app.kubernetes.io/component=activegate
```

### MySQL Not Starting
```bash
kubectl describe pod -n mysql mysql-statefulset-0
kubectl logs -n mysql mysql-statefulset-0
```

### Flask Pods CrashLooping
```bash
kubectl logs -n flask-app -l app=flask
# Usually due to MySQL not ready - wait a few minutes
```

### Secret Not Found Errors
Make sure mysql-secret exists in mysql namespace:
```bash
kubectl get secret -n mysql mysql-secret
```

---

## What's Next?

### Option A: Test the Full Deployment

Run the complete playbook and verify all services.

### Option B: Create GitHub Actions Workflow (Phase 4)

Automate the entire process:
1. Terraform provisions VM
2. Ansible configures everything
3. One-click deployment from GitHub

---

## Current State Summary

✅ **Terraform** - VM infrastructure as code  
✅ **Ansible Roles Complete** - All 6 roles created  
✅ **Base System** - Tested and working  
✅ **Docker** - Tested and working  
✅ **k3s** - Tested and working  
✅ **OneAgent** - Tested and working  
🚧 **ActiveGate** - Created, needs testing  
🚧 **Applications** - Created, needs testing  

**You're 85% complete with Phase 3!**

---

## Recommended Next Steps

1. **Install Helm on VM**
2. **Run full playbook** or **incremental deployment**
3. **Verify all pods are running**
4. **Check Dynatrace console** for monitoring data
5. **Proceed to Phase 4** (GitHub Actions)

**Which would you like to do first?**
