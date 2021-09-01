# Provision a Nomad cluster on AWS

## Pre-requisites

To get started, create the following:

- AWS account
- [API access keys](http://aws.amazon.com/developers/access-keys/)
- [SSH key pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)

## Set the AWS environment variables

```bash
$ export AWS_ACCESS_KEY_ID=[AWS_ACCESS_KEY_ID]
$ export AWS_SECRET_ACCESS_KEY=[AWS_SECRET_ACCESS_KEY]
```

## Build an AWS machine image with Packer

[Packer](https://www.packer.io/intro/index.html) is HashiCorp's open source tool 
for creating identical machine images for multiple platforms from a single 
source configuration. The Terraform templates included in this repo reference a 
publicly available Amazon machine image (AMI) by default. The AMI can be customized 
through modifications to the [build configuration script](../shared/scripts/setup.sh) 
and [packer.json](packer.json).

Change directory to /infra_deploy/packer.

Take a look at the packer.json file. You may want to alter some attributes such as the AWS region.

When you are happy with the file, run the following:

```bash
$ packer build packer.json
```
Once this build is complete, copy the AMI ID to be used in the next step.


## Provision a cluster with Terraform

Change directory to ./infra_deploy/

Copy the terraform.tfvars.example file to terraform.tfvars

Make sure you alter the region, SSH key name and AMI ID at a minimum:

```bash
region                  = "ap-southeast-2"
ami                     = "ami-09730698a875f6abd"
instance_type           = "t2.medium"
key_name                = "KEY_NAME"
server_count            = "3"
client_count            = "4"
```


Provision the cluster:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Access the cluster

SSH to one of the servers using its public IP:

```bash
$ ssh -i /path/to/private/key ubuntu@PUBLIC_IP
```

The infrastructure that is provisioned for this test environment is configured to 
allow traffic to port 22 from the Whitelist IP you have nominated. If you input 0.0.0.0/0 here then this port is open to the world. This is obviously not recommended for production 
deployments.

## What next?

You now have a working Nomad and Consul cluster ready to receive workloads. You may have your own job definition, or may want to use the demo application located in the ../app_deploy folder.
