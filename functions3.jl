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
    push!(agtList,agent(length(agtList),floor(Int64,rand(paymentDistribution,1)[1])))
end

#the function that generates a house

function houseGen()
    global houseList
    haus=newHouse(rand(qualityDistribution,1)[1],nothing,nothing)
    push!(houseList,haus)
    push!(dwellingList,haus)
    return haus
end

function hotelGen()
    global hotelList
    hot=hotel(agtGen(),nothing)
    push!(hotelList,hot)
end

# we need a function that generates the network

function networkGen()
    global transactionGraph
    global houseList
    global hotelList
    # generate graph
    transactionGraph=SimpleDiGraph(length(houseList)+length(hotelList))
end

# now, we need functions that give neighbors in agent terms

function agtNeighbor(agt::agent)
end

function agtNeighbor(dwell::dwelling)
end

function agtNeighbor(ln::loan)
end
# and neighbors in terms of dwellings
function dwellNeighbor(agt::agent)
end

function dwellNeighbor(dwell::dwelling)
end

function dwellNeighbor(ln::loan)
end

# and neighbors in terms of loans
function loanNeighbor(agt::agent)
end

function loanNeighbor(dwell::dwelling)
end

function loanNeighbor(ln::loan)
end


# we need the function that turns a new house into an old house 

function makeOld(haus::oldHouse,agt::Agent)
    global houseList
    hIndex=0
    for i in 1:length(houseList)
        if houseList[i]==haus
            hIndex=i
        end
    end
    currHaus=exitHouse(haus.quality,agt)
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
    currHaus=exitHouse(haus.quality,haus.owner)
    houseList[hIndex]=currHaus
    return haus
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
f
function hausQuality(haus::house)
    return haus.quality+rand(qualityError,1)[1]
end

function hausQuality(haus::hotel)
    return -Inf
end

# also, we need a function where an agent calculates its budget for a house

function budgetCalc(hotel)
    global interestRate
    homeBudget=mortgageCalc(agt.budget)
    return homeBudget
end

function budgetCalc(haus::house,saleValue)
    global interestRate
    # does the agent own a house?
    agtHaus=houseOwner(agt)
    if isnothing(agtHaus)
        homeBudget=mortgageCalc(agt.budget)
    else
        currLoan=agtLoan(agt)
        # how much equity does the agent have?
        equity=saleValue-currLoan.outstandingBalance
        homeBudget=equity+mortgageCalc(agt.budget)
    end
    return homeBudget
end