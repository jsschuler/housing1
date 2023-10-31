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
inFlow::Int64=100
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
dwellingList=dwelling[]
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


