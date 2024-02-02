
# a function that randomly selects homes for agents who want to exit

function exitHomesGen(env::environment)
    canExit::Array{oldHouse}=oldHouse[]
    for haus in env.allHouses
        if typeof(haus)==oldHouse
            push!(canExit,haus)
        end
    end
    # how many can exit?
    maxExit=min(env.outFlow,length(canExit))
    exitHomes=sample(canExit,maxExit,replace=false)
    retHomes=exitHouse[]
    for exit in exitHomes
        push!(retHomes,exitList(env,exit))
    end
    return retHomes
end
# a function that randomly selects agents who want to move in place
function oldHomesGen(env::environment)
    canMove::Array{oldHouse}=oldHouse[]
    for haus in env.allHouses
        if typeof(haus)==oldHouse
            push!(canMove,haus)
        end
    end
    maxMove=min(env.inPlace,length(canMove))
    
    oldHomes=sample(canMove,maxMove,replace=false)
    return oldHomes
end
# function to build new homes
function newConstruction(env::environment)
    newList::Array{newHouse}=newHouse[]
    for i in env.construction
        push!(newList,houseGen(env))
    end
    return newList
end
# and the function whereby new agents enter the market

function marketEntry(env::environment)
    hotelList::Array{hotel}=hotel[]
    for i in env.inFlow
        push!(hotelList,hotelGen(env))
    end
    return hotelList
end

# now we need to load the code that generates the preferende error term 
include("qualityDistribution.jl")


function preferenceLink(env::environment,dwelling1::dwelling,dwelling2::dwelling,error::Distribution)
    qual2=dwelling2.quality+rand(qualityError,1)[1]
    qual1=dwelling1.quality+rand(qualityError,1)[1]

     if qual2 > qual2
        add_edge!(env.transactionGraph,env.nodeDict[dwelling1],env.nodeDict[dwelling2])
        # now, add the  utility each agent gets from owning the house as an edge property
        #set_prop!(env.transactionGraph,,:qual,qual2)
        env.qualDict[Edge(nodeDict[dwelling1],nodeDict[dwelling2])]=qual2
    end
end


# now, we need the function that generates the transaction graph
function transactionGraphGen(env::environment,
                             hotels::Array{hotel},
                             newHouses::Array{newHouse},
                             oldHouses::Array{oldHouse},
                             exitHouses::Array{exitHouse})
                            

    # now, set up dictionaries to relate the nodes to dwellings
    nodeDict=Dict{dwelling,Int64}()
    agtDict=Dict{Int64,dwelling}()
    kdx=0
    for hot in hotels
        kdx=kdx+1
        env.nodeDict[hot]=kdx
        env.intDict[kdx]=hot
    end
    for haus in vcat(newHouses,oldHouses,exitHouses)
        kdx=kdx+1
        env.nodeDict[haus]=kdx
        env.intDict[kdx]=haus
    end

    env.transactionGraph=SimpleDiGraph(length(keys(nodeDict)))
    # now build the transaction graph by linking homes where agents would like to move
    for haus1 in vcat(hotels,oldHouses)
        for haus2 in vcat(newHouses,oldHouses,exitHouses)
            preferenceLink(env,haus1,haus2,qualityError)
        end
    end
    # now log the transaction graph
    graphLog(env,env.transactionGraph,"transaction")

    return env.transactionGraph
end

# now, we need a function that runs the inner loop of the main process
# this forms the most preferred graph 
# and the highest bidder graph 
# and takes their intersection

# note that both of these functions alter the mutable transaction graph

# first, we need separate functions for all of these
function mostPreferredGraph(env::environment,
                            mutableGraph::SimpleDiGraph,
                            hotels::Array{hotel},
                            oldHouses::Array{oldHouse}
                            )
    # form the most preferred graph
    mostPreferredGraph=SimpleDiGraph(length(vertices(mutableGraph)))
    allPreferers=vcat(hotels,oldHouses)
    for haus1 in sample(allPreferers,length(allPreferers),replace=false)
        hiQual=-Inf
        hiHaus=nothing
        # find all arrows pointing out
        pointingOut=outneighbors(mutableGraph,env.nodeDict[haus1])
        for hausDex in pointingOut
            haus2=env.intDict[hausDex]
            curQual=quality(haus2,haus1)
            if curQual >= hiQual
                hiHaus=haus2
            end
        end
        add_edge!(mostPreferredGraph,env.nodeDict[hiHaus],env.nodeDict[haus1])
    end
    graphLog(env,mostPreferredGraph,"mostPreferred")
    return mostPreferredGraph
