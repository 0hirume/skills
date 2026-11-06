---
name: luau
description: Luau mutability, naming, and error message conventions. Use when reading, reviewing, or editing Luau code.
disable-model-invocation: true
---

# Luau

## Mutability

- Use `const` by default for bindings, including imports and local functions.
- Use `local` only when reassignment or deferred initialization is required.
- Use `read` by default for table type properties and indexers.
- Leave properties or indexers writable only when consumers need to mutate them.
- `const` prevents rebinding; it does not freeze the value. `read` restricts writes through the type; it does not provide deep immutability.

## Naming

- Use `snake_case` by default for project-controlled names.
- `PascalCase` is allowed. Never use `camelCase`.
- Preserve names required by external APIs, frameworks, or tooling.

## Error messages

- Use sentence case without a trailing period.
- State what failed or what was expected; avoid vague messages.
- Wrap identifiers in backticks and preserve their exact spelling.
- Include relevant context and expected versus actual values when useful and safe.
- Never include secrets or sensitive user data.
