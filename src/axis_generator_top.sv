/*
    0x0 - CONTROL:
        [0] - start - запуск процесса генерации пакетов, бит автоматически сбрасывется после установки
        [1] - stop - остановка процесса генерации пакетов, бит автоматически сбрасывется после установки
        [2] - auto_length - автоматическая генерация длины пакетов (в пределах от MINIMAL LENGTH до MAXIMUM LENGTH), в противном случае длина всегда равна <FIXED LENGTH>
        [3] - auto_channel - автоматическая генерация номера канала (в пределах от MINIMAL CHANNEL до MAXIMUM CHANNEL), в противном случае номер канала всегда <FIXED CHANNEL>
        [4] - auto_pause - автоматическая генерация паузы между пакетами (в пределах от MINIMAL PAUSE до MAXIMUM PAUSE), в противном случае пауза между пакетами всегда <FIXED PAUSE>
        [5] - use_limit_transaction - генерировать заданное количество пакетов и останавливать генерацию
        [31:6] - RESERVED

    0x1 - FIXED LENGTH, 16 bit, выражается в байтах
    0x2 - MINIMAL LENGTH, 16 bit, выражается в байтах
    0x3 - MAXIMUM LENGTH, 16 bit, выражается в байтах
    0x4 - FIXED CHANNEL, 16 bit
    0x5 - MINIMAL CHANNEL, 16 bit
    0x6 - MAXIMUM CHANNEL, 16 bit
    0x7 - FIXED PAUSE, 32 bit, выражается в количестве периодов тактовой частоты
    0x8 - MINIMAL PAUSE, 32 bit, выражается в количестве периодов тактовой частоты
    0x9 - MAXIMUM PAUSE, 32 bit, выражается в количестве периодов тактовой частоты
    0xA - COUNT PACKET, 32 bit,

*/
module axis_generator_top #(
    parameter ID_WIDTH = 10,
    parameter DATA_WIDTH = 32,
    parameter TKEEP_WIDTH = DATA_WIDTH/8
) (
    input   bit                             clk,
    input   bit                             reset_n,

//AXILite Interface
//write channel
    input   wire    [5:0]  	                s_axil_awaddr,
    input   wire    [2:0]                   s_axil_awprot,
    input   wire                            s_axil_awvalid,
    output  wire                            s_axil_awready,
    input   wire    [31:0]  	            s_axil_wdata,
    input   wire    [3:0]  	                s_axil_wstrb,
    input   wire                            s_axil_wvalid,
    output  wire                            s_axil_wready,
    output  wire    [1:0]                   s_axil_bresp,
    output  wire                            s_axil_bvalid,
    input   wire                            s_axil_bready,
//read channel
    input   wire    [5:0]  	                s_axil_araddr,
    input   wire    [2:0]                   s_axil_arprot,
    input   wire                            s_axil_arvalid,
    output  wire                            s_axil_arready,
    output  wire    [31:0]  	            s_axil_rdata,
    output  wire    [1:0]                   s_axil_rresp,
    output  wire                            s_axil_rvalid,
    input   wire                            s_axil_rready,


    output  bit     [ID_WIDTH-1:0]          m_axis_tid_o,
    output  bit     [DATA_WIDTH-1:0]        m_axis_tdata_o,
    output  bit                             m_axis_tvalid_o,
    output  bit                             m_axis_tlast_o,
    output  bit     [TKEEP_WIDTH-1:0]       m_axis_tkeep_o,
    input   bit                             m_axis_tready_i
);


/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

