#!/bin/bash

file=`basename  -s .s $1`
src="$file".s
bin="$file".bin

addr=`grep .org $src | awk '{ print $2 }'`
addr=`echo $addr | cut -d "$" -f 2 | awk '{ printf "%04x\n",strtonum("0x"$0)}'`

low=`echo ${addr:2:2}`
high=`echo ${addr:0:2}`

echo -n -e "\x$low\x$high" | dd conv=notrunc of=$bin

