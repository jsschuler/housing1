## LOAN FUNCTIONS ####


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


#mutable struct loan
#    interestRate::Float64
#    initialBalance::Float64
#    monthlyPayment::Float64
#    outstandingBalance::Float64
#    paymentsMade::Int64
#    collateral::house
#    paidInFull::Bool
#end


# the function generating initial loans takes the owner as the borrower
function loanGen(env::environment,collat::popHouse,amount::Float64)
    newLoan=loan(env.loanTicker+1,env.interestRate,amount,collat.owner.budget,amount,0,collat,false)
    env.loanTicker += 1
    loanLog(env,newLoan)
    push!(env.loanList,newLoan)
    return env
end
# the ones in transactions take the buyer
# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::soldExitHouse,amount::Float64)
    # how much did the house sell for?
    salePrice=collat.salePrice
    # how much money does the buyer have from the prior transaction?
    buyerHotel=env.allHotels[findfirst(hot -> hot.owner==collat.buyer,env.allHotels)]
    #println("Debug")
    #println(buyerHotel)
    # now, how much does the agent have to finance?
    neededLoan=max(0,salePrice-buyerHotel.budget)
    if neededLoan > 0
        newLoan=loan(env.interestRate,neededLoan,collat.buyer.budget,neededLoan,0,collat,false)
        collat.buyer.loan=newLoan
    
        loanLog(env,newLoan)
        push!(env.loanList,newLoan)
    end 
    return env
end

# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::soldEmptyHouse,amount::Float64)
    
    # how much did the house sell for?
    salePrice=collat.salePrice
    # how much money does the buyer have from the prior transaction?
    buyerHotel=env.allHotels[findfirst(hot -> hot.owner==collat.buyer,env.allHotels)]
    # now, how much does the agent have to finance?
    neededLoan=max(0,salePrice-buyerHotel.budget)
    if neededLoan > 0
        newLoan=loan(env.loanTicker +1 ,env.interestRate,neededLoan,collat.buyer.budget,neededLoan,0,collat,false)
        collat.buyer.loan=newLoan
        env.loanTicker += 1
        loanLog(env,newLoan)
        push!(env.loanList,newLoan)
    end 
    return env
end

# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::soldHouse,amount::Float64)
    
    # how much did the house sell for?
    salePrice=collat.salePrice
    # how much money does the buyer have from the prior transaction?
    buyerHotel=env.allHotels[findfirst(hot -> hot.owner==collat.buyer,env.allHotels)]
    # now, how much does the agent have to finance?
    neededLoan=max(0,salePrice-buyerHotel.budget)
    if neededLoan > 0
        newLoan=loan(env.loanTicker+1,env.interestRate,neededLoan,collat.buyer.budget,neededLoan,0,collat,false)
        collat.buyer.loan=newLoan
        env.loanTicker += 1
        loanLog(env,newLoan)
        push!(env.loanList,newLoan)
    end 
    return env
end


##### LOAN PAYING FUNCTIONS #####
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
end

# now we need a function that assesses interest
function assessInterest(loan)
    loan.outstandingBalance=loan.outstandingBalance*(1+loan.interestRate/12)
end