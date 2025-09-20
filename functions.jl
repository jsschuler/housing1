
# basic functions
function aSort(arr::Array)
    return sample(arr,length(arr),replace=false)
end


# basic object generation functions

function agtGen(env::environment)
    env.agtTicker=env.agtTicker+1
    outAgt=agent(env.agtTicker,floor(Int64,rand(env.paymentDistribution,1)[1]))
    #agtLog(env,outAgt)
    push!(env.agtList,outAgt)
    return outAgt
end


function houseGen(env::environment)
    houseCounter=length(env.allHouses)+1
    haus=newHouse(houseCounter,rand(env.qualityDistribution,1)[1],nothing,nothing)
    houseLog(env,haus)
    push!(env.allHouses,haus)
    return haus
end

function hotelGen(env::environment)
    hotelCounter=length(env.allHotels)+1
    hot=hotel(hotelCounter,0,agtGen(env))
    hotelGenLog(env,hot)
    push!(env.allHotels,hot)
    return hot
end



### LOAN FUNCTIONS ####


# the basic mortgage function assumes the agent borrowing as much as they can
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

# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::popHouse,amount::Int64)
    newLoan=loan(env.interestRate,amount,collat.owner.budget,amount,0,collat,false)
    push!(env.loanList,newLoan)
    return env
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


function budgetCalc(env::environment,hotel::hotel)
    homeBudget=maxMortgage(env,hotel)+hotel.budget
    return homeBudget
end

function budgetCalc(env::environment,haus::oldHouse)
    balance=outstandingLoan(env,haus)
    bestOffer=haus.bestOffer
    if isnothing(bestOffer)
        bestOffer=0
    end
    # what is the maximum mortgage the agent can take out?
    maxMort=maxMortgage(env,haus)
    return maxMort+bestOffer-balance
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

# graph searching functions


function pathGenBack(graph,vertex)
    node1=nothing
    node2=nothing
    haltCond=true
    while !haltCond
        haltCond=
            nbh=inneighbors(graph,vertex)[1]
            node1=node2
            node2=nbh
    end

end

function allPaths(saleGraph)
    # we need a dictionary with the vertex beginning the path as they key 
    pathDict=Dict{Int64,Array}()
    for vert in vertices(saleGraph)
        if length(inneighbors(saleGraph,vert))==0 && length(outneighbors(saleGraph,vert)) > 0
            pathDict[vert]=[]
        end
    end
    for vert in keys(pathDict)
        srcNode=vert
        while true 
            #println("SRC")
            #println(srcNode)
            destNode=outneighbors(saleGraph,srcNode)[1]
            push!(pathDict[vert],Edge(srcNode,destNode))
            if length(outneighbors(saleGraph,destNode))==0
                break
            else
                srcNode=destNode
            end
        end
    end
    return pathDict
end


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


# debug functions

function fIndex(dwell::dwelling)
    return dwell.index
end

# string hash function for keys 

function sHash(obj)
    return string(hash(obj),base=16)
end