# DNS Records managed by Terraform

# SGOS Infrastructure Documentation
resource "cloudflare_record" "sgos_infra" {
  zone_id = var.cloudflare_zone_id
  name    = "sgos-infra"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.toucan.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}


