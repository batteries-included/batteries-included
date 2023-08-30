---
title: 'DevOps and SRE: Lessons from the Frontlines'
date: 2023-08-17
tags: ['devops', 'sre', 'pe', 'usability']
draft: true
---

DevOps has been hailed as the knight in shining armor in the ever-evolving world
of software development and operations, promising to bridge the gap between
development and operations. However, as many have come to realize, the road to
DevOps nirvana is more complex than it seems. While the intention behind DevOps
is noble, its implementation often leaves much to be desired.

Let's embark on a journey to understand these challenges and how Site
Reliability Engineering (SRE) can guide DevOps toward a brighter future.

Some will correctly argue that SRE is just another form of DevOps, we’ll focus
on SREs as an engineering role in use by hyperscalers. And speak of DevOps as
written about and applied in practice today.

# The DevOps Dilemma

DevOps, at its core, is a transformative philosophy that seeks to break down the
silos between development (Dev) and operations (Ops) teams. It's a method of
bringing developers closer to the concerns and technologies of operations.
Stemming from the fusion of "development" and "operations," DevOps emphasizes
collaboration, automation, and integration.

While powerful, the introduction of GitOps, YAML configuration, and
infrastructure as code have also added layers of complexity. These tools, in
their essence, are meant to streamline processes, but they often end up
overcomplicating them.

Imagine a scenario where every time you wanted to make a cup of coffee, you had
to configure a YAML file, push it to a Git repository, and then execute a series
of commands. Sounds tedious, right? This complexity and friction is what many
teams face daily. Adding a new, more complex tool to the mix doesn't inspire a
team to produce software that's easy to operate. It can do the opposite.

## Friction

In software development and operations, friction is more than just a minor
inconvenience; it's a precursor to a cascade of challenges that can culminate in
detrimental business outcomes. Friction in any process, especially in software
development, acts as a bottleneck. When developers encounter obstacles that
hinder their workflow, it not only slows down the development process but leads
to shortcuts and workarounds. These shortcuts, while providing temporary relief,
often result in technical debt. As this debt accumulates, introducing new
features, fixing bugs, and maintaining the current system becomes increasingly
challenging. Over time, this can lead to an unreliable product, affecting
customer satisfaction and business results.

## Silos Aren't Just For Grain

![Golden Silo](./devops-pe/silo.png)

DevOps teams have many different challenges. One of the most daunting is the
siloed nature of their work. Production teams with designers, mobile, web, and
product specialists have vastly different day-to-day schedules. That leads to
DevOps being an ancillary team with almost insurmountable disadvantages.

## The Disconnect of Perspective

![Perspective](./devops-pe/perspective.png)

DevOps engineers, by the very nature of their role, focus on the intersection of
development and operations. Their primary concerns revolve around deployment,
scalability, and infrastructure. When they craft tools in these tools are often
optimized for these specific concerns. The things keeping a DevOps engineer up
at night are different from a product developer with business deadlines.

## The Skillset Mismatch

DevOps engineers possess a specialized skill set, honed for the challenges of
bridging development and operations. The tools they create are often tailored to
leverage this expertise. However, product teams might not share this same skill
set. Introducing a tool that requires a deep understanding of, container
orchestration, to a frontend developer or a UX designer, can be overwhelming.
It's akin to handing someone a pile of razor and being surprised they cut their
hands.

## The "Not Invented Here" Syndrome

It's a human tendency to be wary of solutions crafted outside one's immediate
team or circle. This phenomenon, often termed the "Not Invented Here" syndrome,
can be a significant barrier to the adoption of tools. When a product team sees
a tool crafted by someone outside their immediate circle, there's an inherent
skepticism. They might question its relevance, its efficiency, or even its
necessity. This skepticism is amplified if the tool doesn't immediately resonate
with their needs.

## Communication Gaps

![Communications](./devops-pe/communications.png)

Siloed development often leads to communication gaps. When a DevOps engineer
crafts a tool in isolation, there's limited feedback from potential end-users
(i.e., the product team). Without this feedback loop, it's challenging to ensure
that the tool aligns with the product team's requirements. When the tool is
finally presented, it might seem alien or misaligned, leading to resistance.

# Enter the SRE/PE

