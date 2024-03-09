#########################################################################################################################
#                                                                                                                       #
#                  Housing Model                                                                                        #
#                  January 2024                                                                                         #
#                  John S. Schuler                                                                                      #
#                                                                                                                       #
#########################################################################################################################

# load libraries
using LightGraphs
using Distributions
using StatsBase
using DataFrames
using Random
using TikzGraphs, TikzPictures
using SparseArrays
using CSV
include("structs.jl")
include("reportingFunctions.jl")
include("functions.jl")
include("environments.jl")

# initialize environment with parameters

# we need a global variable which is a switch to pause 
pauseBool::Bool=true
seed=43884
Random.seed!(seed)
function checkPoint(message)
    global pauseBool
    if pauseBool
        println(message)
        readline()
    end
end

# the interest rate (mutable)
interestRate::Float64=.04
# distribution of agent budgets
paymentDistribution=Truncated(Levy(500,100),0,5*10^9)
# distribution of house qualities 
qualityDistribution=Truncated(Levy(0,10),0,63658)
# initial agent count
agtCnt::Int64=500
# population inflow (agents who can buy without selling)
inFlow::Int64=30
# population outflow (agents who can sell without buying)
outFlow::Int64=30
# new housing construction 
construction::Int64=30
# how many agents simply want to move within the market?
inPlace::Int64=30
# what 
# how many ticks to run the model ?
allTicks=100

env=environGen((string(seed,base=16)*sHash(paymentDistribution)*sHash(qualityDistribution)*sHash(agtCnt)*sHash(inFlow)*sHash(outFlow)*sHash(construction)*sHash(inPlace)*sHash(allTicks)),
               qualityDistribution,
               paymentDistribution,
               agtCnt,
               inFlow,
               outFlow,
               construction,
               inPlace,
               interestRate,
               allTicks,
               false)

env=initialize(env)

# now, we can actually run the model

include("modelRun.jl")

modelRun(env)