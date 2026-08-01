---
id: A-2026-08-01-032
session: none
type: info
title: "Tag Priority Resolution Rules"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:TAG_PRIORITY_RULES.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Tag Priority Resolution Rules

This document defines how Taskr resolves a task priority from tag priority definitions when the user does not enter a manual priority value.

## Rule Order

1. Manual task priority always wins.
2. If there is no manual task priority, resolve priority from selected tags.
3. If no tag has a priority definition, fall back to existing auto-priority behavior.

## Data Model

Each tag priority definition is stored as:

- `priority_min`
- `priority_max`

Interpretation:

| Tag definition | Meaning |
| --- | --- |
| `min = max` | Exact priority value |
| `min < max` | Priority range |
| `min = null` or `max = null` | No priority definition |

## Core Rule

If the user manually enters a task priority number, that number is used directly and tag priority rules are ignored.

| Manual task priority | Tag definitions | Result |
| --- | --- | --- |
| `72` | `40`, `60-80` | `72` |
| `15` | `50-70`, `90` | `15` |

## Exact Value Only

If every selected tag has an exact priority value, the result is the arithmetic average of those values.

Formula:

```text
result = average(all exact values)
```

Examples:

| Tags | Result |
| --- | --- |
| `40`, `60` | `50` |
| `20`, `50`, `80` | `50` |
| `30`, `30`, `90` | `50` |

## Range Only

### One range

If exactly one tag has a range, pick a random value inside that range.

| Tags | Result |
| --- | --- |
| `40-60` | Random value in `40-60` |

### Two ranges

If two range tags overlap, use the intersection and pick a random value from that intersection.

| Tags | Intersection | Result |
| --- | --- | --- |
| `40-70`, `50-80` | `50-70` | Random value in `50-70` |
| `20-60`, `30-50` | `30-50` | Random value in `30-50` |

If two range tags do not overlap, find the closest two boundary values and average them.

| Tags | Closest boundaries | Result |
| --- | --- | --- |
| `10-20`, `40-50` | `20` and `40` | `30` |
| `0-25`, `40-90` | `25` and `40` | `32.5` |

### Three or more ranges

If there are three or more range tags, build a synthetic range:

- low side = average of all lower bounds
- high side = average of all upper bounds

Then pick a random value from that synthetic range.

Formula:

```text
synthetic_min = average(all mins)
synthetic_max = average(all maxes)
result = random value in [synthetic_min, synthetic_max]
```

Examples:

| Tags | Synthetic range | Result |
| --- | --- | --- |
| `10-30`, `20-40`, `30-60` | `20-43.33` | Random value in `20-43.33` |
| `40-50`, `45-80`, `60-90` | `48.33-73.33` | Random value in `48.33-73.33` |

## Mixed: Exact Values + Ranges

When both exact values and ranges are present:

1. Resolve the range side first.
2. Resolve the exact side as the average of all exact values.
3. Combine them with the rules below.

### Exact average vs one resolved range

If the exact average is inside the resolved range, use the exact average directly.

| Exact average | Range | Result |
| --- | --- | --- |
| `50` | `40-60` | `50` |
| `55` | `50-70` | `55` |

If the exact average is lower than the range, average it with the lower bound.

| Exact average | Range | Result |
| --- | --- | --- |
| `20` | `40-60` | `30` |
| `35` | `50-70` | `42.5` |

If the exact average is higher than the range, average it with the upper bound.

| Exact average | Range | Result |
| --- | --- | --- |
| `90` | `40-60` | `75` |
| `88` | `50-70` | `79` |

## Mixed Resolution Flow for 3+ Tags

When there are many tags and some are exact while others are ranges:

1. Reduce all exact tags to one `exact_average`.
2. Reduce all range tags:
   - one range: keep that range
   - two ranges with overlap: keep the overlap range
   - two ranges without overlap: use closest-boundary average as a scalar
   - three or more ranges: build synthetic range from average mins and average maxes
3. Combine `exact_average` with the resolved range/scalar:
   - if resolved result is a range and `exact_average` is inside it, result = `exact_average`
   - if resolved result is a range and `exact_average` is outside it, result = average with nearest bound
   - if resolved result is already a scalar, result = average(`exact_average`, resolved scalar)

Examples:

| Tags | Range-side resolution | Exact-side resolution | Final result |
| --- | --- | --- | --- |
| `40-80`, `50-70`, `90` | overlap `50-70` | `90` | `(90 + 70) / 2 = 80` |
| `10-20`, `40-50`, `90` | scalar `30` | `90` | `(30 + 90) / 2 = 60` |
| `10-30`, `20-40`, `30-60`, `80`, `100` | synthetic `20-43.33` | `90` | `(90 + 43.33) / 2 = 66.67` |
| `40-70`, `60`, `80` | range `40-70` | exact average `70` | `70` |

## Implementation Notes

- A manual task priority value must always override tag-based resolution.
- Exact values should be treated as `min = max`.
- Range resolution may return either:
  - a scalar
  - or a range
- Final numeric values should be rounded consistently before storing/displaying.
- Random range picks should be generated only when the resolved output is still a real range.

## Pseudocode

```text
if manual_priority exists:
  return manual_priority

split tags into:
  exact_values
  ranges

if only exact_values:
  return average(exact_values)

if only ranges:
  return resolve_ranges(ranges)

exact_average = average(exact_values)
range_result = resolve_ranges(ranges)

if range_result is scalar:
  return average(exact_average, range_result)

if exact_average < range_result.min:
  return average(exact_average, range_result.min)

if exact_average > range_result.max:
  return average(exact_average, range_result.max)

return exact_average
```
