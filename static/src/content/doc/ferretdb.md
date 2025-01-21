---
title: 'FerretDB - MongoDB alternative'
description:
  FerretDB is a document-oriented database that provides a MongoDB-compatible
  API.
tags: ['ferretdb', 'database', 'mongodb', 'alternative', 'postgres']
category: batteries
draft: false
---

FerretDB is a document-oriented database that provides a MongoDB-compatible API.
It is built on top of PostgreSQL and offers a truly
[open-source](https://github.com/FerretDB/FerretDB) alternative to MongoDB.

## Installing FerretDB

To get started with FerretDB:

1. Navigate to the `Datastores` section in the control server.
2. Click `Manage Batteries`.
3. Find the `FerretDB` battery and click `Install`.

FerretDB also depends on the Postgres battery, which is installed automatically
when first starting the control server.

## Creating a FerretDB instance

To create a new FerretDB instance:

1. Go to the `Datastores` tab.
2. [Ensure that there is a Postgres instance](/docs/postgres) running.
3. Click `New FerretDB` in the FerretDB section.
4. Fill out the form with the desired settings, choosing the Postgres instance
   to use, along with memory and CPU limits.
5. Click `Save FerretDB` to finalize creation.

<video src="/videos/docs/ferretdb/ferretdb-create.mp4" controls></video>

## Accessing FerretDB

After creating a FerretDB instance, there will be a service created in the
`battery-data` namespace with the name of the FerretDB instance.

For example, from within a [Jupyter notebook](/docs/jupyter) we can easily
connect to the instance:

```python
from pymongo import MongoClient

# Using the IP shown in the FerretDB service
client = MongoClient('mongodb://10.244.0.33:27017')
client.server_info()
```

<div align="center">
   <img src="/images/docs/ferretdb/ferretdb-test.png" width="40%">
</div>

## Additional Resources

- Check out the official [FerretDB documentation](https://docs.ferretdb.io/) for
  more details.
