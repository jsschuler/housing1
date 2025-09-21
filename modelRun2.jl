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


