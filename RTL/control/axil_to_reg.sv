/*
    0x0 - CONTROL:
        [0] - start
        [1] - stop
        [2] - auto_length
        [3] - auto_channel
        [4] - auto_pause
        [5] - use_limit_transaction
        [31:6] - RESERVED

    0x1 - FIXED LENGTH, 16 bit
    0x2 - MINIMAL LENGTH, 16 bit
    0x3 - MAXIMUM LENGTH, 16 bit
    0x4 - FIXED CHANNEL, 16 bit
    0x5 - MINIMAL CHANNEL, 16 bit
    0x6 - MAXIMUM CHANNEL, 16 bit
    0x7 - FIXED PAUSE, 32 bit
    0x8 - MINIMAL PAUSE, 32 bit
    0x9 - MAXIMUM PAUSE, 32 bit
    0xA - COUNT PACKET, 32 bit,
*/
module axil_to_reg #(
    parameter ID_WIDTH = 10
)(
    input bit clk,
    input bit reset_n,

//Avalon Interface
//write channel
    input   wire    [5:0]  	    s_axil_awaddr,
    input   wire    [2:0]       s_axil_awprot,
    input   wire                s_axil_awvalid,
    output  wire                s_axil_awready,
    input   wire    [31:0]  	s_axil_wdata,
    input   wire    [3:0]  	    s_axil_wstrb,
    input   wire                s_axil_wvalid,
    output  wire                s_axil_wready,
    output  wire    [1:0]       s_axil_bresp,
    output  wire                s_axil_bvalid,
    input   wire                s_axil_bready,
//read channel
    input   wire    [5:0]  	    s_axil_araddr,
    input   wire    [2:0]       s_axil_arprot,
    input   wire                s_axil_arvalid,
    output  wire                s_axil_arready,
    output  wire    [31:0]  	s_axil_rdata,
    output  wire    [1:0]       s_axil_rresp,
    output  wire                s_axil_rvalid,
    input   wire                s_axil_rready,
//register
    //control
    output  logic               cntrl_start_o,
    output  logic               cntrl_stop_o,
    output  logic               cntrl_auto_length_o,
    output  logic               cntrl_auto_channel_o,
    output  logic               cntrl_auto_pause_o,
    output  logic               cntrl_use_limit_transaction_o,

    output  logic   [15:0]      cntrl_fixed_length_o,
    output  logic   [15:0]      cntrl_min_length_o,
    output  logic   [15:0]      cntrl_max_length_o,
    
    output  logic   [ID_WIDTH-1:0] cntrl_fixed_channel_o,
    output  logic   [ID_WIDTH-1:0] cntrl_min_channel_o,
    output  logic   [ID_WIDTH-1:0] cntrl_max_channel_o,

    output  logic   [31:0]      cntrl_fixed_pause_o,
    output  logic   [31:0]      cntrl_min_pause_o,
    output  logic   [31:0]      cntrl_max_pause_o,

    output  logic   [31:0]      cntrl_cnt_packet_o  

);


