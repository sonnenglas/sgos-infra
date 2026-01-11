# =============================================================================
# Zero Trust Access Applications and Policies
# =============================================================================

# SGOS Infrastructure Documentation - requires Sonnenglas Google login
resource "cloudflare_zero_trust_access_application" "sgos_infra" {
  zone_id          = var.cloudflare_zone_id
  name             = "SGOS Infrastructure Docs"
  domain           = "sgos-infra.sgl.as"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "sgos_infra_google" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.sgos_infra.id
  name           = "Require Sonnenglas Google"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = ["sonnenglas.net"]
  }
}
