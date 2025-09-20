# this code contains all of the required functions to convert between different house types
# while the model is running

function forSaleToSold!(env::environment,haus::forSaleHouse,buyer::agent,salePrice::Float64)
    # first we need to remove the house from the for sale list
    deleteat!(env.forSaleHouses,findfirst(x->x==haus,env.forSaleHouses))
    # then we need to create a new sold house object
    soldHaus=soldHouse(haus.id,haus.quality,haus.owner,salePrice,buyer)
    # then we need to add the new sold house to the sold house list
    push!(env.soldHouses,soldHaus)
    # finally we need to return the new sold house object
    return soldHaus
end

function exitToSoldExit!(env::environment,haus::exitHouse,buyer::agent,salePrice::Float64)
    # first we need to remove the house from the exit list
    deleteat!(env.exitHouses,findfirst(x->x==haus,env.exitHouses))
    # then we need to create a new sold exit house object
    soldHaus=soldExitHouse(haus.id,haus.quality,haus.owner,salePrice,buyer)
    # then we need to add the new sold exit house to the sold exit house list
    push!(env.soldExitHouses,soldHaus)
    # finally we need to return the new sold exit house object
    return soldHaus
end

# now a function that converts a sold house to a populated house
# the sale price is only for records
function soldToPop!(env::environment,haus::soldHouse)
    # first, find the index of the house in the environment
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=popHouse(haus.index,haus.quality,haus.buyer)
    # finally, add the owner to the list of agents in hotels
    push!(env.hotelList,hotelGen(env,haus.owner,salePrice))
    # remove the sold house from the sold house list
    deleteat!(env.soldHouses,findfirst(x->x==haus,env.soldHouses))
end
# now a function that converts a sold exit house to a populated house
# the sale price is only for records
function soldExitToPop!(env::environment,haus::soldExitHouse)
    # first, find the index of the house in the environment
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=popHouse(haus.index,haus.quality,haus.buyer)
    # finally, do not add the owner to the list of agents in hotels
    # remove the sold exit house from the sold exit house list
    deleteat!(env.soldExitHouses,findfirst(x->x==haus,env.soldExitHouses))
end 

# now a function to convert a populated house to a for sale house
function popToForSale!(env::environment,haus::popHouse)
    # first, remove the house from the populated house list
    deleteat!(env.popHouses,findfirst(x->x==haus,env.popHouses))
    # then, create a new for sale house object      
    forSaleHaus=forSaleHouse(haus.index,haus.quality,haus.owner)
    # then, add the new for sale house to the for sale house list
    push!(env.forSaleHouses,forSaleHaus)
    # finally update its place in the all houses list
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=forSaleHaus
end

# finally, a function to convert a new house to a populated house