/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************        DECLARATION         ************************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    bit                 write_transaction, read_transaction;//выставляется в момент активной транзакции (чтения или записи)
    bit     [31:0]      fixed_channel_register;
    bit     [31:0]      min_channel_reg, max_channel_reg;
    logic   [31:0]      cntrl_control;


    wire    [5:0]       reg_wr_addr;
    wire    [31:0]      reg_wr_data;
    wire    [3:0]       reg_wr_strb;
    wire                reg_wr_en;
    reg                 reg_wr_wait;
    reg                 reg_wr_ack;

    wire    [5:0]       reg_rd_addr;
    wire                reg_rd_en;
    reg     [31:0]      reg_rd_data;
    reg                 reg_rd_wait;
    reg                 reg_rd_ack;



    wire [3:0] wr_aligned_address = reg_wr_addr[5:2];
    wire [3:0] rd_aligned_address = reg_rd_addr[5:2];



    axil_reg_if #
    (
        // Width of data bus in bits
        .DATA_WIDTH(32),
        // Width of address bus in bits
        .ADDR_WIDTH(6),
        // Width of wstrb (width of data bus in words)
        .STRB_WIDTH(4),
        // Timeout delay (cycles)
        .TIMEOUT(10)
    ) axil_reg_if_inst (
        .clk                (clk                        ),
        .rst                (~reset_n                   ),

        /*
        * AXI-Lite slave interface
        */
    //write channel
        .s_axil_awaddr		(s_axil_awaddr              ),
        .s_axil_awprot		(s_axil_awprot              ),
        .s_axil_awvalid	    (s_axil_awvalid             ),
        .s_axil_awready	    (s_axil_awready             ),
        .s_axil_wdata		(s_axil_wdata               ),
        .s_axil_wstrb		(s_axil_wstrb               ),
        .s_axil_wvalid		(s_axil_wvalid              ),
        .s_axil_wready		(s_axil_wready              ),
        .s_axil_bresp		(s_axil_bresp               ),
        .s_axil_bvalid		(s_axil_bvalid              ),
        .s_axil_bready		(s_axil_bready              ),
    //read channel
        .s_axil_araddr		(s_axil_araddr              ),
        .s_axil_arprot		(s_axil_arprot              ),
        .s_axil_arvalid 	(s_axil_arvalid             ),
        .s_axil_arready	    (s_axil_arready             ),
        .s_axil_rdata		(s_axil_rdata               ),
        .s_axil_rresp		(s_axil_rresp               ),
        .s_axil_rvalid		(s_axil_rvalid              ),
        .s_axil_rready		(s_axil_rready              ),

    /*
    * Register interface
    */
        .reg_wr_addr        (reg_wr_addr                ),
        .reg_wr_data        (reg_wr_data                ),
        .reg_wr_strb        (reg_wr_strb                ),
        .reg_wr_en          (reg_wr_en                  ),
        .reg_wr_wait        (reg_wr_wait                ),
        .reg_wr_ack         (reg_wr_ack                 ),

        .reg_rd_addr        (reg_rd_addr                ),
        .reg_rd_en          (reg_rd_en                  ),
        .reg_rd_data        (reg_rd_data                ),
        .reg_rd_wait        (reg_rd_wait                ),
        .reg_rd_ack         (reg_rd_ack                 )
    );



/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/


//Memory-Mapped*************************************************************
    assign reg_wr_wait = 1'b0;
    assign reg_rd_wait = 1'b0;


    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) reg_wr_ack <= 1'b0;
        else if(reg_wr_ack) reg_wr_ack <= 1'b0;
        else reg_wr_ack <= reg_wr_en;
    end


