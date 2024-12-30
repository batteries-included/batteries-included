---
title: Jupyter Notebooks
description: Set up and manage Jupyter Notebooks for interactive development.
tags: ['AI', 'jupyter', 'notebooks', 'data-science']
draft: false
---

Jupyter Notebooks provide an interactive environment for data science, machine
learning, and general programming. With Batteries Included, you can quickly set
up notebooks with pre-configured environments for Python, R, Julia, etc.

## Installing Jupyter Notebooks

To get started with Jupyter Notebooks:

1. Navigate to the `AI` section in the control server.
2. Click `Manage Batteries`.
3. Find the `Notebooks` battery and click `Install`.

<video src="/videos/docs/jupyter/installing-jupyter.mp4" controls></video>

## Creating a Notebook

Once installed, you can create new notebooks:

1. Go to the `AI` tab
2. Click `New Notebook` in the Jupyter Notebooks section
3. Configure your notebook:
   - Give it a name
   - Choose the instance size
   - Add environment variables (optional)
   - Select advanced settings if needed

<video src="/videos/docs/jupyter/creating-notebook.mp4" controls></video>

## Accessing Your Notebooks

After creating a notebook:

1. Return to the `AI` tab
2. Find your notebook in the list
3. Click the `Open Notebook` button to launch the Jupyter interface
4. Choose from available kernels including Python, R, and Julia

<video src="/videos/docs/jupyter/opening-notebook.mp4" controls></video>

## Environment Variables

You can connect your notebook to other services by adding environment variables:

- Add database connections (e.g., `DATABASE_URL`)
- Configure API keys
- Set other environment-specific variables

These variables will be available in your notebook's environment automatically.

## Additional Resources

- Visit our [PGVector guide](/docs/pgvector) to learn how to create AI
  applications using PostgreSQL and PGVector with Jupyter Notebooks.
