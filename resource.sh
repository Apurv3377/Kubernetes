#!/bin/bash



alias util='kubectl get nodes --no-headers | awk '\''{print $1}'\'' | xargs -I {} sh -c '\''echo {} ; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo '\'''

#util
a=$1
b=$2
f=$3
c="cpu"
d="mem"
e="req"
g="lim"
h=$4
i="per"

if [ "$#" -eq 0 ]
then
util
fi

if [ "$#" -eq 1 ]
then
util | grep $1 -A 3
fi

if [ "$b" = "$c" ] && [ "$#" -eq 2 ]
then
util | grep $1 -A 3 |awk 'NR==2 || NR==3 || NR==1 {print $0}'
fi

if [ "$b" = "$d" ] && [ "$#" -eq 2 ]
then
util | grep $1 -A 3 |awk 'NR==2 || NR==4 || NR==1 {print $0}'
fi

if [ "$f" = "$e" ] && [ "$b" = "$c" ] && [ "$#" -eq 3 ]
then
util | grep $1 -A 3 | grep cpu| awk '{print $2 $3}'
fi

if [ "$f" = "$g" ] && [ "$b" = "$c" ] && [ "$#" -eq 3 ]
then
util | grep $1 -A 3 | grep cpu| awk '{print $4 $5}'
fi

if [ "$f" = "$e" ] && [ "$b" = "$d" ] && [ "$#" -eq 3 ]
then
util | grep $1 -A 3 | grep mem| awk '{print $2 $3}'
fi

if [ "$f" = "$g" ] && [ "$b" = "$d" ] && [ "$#" -eq 3 ]
then
util | grep $1 -A 3 | grep mem| awk '{print $4 $5}'
fi

if [ "$h" = "$i" ] && [ "$#" -eq 4 ]
then
sh $0 $1 $2 $3 | sed 's/.*(\(.*\))/\1/' | tr -d '%'
fi

if [ "$1" = "help" ] || [ "$1" = "h" ]
then
echo  'Usage : '
echo  'sh resource.sh [node] [cpu/mem] [req/lim] [per]'
echo  'req : Requests, lim : Limits, per : Percentage'
fi

