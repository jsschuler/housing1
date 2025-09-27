# this code contains all of the required functions to convert between different house types
# while the model is running
# in the functions mapping houses up for sale to sold houses, we reference hotels rather than buyers
# since all buyers live in hotels
function sell!(env::environment,haus::forSaleHouse,buyer::hotel,salePrice::Float64)
    # first pay off the mortgage if there is one.
    if typeof(haus)!=emptyHouse
        if !isnothing(haus.owner.loan)
            deleteat!(env.loanList,findfirst(x->x==haus.owner.loan,env.loanList))
        end
    end
    # then we need to remove the house from the for sale list
    deleteat!(env.forSaleHouses,findfirst(x->x==haus,env.forSaleHouses))
    # then we need to create a new sold house object
    soldHaus=soldHouse(haus.index,haus.quality,haus.owner,salePrice,buyer.owner)
    # then we need to add the new sold house to the sold house list
    push!(env.soldHouses,soldHaus)
    borrowedBalance::Float64=max(salePrice-buyer.budget,0.0)
    if borrowedBalance > 0.0
        loanGen(env,soldHaus,borrowedBalance)
    else
        buyer.owner.loan=nothing
    end
    # now remove the hotel from the hotels list
    hotelDelLog(env,env.allHotels[findfirst(x->x==buyer,env.allHotels)])
    deleteat!(env.allHotels,findfirst(x->x==buyer,env.allHotels))
    # finally we need to return the new sold house object
    agtLeaveLog(env,soldHaus,soldHaus.owner)
    saleLog(env,soldHaus,salePrice)
    return soldHaus
end

function sell!(env::environment,haus::exitHouse,buyer::hotel,salePrice::Float64)
    # first pay off the mortgage if there is one.
    if typeof(haus)!=emptyHouse
        if !isnothing(haus.owner.loan)
            deleteat!(env.loanList,findfirst(x->x==haus.owner.loan,env.loanList))
        end
    end
    #println(env.exitHouses)
    #println(haus)
    #println(findfirst(x->x==haus,env.exitHouses))
    # then we need to remove the house from the exit list
    deleteat!(env.exitHouses,findfirst(x->x==haus,env.exitHouses))
    # then we need to create a new sold exit house object
    soldHaus=soldExitHouse(haus.index,haus.quality,haus.owner,salePrice,buyer.owner)
    # then we need to add the new sold exit house to the sold exit house list
    push!(env.soldExitHouses,soldHaus)
    # now generate the loan the agent takes out
    # if the agent has left over money, we assume it blows it in Vegas
    borrowedBalance::Float64=max(salePrice-buyer.budget,0.0)
    if borrowedBalance > 0.0
        loanGen(env,soldHaus,borrowedBalance)
    else
        buyer.owner.loan=nothing
    end
    # now remove the hotel from the hotels list
    hotelDelLog(env,env.allHotels[findfirst(x->x==buyer,env.allHotels)])
    deleteat!(env.allHotels,findfirst(x->x==buyer,env.allHotels))
    # finally we need to return the new sold exit house object
    agtLeaveLog(env,soldHaus,soldHaus.owner)
    saleLog(env,soldHaus,salePrice)
    return soldHaus
end

# now a function that converts a sold house to a populated house
# the sale price is only for records
function populate!(env::environment,haus::soldHouse)
    # first, find the index of the house in the environment
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    popHaus=popHouse(haus.index,haus.quality,haus.buyer)
    # then, replace it with a populated house
    env.allHouses[idx]=popHaus
    # finally, add the owner to the list of agents in hotels
    push!(env.allHotels,hotelGen!(env,haus.owner,salePrice))
    # remove the sold house from the sold house list
    deleteat!(env.soldHouses,findfirst(x->x==haus,env.soldHouses))
    # now update the loan information
    if !isnothing(popHaus.owner.loan)
        popHaus.owner.loan.collateral=popHaus
    end
    agtMoveInLog(env,popHaus,popHaus.owner)
    return popHaus
end
# now a function that converts a sold exit house to a populated house
# the sale price is only for records
function populate!(env::environment,haus::soldExitHouse)
    # first, find the index of the house in the environment
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    popHaus=popHouse(haus.index,haus.quality,haus.buyer)
    # then, replace it with a populated house
    env.allHouses[idx]=popHaus
    # finally, do not add the owner to the list of agents in hotels
    # remove the sold exit house from the sold exit house list
    deleteat!(env.soldExitHouses,findfirst(x->x==haus,env.soldExitHouses))
    # now update the loan information
    if !isnothing(popHaus.owner.loan)
        popHaus.owner.loan.collateral=popHaus
    end    
    agtMoveInLog(env,popHaus,popHaus.owner)
    return popHaus
end 

# now a function to convert a populated house to a for sale house
function list!(env::environment,haus::popHouse)
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

# and an exit function
function exit!(env::environment,haus::popHouse)
    # first, remove the house from the populated house list
    deleteat!(env.popHouses,findfirst(x->x==haus,env.popHouses))
    # then, create a new for sale house object      
    forSaleHaus=exitHouse(haus.index,haus.quality,haus.owner)
    # then, add the new for sale house to the for sale house list
    push!(env.exitHouses,forSaleHaus)
    # finally update its place in the all houses list
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=forSaleHaus
    
    return forSaleHaus
end


# finally, a function to convert an empty house to a sold empty

function sell!(env::environment,haus::emptyHouse,buyer::hotel,salePrice::Float64)
    # first pay off the mortgage if there is one.
    if typeof(haus)!=emptyHouse
        if !isnothing(haus.owner.loan)
            deleteat!(env.loanList,findfirst(x->x==haus.owner.loan,env.loanList))
        end
    end 
    # then, remove the house from the empty house list
    deleteat!(env.emptyHouses,findfirst(x->x==haus,env.emptyHouses))
    # then, create a new for sale house object      
    soldEmpty=soldEmptyHouse(haus.index,haus.quality,salePrice,buyer.owner)
    # then, add the new for sale house to the for sale house list
    push!(env.soldEmptyHouses,soldEmpty)
    # finally update its place in the all houses list
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=soldEmpty
    # now generate the loan the agent takes out
    # if the agent has left over money, we assume it blows it in Vegas
    borrowedBalance::Float64=max(salePrice-buyer.budget,0.0)
    if borrowedBalance > 0.0
        loanGen(env,soldEmpty,borrowedBalance)
    else
        buyer.owner.loan=nothing
    end
    # now remove the hotel from the hotels list
    hotelDelLog(env,env.allHotels[findfirst(x->x==buyer,env.allHotels)])
    deleteat!(env.allHotels,findfirst(x->x==buyer,env.allHotels))
    saleLog(env,soldEmpty,salePrice)
    return soldEmpty
end

# and a function to convert a sold empty house to a populated house
function populate!(env::environment,haus::soldEmptyHouse)
    # first, remove the house from the sold empty house list
    deleteat!(env.soldEmptyHouses,findfirst(x->x==haus,env.soldEmptyHouses))
    # then, create a new for sale house object      
    popHaus=popHouse(haus.index,haus.quality,haus.buyer)
    # then, add the new for sale house to the for sale house list
    push!(env.popHouses,popHaus)
    # finally update its place in the all houses list
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=popHaus
    # now update the loan information
    if !isnothing(popHaus.owner.loan)
        popHaus.owner.loan.collateral=popHaus
    end
    agtMoveInLog(env,popHaus,popHaus.owner)
    return popHaus
end
