---
title: Certificates
description:
  Automatically manage SSL/TLS certificates and trust bundles using Cert
  Manager, Battery CA, and Trust Manager batteries.
tags: ['security', 'certificates', 'tls', 'ssl']
category: batteries
draft: false
---

Batteries Included provides comprehensive certificate management via three
batteries:

- Cert Manager: Automates X.509 certificate management and issuance.
- Battery CA: Acts as the Certificate Authority for your installation.
- Trust Manager: Manages TLS trust bundles across your cluster.

SSL/TLS certificates secure internet traffic by encrypting data and verifying
website authenticity. Batteries Included automates the entire process by
integrating cert-manager, Let's Encrypt, Istio, and Knative to handle
certificate issuance, renewal, and SSL configuration across all services.

When deployed on public-facing infrastructure (like AWS or other cloud
providers), Batteries Included automatically installs and configures these
components for secure certificate management.

For local development environments (i.e. Kind), these batteries are optional
since everything runs locally.

All three batteries require minimal setup - once installed, they work
automatically with no additional configuration required!

## Cert Manager

Cert Manager is a Kubernetes controller that automates the management and
issuance of TLS certificates. It supports various certificate sources and
ensures your certificates stay valid by handling renewals automatically.

Cert Manager provides automated certificate issuance and renewal, and offers
Kubernetes-native certificate management that integrates seamlessly with your
infrastructure.

### Installing Cert Manager

To set up Cert Manager:

1. Navigate to the `Net/Security` section in the control server.
2. Click `Manage Batteries`.
3. Find and install the `Cert Manager` battery.
4. Optionally provide an email address for certificate-related notifications.

For cloud deployments, Cert Manager is typically installed automatically as part
of your initial setup.

<video src="/videos/docs/certificates/installing-cert-manager.mp4" controls></video>

## Battery CA

Battery CA serves as the internal Certificate Authority for your Batteries
Included installation. It provides the internal PKI infrastructure necessary for
secure service-to-service communication and certificate signing for internal
services. Once installed, Battery CA requires no additional configuration.

### Installing Battery CA

To set up Battery CA:

1. Navigate to the `Net/Security` section in the control server.
2. Click `Manage Batteries`.
3. Find and install the `Battery CA` battery.

<video src="/videos/docs/certificates/installing-battery-ca.mp4" controls></video>

## Trust Manager

Trust Manager simplifies how applications in your cluster trust and verify
certificates. It provides centralized management of trusted certificates and
automatically updates all applications when trust settings change. Like other
certificate batteries, it requires no configuration after installation.

### Installing Trust Manager

To set up Trust Manager:

1. Navigate to the `Net/Security` section in the control server.
2. Click `Manage Batteries`.
3. Find and install the `Trust Manager` battery.

<video src="/videos/docs/certificates/installing-trust-manager.mp4" controls></video>

## Additional Resources

- Read the official [Cert Manager](https://cert-manager.io/docs/) and
  [Trust Manager](https://cert-manager.io/docs/trust/trust-manager/)
  documentation for detailed information.
