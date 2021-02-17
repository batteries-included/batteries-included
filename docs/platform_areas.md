# Main Areas

- Machine Learning
- Storage
- Monitoring
- Developer Tools
- Databases
- Networking


## Machine Learning

Sagemaker but with mostly open source parts. Real honest machine learning doesn't have to be all that much around the math inside of a NN. It's just as important to use that ML in the smartest ways that extract the most business value.

- Pytorch
- Tensorboard
- Kubeflow


## Storage

We want to provide an all inclusive platform it's kind of hard to train ML without somewhere to get training data and somewhere to place the result. So lets provide durable storage for all the needs and all the automated  tools to keep that working.

- Rook
- Rook's S3 api
- PVC's
- NFS

## Monitoring

We are going to have to be able to operate this software until all of the feedback and remediation loops are automated. Lets do that by providing value to customers. Use open source monitoring and alerting with automated best practices from that.

- Prometheus
- Alertmanager
- TimescaleDB
- Grafana

### Other Mentions

InfluxDB: Seems like there's no way to scale this past one machine without being the influxdb team.

## Developer Tools

Provide the tools that developers and data scientists use every day. Make something that teams can't think about living without.

- Matrix
- Docker Registry
- Hashi-corp


## Database

- Postgres


## Networking

- Load balancers
- DNS Servers
- SSL