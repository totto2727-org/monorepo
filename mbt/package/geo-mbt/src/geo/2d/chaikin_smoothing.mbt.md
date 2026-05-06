# `chaikin_smoothing.mbt` — corner-smoothing subdivision

## Goal

Round off the corners of a polyline by **subdividing each edge** so that every original sharp corner becomes a curve of small line segments. Iterate `n` times to control how smooth the result becomes.

This is the **opposite** of simplification: it adds vertices and bends edges. Used for:

- Smoothing the appearance of jagged polylines (e.g. a rough digitised path).
- Approximating Bézier-like curves when you only have control points.
- Pre-processing data that will be rendered as a smooth path.

## API surface

```moonbit nocheck
pub fn chaikin_smoothing(ls : LineString, iterations : Int) -> LineString
```

- `iterations = 0`: returns the input unchanged.
- `iterations = n`: applies the subdivision `n` times. Each iteration roughly doubles the vertex count.

## Algorithm — Chaikin's corner-cutting subdivision

For each edge `(P, Q)` in the input, replace its midpoint with two new vertices placed **¼ of the way and ¾ of the way along** the edge:

```
old:    P ─────────────── Q

new:    P    Q'        Q''   Q
              ↑          ↑
            ¼ along    ¾ along

(Q' replaces what was P; Q'' replaces what was Q. The corner at the
original Q is "cut off" by the next edge's pair of vertices.)
```

Combined across all edges, every original sharp corner becomes a smooth bevel. After `n` iterations, the polyline has `O(2ⁿ)` more vertices than the input and looks visually smooth.

For a polyline with vertices `[v₀, v₁, …, vₙ]`:

```
For each i from 0 to n-1:
  Q_left  = ¾ · vᵢ + ¼ · vᵢ₊₁
  Q_right = ¼ · vᵢ + ¾ · vᵢ₊₁
  emit Q_left, Q_right
```

The first and last vertices of the output are special:

- For an **open** line string, the first and last vertices of the input are kept exactly (so the start and end don't drift). This is the port's convention.
- For a **closed** ring (start == end), the algorithm wraps around so the closure is preserved.

## Step-by-step (1 iteration of an open 3-vertex line)

```
input:  A — B — C    (A = (0,0), B = (5,5), C = (10, 0))

Edge A→B:  Q_left  = ¾A + ¼B = (1.25, 1.25)
            Q_right = ¼A + ¾B = (3.75, 3.75)

Edge B→C:  Q_left  = ¾B + ¼C = (6.25, 3.75)
            Q_right = ¼B + ¾C = (8.75, 1.25)

Output (open, keeps endpoints):
  A, Q_right(A→B), Q_left(B→C), Q_right(B→C), C
  = (0,0), (3.75, 3.75), (6.25, 3.75), (8.75, 1.25), (10, 0)
```

After 2 iterations, the polyline has 9 vertices; after 3, 17; after 4, 33. The shape converges to a **piecewise quadratic B-spline** as iterations → ∞.

## Examples

```moonbit nocheck
// 0 iterations: identity
let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 5.0), (10.0, 0.0)])
@lib2d.chaikin_smoothing(ls, 0)        // == ls

// 1 iteration: 5 vertices (originally 3, the two corner-cut steps add 2)
@lib2d.chaikin_smoothing(ls, 1).length()    // 5

// 3 iterations: ~17 vertices, visibly smooth
@lib2d.chaikin_smoothing(ls, 3).length()    // 17
```

Tests in `simplify_test.mbt`:

- `chaikin_smoothing 0 iterations is identity`
- `chaikin_smoothing 1 iteration: open line gets 2*(n-1) + 2 = 2n coords`

Plus the bench `bench: chaikin_smoothing 3 iterations`.

## Vertex count

Each iteration roughly **doubles** the vertex count:

| Iterations | Vertex count (open line of `n` original) |
| ---------- | ---------------------------------------- |
| 0          | `n`                                      |
| 1          | `2n`                                     |
| 2          | `4n`                                     |
| 3          | `8n`                                     |
| ...        | `O(2^iter · n)`                          |

The output gets exponentially heavier — Chaikin smoothing is **not** a free operation. Pick the smallest `iterations` that gives the visual result you need (typically 2–4).

## Curve properties

The Chaikin subdivision converges to a **uniform quadratic B-spline** in the limit. Practically that means:

- Smoothness improves with each iteration.
- The output "shrinks" toward the inside of corners — a 90° corner becomes a smooth bevel that doesn't reach the original corner location.
- Endpoints (for open polylines) are preserved exactly.

For a closed ring (e.g. polygon exterior), the smoothed result is also closed, but the polygon **shrinks slightly** on each iteration. If you need the polygon to stay roughly the same size, use a corner-cutting variant that preserves area (e.g. Doo–Sabin) — not currently in the port.

## Caveats

- **No tolerance parameter** — you control quality solely via `iterations`.
- **Doesn't smooth vertices already on near-straight edges** — well, it does, but the resulting bevels are imperceptibly small there. This is generally desired (smooth corners only where corners exist).
- **Self-intersecting input** stays self-intersecting; smoothing doesn't repair topology.

## Performance

`O(n · 2^iter)` time and space (the output is `O(2^iter · n)`). Fast for small `iter` (typically 2–4). Don't crank `iterations` to high values blindly.

## Related

- `densify.mbt` — adds vertices but doesn't smooth corners.
- `simplify.mbt` / `simplify_vw.mbt` — opposite operation (vertex removal).
- `remove_repeated_points.mbt` — removes only **adjacent duplicates**, not nearby ones.
