## For Kind

Kind is an open source project that allows you to run Kubernetes clusters on your local machine. Using it as a Kubernetes provider allows installing locally without needing a cloud provider. This is not recommended for production use, but is great for development and testing.

When installing on Kind Batteries Included will:

- Start Kind on the local docker daemon
- Pick an IP range for MetalLB to use
- Start the Batteries Included control server
- Deploy Istion and the Istio Ingress Gateway battery
- Start MetalLB with the docker IP range
