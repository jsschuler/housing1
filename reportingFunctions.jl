# we need a function that logs environments
function envLog(env::environment)
    dArray=DataFrame([[env.key],[string(typeof(qualityDistribution))],[string(typeof(paymentDistribution))],[agtCnt],[inFlow],[outFlow],[construction],[inPlace]],:auto)
    CSV.write("../housingData/modelRun"*env.key*".csv",dArray,header=false,append=true)
end
# We need a function that logs housing construction
function houseLog(env::environment,haus::newHouse)
    dArray=DataFrame([[env.key],[env.tick],[haus.index],[haus.quality]],:auto)
    CSV.write("../housingData/construction"*env.key*".csv",dArray,header=false,append=true)
end
# and agent generation
function agtLog(env::environment,agt::agent)
    dArray=DataFrame([[env.key],[env.tick],[agt.init],[agt.budget]],:auto)
    CSV.write("../housingData/agents"*env.key*".csv",dArray,header=false,append=true)
end

# and hotel generation

function hotelGenLog(env::environment,hot::hotel)
    dArray=DataFrame([[env.key],[env.tick],[hot.index],[hot.quality],[hot.owner.init]],:auto)
    CSV.write("../housingData/hotelCons"*env.key*".csv",dArray,header=false,append=true)
end

# and hotel deletion
function hotelDelLog(env::environment,hot::hotel)
    dArray=DataFrame([[env.key],[env.tick],[hot.index],[hot.quality],[hot.owner.init]],:auto)
    CSV.write("../housingData/hotelsDes"*env.key*".csv",dArray,header=false,append=true)
end
# and loan generation
function loanLog(env::environment,ln::loan)
    dArray=DataFrame([[env.key],[env.tick],[ln.interestRate],[ln.initialBalance],[ln.monthlyPayment],[ln.collateral.index]],:auto)
    CSV.write("../housingData/loanGen"*env.key*".csv",dArray,header=false,append=true)
    
end
# and loan payment in full
function loanFullLog(env::environment,ln::loan)
    dArray=DataFrame([[env.key],[env.tick],[ln.interestRate],[ln.collateral.index]],:auto)
    CSV.write("../housingData/loanFull"*env.key*".csv",dArray,header=false,append=true)
end
# and agents moving into the market
function agtMoveIn(env::environment,dwell::dwelling,agt::agent)
    dArray=DataFrame([[env.key],[env.tick],[dwell.index],[agt.init]],:auto)
    CSV.write("../housingData/moveIn"*env.key*".csv",dArray,header=false,append=true)
end


# and agents moving out of the market
function agtLeave(env::environment,origin::dwelling,agt::agent)
    dArray=DataFrame([[env.key],[env.tick],[origin.index],[agt.init]],:auto)
    CSV.write("../housingData/agtLeave"*env.key*".csv",dArray,header=false,append=true)
end
# and within the market
function agtMove(env::environment,origin::dwelling,dest::dwelling,agt::agent)
    dArray=DataFrame([[env.key],[env.tick],[origin.index],[dest.index],[agt.init]],:auto)
    CSV.write("../housingData/agtMove"*env.key*".csv",dArray,header=false,append=true)
end

# finally functions to track graphs and dictionaries
function graphLog(env::environment,tarGraph::SimpleDiGraph,label::String)
    hausDex=[]
    netDex=[]
    for ky in keys(env.nodeDict)
        push!(hausDex,ky)
        push!(netDex,env.nodeDict[ky])
    end
    dataDict=Dict(:key => env.key, :tick => env.tick, :house=> hausDex,:node => netDex)
    CSV.write("../housingData/dictionaries"*label*"-"*env.key*".csv",DataFrame(dataDict),header=false,append=true)

    # now log network
    srcVec=[]
    dstVec=[]
    for ed in edges(tarGraph)
        push!(srcVec,src(ed))
        push!(dstVec,dst(ed))
    end
    dataDict2=Dict(:key => env.key,:tick=>env.tick,:src=>srcVec,:dst => dstVec)
    CSV.write("../housingData/networks"*label*"-"*env.key*".csv",DataFrame(dataDict2),header=false,append=true)
end