end
# note that the highest bidder must be able to cover the outstanding mortgage of an exit house
function highestBidderGraph(env::environment,
                            mutableGraph::SimpleDiGraph,
                            newHouses::Array{newHouse},
                            oldHouses::Array{oldHouse},
                            exitHouses::Array{exitHouse})
    highBidGraph=SimpleDiGraph(length(hotelList)+length(onMarket))
    # go in random order so we can assign randomly in the case of tie
    onMarket=vcat(newHouses,oldHouses,exitHouses)
    for haus in sample(onMarket,length(onMarket),false)
        hiBudget=0
        secondHiBudget=0
        hiHaus=nothing
        # find all arrows pointing to this house
        pointingIn=inneighbors(mutableGraph,env.nodeDict[haus])
        for dwellDex in pointingIn
            dwell=env.nodeDict[dwellDex]
            budg=budgetCalc(env,dwell.owner)
            if budg >= hiBudget
                secondHiBudget=hiBudget
                hiBudget=budg
                hiHaus=dwell
            end
        end
        if typeof(hiHaus)==exitHouse
            outstandingAmt=outstandingLoan(hiHaus)
            if secondHiBudget >= outstandingAmt
                add_edge!(highBidGraph,env.nodeDict[hiHaus],env.nodeDict[haus])
                # log the second highest bid to the transaction network
                #set_prop!(env.transactionGraph,Edge(nodeDict[hiHaus],nodeDict[haus]),:bid,secondHiBudget)
                env.bidDict[Edge(nodeDict[hiHaus],nodeDict[haus])]=secondHiBudget
                # have the offered house record the second best offer
                haus.bestOffer=secondHiBudget
            end
        else
            add_edge!(highBidGraph,env.nodeDict[hiHaus],env.nodeDict[haus])
            # log the second highest bid to the transaction network
            #set_prop!(env.transactionGraph,Edge(nodeDict[hiHaus],nodeDict[haus]),:bid,secondHiBudget)
            env.bidDict[Edge(nodeDict[hiHaus],nodeDict[haus])]=secondHiBudget
            # have the offered house record the second best offer
            haus.bestOffer=secondHiBudget
        end
    end
    graphLog(env,highBidGraph,"highestBid")
    return highBidGraph
end

# now, we need the function that performs the intersection
function graphIntersect(mostPreferredGraph::SimpleDiGraph,highBidGraph::SimpleDiGraph)
    interSect=intersect(highBidGraph,mostPreferredGraph)
    graphLog(env,interSect,"intersection")
    return interSect
end

# now a function to pair back links to exit houses where the best offer won't
# cover the mortgage and deletes the entire chain / cycle



# now we need a function that takes the sale graph and alters the mutable graph
# to remove all other links pointing to the sold house
# and all links pointing from the buying dwelling

function tempTransactionPare(env::environment,saleGraph::SimpleDiGraph,mutableGraph::SimpleDiGraph)
    for edge in collect(edges(saleGraph))
        destNode=dst(edge)
        srcNode=src(edge)
        # get all edges pointing to the destination node
        for inNbh in inneighbors(mutableGraph,destNode)
            # if the inNeighbor is not the same as the source node, delete
            if inNbh!=srcNode
                rem_edge!(mutableGraph, Edge(inNbh,destNode))
            end
        end
        for outNbh in outneighbors(mutableGraph,srcNode)
            # if the outNeighbor is not the same as the destination node, delete
            if outNbh!=destNode
                rem_edge!(mutableGraph, Edge(srcNode,outNbh))
            end
        end
    end
    graphLog(env,mutableGraph,"mutableGraph")
    return mutableGraph
end

# now finally, the function that runs the inner loop step

