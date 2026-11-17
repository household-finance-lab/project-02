# The Five-Point Difference

Why adult-child coresidence mattered for the average but barely helped predict the individual

*Household Finance Lab · Lena Gan & Sara Kay · September 2026*

---

At 50, you might expect to be past the financially fragile years.

But what if your adult child still lives at home?

We found that it tells us something.

Then Sara asked a different question, and we had to work out how both answers could be right.

## The question we couldn't ask

The question I wanted was the obvious one. Does having an adult child at home cost parents money?

We couldn't ask it.

The survey tells us whether an adult child lives in the household. It doesn't tell us whether the people in the other group have adult children at all. "No adult child at home" can mean children who moved out, no children, or children who are still minors.

So we narrowed the question to what the data can carry.

Among adults 50 and older, are those living with an adult child less able to cover a $2,000 emergency from savings than otherwise similar adults without one?

A smaller question. The one we could answer honestly.

## What we did

We used the Federal Reserve's 2025 SHED: 6,962 adults age 50 and older, 1,738 of them living with an adult child.

The outcome was simple: could they cover a $2,000 emergency from savings?

We compared the two groups. Then we adjusted for characteristics we had fixed in advance: age, gender, race, marital status, education, employment, housing, and income.

## What happened

The raw difference was large.

Without an adult child at home, 64.7% could cover the expense. With one, 51.6% could.

A gap of 13.1 percentage points.

The two groups differ in other ways, so we adjusted.

The gap got smaller. It didn't disappear.

After adjustment, adults living with an adult child were about **5 percentage points** less likely to be able to cover it.

Then we tried changing things. We dropped 161 records where two household measures disagreed, lowered the age cutoff to 45, then included all adults. The estimate barely moved.

The income measure was the exception. Swapping in the survey's other income measure moved the gap from 5.1 to 7.8 points. The two measures differ in concept, collection, and detail, so we can't say which one moved it. The result held either way. Its size depended on how we measured income.

So we had our result.

Then Sara asked a different question.

## Association isn't prediction

Mine was whether living with an adult child goes with lower emergency savings capacity.

Hers was this: if we already know someone's age, income, education, employment, and housing, does knowing an adult child lives with them help predict whether *that person* can cover the emergency?

They sound like the same question. They aren't.

Sara built a model without coresidence and tested it on people it hadn't seen. Then she added coresidence and tested again, five times over.

AUC measures how well a model separates people who can cover the expense from people who can't. A score of .50 is no better than chance.

| What the model knows | Weighted AUC |
|---|---|
| Everything except adult-child coresidence | .8414 |
| Plus adult-child coresidence | .8425 |

An improvement of about .001. A second, more flexible model told the same story.

The model already knew a lot, and coresidence overlaps with much of it. Households with an adult child at home differ in employment and housing, so part of what "adult child lives here" carries was already in there.

That doesn't erase the group difference. Association asks whether groups differ after adjustment. Prediction asks whether one more fact helps identify the individual.

The answer to the first was yes.

The answer to the second was: barely.

Both are true.

## What we don't know

We don't know why.

Another adult may draw on shared resources. Parents with fewer resources may be more likely to have a child living with them. Or the child may be contributing money rather than costing it.

The survey sees who lives together. It doesn't see the money moving between them. That's why we call this adult-child coresidence, not "supporting an adult child."

And because the data capture one moment, none of this shows that a child moving home *causes* a parent's savings to fall.

## So what?

It's tempting to turn a living arrangement into a financial story.

Adult child at home. Lower savings. So the child must be draining the parents.

Our data don't support that.

What they support is narrower. Living with an adult child goes with lower emergency savings capacity, even after accounting for many measured differences. And it tells us very little about which particular person can handle a $2,000 emergency.

A difference can be clear in the group and barely useful for predicting the person.

---

**Where this goes next.** The missing piece is the money inside the household. Who pays the rent? Who buys groceries? Is the adult child receiving support, contributing, or both? The SHED doesn't record those transfers.

**We didn't get here first.** Researchers have long studied adult-child coresidence and parents' finances, and the distinction at the center of our result has its own history: Galit Shmueli on explaining versus predicting, and Nancy Cook on why an informative variable can barely move AUC. Our contribution is narrower: asking both questions about coresidence and emergency savings among adults 50 and older.

**Want the machinery?** The analysis plan, data construction, Stata models, sensitivity checks, Python cross-validation, and every analytical decision are in the GitHub repository, including the question we had to give up.

---

*Observational analysis of 2025 SHED data with a documented analysis plan. Not peer reviewed. Primary sample: 6,962 adults age 50 and older. Adjusted association: −5.11 percentage points (95% CI −7.49 to −2.73). Prediction: repeated five-fold cross-validation, five repeats; weighted AUC .8414 without coresidence and .8425 with it. Cross-sectional data cannot establish causality or identify transfers within households.*
