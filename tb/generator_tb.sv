module generator_tb();

    localparam ID_WIDTH = 10;
    localparam DATA_WIDTH = 32;
    localparam TKEEP_WIDTH = DATA_WIDTH/8;


    reg clk;
    reg reset_n;

//CONTROL, using AXI-Lite interface
//write channel
    reg     [5:0]  	    s_axil_awaddr;
    reg     [2:0]       s_axil_awprot;
    reg                 s_axil_awvalid;
    wire                s_axil_awready;
    reg     [31:0]  	s_axil_wdata;
    reg     [3:0]  	    s_axil_wstrb;
    reg                 s_axil_wvalid;
    wire                s_axil_wready;
    wire    [1:0]       s_axil_bresp;
    wire                s_axil_bvalid;
    reg                 s_axil_bready;
//read channel
    reg     [5:0]  	    s_axil_araddr;
    reg     [2:0]       s_axil_arprot;
    reg                 s_axil_arvalid;
    wire                s_axil_arready;
    wire    [31:0]  	s_axil_rdata;
    wire    [1:0]       s_axil_rresp;
    wire                s_axil_rvalid;
    reg                 s_axil_rready;


    logic     [ID_WIDTH-1:0]          m_axis_tid_o;
    logic     [DATA_WIDTH-1:0]        m_axis_tdata_o;
    logic                             m_axis_tvalid_o;
    logic                             m_axis_tlast_o;
    logic     [TKEEP_WIDTH-1:0]       m_axis_tkeep_o;
    logic                             m_axis_tready_i;

    axis_generator_top #(
        .ID_WIDTH       (ID_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .TKEEP_WIDTH    (TKEEP_WIDTH)
    ) DUT (
        .clk                (clk                        ),
        .reset_n            (reset_n                    ),
    
    //CONTROL, using AXI-Lite interface
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
    
    
        .m_axis_tid_o       (m_axis_tid_o               ),
        .m_axis_tdata_o     (m_axis_tdata_o             ),
        .m_axis_tvalid_o    (m_axis_tvalid_o            ),
        .m_axis_tlast_o     (m_axis_tlast_o             ),
        .m_axis_tkeep_o     (m_axis_tkeep_o             ),
        .m_axis_tready_i    (m_axis_tready_i            )
    );

    always begin
        clk = 1'b0;
        #10;
        clk = 1'b1;
        #10;
    end



    task mm_write(bit [3:0] word_address, bit [31:0] writedata);
        fork
            //write address stream
            begin
                s_axil_awaddr   <= {word_address, 2'h0};
                s_axil_awprot   <= 3'h0;
                s_axil_awvalid  <= 1'b1;

                do begin
                    @(posedge clk);
                end
                while(!s_axil_awready);

                s_axil_awaddr   <= 6'h0;
                s_axil_awprot   <= 3'h0;
                s_axil_awvalid  <= 1'b0;
            end
            //write data stream
            begin
                s_axil_wdata    <= writedata;
                s_axil_wstrb    <= 4'hF;
                s_axil_wvalid   <= 1'b1;

                do begin
                    @(posedge clk);
                end
                while(!s_axil_wready);

                s_axil_wdata    <= 32'h0;
                s_axil_wstrb    <= 4'h0;
                s_axil_wvalid   <= 1'b0;
            end

            //wait response
            begin
                while(!(s_axil_bready && s_axil_bvalid)) begin
                    @(posedge clk);
                end
            end
        join
    endtask


    task automatic axi_read(bit [3:0] word_address, ref [31:0] readdata);
        fork
            begin:read_request
                s_axil_araddr   <= {word_address, 2'b00};
                s_axil_arprot   <= 3'h0;
                s_axil_arvalid  <= 1'b1;

                do begin
                    @(posedge clk);
                end
                while(!s_axil_arready);

                s_axil_araddr   <= 6'h0;
                s_axil_arprot   <= 3'h0;
                s_axil_arvalid  <= 1'b0;
            end
            begin:read_response
                while(!(s_axil_arready && s_axil_rvalid)) begin
                    @(posedge clk);
                end
                readdata = s_axil_rdata;
            end
        join
    endtask

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

    bit [15:0] fixed_length, minimal_length, maximum_length;
    bit [15:0] fixed_channel, mimimal_channel, maximum_channel;
    bit [31:0] fixed_pause, minimal_pause, maximum_pause;
    bit [31:0] count_packet;


    bit start = 1;
    bit stop = 0;
    bit auto_length = 1;
    bit auto_channel = 1;
    bit auto_pause = 1;
    bit use_limit_transaction = 1;

    int statistic [2**16-1:0];
    int cnt_packet;
    int max_cnt_packet = 10_000;


    initial begin
        reset_n         <= 1'b0;
        s_axil_awaddr   <= 6'h0;
        s_axil_awprot   <= 3'h0;
        s_axil_awvalid  <= 1'b0;
        s_axil_wdata    <= 32'h0;
        s_axil_wstrb    <= 4'h0;
        s_axil_wvalid   <= 1'b0;
    
    
        s_axil_araddr   <= 6'h0;
        s_axil_arprot   <= 3'h0;
        s_axil_arvalid  <= 1'b0;

        repeat(5) @ (posedge clk);
        reset_n         <= 1'b1;
        repeat(5) @ (posedge clk);


        fixed_length    <= 16'd9;
        minimal_length  <= 16'd64;
        maximum_length  <= 16'd1600;
        fixed_channel   <= 16'h0;
        mimimal_channel <= 16'd0;
        maximum_channel <= 16'd16;
        fixed_pause     <= 32'h0;
        minimal_pause   <= 32'd0;
        maximum_pause   <= 32'd200;
        count_packet    <= max_cnt_packet;
        @(posedge clk);


        mm_write(4'h1, {16'h0, fixed_length});
        mm_write(4'h2, {16'h0, minimal_length});
        mm_write(4'h3, {16'h0, maximum_length});
        mm_write(4'h4, {16'h0, fixed_channel});
        mm_write(4'h5, {16'h0, mimimal_channel});
        mm_write(4'h6, {16'h0, maximum_channel});
        mm_write(4'h7, fixed_pause);
        mm_write(4'h8, minimal_pause);
        mm_write(4'h9, maximum_pause);
        mm_write(4'hA, count_packet);

        mm_write(4'h0, {26'h0, use_limit_transaction, auto_pause, auto_channel, auto_length, stop, start});
        repeat(100) @(posedge clk);
        while(cnt_packet < max_cnt_packet) begin
            @(posedge clk);
        end
        print_result();
        repeat(1000) @(posedge clk);
        $display("***TEST FINISH***");
        $stop();
    end


    task print_result();
        $display("Statistic packet length:");
        for(bit [15:0] i = minimal_length; i <= maximum_length; i++) begin
            $display("Length = %0d, statistic = %0d", i, statistic[i]);
        end
    endtask


    initial begin
        s_axil_bready   <= 1'b0;
        s_axil_rready   <= 1'b0;
        m_axis_tready_i <= 1'b0;
        wait(reset_n);
        fork
            forever begin
                s_axil_bready <= 1'b1;
                repeat($urandom_range(10,0)) @(posedge clk);
                s_axil_bready <= 1'b0;
                repeat($urandom_range(10,0)) @(posedge clk);
            end
            forever begin
                s_axil_rready <= 1'b1;
                repeat($urandom_range(10,0)) @(posedge clk);
                s_axil_rready <= 1'b0;
                repeat($urandom_range(10,0)) @(posedge clk);
            end
            forever begin
                m_axis_tready_i <= 1'b1;
                repeat($urandom_range(10,0)) @(posedge clk);
                m_axis_tready_i <= 1'b0;
                repeat($urandom_range(10,0)) @(posedge clk);
            end
        join
    end

    function int tkeepcntbits(logic [TKEEP_WIDTH-1:0] tkeep);
        int result;
        result = 0;
        for(int i = 0; i < ID_WIDTH; i++) begin
            if(tkeep[i]) result++;
        end
        return result;
    endfunction

    //check length
    initial begin
        int pkt_length;
        cnt_packet = 0;
        wait(reset_n);
        forever begin
            @(posedge clk);
            if(m_axis_tvalid_o && m_axis_tready_i) begin
                pkt_length += tkeepcntbits(m_axis_tkeep_o);
                if(m_axis_tlast_o) begin
                    if(auto_length & ((pkt_length >= minimal_length) && (pkt_length <= maximum_length)) || !auto_length && (pkt_length == fixed_length)) begin
                        statistic[pkt_length] += 1;
                    end
                    else begin
                        $display("Error length!!! Minimal length = %0d, Maximum length = %0d, Length = %0d", minimal_length, maximum_length, pkt_length);
                    end
                    pkt_length = 32'h0;
                    cnt_packet++;
                    if((cnt_packet % 1000) == 0) begin
                        $display("Current count packet = %0d", cnt_packet);
                    end
                end
            end
        end
    end
endmodule