
# Currently the data is loaded from https://www.cryptocompare.com/api/

# Due to restrictions, only the most liquid currencies are added for full list
# coins.list.file <- 'https://www.cryptocompare.com/api/data/coinlist/'
# coins.list <- fromJSON(paste(readLines(coins.list.file), collapse=""))
# coins.list <- coins.list$Data[sapply(coins.list$Data, length) == 14]
# coins.df <- do.call(rbind, lapply(coins.list, data.frame, stringsAsFactors = FALSE))

data.reload.needed <- function() {
    if (!file.exists(Config$mdata$data.file)) return(TRUE)
    if (!Config$mdata$force.mdata.reload) return(FALSE)
    load(Config$mdata$data.file)
    return(Sys.Date() - last(mdata$Timeline) > Config$mdata$max.cache.delay)
}

read.coin.file <- function(fn) {
    df <- read.csv(fn, sep = ' ', stringsAsFactors = FALSE)
    vol <- pmax(df$volumefrom, df$volumeto)
    df$open[vol == 0] <- NA
    df$high[vol == 0] <- NA
    df$low[vol == 0] <- NA
    df$close[vol == 0] <- NA
    timeSeries(cbind(
        Open = df$open,
        High = df$high,
        Low = df$low,
        Close = df$close,
        Volume = vol
    ), as.POSIXlt(df$time, origin = '1970-01-01'))
}

reload.data <- function() {
    if (!dir.exists(Config$mdata$cache.dir)) dir.create(Config$mdata$cache.dir)
    # update data on individual currencies
    for (ticker in Config$mdata$tickers.list) {
        cat('Loading ', ticker, '...')
        fn <- file.path(Config$mdata$cache.dir, paste0(ticker, '.csv'))
        coin.url <- sprintf('https://min-api.cryptocompare.com/data/histoday?fsym=%s&tsym=USD&limit=100000&aggregate=1', ticker)
        coin.data <- fromJSON(paste(readLines(coin.url), collapse=""))
        # replace NULLS with NAs
        coin.data$Data <- lapply(
            coin.data$Data, function(xx) {
                xx[sapply(xx, is.null)] <- NA
                xx
            }
        )
        
        data <- do.call(rbind, lapply(coin.data$Data, data.frame))
        if (!is.null(data)) {
            write.table(data, file=fn, row.names = F)
            cat('[OK]\n')
        } else cat('[FAILED]\n')
    }
    coins.data <- lapply(
        list.files(Config$mdata$cache.dir, full.names = TRUE),
        read.coin.file
    )
    names(coins.data) <- tools::file_path_sans_ext(list.files(Config$mdata$cache.dir, full.names = FALSE))
    # filter those tickers that never make it to universe
    coins.data <- lapply(coins.data, function(v) {
        DollarVolume <- v[, 'Volume'] * (v[, 'Open'] + v[, 'Close'] + v[, 'Low']/2 + v[, 'High']/2) / 3
        cbind(v, DollarVolume = DollarVolume)
    })
    coins.data <- coins.data[sapply(coins.data, function(v) {
        mean.vol <- runmean(v$DollarVolume, k=30, align='right')
        any(mean.vol >= Config$mdata$min.usd.volume, na.rm = TRUE)
    })]
    fields <- c('Open', 'High', 'Low', 'Close', 'Volume', 'DollarVolume')
    
    mdata <- list()
    mdata$Tickers <- names(coins.data)
    for (field in fields) {
        mdata[[field]] <- do.call(cbind, lapply(coins.data, function(v) {v[, field]}))
    }
    mdata$Timeline <- time(mdata[[fields[1]]])
    for (field in fields) {
        mdata[[field]] <- getDataPart(mdata[[field]])
        #mdata[[field]] <- replace.beginning.values(mdata[[field]], 0, NA)
        rownames(mdata[[field]]) <- as.character(mdata$Timeline)
        colnames(mdata[[field]]) <- mdata$Tickers
    }
    mean.vol <- apply(mdata$DollarVolume, 2, runmean, k=30, align='right')
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
