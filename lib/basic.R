Sys.setlocale('LC_ALL', 'en_US.UTF-8')

load.libraries <- function(libs) {
    for (lib in libs) {
        if (!require(lib, character.only = TRUE)) {
            install.packages(lib)
            library(lib, character.only = TRUE)
        }
    }
}

load.libraries(c(
    'timeSeries',
    'PerformanceAnalytics',
    'rjson',
    'caTools',
    'R6',
    'Rcpp'
))


delay <- function(x, period = 1, fill.value = NA) {
    if (period == 0) return(x)
    stopifnot(is.vector(x) | is.matrix(x) | is.timeSeries(x))
    if (is.timeSeries(x)) return(timeSeries(delay(getDataPart(x), period), time(x), units = names(x)))
    if (is.vector(x)) {
        if (period >= length(x)) return(rep(fill.value, length(x)))
        return(c(rep(fill.value, period), head(x, -period)))
    }
    if (is.matrix(x)) {
        if (period >= nrow(x)) return(matrix(fill.value, nrow(x), ncol(x), dimnames = list(rownames(x), colnames(x))))
        result <- rbind(matrix(fill.value, period, ncol(x)), head(x, -period))
        rownames(result) <- rownames(x)
        colnames(result) <- colnames(x)
        return(result)
    }
}

# in the future - speed up in Rcpp
replace.beginning.values <- function(x, what, by) {
    stopifnot(is.vector(x) | is.matrix(x) | is.timeSeries(x))
    if (is.timeSeries(x)) return(timeSeries(replace.beginning.values(getDataPart(x), what, by), time(x), units = names(x)))
    if (is.vector(x)) {
        i = 1
        while (i <= length(x)) {
            if (is.finite(x[i])) {
                if (x[i] != what) break
                x[i] = by
            }
            i <- i + 1
        }
        return(x)
    }
    apply(x, 2, replace.beginning.values, what = what, by = by)
}
