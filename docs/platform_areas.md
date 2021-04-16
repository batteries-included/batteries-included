# 1. Platform Areas

This document should be a place to describe the services that we provide to users.

- [1. Platform Areas](#1-platform-areas)
  - [1.1. Main Areas](#11-main-areas)
    - [1.1.1. Machine Learning Exploration](#111-machine-learning-exploration)
    - [1.1.2. Machine Learning Training](#112-machine-learning-training)
    - [1.1.3. Monitoring](#113-monitoring)
    - [1.1.4. Logging](#114-logging)
    - [1.1.5. Database](#115-database)
    - [1.1.6. Automated Operations](#116-automated-operations)
    - [1.1.7. Developer Tools](#117-developer-tools)
  - [1.2. Supporting Areas](#12-supporting-areas)
    - [1.2.1. Storage](#121-storage)
    - [1.2.2. Networking](#122-networking)

## 1.1. Main Areas

These are the services that we provide as solutions directly to our users. These should solve a problem that's important to our users and it's very visible to them. These should be services or solutions that we provide end to end.

### 1.1.1. Machine Learning Exploration

Sagemaker but with mostly open source parts. Real honest machine learning doesn't have to be all that much around the math inside of a NN. It's just as important to use that ML in the smartest ways that extract the most business value.

- JuypterHub
- Tensorboard

### 1.1.2. Machine Learning Training

Model pipelines are hugely impactful and currently most companies are not aware of their power. So we should make automated training and continuous training easy to use and impactful. For this we need full training pipeline, model storage, and other services.

- Pytorch Lightning
- Kubeflow/Airflow

### 1.1.3. Monitoring

We are going to have to be able to operate this software until all of the feedback and remediation loops are automated. Lets do that by providing value to customers. Use open source monitoring and alerting with automated best practices from that.

- Prometheus
- Alertmanager
- Grafana

### 1.1.4. Logging

- Elasticsearch
- Logstash
- Filebeat

### 1.1.5. Database

- Postgres
- TimescaleDB

VS:

- Vitess

VS:

- Yugabyte

### 1.1.6. Automated Operations

- Automated reaction to alerts
- Automated troubleshooting

### 1.1.7. Developer Tools

Provide the tools that developers and data scientists use every day. Make something that teams can't think about living without.

- Docker Registry
- CI
- Chaos Engineering

## 1.2. Supporting Areas

These are areas/services that might be present on cloud based clusters and we wouldn't need to provide this as it's not user facing. Instead we would be on the hook for configuring it like we are expecting when there

### 1.2.1. Storage

We want to provide an all inclusive platform it's kind of hard to train ML without somewhere to get training data and somewhere to place the result. So lets provide durable storage for all the needs and all the automated  tools to keep that working.

- Rook
- Rook's S3 api
- PVC's
- NFS

VS:

- OpenEBS
- minio

### 1.2.2. Networking

- Load balancers
- DNS Servers
- SSL
