---
title: Keycloak
description: Set up and manage authentication and identity with Keycloak.
tags: ['security', 'authentication', 'oauth', 'sso']
category: batteries
draft: false
---

Keycloak is an open-source Identity and Access Management (IAM) solution that
provides authentication, authorization, and user management for modern
applications and services.

In Batteries Included, Keycloak can easily serve as the foundation for secure
authentication across your infrastructure.

## Installing Keycloak

To install Keycloak:

1. Navigate to the `Net/Security` section in the control server.
2. Click `Manage Batteries`.
3. Find the `Keycloak` battery and click `Install`.
4. Optionally configure the installation (defaults recommended.)

<video src="/videos/docs/keycloak/keycloak-install.mp4" controls></video>

## Managing Realms

After installation, Keycloak automatically creates two default realms: the
`Batteries Included` realm and the `Keycloak` realm. You can manage these realms
through the `Net/Security` section in the `Realms` subsection. Each realm has
its own dedicated page in the control panel where you can access the admin
console, manage users, and configure realm settings.

## User Management

To add new users to a realm:

1. Navigate to the realm's page.
2. Click `New User` in the Users section.
3. Fill in the required information.
4. Click `Create User`.

After creating a user, you'll receive a temporary password, and after using it
will prompt you to change it on first login. After the password change and
proper permissions, they'll have access to the Keycloak dashboard.

<video src="/videos/docs/keycloak/keycloak-add-user.mp4" controls></video>

## Identity Providers

Through the Keycloak admin console, you can configure various identity providers
including standard protocols like OpenID Connect and SAML v2.0, as well as
popular social and enterprise providers like Google, GitHub, Microsoft, etc.

<img src="/images/docs/keycloak/keycloak-identity.png">

## Understanding Keycloak and SSO

Keycloak works in conjunction with the SSO (Single Sign-On) battery in Batteries
Included:

- The Keycloak battery provides the authentication service itself.
- The SSO battery (installed separately) configures all other batteries to use
  Keycloak for authentication.
- Together, they create a unified authentication system across your entire
  installation.

## Additional Resources

- For detailed configuration options and advanced features, visit the
  [official Keycloak documentation](https://www.keycloak.org/documentation).
