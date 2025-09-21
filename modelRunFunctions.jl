# now the way the model will work is as follows:
# at each tick:
    # 1 Sold houses become populated houses and their owners move to hotels
    # 2 Sold Exit houses become populated houses and their owners leave the market
    # 3. a number of new agents enter the market and dwell in hotels
    # 4. a number of agents decide to leave the market and list their houses as exit houses
    # 5. a number of new houses are built 
    # 6. a number of agents decide to move within the market and list their houses as for sale houses
    # 7 now, the inner loop starts and runs for a set number of rounds
        # a preference graph is generated connecting hotels to empty houses, exit houses, or for sale houses
        # in this preference graph, each hotel is connected to the house it prefers most
        # each house is sold to the highest bidding hotel for the price of the second highest bidding hotel 
        # the exit or for sale houses become sold exit houses
        # this means that agents which successfully, do not re-enter the market until the next tick



# we need a function that processes all sold houses. 
function allSold!(env::environment)
    for haus in vcat(env.soldHouses,env.soldEmptyHouses,env.soldExitHouses)
       # convert 
       populate!(env,haus)
    end
end
# and a function where new agents enter
function allEnter!(env::environment)
    for i in 1:env.inFlow
        newHotelGen!(env)
    end
end

# Now, we need to be aware of the issue that the number of agents who want to move either in place or away
# may exceed the number of populated houses
# thus, we randomize the order 

function upForSale!(env::environment)
    # how many populated houses are there?
    popCnt::Int64=length(env.popHouses)
    # now randomize the exiters vs the movers in place
    typeOrder=sample(vcat(repeat(:inPlace),env.inPlace),repeat(:outFlow,env,outFlow)),env.inPlace+env.outFlow,replace=false)
    # and randomize the exiting populated houses order
    hausOrder=sample(env.popHouses,length(env.popHouses),replace=false)
    for i in 1:length(popOrder)
        if typeOrder[i]==:inPlace
            list!(env,hausOrder[i])
        else
            exit!(env,hausOrder[i])
        end
    end
end