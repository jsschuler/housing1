
# we need a function that processes all sold houses. 
function allSold!(env::environment)
    for haus in vcat(env.soldHouses,env.soldEmptyHouses,env.soldExitHouses)
       # convert 
       populate!(env,haus)
    end
end
# and a function where new agents enter
function allEnter!(env::environment)
    for i in 1:env.inFlow
        #println("Hotel "*string(i)*" generated!")
        hotelGen!(env)
    end
end

# Now, we need to be aware of the issue that the number of agents who want to move either in place or away
# may exceed the number of populated houses
# thus, we randomize the order 

function upForSale!(env::environment)
    # how many populated houses are there?
    popCnt::Int64=length(env.popHouses)
    # now randomize the exiters vs the movers in place
    typeOrder=sample(vcat(repeat([:inPlace],env.inPlace),repeat([:outFlow],env.outFlow)),env.inPlace+env.outFlow,replace=false)
    # and randomize the exiting populated houses order
    hausOrder=sample(env.popHouses,length(env.popHouses),replace=false)
    for i in 1:min(length(typeOrder),length(hausOrder))
        if typeOrder[i]==:inPlace
            list!(env,hausOrder[i])
        else
            exit!(env,hausOrder[i])
        end
    end
end

function construct!(env::environment)
    newHaus=emptyHouse(length(env.allHouses)+1,rand(env.qualityDistribution,1)[1])
    push!(env.allHouses,newHaus)
    push!(env.emptyHouses,newHaus)
    return newHaus
end

function allConstruct!(env::environment)
    for i in 1:env.construction
        construct!(env)
    end
end
# now we need functions that build the dictionaries that support the network
function dictGen!(env::environment)
    env.intDict=Dict{Int64,dwelling}()
    env.nodeDict=Dict{dwelling,Int64}()
    j::Int64=0
    for haus in env.forSaleHouses
        j=j+1
        env.intDict[j]=haus
        env.nodeDict[haus]=j
    end
    for haus in env.emptyHouses
        j=j+1
        env.intDict[j]=haus
        env.nodeDict[haus]=j
    end
    for haus in env.exitHouses
        j=j+1
        env.intDict[j]=haus
        env.nodeDict[haus]=j
    end
    for hot in env.allHotels
        j=j+1
        env.intDict[j]=hot
        env.nodeDict[hot]=j
    end
end

# we need a function whereby an agent perceives house quality
function qualGen(env::environment,haus::house)
    apparentQual::Float64=haus.quality
    apparentQual=apparentQual+rand(env.qualityError,1)[1]
    return apparentQual
end

# now a function to generate the network
function graphGen!(env::environment)
    env.transactionGraph=SimpleDiGraph(0)
    # now add nodes
    for key in keys(env.intDict)
        add_vertex!(env.transactionGraph)
    end
    # now, let's generate linkages
    # there is a link between any hotel and the house the agent in the hotel likes most
    for hot in env.allHotels
        bestHaus::Union{Nothing,dwelling}=nothing
        bestQual=0.0
        for haus in vcat(env.forSaleHouses,env.emptyHouses,env.exitHouses)
            currQual=qualGen(env,haus)
            if currQual > bestQual
                bestHaus=haus
                #println("better!")
            end
        end
        #println("Debug")
        #println(hot)
        #println(bestHaus)
        add_edge!(env.transactionGraph,env.nodeDict[hot],env.nodeDict[bestHaus])
    end
    return env.transactionGraph
end

# now we need the main function that peforms a single auction

function auction!(env::environment)
    # generate dictionary
    dictGen!(env)
    # generate most preferred graph
    graphGen!(env)
    #println("Nodes")
    #println(nv(env.transactionGraph))
    #println("Edges")
    #println(ne(env.transactionGraph))
    #println("Hotels")
    #println(length(env.allHotels))
    #println("For Sale")
    #println(length(env.forSaleHouses))
    #println("Empty")
    #println(length(env.emptyHouses))
    #println("Exiting")
    #println(length(env.exitHouses))
    # now, loop over all houses for sale
    println("Debug Loop")
    println(countmap(indexReturn.(vcat(env.forSaleHouses,env.exitHouses,env.emptyHouses))))
    for haus in vcat(env.forSaleHouses,env.exitHouses,env.emptyHouses)
        # get all nodes with arrows pointing in to the house
        saleNode=env.nodeDict[haus]
        inNbbh=inneighbors(env.transactionGraph,saleNode)
        ultimateBidder::Union{Nothing,hotel}=nothing
        ultimateBid::Float64=0.0
        penultimateBidder::Union{Nothing,hotel}=nothing
        penultimateBid::Float64=0.0
        #println(haus.index)
        for i in inNbbh
            #println(intDict[i].index)
            # calculate max bid
            bigMort=maxMortgage(env,env.intDict[i]) 
            currBudget=env.intDict[i].budget 
            if typeof(haus)!=emptyHouse
                if !isnothing(haus.owner.loan)
                    totBudget=bigMort+currBudget-haus.owner.loan.outstandingBalance
                else
                    totBudget=bigMort+currBudget
                end
            else    
                totBudget=bigMort+currBudget
            end
            #println("Total Budget is: "*string(totBudget))
            if totBudget > ultimateBid
                #println("Outbidded!")
                penultimateBid=ultimateBid
                penultimateBidder=ultimateBidder
                ultimateBid=totBudget
                ultimateBidder=env.intDict[i]
            end
        end
        # now, if the second highest bid is 0, we use 90% of the highest bid instead
        if penultimateBid==0.0
            penultimateBid=.9*ultimateBid
        end
        # now that we have the highest bidder, we can sell the house
        if !isnothing(ultimateBidder)
            sell!(env,haus,ultimateBidder,penultimateBid)    
        end
    end
