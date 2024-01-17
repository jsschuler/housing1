# Part I: pure calculation functions
# these functions do not depend on the objects 


function mortgageCalc(payment::Int64)
    global interestRate
    monthlyRate::Float64=interestRate/12 
    # apply interest rate calculation
    
    
    return floor(Int64,payment*(((1+monthlyRate)^(12*30)) -1)/(monthlyRate*(1+monthlyRate)^(12*30)))+1
end

function outstandingBalance(ln::loan,k::Int64)
    #println(k)
    monthlyRate=ln.interestRate/12
    #println(ln.interestRate)
    #println(monthlyRate)
    n=30*12
    ratDelta=Rational((1+monthlyRate)^n)-Rational((1+monthlyRate)^k)
    denom=-1+(1+monthlyRate)^n
    ratio=ratDelta/denom
    return floor(Int64,ln.initialBalance*ratio)
end



# the function that pays down a loan
function payLoan(obj::loan)
    
    if !obj.paidInFull 
        obj.paymentsMade=obj.paymentsMade+1
        obj.outstandingBalance=floor(Int64,outstandingBalance(obj,obj.paymentsMade))
    end

    if obj.paymentsMade==30*12
        obj.paidInFull=true
        obj.outstandingBalance=0
    end
    return obj.paidInFull
end

# the function that generates an agent

function agtGen()
    global agtList
    global paymentDistribution
    outAgt=agent(length(agtList),floor(Int64,rand(paymentDistribution,1)[1]))
    push!(agtList,outAgt)
    return outAgt
end

#the function that generates a house

function houseGen()
    global houseList
    global houseCounter
    houseCounter=houseCounter+1
    haus=newHouse(houseCounter,rand(qualityDistribution,1)[1],nothing,nothing,nothing)
    push!(houseList,haus)
    return haus
end

function hotelGen()
    global hotelList
    global hotelCounter
    hotelCounter=hotelCounter+1
    hot=hotel(-hotelCounter,agtGen(),nothing)
    push!(hotelList,hot)
    return hot
end

# we need a function that links properties when the agent 
# living in one property prefers the other

function addArrow!(dwelling1::dwelling,dwelling2::dwelling)
    global nodeDict
    global transactionGraph
    #println(dwelling1)
    #println(dwelling2)
    #println(nodeDict[dwelling1])
    #println(nodeDict[dwelling2])
    add_edge!(transactionGraph,nodeDict[dwelling1],nodeDict[dwelling2])
    # now add 
end

function preferenceLink(dwelling1::dwelling,dwelling2::dwelling)
    global nodeDict
    global transactionGraph
    qual2=hausQuality(haus2)
    qual1=hausQuality(haus1)

     if qual2 > qual2
        addArrow!(haus1,haus2)
        # now, add the bid and the utility as properties of the edge
        set_prop!(transactionGraph,Edge(nodeDict[dwelling1],nodeDict[dwelling2]),:bid,haus1.budget)
        set_prop!(transactionGraph,Edge(nodeDict[dwelling1],nodeDict[dwelling2]),:util,qual2)
    end
end




# and one that removes them

function remArrow!(dwelling1::dwelling,dwelling2::dwelling)
    global nodeDict
    global transactionGraph
    rem_edge!(transactionGraph,nodeDict[dwelling1],nodeDict[dwelling2])
end

# we need a function that returns all the edges as ordered pairs of dwellings 

function dwellEdges()
    global transactionGraph
    global agtDict

    allEdges=edges(transactionGraph)
    allSources=src.(allEdges)
    allDests=dst.(allEdges)
    allTuples=[]
    for i in 1:length(allSources)
        push!(allTuples,(agtDict[allSources[i]],agtDict[allDests[i]]))
    end
    return allTuples
end

# we need neighbor functions

function inNeighbors(dwell::dwelling)
    global agtDict
    global transactionGraph
    global nodeDict

    nbhs=inneighbors(transactionGraph,nodeDict[dwell])
    structNbh=[]
    for nb in nbhs
        push!(structNbh,agtDict[nb])
    end
    return structNbh
end

