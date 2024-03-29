
# a function that randomly selects homes for agents who want to exit

function exitHomesGen(env::environment,exitHouses::Array{exitHouse},oldHouses::Array{oldHouse},newHouses::Array{newHouse})
    # find homes that can be exit homes 
    stillOnMarket=vcat(exitHouses,oldHouses,newHouses)
    marketable=setdiff(env.allHouses,stillOnMarket)
    marketableIdx=[]
    # now, get indexes for both the list of all houses and the marketable list 
    for mark in marketable
        push!(marketableIdx,filter(i -> env.allHouses[i]==mark,1:length(env.allHouses))[1])
    end
    maxExit=min(length(marketableIdx),env.outFlow)
    exitIdx=sample(marketableIdx,maxExit,replace=false)
    allExits=exitHouse[]
    for i in exitIdx
        #println(env.allHouses[i])
        exitHaus=makeExit(env.allHouses[i])
        env.allHouses[i]=exitHaus
        push!(allExits,exitHaus)
    end
    return allExits
end
# a function that randomly selects agents who want to move in place
function oldHomesGen(env::environment,exitHouses::Array{exitHouse},oldHouses::Array{oldHouse},newHouses::Array{newHouse})
    stillOnMarket=vcat(exitHouses,oldHouses,newHouses)
    marketable=setdiff(env.allHouses,stillOnMarket)
    canMove::Array{oldHouse}=oldHouse[]
    for haus in marketable
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
    for i in 1:env.construction
        newHaus=houseGen(env)
        houseLog(env,newHaus)
        push!(newList,newHaus)
    end
    return newList
end
# and the function whereby new agents enter the market

function marketEntry(env::environment)
    hotelList::Array{hotel}=hotel[]
    for i in 1:env.inFlow
        push!(hotelList,hotelGen(env))
    end
    return hotelList
end
# now we need to load the code that generates the preferende error term 
include("qualityDistribution.jl")


function preferenceLink(env::environment,dwelling1::dwelling,dwelling2::dwelling,error::Distribution)
    qual2=dwelling2.quality+rand(qualityError,1)[1]
    qual1=dwelling1.quality+rand(qualityError,1)[1]

     if qual2 > qual1
        add_edge!(env.transactionGraph,env.nodeDict[dwelling1],env.nodeDict[dwelling2])
        # now, add the  utility each agent gets from owning the house as an edge property
        #set_prop!(env.transactionGraph,,:qual,qual2)
        env.qualDict[Edge(env.nodeDict[dwelling1],env.nodeDict[dwelling2])]=qual2
    end
end


# now, we need the function that generates the transaction graph
function transactionGraphGen(env::environment,
                             hotels::Array{hotel},
                             newHouses::Array{newHouse},
                             oldHouses::Array{oldHouse},
                             exitHouses::Array{exitHouse})
                            

    # now, set up dictionaries to relate the nodes to dwellings
    env.intDict=Dict{Int64,dwelling}()
    env.nodeDict=Dict{dwelling,Int64}()
    hashes=[]
    
    kdx=0
    for hot in hotels
        kdx=kdx+1
        push!(hashes,hash(hot))
        env.nodeDict[hot]=kdx
        env.intDict[kdx]=hot
        if length(keys(env.nodeDict))!=length(keys(env.intDict))
            println("Error")
            println(hot)
        end
    end
    for haus in vcat(newHouses,oldHouses,exitHouses)
        kdx=kdx+1
        push!(hashes,hash(haus))
        env.nodeDict[haus]=kdx
        env.intDict[kdx]=haus
        if length(keys(env.nodeDict))!=length(keys(env.intDict))
            println("Error")
            println(haus)
            # is there also an exit house with this index?
            println("exit houses")
            println(filter(x->x.index==haus.index,exitHouses))
            println(filter(x->hash(x)==hash(haus),exitHouses))
            println("new houses")
            println(filter(x->hash(x)==hash(haus),newHouses))
            println(filter(x->hash(x)==hash(haus),newHouses))      
                  
        end
    end

    env.transactionGraph=SimpleDiGraph(length(keys(env.nodeDict)))
    #println("Graph Check")
    #println(env.transactionGraph)
    #println("int dict check")
    #println(length(keys(env.intDict)))
    #println("node dict check")
    #println(length(keys(env.nodeDict)))
    # now build the transaction graph by linking homes where agents would like to move
    for haus1 in vcat(hotels,oldHouses)
        for haus2 in vcat(newHouses,oldHouses,exitHouses)
            preferenceLink(env,haus1,haus2,qualityError)
        end
    end
    # now log the transaction graph
    #graphLog(env,env.transactionGraph,"transaction")
    #graphLog(env,env.transactionGraph,"transactionGraph")
    #checkPoint("transaction Graph Generated")
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
        #println(env.nodeDict[haus1])
        #println(mutableGraph)
        #println(keys(env.nodeDict))
        pointingOut=outneighbors(mutableGraph,env.nodeDict[haus1])
        for hausDex in pointingOut
            haus2=env.intDict[hausDex]
            #curQual=quality(haus2,haus1)
            #println("Debug")
            #println(haus1)
            #println(countmap(keys(env.intDict)))
            #println(any(keys(env.intDict).==haus1.index))
            currQual=env.qualDict[Edge(env.nodeDict[haus1],hausDex)]
            #println(currQual)
            #println(hiQual)
            if currQual >= hiQual
                hiHaus=haus2
                hiQual=currQual
            end
        end
        if !isnothing(hiHaus)
            add_edge!(mostPreferredGraph,env.nodeDict[haus1],env.nodeDict[hiHaus])
        end
    end
    #graphLog(env,mostPreferredGraph,"mostPreferred")
    #checkPoint("Most Preferred Graph Generated")
    #graphLog(env,mostPreferredGraph,"mostPreferred")
    return mostPreferredGraph
