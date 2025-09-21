abstract type object end
# we need an abstract dwelling type to make the network work correctly 
abstract type dwelling <: object end
abstract type house <: dwelling end
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

# basic agent object 


struct agent <: object
    init::Int64
    budget::Int64
    loan::Union{loan,Nothing}
end



# basic house objects



# an empty home just has an id and a quality
mutable struct emptyHouse <: house
    index::Int64
    quality::Float64
end

# we need a sold empty house also, no owner but a sale price and a buyer
mutable struct soldEmptyHouse <: house
    index::Int64
    quality::Float64
    salePrice::Float64
    buyer::agent
end

# a currently occupied home has an owner also
mutable struct popHouse <: house
    index::Int64
    quality::Float64
    owner::agent
end
# a for sale house has the same parameters but the owner plans to stay in the market
mutable struct forSaleHouse <: house
    index::Int64
    quality::Float64
    owner::agent
end
# an exit house also has the same parameters but the owner plans to leave the market
mutable struct exitHouse <: house
    index::Int64
    quality::Float64
    owner::agent
end

# now, need two sold house types
# a sold house has an owner and a buyer and a sale price. The owner will occupy a hotel for the next round
mutable struct soldHouse <: house
    index::Int64
    quality::Float64
    owner::agent
    salePrice::Float64
    buyer::agent
end
# a sold exit house has the same parameters but the owner will leave the market
mutable struct soldExitHouse <: house
    index::Int64
    quality::Float64
    owner::agent
    salePrice::Float64
    buyer::agent
end 


# we need a temporary "dwelling" for agents looking to buy
# the hotel budget is the additional budget the agent has from a previous sale if any.
# the budget is either the house to be sold, or the sale price, or zero
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







##### ENVIRONMENT STRUCT #######

mutable struct environment
    key::Union{Nothing,String} # 1
    # global parameters
    # distribution of house qualities 
    qualityDistribution::Union{Nothing,Distribution} # 2
    paymentDistribution::Union{Nothing,Distribution} # 3
    qualityError::Union{Nothing,Distribution} #4
    # initial agent count
    agtCnt::Union{Nothing,Int64} # 5
    # population inflow (agents who can buy without selling)
    inFlow::Union{Nothing,Int64} # 6
    # population outflow (agents who can sell without buying)
    outFlow::Union{Nothing,Int64} # 7
    # new housing construction 
    construction::Union{Nothing,Int64} # 8
    # how many agents simply want to move within the market?
    inPlace::Union{Nothing,Int64}   # 9
    interestRate::Union{Nothing,Float64}    # 10
    allTicks::Union{Nothing,Int64} # 11
    tick::Union{Nothing,Int64}  # 12 
    agtList::Union{Nothing,Array{agent}} # 13
    allHouses::Union{Nothing,Array{house}} # 14
    allHotels::Union{Nothing,Array{hotel}} # 15
    popHouses::Union{Nothing,Array{popHouse}} # 16
    forSaleHouses::Union{Nothing,Array{forSaleHouse}} # 17
    exitHouses::Union{Nothing,Array{exitHouse}} # 18
    soldHouses::Union{Nothing,Array{soldHouse}} # 19
    soldExitHouses::Union{Nothing,Array{soldExitHouse}} # 20
    emptyHouses::Union{Nothing,Array{emptyHouse}} # 21
    soldEmptyHouses::Union{Nothing,Array{soldEmptyHouse}} # 22
    loanList::Union{Nothing,Array{loan}} # 23
    transactionGraph::Union{Nothing,SimpleDiGraph} # 24
    nodeDict::Union{Nothing,Dict{dwelling,Int64}} # 25
    intDict::Union{Nothing,Dict{Int64,dwelling}} # 26
    # agent Ticker
    agtTicker::Union{Nothing,Int64} # 27
    # hotel ticker
    hotelTicker::Union{Nothing,Int64} # 28
end

