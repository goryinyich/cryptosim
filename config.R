
# function that loads tickers list
get.tickers.list = function() {
    df <- read.csv('./mdata/liquid_list.csv', stringsAsFactors = FALSE)
    df$Symbol
}

Config <- list(
    
    mdata = list(
        data.file = './mdata/data.RData',
        cache.dir = './cache/',
        force.mdata.reload = FALSE, # if FALSE, mdata is never reloaded once loaded
        max.cache.delay = 1, # if current.date - last timestamp of mdata > max.cache.delay, cache is reloaded (if force.mdata.reload == TRUE)
        # rules for universe filtering
        tickers.list = get.tickers.list(),
        min.usd.volume = 1e5, # min daily dollar volume for ticker to be included in the Universe.Volume
        universe.tops = c(10, 20, 40)
    ),
    
    backtester = list(
        strats = list.files('./strats/', full.names = TRUE),
        
        trading.delay = 0,
        initial.capital = 1e6,
        fixed.fee = 1e-6, # share of initial capital per trade
        tvr.fee = 3e-4, # broker fees for trade volume
        min.trade.vol = 1e-3, # min share of initial capital to do trade
        spread.cost = 2e-3 # slippage
    )
    
)