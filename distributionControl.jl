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

function 