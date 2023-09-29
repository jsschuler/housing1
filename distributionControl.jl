# the goal is to have two distributions 
# a levy distribution of quality 
# and a cauchy distribution 

# the main parameter is the quantile distance Δ
# that is, when we randomly chose a quantile Q from the Levy distribution,
# we flip a coin and chose Q-Δ or Q+Δ. 
# then, we tune the parameter of the cauchy distibution to flip this order with 
# probability π
qualityDistribution::Levy=Levy(0,10)
U=Uniform()
π=0.05
Δ=0.05

function switchProb(cauchyParameter)
    global Δ
    global qualityDistribution
    U=Uniform(0,1-Δ)
    X1=rand(U,100000)
    X2=X1 .+ Δ
    function F(x)
        return quantile(qualityDistribution,x)
    end

    Y1=F.(X1)
    Y2=F.(X2)
    cauchy=Cauchy(0,cauchyParameter)
    Z1=Y1.+rand(cauchy,100000)
    Z2=Y2.+rand(cauchy,100000)

    return mean(Z1 .> Z2)
end




