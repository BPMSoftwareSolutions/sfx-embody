# Empty quote regression — 2026-09-20

Command Prompt preserves single quotes in `--input 'SPY'`; PowerShell removes them. The cross-shell invocation is `--input SPY` (or double quotes). Both shells were reproduced against the installed CLI. Before the change, the literal-apostrophe input produced HTTP 200 with an empty quote and `EQUITY_MARKET_PRICE_EVIDENCE_RESOLVED` with null fields.

The migration wraps both fallback selection expressions with the same declared JSON validation. Missing/null/empty mapped fields yield the existing `NATIVE_MARKET_PRICE_TESTIMONY_REJECTED` outcome and absence count. It also updates the declared installer template so subsequent provider bindings inherit the check. Native argument values are preserved. This is presence validation, not a replacement for full output-contract admission.

Proof: ten independent Node expression fixtures; rollback dry-run; same-transaction live preflight for ordinary SPY and literal-apostrophe SPY; installed `sfx capability observe` checks for both cases. Plain SPY still resolves with a numeric price; literal-apostrophe SPY returns `REQUIRED_NATIVE_FIELDS_ABSENT` without a payload. CLI exit 0 means delivery completed; the domain status communicates rejection.

The valid observed path digest remains `sha256:0724765ddbe8da85dc22ca478671087b0ff75ce3fa0332e3b06456aab5efa01d`. No guard is dropped, disabled or recreated. The selected procedure and route definitions are checked before replacement. Retained before/after definitions, fixtures and preflight receipt provide a reviewable record.