function innerGraphIterate(env::environment,
                           hotels::Array{hotel},
                           oldHouses::Array{oldHouse},
                           newHouses::Array{newHouse},
                           exitHouses::Array{exitHouse},
                           saleGraph::SimpleDiGraph)
    # generate the mutable version of the transaction graph
    mutableGraph=env.transactionGraph
    # form the most preferred graph
    mostPreferred=mostPreferredGraph(env,mutableGraph,hotels,oldHouses)
    # form the highest bidder graph
    highestBidders=highestBidderGraph(env,mutableGraph,newHouses,oldHouses,exitHouses)
    # intersect them
    interGraph::SimpleDiGraph=graphIntersect(mostPreferred,highestBidders)
    # now, remove any chains that end in an exit house where the offer won't cover the mortgage
    graphPair=pairbackGraph(env,interGraph,mutableGraph)
    interGraph=graphPair[1]
    mutableGraph=graphPair[2]
    # now, pair back mutable transaction Graph
    mutableGraph=tempTransactionPare(env,interGraph,mutableGraph)
    saleGraph=join(saleGraph,interGraph)
    graphLog(env,saleGraph,"saleGraphIter")
    graphLog(env,mutableGraph,"mutableGraphIter")
    return (saleGraph,mutableGraph)
end

# now, we need the functions for the outer loop
function offerUpdate(env::environment,saleGraph::SimpleDiGraph)
    for edge in edges(saleGraph)
        env.nodeDict[dst(edge)].bestOffer=env.bidDict[edge]
    end
end

# now finally, the outer loop iterator
function outerGraphIterator(env::environment,
                            hotels::Array{hotel},
                            oldHouses::Array{oldHouse},
                            newHouses::Array{newHouse},
                            exitHouses::Array{exitHouse},
                            saleGraph::SimpleDiGraph)

    haltCond::bool=false

    while !haltCond
        graphPair=innerGraphIterate(env,hotels,oldHouses,newHouses,exitHouses,saleGraph)
        if graphPair[1]==graphPair[2]
            haltCond=true
        end
    end
    return graphPair[1]
end

# and the step function

function modelStep(env::environment,
                   hotels::Array{hotel},
                   oldHouses::Array{oldHouse},
                   newHouses::Array{newHouse},
                   exitHouses::Array{exitHouse})
    haltCond::Bool=false
    oldSaleGraph::SimpleDiGraph=SimpleDiGraph(0)
    newSaleGraph::SimpleDiGraph=SimpleDiGraph(0)

    while haltCond
        # iterate model and generate the current sales graph
        saleGraph=outerGraphIterator(env,hotels,oldHouses,newHouses,exitHouses)
        # update the budget of the agents
        offerUpdate(env,saleGraph)
        # halt when the sale graph stabilizes
        oldSaleGraph=newSaleGraph
        newSaleGraph=saleGraph
        if oldSaleGraph==newSaleGraph
            haltCond=true
        end
    end 
    return newSaleGraph
end

function modelTick(env::environment)
    env.tick=env.tick+1
    # agents departing the market list homes 
    exitHouses=exitHomesGen(env)
    # agents moving within the market list homes
    oldHouses=oldHomesGen(env)
    # new construction
    newHouses=newConstruction(env)
    # people looking to buy move into the market
    hotels=marketEntry(env)

    # generate the transaction graph
    env.transactionGraph=transactionGraphGen(env,hotels,newHouses,oldHouses,exitHouses)

    # now generate the sales graph
    saleGraph=modelStep(env,hotels,oldHouses,newHouses,exitHouses)

    # now track payments
    allEdges=edges(saleGraph)

    # now, we need a dictionary to store all payments
    paymentDict=Dict{dwelling,Int64}()
    for key in keys(env.nodeDict)
            paymentDict[key]=0
    end

    for edge in allEdges
        bestBid=env.bidDict[edge]
        paymentDict[dst(edge)]=bestBid

    end


    for edge in edges(saleGraph)
        haus1=env.nodeDict[src(edge)]
        haus2=env.nodeDict[dst[edge]]

        moveIn(env,haus2,haus1.owner)

        # how much is agt1 paying agt2?
        paid=paymentDict[src(edge)]

        haus2.owner=agt1
        # pay down loans on sold homes
        payFull(haus2)
        # generate mortgages on new homes
        bestBid=env.bidDict[edge]
        # now, what is the difference between what the agent is paying and what the agent was paid?
        delta=bedBid-paid
        # generate the loan
        loanGen(env,haus2,delta)

        # Now, 
        # log all sales and prices 
    end
end

function modelRun(env::environment)
    while env.tick <= env.allTicks
        modelTick(env)
    end
end