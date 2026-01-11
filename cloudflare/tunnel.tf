# =============================================================================
# SGOS Cloudflare Tunnels
# Only manages toucan and hornbill - other tunnels are outside SGOS scope
# =============================================================================

# Toucan tunnel (control server)
# Services: GlitchTip, SGOS Infra Docs, Homepage, Beszel, Dozzle
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
    ingress_rule {
      hostname = "glitchtip.sgl.as"
      service  = "http://localhost:8000"
    }
    ingress_rule {
      hostname = "sgos-infra.sgl.as"
      service  = "http://localhost:4200"
    }
    # Monitoring
    ingress_rule {
      hostname = "dashboard.sgl.as"
      service  = "http://localhost:3003"
    }
    ingress_rule {
      hostname = "beszel.sgl.as"
      service  = "http://localhost:8090"
    }
    ingress_rule {
      hostname = "dozzle.sgl.as"
      service  = "http://localhost:8888"
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
      service  = "http://localhost:9000"
    }
    # Add more SGOS apps here as they're deployed
    ingress_rule {
      service = "http_status:404"
    }
  }
}