end
# now the way the model will work is as follows:
# at each tick:
    # 1 Sold houses become populated houses and their owners move to hotels
    # 2 Sold Exit houses become populated houses and their owners leave the market
    # 3. a number of new agents enter the market and dwell in hotels
    # 4. a number of new houses are built 
    # 5. a number of agents decide to leave the market and list their houses as exit houses
    # 6. a number of agents decide to move within the market and list their houses as for sale houses
    # 7 now, the inner loop starts and runs for a set number of rounds
        # a preference graph is generated connecting hotels to empty houses, exit houses, or for sale houses
        # in this preference graph, each hotel is connected to the house it prefers most
        # each house is sold to the highest bidding hotel for the price of the second highest bidding hotel 
        # the exit or for sale houses become sold exit houses
        # this means that agents which successfully, do not re-enter the market until the next tick
function modelTick!(env::environment)
    #increment model tick
    env.tick=env.tick+1
    #println("Initial")
    #println(env.tick)
    #println("Hotels")
    #println(length(env.allHotels))
    #println("For Sale")
    #println(length(env.forSaleHouses))
    #println("Empty")
    #println(length(env.emptyHouses))
    #println("Exiting")
    #println(length(env.exitHouses))
    
    # every loan is paid
    for loan in env.loanList
        payLoan(loan)
        assessInterest(loan)
    end
    # now, if the agent has paid the loan in full, delete it
    tmpList=loan[]
    for loan in env.loanList
        if !loan.paidInFull
            push!(tmpList,loan)
        end
    end
    for agt in env.agtList
        if !isnothing(agt.loan)
            if agt.loan.paidInFull
                loanFullLog(env,loan)
                agt.loan=nothing
            end
        end
    end
    env.loanList=tmpList



    # process all sold houses
    allSold!(env)
    
    #println("After All Sold")
    #println(env.tick)
    #println("Hotels")
    #println(length(env.allHotels))
    #println("For Sale")
    #println(length(env.forSaleHouses))
    #println("Empty")
    #println(length(env.emptyHouses))
    #println("Exiting")
    #println(length(env.exitHouses))
    # build new homes
    allConstruct!(env)

    #println("After Constructed")
    #println(env.tick)
    #println("Hotels")
    #println(length(env.allHotels))
    #println("For Sale")
    #println(length(env.forSaleHouses))
    #println("Empty")
    #println(length(env.emptyHouses))
    #println("Exiting")
    #println(length(env.exitHouses))
    # new agents enter
    allEnter!(env)
    
    #println("After Entering")
    #println(env.tick)
    #println("Hotels")
    #println(length(env.allHotels))
    #println("For Sale")
    #println(length(env.forSaleHouses))
    #println("Empty")
    #println(length(env.emptyHouses))
    #println("Exiting")
    #println(length(env.exitHouses))

    # put all houses up for sale
    upForSale!(env)

    #println("After Up For Sale")
    #println(env.tick)
    #println("Hotels")
    #println(length(env.allHotels))
    #println("For Sale")
    #println(length(env.forSaleHouses))
    #println("Empty")
    #println(length(env.emptyHouses))
    #println("Exiting")
    #println(length(env.exitHouses))

    # now we run the auction for 10000 ticks or until there are no remaining houses up for sale
    aTick::Int64=0
    while length(vcat(env.forSaleHouses,env.exitHouses,env.emptyHouses)) > 0
        aTick=aTick+1
        auction!(env)
        if aTick==10000
            break
        end
    end
end

function modelRun!(env::environment)
    global allTicks

    for t in 1:allTicks
        modelTick!(env)
    end
    return nothing
end

function isReady(arg::Int64)
    if isready(coreDict[c])
        return true
    else
        return false
    end
end
