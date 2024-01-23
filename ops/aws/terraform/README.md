# EKS Terraform

Deploy all infrastructure needed to run an EKS cluster.

## Lifecycle

New environments are spun up by workspace.

As an example, for a staging cluster, in vars/ there would be a `stage.tfvars`
that sets specific terraform vars. The most important is `cluster_name`.

We're currently just applying from our local machines. Eventually, we may add
CI/CD of some sort.

### Setup

We use S3 + Dynamo as remote state store.

1. `terraform init`
1. `terraform workspace new <ws>`
1. copy existing vars file to vars/<ws>.tfvars
1. make sure you have a peer set up in `gateway.tf`
1. update newly copied vars file with the correct settings
1. `terraform plan -var-file=vars/<ws>.tfvars`
1. create PR, merge, `terraform apply -var-file=vars/<ws>.tfvars` locally

#### Caveats

1. It will take several minutes (~15?) to create the EKS cluster.
1. It may take a second apply to ensure that everything is fully created.
1. After creating the EKS cluster, terraform will need network connectivity to
   the private cluster. You'll need to set up `wireguard` for this.

### Teardown

Unfortunately, a few things are created outside of Terraform that prevent being
able to cleanly `destroy`.

1. The `karpenter` managed nodes don't currently get removed and will need to
   be terminated outside of terraform before proceeding.
1. There are launch templates that `karpenter` creates that may not get
   destroyed.
1. The gateway instance (and EIP) is terminated before the k8s resources so
   they fail to terminate and need to be manually removed. I use a one-liner
   like:

```bash
for resource in $(terraform state list | grep -P 'helm_release|kubectl'); do terraform state rm "$resource"; done
```

## Components

### VPC


### EKS cluster

We create an EKS cluster with a small managed node group for critical cluster
addons to be ran on. Workload nodes are scheduled by Karpenter. One can set up
their kubeconfig via:

```bash
aws eks update-kubeconfig --name <ws> --alias <ws> --user-alias <ws>
```

#### EBS CSI (addon)

Allows attaching EBS volumes as container storage.

#### CoreDNS (addon)

Used as cluster DNS resolver

#### VPC CNI (addon)

Currently, we're using the "default" AWS CNI provider that uses IPs attached to
Elastic Network Interfaces to provide IPAM and cluster networking. 

#### Kube proxy (addon)

For service based, virtual IP networking.

#### AWS Load Balancer Controller (addon)

For creating load balancers for services with `Type: LoadBalancer`.

### [Karpenter](https://karpenter.sh)

Runs on the small managed node group created by default. Creates additional
nodes as needed.
