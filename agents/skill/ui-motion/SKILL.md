---
name: ui-motion
description: Add, review and tune UI transitions and animations in web apps (CSS, Tailwind, CSS-in-JS, Framer Motion / Motion). Ships a small motion-token scale (duration, easing, distance, scale, blur), decision rules that map a UI element to the right transition, compact recipes (dropdown, modal, panel/drawer, toast, tooltip, accordion, sliding tabs, text/icon swap, skeleton reveal, stagger, error shake) and two commands, `motion review` (audit only) and `motion apply` (edit). Use when the user asks to "add a transition", "animate the modal / dropdown / toast", "make it feel smoother", "the animation feels janky / slow", "fix the timing / easing", "stagger the list", "audit my animations", "tokenize my durations", or mentions prefers-reduced-motion.
---

# UI Motion

Motion should explain what changed and where things went, then get out of the way. This skill gives the agent one shared scale of values, rules for picking the right transition for an element, and short recipes to drop in. No dependencies: everything is plain CSS plus a few lines of JS where a close needs cleanup.

## Core rules

1. **Pick by purpose, not by number.** First decide what the motion does (a dropdown opening, a toast leaving, a label swapping), then take the token whose usage matches. A `320ms` modal close is wrong because closes should be quick, not because 320 is far from 300.
2. **Closes are faster than opens.** Opening invites attention; closing should feel instant. Never delay a close or a hover-out.
3. **Animate `transform` and `opacity` only** (plus `filter: blur()` sparingly). Do not animate `width`, `height`, `top`, `left`, `margin` or `box-shadow`; for height use the `grid-template-rows: 0fr → 1fr` trick.
4. **No `transition: all`.** List the properties.
5. **Small things move less.** Travel distance and pre-scale grow with the size of the surface: a label moves 4px, a modal scales from 0.96, a drawer slides its full width.
6. **Every recipe ships a reduced-motion guard.** Keep it; under `prefers-reduced-motion: reduce`, replace movement with a plain fade or no transition.
7. **One easing by default.** `--ease-out-smooth` covers almost all surface motion. Bounce/overshoot only on small celebratory entrances, never on a close.
8. **If it feels late, shorten the duration** instead of adding a delay. Delays are for stagger, hover intent (tooltips) and deliberate sequencing.

## Tokens

Drop this block into the global stylesheet once. Recipes below reference these names; if the project has no tokens, inline the literal values.

```css
:root {
  /* durations */
  --dur-stagger: 40ms;   /* per-item offset in a list */
  --dur-instant: 100ms;  /* hover color, press feedback, tooltip close */
  --dur-quick: 150ms;    /* dropdown/modal close, text swap, tooltip open */
  --dur-base: 250ms;     /* dropdown/modal open, tabs, icon swap, accordion, page slide */
  --dur-calm: 350ms;     /* drawer/panel close, toast close */
  --dur-slow: 450ms;     /* drawer/panel open, skeleton → content, toast open */
  --dur-emphasis: 600ms; /* one-off celebration: success check, onboarding reveal */

  /* easings */
  --ease-out-smooth: cubic-bezier(0.22, 1, 0.36, 1); /* default for surfaces */
  --ease-in-out: cubic-bezier(0.65, 0, 0.35, 1);     /* in-place swaps */
  --ease-linear: linear;                             /* spinners, shimmer, progress */
  --ease-pop: cubic-bezier(0.34, 1.5, 0.64, 1);      /* small entrances only */

  /* distances */
  --move-xs: 4px;   /* text swap */
  --move-sm: 8px;   /* dropdown offset, page slide, toast rise, error shake */
  --move-md: 16px;  /* staggered text / list reveal */

  /* pre-scales (always settle to 1) */
  --scale-modal: 0.96;
  --scale-popover: 0.97;
  --scale-hint: 0.98;

  /* pre-blur (always settles to 0) */
  --blur-sm: 2px;   /* text/icon swap, skeleton reveal */
  --blur-md: 4px;   /* page slide, text reveal */
}

@media (prefers-reduced-motion: reduce) {
  :root {
    --move-xs: 0px; --move-sm: 0px; --move-md: 0px;
    --scale-modal: 1; --scale-popover: 1; --scale-hint: 1;
    --blur-sm: 0px; --blur-md: 0px;
  }
}
```

