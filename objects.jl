

# basic agent object 

struct agent
    init::Int64
    budget::Int64
    
end

# basic house object 

mutable struct house
    quality::Float64
    owner::Union{agent,Nothing}
end




# an object to buy

abstract type transaction end


struct buy <: transaction
    conditional::Union{transaction,Nothing}
    target::house
    price::Int64
end

struct sell <: transaction
    conditional::Union{transaction,Nothing}
    target::house
    price::Int64
end

# basic loan object 
mutable struct loan
    interestRate::Float64
    initialBalance::Int64
    monthlyPayment::Int64
    outstandingBalance::Int64
    paymentsMade::Int64
    collateral::house
    paidInFull::Bool
end
