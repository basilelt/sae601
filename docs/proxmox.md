1. Log into your Proxmox web interface (at https://proxmox.basile.local:8006 in your case)

2. Navigate to Datacenter → Permissions → API Tokens

3. Click the "Add" button

4. Fill in the required fields:
- User: terraform@pam (matching your token ID configuration)
- Token ID: terraform-token
- Privilege Separation: Typically unchecked for Terraform automation
- Expiration date: Optional, leave empty for no expiration

5. Click "Create"

6. **IMPORTANT**: When the token is created, Proxmox will display the secret once and only once. Copy this secret value immediately.

7. Paste this secret into your terraform.tfvars file, replacing "your-token-secret"

8. Click "Add" under the "API Token Permissions" section

9. Configure the permission:
- Path: /
- API Token: terraform@pam!terraform-token
- Role: Administrator

1.  Click "Add"