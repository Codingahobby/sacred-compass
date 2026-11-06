# Sacred Compass engineering standards

These instructions apply to this repository and future incremental development.

## Scope

Version 1 follows the original core MVP. Basic trip collections and place
correction/reporting with administrator review are proposed additions awaiting
final stakeholder approval. Implement neither without that approval and a task
covering it. Organisation self-service, organisation messaging, rewarded
advertising and advanced itinerary planning remain deferred unless separately
approved. A Figma screen's existence does not authorize its implementation.

## Architecture and changes

Keep application setup, routes and themes in lib/app, shared infrastructure in
lib/core, and feature-owned models, repositories, state and UI in lib/features.
Reuse existing repositories and SDK clients. Keep changes proportional to an
identified problem and preserve existing callers. Avoid speculative layers,
dependencies, storage packages and broad refactoring.

## Layout and accessibility

Use available constraints, SafeArea and scrollable content for forms and error
states. Treat Figma dimensions as reference geometry. Preserve approved fonts,
assets and colours while allowing text to wrap and controls to stay reachable.
Keep primary controls usable on small phones, landscape, with the keyboard open,
and at increased text scaling. Use at least 44 logical pixels for interactive
targets, and 48 where practical on Android. Test enabled and disabled controls.
Respect MediaQuery.disableAnimations and dispose animation controllers.

## Lifecycle and state

Keep transient form controllers and loading state in the owning screen and
dispose them. Preserve input and scroll offsets during ordinary navigation and
background/resume while the process remains alive. Do not add durable form drafts
or process-death restoration unless a feature needs them. Dispose subscriptions
and handle stream errors. Reconcile identity with the SDK session on auth errors.
Check mounted after asynchronous UI work and discard responses belonging to a
previous account. Prevent concurrent duplicate submissions.

## Persistence and account isolation

Use lightweight key-value storage only when a non-sensitive preference needs to
survive restart. Keep it separate from the SDK's session storage. Use Supabase
for account-synchronised and permission-controlled information, with RLS as the
security boundary. Use a structured local database only when an approved offline
or substantial draft workflow requires querying, transactions or a sync queue.

Let supabase_flutter restore, refresh and remove its own persisted session.
Do not manually persist passwords, tokens or session copies. Do not log them.
Any future private cache must be scoped by user ID and cleared on logout or
account change. Invalidate in-flight work before exposing another account.
Current public place results do not justify adding a private or offline cache.

## Assets, configuration and verification

Keep client configuration in Git-ignored config.json and safe placeholders in
config.example.json. Bundle original assets and licensed fonts locally. Do not
ship temporary Figma URLs. Do not change backend schemas or RLS during UI work.

Add focused regression tests for identified failures and meaningful user flows.
Cover loading, success, empty results, failure/retry, guest access and relevant
account transitions. Include layout and state-preservation tests when changed.
Use injected fakes in automated tests. Never create hosted test accounts silently.

Run flutter analyze and flutter test from the repository root. Report blocked
commands precisely and provide the local commands. A successful dart analyze is
supplemental evidence and does not establish that Flutter widget tests passed.
Do not disable checks or alter system permissions to conceal a failed check.
