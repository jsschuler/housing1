# we need a function that logs environments
function envLog(env::environment)
    dArray=[env.key,string(typeof(qualityDistribution)),string(typeof(paymentDistribution)),agtCnt,inFlow,outFlow,construction,inPlace]
    CSV.write("../housingData/modelRun"*env.key*".csv",dArray,header=false,append=true)
end
# We need a function that logs housing construction
function houseLog(env::environment,haus::newHouse)
    dArray=[env.key,env.tick,haus.index,haus.quality]
    CSV.write("../housingData/construction"*env.key*".csv",dArray,header=false,append=true)
end
# and agent generation
function agtLog(env::environment,agt::agent)
    dArray=[env.key,env.tick,agt.init,agt.budget]
    CSV.write("../housingData/agents"*env.key*".csv",dArray,header=false,append=true)
end

# and hotel generation

function hotelGenLog(env::environment,hot::hotel)
    dArray=[env.key,env.tick,hot.index,hot.quality,hot.owner.init]
    CSV.write("../housingData/hotelCons"*env.key*".csv",dArray,header=false,append=true)
end

# and hotel deletion
function hotelDelLog(env::environment,hot::hotel)
    dArray=[env.key,env.tick,hot.index,hot.quality,hot.owner.init]
    CSV.write("../housingData/hotelsDes"*env.key*".csv",dArray,header=false,append=true)
end
# and loan generation
function loanLog(env::environment,ln::loan)
    dArray=[env.key,env.tick,ln.interestRate,ln.initialBalance,ln.monthlyPayment,ln.collateral.index]
    CSV.write("../housingData/loanGen"*env.key*".csv",dArray,header=false,append=true)
    
end
# and loan payment in full
function loanFullLog(env::environment,ln::loan)
    dArray=[env.key,env.tick,ln.interestRate,ln.collateral.index]
    CSV.write("../housingData/loanFull"*env.key*".csv",dArray,header=false,append=true)
end


# and agents moving out of the market

# and within the market

# and agents leaving hotels





