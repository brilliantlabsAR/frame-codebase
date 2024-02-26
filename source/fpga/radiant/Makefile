.PHONY: lram jmems

all: lram jmems
	radiant frame.rdf

jmems:
	make -C jisp
lram:
	make -C image_buffer

clean:
	make clean -C jisp
	make clean -C image_buffer
