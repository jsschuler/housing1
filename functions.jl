
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
    push!(agtList,agent(length(agtList),floor(Int64,rand(paymentDistribution,1)[1]),Int64[]))
end

#the function that generates a house

function houseGen()
    global houseList
    push!(houseList,house(rand(qualityDistribution,1)[1],nothing))
end

function hotelGen()
    global hotelList
    push!(hotelList,hotel(nothing))
end


# now we need the function that randomly assigns agents and houses 

function houseShuffle()
    global agtList
    global houseList
    for i in 1:length(agtList)
        houseList[i].owner=agtList[i]
    end
end

# now we need the function that sorts the agents into houses of quality corresponding to their budget

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

function qualityAssessment(haus::house)
    global qualityError
    return haus.quality + rand(qualityError,1)[1]
end
# we need a function that returns the quality of an agent's current house 
# if the agent has no house, it returns -inf 
function hausQuality(agt::agent)
    global houseList
    myHaus=filter(x -> x.owner==agt,houseList)
    if length(myHaus)==0
        return -Inf
    else
        return myHaus[1]
    end
end

# likewise, we need a function that turns an agent into its graph index and vice versa

function indexAgt(idx::Int64)
    return agtList[idx]
end

function agtIndex(agt::agent)
    return collect(1:length(agtList))[agtList.==agt][1]
end

# does an agent own a house?

function houseOwner(agt::agent)
    houseVec=filter(x-> x.owner==agt,houseList)
    if length(houseVec) > 0
        return houseVec[1]
    else
        return nothing
    end
end

function agtLoan(agt::agent)
    haus=houseOwner(agt)
    loanHeld=filter(x->x.collateral==haus)
    if length(loanHeld)==0
        return nothing
    else
        return loanHeld[2]
    end
end


# also, we need a function where an agent calculates its budget for a house

function budgetCalc(agt,saleValue)
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

# finally, we need some network functions 

function agtNeighbors(agt::agent)
    global transactionGraph
    agtNum=(1:length(agtList))[agtList.==agt][1]
    neighbors(transactionGraph,agtNum)

end