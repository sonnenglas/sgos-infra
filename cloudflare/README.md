# Cloudflare Infrastructure

Terraform configuration for Cloudflare resources (sgl.as zone).

## Setup

### 1. Create API Token

Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens):

1. Create Custom Token
2. Token name: `terraform-sgl-as`
3. Permissions:
   - Account / Cloudflare Tunnel / Edit
   - Account / Access: Apps and Policies / Edit
   - Zone / DNS / Edit
4. Zone Resources: Include → Specific zone → sgl.as
5. Create Token

Reference: [Cloudflare Tunnel Terraform Guide](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/deployment-guides/terraform/)

### 2. Get IDs

**Account ID:** Cloudflare dashboard → any zone → Overview → right sidebar

**Zone ID:** Cloudflare dashboard → sgl.as → Overview → right sidebar

### 3. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Import Existing Resources

Import existing resources so Terraform doesn't recreate them:

```bash
# Import tunnel (get tunnel ID from dashboard or API)
terraform import cloudflare_tunnel.toucan <account-id>/<tunnel-id>

# Import access application
terraform import cloudflare_access_application.glitchtip <zone-id>/<app-id>
```

### 6. Plan and Apply

```bash
# See what would change
terraform plan

# Apply changes
terraform apply
```

## Files

| File | Purpose |
|------|---------|
| versions.tf | Terraform and provider versions |
| variables.tf | Input variable definitions |
| main.tf | Provider configuration |
| tunnel.tf | Cloudflare Tunnel configuration |
| access.tf | Zero Trust apps and policies |
| terraform.tfvars | Your secrets (gitignored) |
