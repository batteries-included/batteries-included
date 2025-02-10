---
title: 'Contextual Information Makes Platforms More Stable'
publishDate: 2025-02-10
tags: ['sev', 'sev-review', 'ui', 'ux', 'stability']
draft: false
---

Learning from operational mistakes is critical, so I was excited to read a
well-written postmortem from Cloudflare's Feb 6th, 2025 incident. The
[postmortem](https://blog.cloudflare.com/cloudflare-incident-on-february-6-2025/)
is a great read, and I think it shows a lot about how well CloudFlare has
handled this that the article is out so soon after the incident. For today, I
want to focus on things that could have stopped the cause of the incident.
Reading the blog post, I don't see much that could be optimized regarding how
the incident was managed or how the issue was fixed. Meaning that the most
impactful thing we can do is to learn how to stop this kind of incident from
happening in the first place.

## The Incident Cause

The incident was caused when an abuse report was acted upon. A human ran some
procedure (editing JSON/Yaml or entering the data into a text field) to turn off
services on their API gateway layer. This mistaken action eventually disabled
the root service for their
[R2 Object Storage](https://www.cloudflare.com/developer-platform/products/r2/)
product, causing a cascading failure that took down dependent services and
customers. The post doesn't specify how the root R2 service was targeted, but
rather, the expected user-related endpoint inside.

## Tags for Context

CF themselves say that one of the causes of this was not having the correct
contextual information. They say:

> A key system-level control that led to this incident was how we identify (or
> "tag") internal accounts used by our teams.

> Our abuse processing systems were not explicitly configured to identify these
> accounts and block disablement actions against them.

In other words the contextual information of ownership was not available to the
person/system making the change. If the operator had been shown some UI, a
dialogue, or a warning that said "this is tagged as a prod service", it's very
likely that the operator would have stopped and thought about what they were
doing.

## Other Useful Information For Operators

Ownership tags, though, aren't the only information that could have stopped
this. The operator was acting on an abuse report and had an expectation of what
their actions would do. If they were shown this action would disable 100% of the
R2 service throughput or this would disable the `X,000,000` number of endpoints,
then the person could have stopped and investigated the anomaly. Showing a graph
of the impact would have been even better.

From experience, systems that inform operators of the current status and the
impact of their actions have fewer human errors. Human errors are the leading
cause of downtime incidents.

## Passing Contextual Information

However, there's more information that we can pass along to make our systems
more stable. The reason this action was being performed should also have been
passed along. When the operator took the information from the abuse report and
entered it into the system disabling process, the system lost the context of why
the action was being taken. If the abuse report had a link that, when clicked,
transferred them to a pre-filled-out UI that only accepted endpoints and not
services, then the operator would not have been using a sledgehammer to kill a
fly.

# Conclusion

I don't want to be too long-winded, so here are a few bullet points on things
that we all can learn from this incident and the CF writeup:

- Systems that pass along contextual information are more stable
- Show the impact of actions to operators
- Show the current system state to operators
- Pass along why actions are being taken to all layers of a system

Spoiler: We at Batteries Included are big believers in including lots of context
in operational platforms. Check out our
[github](https://github.com/batteries-included/batteries-included),
[docs](/docs), or
[demo videos](https://www.youtube.com/@BatteriesIncludedPlatform/videos) for
more.
