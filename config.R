
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
        # for build_data_poloniex
        base_currency = 'USDT', # 'BTC', 'USDT', 'XMR', 'ETH'
        frequency = 900, # '300' - 5 min, '900' - 15 min, '1800' - 30 min, '7200' - 2 hours, '14400' - 4 hours, and '86400' - 1 day
        # rules for universe filtering
        tickers.list = get.tickers.list(),
        min.usd.volume = 1e6, # min daily dollar volume for ticker to be included in the Universe.Volume
        universe.tops = c(10, 20, 40)
    ),
    
    backtester = list(
        strats = list.files('./strats/', full.names = TRUE),
        
        trading.delay = 1,
        initial.capital = 1e6,
        fixed.fee = 1e-6, # share of initial capital per trade
        tvr.fee = 4e-4, # broker fees for trade volume
        min.trade.vol = 1e-3, # min share of initial capital to do trade
        spread.cost = 50e-4 # spread
    )
    
)