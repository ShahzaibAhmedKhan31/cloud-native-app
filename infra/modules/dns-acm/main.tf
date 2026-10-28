# ============================================================
# Create Managed Route 53 Hosted Zone for your Domain
# ============================================================
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = "${var.name_prefix}-zone"
  }
}

# ============================================================
# Request SSL Certificate from AWS Certificate Manager (ACM)
# ============================================================
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  # Covers root domain and subdomains (e.g., app.yourdomain.com)
  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  tags = {
    Name = "${var.name_prefix}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================
# Create Route 53 CNAME Records for Certificate Validation
# ============================================================
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# ============================================================
# Validate ACM Certificate via Route 53
# ============================================================
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ============================================================
# Route 53 Alias Record (Points app.yourdomain.com -> ALB)
# ============================================================
resource "aws_route53_record" "alb_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}