Sanity limits: a translate above ~40px on anything but a drawer reads as sluggish; a pre-scale below ~0.9 reads as a zoom; total stagger (offset × items) should stay under ~300ms, so cap the staggered items for long lists.

## Decision rules

Match the visible element first, then the verb. If two fit, take the lighter one.

| Element / situation | Transition | Open | Close |
| --- | --- | --- | --- |
| Menu or popover anchored to a trigger | Dropdown | `--dur-base`, scale `--scale-popover` + `--move-sm`, origin at trigger | `--dur-quick`, fade only |
| Centered dialog over a backdrop | Modal | `--dur-base`, scale `--scale-modal` | `--dur-quick` |
| Surface sliding in from an edge | Drawer / panel | `--dur-slow`, translate 100% | `--dur-calm` |
| Transient message | Toast | `--dur-slow`, rise `--move-sm` | `--dur-calm`, fade |
| Hover/focus hint | Tooltip | 300ms intent delay, `--dur-quick`, `--scale-hint` | `--dur-instant`, no delay |
| Collapsible section | Accordion | `--dur-base`, grid rows `0fr → 1fr` | same (symmetric) |
| Moving highlight across options | Sliding tabs | `--dur-base`, translate the indicator | same (symmetric) |
| Label or value changes in place | Text swap | `--dur-quick`, `--move-xs` + `--blur-sm` | same |
| Two icons in one slot | Icon swap | `--dur-base`, scale 0.8 + `--blur-sm` | same |
| Placeholder → real content | Skeleton reveal | `--dur-slow` cross-fade + `--blur-sm` | n/a |
| List or stacked text entering | Stagger reveal | `--dur-slow`, `--move-md`, `--dur-stagger` per item | fade, no stagger |
| Invalid input | Error shake | ~350ms, ±`--move-sm` decaying | n/a |
| List ↔ detail, step 1 ↔ 2 | Page slide | `--dur-base`, `--move-sm` + `--blur-md` | same (symmetric) |
| Button press | Press | `--dur-instant`, scale 0.97 | `--dur-quick` |

No clear match: ask the user rather than guess.

## Recipes

All recipes use an `m-` class prefix so they never collide with project classes. Open/close surfaces use the same state contract: add `.is-open` to open; to close, swap it for `.is-closing` and remove `.is-closing` after the close duration (helper at the end).

### Dropdown

```css
.m-dropdown {
  transform-origin: var(--origin, top left);
  opacity: 0;
  transform: translateY(calc(var(--move-sm) * -1)) scale(var(--scale-popover));
  pointer-events: none;
  transition: opacity var(--dur-base) var(--ease-out-smooth),
              transform var(--dur-base) var(--ease-out-smooth);
}
.m-dropdown.is-open { opacity: 1; transform: none; pointer-events: auto; }
.m-dropdown.is-closing {
  opacity: 0;
  transition: opacity var(--dur-quick) var(--ease-out-smooth);
}
```

Set `--origin` to the corner nearest the trigger (`top right` for a right-aligned menu).

### Modal

```css
.m-modal, .m-backdrop { opacity: 0; pointer-events: none; }
.m-modal { transform: scale(var(--scale-modal)); }
.m-modal, .m-backdrop {
  transition: opacity var(--dur-base) var(--ease-out-smooth),
              transform var(--dur-base) var(--ease-out-smooth);
}
.m-modal.is-open, .m-backdrop.is-open { opacity: 1; transform: none; pointer-events: auto; }
.m-modal.is-closing, .m-backdrop.is-closing {
  opacity: 0;
  transform: scale(var(--scale-modal));
  transition-duration: var(--dur-quick);
}
.m-backdrop.is-closing { transform: none; }
```

