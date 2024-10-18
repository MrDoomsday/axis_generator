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
        for(int i = 0; i < DATA_WIDTH; i++) result[i] = data_0[i] ^ data_1[DATA_WIDTH-1-i];
        return result;
    endfunction
        


    bit    [15:0]               pkt_length_prepare, pkt_length_thermo;
    bit    [ID_WIDTH-1:0]       pkt_channel_prepare, pkt_channel_thermo;
    bit    [31:0]               pkt_pause_prepare, pkt_pause_thermo;
    bit    [31:0]               pkt_channel_max;


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
        if(!reset_n) lfsr_1 <= 512'hFFFFFFFFFFFFFFFFF10101010101010101010011111010101010;
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

    assign pkt_channel_max = {  lfsr_0[12]  ^ lfsr_1[25], lfsr_0[128] ^ lfsr_1[121], //[15]
                                lfsr_0[198] ^ lfsr_1[21], lfsr_0[120] ^ lfsr_1[118], //[14]
                                lfsr_0[199] ^ lfsr_1[89], lfsr_0[113] ^ lfsr_1[19],  //[13]
                                lfsr_0[9]   ^ lfsr_1[12], lfsr_0[199] ^ lfsr_1[112], //[12]
                                lfsr_0[3]   ^ lfsr_1[197],lfsr_0[96]  ^ lfsr_1[190], //[11]
                                lfsr_0[1]   ^ lfsr_1[65], lfsr_0[85]  ^ lfsr_1[182], //[10]
                                lfsr_0[2]   ^ lfsr_1[234],lfsr_0[80]  ^ lfsr_1[172], //[9]
                                lfsr_0[297] ^ lfsr_1[76], lfsr_0[79]  ^ lfsr_1[166], //[8]
                                lfsr_0[477] ^ lfsr_1[18], lfsr_0[63]  ^ lfsr_1[151], //[7]
                                lfsr_0[410] ^ lfsr_1[24], lfsr_0[54]  ^ lfsr_1[150], //[6]
                                lfsr_0[359] ^ lfsr_1[5],  lfsr_0[46]  ^ lfsr_1[400], //[5]
                                lfsr_0[415] ^ lfsr_1[38], lfsr_0[40]  ^ lfsr_1[360], //[4]
                                lfsr_0[501] ^ lfsr_1[86], lfsr_0[311] ^ lfsr_1[280], //[3]
                                lfsr_0[187] ^ lfsr_1[7],  lfsr_0[203] ^ lfsr_1[220], //[2]
                                lfsr_0[378] ^ lfsr_1[39], lfsr_0[105] ^ lfsr_1[120], //[1]
                                lfsr_0[399] ^ lfsr_1[19], lfsr_0[70]  ^ lfsr_1[20]   //[0]
                            };
    

    always_ff @ (posedge clk) begin
        pkt_length_prepare   <= { lfsr_0[128] ^ lfsr_1[500], //[15]
                                  lfsr_0[120] ^ lfsr_1[350], //[14]
                                  lfsr_0[112] ^ lfsr_1[390], //[13]
                                  lfsr_0[104] ^ lfsr_1[101], //[12]
                                  lfsr_0[96] ^ lfsr_1[80],   //[11]
                                  lfsr_0[88] ^ lfsr_1[250],   //[10]
                                  lfsr_0[80] ^ lfsr_1[302],   //[9]
                                  lfsr_0[72] ^ lfsr_1[187],   //[8]
                                  lfsr_0[64] ^ lfsr_1[17],   //[7]
                                  lfsr_0[56] ^ lfsr_1[67],   //[6]
                                  lfsr_0[48] ^ lfsr_1[81],   //[5]
                                  lfsr_0[40] ^ lfsr_1[189],   //[4]
                                  lfsr_0[32] ^ lfsr_1[367],   //[3]
                                  lfsr_0[24] ^ lfsr_1[234],   //[2]
                                  lfsr_0[16] ^ lfsr_1[499],   //[1]
                                  lfsr_0[8] ^ lfsr_1[222]      //[0]
                                };

        //предусмотреть рандомизацию канала
        pkt_channel_prepare  <= pkt_channel_max[ID_WIDTH-1:0];//мы забираем столько, сколько требует ширина канала


        pkt_pause_prepare    <= { lfsr_0[256] ^ lfsr_1[256], lfsr_0[127] ^ lfsr_1[127], //[15]
                                  lfsr_0[230] ^ lfsr_1[211], lfsr_0[119] ^ lfsr_1[118], //[14]
                                  lfsr_0[199] ^ lfsr_1[89],  lfsr_0[111] ^ lfsr_1[109], //[13]
                                  lfsr_0[99]  ^ lfsr_1[12],  lfsr_0[103] ^ lfsr_1[100], //[12]
                                  lfsr_0[31]  ^ lfsr_1[197], lfsr_0[95]  ^ lfsr_1[90],  //[11]
                                  lfsr_0[17]  ^ lfsr_1[65],  lfsr_0[84]  ^ lfsr_1[82],  //[10]
                                  lfsr_0[2]   ^ lfsr_1[234], lfsr_0[79]  ^ lfsr_1[72],  //[9]
                                  lfsr_0[286] ^ lfsr_1[76],  lfsr_0[78]  ^ lfsr_1[66],  //[8]
                                  lfsr_0[237] ^ lfsr_1[182], lfsr_0[63]  ^ lfsr_1[52],  //[7]
                                  lfsr_0[382] ^ lfsr_1[245], lfsr_0[55]  ^ lfsr_1[54],  //[6]
                                  lfsr_0[28]  ^ lfsr_1[55],  lfsr_0[47]  ^ lfsr_1[40],  //[5]
                                  lfsr_0[10]  ^ lfsr_1[387], lfsr_0[39]  ^ lfsr_1[36],  //[4]
                                  lfsr_0[94]  ^ lfsr_1[86],  lfsr_0[31]  ^ lfsr_1[28],  //[3]
                                  lfsr_0[39]  ^ lfsr_1[70],  lfsr_0[23]  ^ lfsr_1[22],  //[2]
                                  lfsr_0[148] ^ lfsr_1[35],  lfsr_0[15]  ^ lfsr_1[12],  //[1]
                                  lfsr_0[123] ^ lfsr_1[17],  lfsr_0[7]   ^ lfsr_1[2]    //[0]
                                };
    end

    always_ff @ (posedge clk) begin
        pkt_length_o  <= pkt_length_prepare     &   pkt_length_thermo;//маскируем старшие биты, которые дадут нам заведомо превосходящую заданный диапазон длину
        pkt_channel_o <= pkt_channel_prepare    &   pkt_channel_thermo;
        pkt_pause_o   <= pkt_pause_prepare      &   pkt_pause_thermo;
    end

    endmodule 