#usage: ipgen [-h] [-o OUTPUT_DIR] [-proj_dir PROJ_DIR] [-ip IP_MODULE_DIR]
#             [-cfg IP_CONFIG_FILE] [-skip_uniquify SKIP_UNIQUIFY_HDL]
#             [-cfg_value IP_CONFIG_VALUE] -name IP_INSTANCE_NAME
#             [-platform IPGEN_PLATFORM] [-vlnv IPGEN_VLNV]
#             [-rtl_library_path RTL_LIBRARY_PATH] [-a ARCHITECTURE]
#             [-p DEVICE] [-t PACKAGE] [-sp PERFORMANCE] [-f FAMILY]
#
#Lattice soft IP generation engine.
IP := -ip /opt/lscc/radiant/2023.2/ip/common/ram_dp_true
VLNV := -vlnv latticesemi.com:module:ram_dp_true:2.2.0
IPGEN_FLAGS := $(VLNV) -sp "8_Low-Power_1.0V" -t "WLCSP72" -f "LIFCL" -p "LIFCL-17"

all: ram_dp_true_w16_d128/ram_dp_true_w16_d128.ipx ram_dp_true_w16_d128/rtl/ram_dp_true_w16_d128.v
%.v %.ipx: 
	if [ ! -d ram_dp_true_w16_d128 ]; then \
		mkdir ram_dp_true_w16_d128 ; \
	fi
	ipgenwrap -cfg ram_dp_true_w16_d128.cfg -name ram_dp_true_w16_d128 -o ram_dp_true_w16_d128 $(IPGEN_FLAGS)

clean:
	rm -rf ram_dp_true_w16_d128

