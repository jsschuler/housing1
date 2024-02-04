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
include("functions.jl")
include("environments.jl")
include("reportingFunctions.jl")
# initialize environment with parameters

# we need a global variable which is a switch to pause 
pauseBool::Bool=true
Random.seed!(43884)
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
agtCnt::Int64=100
# population inflow (agents who can buy without selling)
inFlow::Int64=10
# population outflow (agents who can sell without buying)
outFlow::Int64=10
# new housing construction 
construction::Int64=10
# how many agents simply want to move within the market?
inPlace::Int64=20
# what 
# how many ticks to run the model ?
allTicks=1

env=environGen(qualityDistribution,
               paymentDistribution,
               agtCnt,
               inFlow,
               outFlow,
               construction,
               inPlace,
               interestRate,
               allTicks)

env=initialize(env)

# now, we can actually run the model

include("modelRun.jl")

modelRun(env)