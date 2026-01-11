# =============================================================================
# Zero Trust Access Applications and Policies
# =============================================================================

# App 1: API path - public (bypass), evaluated FIRST due to more specific path
resource "cloudflare_zero_trust_access_application" "demo_api" {
  zone_id          = var.cloudflare_zone_id
  name             = "Demo API (Public)"
  domain           = "demo.sgl.as/api/*"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "demo_api_bypass" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.demo_api.id
  name           = "Public Access"
  precedence     = 1
  decision       = "bypass"

  include {
    everyone = true
  }
}

# App 2: Main app - requires Google login
resource "cloudflare_zero_trust_access_application" "demo" {
  zone_id          = var.cloudflare_zone_id
  name             = "Demo App (Protected)"
  domain           = "demo.sgl.as"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "demo_require_google" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.demo.id
  name           = "Require Sonnenglas Google"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = ["sonnenglas.net"]
  }
}
