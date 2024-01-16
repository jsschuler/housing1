#########################################################################################################################
#                                                                                                                       #
#                  Housing Model                                                                                        #
#                  September 2023                                                                                       #
#                  John S. Schuler                                                                                      #
#                                                                                                                       #
#########################################################################################################################

# load libraries
using LightGraphs
using MetaGraphs
using Distributions
using StatsBase
using DataFrames
# we have a few global parameters 
# the interest rate (mutable)
interestRate::Float64=.04
# distribution of agent budgets
paymentDistribution=Truncated(Levy(500,100),0,5*10^9)
# distribution of house qualities 
qualityDistribution=Truncated(Levy(0,10),0,63658)
# initial agent count
agtCnt::Int64=5000
# population inflow (agents who can buy without selling)
inFlow::Int64=200
# population outflow (agents who can sell without buying)
outFlow::Int64=100
# new housing construction 
construction::Int64=100
# how many agents simply want to move within the market?
inPlace::Int64=100
# what 
# how many ticks to run the model ?
ticks=1

include("structs3.jl")
include("functions3.jl")

# now, we include the code that finds the global cauchy parameter for noise in agent
# quality perception
include("distributionControl.jl")

houseCounter=0
hotelCounter=0


# in the initial set up, we generate a bunch of houses and a bunch of agents and 
# assign agents to houses at random. 
houseList=house[]
hotelList=hotel[]
agtList=agent[]
loanList=loan[]
for i in 1:agtCnt
    agtGen()
end

# generate place holder graph so it is global
transactionGraph=MetaDiGraph(0)
# same thing for the preferences Graph
preferenceGraph=SimpleDiGraph(0)
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

# now, the trading algorithm

# we need a global node dictionary
nodeDict=Dict{Int64,dwelling}()
agtDict=Dict{Int64,dwelling}()

# we need a dictionary to keep track of the second highest bid
bidDict=Dict{house,Int64}()

onMarket::Array{house}=house[]
for t in 1:ticks
    # randomly generate houses to go on market
    # which houses are currently off Market?
    offMarket=setdiff(houseList,onMarket)
    #println("Debug")
    #println(arraySummarize(offMarket))
    # take a (possibly empty) random sample
    exitEnteringMarket=sample(offMarket,min(outFlow,length(offMarket)),replace=false)
    offMarket=setdiff(offMarket,exitEnteringMarket)
    #println("Debug")
    #println(arraySummarize(offMarket))
    #println(arraySummarize(exitEnteringMarket))   
    for haus in exitEnteringMarket
        push!(onMarket,makeExit(haus))
    end
    inPlaceEnteringMarket=sample(offMarket,min(inPlace,length(offMarket)),replace=false)
    offMarket=setdiff(offMarket,inPlaceEnteringMarket)
    #println("Debug")
    #println(arraySummarize(offMarket))
    #println(arraySummarize(inPlaceEnteringMarket))   
    for haus in inPlaceEnteringMarket
        push!(onMarket,haus)
    end
    # now generate new houses 
    for i in 1:construction
        push!(onMarket,houseGen())
    end
    # generate hotels, which in turn generate agents 
    for i in 1:inFlow
        hotelGen()
    end

    # now set up the network
    global transactionGraph
    transactionGraph=MetaDiGraph(length(hotelList)+length(houseList))

    # now, set up dictionaries to relate the nodes to dwellings
    global nodeDict
    nodeDict=Dict{dwelling,Int64}()
    global agtDict
    agtDict=Dict{Int64,dwelling}()
    kdx=0
    for hot in hotelList
        kdx=kdx+1
        nodeDict[hot]=kdx
        agtDict[kdx]=hot
    end
    for haus in houseList
        kdx=kdx+1
        nodeDict[haus]=kdx
        agtDict[kdx]=haus
    end

    # like DD, we keep the model running until the agents affected by the last change decide not to change
    # when a new offer occurs, the following agents are affected
    # the agent receiving the offer
    # the agent who was outbid

    haltCond=false
    while !haltCond
        # Step 1, build the transaction graph 
        for haus1 in vcat(hotelList,inPlaceEnteringMarket)
            for haus2 in onMarket
                
            end
        end

    end




end