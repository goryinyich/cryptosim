
# loading data from https://poloniex.com/support/api/

read.json <- function(fn) {
    dt <- fromJSON(paste(readLines(fn), collapse=""))
    df <- do.call(rbind, lapply(dt, as.vector))
    storage.mode(df) <- 'numeric'
    data.frame(df)
}

data.reload.needed <- function() {
    if (!file.exists(Config$mdata$data.file)) return(TRUE)
    if (!Config$mdata$force.mdata.reload) return(FALSE)
    load(Config$mdata$data.file)
    return(Sys.Date() - last(mdata$Timeline) > Config$mdata$max.cache.delay)
}

read.coin.file <- function(fn) {
    df <- read.csv(fn, sep = ' ', stringsAsFactors = FALSE)
    timeSeries(cbind(
        Open = df$open,
        High = df$high,
        Low = df$low,
        Close = df$close,
        Volume = df$quoteVolume,
        DollarVolume = df$volume
    ), as.POSIXlt(df$date, origin = '1970-01-01'))
}

reload.data <- function() {
    if (dir.exists(Config$mdata$cache.dir)) {
        if (Config$mdata$force.mdata.reload) unlink(Config$mdata$cache.dir, recursive = TRUE)
    } else dir.create(Config$mdata$cache.dir)
    # coins list
    coins.df <- read.json('https://poloniex.com/public?command=returnTicker')
    tickers <- grep(paste0(Config$mdata$base_currency, '_'), rownames(coins.df), value = TRUE)
    cat(paste0(length(tickers), ' tickers found for base currency ', Config$mdata$base_currency, '\n'))
    for (ticker in tickers) {
        cat('Loading ', ticker, '... ')
        fn <- file.path(Config$mdata$cache.dir, paste0(ticker, '.csv'))
        if (!file.exists(fn)) {
            df <- read.json(paste0('https://poloniex.com/public?command=returnChartData&currencyPair=', ticker, '&start=1&end=9999999999&period=', Config$mdata$frequency))
            write.table(df, file=fn, row.names = F)
            cat('[OK]\n')
        } else cat('[CACHE HIT]\n')
    }
    
    coins.data <- lapply(
        list.files(Config$mdata$cache.dir, full.names = TRUE),
        read.coin.file
    )
    names(coins.data) <- tools::file_path_sans_ext(list.files(Config$mdata$cache.dir, full.names = FALSE))
    # filter those tickers that never make it to universe
    fields <- c('Open', 'High', 'Low', 'Close', 'Volume', 'DollarVolume')
    
    mdata <- list()
    mdata$Tickers <- names(coins.data)
    for (field in fields) {
        mdata[[field]] <- do.call(cbind, lapply(coins.data, function(v) {v[, field]}))
    }
    mdata$Timeline <- time(mdata[[fields[1]]])
    for (field in fields) {
        mdata[[field]] <- getDataPart(mdata[[field]])
        rownames(mdata[[field]]) <- as.character(mdata$Timeline)
        colnames(mdata[[field]]) <- mdata$Tickers
    }
    wnd <- 30 * 86400 / Config$mdata$frequency
    mean.vol <- wnd * apply(mdata$DollarVolume, 2, runmean, k = wnd, align='right') / 30
    mdata$Universe.Volume <- mean.vol >= Config$mdata$min.usd.volume
    for (top.n in Config$mdata$universe.tops) {
        mdata[[paste0('Universe.Top', top.n)]] <- t(apply(mdata$DollarVolume, 1, function(v) {
            v <- rank(v, na.last = 'keep')
            v <- v > max(v, na.rm=T) - top.n
            v[!is.finite(v)] <- F
            v
        }))
    }
    save(mdata, file = Config$mdata$data.file)
}

if (data.reload.needed()) reload.data()
load(Config$mdata$data.file)



