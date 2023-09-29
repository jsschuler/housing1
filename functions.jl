
function mortgageCalc(payment::Int64)
    global interestRate
    monthlyRate::Float64=interestRate/12.0 
    return payment*(((1+monthlyRate)^30) -1)/(monthlyRate*(1+monthlyRate)^30)
end

function principalPayment(obj::loan)
    return floor(Int64,loan.monthlyPayment-(loan.interestRate*loan.outstandingBalance))+1
end
# the function that pays down a loan
function payLoan(obj::loan)
    if !loan.paidInFull 
        loan.paymentsMade=paymentsMade+1
        loan.outstandingBalance=max(loan.outstandingBalance-principalPayment(loan),0)
    end

    if loan.outStandingBalance==0
        loan.paidInFull=true
    end
    return loan.paidInFull
end

# the function that generates an agent

function agtGen()
    global agtList
    global paymentDistribution
    push!(agtList,agent(floor(Int64,rand(paymentDistribution,1)[1])))
end

#the function that generates a house

function houseGen()
    global houseList
    push!(houseList,house(rand(qualityDistribution,1)[1],nothing))
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
    println("Debug")
    #println(house1.quality)
    #println(house2.quality)
    #println(house1.owner.budget)
    #println(house2.owner.budget)
    println((house1.quality > house2.quality) & (house1.owner.budget < house2.owner.budget))
    println((house2.quality > house1.quality) & (house2.owner.budget < house1.owner.budget))

    if (house1.quality > house2.quality) & (house1.owner.budget < house2.owner.budget)
        println("swapped")
        richOwner=house2.owner
        house2.owner=house1.owner
        house1.owner=richOwner
        swap=true
    elseif (house2.quality > house1.quality) & (house2.owner.budget < house1.owner.budget)
        println("swapped")
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
        println(tick)
        if housingSwap(twoHouses[1],twoHouses[2])
            tick=0
        end
        if tick==1000
            break
        end
    end
end

function loanGen()
    global interestRate
    #interestRate::Float64
    initialBalance::Int64
    monthlyPayment::Int64
    outstandingBalance::Int64
    paymentsMade::Int64
    collateral::house
    paidInFull::Bool
end