end
# note that the highest bidder must be able to cover the outstanding mortgage of an exit house
function highestBidderGraph(env::environment,
                            mutableGraph::SimpleDiGraph,
                            newHouses::Array{newHouse},
                            oldHouses::Array{oldHouse},
                            exitHouses::Array{exitHouse})
   
    # go in random order so we can assign randomly in the case of tie
    onMarket=vcat(newHouses,oldHouses,exitHouses)
    highBidGraph=SimpleDiGraph(length(env.allHotels)+length(onMarket))
    # get a dictionary to keep bid
    bidDict::Dict{Int64}{Int64}=Dict{Int64}{Int64}()
    for haus in sample(onMarket,length(onMarket),replace=false)
        hiBudget=0
        secondHiBudget=0
        hiHaus=nothing
        # find all arrows pointing to this house
        pointingIn=collect(inneighbors(mutableGraph,env.nodeDict[haus]))
        #println(pointingIn)
        for dwellDex in pointingIn
            dwell=env.intDict[dwellDex]
            budg=budgetCalc(env,dwell)
            #println("Budget")
            #println(budg)
            #println(hiBudget)
            #println(secondHiBudget)
            #println(budg >= hiBudget)
            if budg >= hiBudget
                secondHiBudget=hiBudget
                hiBudget=budg
                hiHaus=dwell
            end
        end
        #if Edge(env.nodeDict[hiHaus],env.nodeDict[haus])==Edge(17,589)
        #    print("Here!")
        #end
        #println("Budget")
        #println(hiBudget)
        #println(hiHaus)
        # now, add an edge if there is a bidder
        
        

        if !isnothing(hiHaus)
            if typeof(hiHaus)==exitHouse
                println("outstanding")
                println(outstandingAmt)
                outstandingAmt=outstandingLoan(hiHaus)
                if secondHiBudget >= outstandingAmt
                    add_edge!(highBidGraph,env.nodeDict[hiHaus],env.nodeDict[haus])
                    # log the second highest bid to the transaction network
                    #set_prop!(env.transactionGraph,Edge(nodeDict[hiHaus],nodeDict[haus]),:bid,secondHiBudget)
                    bidDict[nodeDict[haus]]=secondHiBudget
                    # have the offered house record the second best offer
                    #println("second offer")
                    #println(secondHiBudget)
                    #haus.bestOffer=secondHiBudget
                end
            else
                #println("HiHaus")
                #println(hiHaus)
                add_edge!(highBidGraph,env.nodeDict[hiHaus],env.nodeDict[haus])
                # log the second highest bid to the transaction network
                #set_prop!(env.transactionGraph,Edge(nodeDict[hiHaus],nodeDict[haus]),:bid,secondHiBudget)
                bidDict[env.nodeDict[haus]]=secondHiBudget
                # have the offered house record the second best offer
                #println("second offer")
                #println(secondHiBudget)
                #haus.bestOffer=secondHiBudget
            end
        end
    end
    #graphLog(env,highBidGraph,"highestBid")
    #graphLog(env,highBidGraph,"hiBid")
    #bestOfferVec=[]
    #for haus in vcat(newHouses,oldHouses,exitHouses)
    #    push!(bestOfferVec,haus.bestOffer)
    #end
    #println(countmap(bestOfferVec))
    checkPoint("Highest Bidder Graph Generated")
    return (highBidGraph,bidDict)
