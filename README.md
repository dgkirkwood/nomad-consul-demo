# Demo Application Deployment using Consul and Nomad on AWS

## What is this?

This repository contains all the code you will need to deploy a highly available Nomad and Consul cluster on AWS, and then an example application to deploy into that environment.
**Note this is a demo environment and application which should not be used in production**

## How to use this repository

Explore the subdirectories to familiarise yourself with the code. 
1.  /infra_deploy contains Packer and Terraform definitions to build the VMs and supporting elements on AWS. 

    **Start here and follow the README instructions.**

2. /app_deploy contains Nomad and Consul definitions for the application used in this demo.

    **Use this folder if you want an application to test in the environment**

/shared contains configuration and scripts that are consumed by the Packer build in step 1.


