# home-tools
Repository with muy favourite tools to be deployed on Kubernetes with Terraform

## Pre-Commit hook
This repository contains a git hook that formats the files before any commit.
For the pre-commit to occur, change the git hook folder with:
```
git config --local core.hooksPath .githooks/
```