# Harness Engineering Principles

The harness — the complete environment an agent operates in — determines outcomes more than the model itself.

## Debug the Environment, Not the Prompt

When something fails, ask:
- What information does the agent need that it currently cannot access?
- What feedback loop is missing that would catch this mistake earlier?
- What constraint relies on agent judgment that should be enforced mechanically?

Invest in tools and structure that prevent categories of failure, not prompts that fix individual instances.

## Repository as System of Record

If it's not in the repo, it doesn't exist for the agent. Encode intent into files.
- Specs, architectural decisions, and constraints belong in tracked files
- Progress state (what's done, what's left) belongs in files the next session can read
- Prefer structured formats (JSON, typed configs) over prose for state that agents update — rigid formats resist casual overwriting

## Clean State Handoffs

Every unit of work should end in a state the next session (or human) can build on.
- Don't leave half-implemented features — either complete a coherent unit or revert to the last clean state
- Document what was done and what remains for multi-session work

## Mechanical Enforcement Over Judgment

For architectural invariants, prefer automated checks over relying on agent discipline.
- Suggest linters, structural tests, and CI checks rather than trying harder manually
- Enforce boundaries (dependency directions, API contracts, naming) — allow freedom within them
