# devtree-harness

A personal dev productivity harness for my many personal and work projects.
This repo is the harness meta-layer: it holds the tooling, decisions, and eventual NixOS configs.

## The devtree

A devtree is a root directory with arbitrary structure.
It gathers multiple projects together, along with task tracking for those projects.
Task items can reference any item in the devtree, across project boundaries.

Perso and work each get their own devtree, so the two contexts never mix.

## Human-first constraint

This harness serves a human first, not only AI agents.
Every capability must be usable manually: plain commands, short invocations, no overwhelming tooling surface.

Agent support is a layer on top, never the reason the tooling exists.

## Scope

This repo aims to contain:

- Harness decisions and their rationale
- Custom tooling
- Nix package definitions for the harness itself
- NixOS modules and configs for optional tooling around the harness

## Status

Early scoping: the harness is being designed, and decisions are not final yet.
