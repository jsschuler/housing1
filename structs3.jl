abstract type object end

# basic agent object 

struct agent <: object
    init::Int64
    budget::Int64
end

# we need an abstract dwelling type to make the network work correctly 
abstract type dwelling <: object end

# basic house objects

abstract type house <: dwelling 

end

mutable struct newHouse <: house
    quality::Float64
    owner::Nothing
    preferenceOrdering::Union(Nothing,Array{house})
    bidOrdering::Union(Nothing,DataFrame)
end

mutable struct exitHouse <: house
    quality::Float64
    owner::agent
    preferenceOrdering::Union(Nothing,Array{house})
    bidOrdering::Union(Nothing,DataFrame)
end

mutable struct oldHouse <: house
    quality::Float64
    owner::agent
    preferenceOrdering::Union(Nothing,Array{house})
    bidOrdering::Union(Nothing,DataFrame)
end


# we need a temporary "dwelling" new agents 

mutable struct hotel <: dwelling
    owner::agent
    preferenceOrdering::Union(Nothing,DataFrame)
end

# and a loan object

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


# now, the network can be thought of as linking agents, or dwellings or even loans.
# we can write functions that give neighbors of one type given an argument in another 