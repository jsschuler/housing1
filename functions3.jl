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
    global agtLoans
    global agtDwellings
    global agtGraph
    push!(agtList,agent(length(agtList),floor(Int64,rand(paymentDistribution,1)[1]),Int64[]))
end

#the function that generates a house

function houseGen()
    global houseList
    global dwellingList
    haus=house(rand(qualityDistribution,1)[1],nothing)
    push!(houseList,haus)
    push!(dwellingList,haus)
end

function hotelGen()
    global hotelList
    global dwellingList
    hot=hotel(nothing)
    push!(hotelList,hot)
    push!(dwellingList,hot)
end

# we need a function that generates the network

function networkGen()
    global transactionGraph
    global dwellingList
    # generate graph
    transactionGraph=SimpleDiGraph(length(dwellingList))

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