#########################################################################################################################
#                                                                                                                       #
#                  Housing Model                                                                                        #
#                  September 2023                                                                                       #
#                  John S. Schuler                                                                                      #
#                                                                                                                       #
#########################################################################################################################

# load libraries
using LightGraphs
using Distributions
using StatsBase
# we have a few global parameters 
# the interest rate (mutable)
interestRate::Float64=0.04
# distribution of agent budgets
paymentDistribution::Levy=Levy(500,100)
# distribution of house qualities 
qualityDistribution::Levy=Levy(0,10)
# initial agent count
agtCnt::Int64=5000
# population inflow (agents who can buy without selling)
inFlow::Int64=100
# population outflow (agents who can sell without buying)
outFlow::Int64=100
# new housing construction 
construction::Int64=100


include("objects.jl")
include("functions.jl")
# in the initial set up, we generate a bunch of houses and a bunch of agents and 
# assign agents to houses at random. 
houseList=house[]
agtList=agent[]
loanList=loan[]
for i in 1:agtCnt
    agtGen()
end

for i in 1:agtCnt
    houseGen()
end

# then agents can outbid other agents for houses they like better. 
# this process continues until it stabilizes 
initialSwapping()
# now generate the loans for each agent
for house in houseList


# then, we randomly age the agents a Poisson number of years so they can pay down their loan balances 
payOffs=rand(DiscreteUniform(12*30),length(agtList))
for i in 1:length(agtList)
    currAgt=agtList[i]
end