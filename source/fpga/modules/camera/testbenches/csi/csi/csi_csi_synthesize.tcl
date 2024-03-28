if {[catch {

# define run engine funtion
source [file join {/opt/lscc/radiant/2023.2} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) 1
set para(prj_dir) "/home/rohit/Documents/csi"
# synthesize IPs
# synthesize VMs
# propgate constraints
file delete -force -- csi_csi_cpe.ldc
run_engine_newmsg cpe -f "csi_csi.cprj" "csi2_receiver_ip.cprj" "byte_to_pixel_ip.cprj" "pll_sim_ip.cprj" "csi2_transmitter_ip.cprj" "pixel_to_byte_ip.cprj" -a "LIFCL"  -o csi_csi_cpe.ldc
# synthesize top design
file delete -force -- csi_csi.vm csi_csi.ldc
run_engine_newmsg synthesis -f "csi_csi_lattice.synproj"
run_postsyn [list -a LIFCL -p LIFCL-17 -t WLCSP72 -sp 8_Low-Power_1.0V -oc Commercial -top -w -o csi_csi_syn.udb csi_csi.vm] [list /home/rohit/Documents/csi/csi/csi_csi.ldc]

} out]} {
   runtime_log $out
   exit 1
}
