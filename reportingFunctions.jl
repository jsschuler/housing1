# we need a function that logs environments
function envLog(env::environment)
    
end


function graphLog(env::environment,graph::SimpleDiGraph,label::String)
    srcIndex=[]
    dstIndex=[]
    
    for edge in edges(graph)
        push!(srcIndex,src(edge))
        push!(dstIndex,dst(edge))
    end
    CSV.write("../housingData/"*label*"_edges"*string(env.tick)*".csv",edgeDF,header=false)
end

# We need a function that logs housing construction

# and hotel generation

# and hotel deletion

# and loan generation

# and loan payments

# and loan payment in full

# and agents moving out of the market

# and within the market

# and agents leaving hotels





