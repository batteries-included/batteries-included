---
title: 'DevOps and SRE: Lessons from the Frontlines'
excerpt:
  DevOps aims to bridge the gap between software development and operations, but
  its implementation can face serious challenges.
publishDate: 2024-06-08
tags: ['devops', 'sre', 'pe', 'usability']
image: ./covers/post-3.jpg
draft: true
---

DevOps emerged as one of the primary approaches to bridge the gap between these
traditionally separate domains in software development and operations. Yet, for
many organizations, the actual implementation of DevOps principles often proves
more complex than anticipated.

This article examines these challenges and also explores how we can learn from
[Site Reliability Engineering (SRE)](https://sre.google) to enhance DevOps
practices.

Note: some will argue that SRE is a form of DevOps; for this discussion, we'll
focus on SRE as the engineering role used by hyperscalers and consider DevOps as
it is commonly described and applied in industry practice today.

## The DevOps Dilemma

_DevOps_ is a philosophy that seeks to integrate software development and
operations-- emphasizing collaboration, automation, and integration. While this
sounds exciting, development teams have differing needs, leading to a
proliferation of tools and practices like GitOps, YAML workflows, infrastructure
as code, etc. While these are intended to streamline processes, they often add
layers of complexity.

Imagine a scenario where every time you wanted to make a cup of coffee, you had
to configure a YAML file, push it to a Git repository, and then execute a series
of commands. Sounds tedious, right? Many teams face this complexity and friction
daily. Adding a new, more complex tool to the mix doesn't inspire a team to
produce easy-to-operate software; it can do the opposite.

One of DevOps' primary challenges is addressing friction in the development
process. When developers encounter obstacles to their workflow, it's not
uncommon for them to resort to band-aid fixes or short-sighted workarounds. As
time passes, these practices accumulate technical debt, impeding the
introduction of new features, bug fixes, and system maintenance, ultimately
affecting business outcomes and customer satisfaction.

## Silos Aren't Just For Grain

![Silo](./devops-pe/waldemar-7kSnMLGoR9w-unsplash.jpg)

Another substantial challenge is the inherently siloed nature of DevOps work.
Production teams, comprised of specialists like designers, mobile developers,
web developers, and product managers, often operate on different schedules and
priorities. This can turn DevOps into an ancillary team facing unique
challenges.

DevOps engineers focus on deployment, scalability, and infrastructure, which
tends to differ from product developers, who are often more concerned with
business deadlines and feature development. This specialization gap can create
significant barriers to adopting new tools and practices:

- Introducing new and complex tools to team members without the necessary
  background may face resistance.
- Teams may be skeptical of solutions developed outside their immediate circle,
  a phenomenon known as "Not Invented Here" (NIH) syndrome.
- When DevOps engineers create tools in isolation, there's often limited input
  from potential end-users (e.g., the product team), resulting in insufficiently
  vetted tools.
- Absence of regular feedback from end-users may lead to misaligned priorities
  and inefficient resource allocation.

## The SRE Solution

[Site Reliability Engineers (SREs)](https://sre.google/books/) or
[Production Engineers (PEs)](https://engineering.fb.com/category/production-engineering/)
bring a fresh perspective to these challenges. Unlike traditional sysadmins, who
operate systems _separate_ from developers, SREs are specialized engineers who
join teams for limited engagements, build tools, and address issues while being
part of the team.

[Google](https://google.com), a tech behemoth known for its vast array of
services and [unparalleled scale](https://www.youtube.com/watch?v=3t6L-FlfeaI),
has been a pioneer in adopting and promoting the SRE model. At Google, SRE is
not just a role but a philosophy based on the belief that embedding engineers
with deep operational knowledge into product teams is the most effective way to
ensure system reliability. These SREs work hand-in-hand with product developers,
ensuring that the software is functional but also scalable, reliable, and
efficient.

SREs focus on automating as many operational tasks as possible, adhering to the
principle that "operations is a software problem." This approach reduces manual
intervention and associated errors while allowing for rapid scaling and
adaptability. SREs don't simply build tools and automation; they immerse
themselves in the team, influencing development practices. They act as
educators, teaching teams how to produce more robust systems.

SRE responsibilities are diverse-- a significant portion of time is spent on
operations work, including emergency incident response, change management, and
IT infrastructure management. These engineers also support the development team
in creating new features and stabilizing production systems while continuously
improving processes through post-incident reviews and knowledge sharing.

This hands-on approach ensures that the tools and the team's culture are
internally developed. When an SRE transitions to their next assignment, they
don't just leave behind tools; they leave behind a legacy. A legacy of a team
that's empowered, educated, and equipped to navigate the challenges of modern
software development through automation.

## Testing and The Human Element

![Science!](./devops-pe/testing.png)

> Computers are infallible; humans are not.

This adage, while simplistic, captures the essence of most production issues in
the software realm. Most production hiccups, from minor glitches to significant
outages, can be traced back to human intervention. Whether it's an inadequately
reviewed code change,
[a configuration tweak that went awry](https://engineering.fb.com/2021/10/05/networking-traffic/outage-details/),
or an unintended consequence of a manual override, human error is often the root
cause-- particularly from those closest to the software.

As a developer, many times, the most impactful thing you can do for operations
is to protect operations from yourself.

Testing plays a crucial role in verifying that the software aligns with its
intended functionality. As Robert C. Martin once noted, _"Truth can only be
found in one place: the code." _ But what happens when that truth is distorted
by human error? That is where tests come into play, ensuring that the software
we envisioned aligns with what's running in production. However, like any tool
wielded by humans, its effectiveness varies significantly. Over-testing can slow
development, while inadequate or irrelevant tests can provide a false sense of
security. Striking the right balance is crucial.

The good news is that developers aren't resistant to change; they're resistant
to slowdowns. If presented with tools that enhance safety without compromising
speed, adoption becomes a no-brainer. It's akin to offering a race car driver a
faster and better-equipped vehicle with the best safety features. Who would say
no?

Removing old, redundant tests is a step in this direction. While tests are
crucial, outdated or irrelevant tests can clutter the development process,
providing a false sense of security without adding real value. By pruning these
tests, developers can focus on what truly matters, ensuring their code is
efficient and robust.

Well-crafted tests can be a game-changer when complemented by integrated DevOps
tooling like monitoring and tracing.

For example, when asserting that metrics match, a test can be a unit test, and
monitoring is verified to be functional with helpful information. Additionally,
a performance integration test part of the CI/CD pipeline can ensure production
infrastructure as code (IaC) works while giving developers a new superpower to
test if their code is faster or slower.

Tests can provide fascinating insights into development team practices;
revealing what's changing, how often, where potential issues could come from,
and if the developer fears match production. Focusing on bridging gaps in
understanding or expectations through tests can have an outsized impact, as they
are a leading indicator of where corners are being cut to move faster.

> Testing leads to failure, and failure leads to understanding -- Burt Rutan

## Moving Forward: Improving DevOps Practices

![Path](./devops-pe/path.png)

While DevOps has historically focused on bringing developers closer to
operations via automation, SRE aims to bring sysadmin knowledge directly to
development teams to build automation. This distinction can lead to
significantly different outcomes.

So let's learn from SREs and help developers better!

To improve DevOps practices, consider the following approaches:

1. **Embed and Engage**: Join teams for limited periods to understand their
   needs, challenges, and goals. Shared experiences foster mutual trust.

2. **Educate**: Integrate monitoring, alerting, and logging into the development
   process. Demonstrate the value of these practices for both production and
   development cycles.

3. **Build and Integrate**: Develop tools and systems that align with team
   needs, particularly in testing. Tailor solutions based on a thorough
   understanding of team requirements.

4. **Evolve**: Your role extends beyond merely maintaining YAML hygiene or
   fixing pipeline issues. It's about education, tool development, and then
   moving on to the next challenge so the business can also.

The path ahead for DevOps isn't just about tweaking configurations - it's about
rolling up our sleeves, joining forces with dev teams, and building stuff that
actually makes their lives easier.
