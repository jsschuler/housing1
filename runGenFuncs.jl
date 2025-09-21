# this code contains the functions required to generate new objects needed while the model is running
# this includes newly built houses, entering agents, loans, and hotels 

function hotelGen!(env::environment)
    env.hotelTicker=env.hotelTicker-1
    outHotel=hotel(env.hotelTicker,0.0,agtGen!(env))
    push!(env.allHotels,outHotel)
    #hotelLog(env,outHotel)
    return outHotel
end



# we need a function to generate a single new house
function houseGen!(env::environment)
    houseCounter=length(env.allHouses)+1
    haus=emptyHouse(houseCounter,rand(env.qualityDistribution,1)[1])
    #houseLog(env,haus)
    push!(env.allHouses,haus)
    push!(env.emptyHouses,haus)
    return haus
end
