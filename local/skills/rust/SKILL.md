---
name: rust
description: Rust Design Patterns and Canonical Rust Best Practices. Use when reading, reviewing, or editing .rs files and Rust crate interfaces.
disable-model-invocation: true
---

# Rust

Apply the Rust Design Patterns and Canonical Rust Best Practices chapters to the current Rust task. Read each applicable chapter in full, including its examples, rationale, and tradeoffs.

Follow session and project instructions, the authorized scope, and existing public contracts. Inspect the crate's manifest, toolchain, edition, supported Rust version, feature gates, neighboring code, and callers before changing it. Preserve validation, security, error handling, and data-loss protections.

## Canonical style and practices

Use the [chapter index](skill://rust/references/canonical/index.md) to select the guidance relevant to the files and interfaces being changed.

- [Cosmetic discipline](skill://rust/references/canonical/cosmetic.md): semantic spacing, grouping, and hexadecimal presentation.
- [Naming discipline](skill://rust/references/canonical/naming.md): names, pattern bindings, generic parameters, lifetimes, and builders.
- [Import discipline](skill://rust/references/canonical/imports.md): explicit imports, standard/dependency/local grouping, nested paths, and module qualification.
- [Pattern matching discipline](skill://rust/references/canonical/matching.md): exhaustive matching, reference handling, tuple bindings, and signature destructuring.
- [Code discipline](skill://rust/references/canonical/code.md): `Self`, construction, collection, mutation, references, shadowing, bounds, annotations, scoped resources, and expression layout.
- [Function discipline](skill://rust/references/canonical/functions.md): unit returns, generic visibility, unused parameters, and builder interfaces and ownership.
- [Ordering discipline](skill://rust/references/canonical/ordering.md): definitions, implementation placement and order, derives, declarations, and fields.
- [Structural discipline](skill://rust/references/canonical/structure.md): module roots, namespace layout, and error/result ownership.
- [Comment discipline](skill://rust/references/canonical/comments.md): the form and precision of authorized documentation.
- [Error and panic discipline](skill://rust/references/canonical/errors.md): error messages, types, conversion, propagation, and panic boundaries.
- [Unsafe discipline](skill://rust/references/canonical/unsafe.md): minimal unsafe operations and documented preconditions.
- [Preconditions](skill://rust/references/canonical/preconditions.md): required or task-authorized formatting, Clippy, feature coverage, and verification ownership.

Chapter examples link their [support definitions](skill://rust/references/canonical/examples/errors.md) where required. Treat examples as contextual code fragments and preserve their stated assumptions when applying them.

## Rust Design Patterns

Use the [complete chapter index](skill://rust/references/design/index.md) to find the specific idiom, design pattern, or anti-pattern. Read the applicable chapter's motivation, example, advantages, disadvantages, and alternatives before choosing a design.

- [Idioms](skill://rust/references/design/idioms/index.md): borrowing, construction, default values, destruction, ownership transitions, dispatch, iteration, closures, extensibility, documentation, and recovery.
- [Design patterns](skill://rust/references/design/patterns/index.md): behavioural, construction, structural, and foreign-interface patterns.
- [Anti-patterns](skill://rust/references/design/antipatterns/index.md): cloning to appease borrowing, warning policy, and dereference-based inheritance.
- [Functional programming](skill://rust/references/design/functional/index.md): programming paradigms, generic state-specific interfaces, and optics.
- [Foreign idioms](skill://rust/references/design/idioms/foreign/index.md) and [foreign patterns](skill://rust/references/design/patterns/foreign/index.md): errors, strings, object handles, and related lifetimes across foreign interfaces.
- [Refactoring](skill://rust/references/design/refactoring.md): apply the guides within the approved behavior-preserving change.
- [Additional resources](skill://rust/references/design/resources/index.md) and [design principles](skill://rust/references/design/resources/principles.md).

For a maintainability review, apply [quality](skill://quality) with the relevant source chapters. Report findings and proposed remedies; a review does not authorize implementation.

## Sources

- [Rust Design Patterns](https://github.com/rust-unofficial/patterns).
- [Canonical Rust Best Practices](https://github.com/canonical/rust-best-practices).
