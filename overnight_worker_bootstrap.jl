using Graphs
using Distributions
using StatsBase
using DataFrames
using Random
using SparseArrays
using CSV
using Dates
using JLD2
using Statistics

if !isdefined(Main, :PROJECT_DIR)
    error("PROJECT_DIR must be defined in Main before including overnight_worker_bootstrap.jl")
end

include(joinpath(PROJECT_DIR, "structs.jl"))
include(joinpath(PROJECT_DIR, "reportingFunctions.jl"))
include(joinpath(PROJECT_DIR, "environments.jl"))
include(joinpath(PROJECT_DIR, "genFuncs.jl"))
include(joinpath(PROJECT_DIR, "testFuncs.jl"))
include(joinpath(PROJECT_DIR, "loanFunctions.jl"))
include(joinpath(PROJECT_DIR, "runGenFuncs.jl"))
include(joinpath(PROJECT_DIR, "conversionFunctions.jl"))
include(joinpath(PROJECT_DIR, "modelRunFunctions.jl"))
# qualityDistribution.jl calibrates qualityError from the current global
# qualityDistribution, so define a default before including it.
qualityDistribution = Truncated(Levy(0, 10), 0, 63658)
include(joinpath(PROJECT_DIR, "qualityDistribution.jl"))

# Disable filesystem logging for overnight performance.
function envLog(env::environment) end
function interestLog(env::environment) end
function houseLog(env::environment, haus::emptyHouse) end
function houseLog(env::environment, haus::popHouse) end
function agtLog(env::environment, agt::agent) end
function hotelGenLog(env::environment, hot::hotel) end
function hotelDelLog(env::environment, hot::hotel) end
function loanLog(env::environment, ln::loan) end
function loanFullLog(env::environment, ln::loan) end
function loanPreLog(env::environment, ln::loan) end
function agtMoveInLog(env::environment, dwell::dwelling, agt::agent) end
function agtLeaveLog(env::environment, origin::dwelling, agt::Union{Nothing, agent}) end
function graphLog(env::environment, tarGraph::SimpleDiGraph, label::String) end

# Worker-local sale capture (reused each run).
if !isdefined(Main, :SALE_PRICES_REF)
    const SALE_PRICES_REF = Ref{Vector{Float64}}(Float64[])
end
function saleLog(env::environment, haus::dwelling, price::Float64)
    push!(SALE_PRICES_REF[], price)
end

"""
Parallel-safe initializer (avoids cross-worker seed queue in initMod()).
"""
function initModWithSeed(run_seed::Int)
    global seed = run_seed
    Random.seed!(run_seed)
    env = initAll()
    initAgents!(env)
    initHouses!(env)
    initialSwapping!(env)
    return env
end

function run_one(spec::NamedTuple, payment_expr::Expr, quality_expr::Expr)
    global interestRate = spec.interestRate
    global paymentDistribution = eval(payment_expr)
    global qualityDistribution = eval(quality_expr)
    global agtCnt = spec.agtCnt
    global inFlow = spec.inFlow
    global outFlow = spec.outFlow
    global construction = spec.construction
    global inPlace = spec.inPlace
    global allTicks = spec.allTicks
    global pauseBool = false

    SALE_PRICES_REF[] = Float64[]
    env = initModWithSeed(spec.seed)
    modelRun!(env)

    prices = SALE_PRICES_REF[]
    sales_n = length(prices)
    med = sales_n == 0 ? NaN : median(prices)
    p95 = sales_n == 0 ? NaN : quantile(prices, 0.95)
    ratio = sales_n == 0 ? NaN : p95 / med
    mx = sales_n == 0 ? NaN : maximum(prices)

    return (
        agtCnt = spec.agtCnt,
        inFlow = spec.inFlow,
        outFlow = spec.outFlow,
        inPlace = spec.inPlace,
        construction = spec.construction,
        allTicks = spec.allTicks,
        run_id = spec.run_id,
        seed = spec.seed,
        sales_n = sales_n,
        median_price = med,
        p95_price = p95,
        p95_median_ratio = ratio,
        max_price = mx,
    )
end
