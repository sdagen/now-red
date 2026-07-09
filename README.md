# Operation IRON RELAY — Contested Logistics Mission Simulator

A mission-level simulator of blue-force resupply under red-force interdiction,
built with SimEvents, Stateflow, and System Composer (R2026a).

## Scenario

Blue sustains a forward operating base (FOB) for 30 days by dispatching truck
convoys (20 trucks / 100 tons, one every 8 h) from a logistics support area over
two routes: ROUTE NORTH (6 h transit, high threat) and ROUTE SOUTH (10 h,
lower threat). A red interdiction cell sits on each route and cycles through
DORMANT / ACTIVE / SURGE postures; each transiting convoy risks ambush with a
posture-dependent probability. Ambushes cause partial truck attrition or, with
probability `P_CATASTROPHIC_KILL`, destroy the convoy. The FOB burns
200 tons/day.

## Files

This folder is a MATLAB project (`IronRelay.prj`). Opening the project puts
`models/` and `scripts/` on the path and auto-loads the scenario parameters.

| File | Purpose |
|------|---------|
| `scripts/scenarioParams.m` | All scenario parameters (run automatically at project startup) |
| `models/LogisticsMission.slx` | Executable mission model: SimEvents convoy flow + Stateflow red cells |
| `scripts/runCampaign.m` | Monte Carlo campaign runner: `results = runCampaign(30)` |
| `models/LogisticsArchitecture.slx` | System Composer architecture: BlueForce / RedForce with typed interfaces |
| `models/LogisticsInterfaces.sldd` | Interface dictionary (SupplyConvoy, ThreatAction, ...) |
| `scripts/defineArchInterfaces.m` | Rebuilds/assigns the interface dictionary |
| `work/` | Derived artifacts (simulation cache, codegen) — gitignored |

## Quick start

```matlab
openProject('D:\dev\new-red');          % loads params via startup script
out = sim('LogisticsMission');          % single 30-day campaign
results = runCampaign(30);              % 30-run Monte Carlo + plots
```

Time base: 1 simulation time unit = 1 hour.

## Design notes

- Red cells are Stateflow charts on the SimEvents entity path: convoys arrive as
  messages, a parallel `Posture` state machine sets the current ambush
  probability, and the `Handler` state consumes/forwards each convoy.
- Randomness comes from a seeded Park–Miller LCG inside each chart
  (`RUN_SEED_NORTH` / `RUN_SEED_SOUTH`), so runs are reproducible and
  Monte-Carlo-sweepable (Stateflow `rand` cannot be reseeded from outside).
- Metrics: cumulative tons delivered/lost, convoys destroyed, FOB stockpile
  (initial + delivered − consumption).
- Blue C2 routing is adaptive: the `BlueC2` chart sits on the entity path
  (custom-output-switch pattern) and forwards each convoy north or south.
  Every `C2_ASSESS_PERIOD_HR` it updates exponentially-faded recent losses
  per route (`C2_MEMORY_FACTOR`) and picks the cheaper route, with
  `C2_SOUTH_PENALTY_TONS` expressing the longer southern transit. Routing
  history is logged as `routeSelected`. In the 30-run Monte Carlo, adaptive
  routing delivers ~8,276 tons vs ~8,194 for round-robin at equal losses.

## Extension ideas

- Convoy escorts that reduce ambush effectiveness; red cells that adapt posture
  to observed convoy schedule.
- Stress studies: raise `P_AMBUSH_*`, cut `DISPATCH_PERIOD_HR`, or lower
  `FOB_STOCK_INITIAL_TONS` until `P(FOB goes dry)` becomes the headline metric.
- Requirements Toolbox gates on throughput ≥ 85% and stock > 0 (see
  `requirements-table-gates` skill).
