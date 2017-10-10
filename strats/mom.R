
evaluate <- function(mdata) {

    signal <- sign(mdata$Close / delay(mdata$Close, 365) - 1)
    signal[signal < 0] <- 0
    signal[!mdata$Universe.Volume] <- 0
    signal / rowSums(abs(signal), na.rm=T)
    
}
