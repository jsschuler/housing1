# we need a function to test the correlation between the budget of an agent and the quality of their house
# best to do this using quantiles
function testCorrelation(env::environment)
    budgets=Float64[]
    qualities=Float64[]
    for haus in env.popHouses
        push!(budgets,cdf(env.paymentDistribution,haus.owner.budget))
        push!(qualities,cdf(env.qualityDistribution,haus.quality))
    end
    return cor(budgets,qualities)
end

