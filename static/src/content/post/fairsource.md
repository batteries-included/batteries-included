---
title: 'The Promise and Challenge of Fair Source Licensing'
excerpt:
  Fair Source is a solid, sustainable approach to licensing for companies that
  use it proactively
publishDate: 2024-09-18
tags: ['open source', 'license', 'oss', 'company']
image: /images/posts/post-19.jpg
draft: false
---

Sentry announced a new software model called Fair Source in a blog post earlier
this month. The debate following this announcement has sparked heated
conversation. As a founder, open-source user, contributor, and community
advocate, I've thought a lot about the points of view in this conversation.
We're trying to take a step forward with finding a sustainable model for
software development that gives to the community as much as possible,
sustainibly.

## What We Are Looking For in a Licensing Agreement

Open source is a fundamental part of modern development. Businesses regularly
rely on open-source libraries and components to help them build flexible and
sustainable solutions. A license that allows the developers making the software
to continue creating solutions without competing priorities miring the process.
We want something that will work for the long term and allows us to build easy
to use automated infrastructure.

### Anchoring Principal

However, one of the challenges of a purely open-source model is that many assume
it is a cost-free solution and, as such, it has no value for them to pay for.
This assumption, known as
[the anchoring effect](https://en.wikipedia.org/wiki/Anchoring_effect), can lead
to the misconception that open-source software should always be free, which can
hinder the sustainability of compelling software.

Sentry developer [Armin Ronacher](https://github.com/mitsuhiko) addresses this
issue on his blog, arguing
[across several posts](https://lucumr.pocoo.org/2023/11/19/cathedral-and-bazaaar-licensing/)
for the value of a hybrid approach to open-source development.

Large businesses with correspondingly large bank balances should assume that
they will have to incentivize the building of the solutions that power modern
tech stacks. That means it's vital that any license communicates who can use the
software for free, who will have to pay, and in what amount.

### Open Core Split Priorities

One way that open source projects try to raise enough money to pay the bills is
by adopting an open core model. In this pattern, the core product is given away
for free, but some parts businesses need are kept closed-source. This results in
a split of priorities for open-source developers and companies, as the
developers may prioritize the open-source aspect, while the company may focus on
the proprietary tool to generate revenue.

The way I have seen this play out most often is that some group of developers
releases a new open-source project that's new and exciting while working for a
company. However, not everyone has the knowledge and understanding to use or
configure the latest software. So, the company employing the open-source
developers will create a tool that makes the open-source project easy to use or
integrate with others. From then on, the open-source community and the company
sponsoring the project will have different priorities.

The community wants open source to be easy to use and full-featured. They want
everything to be free and easy to access. While they usually don't contribute
the majority of the code, they still expect to have free and easy-to-change
access forever.

The company needs to be able to pay bills, so it wants as many sales of the tool
as possible. To do this, there needs to be some differentiation between the
open-source solution and the open-source solution combined with the proprietary
tool. The company is incentivised to keep open-source hard to use and complex,
while any large changes to open-source are potential revenue losses.

This split makes it difficult for everyone to move forward in the long term.
Instead, the projects become [enterprise zombies](https://hadoop.apache.org/),
hard to kill, and everyone is afraid to be too close.

### Open Source Sustainability

In
“[The Life and Death of Open Source Companies](https://lucumr.pocoo.org/2023/12/25/life-and-death-of-open-source/),”
Ronacher highlights the challenges of open-source businesses. He tells the story
of Josef Prusa, a developer of open-source 3D printing software and 3D printing
hardware. His main competitor, Bambu Labs, is larger, better financed, and (most
importantly) building its hardware on Josef's open software.

Because of this,
[Prusa is openly reconsidering his fully open-sourced approach](https://blog.prusa3d.com/the-state-of-open-source-in-3d-printing-in-2023_76659/)
to development because it lacks sustainability.

As Ronacher writes:

_"...building a true Open Source company is hard. Under the OSI definition of
open source, you are put at a massive disadvantage as you are prevented from
putting protections in place that shield you from other competitors in that
place who chose not to play by the same rules but can leverage your source."_

The world is starting to understand that, eventually, successful open-source
projects need to pay more developers than the free price tag allows. This forces
costs to be raised unexpectedly for open source users and is seen as a rug pull
or trick.

## What Is Fair Source?

In an August 2024 post, Sentry announced the [Fair Source](https://fair.io/)
movement, launching a campaign (including a website) to broadcast the more
concrete licensing terms and partner companies. This was an attempt to build a
more extensive network of partners while better defining how developers could
use code.

This project included three licensing structures that exist under "Fair Source":

- Functional Source Licensing (FSL)
- Fair Core Licensing (FCL)
- Business Source Licensing (BSL)

However,
[developer response was mixed](https://news.ycombinator.com/item?id=37092928)
precisely because the terms of this licensing weren't well-articulated. Many
perceived this as an attempt to have their cake and eat it too–to claim an
open-source product while closing their source code for some time.

## The Challenges of Fair Source So Far

Depending on your perspective, Fair Source is a massive move in the right
direction or a restriction on the potential of open source to remain open.

According to some, it limited the scope of OSS and harmed the development
community. Developers couldn't take existing code, build services or
innovations, and sell that software without adhering to more restricted
licenses.

Conversely, many developers heralded the move with a more well-defined approach
to how source code could be used, modified, and deployed while protecting the
projects of smaller creators or businesses who, under more permissive copyleft
frameworks, could see their software forked to oblivion by larger companies.

So… is Fair Source the right approach?

The short answer is that Fair Source is a solid, sustainable approach to
licensing for companies that use it proactively and transparently rather than
retroactively.

Let's be clear: open-source software is vital to tech success and innovation. We
see it as a necessity to keep people plugged in. Developers want to build
things, and the research bears that out the
[Github State of the Octoverse](https://github.blog/news-insights/research/the-state-of-open-source-and-ai/)
report showed that 2023 recorded the most significant number of first-time
open-source contributors ever.

However, we also recognize that OSS has its share of challenges that can stifle
innovation for developers and businesses that need to protect their work and
generate revenue to support that work. We understand these challenges and are
working towards solutions step by step.

License frameworks like Fair Source can support this if applied early in
development. That way, developers, users, and businesses involved with the
project know precisely where they stand.

The problem isn't with Fair Source licensing. Businesses need to adopt it early
and transparently. By starting early with this approach, companies can avoid the
confusion and (seeming) backtracking that comes with going from an open source
to a hybrid license model.

## Batteries Included and Our Commitment

We've adopted this license from day one; however, we want to be as open as
possible about the realities of building a business. Here is
[the license](https://www.batteriesincl.com/LICENSE-1.0). Stay tuned for the
source code release.
