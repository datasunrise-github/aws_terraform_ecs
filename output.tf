# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DataSunrise Cluster for Amazon Web Services
# Version 0.1
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

output "DataSunriseConsoleURL" {
  value = "https://${aws_lb.ds_ntwrk_load_balancer.dns_name}"
}