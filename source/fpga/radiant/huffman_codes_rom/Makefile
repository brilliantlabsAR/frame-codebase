#usage: ipgen [-h] [-o OUTPUT_DIR] [-proj_dir PROJ_DIR] [-ip IP_MODULE_DIR]
#             [-cfg IP_CONFIG_FILE] [-skip_uniquify SKIP_UNIQUIFY_HDL]
#             [-cfg_value IP_CONFIG_VALUE] -name IP_INSTANCE_NAME
#             [-platform IPGEN_PLATFORM] [-vlnv IPGEN_VLNV]
#             [-rtl_library_path RTL_LIBRARY_PATH] [-a ARCHITECTURE]
#             [-p DEVICE] [-t PACKAGE] [-sp PERFORMANCE] [-f FAMILY]
#
#Lattice soft IP generation engine.
M := huffman_codes_rom

IP := -ip /opt/lscc/radiant/2023.2/ip/common/rom
VLNV := -vlnv latticesemi.com:module:rom:2.4.0
IPGEN_FLAGS := $(VLNV) -sp "8_Low-Power_1.0V" -t "WLCSP72" -f "LIFCL" -p "LIFCL-17"

all: ipgen/$(M).ipx ipgen/rtl/$(M).v
%.v %.ipx: 
	if [ ! -d ipgen ]; then \
                mkdir ipgen; \
        fi;
	ipgenwrap -cfg $(M).cfg -name $(M) -o ipgen $(IPGEN_FLAGS)

clean:
	rm -rf ipgen
