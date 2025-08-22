---
title: 'Local NVIDIA AI Acceleration'
description:
  Set up NVIDIA Container Toolkit for GPU-accelerated AI workloads on local Kind
  clusters.
tags: ['AI', 'NVIDIA', 'GPU', 'Kind', 'local-development']
category: getting-started
draft: false
---

Using NVIDIA GPUs should be simple. We make it easy, from local development to
production autoscaling in the cloud.

For local work, we use Kind to run Kubernetes in Docker. This gives you a real
production environment on your machine. We handle the hard parts of connecting
Kubernetes to your GPU. You build. We make the hardware work.

## TLDR

If you have nvidia hardware and have installed the NVIDIA Container Toolkit,
then Batteries Included will automatically detect and use your GPU. Install the
cli and start a local cluster with one command.

```bash
bash -c "$(curl -fsSL https://home.batteriesincl.com/api/v1/scripts/start_local)"
```

If you don't have NVIDIA container toolkit installed, follow these steps:

```bash
bash -c "$(curl -fsSL https://home.batteriesincl.com/api/v1/scripts/install_bi)
sudo bash -c "$(~/.local/bin/bi gpu setup-command)"
~/.local/bin/bi start-local
```

## Prerequisites

- An NVIDIA GPU.
- NVIDIA drivers installed.
- Docker installed.

## Install BI CLI

There are several ways to install the BI CLI, depending on your preferences.
Below we list them in order of convenience.

### Automatically

```bash
bash -c "$(curl -fsSL https://home.batteriesincl.com/api/v1/scripts/install_bi)"
```

### Manually

- Download the install script
  `curl -fsSL https://home.batteriesincl.com/api/v1/scripts/install_bi -o install_bi`
- Validate the script contents and make sure it's safe for you to run
- Run the install script: `chmod +x install_bi && bash install_bi`
- Verify `ls -al ~/.local/bin`

### By Hand

You don't like curl and bash being in the same breath, and that's ok. I'll hold
your hand.

- Go to Batteries Included's Releases Page on GitHub
  [here](https://github.com/batteries-included/batteries-included/releases/latest).
- Find the checksums.txt file and the archive for your platform and operating
  system.
- Check the [sha256](https://en.wikipedia.org/wiki/SHA-2) checksum.
- Unpack the archive into `~/.local/share/`.
- Create a symlink to the newly downloaded binary in `~/.local/bin`.
- Add `~/.local/bin` to your PATH if it's not already there.

## Setup NVIDIA Container Toolkit

Next we need to configure the NVIDIA Container Toolkit. To do that Batteries
Included provides a setup command. Run it:

```bash
sudo bash -c "$(~/.local/bin/bi gpu setup-command)"
```

## Verify (Optional)

Now if you want to verify your installation, and see the results simply run:

```bash
~/.local/bin/bi gpu validate-nvidia-ctk
```

This validates:

- NVIDIA GPU detection
- Container toolkit installation
- Docker daemon configuration
- GPU access from containers

The validation should pass with green checkmarks.

## Start Batteries Included

Finally all that is left to do is start the local cluster with NVIDIA support.

```bash
~/.local/bin/bi start-local
```

## Use the GPU

Now by default the Batteries Included platform will configure our batteries for
GPU usage. We have some example projects that you can explore. Simply create a
new project and select import from snapshot to try some of our example AI
projects.

If instead you would prefer to build yourself, two great places to start are:

### Ollama

1. Go to `AI` → `Ollama`.
2. Create an instance. Select "Any NVIDIA GPU".
3. Deploy models. They will use the GPU.

### Jupyter

1. Go to `AI` → `Jupyter Notebooks`.
2. Create a notebook. Select "Any NVIDIA GPU".
3. Your code can now access CUDA.

## How It Works

The `start-local` command automates everything:

1. Installs `bi` to `~/.local/share` and links to `~/.local/bin`.
2. Finds NVIDIA GPUs. Validates your setup.
3. Creates a Kind cluster.
4. Configures each node to expose the GPU to Kubernetes.
5. Installs the NVIDIA Device Plugin and Node Feature Discovery.
6. Configures Ollama and Jupyter for GPU scheduling.

## Troubleshooting

### Validate

Check your setup.

```bash
bi debug validate-nvidia-ctk
```

This checks GPU detection, toolkit, Docker, and runtime configuration.

### Common Issues

- **No GPUs found**: Does `nvidia-smi` work? Check your driver install and make
  sure that everything boots cleanly with `dmesg | grep -i nvidia`.
- **Docker errors**: Did the configuration get changed correctly?
- **Kind errors**: Is your machine overloaded or under heavy load?

## Next

- Deploy LLMs with [Ollama](/docs/ollama).
- Build ML pipelines with [Jupyter Notebooks](/docs/jupyter).
- Create vector databases with [PGVector](/docs/pgvector).
- Monitor GPU use.

You have local AI. With enterprise power. And full control.
