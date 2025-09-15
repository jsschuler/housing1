
# basic functions
function aSort(arr::Array)
    return sample(arr,length(arr),replace=false)
end

# basic object generation functions

function agtGen(env::environment)
    env.agtTicker=env.agtTicker+1
    outAgt=agent(env.agtTicker,floor(Int64,rand(env.paymentDistribution,1)[1]))
    agtLog(env,outAgt)
    push!(env.agtList,outAgt)
    return outAgt
end


function houseGen(env::environment)
    houseCounter=length(env.allHouses)+1
    haus=emptyHouse(houseCounter,rand(env.qualityDistribution,1)[1],nothing,nothing)
    houseLog(env,haus)
    push!(env.allHouses,haus)
    return haus
end

function hotelGen(env::environment)
    hotelCounter=length(env.allHotels)+1
    hot=hotel(hotelCounter,-Inf,agtGen(env),nothing)
    hotelGenLog(env,hot)
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

function maxMortgage(env::environment,haus::hotel)
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
function loanGen(env::environment,collat::popHouse)
    initialBalance=maxMortgage(env,collat)
    newLoan=loan(env.interestRate,initialBalance,collat.owner.budget,initialBalance,0,collat,false)
    loanLog(env,newLoan)
    push!(env.loanList,newLoan)
    return env
end

# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::popHouse,amount::Int64)
    newLoan=loan(env.interestRate,amount,collat.owner.budget,amount,0,collat,false)
    push!(env.loanList,newLoan)
    return env
end

# now we need the house conversion functions

# populating the house does not assume we have populated dictionaries yet but otherwise, works like moveIn
function populate(env::environment,haus::emptyHouse,agt::agent)
    hIndex=0
    for i in 1:length(env.allHouses)
        if env.allHouses[i]==haus
            hIndex=i
        end
    end
    currHaus=popHouse(haus.index,haus.quality,agt,agt)
    env.allHouses[hIndex]=currHaus
    return env
end



# a function to list for agents who wish to exit
function makeEmpty(haus::popHouse)
        hIndex=0
    for i in 1:length(env.allHouses)
        if env.allHouses[i]==haus
            hIndex=i
        end
    end
    currHaus=emptyHouse(haus.index,haus.quality)
    env.allHouses[hIndex]=currHaus
    return env
end




# initialization functions
# now we need the function that randomly assigns agents and houses 

function housingSwap(house1::popHouse,house2::popHouse)
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



## Graph manipulation functions
# we need a function returning all hotels that point into a 
# empty house in the most preferred graph
function inNeighbors(env::environment,dwell::emptyHouse)
    global agtDict
    global nodeDict

    nbhs=inneighbors(envtransactionGraph,env.nodeDict[dwell])
    structNbh=[]
    for nb in nbhs
        push!(structNbh,intDict[nb])
    end
    return structNbh
end

# similarly, we need a function returning the most preferred option for each hotel

function outNeighbors(dwell::hotel)
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


function outstandingLoan(env::environment,haus::popHouse)
    loanHeld=filter(x->x.collateral==haus,env.loanList)
    if length(loanHeld)==0
        return 0
    else
        return loanHeld[1].outstandingBalance
    end
end


function netMortgage(env::environment,hot::hotel)
    homeBudget=maxMortgage(env,hot)+hot.budget
    return homeBudget
end

function netMortgage(env::environment,haus::popHouse)
    balance=outstandingLoan(env,haus)
    bestOffer=haus.bestOffer
    # what is the maximum mortgage the agent can take out?
    maxMort=maxMortgage(env,haus)
    return maxMort-balance
end

# a loan payment function

# we need a function to pay loans in full
function payFull(env::environment,haus::house)
    loanHeld=filter(x->x.collateral==haus,env.loanList)
    if length(loanHeld) > 0
        filter!(x-> x!=loanHeld[1],env.loanList)
    end
    return env
end
# debug functions

function fIndex(dwell::dwelling)
    return dwell.index
end

# string hash function for keys 

function sHash(obj)
    return string(hash(obj),base=16)
end