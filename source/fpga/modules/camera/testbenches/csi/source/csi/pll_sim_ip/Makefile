IP := -ip /opt/lscc/radiant/2023.2/ip/lifcl/pll
VLNV := -vlnv latticesemi.com:module:pll:1.8.0
IPGEN_FLAGS := $(VLNV) -sp "8_Low-Power_1.0V" -t "WLCSP72" -f "LIFCL" -p "LIFCL-17"

all: ./pll_sim_ip.ipx ./rtl/pll_sim_ip.v
%.v %.ipx: 
	ipgenwrap -cfg pll_sim_ip.cfg -name pll_sim_ip -o . $(IPGEN_FLAGS)

clean:
	rm -rf $(filter-out Makefile pll_sim_ip.cfg pll_sim_ip.ipx component.xml design.xml,$(shell ls))
