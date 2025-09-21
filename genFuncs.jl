# this code contains all the functions needed to generate initial objects in the environment
# one this runs, the model is fully initialized
function agtGen!(env::environment)
    env.agtTicker=env.agtTicker+1
    outAgt=agent(env.agtTicker,floor(Int64,rand(env.paymentDistribution,1)[1]),nothing)
    #agtLog(env,outAgt)
    push!(env.agtList,outAgt)
    return outAgt
end

function initAgents!(env::environment)
    for i in 1:env.agtCnt
        agtGen!(env)
    end
    return env
end

# now we need a function that generates a populated house for each existing agent
function initHouses!(env::environment)
    for agt in env.agtList
        haus=popHouse(length(env.allHouses)+1,rand(env.qualityDistribution,1)[1],agt)
        push!(env.allHouses,haus)
        push!(env.popHouses,haus)
        #houseLog(env,haus)
    end
    return env
end

# now functions that align agent budget and house quality

function housingSwap(house1::popHouse,house2::popHouse)
    #println("Debug")
    #println(house1.quality)
    #println(house2.quality)
    #println(house1.owner.budget)
    #println(house2.owner.budget)
    #println((house1.quality > house2.quality) & (house1.owner.budget < house2.owner.budget))
    #println((house2.quality > house1.quality) & (house2.owner.budget < house1.owner.budget))
    if (house1.quality > house2.quality) & (house1.owner.budget < house2.owner.budget)
        #println("swapped")
        richOwner=house2.owner
        house2.owner=house1.owner
        house1.owner=richOwner

        swap=true
    elseif (house2.quality > house1.quality) & (house2.owner.budget < house1.owner.budget)
        #println("swapped")
        richOwner=house1.owner
        house1.owner=house2.owner
        house2.owner=richOwner
        swap=true
    else
        #println("Flag3")
        swap=false
    end
    return swap
end

function initialSwapping!(env::environment)
    tick::Int64=0
    while true
        # select two random houses 
        twoHouses=sample(env.allHouses,2,replace=false)
        tick=tick+1
        #println(tick)
        if housingSwap(twoHouses[1],twoHouses[2])
            tick=0
        end
        if tick==10000000
            break
        end
    end
end

function initMod()
    env=initAll()
    initAgents!(env)
    initHouses!(env)
    #println("Before swapping")
    #println(env.allHouses)
    initialSwapping!(env)
    envLog(env::environment)
    return env
end