### Drawer / panel

```css
.m-drawer {
  transform: translateX(100%);
  transition: transform var(--dur-slow) var(--ease-out-smooth);
}
.m-drawer.is-open { transform: none; }
.m-drawer.is-closing { transform: translateX(100%); transition-duration: var(--dur-calm); }
@media (prefers-reduced-motion: reduce) {
  .m-drawer, .m-drawer.is-closing { transform: none; opacity: 0; transition: opacity var(--dur-quick) linear; }
  .m-drawer.is-open { opacity: 1; }
}
```

The drawer moves its full width, so the token reset does not cover it; the explicit guard swaps the slide for a fade.

### Toast

```css
.m-toast {
  opacity: 0;
  transform: translateY(var(--move-sm));
  filter: blur(var(--blur-sm));
  transition: opacity var(--dur-slow) var(--ease-out-smooth),
              transform var(--dur-slow) var(--ease-out-smooth),
              filter var(--dur-slow) var(--ease-out-smooth);
}
.m-toast.is-open { opacity: 1; transform: none; filter: none; }
.m-toast.is-closing { opacity: 0; transform: none; filter: none; transition: opacity var(--dur-calm) var(--ease-out-smooth); }
```

### Tooltip

```css
.m-tooltip {
  opacity: 0;
  transform: scale(var(--scale-hint));
  transition: opacity var(--dur-instant) ease-out, transform var(--dur-instant) ease-out;
}
.m-trigger:hover .m-tooltip,
.m-trigger:focus-visible .m-tooltip {
  opacity: 1;
  transform: none;
  transition-duration: var(--dur-quick);
  transition-delay: 300ms; /* hover intent: a passing cursor does not trigger it */
}
```

Once one tooltip is showing, moving to a neighbour should show the next one without the delay; handle that in JS by toggling a `.no-delay` class on the group for ~500ms after a tooltip closes.

### Accordion

```css
.m-accordion-body {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows var(--dur-base) var(--ease-out-smooth);
}
.m-accordion-body > * { overflow: hidden; }
.m-accordion.is-open .m-accordion-body { grid-template-rows: 1fr; }
.m-accordion-chevron { transition: transform var(--dur-base) var(--ease-out-smooth); }
.m-accordion.is-open .m-accordion-chevron { transform: rotate(180deg); }
```

### Sliding tabs

```css
.m-tabs { position: relative; }
.m-tabs-indicator {
  position: absolute; inset-block: 0; left: 0;
  width: var(--w, 0px);
  transform: translateX(var(--x, 0px));
  transition: transform var(--dur-base) var(--ease-out-smooth),
              width var(--dur-base) var(--ease-out-smooth);
}
```

```js
function moveIndicator(tabs, active) {
  const ind = tabs.querySelector(".m-tabs-indicator");
  ind.style.setProperty("--x", `${active.offsetLeft}px`);
  ind.style.setProperty("--w", `${active.offsetWidth}px`);
}
```

Animating `width` is acceptable here: one small element, and it avoids a scale distortion on the pill's border radius.

### Text / icon swap

Keep both states in the same grid cell so the layout does not jump.

```css
.m-swap { display: inline-grid; }
.m-swap > * {
  grid-area: 1 / 1;
  transition: opacity var(--dur-quick) var(--ease-in-out),
              transform var(--dur-quick) var(--ease-in-out),
              filter var(--dur-quick) var(--ease-in-out);
}
.m-swap > :not(.is-active) {
  opacity: 0;
  transform: translateY(var(--move-xs));
  filter: blur(var(--blur-sm));
}
```

For icons, replace the translate with `scale(0.8)` and use `--dur-base`.

### Skeleton reveal

```css
.m-skeleton { animation: m-pulse 1.4s var(--ease-in-out) infinite; }
@keyframes m-pulse { 50% { opacity: 0.5; } }
.m-loaded { animation: m-reveal var(--dur-slow) var(--ease-out-smooth) both; }
@keyframes m-reveal { from { opacity: 0; filter: blur(var(--blur-sm)); } }
@media (prefers-reduced-motion: reduce) { .m-skeleton { animation: none; } }
```

