---
title: 'Platform Engineering is about change not starting templates'
excerpt:
  Enigneers often make the mistake of thinking that giving the correct defaults
  or starting code templates for software defined infrastructure is all that's
  needed to ensure consinsitency and reliablity in the future
publishDate: 2024-06-13
tags: ['terraform', 'platform', 'platform engineering', 'SDLC']
image: /images/posts/post-10.jpg
draft: true
---

Enigneers often make the mistake of thinking that giving the correct defaults or
starting code templates for software defined infrastructure is all that's needed
to ensure consinsitency and reliablity in the future. However expeience has
shown that giving templated code isn't enought to ensure future software
development velocity and reliability. Lets delve into the issues that can arise
when dealing with helm templates and how Batteries Included's automation and UI
solve the issues.

## Empowered Ownership

The best software is produced by teams of engineer who have the autonomy to make
the software in their vision. The engineers need to feel a culture of ownership
and empowerment. That ownership empowerment is hurt badly by a model where a
infrastructure team hands out the best helm or terraform templates to any
developer that needs a database, cache, or stream processing system, etc.

- Who owns the Infrastructure as Code itself? Product developers will not feel
  the ownership of code that's dropped from on high withouth any understanding.
  It's written by one team who makes periodic changes, while it's deployed by
  another team.
- The infrastructure team feels like a judmental parent that's watching their
  good advice not work well.
- Changes to productuction code now also deploy infrastrucure changes. Any
  breakage here likely will require a manual intervention, that developers who
  are not versed in YAML or terraform will struggle to complete by themselves.

## Drift

It's not just about ownership though code is a living entity that changes all of
the time. That unconstrained change in different groups cause the infrastructure
to drift aparrt and become unstable and brittle.

## Example

To illistrate the point lets take a pretend company with an infrastructure team
gave postgresl teffaform templates out to two different internal groups. Each
group started with the same values and defaults. All monitoring worked and
everything was standardized.

As time goes by team Foo's service might have more growth than the other (Team
Bar's service). Foo will need to expand the resources used by their
infrastructure and change the setting to work on the newly provisioned VM's or
hardware. Team Bar's service however never moves hardware and gets less and less
traffic.

When a new version of postgres comes out and the infrstucutre team asks that all
teams upgrade to the latest version they will likely also give guidance on what
changes are needed eg:

- 5% more memory is needed by the containers
- 1 extra core of cpu is needed for compression
- Less storage because autovacuuming is better

These changes to infrastructure are no longer safe to give out since the
different teams beause that initial terraform has changed in ways that we don't
know about. If the team that moved up to different hardware (Team Foo) tries to
use more memory, they could find themselves fighting the
[linux oom killer](https://github.com/facebookincubator/oomd) while the Bar team
will see everything working well.

Developers from team Foo or team Bar who are not versed in the infrastucture
will likely be unable to find the perfect solution to any issues that arise. For
example it's easy to stop using some memory by turning off monitoring/scraping
of metrics. It will solve the current issue and make the problem of drifting
infrastructure even worse.

# How To Solve This

- Make sure that changes to infrastructure are always safe. Automate all changes
  so that the changed fields are safety checked, that it's not even possible to
  edit fields in ways known to cause instability.
- Give the tools to make the correct changes easier than the suboptimal changes.
- All infastructure is deployed by teams or people that know how to operate the
  infrastucture. Don't ask a web developer to push postgresql and debug why IO
  patterns are different.
- All deployments of infrastrucutre need to be done safely which requires deep
  insights into metrics, traffic flows, and network architechture to ensure that
  the changes are safe. (This can not be done by pushing a git ops repo that
  blindly applies to kubernetes.)
