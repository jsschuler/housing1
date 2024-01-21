# basic functions
function aSort(arr::Array)
    return sample(arr,length(arr),replace=false)
end

# basic object generation functions

function agtGen(env::environment)
    outAgt=agent(length(env.agtList),floor(Int64,rand(env.paymentDistribution,1)[1]))
    push!(env.agtList,outAgt)
    return outAgt
end


function houseGen(env::environment)
    houseCounter=length(env.allHouses)+1
    
    haus=newHouse(houseCounter,rand(env.qualityDistribution,1)[1],nothing,nothing)
    push!(env.allHouses,haus)
    return haus
end

function hotelGen(env::environment)
    hotelCounter=length(env.allHotels)+1
    hot=hotel(hotelCounter,-Inf,agtGen(env),nothing)
    push!(env.allHotels,hot)
    return hot
end

### LOAN FUNCTIONS ####

function maxMortgage(env::environment,haus::oldHouse)
    monthlyRate::Float64=env.interestRate/12 
    # apply interest rate calculation
    payment=haus.owner.budget
    return floor(Int64,payment*(((1+monthlyRate)^(12*30)) -1)/(monthlyRate*(1+monthlyRate)^(12*30)))+1
end

# we need a function that calculates the monthly payment

function mortgageCosts(env::environment,borrowed::Int64)
    r=env.interestRate/12
    return floor(Int64,r*borrowed/(1-(1+r)^-(30*12)))
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


# the function generating a loan from just a house assumes agents are borrowing as much as they can
function loanGen(env::environment,collat::oldHouse)
    initialBalance=maxMortgage(env,collat)
    push!(env.loanList,loan(env.interestRate,initialBalance,collat.owner.budget,initialBalance,0,collat,false))
end

# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::oldHouse,amount::Int64)
    push!(env.loanList,loan(env.interestRate,initialBalance,collat.owner.budget,initialBalance,0,collat,false))
end

# now we need the house conversion functions

# moving into a new house or an exit house converts it to an old house

function moveIn(env::environment,haus::newHouse,agt::agent)
    hIndex=0
    for i in 1:length(env.allHouses)
        if env.allHouses[i]==haus
            hIndex=i
        end
    end
    currHaus=oldHouse(haus.index,haus.quality,agt,nothing)
    env.allHouses[hIndex]=currHaus
    return haus
end

function moveIn(env::environment,haus::exitHouse,agt::agent)
    hIndex=0
    for i in 1:length(env.allHouses)
        if env.allHouses[i]==haus
            hIndex=i
        end
    end
    currHaus=oldHouse(haus.index,haus.quality,agt,nothing)
    env.allHouses[hIndex]=currHaus
    return haus
end

function moveIn(env::environment,haus::oldHouse,agt::agent)
    hIndex=0
    for i in 1:length(env.allHouses)
        if env.allHouses[i]==haus
            hIndex=i
        end
    end
    currHaus.owner=agt
    return haus
end

# a function to list for agents who wish to exit

function exitList(env::environment,haus::oldHouse)
    for i in 1:length(env.allHouses)
        idx=0
        if env.allHouses==haus
            idx=i
        end
    end
    currHaus=env.allHouses[idx]
    exitHome=exitHouse(currHaus.index,currHaus.quality,currHaus.owner,currHaus.bestOffer)
    env.allHouses[idx]=exitHome
    return exitHome
end


# initialization functions
# now we need the function that randomly assigns agents and houses 

function housingSwap(house1::dwelling,house2::dwelling)
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

function initialSwapping(env::environment)
    tick::Int64=0
    while true
        # select two random houses 
        twoHouses=sample(env.allHouses,2,replace=false)
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

##### LOAN PAYING FUNCTIONS #####
# the function that pays down a loan
function payLoan(env::environment,obj::loan)
    
    if !obj.paidInFull 
        obj.paymentsMade=obj.paymentsMade+1
        obj.outstandingBalance=floor(Int64,outstandingBalance(obj,obj.paymentsMade))
    end

    if obj.paymentsMade==30*12
        obj.paidInFull=true
        obj.outstandingBalance=0
    end
end


# house quality functions

function hausQuality(haus::house)
    return haus.quality+rand(qualityError,1)[1]
end

function hausQuality(haus::hotel)
    return -Inf
end

## Graph manipulation functions
function inNeighbors(env::environment,dwell::dwelling)
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

#### some budget functions #####

function outstandingLoan(env::environment,haus::newHouse)
    return 0
end

function outstandingLoan(env::environment,haus::oldHouse)
    loanHeld=filter(x->x.collateral==haus,env.loanList)
    if length(loanHeld)==0
        return 0
    else
        return loanHeld[1].outstandingBalance
    end
end

function outstandingLoan(env::environment,haus::exitHouse)
    loanHeld=filter(x->x.collateral==haus,env.loanList)
    if length(loanHeld)==0
        return 0
    else
        return loanHeld[1].outstandingBalance
    end
end



function budgetCalc(env::environment,hotel::hotel)
    homeBudget=maxMortgage(env,hotel.owner.budget)
    return mortgageCalc(homeBudget)
end

function budgetCalc(env::environment,haus::oldHouse)
    balance=outstandingLoan(haus)
    bestOffer=haus.bestOffer
    # what is the maximum mortgage the agent can take out?
    maxMort=mortgageCalc(env,haus.owner.budget)
    return maxMort+bestOffer-balance
end

# a loan payment function

# we need a function to pay loans in full
function payFull(env::environment,haus::house)
    loanHeld=filter(env.loanList,x->x.collateral==haus2)
    if length(loanHeld) > 0
        filter!(x-> x!=loanHeld[1],env.loanList)
    end
end

# graph searching functions

# we need the final step processing functions
# implemented as an iteration

function cleanUp(arg::Nothing,graph::SimpleDiGraph)
    global nodeDict
    global loanList
    noInNbh=[]
    for vert in vertices(graph)
        if length(inneighbors(vert))==0
            push!(noInNbh,vert)
        end
    end
    return noInNbh
end

function cleanUp(arg::Array{Int64},graph::SimpleDiGraph)
    global nodeDict
    global loanList
    outNbhs=[]
    for vert in vertices(graph)
        for nbh in outNeighbors(vert)
            push!(outNbhs,nbh)
        end
    end
    return outNbhs
end