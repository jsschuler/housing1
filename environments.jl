# This code provides functions that controls the environment. 
# This way, the main code can run different versions in parallel



function environGen(qualityDistribution::Distribution,
                    paymentDistribution::Distribution,
                    agtCnt::Int64,
                    inFlow::Int64,
                    outFlow::Int64,
                    construction::Int64,
                    inPlace::Int64,
                    interestRate::Float64,
                    allTicks::Int64
)

    return environment(qualityDistribution,
                       paymentDistribution,
                       agtCnt,
                       inFlow,
                       outFlow,
                       construction,
                       inPlace,
                       interestRate,
                       allTicks,
                       0,
                       agent[],
                       house[],
                       hotel[],
                       loan[],
                       SimpleDiGraph(0),
                       Dict{dwelling,Int64}(),
                       Dict{Int64,dwelling}(),
                       Dict{Int64,Int64}())

end

# the initialize function generates houses and agents
# randomly assigns them
# then allows agents to trade so that house quality is correlated with agent budget
# finally, randomly age mortgages


function initialize(env::environment)
    for i in 1:env.agtCnt
        houseGen(env)
        agtGen(env)
    end
    houseRand=aSort(env.allHouses)
    agtRand=aSort(env.agtList)
    for i in 1:length(houseRand)
        moveIn(env,houseRand[i],agtRand[i])
    end
    # now sort agents

    initialSwapping(env)

    # now generate the loans for each agent
    for house in env.allHouses
        loanGen(env,house)
    end
    
    # then, we randomly age the agents a Uniform number of years so they can pay down their loan balances 
    payOffs=rand(DiscreteUniform(12*50),length(env.loanList))
    for i in eachindex(payOffs)
        currLoan=env.loanList[i]
        for j in 1:payOffs[i]
            payLoan(env,currLoan)
        end 
    end

    return env
end