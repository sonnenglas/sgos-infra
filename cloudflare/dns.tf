# DNS Records managed by Terraform

# =============================================================================
# Toucan Tunnel Services
# =============================================================================

# GlitchTip - Error Tracking
resource "cloudflare_record" "glitchtip" {
  zone_id = var.cloudflare_zone_id
  name    = "glitchtip"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.toucan.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# SGOS Infrastructure Documentation
resource "cloudflare_record" "sgos_infra" {
  zone_id = var.cloudflare_zone_id
  name    = "sgos-infra"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.toucan.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# Monitoring - Homepage Dashboard
resource "cloudflare_record" "dashboard" {
  zone_id = var.cloudflare_zone_id
  name    = "dashboard"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.toucan.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# Monitoring - Beszel
resource "cloudflare_record" "beszel" {
  zone_id = var.cloudflare_zone_id
  name    = "beszel"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.toucan.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# Monitoring - Dozzle
resource "cloudflare_record" "dozzle" {
  zone_id = var.cloudflare_zone_id
  name    = "dozzle"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.toucan.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# PocketID - Identity Provider (NO Zero Trust - it IS the identity provider)
resource "cloudflare_record" "pocketid" {
  zone_id = var.cloudflare_zone_id
  name    = "id"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.toucan.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# =============================================================================
# Hornbill Tunnel Services
# =============================================================================

# Phone - Voicemail System (NO Zero Trust - public webhook endpoint)
resource "cloudflare_record" "phone" {
  zone_id = var.cloudflare_zone_id
  name    = "phone"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.hornbill.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
