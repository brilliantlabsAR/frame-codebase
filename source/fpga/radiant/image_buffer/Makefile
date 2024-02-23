IP := -ip /opt/lscc/radiant/2023.2/ip/lifcl/large_ram_dp
VLNV := -vlnv latticesemi.com:module:large_ram_dp:1.2.0
IPGEN_FLAGS := $(VLNV) -sp "8_Low-Power_1.0V" -t "WLCSP72" -f "LIFCL" -p "LIFCL-17"

all: large_ram_dp/large_ram_dp.ipx large_ram_dp/rtl/large_ram_dp.v
%.v %.ipx: 
	if [ ! -d large_ram_dp ]; then \
		mkdir large_ram_dp ; \
	fi
	ipgenwrap -cfg large_ram_dp.cfg -name large_ram_dp -o large_ram_dp $(IPGEN_FLAGS)

clean:
	rm -rf large_ram_dp
