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

Change directory to aws/packer and run the following:

```bash
$ packer build packer.json
```
Once this build is complete, copy the AMI ID to be used in the next step.


## Provision a cluster with Terraform

Change directory to aws/

Copy the terraform.tfvars.example file to terraform.tfvars

Make sure you alter the region, SSH key name and AMI ID at a minimum:

```bash
region                  = "us-east-1"
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
allow all traffic over port 22. This is obviously not recommended for production 
deployments.

