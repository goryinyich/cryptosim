
calc.pnl <- function(
    weights,
    mdata,
    trading.delay,
    initial.capital,
    min.trade.vol,
    spread.cost,
    fix.fee,
    tvr.fee
) {
    bkts <- cpp_calc_pnl(
        weights = signal,
        close_px = mdata$Close,
        trading_delay = Config$backtester$trading.delay,
        initial_cash = Config$backtester$initial.capital,
        min_trade_volume = Config$backtester$min.trade.vol,
        spread_cost = Config$backtester$spread.cost,
        fix_fee = Config$backtester$fixed.fee,
        tvr_fee = Config$backtester$tvr.fee
    )
    bkts$effective.weights <- timeSeries(bkts$effective.weights, mdata$Timeline, units = mdata$Tickers)
    bkts$capital <- timeSeries(bkts$capital, mdata$Timeline)
    bkts$fees <- timeSeries(bkts$fees, mdata$Timeline)
    bkts$slippage <- timeSeries(bkts$slippage, mdata$Timeline)
    bkts$pnl <- bkts$capital / delay(bkts$capital, 1) - 1
    bkts
}
