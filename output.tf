# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DataSunrise Cluster for Amazon Web Services
# # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

output "DataSunriseConsoleURL" {
  value = "https://${aws_lb.ds_ntwrk_load_balancer.dns_name}"
}