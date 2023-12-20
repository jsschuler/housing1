#########################################################################################################################
#                                                                                                                       #
#                  Housing Model                                                                                        #
#                  September 2023                                                                                       #
#                  John S. Schuler                                                                                      #
#                                                                                                                       #
#########################################################################################################################

# load libraries
using Graphs
using Distributions
using StatsBase
using DataFrames
# we have a few global parameters 
# the interest rate (mutable)
interestRate::Float64=.04
# distribution of agent budgets
paymentDistribution::Truncated{Levy{Float64}, Continuous, Float64, Float64, Float64}=Truncated(Levy(500,100),0,5*10^9)
# distribution of house qualities 
qualityDistribution::Truncated{Levy{Float64}, Continuous, Float64, Float64, Float64}=Truncated(Levy(0,10),0,63658)
# initial agent count
agtCnt::Int64=5000
# population inflow (agents who can buy without selling)
inFlow::Int64=200
# population outflow (agents who can sell without buying)
outFlow::Int64=100
# new housing construction 
construction::Int64=100
# how many agents simply want to move within the market?
inPlace::Int64=100
# what 
# how many ticks to run the model ?
ticks=100

include("objects.jl")
include("functions.jl")

# now, we include the code that finds the global cauchy parameter for noise in agent
# quality perception
include("distributionControl.jl")

# we need some global dictionaries to associate the objects 

agtLoans::Dict{agt,Union{loan,Nothing}}=Dict{agt,Union{loan,Nothing}}()
agtDwellings::Dict{agt,Union{dwelling,Nothing}}=Dict{agt,Union{dwelling,Nothing}}()
# loan objects have associated collateral and collateral has an owner so not dictionary is needed in these directions
# we do need a dictionary that associates a dwelling with a loan 

# and a dictionary that associates a dwelling with a loan. Every dwelling needs an entry but it need not have a loan
dwellingLoan::Dict{dwelling,Union{loan,Nothing}}=Dict{dwelling,Union{loan,Nothing}}()

# we need a dictionary that associates a graph node with an agent 
graphAgt::Dict{Int64,agent}=Dict{Int64,agent}()
# and vice versa 
agtGraph::Dict{agent,Union{Int64,Nothing}}=Dict{agent,Union{Int64,Nothing}}()


# in the initial set up, we generate a bunch of houses and a bunch of agents and 
# assign agents to houses at random. 
houseList=house[]
hotelList=hotel[]
agtList=agent[]
loanList=loan[]
for i in 1:agtCnt
    agtGen()
end

# generate place holder graph so it is global
transactionGraph=SimpleDiGraph(0)

for i in 1:agtCnt
    houseGen()
end

houseShuffle()
# then agents can outbid other agents for houses they like better. 
# this process continues until it stabilizes 
initialSwapping()

# now generate the loans for each agent
for house in houseList
    loanGen(house.owner.budget,house)
end

# then, we randomly age the agents a Uniform number of years so they can pay down their loan balances 
payOffs=rand(DiscreteUniform(12*50),length(loanList))
for i in eachindex(payOffs)
    currLoan=loanList[i]
    for j in 1:payOffs[i]
        payLoan(currLoan)
    end 
end

# are any loans paid off?
loanBool=Bool[]
loanBalance=Int64[]
for ln in loanList
    push!(loanBool,ln.paidInFull)
    push!(loanBalance,ln.outstandingBalance)
end

# now, the trading algorithm

onMarket::Array{house}=house[]
for t in 1:ticks
    # randomly generate houses to go on market
    # which houses are currently off Market?
    offMarket=setdiff(houseList,onMarket)
    # take a (possibly empty) random sample
    for haus in sample(offMarket,min(outFlow,length(offMarket)))
        push!(onMarket,makeExit(haus))
    end

    for haus in sample(offMarket,min(inPlace,length(offMarket)))
        push!(onMarket,haus)
    end
    # now generate new houses 
    for i in 1:construction
        push!(onMarket,houseGen())
    end
    # generate hotels, which in turn generate agents 
    for i in 1:inFlow
        push!(hotelList,hotelGen())
    end

    # since every hotel dweller bids on every on-market home, we can record each bid 
    bidList=Int64[]
    for hot in hotelList
        push!(bidList,budgetCalc(hot.owner.budget))
    end
    hotelBidFrame=DataFrame(dwelling=hotelList,bid=bidList)
    # sort this by descending offer
    sort!(hotelBidFrame,:bid,rev=true)

    for haus in onMarket
        haus.bidOrdering=hotelBidFrame
    end

    # now, beginning with hotels, the agents within them select their preferred houses (all on Market houses for all hotel agents)
    for hot in hotelList
        preferenceFrame=DataFrame(houses=onMarket)
        preferenceFrame.preference=hausQuality.(onMarket)
        sort!(preferenceFrame,:preference,rev=true)
        hot.preferenceOrdering=preferenceFrame
    end

    for hot in hotelList
        for hau
    # find the house, agent pair where each ranks the other first
    # for that house, save the second highest bidder's bid 
    # remove the agent's other bids
    # remove other's bids for the house
    # halt when every house has no more than one arrow pointing in

    # now, for those houses with an arrow pointing in, 
        # if they are exit houses, do nothing
        # if they are old houses, these houses determine their orders of preference 
        # we go through the same process
        # halt when every house has no more than one arrow pointing in 
    
    # now, this entire process halts when every old house and hotel has no more than one arrow pointing out



end