end

# now, we need the function that performs the intersection
function graphIntersect(env::environment,mostPreferredGraph::SimpleDiGraph,highBidGraph::SimpleDiGraph,bidDict::Dict{Int64}{Int64})
    interSect=intersect(highBidGraph,mostPreferredGraph)
    #graphLog(env,interSect,"intersection")
    #graphLog(env,interSect,"intersection")
    #checkPoint("Graph Intersection")

    # now, get only the bids that are actually both highest and most preferred
    smallBidDict::Dict{Int64}{Int64}=Dict{Int64}{Int64}()
    
    for ky in keys(bidDict)
        smallBidDict[ky]=bidDict[ky]
    end

    return (interSect,smallBidDict)
end

# now a function to pair back links to exit houses where the best offer won't
# cover the mortgage and deletes the entire chain / cycle
# ignore for now
function pairbackGraph(env::environment,interGraph::SimpleDiGraph,mutableGraph::SimpleDiGraph)
    return (interGraph,mutableGraph)
end


# now we need a function that takes the sale graph and alters the mutable graph
# to remove all other links pointing to the sold house
# and all links pointing from the buying dwelling

function tempTransactionPare(env::environment,saleGraph::SimpleDiGraph,mutableGraph::SimpleDiGraph)
    #println("Sales")
    #println(length(collect(edges(saleGraph))))
    for edge in collect(edges(saleGraph))
        destNode=dst(edge)
        srcNode=src(edge)
        #println("Graph Sale")
        #println(srcNode)
        #println(destNode)
        # get all edges pointing to the destination node
        #println("Neighbors Now")
        #println(inneighbors(mutableGraph,destNode))
        #println(outneighbors(mutableGraph,srcNode))

        inNbhList=collect(inneighbors(mutableGraph,destNode))
        for inNbh in inNbhList
            # if the inNeighbor is not the same as the source node, delete
            #println((inNbh,destNode))
            if inNbh!=srcNode
                #println((inNbh,destNode))
                rem_edge!(mutableGraph,inNbh,destNode)
            end
        end
        outNbhList=collect(outneighbors(mutableGraph,srcNode))
        for outNbh in outNbhList
            # if the outNeighbor is not the same as the destination node, delete
            #println((srcNode,outNbh))
            if outNbh!=destNode
                #println((srcNode,outNbh))
                rem_edge!(mutableGraph, srcNode,outNbh)
            end
        end
        #println("Neighbors Later")
        #println(inneighbors(mutableGraph,destNode))
        #println(outneighbors(mutableGraph,srcNode))
    end
    #graphLog(env,mutableGraph,"mutableGraph")
    #graphLog(env,mutableGraph,"tempTrans")
    #checkPoint("Temporary Transaction Graph")
    return mutableGraph
end

# now finally, the function that runs the inner loop step

function innerGraphIterate(env::environment,
                           mutableGraph::SimpleDiGraph,
                           hotels::Array{hotel},
                           oldHouses::Array{oldHouse},
                           newHouses::Array{newHouse},
                           exitHouses::Array{exitHouse})
    
    # form the most preferred graph
    mostPreferred=mostPreferredGraph(env,mutableGraph,hotels,oldHouses)
    # form the highest bidder graph
    hiBidData=highestBidderGraph(env,mutableGraph,newHouses,oldHouses,exitHouses)
    highestBidders=hiBidData[1]    
    # and set high bid dictionry 
    bidDict=hiBidData[2]
    # intersect them
    interVec=graphIntersect(env,mostPreferred,highestBidders,bidDict)
    interGraph::SimpleDiGraph=interVec[1]
    newDict=interVec[2]
    # now overwrite the environment bid dictionary with the new high bids
    for ky in keys(newDict)
        env.bidDict[ky]=newDict[ky]
    end

    graphLog(env,interGraph,"interGraph")
    # now, if an edge is associated with an offer that will not cover the mortgage of an exit house, delete it so long as we have this setting
    #if env.mortgageFlag
    #    allEdge=collect(edges(interGraph))
    #    for edg in allEdge
    #
    #    end
    #end
    #graphPair=pairbackGraph(env,interGraph,mutableGraph)
    #interGraph=graphPair[1]
    #mutableGraph=graphPair[2]
    

    # now, for each edge corresponding to a sale, remove from the mutable graph all other arrows coming out of the source, and other arrows pointing in to the destination
    mutableGraph=tempTransactionPare(env,interGraph,mutableGraph)

    
    #graphLog(env,mutableGraph,"tempTransInner")
    #checkPoint("Inner Iteration")

    # return just the mutable graph

    return (mutableGraph,bidDict)
