onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /generator_tb/DUT/clk
add wave -noupdate /generator_tb/DUT/reset_n
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_awaddr
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_awprot
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_awvalid
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_awready
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_wdata
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_wstrb
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_wvalid
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_wready
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_bresp
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_bvalid
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_bready
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_araddr
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_arprot
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_arvalid
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_arready
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_rdata
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_rresp
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_rvalid
add wave -noupdate -expand -group AXI-Lite /generator_tb/DUT/s_axil_rready
add wave -noupdate -expand -group axis /generator_tb/DUT/m_axis_tid_o
add wave -noupdate -expand -group axis /generator_tb/DUT/m_axis_tdata_o
add wave -noupdate -expand -group axis /generator_tb/DUT/m_axis_tvalid_o
add wave -noupdate -expand -group axis /generator_tb/DUT/m_axis_tlast_o
add wave -noupdate -expand -group axis /generator_tb/DUT/m_axis_tkeep_o
add wave -noupdate -expand -group axis /generator_tb/DUT/m_axis_tready_i
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_control
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_fixed_length
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_min_length
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_max_length
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_fixed_channel
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_min_channel
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_max_channel
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_fixed_pause
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_min_pause
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_max_pause
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_cnt_packet
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_start
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_stop
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_auto_length
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_auto_channel
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_auto_pause
add wave -noupdate -expand -group Internal /generator_tb/DUT/cntrl_use_limit_transaction
add wave -noupdate -expand -group Internal /generator_tb/DUT/descriptor_data_for_fifo
add wave -noupdate -expand -group Internal /generator_tb/DUT/descriptor_data_from_fifo
add wave -noupdate -expand -group Internal /generator_tb/DUT/descriptor_valid_for_fifo
add wave -noupdate -expand -group Internal /generator_tb/DUT/descriptor_valid_from_fifo
add wave -noupdate -expand -group Internal /generator_tb/DUT/descriptor_ready_for_fifo
add wave -noupdate -expand -group Internal /generator_tb/DUT/descriptor_ready_from_fifo
add wave -noupdate -expand -group Internal /generator_tb/DUT/lfsr_out
add wave -noupdate -expand -group Internal /generator_tb/DUT/pkt_length
add wave -noupdate -expand -group Internal /generator_tb/DUT/pkt_channel
add wave -noupdate -expand -group Internal /generator_tb/DUT/pkt_data
add wave -noupdate -expand -group Internal /generator_tb/DUT/pkt_pause
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1902328 ns} {1907025 ns}
