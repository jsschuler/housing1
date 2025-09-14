abstract type object end

# basic agent object 


struct agent <: object
    init::Int64
    budget::Int64
end

# we need an abstract dwelling type to make the network work correctly 
abstract type dwelling <: object end

# basic house objects

abstract type house <: dwelling end

mutable struct emptyHouse <: house
    index::Int64
    quality::Float64
end

mutable struct popHouse <: house
    index::Int64
    quality::Float64
    owner::agent
end



# we need a temporary "dwelling" for agents looking to buy
# the hotel budget is the additional budget the agent has from a previous sale if any.
mutable struct hotel <: dwelling
    index::Int64
    budget::Float64
    owner::agent
end

# define hash and equality operators for dwellings so we can use them as dictionary keys

#Base.hash(m::dwelling, h::UInt) = hash(m.index, hash(m.index, h))
Base.hash(m::hotel) = hash(-m.index)
Base.hash(m::house) = hash(m.index)
Base.:(==)(m1::dwelling, m2::dwelling) = ((m1.index == m2.index) & (m1.quality==m2.quality))



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



##### ENVIRONMENT STRUCT #######

mutable struct environment
    key::String
    # global parameters
    # distribution of house qualities 
    qualityDistribution::Distribution
    paymentDistribution::Distribution
    # initial agent count
    agtCnt::Int64
    # population inflow (agents who can buy without selling)
    inFlow::Int64
    # population outflow (agents who can sell without buying)
    outFlow::Int64
    # new housing construction 
    construction::Int64
    # how many agents simply want to move within the market?
    inPlace::Int64
    interestRate::Float64
    allTicks::Int64
    tick::Int64
    agtList::Array{agent}
    allHouses::Array{house}
    allHotels::Array{hotel}
    loanList::Array{loan}
    transactionGraph::SimpleDiGraph
    nodeDict::Dict{dwelling,Int64}
    intDict::Dict{Int64,dwelling}
    bidDict::Dict{Int64,Int64}
    qualDict::Dict{Graphs.SimpleGraphs.SimpleEdge{Int64},Float64}
    mortgageFlag::Bool
    # agent Ticker
    agtTicker::Int64
    qualBound::Float64
end
# 23
