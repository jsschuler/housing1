# this code contains all the funtions needed to initialize the environment

function initEnv()
    return environment(repeat([nothing],26)... )
end

# now we need functions to initialize every parameter in the environment
function keyGen!(env::environment)
    global seed
    env.key=string(Dates.now())*"-"*string(seed)*"-"*string(rand(1:10^6))
end

function qualGen!(env::environment)
    global qualityDistribution
    env.qualityDistribution=qualityDistribution
end
function interestRateGen!(env::environment)
    global interestRate
    env.interestRate=interestRate
end
function paymentGen!(env::environment)
    global paymentDistribution
    env.paymentDistribution=paymentDistribution
end
function agtCntGen!(env::environment)
    global agtCnt
    env.agtCnt=agtCnt
end
function inFlowGen!(env::environment)
    global inFlow
    env.inFlow=inFlow
end
function outFlowGen!(env::environment)
    global outFlow
    env.outFlow=outFlow
end
function constructionGen!(env::environment)
    global construction
    env.construction=construction
end
function inPlaceGen!(env::environment)
    global inPlace
    env.inPlace=inPlace
end
function allTicksGen!(env::environment)
    global allTicks
    env.allTicks=allTicks  
    env.tick=0
end

function initDwellings!(env::environment)
    env.allHouses=house[]
    env.popHouses=popHouse[]
    env.forSaleHouses=forSaleHouse[]
    env.exitHouses=exitHouse[]
    env.soldHouses=soldHouse[]
    env.soldExitHouses=soldExitHouse[]
    env.emptyHouses=emptyHouse[]
    env.soldEmptyHouses=soldEmptyHouse[]
    env.allHotels=hotel[]

    return env
end

function initAgtList!(env::environment)
    env.agtList=agent[]
end

function initLoanList!(env::environment)
    env.loanList=loan[]
end

function setAgtTicker!(env::environment)
    env.agtTicker=0
end

function initAll()
    env=initEnv()
    keyGen!(env)
    qualGen!(env)
    paymentGen!(env)
    interestRateGen!(env)
    agtCntGen!(env)
    inFlowGen!(env)
    outFlowGen!(env)
    constructionGen!(env)
    inPlaceGen!(env)
    allTicksGen!(env)
    initDwellings!(env)
    initAgtList!(env)
    initLoanList!(env)
    setAgtTicker!(env)
    return env
end