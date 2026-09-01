# Landing Method: Subtract, Research, Purpose

Reference for the `anti-slop-frontend` skill. Three process moves that sit between the Design Read and the build, plus the hierarchy and trust rules they depend on. Scope: landing and marketing pages.

The rest of this skill is mostly prohibitive ("do not reach for X"). This file is the positive counterpart: where to start, what to look at first, and what decides whether a section exists at all.

## 1. Start subtractive

Do not start from a decorated draft and negotiate it down. Start from nothing and add back what earns a reason.

- **First pass is monochrome.** Two values only: near-black and near-white. No accent, no gradient, no icon, no decorative shape, no shadow, no border radius decisions yet.
- **Settle structure at that state.** Section list, section order, hierarchy, spacing, copy length. If the page does not work in two values, color will not fix it.
- **Then add back one thing at a time.** The accent, the typeface, images, motion, in that order. Each addition is a separate decision.
- **Admission rule.** If you cannot say in one sentence what an element does for the reader, it does not go back in.

Why this order: removing from a busy page is an unbounded search (every element could plausibly stay), while adding to an empty page is a bounded one (every element must argue for itself). It also removes gradient, icon, and multi-color slop at the source instead of relying on the prohibitions in `ai-tells.md` to catch them later.

## 2. Research references before writing code

The Design Read (SKILL.md §1) reads whatever references the user supplied. When they supplied none, go and find them. Do not build from a generic memory of what a landing page looks like, which is exactly the distribution that produces slop.

Priority order:

1. **Direct competitors and same-category products, live marketing pages.** Highest value by a wide margin. Their layout already encodes what a shared audience needs to see first, and the cost of deviating from it is real. Skip category members that ship no marketing page (editor-first or app-only products), since they answer a different question.
2. **Award galleries** for composition, color use, and motion at the top of the craft range.
3. **Designer portfolio galleries** for the visual language of a specific category.

From each reference, extract exactly three things: section order, what the hero asks the visitor to do, and how many colors are actually in play. Three to five references are enough.

The goal is not imitation. It is convention where the reader expects convention, and difference where the product is actually different. Deviating from a layout that three competitors share is allowed, but you must be able to state the reason.

Do not hardcode specific product or gallery names into a build. They date fast.

## 3. Name the page's purpose, then let it delete sections

Answer one question before writing any section: **what should a visitor do on this page?** The answer is a single action, not a list.

- **The hero carries the device for that action**, not a description of it. A search product puts the input field in the hero; a store puts products in the hero; a waitlist puts the email field in the hero. A button that describes an action the page could have offered directly is a weaker version of the same idea.
- **Every section below is admitted by one test:** does this section move the reader toward that action? Building trust counts. Decoration does not. A section that fails the test is cut, not shrunk.
- **Do not encode a fixed section sequence.** Order comes from the references in §2 and from the purpose. A template sequence applied to every page is itself an AI tell.

## Hierarchy and proportion

- **Exactly one element is the largest and heaviest per viewport.** Rank by size and weight first, and by color last. Two elements competing for first place means neither wins.
- **Whitespace is a signal, not leftover space.** It is what tells the reader that the page is not asking for everything at once. Cutting it to fit more in trades the impression of quality for content nobody reads.
- **Color proportion, roughly 60 / 30 / 10:** ground, supporting surface, accent. Treat this as a proportion sanity check, not a law. It is a design convention with no empirical backing, and it sits underneath the hard rule in `ai-tells.md` (one accent, locked, whole page).

This connects to the evidence in the sources for this file: perceived visual complexity predicts a negative first impression, and pages closer to their category's conventional layout are judged better looking, both measurable within the first 50ms of exposure. Simplify and stay recognizable is the actionable form of that.

## Social proof placement

Customer quotes, company logos, and usage counts are trust devices, not decoration. Formatting rules live in `ai-tells.md` (quote length, attribution shape); placement is the part that matters here.

- **Evidence before endorsement.** Show what the product produces (real output, screenshots, a gallery) before showing who uses it. A testimonial about a product the reader has not seen working is noise.
- **Trust blocks belong below the hero**, never inside it. The hero already has its one job.
- **Never fabricate.** Invented quotes, invented logos, and invented user counts are the same failure as invented statistics. Use a clearly labeled placeholder slot and tell the user.

## Deliberately not encoded

These came from the source material and were rejected. Listed so they do not get re-added.

- **Any fixed section template** (features, then showcase, then testimonials, then CTA). Encoding a sequence produces the templated rhythm this skill exists to prevent. The transferable part is the deletion test in §3.
- **Transparent nav that turns opaque on scroll.** One valid tactic among many. As a rule it would give every page the same nav behavior, which is a new default.
- **Color-emotion physiology claims** (red raises arousal, green relaxes). Contested literature with failed and reversed replications, and the actionable residue is just contrast, already covered.
- **Facial-expression affect transfer from photos of people.** Real phenomenon, but the web-image application is extrapolation with no concrete instruction attached.
- **Advice on how to phrase prompts to an AI.** The agent reading this file is the thing being prompted. SKILL.md §1 already covers the useful translation: infer the direction, declare it, then decide specifically.