//control
    bit     [31:0]              cntrl_control;
    bit     [15:0]              cntrl_fixed_length;
    bit     [15:0]              cntrl_min_length;
    bit     [15:0]              cntrl_max_length;
    
    bit     [ID_WIDTH-1:0]      cntrl_fixed_channel;
    bit     [ID_WIDTH-1:0]      cntrl_min_channel;
    bit     [ID_WIDTH-1:0]      cntrl_max_channel;

    bit     [31:0]              cntrl_fixed_pause;
    bit     [31:0]              cntrl_min_pause;
    bit     [31:0]              cntrl_max_pause;

    bit     [31:0]              cntrl_cnt_packet;

    wire                        cntrl_start;
    wire                        cntrl_stop;
    wire                        cntrl_auto_length;
    wire                        cntrl_auto_channel;
    wire                        cntrl_auto_pause;
    wire                        cntrl_use_limit_transaction;

    //descriptor to fifo
    wire    [48+ID_WIDTH-1:0]   descriptor_data_for_fifo, descriptor_data_from_fifo;
    wire                        descriptor_valid_for_fifo, descriptor_valid_from_fifo;
    wire                        descriptor_ready_for_fifo, descriptor_ready_from_fifo;



//pseudo random generator
    bit     [511:0]             lfsr_out;
    bit     [15:0]              pkt_length;
    bit     [ID_WIDTH-1:0]      pkt_channel;
    bit     [DATA_WIDTH-1:0]    pkt_data;
    bit     [31:0]              pkt_pause;

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            INSTANCE         ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    genaxis_axil_to_reg #(
        .ID_WIDTH(ID_WIDTH)
    ) axil_to_reg_inst (
        .clk                            (clk),
        .reset_n                        (reset_n),

    //write channel
        .s_axil_awaddr		            (s_axil_awaddr),
        .s_axil_awprot		            (s_axil_awprot),
        .s_axil_awvalid	                (s_axil_awvalid),
        .s_axil_awready	                (s_axil_awready),
        .s_axil_wdata		            (s_axil_wdata),
        .s_axil_wstrb		            (s_axil_wstrb),
        .s_axil_wvalid		            (s_axil_wvalid),
        .s_axil_wready		            (s_axil_wready),
        .s_axil_bresp		            (s_axil_bresp),
        .s_axil_bvalid		            (s_axil_bvalid),
        .s_axil_bready		            (s_axil_bready),
    //read channel
        .s_axil_araddr		            (s_axil_araddr),
        .s_axil_arprot		            (s_axil_arprot),
        .s_axil_arvalid 	            (s_axil_arvalid),
        .s_axil_arready	                (s_axil_arready),
        .s_axil_rdata		            (s_axil_rdata),
        .s_axil_rresp		            (s_axil_rresp),
        .s_axil_rvalid		            (s_axil_rvalid),
        .s_axil_rready		            (s_axil_rready),

    //register
        .cntrl_start_o                  (cntrl_start),
        .cntrl_stop_o                   (cntrl_stop),
        .cntrl_auto_length_o            (cntrl_auto_length),
        .cntrl_auto_channel_o           (cntrl_auto_channel),
        .cntrl_auto_pause_o             (cntrl_auto_pause),
        .cntrl_use_limit_transaction_o  (cntrl_use_limit_transaction),

        .cntrl_fixed_length_o           (cntrl_fixed_length),
        .cntrl_min_length_o             (cntrl_min_length),
        .cntrl_max_length_o             (cntrl_max_length),
        
        .cntrl_fixed_channel_o          (cntrl_fixed_channel),
        .cntrl_min_channel_o            (cntrl_min_channel),
        .cntrl_max_channel_o            (cntrl_max_channel),

        .cntrl_fixed_pause_o            (cntrl_fixed_pause),
        .cntrl_min_pause_o              (cntrl_min_pause),
        .cntrl_max_pause_o              (cntrl_max_pause),

        .cntrl_cnt_packet_o             (cntrl_cnt_packet)
    );



    genaxis_lfsr_generator #(
        .ID_WIDTH   (ID_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) lfsr_generator_inst (
        .clk                            (clk),
        .reset_n                        (reset_n),
        
        .cntrl_min_length_i             (cntrl_min_length),
        .cntrl_max_length_i             (cntrl_max_length),

        .cntrl_min_channel_i            (cntrl_min_channel),
        .cntrl_max_channel_i            (cntrl_max_channel),

        .cntrl_min_pause_i              (cntrl_min_pause),
        .cntrl_max_pause_i              (cntrl_max_pause),

        .lfsr_out_o                     (lfsr_out),
        .pkt_length_o                   (pkt_length),
        .pkt_channel_o                  (pkt_channel),
        .pkt_data_o                     (pkt_data),
        .pkt_pause_o                    (pkt_pause)
    );


    genaxis_generator_descriptor #(
        .ID_WIDTH(ID_WIDTH)
    ) generator_descriptor_inst (
        .clk                            (clk),
        .reset_n                        (reset_n),
    
    //register
        .cntrl_start_i                  (cntrl_start),
        .cntrl_stop_i                   (cntrl_stop),
        .cntrl_auto_length_i            (cntrl_auto_length),
        .cntrl_auto_channel_i           (cntrl_auto_channel),
        .cntrl_auto_pause_i             (cntrl_auto_pause),
        .cntrl_use_limit_transaction_i  (cntrl_use_limit_transaction),
        
        
        .cntrl_fixed_length_i           (cntrl_fixed_length),
        .cntrl_min_length_i             (cntrl_min_length),
        .cntrl_max_length_i             (cntrl_max_length),
        
        .cntrl_fixed_channel_i          (cntrl_fixed_channel),
        .cntrl_min_channel_i            (cntrl_min_channel),
        .cntrl_max_channel_i            (cntrl_max_channel),
    
        .cntrl_fixed_pause_i            (cntrl_fixed_pause),
        .cntrl_min_pause_i              (cntrl_min_pause),
        .cntrl_max_pause_i              (cntrl_max_pause),
    
        .cntrl_cnt_packet_i             (cntrl_cnt_packet),
        
    //input data from lfsr generator
        .pkt_length_i                   (pkt_length),
        .pkt_channel_i                  (pkt_channel),
        .pkt_pause_i                    (pkt_pause),
    
    //output descriptor
        .descriptor_data_o              (descriptor_data_for_fifo),//{channel, pause[15:0], length[15:0]}
        .descriptor_valid_o             (descriptor_valid_for_fifo),
        .descriptor_ready_i             (descriptor_ready_for_fifo) 
    
    );


    genaxis_axis_fifo #(
        .T_DATA_WIDTH(48+ID_WIDTH),
        .SIZE(2048)
    ) descriptor_buffer_inst (
        .clk            (clk),
        .reset_n        (reset_n),
    
        //input stream
        .s_data_i       (descriptor_data_for_fifo),//{channel, pause[15:0], length[15:0]}
        .s_valid_i      (descriptor_valid_for_fifo),
        .s_ready_o      (descriptor_ready_for_fifo),
    
        //output stream
        .m_data_o       (descriptor_data_from_fifo),//{channel, pause[15:0], length[15:0]}
        .m_valid_o      (descriptor_valid_from_fifo),
        .m_ready_i      (descriptor_ready_from_fifo),
    
        .fifo_empty_o   (),
        .fifo_full_o    ()
    );

    genaxis_descriptor_to_axis #(
        .ID_WIDTH   (ID_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) descriptor_to_axis_inst (
        .clk                    (clk),
        .reset_n                (reset_n),
    
        .psrand_data_i          (pkt_data),

    //input descriptor
        .in_descriptor_data_i   (descriptor_data_from_fifo),//{channel, pause[31:0], length[15:0]}
        .in_descriptor_valid_i  (descriptor_valid_from_fifo),
        .in_descriptor_ready_o  (descriptor_ready_from_fifo),
    
    //Avalon-ST Interface
        .m_axis_tid_o           (m_axis_tid_o),
        .m_axis_tdata_o         (m_axis_tdata_o),
        .m_axis_tvalid_o        (m_axis_tvalid_o),
        .m_axis_tlast_o         (m_axis_tlast_o),
        .m_axis_tkeep_o         (m_axis_tkeep_o),
        .m_axis_tready_i        (m_axis_tready_i)
    );


/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    
endmodule