#!/usr/bin/env bash

git ls-tree -zr --name-only HEAD |
  xargs -0 -n1 git blame --line-porcelain HEAD |
  grep -ae "^author " |
  sort |
  uniq -c |
  sort -nr
