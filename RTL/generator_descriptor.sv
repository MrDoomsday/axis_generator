module generator_descriptor #(
    parameter ID_WIDTH = 10
)(
    input   bit             clk,
    input   bit             reset_n,

//register
    input   bit                         cntrl_start_i,
    input   bit                         cntrl_stop_i,
    input   bit                         cntrl_auto_length_i,
    input   bit                         cntrl_auto_channel_i,
    input   bit                         cntrl_auto_pause_i,
    input   bit                         cntrl_use_limit_transaction_i,
    
    
    input   bit     [15:0]              cntrl_fixed_length_i,
    input   bit     [15:0]              cntrl_min_length_i,
    input   bit     [15:0]              cntrl_max_length_i,
    
    input   bit     [ID_WIDTH-1:0]      cntrl_fixed_channel_i,
    input   bit     [ID_WIDTH-1:0]      cntrl_min_channel_i,
    input   bit     [ID_WIDTH-1:0]      cntrl_max_channel_i,

    input   bit     [31:0]              cntrl_fixed_pause_i,
    input   bit     [31:0]              cntrl_min_pause_i,
    input   bit     [31:0]              cntrl_max_pause_i,

    input   bit     [31:0]              cntrl_cnt_packet_i,
    
//input data from lfsr generator
    input   bit     [15:0]             pkt_length_i,
    input   bit     [ID_WIDTH-1:0]     pkt_channel_i,
    input   bit     [31:0]             pkt_pause_i,

//output descriptor
    output  bit     [48+ID_WIDTH-1:0]  descriptor_data_o,//{channel, pause[31:0], length[15:0]}
    output  bit                        descriptor_valid_o,
    input   bit                        descriptor_ready_i 

);

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    bit                         auto_length_r;
    bit                         auto_channel_r;
    bit                         auto_pause_r;
    bit                         cntrl_use_limit_transaction_i_r;


    bit     [15:0]              fixed_length_r;
    bit     [15:0]              min_length_r;
    bit     [15:0]              max_length_r;
    
    bit     [ID_WIDTH-1:0]      fixed_channel_r;
    bit     [ID_WIDTH-1:0]      min_channel_r;
    bit     [ID_WIDTH-1:0]      max_channel_r;

    bit     [31:0]              fixed_pause_r;
    bit     [31:0]              min_pause_r;
    bit     [31:0]              max_pause_r;

    bit     [31:0]              cnt_packet_r;
    logic                       get_length_ok, 
                                get_channel_ok, 
                                get_pause_ok;
    logic                       get_parameter_ok;

    bit     [15:0]              descr_length;
    bit     [31:0]              descr_pause;
    bit     [ID_WIDTH-1:0]      descr_channel;



    enum bit [1:0] {
        IDLE, 
        GET_PARAMETER, 
        SEND_DESCRIPTOR
    } state, state_next;

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) state <= IDLE;
        else state <= state_next;
    end

    always_comb begin
        state_next = state;

        case(state)
            IDLE: if(cntrl_start_i  && (cntrl_use_limit_transaction_i ? (cntrl_cnt_packet_i > 32'h0) : 1'b1) 
                                    && (cntrl_auto_length_i ? (cntrl_max_length_i > cntrl_min_length_i) : (cntrl_fixed_length_i > 16'h0))
                                    && (cntrl_auto_pause_i ? (cntrl_max_pause_i > cntrl_min_pause_i) : 1'b1)
                                    && (cntrl_auto_channel_i ? (cntrl_max_channel_i > cntrl_min_channel_i) : 1'b1)) state_next = GET_PARAMETER;

            GET_PARAMETER: begin
                if(cntrl_stop_i) state_next = IDLE;
                else if(get_parameter_ok) state_next = SEND_DESCRIPTOR;
            end

            SEND_DESCRIPTOR: begin
                if(cntrl_stop_i) state_next = IDLE;
                else if(descriptor_ready_i && descriptor_valid_o) begin
                    if((cnt_packet_r == 32'h0) && cntrl_use_limit_transaction_i_r) state_next = IDLE;
                    else state_next = GET_PARAMETER;
                end
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

//fixed parameter for transmitter
    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            auto_length_r                   <= 1'b0;
            auto_channel_r                  <= 1'b0;
            auto_pause_r                    <= 1'b0;
            cntrl_use_limit_transaction_i_r   <= 1'b0;
        end
        else if((state == IDLE) && cntrl_start_i) begin
            auto_length_r                   <= cntrl_auto_length_i;
            auto_channel_r                  <= cntrl_auto_channel_i;
            auto_pause_r                    <= cntrl_auto_pause_i;
            cntrl_use_limit_transaction_i_r   <= cntrl_use_limit_transaction_i;
        end
    end
    

    always_ff @ (posedge clk) begin
        if((state == IDLE) && cntrl_start_i) cnt_packet_r <= cntrl_cnt_packet_i - 32'h1;
        else if((state == SEND_DESCRIPTOR) && descriptor_ready_i) cnt_packet_r <= cnt_packet_r - 32'h1;

        if((state == IDLE) && cntrl_start_i) begin
            fixed_length_r  <= cntrl_fixed_length_i;
            min_length_r    <= cntrl_min_length_i;
            max_length_r    <= cntrl_max_length_i;
            
            fixed_channel_r <= cntrl_fixed_channel_i;
            min_channel_r   <= cntrl_min_channel_i;
            max_channel_r   <= cntrl_max_channel_i;
        
            fixed_pause_r   <= cntrl_fixed_pause_i;
            min_pause_r     <= cntrl_min_pause_i;
            max_pause_r     <= cntrl_max_pause_i;
        end
    end

//create current transaction
    assign get_parameter_ok =   (auto_length_r  ? get_length_ok     : 1'b1) &
                                (auto_channel_r ? get_channel_ok    : 1'b1) &
                                (auto_pause_r   ? get_pause_ok      : 1'b1);



    always_ff  @ (posedge clk) begin
        if(state == GET_PARAMETER) begin
            if(auto_length_r) begin
                if(!get_length_ok && (pkt_length_i >= min_length_r) && (pkt_length_i <= max_length_r)) begin
                    get_length_ok   <= 1'b1;
                    descr_length    <= pkt_length_i;
                end
            end
            else begin
                descr_length <= fixed_length_r;
            end

            if(auto_channel_r) begin
                if(!get_channel_ok && (pkt_channel_i >= min_channel_r) && (pkt_channel_i <= max_channel_r)) begin
                    get_channel_ok  <= 1'b1;
                    descr_channel   <= pkt_channel_i;
                end
            end
            else begin
                descr_channel <= fixed_channel_r;
            end

            if(auto_pause_r) begin
                if(!get_pause_ok && (pkt_pause_i >= min_pause_r) && (pkt_pause_i <= max_pause_r)) begin
                    get_pause_ok    <= 1'b1;
                    descr_pause     <= pkt_pause_i;
                end
            end
            else begin
                descr_pause <= fixed_pause_r;
            end
        end
        else begin
            get_length_ok   <= 1'b0;
            get_channel_ok  <= 1'b0;
            get_pause_ok    <= 1'b0;
        end
    end


//SEND DESCRIPTOR
    assign descriptor_data_o = {descr_channel, descr_pause, descr_length};
    assign descriptor_valid_o = (state == SEND_DESCRIPTOR);


endmodule