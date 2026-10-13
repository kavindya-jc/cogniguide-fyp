# Manual Test Notes — Stage 4

## Joshua bottles problem

- Good step-by-step guidance (multiply, then subtract).
- When stuck, agent rephrased with a concrete analogy instead of repeating itself.
- Correctly confirmed final answer and added a genuine reflection question at the end.
- Hit several 503 "high demand" errors mid-conversation; fallback message worked, no crash.

## Pam/Rena age problem

- Strong scaffolding: when I guessed wrong twice, agent asked me to verify my own guess
  rather than just correcting it - teaches a checking method, not just the answer.
- Eventually guided to correct answer (5) through hypothesis testing.

## Erasers problem

- Correctly identified the red herring (Ernest's bag) and praised focusing on the right numbers.
- Hit a 429 RESOURCE_EXHAUSTED error - Gemini free tier daily quota (20 requests/day for
  gemini-3.6-flash) was exceeded partway through testing.

## Overall

- Agent behavior is solid: avoids direct answers, gives real scaffolding, recognizes
  correct/incorrect answers appropriately, encourages reflection.
- Key constraint discovered: Gemini free tier allows only 20 requests/day per model.
  This significantly limits how much multi-turn testing is feasible per day and will
  shape how Stage 5 (evaluation) and Phase 2 (adaptive agent, needs frequent calls) are run.
