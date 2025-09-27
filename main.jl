#########################################################################################################################
#                                                                                                                       #
#                  Housing Model                                                                                        #
#                  January 2024                                                                                         #
#                  John S. Schuler                                                                                      #
#                                                                                                                       #
#########################################################################################################################

# Key needed fix: agents observe the quality and price of houses sold. If the agent believes it can
# buy a house it prefers at a price it can afford, it sells its current house 
# and then enters a hotel to wait for the next round of sales.
# but this data only becomes available after the model runs 
# so for the first k ticks, agents will sell at random 
# we can turn off this feature to see what difference it makes 
using Distributed
# load libraries
@everywhere using Distributed
@everywhere using Graphs
@everywhere using Distributions
@everywhere using StatsBase
@everywhere using DataFrames
@everywhere using Random
@everywhere using SparseArrays
@everywhere using CSV
@everywhere using Dates


# initialize environment with parameters

# we need a global variable which is a switch to pause 
pauseBool::Bool=true
seed=43884
Random.seed!(seed)
function checkPoint(message)
    global pauseBool
    if pauseBool
        #println(message)
        #readline()
        true
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
# also, what is the 

include("structs.jl")
include("reportingFunctions.jl")
#include("functions.jl")
include("environments.jl")
include("genFuncs.jl")
include("testFuncs.jl")
include("loanFunctions.jl")
include("runGenFuncs.jl")
include("conversionFunctions.jl")
include("modelRunFunctions.jl")
include("qualityDistribution.jl")

env=initMod()
modelRun!(env)
