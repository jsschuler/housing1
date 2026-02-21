# Housing Model Context Summary

## Objective Recap
We investigated erratic sale-price behavior in the Julia housing model, applied targeted fixes, and benchmarked volatility across scales.  
We also added an overnight, process-parallel scale runner with pilot mode and automatic R plotting.

## Key Model Fixes Applied

### 1) Preference graph bug fix
- File: `modelRunFunctions.jl`
- Issue: buyer choice logic did not update `bestQual`, so preferences were effectively wrong.
- Change:
  - Initialize `bestQual = -Inf`
  - Update `bestQual` whenever a better house is found
  - Guard edge creation when `bestHaus` is `nothing`

### 2) Duplicate hotel insertion fix
- File: `conversionFunctions.jl`
- Issue: sellers from `soldHouse` were added to hotels twice.
- Change:
  - Removed extra `push!` wrapper around `hotelGen!` in `populate!(::soldHouse)`.

### 3) Remove seller-debt subtraction from buyer budget
- File: `modelRunFunctions.jl`
- Issue: bidder budget was reduced by seller loan balance, mixing seller constraints into buyer affordability.
- Change:
  - Set bidder max budget to buyer-side only (`bigMort + currBudget`).

### 4) Lighter-tailed budget distribution
- File: `main.jl`
- Issue: heavy Levy tails amplified bid outliers.
- Change:
  - From: `Truncated(Levy(500,100),0,5*10^9)`
  - To: `Truncated(LogNormal(log(2500),0.45),200,15000)`

### 5) Seller debt-floor clearing rule
- File: `modelRunFunctions.jl`
- Issue: no explicit protection against sales below outstanding debt.
- Change:
  - For `forSaleHouse` and `exitHouse`, require sale price >= seller outstanding loan balance (if loan exists).
  - If below floor, listing remains unsold that round.

### 6) Single-bidder fallback redesign
- File: `modelRunFunctions.jl`
- Issue: fallback `0.9 * highest_bidder_capacity` caused thin-market spikes.
- Change:
  - If debt floor exists:
    - target = `1.05 * debt_floor`
    - clamp to `[debt_floor, buyer_cap]`
  - If no debt floor:
    - fallback = `0.60 * buyer_cap`
- Added detailed explanatory comments directly in code.

## Experimental Findings (Iterative Benchmarks)

### Small baseline (12 agents, 5 ticks, 20 runs) before lighter tails
- Very high instability and extreme tails.
- Example metrics observed:
  - `MEDIAN_P95_MED_RATIO ~ 6.42`
  - `MAX_P95_MED_RATIO ~ 88.14`
  - `MAX_OF_MAX_PRICE ~ 6.3e6`

### After lighter-tail budget patch
- Significant volatility reduction.
- Example metrics observed:
  - `MEDIAN_P95_MED_RATIO ~ 2.77`
  - `MAX_P95_MED_RATIO ~ 4.08`
  - `MAX_OF_MAX_PRICE ~ 1.35e6`

### After debt-floor-only gate
- Slight ratio improvement, fewer clears in weak-demand runs.
- Example:
  - `MEDIAN_P95_MED_RATIO ~ 2.61`
  - sales min dropped in some runs.

### After single-bidder fallback redesign (plus debt floor)
- Additional volatility improvement and better clearing than debt-floor-only stage.
- Example:
  - `MEDIAN_P95_MED_RATIO ~ 2.07`
  - `MAX_P95_MED_RATIO ~ 3.21`
  - `MAX_OF_MAX_PRICE ~ 7.4e5`

### Scale checks
- Larger configurations were run and compared by `p95/median` volatility ratio.
- Main grid (`allTicks=15`, runs/scale=8) showed:
  - `agtCnt=12`: ratio median `2.195`, max `4.217`
  - `agtCnt=25`: ratio median `2.203`, max `2.447`
  - `agtCnt=35`: ratio median `2.376`, max `3.132`
  - `agtCnt=50`: ratio median `2.371`, max `2.476`
- Interpretation:
  - Volatility no longer explodes with scale.
  - Ratios are mostly in a tighter band around ~2.2–2.4.
  - Smallest scale remains most prone to outlier runs.

## New Overnight Runner (Parallel + Plotting)

### Added files
- `overnight_scale_parallel.jl`
- `overnight_worker_bootstrap.jl`
- `overnight_plot.R`

### Design
- Process-based parallelism:
  - `Distributed.addprocs(...)`
  - `pmap(...)`
- Worker startup flags:
  - `--compiled-modules=yes --pkgimages=yes`
- Seed-explicit initializer avoids shared seed queue race from `initMod()`.
- Summary-only logging during runs for performance.
- Outputs:
  - Run-level CSV: `overnight_runs_<timestamp>.csv`
  - Scale summary CSV: `overnight_scale_summary_<timestamp>.csv`
  - Plot folder: `overnight_plots_<timestamp>/`

### Shared-memory note
- Julia workers are separate processes (not a shared heap).
- Read-only runtime/library/pkg-image pages are typically shared by OS caching.
- Current flags are set to improve that reuse and reduce startup overhead.

## Run Instructions

### 0) Julia binary used in this environment
```bash
/Applications/Julia-1.11.app/Contents/Resources/julia/bin/julia
```

### 1) Quick pilot (recommended before overnight)
```bash
/Applications/Julia-1.11.app/Contents/Resources/julia/bin/julia /Users/l25-n05917-res/ResearchCode/housing1/overnight_scale_parallel.jl --pilot --ticks=5
```

### 2) Full overnight run (default config in script)
```bash
/Applications/Julia-1.11.app/Contents/Resources/julia/bin/julia /Users/l25-n05917-res/ResearchCode/housing1/overnight_scale_parallel.jl
```

### 3) Optional overrides
- Override runs per scale:
```bash
/Applications/Julia-1.11.app/Contents/Resources/julia/bin/julia /Users/l25-n05917-res/ResearchCode/housing1/overnight_scale_parallel.jl --runs-per-scale=24
```
- Override ticks:
```bash
/Applications/Julia-1.11.app/Contents/Resources/julia/bin/julia /Users/l25-n05917-res/ResearchCode/housing1/overnight_scale_parallel.jl --ticks=30
```

### 4) Outputs to inspect next day
- `overnight_runs_<timestamp>.csv`
- `overnight_scale_summary_<timestamp>.csv`
- `overnight_plots_<timestamp>/tail_volatility_boxplot.png`
- `overnight_plots_<timestamp>/sales_count_boxplot.png`
- `overnight_plots_<timestamp>/median_price_boxplot.png`
- `overnight_plots_<timestamp>/scale_curve_ratio_median.png`

## Current Working-State Notes
- Files modified in this session include:
  - `main.jl`
  - `modelRunFunctions.jl`
  - `conversionFunctions.jl`
  - `overnight_scale_parallel.jl` (new)
  - `overnight_worker_bootstrap.jl` (new)
  - `overnight_plot.R` (new)
- Existing in-repo changes were preserved (no resets/reverts performed).
