---
title: Platform Areas
date: '2021-11-11'
tags: ['planning']
draft: false
summary: Platform area plans.
images: []
---

# 1. Platform Areas

This document should be a place to describe the services that we provide to
users.

- [1. Platform Areas](#1-platform-areas)
  - [1.1. Machine Learning Exploration](#11-machine-learning-exploration)
  - [1.2. Machine Learning Training](#12-machine-learning-training)
  - [1.3. Monitoring/Observability](#13-monitoringobservability)
  - [1.4. Database](#14-database)
  - [1.5. Automated Operations](#15-automated-operations)
  - [1.6. Developer Tools](#16-developer-tools)
  - [1.7. Storage](#17-storage)
  - [1.8. Communications](#18-communications)

### 1.1. Machine Learning Exploration

Sagemaker but with mostly open source parts. Real honest machine learning
doesn't have to be all that much around the math inside of a NN. It's just as
important to use that ML in the smartest ways that extract the most business
value.

- JuypterHub
- Tensorboard

### 1.2. Machine Learning Training

Model pipelines are hugely impactful and currently most companies are not aware
of their power. So we should make automated training and continuous training
easy to use and impactful. For this we need full training pipeline, model
storage, and other services.

- Pytorch Lightning
- Kubeflow/Airflow

### 1.3. Monitoring/Observability

We are going to have to be able to operate this software until all of the
feedback and remediation loops are automated. Lets do that by providing value to
customers. Use open source monitoring and alerting with automated best practices
from that.

- Prometheus
- Alertmanager
- Grafana
- Elasticsearch
- Logstash
- Filebeat

### 1.4. Database

- Postgres
- TimescaleDB

VS:

- Vitess

### 1.5. Automated Operations

- Automated reaction to alerts
- Automated troubleshooting

### 1.6. Developer Tools

Provide the tools that developers and data scientists use every day. Make
something that teams can't think about living without.

- Docker Registry
- CI
- Chaos Engineering

### 1.7. Storage

We want to provide an all inclusive platform it's kind of hard to train ML
without somewhere to get training data and somewhere to place the result. So
lets provide durable storage for all the needs and all the automated tools to
keep that working.

- Rook
- Rook's S3 api
- PVC's
- NFS

VS:

- OpenEBS
- minio

### 1.8. Communications

Now more than ever observability depends on the networking/RPC stack.

- Load balancers
- RPC Mesh/Fabric
- DNS Servers
- SSL
