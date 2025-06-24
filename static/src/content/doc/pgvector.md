---
title: 'AI with PGVector and PostgreSQL'
description:
  Create AI applications using PostgreSQL and PGVector with Jupyter Notebooks.
tags: ['AI', 'Postgres', 'PGVector', 'Jupyter Notebooks']
category: getting-started
draft: false
---

This guide shows you how to use `pgvector` with PostgreSQL and the OpenAI API to
build AI applications. We'll cover embeddings, vector similarity search, and how
to implement them in your projects.

PostgreSQL is a reliable, feature-rich open-source database, and pgvector
extends it with powerful vector similarity search capabilities. This combination
lets you efficiently store and query the high-dimensional vectors used in AI
applications like recommendation systems, natural language processing, and image
recognition, all within a familiar SQL environment.

## The Power of Embeddings in AI

_Embeddings_ are at the heart of many modern AI applications. They are vector
representations of data that capture semantic meaning and relationships.
Embeddings measure how related text strings are, allowing for more nuanced
comparisons than simple text matching.

An embedding is essentially just a list (vector) of floating-point numbers. The
distance between two vectors measures their relatedness. Small distances suggest
high relatedness, while large distances suggest low relatedness. This makes
embeddings incredibly useful for tasks like semantic search, recommendation
systems, and content-based filtering.

## Why Vector Databases Matter

Vector databases, like Postgres with `pgvector`, offer significant advantages in
AI applications:

1. **Efficient Similarity Search**: They excel at finding "similar" items, which
   is often more valuable than exact matches in AI applications.

2. **Handling High-Dimensional Data**: They're optimized for storing and
   querying high-dimensional vectors produced by machine learning models.

3. **Scalability**: Specialized indexing methods allow for quick queries even
   with millions of vectors.

4. **Semantic Understanding**: They enable context-aware searches, understanding
   the meaning behind queries.

These capabilities make vector databases ideal for various AI applications,
including:

- Recommendation systems
- Semantic search engines
- Content-based filtering
- Image and audio similarity search
- Natural language processing tasks

By augmenting Postgres with `pgvector`, developers can leverage these powerful
capabilities while still benefiting from the robustness and extensive feature
set of a mature relational database system.

## Starting an AI Project with Batteries Included

Batteries Included offers a streamlined approach to working with AI projects,
complete with integrated database support. We'll be using _Jupyter Notebooks_ to
run Python code and interact with both the OpenAI API as well as a Postgres
database.

Jupyter Notebooks provide an interactive environment where you can write and
execute code, visualize data, and document your work all in one place. This
makes them ideal for exploratory data analysis, prototyping AI models, and
sharing results with others.

Let's get started!

### Step 1: Install the Jupyter Notebook Battery

First, we need to install the Battery that allows us to create Jupyter
Notebooks:

1. Open the control server and navigate to the `AI` section.
2. Install the `Jupyter Notebook` Battery, granting us the ability to create
   Notebooks.

<video src="/videos/pgvector/ai-battery-creation.webm" controls></video>

### Step 2: Create a PostgreSQL Cluster

Next up, we need the actual database we will use together with the Jupyter
Notebook. Batteries Included makes this easy:

1. Navigate to the `Datastores` section.
2. Click on `New PostgreSQL` to begin creation.
3. Add or modify a user to be in the `battery-ai` namespace. This will store the
   user credentials in a secret that is accessible by the AI Battery.
4. Click `Save Postgres Cluster` to finalize creation.

<video src="/videos/pgvector/creating-database.webm" controls></video>

### Step 3: Set Up the Jupyter Notebook

Lastly, we need to create the Jupyter Notebook itself:

1. Let's navigate back to the `AI` tab.
2. There should be a `Jupyter Notebooks` section available now. Click on
   `New Notebook` to begin creation.
3. We're going to go ahead and add two environment variables:
   - `OPENAI_KEY`: We'll be using OpenAI to generate embeddings, so we need an
     API key to authenticate.
   - `DATABASE_URL`: Navigate to the `Secret` tab, and point this to the `DSN`
     secret created by the Postgres cluster in the previous step.

4. Click `Save Notebook` to finalize creation.

<video src="/videos/pgvector/jupyter-creation.webm" controls></video>

> **Note:** It might take a few moments for the Notebook to finish initializing.