[Site Reliability Engineers (SREs)](https://sre.google/books/) or
[Production Engineers (PEs)](https://engineering.fb.com/category/production-engineering/)
bring a fresh perspective to this puzzle. Unlike traditional sysadmins, who
operate systems separate from developers, only meeting developers when things go
wrong, SREs are specialized engineers who join teams for limited time
engagements building tools and fixing while being part of the team.

[Google](https://google.com), a tech behemoth known for its vast array of
services and [unparalleled scale](https://www.youtube.com/watch?v=3t6L-FlfeaI),
has been a pioneer in adopting and promoting the Site Reliability Engineering
(SRE) model. SRE at Google is not just a role but a philosophy. It's predicated
on the belief that the best way to ensure system reliability is by embedding
engineers, who have a deep understanding of operational systems, directly into
the teams building the product. These SREs work hand-in-hand with product
developers, ensuring that the software is not only functional but also scalable,
reliable, and efficient.

They focus on automating as many operational tasks as possible, adhering to the
principle that "operations is a software problem." This automation-centric
approach not only reduces manual intervention and associated errors but also
allows for rapid scaling and adaptability.

SREs don’t simply build tools and automation. They immerse themselves in the
team, setting the tone for development. They are educators, teaching teams the
art of producing functional and operable systems. This hands-on approach ensures
the tools and the team's culture are internally developed. The team creates a
habit of using the tools to operate and build code. When an SRE transitions to
their next assignment, they don't just leave behind tools; they leave behind a
legacy. A legacy of a team that's empowered, educated, and equipped to navigate
the challenges of modern software development through automation.

# The Human Element

> Computers are infallible; humans are not.

This adage, while simplistic, captures the essence of most production issues in
the software realm. It's a humbling realization that while our digital creations
are marvels of modern ingenuity, they are also susceptible to the imperfections
of their creators. Most production hiccups, from minor glitches to major
outages, can be traced back to human interventions. Whether it's a code change
that didn’t get reviewed,
[a configuration tweak that went awry](https://engineering.fb.com/2021/10/05/networking-traffic/outage-details/),
or a manual override that had unintended consequences, the human touch,
particularly from those closest to the software. The developers are often the
root cause.

As a developer, many times, the most impactful thing you can do for operations
is to protect operations from yourself.

## Testing

![Science!](./devops-pe/testing.png)

As [Robert C. Martin](https://cleancoders.com/series/clean-code) aptly said,
"Truth can only be found in one place: the code." But what happens when that
truth is distorted by human error? That is where tests come into play. They are
our guardians, ensuring that the software we envisioned aligns with what's
running in production. However, like any tool wielded by humans, its efficacy
can be a mixed bag.

While tests are invaluable, their quality and relevance can vary dramatically.
It's a delicate balance. On one hand, over-testing can bog down the development
process, making it cumbersome and inefficient. Conversely, the wrong kind of
tests or flakey tests can give a false sense of security or mask potential
security issues lurking beneath the surface.

### Zoom Zoom

![Formula One Car](./devops-pe/car.png)

> Testing leads to failure, and failure leads to understanding -- Burt Rutan

Developers aren't resistant to change; they're resistant to slowdowns. If
presented with tools that enhance safety without compromising speed, adoption
becomes a no-brainer. It's akin to offering a race car driver a vehicle that's
not only faster but also equipped with the best safety features. Who would say
no?

Removing old, redundant tests is a step in this direction. While tests are
crucial, outdated or irrelevant tests can clutter the development process,
providing a false sense of security without adding real value. By pruning these
tests, developers can focus on what truly matters, ensuring that their code is
both efficient and robust.

### Borring Asserts Aren't Interesting

Complemented by integrated DevOps tools like monitoring and tracing, a
well-crafted test can be a game-changer.

For example, when asserting that the metrics match, a test can be a unit test
and ensure monitoring is functional with helpful information. Or a performance
integration test that is part of the CI/CD pipeline can ensure production
infrastructure as code ( IaC ) works while giving developers a new superpower to
test if their code is faster or slower.

### Tests The First Corner Cut

Tests are just another system that take effort to understand and operate.
However that that time is especially well spent for DevOps engineers. Testing
shows what development teams are doing day to day. They provide a fascinating
view into what's changing, how often, what's flakey, and if developer fears
match production. Time spent bridging gaps of understanding or expectations with
tests has an outsized impact, because they are a leading indicator of where
corners are being cut to move faster.

# The Way Forward

![Path](./devops-pe/path.png)

DevOps has historically focused on pushing developers in the direction of
operations and automating that. While SREs are about bringing the sysadmin
knowledge to the team in order to build automation. That difference is huge in
the outcome. So lets learn from SREs and help developers better.

- _Embed and Engage_: Join teams for limited engagements. Understand their
  needs, challenges, and goals. Shared experiences grow mutual trust.
- _Educate_: Make monitoring, alerting, and logging an integral part of the
  development process. Teach teams the value of these practices, not just for
  production but also for smoother development cycles.
- _Build and Integrate_: Focus on crafting tools and systems that resonate with
  the team (especially testing). Understand their requirements and tailor
  solutions accordingly.
- _Evolve_: Your role is about something other than maintaining YAML hygiene or
  fixing pipeline issues. It's about education, tool development, and then
  moving on to the next challenge so that the business can as well.
