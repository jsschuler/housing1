# now the way the model will work is as follows:
# at each tick:
    #1 Sold houses become populated houses and their owners move to hotels
    #2 Sold Exit houses become populated houses and their owners leave the market
    #3. a number of new agents enter the market and dwell in hotels
    #4. a number of agents decide to leave the market and list their houses as exit houses
    #5. a number of new houses are built 
    #6. a number of agents decide to move within the market and list their houses as for sale houses
    # 7 now, the inner loop starts and runs for a set number of rounds
        # a preference graph is generated connecting hotels to empty houses, exit houses, or for sale houses
        # in this preference graph, each hotel is connected to the house it prefers most
        # each house is sold to the highest bidding hotel for the price of the second highest bidding hotel 
        # the exit or for sale houses become sold exit houses
        # this means that agents which successfully, do not re-enter the market until the next tick

# we need a function that converts a sold house to a populated house

function soldToPop!(env::environment,haus::soldHouse,salePrice::Float64)
    # first, find the index of the house in the environment
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=popHouse(haus.index,haus.quality,haus.buyer)
    # finally, add the owner to the list of agents in hotels
    push!(env.hotelList,hotelGen(env,haus.owner,salePrice))
end

# we need a function that converts a sold exit house to a populated house
# the sale price is only for records
function soldExitToPop!(env::environment,haus::soldExitHouse,salePrice::Float64)
    # first, find the index of the house in the environment
    idx=findfirst(x->x.index==haus.index,env.allHouses)
    # then, replace it with a populated house
    env.allHouses[idx]=popHouse(haus.index,haus.quality,haus.buyer)
    # finally, do not add the owner to the list of agents in hotels
end

# we need a function to generate new hotels for agents entering the market
function newHotelGen!(env::environment)
    for i in 1:env.inFlow
        hotelGen(env)
    end
end

# we need a function for agents exiting to list their houses as exit houses
function exitHouseGen!(env::environment)
    for i in 1:max(env.outFlow)
        # select a random house from the list of populated houses
        if length(env.popHouses)>0
            idx=rand(1:length(env.popHouses))
            haus=env.popHouses[idx]
            # convert it to an exit house
            exit=exitHouse(haus.index,haus.quality,haus.owner)
            # log the event
            exitHouseGenLog(env,exit)
            # replace the house in the environment
            env.allHouses[findfirst(x->x.index==haus.index,env.allHouses)]=exit
            # remove it from the list of populated houses
            deleteat!(env.popHouses,idx)
        end
    end
end
# we need a function to generate new houses
function newHouseGen!(env::environment)
    for i in 1:env.construction
        houseGen(env)
    end
end
# we need a function for agents moving within the market to list their houses as for sale houses
function forSaleHouseGen!(env::environment)
    for i in 1:max(env.inPlace)
        # select a random house from the list of populated houses
        if length(env.popHouses)>0
            idx=rand(1:length(env.popHouses))
            haus=env.popHouses[idx]
            # convert it to a for sale house
            forsale=forSaleHouse(haus.index,haus.quality,haus.owner)
            # log the event
            forSaleHouseGenLog(env,forsale)
            # replace the house in the environment
            env.allHouses[findfirst(x->x.index==haus.index,env.allHouses)]=forsale
            # remove it from the list of populated houses
            deleteat!(env.popHouses,idx)
        end
    end
end



