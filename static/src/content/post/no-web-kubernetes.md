---
title: 'No Web Developer Should Be Forced to Learn Kubernetes'
tags: ['kubernetes', 'web development']
image: ./covers/post-20.jpg
excerpt:
  'Web developers should focus on building features and solving problems for
  their users. They should not be forced to learn the intricacies of Kubernetes
  or any other infrastructure tool.'
draft: false
publishDate: 2025-02-06
---

GitOps purists will tell you that pressing a button to deploy or change an
application is bad practice because the developer isn't directly connected to
the change. That's nonsense. By that logic, no racecar driver knows how to use
their engine because the computer controls the fuel injection while they press a
button with their foot. Automation can allow focus on the things that matter in
a task.

Kubernetes is a complex distributed system with many sharp edges. It's a
powerful tool that can cause more harm than good when mishandled (as all
razor-sharp tools are). Recent trends in GitOps and DevOps have made it seem
obvious that every developer should own the entire lifecycle of their
applications, including deployment and operations, to ensure reliability and
stability are paramount. However, that doesn't work as well as it sounds.

The reality is that distributed computing is tough, and Kubernetes is complex.
No human can hold the entirety of a modern web application along with the cloud
and open source infrastructure powering it all in their head. When changing a
web application, the developer doesn't have the time or expertise to debug and
fix deployment issues as an expert. For example

- How do we add a new environment variable that refers to a secret?
- Does this require a StatefulSet or a Deployment?
- Does that warning about SSL certificates mean that the entire production is
  unprotected, or does it mean that Postgres is using a self-signed certificate?
- When growing the database to a new size, does that need to add new nodes to
  the cluster?
- How should we add a new service to the ingress controller?
- The deployment failed. Which service is causing the issue?

Web and/or product developers should focus on building features and solving
problems for their users. They should not be forced to learn the intricacies of
Kubernetes or any other infrastructure tool. That's why we have built
[Batteries Included](https://www.batteriesincl.com/), a platform that removes
the complexity of Kubernetes and other infrastructure tools, allowing developers
to focus on what they do best: building great products. The Batteries Included
platform provides a simple, intuitive interface for deploying and managing
applications and handles all the complexity of Kubernetes under the hood. It's
source available, so you can see how it works and contribute to its development.
