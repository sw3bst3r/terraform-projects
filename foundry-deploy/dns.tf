// This code assumes you own a domain name and have access to the DNS records for that domain. 
// If you do not own a domain name, you can purchase one from a domain registrar such as 
// Google Domains, GoDaddy, or Namecheap. If you do not have access to the DNS records for your 
// domain, you will need to contact the person or organization that manages your domain's DNS 
// records to make the necessary changes.
variable "domain_name" {
  description = "The domain name to use for the Foundry server"
  type        = string
}
variable "top_level_domain" {
  description = "The top-level domain to use for the Foundry server"
  type        = string
}
data "aws_route53_zone" "primary" {
  name = var.domain_name
}
resource "aws_route53_record" "a_record" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "${var.top_level_domain}.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.this.public_ip]
}
