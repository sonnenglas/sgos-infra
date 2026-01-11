variable "cloudflare_api_token" {
  description = "Cloudflare API token (scoped to sgl.as zone)"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for sgl.as"
  type        = string
}
