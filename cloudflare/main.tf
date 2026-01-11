provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Data source to get zone info
data "cloudflare_zone" "sgl_as" {
  zone_id = var.cloudflare_zone_id
}
