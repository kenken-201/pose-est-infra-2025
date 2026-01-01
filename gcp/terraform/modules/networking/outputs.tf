/*
  出力値 - ネットワーキング設定
  -----------------------------------------------------------------------------
  作成されたネットワークリソースの ID やパラメータを出力します。
  他のモジュールから参照するために使用されます。
*/

output "vpc_id" {
  description = "作成された VPC の ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "作成された VPC の名前"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "作成された VPC の Self Link (URI)"
  value       = google_compute_network.vpc.self_link
}

output "subnet_id" {
  description = "作成されたサブネットの ID"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "作成されたサブネットの名前"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_self_link" {
  description = "作成されたサブネットの Self Link (URI)"
  value       = google_compute_subnetwork.subnet.self_link
}

output "nat_ip" {
  description = "Cloud NAT に割り当てられた静的 IP アドレス"
  value       = google_compute_address.nat.address
}
