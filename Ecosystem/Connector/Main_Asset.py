# IBAPI Dependencies 
from ibapi.client import EClient
from ibapi.wrapper import EWrapper

class IBAPI(EWrapper, EClient): 
    """
    The main class for interacting with the IBKR API
    
                ----- EClient ------> 
    PYTHON CODE                       TWS API
                <---- EWrapper ------
    
    """
    # Initialising the EClient 
    def __init__(self) : 
        EClient.__init__(self, self)


    