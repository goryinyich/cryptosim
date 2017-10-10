

Strategy <- R6Class(
    classname = 'Strategy',
    cloneable = FALSE,
    
    public = list(
        
        initialize = function() {
            
        },
        
        get.default.params() {
            list()
        },
        
        evaluate = function() {
            stop('Strategy::evaluate() is abstract and should be redefined')
        }
        
    ),
    
    private = list(
        
    )
)