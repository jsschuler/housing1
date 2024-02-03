function graphLog(env::environment,graph::SimpleDiGraph,label::String)
    # this function dumps a sparse adjacency matrix
    A=adjacency_matrix(graph)
    rows, cols, vals = findnz(A)
    # get dwelling quality

    edgeDF = DataFrame(row=rows, col=cols)
    nodeDF=DataFrame(edges=1:length(vertices(graph)))
    #CSV.write("../housingData/"*label*"_nodes.csv",nodeDF)
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





