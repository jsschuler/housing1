#########################################################################################################################
#                                                                                                                       #
#                  Housing Model                                                                                        #
#                  September 2023                                                                                       #
#                  John S. Schuler                                                                                      #
#                                                                                                                       #
#########################################################################################################################

# load libraries
using Graphs
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
        push!(hotelList,hotelGen())
    end

    # now set up the network
    global transactionGraph
    transactionGraph=SimpleDiGraph(length(hotelList)+length(houseList))

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

    # since every hotel dweller bids on every on-market home, we can record each bid 
    bidList=Int64[]
    for hot in hotelList
        push!(bidList,budgetCalc(hot))
    end
    hotelBidFrame=DataFrame(dwelling=hotelList,bid=bidList)
    # sort this by descending offer
    sort!(hotelBidFrame,:bid,rev=true)

    for haus in onMarket
        haus.bidOrdering=hotelBidFrame
    end

    # now, beginning with hotels, the agents within them select their preferred houses (all on Market houses for all hotel agents)
    for hot in hotelList
        preferenceFrame=DataFrame(houses=onMarket)
        preferenceFrame.preference=hausQuality.(onMarket)
        sort!(preferenceFrame,:preference,rev=true)
        hot.preferenceOrdering=preferenceFrame
        #println("Preference Frame")
        #println(preferenceFrame)
        for haus in onMarket
            #println("Debug")
            #println(length(keys(nodeDict)))
            #println(any(keys(nodeDict).==repeat([hot],length(keys(nodeDict)))))
            #println(any(keys(nodeDict).==repeat([haus],length(keys(nodeDict)))))
            addArrow!(hot,haus)
        end
    end

    haltCond=true
    while haltCond
        # here is the algorithm:
        # for each network edge, we check:
        # whether the source node is the highest bidder and the destination node is the most preferred 
        # if so, we record the second highest bid price
        # we delete all other edges coming out of the source 
        # and we delete all other edges going in to the destination
        println("edges")
        println(dwellEdges())
        for pair in dwellEdges()
            source=pair[1]
            dest=pair[2]
            # is the destination at the top of the source's list?
            #println(source)
            #println(typeof(source))
            #println(typeof(dest))
            #println(source.preferenceOrdering)
            #println(source.preferenceOrdering[1,1])
            mostPreferred=source.preferenceOrdering[1,1]==dest
            # is the source the destination's highest bidder?
            highestBidder=dest.bidOrdering[1,1]==source
            # if both conditions hold, remove all other edges flowing into the destination and
            # all other arrows flowing out of the source
            if mostPreferred & highestBidder
                # record second highest bid
                bidDict[dest]=dest.bidOrdering[2,2]
                # remove all other edges flowing into the destination
                for inNbh in inNeighbors(dest)
                    if inNbh != source
                        removeEdge!(inNbh,dest)
                    end
                end
                # remove all other edges flowing out of the source
                for outNbh in outNeighbors(source)
                    if outNbh != dest
                        removeEdge!(source,outNbh)
                    end
                end
                # and remove the source from the bid table and the destination from the preference table of all agents
                hotelBidFrame=hotelBidFrame[hotelBidFrame.dwelling.!=source,:]
                for hot in hotelList
                    if hot != source
                        hot.preferenceOrdering=hot.preferenceOrdering[hot.preferenceOrdering.houses .!= dest,:]
                    end
                end
            
            end
        end
    end

    # find the house, agent pair where each ranks the other first
    # for that house, save the second highest bidder's bid 
    # remove the agent's other bids
    # remove other's bids for the house
    # halt when every house has no more than one arrow pointing in

    # now, for those houses with an arrow pointing in, 
        # if they are exit houses, do nothing
        # if they are old houses, these houses determine their orders of preference 
        # we go through the same process
        # halt when every house has no more than one arrow pointing in 
    
    # now, this entire process halts when every old house and hotel has no more than one arrow pointing out



end