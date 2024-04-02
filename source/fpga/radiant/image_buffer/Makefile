IP := -ip /opt/lscc/radiant/2023.2/ip/lifcl/large_ram_dp_w32_d16k_q
VLNV := -vlnv latticesemi.com:module:large_ram_dp:1.2.0
IPGEN_FLAGS := $(VLNV) -sp "8_Low-Power_1.0V" -t "WLCSP72" -f "LIFCL" -p "LIFCL-17"

all: large_ram_dp_w32_d16k_q/large_ram_dp_w32_d16k_q.ipx large_ram_dp_w32_d16k_q/rtl/large_ram_dp_w32_d16k_q.v
%.v %.ipx: 
	if [ ! -d large_ram_dp_w32_d16k_q ]; then \
		mkdir large_ram_dp_w32_d16k_q ; \
	fi
	ipgenwrap -cfg large_ram_dp_w32_d16k_q.cfg -name large_ram_dp_w32_d16k_q -o large_ram_dp_w32_d16k_q $(IPGEN_FLAGS)

clean:
	rm -rf large_ram_dp_w32_d16k_q
