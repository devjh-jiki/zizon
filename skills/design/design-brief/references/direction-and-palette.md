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

## Rule 2. Five roles, one accent

A palette here is five roles, not five pretty colors:

| Role | Job |
|---|---|
| Base | Page background |
| Surface | Cards, panels, raised areas |
| Text | Body copy on base and on surface |
| Accent | The one thing that draws the eye. Actions, focus, the single emphasis |
| Border | Separation at low contrast |

**One trap in that table.** A border that is the *only* thing marking a control boundary,
an input field with no fill of its own, is a UI component under WCAG 1.4.11 and needs
3:1, not the decorative 1.3:1 a divider gets away with. Decide which kind each border is
before you check it.

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

# check every text-on-background pair you are shipping
for fg, bg, label in [("#1a1a1a", "#fafafa", "body on base"),
                      ("#1a1a1a", "#ffffff", "body on surface"),
                      ("#2563eb", "#fafafa", "accent on base")]:
    r = ratio(fg, bg)
    print(f"{label}: {r:.2f}:1 {'PASS' if r >= 4.5 else 'FAIL'}")
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
| Nothing, or a handful | Rare pairing. Not automatically wrong, but say so in the brief |
| A completely different mood | The palette is fighting the direction. Revisit the accent |

**Weight the mood row, not the count row.** On 2026-09-02 three unrelated accents each
returned a full page against `tag=minimal`, so the filter is loose enough that emptiness
almost never fires. The verdict you can actually act on is whether the returned sites feel
like the direction, and that is a judgment the user makes by opening the link.

This is the one place the lookup and the palette meet, and it exists because Awwwards
turned out to have a color filter. Treat the verdict as a lead like any other fetch
result, not as proof.

## Exporting to Coolors

Order the five roles light to dark and join them:

```
https://coolors.co/<base>-<surface>-<border>-<accent>-<text>
```

Hex values without the `#`. The user opens it and turns the dials by hand. Put the URL in
the brief so the palette stays editable after the session ends.

## Typography

Two families maximum: display and body. One is fine.

- Check Google Fonts availability and say so. If a family is paid, say it is paid.
- Do not reach for a serif because the project sounds creative. Serif when the brief is
  editorial, luxury, or heritage, or when the brand already uses one.
- A geometric sans and a neo-grotesque are not a pairing. They read as one font that
  failed to load consistently.