end

# now, we need the functions for the outer loop
function offerUpdate(env::environment,saleGraph::SimpleDiGraph)
    for edge in edges(saleGraph)
        #print("Debug")
        #println(keys(env.nodeDict))
        #println(keys(env.bidDict))
        #println(outneighbors(mutableGraph,10))
        env.intDict[dst(edge)].bestOffer=env.bidDict[dst(edge)]
    end
    return env
end

# now finally, the outer loop iterator
function outerGraphIterator(env::environment,
                            mutableGraph::SimpleDiGraph,
                            hotels::Array{hotel},
                            oldHouses::Array{oldHouse},
                            newHouses::Array{newHouse},
                            exitHouses::Array{exitHouse}
                            )

    
    # for the outer iterator, we halt when there are no more nodes pointing to more than one other node
    
    haltCond::Bool=false
    while !haltCond
        haltCond=true
        for edg in edges(mutableGraph)
            if length(outneighbors(mutableGraph,src(edg))) > 1 || length(inneighbors(mutableGraph,dst(edg))) > 1
                #println("continue")
                haltCond=false
            end
        end
        
        innerDat=innerGraphIterate(env,mutableGraph,hotels,oldHouses,newHouses,exitHouses)
        mutableGraph=innerDat[1]
        currBidDict=innerDat[2]
        # now update overall bid dictionary
        for ky in keys(currBidDict)
            env.bidDict[ky]=currBidDict[ky]
        end

    end
    # check graph
    outNbhList=[]
    inNbhList=[]
    for edg in edges(mutableGraph)
        push!(outNbhList,length(outneighbors(mutableGraph,src(edg)))) 
        push!(inNbhList,length(inneighbors(mutableGraph,dst(edg))))
    end
    #println("Report")
    #println(maximum(outNbhList))
    #println(maximum(inNbhList))

    #graphLog(env,mutableGraph,"mutableGraphOuter")
    
    #checkPoint("Outer Iteration")
    return mutableGraph
end

# and the step function

function modelStep(env::environment,
                   hotels::Array{hotel},
                   oldHouses::Array{oldHouse},
                   newHouses::Array{newHouse},
                   exitHouses::Array{exitHouse})
    haltCond::Bool=false
    mutableGraph=env.transactionGraph
    oldGraph::SimpleDiGraph=SimpleDiGraph(0)
    newGraph::SimpleDiGraph=SimpleDiGraph(0)

    # now, for each model step, we update offers each time 
    # once the transaction graph has stabilized across two steps,
    # we halt
    haldCond::Bool=false
    ticker::Int64=0
    while !haltCond
        ticker=ticker+1
        oldGraph=newGraph

        # update budgets given offers
        if ticker > 1
            println(oldGraph)
            println(outneighbors(oldGraph,17))
            println(length(keys(env.bidDict)))
            env=offerUpdate(env,oldGraph)
        end
        # the outer graph iterator needs to define the bid dictionary
        newGraph=outerGraphIterator(env,
                                    mutableGraph,
                                    hotels,
                                    oldHouses,
                                    newHouses,
                                    exitHouses
                                    )
        
        
        
        # now, if the transaction graph stabilizes after agents re-evaluate
        # halt
        if oldGraph==newGraph
            haltCond=true
        end
    end
    return newGraph
end

