# Get Your SSH Public Key

## On Windows PowerShell:

```powershell
# Display your SSH public key
Get-Content $env:USERPROFILE\.ssh\id_rsa.pub
```

## If you don't have an SSH key yet:

```powershell
# Generate a new SSH key pair
ssh-keygen -t rsa -b 4096 -C "your-email@hubinternational.com"

# Press Enter to accept default location
# Press Enter twice for no passphrase (or set one if you prefer)

# Then display the public key
Get-Content $env:USERPROFILE\.ssh\id_rsa.pub
```

## Next Steps:

1. Copy the entire SSH public key output (starts with "ssh-rsa")
2. Open `terraform.tfvars` in this directory
3. Replace `PASTE_YOUR_SSH_PUBLIC_KEY_HERE` with your actual key
4. Save the file
5. Run `terraform validate` again
