# basic agent object 

struct agent
    init::Int64
    budget::Int64
    
    
end


# we need an abstract dwelling type to make the network work correctly 
abstract type dwelling end

# basic house objects

abstract type house <: dwelling end

mutable struct newHouse <: house
    quality::Float64
    owner::Nothing
end

mutable struct exitHouse <: house
    quality::Float64
    owner::agent
end

mutable struct oldHouse <: house
    quality::Float64
    owner::agent
end


# we need a temporary "dwelling" new agents 

mutable struct hotel <: dwelling
    owner::Union{agent,Nothing}
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
