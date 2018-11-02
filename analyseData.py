#!/usr/bin/env python3

"""
structure of data file:


lines beginning with # are ignored; #'s are used in first line and to divide different data sets
# lines have meta data (date, cpu or gpu, real time or non real time)
# 31.10.2018 16:07; rendering: cpu; time: real time

 #
 data...
 #
 data...

 data consists of paires of
 y force
 diveded by space

"""

import sys
import matplotlib.pyplot as plt
import typing


def plotData(listOfData: str):
    for dataList in listOfData:
        plt.plot(dataList[0], dataList[1])
    plt.show()


def getData(filePath: str):
    listOfData = []
    with open(filePath) as f:
        for line in f.readlines():
            if line[0] == "#":
                listOfData.append([])
                listOfData[-1].append([])
                listOfData[-1].append([])
            else:
                words = line.split()
                listOfData[-1][0].append(float(words[0]))
                listOfData[-1][1].append(float(words[1]))
    listOfData = [x for x in listOfData if x != []]
    return listOfData


def main():
    filePath = sys.argv[1]
    listOfData = getData(filePath)
    print(listOfData)
    plotData(listOfData)

if __name__=="__main__":
    main()
