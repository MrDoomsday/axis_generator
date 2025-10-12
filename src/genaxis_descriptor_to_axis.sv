module genaxis_descriptor_to_axis #(
    parameter ID_WIDTH = 10,
    parameter DATA_WIDTH = 32,
    parameter TKEEP_WIDTH = DATA_WIDTH/8
)(
    input bit clk,
    input bit reset_n,

//pseudo random data
    input   bit     [DATA_WIDTH-1:0]        psrand_data_i,

//input descriptor
    input   bit     [48+ID_WIDTH-1:0]      in_descriptor_data_i,//{channel, pause[31:0], length[15:0]}
    input   bit                            in_descriptor_valid_i,
    output  bit                            in_descriptor_ready_o,

//AXI Stream Interface
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
    logic   [15:0]              packet_length;
    logic   [ID_WIDTH-1:0]      packet_channel;
    logic   [31:0]              packet_pause;
    logic   [TKEEP_WIDTH-1:0]   tkeep_reg;
    logic                       tready;

    enum bit [1:0] {
        IDLE, 
        BEGIN_TRANSFER, 
        TRANSFER, 
        PAUSE
    } state, state_next;
    
    wire short_len = packet_length <= 16'(DATA_WIDTH/8);


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
        in_descriptor_ready_o = 1'b0;

        case(state)
            IDLE: begin
                in_descriptor_ready_o = 1'b1;
                if(in_descriptor_valid_i) state_next = BEGIN_TRANSFER;
            end

            BEGIN_TRANSFER: begin
                if(tready) begin
                    if(short_len) begin
                        if(packet_pause == 32'h0) state_next = IDLE;
                        else state_next = PAUSE;
                    end
                    else state_next = TRANSFER;
                end
            end

            TRANSFER: begin
                if(tready) begin
                    if(short_len) begin
                        if(packet_pause == 32'h0) state_next = IDLE;
                        else state_next = PAUSE;
                    end
                    else state_next = TRANSFER;
                end
            end

            PAUSE: begin
                if(packet_pause == 32'h0) state_next = IDLE;
            end

            default: state_next = IDLE;
        endcase
    end

    wire [2*TKEEP_WIDTH-1:0] tkeep_next = {{TKEEP_WIDTH{1'b0}}, {TKEEP_WIDTH{1'b1}}} << packet_length[$clog2(TKEEP_WIDTH):0];//выдвигаем только количество единиц равное количеству оставшихся байт в пакете

    always_ff @ (posedge clk) begin
        if((state == IDLE) && in_descriptor_valid_i) packet_length <= in_descriptor_data_i[15:0];//длина пакета, который необходимо сгенерировать
        else if(tready && ((state == BEGIN_TRANSFER) || (state == TRANSFER))) packet_length <= packet_length - 16'(DATA_WIDTH/8);

        if((state == IDLE) && in_descriptor_valid_i) packet_pause <= in_descriptor_data_i[47:16];
        else if(state == PAUSE) packet_pause <= packet_pause - 32'h1;

        if((state == IDLE) && in_descriptor_valid_i) packet_channel <= in_descriptor_data_i[48+:ID_WIDTH];
    end

    
    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) m_axis_tvalid_o <= 1'b0;
        else if(tready) begin
            m_axis_tvalid_o <= ((state == BEGIN_TRANSFER) || (state == TRANSFER));
        end
    end

    wire tlast_next = ((state == BEGIN_TRANSFER) || (state == TRANSFER)) & short_len;

    always_ff @ (posedge clk) begin
        if(tready) begin
            m_axis_tid_o    <= packet_channel;
            m_axis_tdata_o  <= psrand_data_i;
            m_axis_tlast_o  <= tlast_next;
            m_axis_tkeep_o  <= tlast_next ? tkeep_next[2*TKEEP_WIDTH-1:TKEEP_WIDTH] : {TKEEP_WIDTH{1'b1}};//по умолчанию они все валидные
        end
    end


    assign tready = m_axis_tready_i | ~m_axis_tvalid_o;

endmodule