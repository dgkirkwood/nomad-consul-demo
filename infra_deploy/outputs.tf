output "IP_Addresses" {
  value = <<CONFIGURATION

Client public IPs: ${join(", ", module.hashistack.client_public_ips)}

Server public IPs: ${join(", ", module.hashistack.server_public_ips)}

RDS Private IP: ${module.hashistack.RDS_IP}

To connect, add your private key and SSH into any client or server with
`ssh ubuntu@PUBLIC_IP`. You can test the integrity of the cluster by running:

  $ consul members
  $ nomad server members
  $ nomad node status

If you see an error message like the following when running any of the above
commands, it usually indicates that the configuration script has not finished
executing:

"Error querying servers: Get http://127.0.0.1:4646/v1/agent/members: dial tcp
127.0.0.1:4646: getsockopt: connection refused"

Simply wait a few seconds and rerun the command if this occurs.

The Nomad UI can be accessed at http://${module.hashistack.server_lb_ip}:4646/ui.
The Consul UI can be accessed at http://${module.hashistack.server_lb_ip}:8500/ui.

Set the following for access from the Nomad CLI and ease of Consul config:

  export NOMAD_ADDR=http://${module.hashistack.server_lb_ip}:4646
  export CONSUL=http://${module.hashistack.server_lb_ip}:8500



CONFIGURATION

}


output "tuple" {
  value = [for s in module.hashistack.tuple: s.arn]
}