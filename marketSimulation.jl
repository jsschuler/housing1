# now consider the probability distribution of sales 

# agents always buy houses they prefer 
# agents will not sell for below the loan balance 
# hotels have exactly one arrow pointing out
# exit houses exactly one arrow pointing in
# old houses have exactly one arrow flowing in and one arrow flowing out 
# arrows do not flow from houses of higher quality to houses of lower quality

function generateSaleNetwork()
    global dwellingList 
    # generate complete directed graph 
    transactionGraph=CompleteDiGraph(length(dwellingList))
    # step 1: remove arrows pointing from better houses to worse 
    
    # step 2: for any hotel, randomly select which arrow will point out 

    # step 3: then select randomly which arrow points out

    # step 4: drop completed cycles and continue until each exit house has at most one arrow pointing in


end