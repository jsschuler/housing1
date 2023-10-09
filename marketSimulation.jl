# now consider the probability distribution of sales 

# agents always buy houses they prefer (arrows always point in the direction of weak preference)
# agents will not sell for below the loan balance 
# hotels have exactly one arrow pointing out
# exit houses exactly one arrow pointing in
# new houses have one arrow pointing in 
# old houses have exactly one arrow flowing in and one arrow flowing out 

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
    # get all houses listed in random order
    houseTargets=sample(houseList,length(houseList),relace=false)
    # we want a list of all dwellings with hotels first 
    dwellingTank::Array{dwelling}=cat(hotelList,houseList,dims=1)
    while true 
        for dwell in dwellingTank
            if typeof(dwell)==hotel
                # case 1, dwelling is a hotel 
                # if the dwelling is a hotel, the hotel dweller targets a house
                # if the offer from the hotel dweller is enough to pay off the mortgage, the house dweller accepts
                for targ in houseTargets
                    # what is the hotel dweller offering?
                    totOffer=mortgageCalc(dwell.budget)
                    # does this cover the seller's mortgage?
                    targ.
                end

            end
            # case 2: dwelling is either an exit house or a new house 
            # dweller does nothing actively but passively accepts offers great enough to pay off 
            # mortgages 

            # case 3: dwelling is an old house 
            # dweller takes the received offer and uses it to make an offer on another random house

        end

    end
    
end