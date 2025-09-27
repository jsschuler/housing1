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
@everywhere interestRate::Float64=.04
# distribution of agent budgets
@everywhere paymentDistribution=Truncated(Levy(500,100),0,5*10^9)
# distribution of house qualities 
@everywhere qualityDistribution=Truncated(Levy(0,10),0,63658)
# initial agent count
@everywhere agtCnt::Int64=500
# population inflow (agents who can buy without selling)
@everywhere inFlow::Int64=30
# population outflow (agents who can sell without buying)
@everywhere outFlow::Int64=30
# new housing construction 
@everywhere construction::Int64=30
# how many agents simply want to move within the market?
@everywhere inPlace::Int64=30
# what 
# how many ticks to run the model ?
@everywhere allTicks=100
cores=16


for c in 2:cores
    @spawnat c myCore(c)
end
sleep(5)

@everywhere include("structs.jl")
@everywhere include("reportingFunctions.jl")
@everywhere include("environments.jl")
@everywhere include("genFuncs.jl")
@everywhere include("testFuncs.jl")
@everywhere include("loanFunctions.jl")
@everywhere include("runGenFuncs.jl")
@everywhere include("conversionFunctions.jl")
@everywhere include("modelRunFunctions.jl")
@everywhere include("qualityDistribution.jl")

#env=initMod()
#modelRun!(env)
coreDict=Dict()
resultDict=Dict()
rowDict=Dict()
for j in 2:cores
    coreDict[j]=nothing
end
r=1
while r < 15
    for c in keys(coreDict)
        #println(sum(jointFrame.completed))
        #println("Core")
        #println(c)
        #println(coreDict[c])
        #println(isReady(coreDict[c]))
        #println(isnothing(coreDict[c]))
        #readline()
        if isnothing(coreDict[c])
            # if the core dictionary is nothing, we send it the parameters
            #println("Sending Parameters")
            #println("core")
            #println(c)
            #println(coreDict[c])
            # read parameters from the first row
            # step 1: get the index of the first non-started row
            
            coreDict[c]=@spawnat c modelRun!(initMod(currSeed))
            #println(coreDißct[c])
            #println(resultDict==:complete)
        elseif isready(coreDict[c])
            #println("Ready")
            #println(coreDict[c])
            coreDict[c]=fetch(coreDict[c])
            global r
            r=r+1
            #println(coreDict[c])
            #println(sum(jointFrame.completed) < size(jointFrame,1))
            #println(sum(jointFrame.completed))
        end
    end    
end