//control transaction
//0x0 - control
    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) cntrl_control[31:2] <= 30'h0;
        else if(reg_wr_en && (wr_aligned_address == 4'h0) && reg_wr_ack) begin
            if(reg_wr_strb[3])  cntrl_control[31:24]   <= reg_wr_data[31:24];
            if(reg_wr_strb[2])  cntrl_control[23:16]   <= reg_wr_data[23:16];
            if(reg_wr_strb[1])  cntrl_control[15:8]    <= reg_wr_data[15:8];
            if(reg_wr_strb[0])  cntrl_control[7:2]     <= reg_wr_data[7:2];
        end
    end

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) cntrl_control[1:0] <= 2'h0;
        else if(reg_wr_en && (wr_aligned_address == 4'h0) && reg_wr_ack && reg_wr_strb[0]) cntrl_control[1:0] <= reg_wr_data[1:0];
        else cntrl_control[1:0] <= 2'h0;
    end

    assign cntrl_start_o                  = cntrl_control[0];
    assign cntrl_stop_o                   = cntrl_control[1];
    assign cntrl_auto_length_o            = cntrl_control[2];
    assign cntrl_auto_channel_o           = cntrl_control[3];
    assign cntrl_auto_pause_o             = cntrl_control[4];
    assign cntrl_use_limit_transaction_o  = cntrl_control[5];

//0x1 - fixed length
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'h1) && reg_wr_ack) begin
            if(reg_wr_strb[1]) cntrl_fixed_length_o[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) cntrl_fixed_length_o[7:0]   <= reg_wr_data[7:0];
        end
    end

//0x2 - cntrl_min_length
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'h2) && reg_wr_ack) begin 
            if(reg_wr_strb[1]) cntrl_min_length_o[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) cntrl_min_length_o[7:0]   <= reg_wr_data[7:0];
        end
    end

//0x3 - cntrl_min_length
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'h3) && reg_wr_ack) begin 
            if(reg_wr_strb[1]) cntrl_max_length_o[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) cntrl_max_length_o[7:0]   <= reg_wr_data[7:0];
        end
    end

//0x4 - fixed_channel_register
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'h4) && reg_wr_ack) begin
            if(reg_wr_strb[3]) fixed_channel_register[31:24] <= reg_wr_data[31:24];
            if(reg_wr_strb[2]) fixed_channel_register[23:16] <= reg_wr_data[23:16];
            if(reg_wr_strb[1]) fixed_channel_register[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) fixed_channel_register[7:0]   <= reg_wr_data[7:0];
        end    
    end
    assign cntrl_fixed_channel_o = fixed_channel_register[ID_WIDTH-1:0];

//0x5 - min_channel_reg
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'h5) && reg_wr_ack) begin 
            if(reg_wr_strb[3]) min_channel_reg[31:24] <= reg_wr_data[31:24];
            if(reg_wr_strb[2]) min_channel_reg[23:16] <= reg_wr_data[23:16];
            if(reg_wr_strb[1]) min_channel_reg[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) min_channel_reg[7:0]   <= reg_wr_data[7:0];
        end
    end
    assign cntrl_min_channel_o = min_channel_reg[ID_WIDTH-1:0];

//0x6 - max_channel_reg
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'h6) && reg_wr_ack) begin
            if(reg_wr_strb[3]) max_channel_reg[31:24] <= reg_wr_data[31:24];
            if(reg_wr_strb[2]) max_channel_reg[23:16] <= reg_wr_data[23:16];
            if(reg_wr_strb[1]) max_channel_reg[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) max_channel_reg[7:0]   <= reg_wr_data[7:0];
        end
    end
    assign cntrl_max_channel_o = max_channel_reg[ID_WIDTH-1:0];

//0x7 - cntrl_fixed_pause,
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'h7) && reg_wr_ack) begin 
            if(reg_wr_strb[3]) cntrl_fixed_pause_o[31:24] <= reg_wr_data[31:24];
            if(reg_wr_strb[2]) cntrl_fixed_pause_o[23:16] <= reg_wr_data[23:16];
            if(reg_wr_strb[1]) cntrl_fixed_pause_o[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) cntrl_fixed_pause_o[7:0]   <= reg_wr_data[7:0];
        end
    end

//0x8 - cntrl_min_pause,
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'h8) && reg_wr_ack) begin 
            if(reg_wr_strb[3]) cntrl_min_pause_o[31:24] <= reg_wr_data[31:24];
            if(reg_wr_strb[2]) cntrl_min_pause_o[23:16] <= reg_wr_data[23:16];
            if(reg_wr_strb[1]) cntrl_min_pause_o[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) cntrl_min_pause_o[7:0]   <= reg_wr_data[7:0];
        end
    end

//0x9 - cntrl_max_pause,
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'h9) && reg_wr_ack) begin
            if(reg_wr_strb[3]) cntrl_max_pause_o[31:24] <= reg_wr_data[31:24];
            if(reg_wr_strb[2]) cntrl_max_pause_o[23:16] <= reg_wr_data[23:16];
            if(reg_wr_strb[1]) cntrl_max_pause_o[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) cntrl_max_pause_o[7:0]   <= reg_wr_data[7:0];
        end
    end

//0xA - cntrl_cnt_packet
    always_ff @ (posedge clk) begin
        if(reg_wr_en && (wr_aligned_address == 4'hA) && reg_wr_ack) begin
            if(reg_wr_strb[3]) cntrl_cnt_packet_o[31:24] <= reg_wr_data[31:24];
            if(reg_wr_strb[2]) cntrl_cnt_packet_o[23:16] <= reg_wr_data[23:16];
            if(reg_wr_strb[1]) cntrl_cnt_packet_o[15:8]  <= reg_wr_data[15:8];
            if(reg_wr_strb[0]) cntrl_cnt_packet_o[7:0]   <= reg_wr_data[7:0];
        end 
    end
/*----------------------------------------------------------------------------*/
/*                              READ REGISTER                                 */
/*----------------------------------------------------------------------------*/

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) reg_rd_ack <= 1'b0;
        else if(reg_rd_ack) reg_rd_ack <= 1'b0;
        else reg_rd_ack <= reg_rd_en;
    end

    always_ff @ (posedge clk) begin
        reg_rd_data <= 32'h0;
        case(rd_aligned_address)
            4'h0:   reg_rd_data <= cntrl_control;
            4'h1:   reg_rd_data <= {16'h0, cntrl_fixed_length_o};
            4'h2:   reg_rd_data <= {16'h0, cntrl_min_length_o};
            4'h3:   reg_rd_data <= {16'h0, cntrl_max_length_o};
            4'h4:   reg_rd_data <= fixed_channel_register;
            4'h5:   reg_rd_data <= min_channel_reg;
            4'h6:   reg_rd_data <= max_channel_reg;
            4'h7:   reg_rd_data <= cntrl_fixed_pause_o;
            4'h8:   reg_rd_data <= cntrl_min_pause_o;
            4'h9:   reg_rd_data <= cntrl_max_pause_o;
            4'hA:   reg_rd_data <= cntrl_cnt_packet_o;
            default: reg_rd_data <= 32'h0;
        endcase
    end



    //assertion
    //check stable register
    //unknown
    SVA_CHECK_UNKNOWN_CONTROL: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o |-> !$isunknown(cntrl_control)
    ) else $error("SVA error: control register is unknown");

    SVA_CHECK_UNKNOWN_LENGTH: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o |-> !$isunknown({cntrl_fixed_length_o, cntrl_min_length_o, cntrl_max_length_o})
    ) else $error("SVA error: one of registers of length has unknown value");

    SVA_CHECK_UNKNOWN_CHANNEL: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o |-> !$isunknown({cntrl_fixed_channel_o, cntrl_min_channel_o, cntrl_max_channel_o})
    ) else $error("SVA error: one of registers of channel has unknown value");

    SVA_CHECK_UNKNOWN_PAUSE: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o |-> !$isunknown({cntrl_fixed_pause_o, cntrl_min_pause_o, cntrl_max_pause_o})
    ) else $error("SVA error: one of registers of pause has unknown value");

    SVA_CHECK_UNKNOWN_CNT_PACKET: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o |-> !$isunknown(cntrl_cnt_packet_o)
    ) else $error("SVA error: the register of quantity of packets has unknown value");

    //zero length and cnt transaction
    SVA_CHECK_START_LENGTH: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o |-> !cntrl_auto_length_o & (cntrl_fixed_length_o > 0) | cntrl_auto_length_o & (cntrl_min_length_o > 0) & (cntrl_max_length_o > 0)
    ) else $error("SVA error: at start the register of length has null value");

    SVA_CHECK_START_CNT_PACKET: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o & cntrl_use_limit_transaction_o |-> (cntrl_cnt_packet_o > 0) 
    ) else $error("SVA error: at start the register of cnt_packet has null value");

    //check min and max values
    SVA_CHECK_MINMAX_LENGTH: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o |-> (cntrl_max_length_o > cntrl_min_length_o)
    ) else $error("SVA error: the minimum value of length is more than maximum");
    
    SVA_CHECK_MINMAX_CHANNEL: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o |-> (cntrl_max_channel_o > cntrl_min_channel_o)
    ) else $error("SVA error: the minimum value of channel is more than maximum");

    SVA_CHECK_MINMAX_PAUSE: assert property (
        @(posedge clk) disable iff(!reset_n)
        cntrl_start_o |-> (cntrl_max_pause_o > cntrl_min_pause_o)
    ) else $error("SVA error: the minimum value of channel is more than maximum");
    

endmodule