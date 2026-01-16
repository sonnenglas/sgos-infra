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

# =============================================================================
# Monitoring Services
# =============================================================================

# Homepage Dashboard
resource "cloudflare_zero_trust_access_application" "dashboard" {
  zone_id          = var.cloudflare_zone_id
  name             = "Dashboard"
  domain           = "dashboard.sgl.as"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "dashboard_google" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.dashboard.id
  name           = "Require Sonnenglas Google"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = ["sonnenglas.net"]
  }
}

# Beszel - Server Monitoring
resource "cloudflare_zero_trust_access_application" "beszel" {
  zone_id          = var.cloudflare_zone_id
  name             = "Beszel"
  domain           = "beszel.sgl.as"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "beszel_google" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.beszel.id
  name           = "Require Sonnenglas Google"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = ["sonnenglas.net"]
  }
}

# Dozzle - Docker Logs
resource "cloudflare_zero_trust_access_application" "dozzle" {
  zone_id          = var.cloudflare_zone_id
  name             = "Dozzle"
  domain           = "dozzle.sgl.as"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "dozzle_google" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.dozzle.id
  name           = "Require Sonnenglas Google"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = ["sonnenglas.net"]
  }
}

# Grafana - Log Analytics
resource "cloudflare_zero_trust_access_application" "grafana" {
  zone_id          = var.cloudflare_zone_id
  name             = "Grafana"
  domain           = "grafana.sgl.as"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "grafana_google" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.grafana.id
  name           = "Require Sonnenglas Google"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = ["sonnenglas.net"]
  }
}

# SGOS Status - App Status Page
resource "cloudflare_zero_trust_access_application" "sgos_status" {
  zone_id          = var.cloudflare_zone_id
  name             = "SGOS Status"
  domain           = "sgos-status.sgl.as"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "sgos_status_google" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.sgos_status.id
  name           = "Require Sonnenglas Google"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = ["sonnenglas.net"]
  }
}

# =============================================================================
# Docflow - Document Management
# =============================================================================

# Docflow main application - requires Sonnenglas Google login
resource "cloudflare_zero_trust_access_application" "docflow" {
  zone_id          = var.cloudflare_zone_id
  name             = "Docflow"
  domain           = "docflow.sgl.as"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "docflow_google" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.docflow.id
  name           = "Require Sonnenglas Google"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = ["sonnenglas.net"]
  }
}

# Dropscan webhook - bypasses Zero Trust (token auth at app level)
resource "cloudflare_zero_trust_access_application" "docflow_dropscan" {
  zone_id          = var.cloudflare_zone_id
  name             = "Docflow Dropscan Webhook"
  domain           = "docflow.sgl.as/api/webhook/dropscan*"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "docflow_dropscan_bypass" {
  zone_id        = var.cloudflare_zone_id
  application_id = cloudflare_zero_trust_access_application.docflow_dropscan.id
  name           = "Bypass - Dropscan cannot send headers"
  precedence     = 1
  decision       = "bypass"

  include {
    everyone = true
  }
}
