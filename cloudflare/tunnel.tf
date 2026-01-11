# =============================================================================
# SGOS Cloudflare Tunnels
# Only manages toucan and hornbill - other tunnels are outside SGOS scope
# =============================================================================

# Toucan tunnel (control server)
# Services: GlitchTip, Grafana, Dokploy (temporary)
resource "cloudflare_zero_trust_tunnel_cloudflared" "toucan" {
  account_id = var.cloudflare_account_id
  name       = "toucan.sgl.as"
  secret     = "imported"

  lifecycle {
    ignore_changes = [secret]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "toucan" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.toucan.id

  config {
    # Order matches current Cloudflare config
    ingress_rule {
      hostname = "dokploy-toucan.sgl.as"
      service  = "http://localhost:3000"
    }
    ingress_rule {
      hostname = "glitchtip.sgl.as"
      service  = "http://localhost:8000"
    }
    # Demo app for testing Zero Trust policies
    ingress_rule {
      hostname = "demo.sgl.as"
      service  = "http://localhost:8000"  # Points to GlitchTip for demo
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Hornbill tunnel (app server)
# Services: SGOS apps via Traefik (or direct)
resource "cloudflare_zero_trust_tunnel_cloudflared" "hornbill" {
  account_id = var.cloudflare_account_id
  name       = "hornbill"
  secret     = "imported"

  lifecycle {
    ignore_changes = [secret]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "hornbill" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.hornbill.id

  config {
    ingress_rule {
      hostname = "phone.sgl.as"
      service  = "http://localhost:80"
    }
    # Add more SGOS apps here as they're deployed
    ingress_rule {
      service = "http_status:404"
    }
  }
}
