# Introduction

Welcome to **observability-sensei**.

If you've ever shipped a green build and still broken production, you're in the right place.

## What this repo is

This is not a slide deck about DevOps. It's a hands-on project with:

- A real TypeScript API instrumented for production
- GitHub Actions pipelines you can copy into your projects
- Bash scripts for health checks, metrics validation, and rollback
- A local Docker stack with Prometheus and Grafana

## What this repo is not

- A managed SaaS product
- A replacement for your company's platform team
- A certificate course with quizzes

We teach **mindset + tooling** the way you'd learn on a strong platform team: by doing.

## Who this is for

- Backend developers moving into CI/CD ownership
- DevOps engineers onboarding juniors
- Tech leads who want their team to think beyond "pipeline green = done"
- Anyone preparing for production on-call

## How to use this repo

| Path | Time | Outcome |
|------|------|---------|
| Fast track | 2 hours | `npm run demo` + [Lab 01](labs/lab-01-health-gate.md) |
| Full path | 1–2 days | Docs 01–08 + all labs |
| Team workshop | Half day | Walk through deploy-with-observability.yml |
| Português | — | [docs/pt/README.md](pt/README.md) |

## Core idea

> **CI tells you the code compiles. Observability tells you the release works.**

Every guide builds on that idea. Start with [CI/CD basics](./01-ci-cd-basics.md).

## Prerequisites

- Basic Node.js and HTTP knowledge
- Familiarity with Git and pull requests
- Docker installed (for the local stack)
- Curiosity about what happens *after* `kubectl apply` or your deploy script finishes

Let's ship with confidence.
