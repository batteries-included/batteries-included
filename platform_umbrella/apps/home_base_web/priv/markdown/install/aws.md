## For AWS

On Amazon Web Services (AWS), Batteries Included will create a new EKS cluster
and deploy batteries needed to automatically run your cluster. We will:

- Create a new EKS cluster
- Start the Batteries Included control server
- Deploy the Karpeneter battery
- Deploy the AWS Load Balancer Controller battery
- Deploy the Istio battery for mTLS and service mesh
- Deploy the Istio Ingress Gateway battery for web traffic routing
- Deploy the Cert Manager battery for SSL certificates

### Needed

For AWS installs, the `bi` binary will need:

- An AWS account with admin permissions
- Authenticated via `aws sso login` or similar
- Profile environment variables set correctly
  (`export AWS_PROFILE=<YOUR_PROFILE_NAME>`)
