module genaxis_lfsr_generator #(
    parameter ID_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
        input logic clk,
        input logic reset_n,

        input   bit     [15:0]              cntrl_min_length_i,
        input   bit     [15:0]              cntrl_max_length_i,

        input   bit     [ID_WIDTH-1:0]      cntrl_min_channel_i,
        input   bit     [ID_WIDTH-1:0]      cntrl_max_channel_i,

        input   bit     [31:0]              cntrl_min_pause_i,
        input   bit     [31:0]              cntrl_max_pause_i,

        output logic    [511:0]             lfsr_out_o,
        output logic    [15:0]              pkt_length_o,
        output logic    [ID_WIDTH-1:0]      pkt_channel_o,
        output logic    [DATA_WIDTH-1:0]    pkt_data_o,
        output logic    [31:0]              pkt_pause_o

    );

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    (* keep *) logic [511:0] lfsr_0;
    (* keep *) logic [511:0] lfsr_1;
    
    
    function bit [DATA_WIDTH-1:0] mixed_data (bit [511:0] data_0, bit [511:0] data_1);
        bit [DATA_WIDTH-1:0] result;
        for(int i = 0; i < DATA_WIDTH; i++) result[i] = data_0[i] ^ data_1[(i+256)%512];
        return result;
    endfunction
        


    bit    [15:0]               pkt_length_prepare, pkt_length_thermo;
    bit    [ID_WIDTH-1:0]       pkt_channel_prepare, pkt_channel_thermo;
    bit    [31:0]               pkt_pause_prepare, pkt_pause_thermo;



/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            INSTANCE         ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    genaxis_utils #(.W(16))         utils_length  (cntrl_max_length_i, pkt_length_thermo);
    genaxis_utils #(.W(ID_WIDTH))   utils_channel (cntrl_max_channel_i, pkt_channel_thermo);
    genaxis_utils #(.W(32))         utils_pause   (cntrl_max_pause_i, pkt_pause_thermo);
    
/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    //период данного регистра оценивается в 2^512 (отводы брались из статьи)
    /*
    Table of Linear Feedback Shift Registers
    Roy Ward, Tim Molteno
    October 26, 2007
    */
    
    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) lfsr_0 <= '1;
        else begin 
            lfsr_0[511] <= lfsr_0[0];
            lfsr_0[510] <= lfsr_0[511];
            lfsr_0[509] <= lfsr_0[510] ^ lfsr_0[0];
            lfsr_0[508] <= lfsr_0[509];
            lfsr_0[507] <= lfsr_0[508];
            lfsr_0[506] <= lfsr_0[507] ^ lfsr_0[0];
            lfsr_0[505] <= lfsr_0[506];
            lfsr_0[504] <= lfsr_0[505];
            lfsr_0[503] <= lfsr_0[504] ^ lfsr_0[0];
            for(int i = 502; i > -1; i--) lfsr_0[i] <= lfsr_0[i+1];
        end
    end

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) lfsr_1 <= 512'h10;
        else begin 
            lfsr_1[511] <= lfsr_1[0];
            lfsr_1[510] <= lfsr_1[511];
            lfsr_1[509] <= lfsr_1[510] ^ lfsr_1[0];
            lfsr_1[508] <= lfsr_1[509];
            lfsr_1[507] <= lfsr_1[508];
            lfsr_1[506] <= lfsr_1[507] ^ lfsr_1[0];
            lfsr_1[505] <= lfsr_1[506];
            lfsr_1[504] <= lfsr_1[505];
            lfsr_1[503] <= lfsr_1[504] ^ lfsr_1[0];
            for(int i = 502; i > -1; i--) lfsr_1[i] <= lfsr_1[i+1];
        end
    end



    assign lfsr_out_o = lfsr_0 ^ lfsr_1;
    assign pkt_data_o = mixed_data(lfsr_0, lfsr_1);


    always_ff @ (posedge clk) begin
        pkt_length_prepare   <= { lfsr_0[128] ^ lfsr_1[128], lfsr_0[120] ^ lfsr_1[119], lfsr_0[112] ^ lfsr_1[110], lfsr_0[104] ^ lfsr_1[101], lfsr_0[96] ^ lfsr_1[91], lfsr_0[88] ^ lfsr_1[83], lfsr_0[80] ^ lfsr_1[73], lfsr_0[72] ^ lfsr_1[67], 
                                lfsr_0[64] ^ lfsr_1[53], lfsr_0[56] ^ lfsr_1[55], lfsr_0[48] ^ lfsr_1[41], lfsr_0[40] ^ lfsr_1[37], lfsr_0[32] ^ lfsr_1[29], lfsr_0[24] ^ lfsr_1[23], lfsr_0[16] ^ lfsr_1[13], lfsr_0[8] ^ lfsr_1[3]};
        pkt_channel_prepare  <= lfsr_0[384+:ID_WIDTH] ^ lfsr_1[384+:ID_WIDTH];
        pkt_pause_prepare    <= lfsr_0[415:384] ^ lfsr_1[415:384];
    end

    always_ff @ (posedge clk) begin
        pkt_length_o  <= pkt_length_prepare     &   pkt_length_thermo;//маскируем старшие биты, которые дадут нам заведомо превосходящую заданный диапазон длину
        pkt_channel_o <= pkt_channel_prepare    &   pkt_channel_thermo;
        pkt_pause_o   <= pkt_pause_prepare      &   pkt_pause_thermo;
    end

    endmodule 