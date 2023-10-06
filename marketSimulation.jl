# now consider the probability distribution of sales 

# agents always buy houses they prefer 
# agents will not sell for below the loan balance 
# hotels have exactly one arrow pointing out
# exit houses exactly one arrow pointing in
# new houses have one arrow pointing in 
# old houses have exactly one arrow flowing in and one arrow flowing out 
# arrows do not flow from houses of higher quality to houses of lower quality

function generateRandomSaleNetwork()
    global dwellingList 
    # generate complete directed graph 
    transactionGraph=CompleteDiGraph(length(dwellingList))
    # step 1: remove arrows pointing from better houses to worse 
    for dwell in dwellingList
        goingOut=outneighbors(dwell)
        currQual=hausQuality(dwell)
        preferredHouses=hausQuality.(goingOut) .>=currQual
        for j in eachindex(goingOut)
            if !preferredHouse[j]
                rem_edge!(transactionGraph,dwell,goingOut[j])
            end
        end
    end

    # step 2: for any hotel, randomly select which arrow will point out 
    global hotelList
    houseTargets=sample(houseList,length(hotelList),relace=false)
    # keep list of old houses that receive an in-arrow
    inHaus=oldHouse[]
    for haus in houseTargets
        if typeof(haus)==oldHouse
            push!(inHaus,haus)
        # select one of the house's out-neighbors
        pointOut=sample(outneigbors(transactionGraph,haus),1)[1]
        # delete all other in neighbors 
        pointIn=collect(setdiff(inneighbors(transactionGraph,pointOut),Set(pointOut)))
        for dwell in pointIn
            rem_edge!(transactionGraph,dwell,pointOut)
        end
    end

    # step 3: then for each of the houses to which these arrows point
        # we repeat this process until there are 
        # now, range over the houses with new in arrows 


end

# is there are the same number of agents, as houses, every agent gets a house 
# given an income and a quality distribution, we can ask: what does the quality error term need to be to get every agent a house?