.PHONY: lram jmems jencmems

all: ip
	radiant frame.rdf

ip: lram jmems jencmems ht pll
jmems:
	make -C jisp
jencmems:
	make -C jenc
lram:
	make -C image_buffer
ht:
	make -C huffman_codes_rom

pll:
	make -C pll_ip
	make -C ../modules/camera/testbenches/csi/source/csi/pll_sim_ip

clean:
	make clean -C jisp
	make clean -C jenc
	make clean -C image_buffer
	make clean -C pll_ip
	make clean -C ht
	make clean -C ../modules/camera/testbenches/csi/source/csi/pll_sim_ip
