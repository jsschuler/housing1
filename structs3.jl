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
    index::Int64
    quality::Float64
    owner::Nothing
    bestOffer::Union{Nothing,Int64}

end

mutable struct exitHouse <: house
    index::Int64
    quality::Float64
    owner::agent
    bestOffer::Union{Nothing,Int64}
    budget::Union{Nothing,Int64}
end

mutable struct oldHouse <: house
    index::Int64
    quality::Float64
    owner::agent
    bestOffer::Union{Nothing,Int64}
    
end


# we need a temporary "dwelling" new agents 

mutable struct hotel <: dwelling
    index::Int64
    owner::agent
    preferenceOrdering::Union{Nothing,DataFrame}
end

# define hash and equality operators for dwellings so we can use them as dictionary keys

Base.hash(m::dwelling, h::UInt) = hash(m.index, hash(m.index, h))

Base.:(==)(m1::dwelling, m2::dwelling) = m1.index == m2.index



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