variable "CLOUDFLARE_API_KEY" {
  type = string
}

variable "CLOUDFLARE_ZONE_ID" {
  type = string
}

variable "CLOUDFLARE_ACCOUNT_ID" {
  type = string
}

variable "CLOUDFLARE_DOMAIN" {
  type = string
}

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
  }
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_KEY
}

resource "cloudflare_access_group" "developpers" {
  account_id = var.CLOUDFLARE_ACCOUNT_ID
  name       = "developpers"

  include {
    email = ["kaihatu.totto2727@gmail.com"]
  }
}

resource "cloudflare_record" "notion" {
  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = "notion"
  type    = "CNAME"
  value   = "www.notion.so"
  proxied = true
}

resource "cloudflare_pages_project" "keyword-game" {
  account_id        = var.CLOUDFLARE_ACCOUNT_ID
  name              = "keyword-game"
  production_branch = "main"
  deployment_configs {
    preview {
      environment_variables = {}
      secrets               = {}
      compatibility_date    = "2023-08-12"
      fail_open             = false
      usage_model           = "bundled"
      placement {
        mode = "smart"
      }
    }
    production {
      environment_variables = {}
      secrets               = {}
      fail_open             = false
      compatibility_date    = "2023-08-12"
      usage_model           = "bundled"
      placement {
        mode = "smart"
      }
    }
  }
}

resource "cloudflare_record" "keyword-game" {
  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = "keyword"
  type    = "CNAME"
  value   = cloudflare_pages_project.keyword-game.subdomain
  proxied = true
}

resource "cloudflare_pages_domain" "keyword-game" {
  account_id   = var.CLOUDFLARE_ACCOUNT_ID
  project_name = cloudflare_pages_project.keyword-game.name
  domain       = cloudflare_record.keyword-game.hostname
}

resource "cloudflare_access_application" "keyword-game-dev-domain" {
  account_id          = var.CLOUDFLARE_ACCOUNT_ID
  name                = "keyword-game-dev-domain"
  domain              = "*.${cloudflare_pages_project.keyword-game.subdomain}"
  self_hosted_domains = ["*.${cloudflare_pages_project.keyword-game.subdomain}"]
  session_duration    = "24h"
}

resource "cloudflare_access_policy" "keyword-game-dev-domain" {
  application_id = cloudflare_access_application.keyword-game-dev-domain.id
  account_id     = var.CLOUDFLARE_ACCOUNT_ID
  name           = "developpers"
  precedence     = "10"
  decision       = "allow"

  include {
    group = [cloudflare_access_group.developpers.id]
  }
}

resource "cloudflare_pages_project" "www" {
  account_id        = var.CLOUDFLARE_ACCOUNT_ID
  name              = "www"
  production_branch = "main"

  deployment_configs {
    preview {
      environment_variables = {}
      compatibility_date    = "2023-08-12"
      fail_open             = false
      usage_model           = "bundled"
      placement {
        mode = "smart"
      }
    }
    production {
      environment_variables = {}
      compatibility_date    = "2023-08-12"
      fail_open             = false
      usage_model           = "bundled"
      placement {
        mode = "smart"
      }
    }
  }
}

resource "cloudflare_record" "www" {
  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = "www"
  type    = "CNAME"
  value   = cloudflare_pages_project.www.subdomain
  proxied = true
}

resource "cloudflare_pages_domain" "www" {
  account_id   = var.CLOUDFLARE_ACCOUNT_ID
  project_name = cloudflare_pages_project.www.name
  domain       = cloudflare_record.www.hostname
}

resource "cloudflare_access_application" "www-dev-domain" {
  account_id          = var.CLOUDFLARE_ACCOUNT_ID
  name                = "www-dev-domain"
  domain              = "*.${cloudflare_pages_project.www.subdomain}"
  self_hosted_domains = ["*.${cloudflare_pages_project.www.subdomain}"]
  session_duration    = "24h"
}

resource "cloudflare_access_policy" "www-dev-domain" {
  application_id = cloudflare_access_application.www-dev-domain.id
  account_id     = var.CLOUDFLARE_ACCOUNT_ID
  name           = "developpers"
  precedence     = "10"
  decision       = "allow"

  include {
    group = [cloudflare_access_group.developpers.id]
  }
}

