# EKS Terraform

Deploy all infrastructure needed to run an EKS cluster


## Lifecycle

New environments are spun up by workspace. 

As an example, for a cluster in the stage environment, in vars/ there would be
a `stage.yaml` that loads environment specific terraform vars.

We're currently just applying from our local machines. Eventually, we may add
CI/CD of some sort.

### Setup

We use S3 + Dynamo as remote state store.

1. `terraform init`
1. `terraform workspace new <ws>`
1. copy existing vars file to vars/<env>.yaml
1. update newly copied vars file with the correct settings
1. `terraform plan`
1. create PR, merge, `terraform apply` locally

#### Caveats

1. It will take several minutes (~15?) to create the EKS cluster.
1. It may take a second apply to ensure that everything is fully created.

### Teardown

Unfortunately, a few things are created outside of Terraform that prevent being
able to cleanly `destroy`.

1. The `karpenter` managed nodes don't currently get removed and will need to
   be terminated outside of terraform before proceeding.
1. There are launch templates that `karpenter` creates that may not get
   destroyed.

## Components

### VPC

We create a /16 VPC for each cluster with 3 small (/26) public subnets and 3
larger (/24) private subnets. 

### EKS cluster

We create an EKS cluster with a small managed node group for critical cluster
addons to be ran on. Workload nodes are scheduled by Karpenter.

#### EBS CSI (addon)

Allows attaching EBS volumes as container storage.

#### CoreDNS (addon)

Used as cluster DNS resolver

#### VPC CNI (addon)

Currently, we're using the "default" AWS CNI provider that uses IPs attached to
Elastic Network Interfaces to provide IPAM and cluster networking. 

#### Kube proxy (addon)

For service based, virtual IP networking.

### [Karpenter](https://karpenter.sh)

Runs on the small managed node group created by default. Creates additional
nodes as needed.
