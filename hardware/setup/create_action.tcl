#-----------------------------------------------------------
#
# Copyright 2016, International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#-----------------------------------------------------------

set root_dir   $::env(DONUT_HARDWARE_ROOT)
set fpga_part  $::env(FPGACHIP)
set action_dir $root_dir/action

create_project action $action_dir -part $fpga_part -force
set_property target_language VHDL [current_project]
create_bd_design "action"

#create memcopy IP
ipx::infer_core -vendor IP -library user -taxonomy /UserIP $action_dir/memcopy
ipx::edit_ip_in_project -upgrade true -name edit_ip_project -directory $action_dir/ip.tmp $action_dir/memcopy/component.xml
ipx::current_core $action_dir/memcopy/component.xml
update_compile_order -fileset sim_1
set_property display_name memcopy [ipx::current_core]
set_property description memcopy [ipx::current_core]
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
close_project -delete
set_property  ip_repo_paths  $action_dir/memcopy [current_project]
update_ip_catalog
create_bd_cell -type ip -vlnv IP:user:action_memcopy:1.0 memcopy_0


ipx::infer_core -vendor IP -library user -taxonomy /UserIP $action_dir/opencldesign
ipx::edit_ip_in_project -upgrade true -name edit_ip_project -directory $action_dir/ip.tmp $action_dir/opencldesign/component.xml
update_compile_order -fileset sim_1
set_property display_name opencldesign [ipx::current_core]
set_property description opencldesign [ipx::current_core]
set_property core_revision 2 [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axi_gmem -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif s_axi_control -clock ap_clk [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
close_project -delete

set_property  ip_repo_paths  $action_dir/opencldesign [current_project]
update_ip_catalog
create_bd_cell -type ip -vlnv IP:user:opencldesign_wrapper:1.0 opencldesign_wrapper_0

#create IOs
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi
set_property CONFIG.CLK_DOMAIN action_clk [get_bd_intf_ports s_axi]
startgroup
create_bd_port -dir I -type clk clk
set_property CONFIG.FREQ_HZ 250000000 [get_bd_ports clk]
endgroup
#create_bd_port -dir I -type rst ddr3_rst_n
#create_bd_port -dir I -type clk ddr3_clk
#set_property CONFIG.FREQ_HZ 200000000 [get_bd_ports ddr3_clk]
startgroup
create_bd_port -dir I -type rst rstn
endgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 c0_ddr3
set_property -dict [list CONFIG.ADDR_WIDTH {33} CONFIG.DATA_WIDTH {64}] [get_bd_intf_ports c0_ddr3]
set_property -dict [list CONFIG.DATA_WIDTH {128}] [get_bd_intf_ports c0_ddr3]
set_property CONFIG.ASSOCIATED_BUSIF {c0_ddr3} [get_bd_ports /clk]
#set_property CONFIG.ASSOCIATED_RESET {ddr3_rst_n} [get_bd_ports /ddr3_clk]
set_property CONFIG.ASSOCIATED_RESET {rstn} [get_bd_ports /clk]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi:m_axi} [get_bd_ports /clk]


#create interconnect_0
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
endgroup
set_property location {1 37 106} [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.NUM_MI {2}] [get_bd_cells axi_interconnect_0]



#AXI MASTER HOST MMIO Interface
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1
endgroup
set_property location {3.5 985 124} [get_bd_cells axi_interconnect_1]
set_property location {2.5 826 121} [get_bd_cells axi_interconnect_1]
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi
set_property CONFIG.ADDR_WIDTH 64 [get_bd_intf_ports m_axi]
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_1]
set_property CONFIG.DATA_WIDTH 128 [get_bd_intf_ports m_axi]
set_property CONFIG.CLK_DOMAIN action_clk [get_bd_intf_ports m_axi]
set_property CONFIG.HAS_REGION 0 [get_bd_intf_ports m_axi]
set_property CONFIG.NUM_READ_OUTSTANDING 2 [get_bd_intf_ports m_axi]
set_property CONFIG.NUM_WRITE_OUTSTANDING 2 [get_bd_intf_ports m_axi]
set_property CONFIG.MAX_BURST_LENGTH 1 [get_bd_intf_ports s_axi]
set_property CONFIG.ASSOCIATED_BUSIF {s_axi} [get_bd_ports /clk]
set_property CONFIG.SUPPORTS_NARROW_BURST 0 [get_bd_intf_ports s_axi]
set_property CONFIG.PROTOCOL AXI4LITE [get_bd_intf_ports s_axi]

