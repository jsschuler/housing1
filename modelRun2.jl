# now the way the model will work is as follows:
# at each tick:
    #1. a number of new agents enter the market and dwell in hotels
    #2. a number of agents decide to leave the market. They will sell at any price. 
    #3. a number of new houses are built 
    #4. a number of agents decide to move within the market. 
        # They will sell if they have sell if they have seen a preferable house sold at a price they can afford
        # in this case, they sell their house to the highest bidder and enter a hotel
    # Critically, this step happens last so agents can't buy their own house. 

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
# now we need to load the code that generates the preference error term 
include("qualityDistribution.jl")

# now we need a function to generate the perference graph 
# it connects hotels to houses the occupant prefers within the quality bound 

function preferenceGraphGen(env::environment)
    # first clear the existing graph
    env.transactionGraph=SimpleDiGraph(0)
    empty!(env.nodeDict)
    empty!(env.intDict) 
    empty!(env.qualDict)
    # now add all hotels and houses on the market to the graph
    for hot in env.allHotels
        add_vertex!(env.transactionGraph)
        env.nodeDict[hot]=nv(env.transactionGraph)
        env.intDict[nv(env.transactionGraph)]=hot
        env.qualDict[Graphs.SimpleGraphs.SimpleEdge{Int64}(nv(env.transactionGraph),nv(env.transactionGraph))]=hot.quality
    end
    for haus in env.allHouses
        if typeof(haus)==emptyHouse
            add_vertex!(env.transactionGraph)
            env.nodeDict[haus]=nv(env.transactionGraph)
            env.intDict[nv(env.transactionGraph)]=haus
            env.qualDict[Graphs.SimpleGraphs.SimpleEdge{Int64}(nv(env.transactionGraph),nv(env.transactionGraph))]=haus.quality
        end
    end
    # now add edges from hotels to the most preferred empty houses
    for hot in env.allHotels
        bestHaus::Union{nothing,emptyHouse}=nothing
        bestQual=-Inf
        for haus in filter!(h -> typeof(h)==emptyHouse, env.allHouses)
            # calculate house quality with error
            currQual=hausQuality(haus)+rand(qualityError,1)[1]
            if currQual > bestQual
                bestHaus=haus
            end
        end
        # now add an edge from the hotel to the most preferred house
        add_edge!(env.transactionGraph,env.nodeDict[hot],env.nodeDict[bestHaus]) 
    end
    return env.transactionGraph
end

# now we need a function that process the preference graph 
# each house is sold to the highest bidding arrow in

function processPreferenceGraph(env::environment)
    # loop over all houses on the market
    for haus in filter!(h -> typeof(h)==emptyHouse, env.allHouses)
        inBidders=inNeighbors(env,haus)
        if length(inBidders)>0
            # if there are any bidders, sell to the highest bidder
            maxBid=-Inf
            bestBidder=nothing
            for bidder in inBidders
                bidAmt=budgetCalc(env,bidder)
                if bidAmt > maxBid
                    maxBid=bidAmt
                    bestBidder=bidder
            end
            if !isnothing(bestBidder)
                # sell the house to the highest bidder
                haus.owner=bestBidder.owner
                bestBidder.houses=push!(bestBidder.houses,haus)
            end
        end
    end
end
