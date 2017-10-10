source('./lib/basic.R')
source('./lib/accounting.R')
sourceCpp('./lib/calc_pnl.cpp')


source('config.R')
source('build_data.R')


for (bstr in Config$backtester$strats) {
    e <- new.env()
    source(bstr, local = e)
    signal <- e$evaluate(mdata)
    signal[!mdata$Universe.Volume] <- 0
    bkts <- calc.pnl(
        weights = signal,
        mdata = mdata,
        trading.delay = Config$backtester$trading.delay,
        initial.capital = Config$backtester$initial.capital,
        min.trade.vol = Config$backtester$min.trade.vol,
        spread.cost = Config$backtester$spread.cost,
        fix.fee = Config$backtester$fixed.fee,
        tvr.fee = Config$backtester$tvr.fee
    )
    charts.PerformanceSummary(bkts$pnl, main=tools::file_path_sans_ext(basename(bstr)))
}
