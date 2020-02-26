#! /bin/bash
#Check Memory Usage Per Process on Linux
ps -o pid,user,%mem,command ax | sort -b -k3 -r

#Checking Memory Usage of Processes with pmap:
sudo pmap 917

#How to monitor CPU/memory usage of a single process?
top -p PID



