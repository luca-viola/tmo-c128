SHELL=/bin/bash

ifdef CC65_HOME
  CL = $(CC65_HOME)/bin/cl65
else
  CL := $(if $(wildcard ../bin/cl65*),../bin/cl65,cl65)
endif

SRC=seq_burst.s #File sorgente
ADDR='0x1300'

seq_burst.bin: $(SRC)
	$(CL) --start-addr $(ADDR) -t c128 -C c128-asm.cfg -o $@ $<

#target "clean" pulisce i file oggetto e il binario nella directory corrente 
clean:
	rm -f seq_burst.bin seq_burst.o

#target "clean" non è un file!
.PHONY: clean
