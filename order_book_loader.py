import urllib
from time import sleep
from datetime import datetime

# The script requests order book for the given instrument from Poloniex and
# dumps it to the file

crncy_1 = "USDT"
crncy_2 = "BTC"
max_depth = 100
dump_file = 'dump.txt'
periodicity = 0.5 # in sec., don't set too low - Poloniex bans IPs with > 6 req's/sec.

while (True):
    url = "https://poloniex.com/public?command=returnOrderBook&currencyPair=" \
        + crncy_1 + "_" + crncy_2 + "&depth=" + str(max_depth)
    response = urllib.urlopen(url).read()

    f = open(dump_file, 'a')
    f.write(response + '\n')
    f.close()    
    
    print datetime.now(), 'tick!'
    sleep(0.5)
