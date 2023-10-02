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
hotelList=hotel[]
dwellingList=dwelling[]
agtList=agent[]
loanList=loan[]
for i in 1:agtCnt
    agtGen()
end

# generate place holder graph so it is global
transactionGraph=SimpleDiGraph(0)

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
    newBuyerList=agent[]
    # generate incoming agents 
    for j in 1:inFlow
        currAgt=agtGen()
        push!(buyerList,currAgt)
        push!(newBuyerList,currAgt)
    end
    # generate a graph 
    global transactionGraph
    transactionGraph=SimpleDiGraph(length(dwellingList))

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
    # agents without a home like all homes
    for hotel in hotelList
        for haus in forSale
            add_edge!(transactionGraph,dwellingIdx(hotel),dwellingIdx(haus))
        end
    end
    # other agents who are not exiting, decide which houses they prefer to their current house
    for haus1 in collect(setdiff(forSale,exitList))
        for haus2 in forSale
            if haus1!=haus2
                if haus1.quality <= qualityAssessment(haus2)
                    add_edge!(transactionGraph,dwellingIdx(haus1,dwellingIdx(haus2)))
                end
            end
        end
    end

    # now, we clear the market in the following way:
    # we start with the agents who do not have houses 
    # each agent sends to each other agent a price and a rank ordering
    # if the transaction is both the buyer's first choice and the sellers, 
    # the transaction clears and the two homes are removed 

    # then we repeat the process until every arrow from an agent in a hotel
    # points to one home

    # then, the agents with bids on their homes make bids in turn and the process continues 
    



end