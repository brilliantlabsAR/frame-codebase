.PHONY: lram jmems jencmems

all: ip
	radiant frame.rdf

ip: lram jmems jencmems pll
jmems:
	make -C jisp
jencmems:
	make -C jenc
lram:
	make -C image_buffer

pll:
	make -C pll_ip

clean:
	make clean -C jisp
	make clean -C jenc
	make clean -C image_buffer
	make clean -C pll_ip
