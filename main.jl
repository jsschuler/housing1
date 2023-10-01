#########################################################################################################################
#                                                                                                                       #
#                  Housing Model                                                                                        #
#                  September 2023                                                                                       #
#                  John S. Schuler                                                                                      #
#                                                                                                                       #
#########################################################################################################################

# load libraries
using LightGraphs
using Distributions
using StatsBase
# we have a few global parameters 
# the interest rate (mutable)
interestRate::Float64=.04
# distribution of agent budgets
paymentDistribution::Truncated{Levy{Float64}, Continuous, Float64, Float64, Float64}=Truncated(Levy(500,100),0,5*10^9)
# distribution of house qualities 
qualityDistribution::Truncated{Levy{Float64}, Continuous, Float64, Float64, Float64}=Truncated(Levy(0,10),0,63658)
# initial agent count
agtCnt::Int64=5000
# population inflow (agents who can buy without selling)
inFlow::Int64=100
# population outflow (agents who can sell without buying)
outFlow::Int64=100
# new housing construction 
construction::Int64=100
# how many agents simply want to move within the market?
inPlace::Int64=100
# what 
# how many ticks to run the model ?
ticks=100

include("objects.jl")
include("functions.jl")

# now, we include the code that finds the global cauchy parameter for noise in agent
# quality perception
include("distributionControl.jl")

# in the initial set up, we generate a bunch of houses and a bunch of agents and 
# assign agents to houses at random. 
houseList=house[]
agtList=agent[]
loanList=loan[]
for i in 1:agtCnt
    agtGen()
end

for i in 1:agtCnt
    houseGen()
end

houseShuffle()
# then agents can outbid other agents for houses they like better. 
# this process continues until it stabilizes 
initialSwapping()
# now generate the loans for each agent
for house in houseList
    loanGen(house.owner.budget,house)
end


# then, we randomly age the agents a Uniform number of years so they can pay down their loan balances 
payOffs=rand(DiscreteUniform(12*50),length(loanList))
for i in eachindex(payOffs)
    currLoan=loanList[i]
    for j in 1:payOffs[i]
        payLoan(currLoan)
    end 
end

# are any loans paid off?
loanBool=Bool[]
loanBalance=Int64[]
for ln in loanList
    push!(loanBool,ln.paidInFull)
    push!(loanBalance,ln.outstandingBalance)
end

any(loanBool)

for t in 1:ticks
    forSale=house[]
    buyerList=agent[]
    sellerList=agent[]
    # generate incoming agents 
    for j in 1:inFlow
        push!(buyerList,agtGen())
    end
    # generate a graph 
    transactionGraph=SimpleDiGraph(length(agtList))

    # select randomly agents exiting 
    # this is equivalent to selecting houses
    exitList=sample(houseList,outFlow,replace=false)
    for haus in exitList
        push!(forSale,haus)
        push!(sellerList,haus.owner)
    end
    # now, select the agents who want to move in place 
    stayingHouses=collect(setdiff(Set(houseList),Set(exitList)))
    inPlace=sample(stayingHouses,inPlace,replace=false)
    for haus in inPlace
        push!(forSale,haus)
        push!(buyerList,haus.owner)
        push!(sellerList,haus.owner)
    end
    # now generate new construction and put these up for sale
    for j in 1:construction
        push!(forSale,houseGen())
    end

    # now, all agents who wish to buy decide which homes they like at least as much as their current home
    # agents without a home like all homes as much as their current home
    buyerDict=Dict{agent,Array{house}}[]
    for buyer in buyerList
        preferred=qualityAssessment.(forSale) .> hausQuality(buyer)
        for k in eachindex(preferred)
            if preferred[k] 
                add_edge!(transactionGraph,buyer,forSale[k].owner)
            end
        end
    end

    
end