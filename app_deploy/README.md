# Deploy a microservices application on to Nomad

## Pre-requisites

Ensure you have followed the steps in the infra_deploy folder to stand up your Nomad and Consul cluster on AWS. Ensure you can reach the cluster UIs and that Nomad and Consul are healthy. 

Check the output of the Terraform run to set the NOMAD_ADDR and CONSUL environment variables.


## Consul configuration

Extra configuration items are used to acheive the following:

* Register the RDS instance created in the infra_deploy stage as an external service. This is used to demonstrate the terminating gateway functionality
* L7 traffic steering to demonstrate differente application deployment scenarios

Ensure the file ext_svc.json is updated with your RDS IP address before you begin. This IP address is output at the end of the Terraform run. 

Once this file is updated, change your terminal to the app_deploy/consul folder and run the following commands:

```bash
$ curl --request PUT --data @ext_svc.json $CONSUL/v1/agent/service/register
$ curl --request PUT --data @servicedefaults.json $CONSUL/v1/config
$ curl --request PUT --data @paymentsresolver.json $CONSUL/v1/config
$ curl --request PUT --data @paymentssplitter.json $CONSUL/v1/config

```

## Nomad configuration

There are two Nomad job files for this demonstration. 

gateways.nomad which deploys the Consul Ingress and Terminating gateways
pyapp.nomad which deploys the microservices application

Change directory to app_deploy/nomad and run the following:

```bash
$ nomad run gateways.nomad
$ nomad run pyapp.nomad
```

Both commands will take some time to execute as they wait for all services to report as healthy before completing. 