function outNeighbors(dwell::dwelling)
    global agtDict
    global transactionGraph
    global nodeDict

    nbhs=outneighbors(transactionGraph,nodeDict[dwell])
    structNbh=[]
    for nb in nbhs
        push!(structNbh,agtDict[nb])
    end
    return structNbh
end

function removeEdge!(dwell1::dwelling,dwell2::dwelling)
    global nodeDict
    global transactionGraph
    rem_vertex!(transactionGraph,nodeDict[dwell1],nodeDict[dwell2])
end

function nodeBidder(haus::dwelling)
    # this function identifies and removes all but the highest bidder and records the second highest bidder's bid
    allIn=inNeighbors(haus)
    
end


# we need the function that turns a new house into an old house 

function makeOld(haus::newHouse,agt::agent)
    global houseList
    hIndex=0
    for i in 1:length(houseList)
        if houseList[i]==haus
            hIndex=i
        end
    end
    currHaus=oldHouse(haus.index,haus.quality,agt,nothing,nothing)
    houseList[hIndex]=currHaus
    return haus
end
# and a function that turns an old house into an exit house
function makeExit(haus::oldHouse)
    global houseList
    hIndex=0
    for i in 1:length(houseList)
        if houseList[i]==haus
            hIndex=i
        end
    end
    currHaus=exitHouse(haus.index,haus.quality,haus.owner,nothing,nothing)
    houseList[hIndex]=currHaus
    return currHaus
end


# now we need the function that randomly assigns agents and houses 

function houseShuffle()
    global agtList
    global houseList
    global dwellingAgtDict
    for i in 1:length(agtList)
        makeOld(houseList[i],agtList[i])
    end
end

# this function will allow richer agents to get their more preferred house

function housingSwap(house1,house2)
    #println("Debug")
    #println(house1.quality)
    #println(house2.quality)
    #println(house1.owner.budget)
    #println(house2.owner.budget)
    #println((house1.quality > house2.quality) & (house1.owner.budget < house2.owner.budget))
    #println((house2.quality > house1.quality) & (house2.owner.budget < house1.owner.budget))
    if (house1.quality > house2.quality) & (house1.owner.budget < house2.owner.budget)
        #println("swapped")
        richOwner=house2.owner
        house2.owner=house1.owner
        house1.owner=richOwner

        swap=true
    elseif (house2.quality > house1.quality) & (house2.owner.budget < house1.owner.budget)
        #println("swapped")
        richOwner=house1.owner
        house1.owner=house2.owner
        house2.owner=richOwner
        swap=true
    else
        #println("Flag3")
        swap=false
    end
    return swap
end

function initialSwapping()
    tick::Int64=0
    global houseList
    while true
        # select two random houses 
        twoHouses=sample(houseList,2,replace=false)
        tick=tick+1
        #println(tick)
        if housingSwap(twoHouses[1],twoHouses[2])
            tick=0
        end
        if tick==1000
            break
        end
    end
end


function loanGen(payment::Int64,collat::house)
    global interestRate
    initialBalance=mortgageCalc(payment)
    global loanList
    push!(loanList,loan(interestRate,initialBalance,payment,initialBalance,0,collat,false))
end

# we need a function that returns the quality of an agent's current house 
# if the agent has no house, it returns -inf 

function hausQuality(haus::house)
    return haus.quality+rand(qualityError,1)[1]
end

function hausQuality(haus::hotel)
    return -Inf
end

# also, we need a function where an agent calculates its budget for a house

function budgetCalc(hotel)
    global interestRate
    homeBudget=mortgageCalc(hotel.owner.budget)
    return homeBudget
end

function budgetCalc(haus::house,saleValue)
    global interestRate
    # does the agent own a house?
    agtHaus=houseOwner(agt)
    if isnothing(agtHaus)
        homeBudget=mortgageCalc(haus.owner.budget)
    else
        currLoan=agtLoan(agt)
        # how much equity does the agent have?
        equity=saleValue-currLoan.outstandingBalance
        homeBudget=equity+mortgageCalc(agt.budget)
    end
    return homeBudget
end

# summary functions

function arraySummarize(array::Vector)
    return countmap(typeof.(array))
end

# we need a function for an agent to make an offer

function offer(currDwelling::dwelling,targetDwelling::dwelling)
    
end