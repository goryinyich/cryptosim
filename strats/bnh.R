
evaluate <- function(mdata) {
    
    signal <- mdata$Close
    signal[, ] <- 1
    signal[!mdata$Universe.Volume] <- 0
    signal / rowSums(abs(signal), na.rm=T)
    
}
