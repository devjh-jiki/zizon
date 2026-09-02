# Directions and palettes

The rules that make step 4 produce a real choice instead of three variations of one idea.

## Rule 1. Force distance between the three

The three directions must differ on **at least two** of these axes:

| Axis | Ends |
|---|---|
| Color temperature | Cool neutral / warm neutral / saturated accent-led |
| Density | Gallery whitespace / balanced / cockpit dense |
| Type classification | Geometric sans / neo-grotesque / editorial serif / mono-inflected |
| Ground | Light-first / dark-first |

State which axes each pair splits on when you present them. If you cannot name two, you
have one direction with three skins, and the user's choice means nothing.

**Do not split on the axis the brief already settled.** If the constraint is
accessibility-first clinical data, density is fixed and the split has to come from
temperature and type.

## Rule 2. Seven roles, one accent

A palette here is seven roles, not seven pretty colors. Each one carries its own contrast
target, which is what makes Rule 3 mechanical rather than a judgment call.

| Role | Job | Contrast target |
|---|---|---|
| Base | Page background | the reference surface |
| Surface | Cards, panels, raised areas | the reference surface |
| Text | Body copy | 4.5:1 on base and on surface |
| Muted text | Secondary labels, timestamps, helper copy | 4.5:1. It is still body copy |
| Divider | Decorative separation between blocks | none |
| Control edge | The only thing marking a control's boundary: an unfilled input, an outlined button | 3:1 on base and on surface, per WCAG 1.4.11 |
| Accent | The one thing that draws the eye. Actions, focus, the single emphasis | 3:1 as a filled surface, 4.5:1 wherever it is used as text |

**Two of those rows exist because five was wrong.** Earlier versions of this file had one
`Border` role and one `Text` role, and two independent verification runs hit the same
wall: a divider between cards and the edge of an email input are different roles with
different legal minimums, and secondary text kept getting quietly held to the 3:1 that
belongs to UI components. Splitting them is not extra ceremony. It is the difference
between a palette that passes and one that ships broken.

**Decide which kind each border is before you check it.** A line is a divider only if
removing it would cost nothing but tidiness. If removing it would hide where a control
begins, it is a control edge and 1.3:1 will not do.

Constraints:

- **One accent.** Add at most one semantic pair (success/danger) and only if the screen
  actually reports state.
- **Neutral base.** Saturation under 80% unless the brief explicitly asks for saturated.
- **Both modes.** Give light and dark values for every role, or say in the brief that the
  product is single-mode on purpose.

## Rule 3. Compute contrast, never estimate it

Targets: **body text 4.5:1**, **large text and UI components 3:1**, in both modes.

This is the only thing in this step a machine can settle, and it is exactly where
AI-generated palettes fail. A palette that looks good in a swatch row and fails at 3.1:1
on body copy will ship and then get rewritten.

Run it. Do not eyeball it.

```python
def _lin(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def luminance(hex_color):
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i+2], 16) for i in (0, 2, 4))
    return 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b)

def ratio(fg, bg):
    a, b = luminance(fg), luminance(bg)
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)

BASE, SURFACE, ACCENT = "#fafafa", "#ffffff", "#1d68c4"

# one row per pair you actually ship, each carrying its own role's target
checks = [
    ("text on base",          "#1a1a1a", BASE,    4.5),
    ("text on surface",       "#1a1a1a", SURFACE, 4.5),
    ("muted on base",         "#595959", BASE,    4.5),
    ("muted on surface",      "#595959", SURFACE, 4.5),
    ("control edge on base",  "#767676", BASE,    3.0),
    ("control edge on surface", "#767676", SURFACE, 3.0),
    ("accent as fill vs base", ACCENT,   BASE,    3.0),
    ("accent as text on base", ACCENT,   BASE,    4.5),
    ("label on accent fill",  "#ffffff", ACCENT,  4.5),
]
for label, fg, bg, target in checks:
    r = ratio(fg, bg)
    print(f"{label:26s} {r:5.2f}:1  needs {target}  {'PASS' if r >= target else 'FAIL'}")

# The divider role carries no target. Do not invent one for it.
# Run this again for the dark mode values before you write the brief.
```

**When a pair fails, change lightness, not hue.** Hue is what the direction chose;
lightness is what accessibility dictates. Swapping the hue to pass a contrast check
silently abandons the direction the user picked.

## Rule 4. Verify the palette by searching backward

Once the palette exists, put the accent back into Awwwards:

```
https://www.awwwards.com/websites/?tag=<aesthetic-slug>&palette=%23<HEX>
```

Read the result as a signal:

| Result | Reading |
|---|---|
| Sites that match the intended mood | The palette belongs to this aesthetic. Cite two as references |
| A set that does not move against the unfiltered tag | The filter never engaged. Check the URL form before reading anything into the result |
| A completely different mood | The palette is fighting the direction. Revisit the accent |

**The query form is not optional here.** `/websites/<slug>/?palette=%23<HEX>` drops the
parameter and hands back the unfiltered tag with the same title and the same status code,
so a path-form URL produces a confident reading of a filter that never ran.
`reference-sites.md` carries the measurement.

**Weight the mood row, not the count row.** The first page renders 31 sites whether or not
a palette is applied, so emptiness almost never fires and a count measures nothing. If you
want a mechanical check that the filter engaged, compare the result set against the
unfiltered tag: a plausible accent moves part of the list, a foreign one moves nearly all
of it. The verdict you actually act on is still whether the returned sites feel like the
direction, and that is a judgment the user makes by opening the link.

This is the one place the lookup and the palette meet, and it exists because Awwwards
turned out to have a color filter. Treat the verdict as a lead like any other fetch
result, not as proof.

## Exporting to Coolors

Join the roles in this fixed order, hex values without the `#`:

```
https://coolors.co/<base>-<surface>-<divider>-<control-edge>-<muted>-<accent>-<text>
```

An earlier version said to order them light to dark and then gave a fixed role order in
the same breath. Those two instructions disagree on every dark-first palette, and a
verification run had to pick one. The role order wins: a stable order is what makes two
briefs comparable at a glance. The user opens it and turns the dials by hand. Put the URL in
the brief so the palette stays editable after the session ends.

## Typography

Two families maximum: display and body. One is fine.

- Check Google Fonts availability and say so. If a family is paid, say it is paid.
- Do not reach for a serif because the project sounds creative. Serif when the brief is
  editorial, luxury, or heritage, or when the brand already uses one.
- A geometric sans and a neo-grotesque are not a pairing. They read as one font that
  failed to load consistently.