function modelTick(env::environment,exitHouses::Array{exitHouse},oldHouses::Array{oldHouse},newHouses::Array{newHouse},hotels::Array{hotel})
    checkPoint("Tick")
    env.tick=env.tick+1
    println("Debug 0")
    println(countmap(typeof.(keys(env.nodeDict))))
    # agents departing the market list homes 
    exitHouses=vcat(exitHouses,exitHomesGen(env,exitHouses,oldHouses,newHouses))
    # agents moving within the market list homes
    oldHouses=vcat(oldHouses,oldHomesGen(env,exitHouses,oldHouses,newHouses))
    # new construction
    newHouses=vcat(newHouses,newConstruction(env))
    # people looking to buy move into the market
    hotels=marketEntry(env)

    #println("Debug 1")
    #println(countmap(typeof.(keys(env.nodeDict))))
    #println(length(keys(env.nodeDict)))
    #println(length(oldHouses)+length(newHouses)+length(exitHouses)+length(hotels))


    # generate the transaction graph
    env.transactionGraph=transactionGraphGen(env,hotels,newHouses,oldHouses,exitHouses)

    # now generate the sales graph
    saleGraph=modelStep(env,hotels,oldHouses,newHouses,exitHouses)
    #graphLog(env,saleGraph,"saleGraphStep")
    #println("Debug 2")
    #println(countmap(typeof.(keys(env.nodeDict))))

    # now make sure the sale chains are valid 


    allEdges=edges(saleGraph)

    # now, we need a dictionary to store all payments
    paymentDict=Dict{dwelling,Int64}()
    for key in keys(env.nodeDict)
            paymentDict[key]=0
    end
    #println("Debug 3")
    #println(countmap(typeof.(keys(env.nodeDict))))
    for edge in allEdges
        bestBid=env.bidDict[dst(edge)]
        paymentDict[env.intDict[dst(edge)]]=bestBid
    end

    #println("Debug 4")
    #println(keys(env.nodeDict))
    #println(length(keys(env.nodeDict)))
    #println(countmap(keys(env.nodeDict)))
    
    #println("All Paths")
    #println(saleGraph)
    allSalePaths=allPaths(saleGraph)
    #println(allSalePaths)
    
    # What is the distribution of best offers?
    bestOffers=[]
    for dwell in vcat(oldHouses,newHouses,exitHouses)
        push!(bestOffers,dwell.bestOffer)
    end
    println(countmap(bestOffers))
    checkPoint("Offers")
    
    # check if the paths begin with hotels and end with exit houses
    
    # removal edges
    removalEdges=[]
    for vert in keys(allSalePaths)
        path=allSalePaths[vert]
        if typeof(env.intDict[src(path[1])])==hotel && (typeof(env.intDict[dst(path[length(path)])])==exitHouse || typeof(env.intDict[dst(path[length(path)])])==newHouse)
            println("Good Path")
            println(length(path))
            println(env.intDict[src(path[1])])
            println(env.intDict[dst(path[length(path)])])
            checkPoint("Good Path")
        else
            println("Bad Path")
            println(length(path))
            println(env.intDict[src(path[1])])
            println(env.intDict[dst(path[length(path)])])
            checkPoint("Bad Path")

            for ed in path
                rem_edge!(saleGraph,ed)
            end
        end
    end


    for edge in edges(saleGraph)

        # remove from lists

        filter!(x-> x!=env.intDict[src(edge)],hotels)
        filter!(x-> x!=env.intDict[src(edge)],oldHouses)
        

        
        filter!(x-> x!=env.intDict[dst(edge)],oldHouses)
        filter!(x-> x!=env.intDict[dst(edge)],exitHouses)
        filter!(x-> x!=env.intDict[dst(edge)],newHouses)

        env=moveIn(env,env.intDict[dst(edge)],env.intDict[src(edge)].owner)

        # how much is agt1 paying agt2?
        paid=paymentDict[env.intDict[src(edge)]]
        saleLog(env,env.intDict[dst(edge)],paid)

        # pay down loans on sold homes
        env=payFull(env,env.intDict[dst(edge)])
        # generate mortgages on new homes
        bestBid=env.bidDict[dst(edge)]
        # now, what is the difference between what the agent is paying and what the agent was paid?
        delta=bestBid-paid

        # generate the loan
        env=loanGen(env,env.intDict[dst(edge)],delta)

        # Now, 
        # log all sales and prices 

    end

    #println("Lengths After")
    #println(length(oldHouses))
    #println(length(newHouses))
    #println(length(exitHouses))
    #println(length(hotels))

    #println("Indices After")
    #println(fIndex.(oldHouses))
    #println(fIndex.(newHouses))
    #println(fIndex.(exitHouses))
    #println(fIndex.(hotels))

    # clear dictionaries
    env.nodeDict=Dict{dwelling,Int64}()
    env.intDict=Dict{Int64,dwelling}()
    # return the unsold houses
    return (exitHouses,oldHouses,newHouses,hotels)

end

function modelRun(env::environment)
    oldHouses=oldHouse[]
    exitHouses=exitHouse[]
    newHouses=newHouse[]
    hotels=hotel[]
    while env.tick <= env.allTicks
        println(env.tick)
        remaining=modelTick(env,exitHouses,oldHouses,newHouses,hotels)
        exitHouses=remaining[1]
        oldHouses=remaining[2]
        newHouses=remaining[3]
        hotels=remaining[4]
    end
end