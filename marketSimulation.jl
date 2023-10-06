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
        goingOut=idxDwelling.(outneighbors(dwellingIdx(dwell)))
        currQual=hausQuality(dwell)
        preferredHouses=hausQuality.(dwellingIdx.(goingOut)) .>=currQual
        for j in eachindex(goingOut)
            if !preferredHouse[j]
                rem_edge!(transactionGraph,dwellingIdx(dwell),goingOut[j])
            end
        end
    end

    # step 2: for any hotel, randomly select which arrow will point out 
    global hotelList
    for hotel in hotelList
        

    end
    # step 3: then for each of the houses to which these arrows point
        # if they are exit houses or new houses, only an arrow points in 
        # if they are not, then randomly choose another house to which they point
        # continue this until we run out of old houses
        # survey old houses that have lack one arrow
        # an old house that lacks an arrow pointing out can switch with a new house or an exit house
        # and old house that lacks an arrow point in 


end

# is there are the same number of agents, as houses, every agent gets a house 
# given an income and a quality distribution, we can ask: what does the quality error term need to be to get every agent a house?