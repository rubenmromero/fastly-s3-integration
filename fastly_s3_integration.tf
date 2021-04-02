terraform {
  required_providers {
    fastly = { 
      source = "fastly/fastly"
    }
  }
  required_version = ">= 0.13"
}

# Export the env variable FASTLY_API_KEY to authenticate the provider to the Fastly account
provider "fastly" {}

variable "fastly_service_name" {
   description = "Fastly service name"
   default     = "fastly-s3-integration"
}

variable "fastly_domain" {
   description = "Fastly CDN domain"
   default     = "fastly-s3-integration.global.ssl.fastly.net"
}

variable "aws_region" {
  description = "AWS region code"
}

resource "random_id" "domain_name_suffix" {
  byte_length = 1
}

locals {
  # Prevent the default Fastly CDN domain from trying to be created twice
  fastly_domain = var.fastly_domain == "fastly-s3-integration.global.ssl.fastly.net" ? "fastly-s3-integration-${random_id.domain_name_suffix.dec}.global.ssl.fastly.net" : var.fastly_domain
}

resource "fastly_service_v1" "fastly_s3_integration" {
  name = var.fastly_service_name

  domain {
    name    = local.fastly_domain
    comment = "Fastly CDN domain"
  }

  backend {
    address           = "s3.${var.aws_region}.amazonaws.com"
    name              = "s3_${var.aws_region}_endpoint"
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = "s3.${var.aws_region}.amazonaws.com"
    ssl_sni_hostname  = "s3.${var.aws_region}.amazonaws.com"
    auto_loadbalance  = false
  }

  force_destroy = true

  snippet {
    name     = "parse_url"
    type     = "recv"
    priority = "100"
    content = <<EOF
if (req.url ~ "/([^/]+)/(.*)$") {
  set req.http.X-Bucket = re.group.1;
  set req.url = "/" re.group.2;
}
EOF
  }

  snippet {
    name     = "set_s3_bucket_host"
    type     = "miss"
    priority = "100"
    content = <<EOF
if (req.http.X-Bucket) {
  set bereq.http.host = req.http.X-Bucket ".s3.${var.aws_region}.amazonaws.com";
}
EOF
  }
}

output "fastly_service_configuration" {
  value = fastly_service_v1.fastly_s3_integration
}
