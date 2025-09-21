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

# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::popHouse,amount::Float64)
    newLoan=loan(env.interestRate,amount,collat.owner.budget,amount,0,collat,false)
    push!(env.loanList,newLoan)
    return env
end

# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::soldExitHouse,amount::Float64)
    newLoan=loan(env.interestRate,amount,collat.owner.budget,amount,0,collat,false)
    push!(env.loanList,newLoan)
    return env
end

# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::soldEmptyHouse,amount::Float64)
    newLoan=loan(env.interestRate,amount,collat.owner.budget,amount,0,collat,false)
    push!(env.loanList,newLoan)
    return env
end

# the function generating a loan with a given quantity works differently
function loanGen(env::environment,collat::soldHouse,amount::Float64)
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