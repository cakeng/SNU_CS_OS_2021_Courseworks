#! /usr/bin/python3
import math
for i in range(9000):
    # tan = i/1000 + 1
    # arctan = math.atan(tan)
    # if arctan == 0:
    #     arctan = 0.0000001
    # sec = 1/math.cos(arctan)
    # val = 123.123
    print ("%.0f, "%(math.cos(3.141592/180*(i/100))*1000000), end='')
    if i%1000 == 999:
        print('')
