SHELL=/bin/bash

ifdef CC65_HOME
  CL = $(CC65_HOME)/bin/cl65
else
  CL := $(if $(wildcard ../bin/cl65*),../bin/cl65,cl65)
endif

SRCS=seq_burst.s #File sorgente

seq_burst.bin: $(SRCS)
	$(CL) --start-addr $1300 -t c128 -C c128-asm.cfg -o $@ $<
	echo -n -e '\x00\x13' > loadaddr
	dd conv=notrunc if=loadaddr of=seq_burst.bin

#target "clean" pulisce i file oggetto e il binario nella directory corrente 
clean:
	rm -f seq_burst.bin seq_burst.o

#target "clean" non è un file!
.PHONY: clean
