---
title: 'Running a Release'
description: How to run a new release of the platform.
tags: ['code', 'tools', 'internal']
category: development
draft: false
---

This shit should be automated but for now this is not too hard. Since it was
only in my head this is a better place.

- Take note of the current version in the repo. That is the version that we're
  going to release
- run `bix source set-version <YOUVERSION+1>`
- Send the resulting code change as a pull request. Title it
  `chore: prepare for <YOURVERSION+1>` or something like that. This will be the
  first commit in the next release/changelog.
- land the pull request
- After it lands `git pull`/`git fetch` and find the last commit before the
  prepare commit.
- Create the tag by taking the above commit's sha and runing
  `git tag -a <YOURVERSION> <YOURSHA>`
- Push that tag to github via `git push origin tag <YOURVERSION>`
- Verify that github actions for release run and the github release is there
