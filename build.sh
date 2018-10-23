#!/bin/sh

CC65_HOME=$HOME/cc65

$CC65_HOME/bin/cl65 -o seq_burst.bin --start-addr $1300 -t c128 -C c128-asm.cfg seq_burst.s
