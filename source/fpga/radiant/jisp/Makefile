#usage: ipgen [-h] [-o OUTPUT_DIR] [-proj_dir PROJ_DIR] [-ip IP_MODULE_DIR]
#             [-cfg IP_CONFIG_FILE] [-skip_uniquify SKIP_UNIQUIFY_HDL]
#             [-cfg_value IP_CONFIG_VALUE] -name IP_INSTANCE_NAME
#             [-platform IPGEN_PLATFORM] [-vlnv IPGEN_VLNV]
#             [-rtl_library_path RTL_LIBRARY_PATH] [-a ARCHITECTURE]
#             [-p DEVICE] [-t PACKAGE] [-sp PERFORMANCE] [-f FAMILY]
#
#Lattice soft IP generation engine.
#
#optional arguments:
#  -h, --help            show this help message and exit
#  -o OUTPUT_DIR         Location to generate IP instance package. (default is
#                        current directory)
#  -proj_dir PROJ_DIR    Location of Radiant Project, which owns generated IP
#                        instance package. (default is current directory)
#  -ip IP_MODULE_DIR     Location of IP module package
#  -cfg IP_CONFIG_FILE   Location of IP configuration file.
#  -skip_uniquify SKIP_UNIQUIFY_HDL
#                        Control weather uniquify hdl files: True/False.
#  -cfg_value IP_CONFIG_VALUE
#                        IP configuration value: 'id:value; id1:value1'.
#  -name IP_INSTANCE_NAME
#                        Name of IP instance package.
#  -platform IPGEN_PLATFORM
#                        Name of ipgen's runtime environment: Radiant or
#                        Propel, Default is Radiant.
#  -vlnv IPGEN_VLNV      Location of IP configuration file by vendor library
#                        name and version. Usage:
#                        'vendor:library:name:version'.
#  -rtl_library_path RTL_LIBRARY_PATH
#                        The Rtl library path for IP.
#  -a ARCHITECTURE       Target architecture name.
#  -p DEVICE             Target device name.
#  -t PACKAGE            Target package name.
#  -sp PERFORMANCE       Target performance name.
#  -f FAMILY             Target family name.

# Memories to generate:
JISP_MEMS := \
        ram_dp_w18_d360 \
        ram_dp_w64_b8_d2880 \
        ram_dp_w64_b8_d1440

JISP_TARGETS := $(foreach m,$(JISP_MEMS),$(m)/$(m).ipx) $(foreach m,$(JISP_MEMS),$(m)/rtl/$(m).v)

IP := -ip /opt/lscc/radiant/2023.2/ip/common/ram_dp
VLNV := -vlnv latticesemi.com:module:ram_dp:2.3.0
IPGEN_FLAGS := $(VLNV) -sp "8_Low-Power_1.0V" -t "WLCSP72" -f "LIFCL" -p "LIFCL-17"

all: $(JISP_TARGETS)
%.v %.ipx: 
	@echo $@ $(JISP_TARGETS)
	for m  in $(JISP_MEMS) ; do \
                if [ ! -d $$m ]; then \
                        mkdir $$m ; \
                fi; \
                ipgenwrap -cfg $$m.cfg -name $$m -o $$m $(IPGEN_FLAGS); \
        done

clean:
	rm -rf $(JISP_MEMS) jisp_tcr.dir reportview.xml

