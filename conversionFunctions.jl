# this code contains all of the required functions to convert between different house types
# while the model is running
# in the functions mapping houses up for sale to sold houses, we reference hotels rather than buyers
# since all buyers live in hotels
function forSaleToSold!(env::environment,haus::forSaleHouse,buyer::hotel,salePrice::Float64)
    # first we need to remove the house from the for sale list
    deleteat!(env.forSaleHouses,findfirst(x->x==haus,env.forSaleHouses))
    # then we need to create a new sold house object
    soldHaus=soldHouse(haus.id,haus.quality,haus.owner,salePrice,buyer.owner)
    # then we need to add the new sold house to the sold house list
    push!(env.soldHouses,soldHaus)
    # now remove the hotel from the hotels list
    deleteat!(env.allHotels,findfirst(x->x==buyer,env.allHotels))
    # finally we need to return the new sold house object
    return soldHaus
end

function exitToSoldExit!(env::environment,haus::exitHouse,buyer::hotel,salePrice::Float64)
    # first we need to remove the house from the exit list
    deleteat!(env.exitHouses,findfirst(x->x==haus,env.exitHouses))
    # then we need to create a new sold exit house object
    soldHaus=soldExitHouse(haus.id,haus.quality,haus.owner,salePrice,buyer.owner)
    # then we need to add the new sold exit house to the sold exit house list
    push!(env.soldExitHouses,soldHaus)
    # now remove the hotel from the hotels list
    deleteat!(env.allHotels,findfirst(x->x==buyer,env.allHotels))
    # finally we need to return the new sold exit house object
    return soldHaus
end

# now a function that converts a sold house to a populated house
# the sale price is only for records
function soldToPop!(env::environment,haus::soldHouse)
    # first, find the index of the house in the environment
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    popHaus=popHouse(haus.index,haus.quality,haus.buyer)
    # then, replace it with a populated house
    env.allHouses[idx]=popHaus
    # finally, add the owner to the list of agents in hotels
    push!(env.hotelList,hotelGen(env,haus.owner,salePrice))
    # remove the sold house from the sold house list
    deleteat!(env.soldHouses,findfirst(x->x==haus,env.soldHouses))
    return popHaus
end
# now a function that converts a sold exit house to a populated house
# the sale price is only for records
function soldExitToPop!(env::environment,haus::soldExitHouse)
    # first, find the index of the house in the environment
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    popHaus=popHouse(haus.index,haus.quality,haus.buyer)
    # then, replace it with a populated house
    env.allHouses[idx]=popHaus
    # finally, do not add the owner to the list of agents in hotels
    # remove the sold exit house from the sold exit house list
    deleteat!(env.soldExitHouses,findfirst(x->x==haus,env.soldExitHouses))
    return popHaus
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
    return forSaleHaus
end

# finally, a function to convert an empty house to a sold empty

function emptyToSoldEmpty!(env::environment,haus::emptyHouse,salePrice::Float64,buyer::hotel)
    # first, remove the house from the empty house list
    deleteat!(env.emptyHouses,findfirst(x->x==haus,env.emptyHouses))
    # then, create a new for sale house object      
    soldEmpty=soldEmptyHouse(haus.index,haus.quality,haus.owner,salePrice,buyer.owner)
    # then, add the new for sale house to the for sale house list
    push!(env.soldEmptyHouse,soldEmpty)
    # finally update its place in the all houses list
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=soldEmpty
    # now remove the hotel from the hotels list
    deleteat!(env.allHotels,findfirst(x->x==buyer,env.allHotels))
    return soldEmpty
end

# and a function to convert a sold empty house to a populated house
function soldEmptyToPop!(env::environment,haus::soldEmptyHouse)
    # first, remove the house from the sold empty house list
    deleteat!(env.soldEmptyHouses,findfirst(x->x==haus,env.soldEmptyHouse))
    # then, create a new for sale house object      
    popHaus=popHouse(haus.index,haus.quality,haus.buyer)
    # then, add the new for sale house to the for sale house list
    push!(env.popHouses,popHaus)
    # finally update its place in the all houses list
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=popHaus
    return popHaus
end