### Locally Accessing the Database

For local development or when you want to use your own tools to set up the
database with embeddings, you can use the `bi` CLI tool to get a connection
string for your PC:

```bash
export DATABASE_URL=$(bi postgres access-info mycluster myusername --localhost)
```

This command retrieves the connection information for your Postgres cluster,
which you can then use with e.g. PgAdmin or DBeaver. You can skip this step if
you're only using the Jupyter Notebook or connecting remotely.

> **Note:** The `app` database is used by default.

### Step 4: Initializing the Jupyter Notebook

Go ahead and open up the Jupyter instance and start a Python 3 Notebook.

<video src="/videos/pgvector/notebook-creation.webm" controls></video>

Now we're ready write code. Let's begin by installing the packages we'll be
using:

```python
!pip install psycopg2-binary
!pip install openai
!pip install pgvector
```

`psycopg2` is a PostgreSQL adapter for Python, `openai` is the official Python
client for the OpenAI API, and `pgvector` is needed to interface with the
pgvector extension in our Python code.

Now, connect to the database using the `DATABASE_URL` environment variable:

```python
import psycopg2
import os

conn = psycopg2.connect(os.environ['DATABASE_URL'])
cur = conn.cursor()
```

### Step 5: Set Up `pgvector` and Create the Documents Table

Next, we'll set up `pgvector` and create a table to store our documents and
their embeddings:

```python
import openai
import numpy as np
import psycopg2
from pgvector.psycopg2 import register_vector
from openai import OpenAI

# Set up OpenAI API
client = OpenAI(api_key=os.environ['OPENAI_KEY'])

# Install pgvector
cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
conn.commit()

register_vector(conn)

# Create a table to store documents and their embeddings
cur.execute("""
CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding VECTOR(1536)
);
""")

conn.commit()
```

### Step 6: Import Example Dataset and Create Embeddings

Now, let's create an example dataset and generate some embeddings:

```python
# Sample documents
documents = [
    "Foxes are great night-time predators",
    "Foxes can make over 40 different sounds",
    "Foxes make use of the earth's magnetic field to hunt",
    "Baby foxes are unable to see, walk or thermoregulate when they are born",
]

for doc in documents:
    # Generate embedding using OpenAI
    response = client.embeddings.create(input=doc, model="text-embedding-ada-002")
    embedding = response.data[0].embedding

    # Insert document + embedding into the database
    cur.execute("INSERT INTO documents (content, embedding) VALUES (%s, %s);", (doc, embedding))
    conn.commit()
```

## Leveraging `pgvector`

Now that we have our environment set up and data stored, let's explore how we
can use `pgvector` in our AI applications.

1. **Indexing**: Let's start by creating an index on the embedding column to
   speed up similarity searches:

```python
cur.execute("CREATE INDEX ON documents USING ivfflat (embedding vector_l2_ops);")
conn.commit()
```

2. **Similarity Search**: When a query comes in, let's generate an embedding for
   the query and use pgvector's similarity search capabilities to find the
   nearest row in your database:

```python
def find_similar_document(query):
    # Generate embedding for the query
    response = client.embeddings.create(input=query, model="text-embedding-ada-002")
    query_embedding = response.data[0].embedding

    # Perform similarity search
    cur.execute("""
    SELECT content, embedding <-> %s::vector AS distance
    FROM documents
    ORDER BY distance
    LIMIT 1;
    """, (query_embedding,))

    return cur.fetchone()

# Example usage
similar_doc = find_similar_document("I was wondering, how many sounds can foxes make?")
if similar_doc:
    doc, distance = similar_doc
    print(f"Distance: {distance:.4f}, Content: {doc}")
else:
    print("No similar document found.")
```

This function will return the most similar document to the given query, along
with its distance score.

For example, performing a vector similarity search with the string:

`I was wondering, how many sounds can foxes make?`

Yields:

`Distance: 0.4075, Content: Foxes can make over 40 different sounds`

## Wrapping Up

And that's really it! As your projects grow, you can effortlessly manage
millions of vectors while maintaining swift query times, thanks to Postgres and
`pgvector`'s efficient indexing. Whether you're developing a cutting-edge
recommendation system or diving into novel AI applications, this combination
offers a flexible and powerful platform to realize your ideas.
