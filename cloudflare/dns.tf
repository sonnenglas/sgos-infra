# DNS Records managed by Terraform

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


