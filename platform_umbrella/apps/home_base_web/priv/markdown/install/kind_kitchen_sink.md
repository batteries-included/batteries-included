## For Kind and the Kitchen Sink

[Kind](https://kind.sigs.k8s.io/) is an open source project that allows you to
run Kubernetes clusters on your local machine. Using it as a Kubernetes provider
allows installing locally without needing a cloud provider. Running the kitchen
sink will install all batteries and turn on all features. We will:

- Start Kind on the local docker daemon
- Install all batteries
- Set to a smaller defautl instance size
- Hope that you have a large development machine
