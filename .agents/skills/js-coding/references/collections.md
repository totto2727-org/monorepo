# TypeScript Collections

> Document type: concrete TypeScript implementation guidance.

Use a collection whose type preserves the domain invariant. In Effect code, prefer `HashSet` when uniqueness is the contract and its equality and hashing semantics match the values. Use the platform `Set` only when its mutable identity semantics and lifecycle are intentional.

Do not deduplicate an array with a local `includes`, `filter`, or `reduce` helper. Reject duplicate boundary input before set construction when duplicates are invalid; otherwise construct the set directly and keep it as the internal representation.

Convert a set to an array only at a consumer that requires a sequence. Make ordering explicit at that boundary instead of relying on incidental iteration order.
