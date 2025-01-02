---
title: PostgreSQL
description: Start and manage a PostgreSQL database with Batteries Included.
tags: ['database', 'postgres', 'datastore']
category: batteries
draft: false
---

Batteries Included ships with PostgreSQL support out-of-the-box. This guide will
walk you through creating and managing a PostgreSQL cluster.

## Creating a PostgreSQL Cluster

Creating a PostgreSQL cluster is straightforward:

1. Navigate to the `Datastores` section.
2. Click on `New PostgreSQL` to begin creation.
3. Configure your cluster settings (users, namespaces, size, database name,
   etc.).
4. Click `Save Postgres Cluster` to finalize creation.

<video src="/videos/postgres/creating-database.webm" controls></video>

## Users and Namespaces

When you create a PostgreSQL cluster, Batteries Included automatically generates
random passwords for each user. These credentials are stored in a Secret within
the cluster's namespace.

## Adding or Modifying Users

You can add or modify users either during cluster creation or afterwards:

1. Navigate to the `Datastores` section.
2. Select `Edit Cluster` to the right of your PostgreSQL cluster.
3. In the `Users` section, you can add new users or modify existing ones.
4. For each user, you can specify which namespaces should have access to their
   credentials.

## Namespaces

To make user credentials available in different namespaces:

1. When creating or editing a user, you'll see a `Namespaces` section.
2. Select the namespaces where you want the user's credentials to be available.
3. When your changes are applied, copies of the credential secret will be
   created in these namespaces.

This allows you to control which namespaces have access to specific database
users, enhancing security and flexibility in your cluster setup. For instance,
if you want to access your PostgreSQL database from a Jupyter Notebook battery,
you can add your user to the `battery-ai` namespace, and then reference it in
that battery's environment variables.

## User Roles and Permissions

The PostgreSQL battery offers various roles that define what actions a user can
perform. When creating or editing a user, you can assign any of the following
roles:

- `Superuser`: Grants full administrative privileges.
- `Createdb`: Allows the user to create new databases.
- `Createrole`: Permits the user to create new roles.
- `Inherit`: Enables inheritance of privileges from roles the user is a member
  of.
- `Login`: Allows the user to log in to the database.
- `Replication`: Designates the user as a replication user.
- `Bypassrls`: Determines whether the user bypasses row-level security (RLS)
  policies.

Select the appropriate roles based on the level of access and capabilities you
want to grant each user.

## Connecting to Your PostgreSQL Cluster Locally

For local development, you can use the `bi` CLI tool to get a connection string:

```bash
export DATABASE_URL=$(bi postgres access-info mycluster myusername --localhost)
```

This command retrieves the connection information for your specific cluster and
user, which you can then use with tools like pgAdmin.
