# DNS Records managed by Terraform

resource "cloudflare_record" "test_txt" {
  zone_id = var.cloudflare_zone_id
  name    = "terraform-test"
  content = "Hello from Terraform - SGOS infra works!"
  type    = "TXT"
  ttl     = 60
}

# SGOS Infrastructure Documentation
resource "cloudflare_record" "sgos_infra" {
  zone_id = var.cloudflare_zone_id
  name    = "sgos-infra"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.toucan.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# Demo app for testing Zero Trust
resource "cloudflare_record" "demo" {
  zone_id = var.cloudflare_zone_id
  name    = "demo"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.toucan.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

