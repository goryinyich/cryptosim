#include <Rcpp.h>
#include <cstring>
#include <math.h>
using namespace Rcpp;

// [[Rcpp::export]]
Rcpp::List cpp_calc_pnl(
        const NumericMatrix& weights,
        const NumericMatrix& close_px,
        const int trading_delay = 0,
        const double initial_cash = 1e6,
        const double min_trade_volume = 1e-3,
        const double spread_cost = 0.0010,
        const double fix_fee = 0.0000,
        const double tvr_fee = 0.0002) {
    NumericMatrix eff_weights(weights.nrow(), weights.ncol());
    NumericVector capital(weights.nrow());
    NumericVector fees(weights.nrow(), 0.0);
    NumericVector slippage(weights.nrow(), 0.0);

    NumericVector curr_wts(weights.ncol(), 0.0);
    NumericVector last_valid_px(weights.ncol(), 0.0);
    double curr_cash = initial_cash;
    
    for (int ti = 0; ti < weights.nrow(); ++ti) {
        // update prices to revalue positions
        for (int i = 0; i < weights.ncol(); ++i) if (std::isfinite(close_px(ti, i))) last_valid_px[i] = close_px(ti, i);
        // update capital
        capital[ti] = sum(curr_wts * last_valid_px) + curr_cash;
        // update effective weights for period passed
        eff_weights(ti, _) = (curr_wts * last_valid_px) / capital[ti];
        if (ti >= trading_delay) {
            // calculate "ideal" target positions
            NumericVector weights_target = (capital[ti] * weights(ti - trading_delay, _)) / last_valid_px;
            // trade whenever is possible (finite price) and trade volume > min_volume
            for (int i = 0; i < weights.ncol(); ++i) if (std::isfinite(close_px(ti, i)) & std::isfinite(weights_target[i])) {
                double usd_vol = fabs(weights_target[i] - curr_wts[i]) * last_valid_px[i];
                if (usd_vol / capital[ti] > min_trade_volume) {
                    // do trade
                    fees[ti] += fix_fee * std::max<double>(initial_cash, capital[ti]) + tvr_fee * usd_vol;
                    slippage[ti] += spread_cost * usd_vol / 2.0;
                    double qty = weights_target[i] - curr_wts[i];
                    curr_wts[i] += qty;
                    curr_cash -= qty * last_valid_px[i];
                }
            }
            curr_cash -= fees[ti] + slippage[ti];
        }
    }
    
    return Rcpp::List::create(
        _("effective.weights") = eff_weights,
        _("capital") = capital,
        _("fees") = fees,
        _("slippage") = slippage
    );
}