### Stagger reveal

```css
.m-stagger > * {
  animation: m-rise var(--dur-slow) var(--ease-out-smooth) both;
  animation-delay: calc(min(var(--i, 0), 6) * var(--dur-stagger));
}
@keyframes m-rise { from { opacity: 0; transform: translateY(var(--move-md)); } }
```

Set `style="--i: 0"`, `1`, `2`, … on each child. The `min(…, 6)` cap keeps long lists from trailing.

### Error shake

```css
.m-shake { animation: m-shake 350ms var(--ease-in-out); }
@keyframes m-shake {
  20% { transform: translateX(calc(var(--move-sm) * -1)); }
  40% { transform: translateX(var(--move-sm)); }
  60% { transform: translateX(calc(var(--move-sm) * -0.5)); }
  80% { transform: translateX(calc(var(--move-sm) * 0.5)); }
}
```

Re-trigger by removing the class, forcing a reflow (`el.offsetWidth`), and adding it back. Pair it with a visible error message; the shake alone is not accessible feedback.

### Close helper

```js
function closeWithTransition(el, ms) {
  el.classList.remove("is-open");
  el.classList.add("is-closing");
  const done = () => el.classList.remove("is-closing");
  el.addEventListener("transitionend", done, { once: true });
  setTimeout(done, ms + 50); // fallback when no transition runs (reduced motion, display:none)
}
```

## Framework notes

- **Tailwind:** put the tokens in `theme.extend` (`transitionDuration`, `transitionTimingFunction`) and use `duration-base ease-out-smooth`; avoid arbitrary `duration-[317ms]`.
- **Framer Motion / Motion:** use `transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}`, a shorter `exit` transition than `animate`, and `useReducedMotion()` to drop `y`/`scale`.
- **React unmounts:** an element removed from the DOM cannot animate out. Keep it mounted until the close finishes (the helper above, `AnimatePresence`, or a `closing` state).

## Commands

Both commands start with `motion` so they never collide with other skills.

### motion review — audit, no edits

Triggers: `motion review`, "audit my animations", "review the transitions", "where is the timing off", "find hardcoded durations".

1. Scan stylesheets, CSS modules, `<style>` blocks, inline styles, CSS-in-JS, Tailwind classes/config and Motion props for durations, delays, easings, `translate`/`scale`/`blur` values, `@keyframes` and `transition` declarations.
2. For each, infer the purpose from the selector/component name and compare against the token tables and decision rules.
3. Also flag: `transition: all`; animating layout properties; closes slower than or equal to opens (except the symmetric ones: accordion, tabs, swaps, page slide); delayed closes or hover-outs; bounce on a close; total stagger above ~300ms; missing `prefers-reduced-motion` handling; elements that unmount without an exit.
4. Output a numbered list grouped by file, only for values that should change, e.g.
   `src/Menu.css:42` — dropdown close `300ms` → `var(--dur-quick)` (150ms): close must be quicker than the 250ms open.
   Values whose purpose matches no token: list as "no matching usage, left as is".
5. Do not edit. End with: "Run `motion apply` to apply these, or name the lines to apply."

### motion apply — add or fix motion

Triggers: `motion apply`, "add a transition here", "animate this", "fix the animation", "apply the motion tokens", "polish the motion".

1. If the user points at an element with no motion, pick one transition from the decision rules and propose it in one line ("This opens from a trigger and is anchored, so a dropdown: 250ms open / 150ms close. Apply?").
2. If fixing existing motion and `motion review` has not run this session, run its scan first, scoped to what the user named.
3. Show how many values change and in which files; wait for confirmation.
4. Apply: add the `:root` tokens once if missing (or inline literals if the project clearly does not want globals), paste the recipe, wire the state classes/JS, keep the reduced-motion guard. Keep the file's existing unit style. Touch only motion values; no reformatting.
5. End with one line listing the files touched.
