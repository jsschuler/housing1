#!/usr/bin/env julia

using Distributed
using Dates
using Random
using Statistics
using DataFrames
using CSV

struct OvernightConfig
    agt_scales::Vector{Int}
    runs_per_scale::Int
    all_ticks::Int
    interest_rate::Float64
    payment_dist::Expr
    quality_dist::Expr
    pilot::Bool
end

"""
Overnight parallel scale study for the housing model.

Design goals:
1) Use process-based parallelism (`Distributed.addprocs` + `pmap`).
2) Avoid per-event CSV logging overhead; emit one summary row per run.
3) Keep worker startup deterministic and reproducible via explicit seeds.

Note on "shared memory" for loaded libraries:
- Julia workers are separate OS processes, each with its own heap.
- With local workers, read-only code/data pages (Julia runtime, shared libs,
  pkg images) are typically shared by the OS page cache.
- We request `--compiled-modules=yes --pkgimages=yes` to reduce per-worker
  compile/load cost and maximize reuse of cached package images.
"""

const PROJECT_DIR = @__DIR__

# -----------------------------
# User-tunable overnight config
# -----------------------------
const DEFAULT_AGT_SCALES = [50, 100, 200, 400]
const DEFAULT_RUNS_PER_SCALE = 32
const DEFAULT_ALL_TICKS = 25
const DEFAULT_INTEREST_RATE = 0.10
const DEFAULT_PAYMENT_DIST = :(Truncated(LogNormal(log(2500), 0.45), 200, 15000))
const DEFAULT_QUALITY_DIST = :(Truncated(Levy(0, 10), 0, 63658))

# Flow/construction policy as a function of scale.
flow_count(agt::Int) = max(2, round(Int, 0.14 * agt))
construct_count(agt::Int) = max(1, round(Int, 0.085 * agt))

function parse_config(args::Vector{String})
    pilot = "--pilot" in args
    runs_per_scale = pilot ? 1 : DEFAULT_RUNS_PER_SCALE
    all_ticks = DEFAULT_ALL_TICKS

    for a in args
        if startswith(a, "--runs-per-scale=")
            runs_per_scale = parse(Int, split(a, "=", limit=2)[2])
        elseif startswith(a, "--ticks=")
            all_ticks = parse(Int, split(a, "=", limit=2)[2])
        end
    end

    return OvernightConfig(
        DEFAULT_AGT_SCALES,
        runs_per_scale,
        all_ticks,
        DEFAULT_INTEREST_RATE,
        DEFAULT_PAYMENT_DIST,
        DEFAULT_QUALITY_DIST,
        pilot,
    )
end

function build_specs(cfg::OvernightConfig)
    specs = NamedTuple[]
    seed_base = 70_000
    for agt in cfg.agt_scales
        inflow = flow_count(agt)
        outflow = flow_count(agt)
        inplace = flow_count(agt)
        construction = construct_count(agt)
        for run_id in 1:cfg.runs_per_scale
            push!(specs, (
                agtCnt = agt,
                inFlow = inflow,
                outFlow = outflow,
                inPlace = inplace,
                construction = construction,
                allTicks = cfg.all_ticks,
                interestRate = cfg.interest_rate,
                seed = seed_base + 10_000 * agt + run_id,
                run_id = run_id,
            ))
        end
    end
    return specs
end

function main()
    cfg = parse_config(ARGS)
    workers_target = max(1, Sys.CPU_THREADS - 1)
    if nworkers() == 0
        addprocs(
            workers_target;
            exeflags = "--project=$(PROJECT_DIR) --compiled-modules=yes --pkgimages=yes",
        )
    end

    # Make project path visible on all processes before bootstrap include.
    for pid in workers()
        remotecall_wait(Core.eval, pid, Main, :(PROJECT_DIR = $PROJECT_DIR))
    end

    bootstrap_path = joinpath(PROJECT_DIR, "overnight_worker_bootstrap.jl")
    include(bootstrap_path)
    for pid in workers()
        remotecall_wait(Base.include, pid, Main, bootstrap_path)
    end

    specs = build_specs(cfg)
    println(
        "Launching $(length(specs)) runs on $(nworkers()) worker processes at $(Dates.now())" *
        " | pilot=$(cfg.pilot) runs_per_scale=$(cfg.runs_per_scale) ticks=$(cfg.all_ticks)",
    )
    results = pmap(spec -> Base.invokelatest(run_one, spec, cfg.payment_dist, cfg.quality_dist), specs)

    # Aggregate table.
    run_df = DataFrame(results)
    stamp = Dates.format(now(), "yyyymmdd_HHMMSS")
    run_out = joinpath(PROJECT_DIR, "overnight_runs_" * stamp * ".csv")
    CSV.write(run_out, run_df)

    grp = groupby(run_df, :agtCnt)
    agg_df = combine(
        grp,
        :sales_n => minimum => :sales_n_min,
        :sales_n => maximum => :sales_n_max,
        :median_price => median => :median_of_medians,
        :p95_median_ratio => median => :ratio_median,
        :p95_median_ratio => (x -> quantile(x, 0.75)) => :ratio_p75,
        :p95_median_ratio => maximum => :ratio_max,
        :max_price => median => :median_of_max_price,
        :max_price => maximum => :max_of_max_price,
    )
    agg_out = joinpath(PROJECT_DIR, "overnight_scale_summary_" * stamp * ".csv")
    CSV.write(agg_out, agg_df)

    println("Run-level results: $run_out")
    println("Scale summary: $agg_out")
    show(stdout, "text/plain", agg_df)
    println()

    # Optional post-processing plot step in R.
    plot_script = joinpath(PROJECT_DIR, "overnight_plot.R")
    if isfile(plot_script)
        plot_dir = joinpath(PROJECT_DIR, "overnight_plots_" * stamp)
        mkpath(plot_dir)
        try
            run(`Rscript $plot_script $run_out $agg_out $plot_dir`)
            println("Plots written to: $plot_dir")
        catch err
            println("R plotting step failed: $err")
        end
    else
        println("R plotting script not found at $plot_script (skipping plots).")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
