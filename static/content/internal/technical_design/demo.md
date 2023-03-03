+++
title = 'How to install for demo'
date = '2023-03-03'
tags = ['demo', 'kubernetes']
draft = false
images = []
+++

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable=traefik" sh -
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```
