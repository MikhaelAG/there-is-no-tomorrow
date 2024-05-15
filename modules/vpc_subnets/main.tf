resource "google_compute_subnetwork" "sub-sg" {
  name = "${var.name}-sub-sg"
  network = var.network_id
  ip_cidr_range = var.ip_cidr_range
  region = var.region
  private_ip_google_access = var.private_ip_google_access
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}