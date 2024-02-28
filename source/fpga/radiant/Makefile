.PHONY: lram jmems jencmems

all: lram jmems jencmems
	radiant frame.rdf

jmems:
	make -C jisp
jencmems:
	make -C jenc
lram:
	make -C image_buffer

clean:
	make clean -C jisp
	make clean -C jenc
	make clean -C image_buffer
