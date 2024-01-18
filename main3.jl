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
# and give this transaction graph two possible edge properties


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
    transactionGraph=MetaDiGraph(length(hotelList)+length(onMarket))

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

    # Step 1, build the transaction graph 
    for haus1 in vcat(hotelList,inPlaceEnteringMarket)
        for haus2 in onMarket
            preferenceLink(haus1,haus2)
        end
    end

    # now, we keep the transaction graph static each model tick
    # only the budget property of edges may change

    # but we need a copy of it to pair back

    # we form two subgraphs as needed

    # the highest bidder graph consists of the agent who is the highest bidder on each property 
    # the most preferred graph consists of arrows connecting to the house that the agent likes best 


    # form transaction graph copy
    mutableGraph=transactionGraph
    haltCond=false
    counter=0
    oldSaleGraph=SimpleDiGraph()
    newSaleGraph=SimpleDiGraph()
    while !haltCond1
        haltcond2=false
        counter=counter+1
        while !haltcond2
            saleGraph=SimpleDiGraph(length(hotelList)+length(onMarket))()
            # in each sub-step
            # form the highest bidder graph for all houses
            highBidGraph=SimpleDiGraph(length(hotelList)+length(onMarket))
            # go in random order so we can assign randomly in the case of tie
            for haus in sample(onMarket,length(onMarket),false)
                hiBudget=0
                secondHiBudget=0
                hiHaus=nothing
                # find all arrows pointing to this house
                pointingIn=inNeighbors(haus)
                for dwell in pointingIn
                    budg=budgetCalc(dwell.owner)
                    if budg >= hiBudget
                        secondHiBudget=hiBudget
                        hiBudget=budg
                        hiHaus=dwell
                end
                addArrow!(highBidGraph,hiHaus,haus)
                # log the second highest bid to the transaction network
                setHiBid!(hiHaus,haus,secondHiBudget)
                # have the offered house record the second best offer
                haus.bestOffer=secondHiBudget
            end
            # form the most preferred graph
            mostPreferredGraph=SimpleDiGraph(length(hotelList)+length(onMarket))
            allPreferers=vcat(hotelList,inPlaceEnteringMarket)
            for haus1 in sample(allPreferers,length(allPreferers),false)
                hiQual=-Inf
                hiHaus=nothing
                # find all arrows pointing out
                pointingOut=outNeighbors(haus1)
                for haus2 in pointingOut
                    curQual=quality(haus2,haus1)
                    if curQual >= hiQual
                        hiHaus=haus2
                    end
                end
                addArrow!(mostPreferredGraph,hiHaus,haus1)
            end
            

            # now, form the intersection graph and join with the sale graph
            interGraph=intersect(highBidGraph,mostPreferredGraph)
            # if the link pointing to an exit house is not an offer that covers the mortgage balance
            # delete the link before it reaches the sale graph.
            for edge in collect(edges(interGraph))
                destHaus=nodeDict[dst(edge)]
                srcHaus=nodeDict[src(edge)]
                if typeof(destHause)==exitHouse
                    curLoan=outstandingLoan(destHause)
                    # now get the bid
                    hiBid=get_prop(transactionGraph, Edge(nodeDict[src(edge),dst(edge)]), :bid)
                    if hiBid < curLoan
                        removeEdge!(srcHaus,destHaus)
                    end
                end
            end
            saleGraph=join(saleGraph,interGraph)

            # now remove from the mutable graph all other links pointing to the sale house 
            # and all other links pointing out of the buying house and repeat
            # This ensures the same home owner can be the highest bidder, that of most preference, or sell twice
            for edge in collect(edges(saleGraph))
                destNode=dst(edge)
                srcNode=src(edge)
                # get all edges pointing to the destination node
                for inNbh in inneighbors(destNode)
                    # if the inNeighbor is not the same as the source node, delete
                    if inNbh!=srcNode
                        rem_edge!(mutableGraph, Edge(inNbh,destNode))
                    end
                end
                for outNbh in outneighbors(srcNode)
                    # if the outNeighbor is not the same as the destination node, delete
                    if outNbh!=destNode
                        rem_edge!(mutableGraph, Edge(srcNode,outNbh!))
                    end
                end
            end
            # halt this sub-process when the mutable transaction graph is identical to the sale graph!
            if mutableGraph==saleGraph
                haltCond2=true
            end
        end
        # Step 2:
        # alter the best offers on houses based on the bid in the transaction graph
        # but iterate through the edges of the sales graph
        # then, agents in the loop can recalculate their budget
        for edge in edges(saleGraph)
            nodeDict[dst(edge)].bestOffer=get_prop(transactionGraph,edge,:bid)
        end
        # now, repeat the above steps 
        # halt when the final sale graph is stable between ticks
        if oldSaleGraph==newSaleGraph
            haltCond1=true
        else
            oldSaleGraph=newSaleGraph
            newSaleGraph=saleGraph
        end
    end
    
    # now, after the halt, 
    # move agents in the direction of the sales graph

    # We need a function that iterates on the graph. 
    # first, it gives us all the nodes with no inNeighbors, then their outNeighbors, etc
    funcArg=nothing
    while isnothing(funcArg) || length(funcArg) > 0
        funcArg=cleanUp(funcArg,oldSaleGraph)
    end

    # handle cycles separately


    for edge in edges(oldSaleGraph)
        haus1=nodeDict[src(edge)]
        haus2=nodeDict[dst[edge]]
        agt1=haus1.owner
        agt2=haus2.owner

        haus2.owner=agt1
        # pay down loans on sold homes
        payFull(haus2)
        # generate mortgages on new homes
        bestBid=get_prop(transactionGraph,edge,:bid)
        # Now, 
        # log all sales and prices 
    end
    

    

end