#AXI MASTER HOST DMA Interface
connect_bd_intf_net [get_bd_intf_ports m_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/M00_AXI]
set_property location {1143 156} [get_bd_intf_ports m_axi]
set_property location {1143 114} [get_bd_intf_ports m_axi]
set_property location {1143 132} [get_bd_intf_ports m_axi]
connect_bd_intf_net [get_bd_intf_pins memcopy_0/m00_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins memcopy_0/s00_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/M00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/S00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/M00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/S00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_1/ARESETN]

#AXI MASTER DDR3 Interface
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_2
endgroup
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_2]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_2/ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_2/S00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins memcopy_0/m01_axi_aresetn]
#connect_bd_net [get_bd_ports ddr3_rst_n] [get_bd_pins axi_interconnect_2/M00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_2/M00_ARESETN]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_2/ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_2/S00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins memcopy_0/m01_axi_aclk]
#connect_bd_net [get_bd_ports ddr3_clk] [get_bd_pins axi_interconnect_2/M00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_2/M00_ACLK]
connect_bd_intf_net [get_bd_intf_pins memcopy_0/m01_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_2/S00_AXI]
#connect_bd_intf_net [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_ports c0_ddr3]

#AXI SLICE Register
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_register_slice:2.1 axi_register_slice_0
endgroup
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_2/M00_AXI] [get_bd_intf_pins axi_register_slice_0/S_AXI]
connect_bd_intf_net [get_bd_intf_ports c0_ddr3] [get_bd_intf_pins axi_register_slice_0/M_AXI]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_register_slice_0/aclk]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_register_slice_0/aresetn]

#connect
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_ports rstn] [get_bd_pins memcopy_0/m00_axi_aresetn]
connect_bd_net [get_bd_ports rstn] [get_bd_pins memcopy_0/s00_axi_aresetn]
connect_bd_intf_net [get_bd_intf_ports s_axi] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports clk] [get_bd_pins memcopy_0/m00_axi_aclk]
connect_bd_net [get_bd_ports clk] [get_bd_pins memcopy_0/s00_axi_aclk]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins opencldesign_wrapper_0/s_axi_control]
connect_bd_intf_net [get_bd_intf_pins opencldesign_wrapper_0/m_axi_gmem] -boundary_type upper [get_bd_intf_pins axi_interconnect_1/S01_AXI]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_1/S01_ACLK]
connect_bd_net [get_bd_pins axi_interconnect_1/S01_ARESETN] [get_bd_pins axi_interconnect_2/M00_ARESETN] -boundary_type upper
connect_bd_net [get_bd_ports clk] [get_bd_pins opencldesign_wrapper_0/ap_clk]
connect_bd_net [get_bd_ports rstn] [get_bd_pins opencldesign_wrapper_0/ap_rst_n]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_ports rstn] [get_bd_pins axi_interconnect_0/M01_ARESETN]

assign_bd_address
set_property range 4K [get_bd_addr_segs {s_axi/SEG_memcopy_0_reg0}]
set_property offset 0x00001000 [get_bd_addr_segs {s_axi/SEG_memcopy_0_reg0}]
set_property range 4K [get_bd_addr_segs {s_axi/SEG_opencldesign_wrapper_0_reg0}]
set_property offset 0x00000000 [get_bd_addr_segs {s_axi/SEG_opencldesign_wrapper_0_reg0}]
set_property range 512K [get_bd_addr_segs {memcopy_0/m01_axi/SEG_c0_ddr3_Reg}]
set_property offset 0x000000000 [get_bd_addr_segs {memcopy_0/m01_axi/SEG_c0_ddr3_Reg}]
set_property offset 0x0000000000000000 [get_bd_addr_segs {memcopy_0/m00_axi/SEG_m_axi_Reg}]
set_property range 8E [get_bd_addr_segs {memcopy_0/m00_axi/SEG_m_axi_Reg}]
set_property offset 0x0000000000000000 [get_bd_addr_segs {opencldesign_wrapper_0/m_axi_gmem/SEG_m_axi_Reg}]
set_property range 8E [get_bd_addr_segs {opencldesign_wrapper_0/m_axi_gmem/SEG_m_axi_Reg}]

save_bd_design

close_project



