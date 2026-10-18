
module l1_icache
(
	input             CLK,
	input             RESET,
	input             pr_reset,
	
	input             DISABLE,

	input             CPU_REQ,
	input      [31:0] CPU_ADDR,
	output reg        CPU_VALID,
	output reg        CPU_DONE,
	output     [31:0] CPU_DATA,
	
	output reg        MEM_REQ,
	output reg [31:0] MEM_ADDR,
	input             MEM_DONE,
	input      [31:0] MEM_DATA,
	
	input      [27:2] snoop_addr,
	input      [31:0] snoop_data,
	input       [3:0] snoop_be,
	input             snoop_we
);

// cache settings
localparam LINES         = 128;
localparam LINESIZE      = 8;
localparam ASSOCIATIVITY = 4;
localparam ADDRBITS      = 29;
localparam CACHEBURST    = 4;

// cache control
localparam ASSO_BITS       = $clog2(ASSOCIATIVITY);
localparam LINESIZE_BITS   = $clog2(LINESIZE);
localparam LINE_BITS       = $clog2(LINES);
localparam CACHEBURST_BITS = $clog2(CACHEBURST);
localparam RAMSIZEBITS     = $clog2(LINESIZE * LINES);
localparam LINEMASKLSB     = $clog2(LINESIZE);
localparam LINEMASKMSB     = LINEMASKLSB + $clog2(LINES) - 1;

reg    [ASSOCIATIVITY-1:0]      tags_dirty_in;
reg    [ASSOCIATIVITY-1:0]      tags_dirty_out;
wire   [ADDRBITS-RAMSIZEBITS:0] tags_read[0:ASSOCIATIVITY-1];
reg                             update_tag_we;
reg    [LINE_BITS-1:0]          update_tag_addr;

reg    [ASSO_BITS-1:0] LRU_in [0:ASSOCIATIVITY-1];
reg    [ASSO_BITS-1:0] LRU_out[0:ASSOCIATIVITY-1];
reg                             LRU_we;
reg    [LINE_BITS-1:0]          LRU_addr;

localparam [2:0]
	START         = 0,
	IDLE          = 1,
	WRITEONE      = 2,
	READONE       = 3,
	FILLCACHE     = 4,
	READCACHE_OUT = 5;
	
// memory
wire             [31:0] readdata_cache[0:ASSOCIATIVITY-1];
reg     [ASSO_BITS-1:0] cache_mux;

reg        [ADDRBITS:0] read_addr;

reg   [RAMSIZEBITS-1:0] memory_addr_a;
reg              [31:0] memory_datain;
reg [0:ASSOCIATIVITY-1] memory_we;
reg               [3:0] memory_be;

reg   [LINESIZE_BITS-1:0] fillcount;
reg [CACHEBURST_BITS-1:0] burstleft;

reg   [2:0] state;
reg         CPU_REQ_hold;

// fifo for snoop (async-read distributed RAM, replaces altdpram-based simple_fifo_mlab)
localparam FIFO_WIDTHU = 4;
localparam FIFO_WIDTH  = 62;

wire [61:0] Fifo_dout;
wire        Fifo_empty;

reg [FIFO_WIDTHU-1:0] fifo_rd_index;
reg [FIFO_WIDTHU-1:0] fifo_wr_index;
reg                   fifo_full;
reg [FIFO_WIDTHU-1:0] fifo_usedw;

wire fifo_wrreq = snoop_we;
wire fifo_rdreq = (state == IDLE) && !Fifo_empty;

assign Fifo_empty = (fifo_usedw == 0) && ~fifo_full;

always @(posedge CLK) begin
	if (RESET)                           fifo_rd_index <= 0;
	else if (fifo_rdreq && ~Fifo_empty)  fifo_rd_index <= fifo_rd_index + 1'd1;
end

always @(posedge CLK) begin
	if (RESET)                                          fifo_wr_index <= 0;
	else if (fifo_wrreq && (~fifo_full || fifo_rdreq))   fifo_wr_index <= fifo_wr_index + 1'd1;
end

always @(posedge CLK) begin
	if (RESET)                                                                           fifo_full <= 1'b0;
	else if (fifo_rdreq && ~fifo_wrreq && fifo_full)                                      fifo_full <= 1'b0;
	else if (~fifo_rdreq && fifo_wrreq && ~fifo_full && (fifo_usedw == {FIFO_WIDTHU{1'b1}})) fifo_full <= 1'b1;
end

always @(posedge CLK) begin
	if (RESET)                                          fifo_usedw <= 0;
	else if (fifo_rdreq && ~fifo_wrreq && ~Fifo_empty)  fifo_usedw <= fifo_usedw - 1'd1;
	else if (~fifo_rdreq && fifo_wrreq && ~fifo_full)   fifo_usedw <= fifo_usedw + 1'd1;
	else if (fifo_rdreq && fifo_wrreq && Fifo_empty)    fifo_usedw <= 1'd1;
end

xpm_memory_dpdistram #(
	.MEMORY_SIZE        ((2**FIFO_WIDTHU) * FIFO_WIDTH),
	.CLOCKING_MODE      ("common_clock"),
	.MEMORY_INIT_FILE   ("none"),
	.MEMORY_INIT_PARAM  ("0"),
	.USE_MEM_INIT       (0),
	.MESSAGE_CONTROL    (0),

	.WRITE_DATA_WIDTH_A (FIFO_WIDTH),
	.READ_DATA_WIDTH_A  (FIFO_WIDTH),
	.BYTE_WRITE_WIDTH_A (FIFO_WIDTH),
	.ADDR_WIDTH_A       (FIFO_WIDTHU),
	.READ_LATENCY_A     (0),

	.READ_DATA_WIDTH_B  (FIFO_WIDTH),
	.ADDR_WIDTH_B       (FIFO_WIDTHU),
	.READ_LATENCY_B     (0)
)
snoopfifo (
	.clka       (CLK),
	.rsta       (1'b0),
	.ena        (1'b1),
	.regcea     (1'b1),
	.wea        (fifo_wrreq && (~fifo_full || fifo_rdreq)),
	.addra      (fifo_wr_index),
	.dina       ({snoop_be, snoop_data, snoop_addr}),
	.douta      (),

	.clkb       (CLK),
	.rstb       (1'b0),
	.enb        (1'b1),
	.regceb     (1'b1),
	.addrb      (fifo_rd_index),
	.doutb      (Fifo_dout)
);
	
assign CPU_DATA = readdata_cache[cache_mux];

reg force_fetch;
reg force_next;

always @(posedge CLK) begin : mainfsm
	reg [ASSO_BITS:0]   i;
	reg [ASSO_BITS-1:0] match;
	
	memory_we <= {ASSOCIATIVITY{1'b0}};
	CPU_DONE  <= 1'b0;
	CPU_VALID <= 1'b0;
	
	if (RESET) begin
		state           <= START;
		update_tag_addr <= {LINE_BITS{1'b0}};
		update_tag_we   <= 1'b1;
		tags_dirty_in   <= {ASSOCIATIVITY{1'b1}};

		MEM_REQ         <= 1'b0;
		CPU_REQ_hold    <= 1'b0;
	end
	else begin
		if (CPU_REQ) CPU_REQ_hold <= 1'b1;

		// LRU update after read
		LRU_we <= CPU_VALID && ~LRU_we;
		for (i = 0; i < ASSOCIATIVITY; i = i + 1'd1) begin
			LRU_in[i] <= LRU_out[i];
			if (cache_mux == i[ASSO_BITS-1:0]) begin
				match     = LRU_out[i];
				LRU_in[i] <= {ASSO_BITS{1'b0}};
			end
		end
		for (i = 0; i < ASSOCIATIVITY; i = i + 1'd1) begin
			if (LRU_out[i] < match) begin
				LRU_in[i] <= LRU_out[i] + 1'd1;
			end
		end

		case (state)
			START:
			begin
				update_tag_addr <= update_tag_addr + 1'd1;
				
				for (i = 0; i < ASSOCIATIVITY; i = i + 1'd1) begin
					LRU_in[i]    <= i[ASSO_BITS-1:0]; 
				end
				LRU_addr        <= update_tag_addr;
				LRU_we          <= 1'b1; 
				
				if (update_tag_addr == {LINE_BITS{1'b1}}) begin
					state         <= IDLE;
					update_tag_we <= 1'b0;
				end
			end
		
			IDLE:
				begin
					if (!Fifo_empty) begin
						state         <= WRITEONE;
						read_addr     <= Fifo_dout[25:0];
						memory_addr_a <= Fifo_dout[RAMSIZEBITS - 1:0];
						memory_datain <= Fifo_dout[57:26];
						memory_be     <= Fifo_dout[61:58];
					end
					else if (CPU_REQ || CPU_REQ_hold) begin
						force_fetch   <= DISABLE;
						force_next    <= DISABLE;
						state         <= READONE;
						read_addr     <= CPU_ADDR[31:2];
						CPU_REQ_hold  <= 1'b0;
						burstleft     <= CACHEBURST[CACHEBURST_BITS-1:0] - 1'd1;
					end
				end
			
			WRITEONE:
				begin
					state <= IDLE;
					for (i = 0; i < ASSOCIATIVITY; i = i + 1'd1) begin
						if (~tags_dirty_out[i]) begin
							if (tags_read[i] == read_addr[ADDRBITS:RAMSIZEBITS]) memory_we[i] <= 1'b1;
						end
					end
				end

			READONE:
				begin
					if (pr_reset) begin
						state     <= IDLE;
						CPU_DONE  <= 1'b1;
					end else begin
						state           <= FILLCACHE;
						MEM_REQ         <= 1'b1;
						MEM_ADDR        <= {read_addr[ADDRBITS:LINESIZE_BITS], {LINESIZE_BITS{1'b0}}, 2'b00};
						fillcount       <= 0;
						memory_addr_a   <= {read_addr[RAMSIZEBITS - 1:LINESIZE_BITS], {LINESIZE_BITS{1'b0}}};
						tags_dirty_in   <= tags_dirty_out;
						update_tag_addr <= read_addr[LINEMASKMSB:LINEMASKLSB];
						LRU_addr        <= read_addr[LINEMASKMSB:LINEMASKLSB];

						if (force_fetch) force_next <= ~force_next;

						if (~force_next) begin
							for (i = 0; i < ASSOCIATIVITY; i = i + 1'd1) begin
								if (~tags_dirty_out[i]) begin
									if (tags_read[i] == read_addr[ADDRBITS:RAMSIZEBITS]) begin
										MEM_REQ   <= 1'b0;
										cache_mux <= i[ASSO_BITS-1:0];
										CPU_VALID <= 1'b1;
										if (!burstleft) begin
											state    <= IDLE;
											CPU_DONE <= 1'b1;
										end else begin
											state     <= READONE;
											burstleft <= burstleft - 1'd1;
											read_addr <= read_addr + 1'd1;
										end
									end
								end
							end
						end
						else begin
							tags_dirty_in <= {ASSOCIATIVITY{1'b1}};
							update_tag_we <= 1'b1;
						end
					end
				end
			
			FILLCACHE:
				begin
					for (i = 0; i < ASSOCIATIVITY; i = i + 1'd1) begin
						if (LRU_out[i] == {ASSO_BITS{1'b1}} ) cache_mux <= i[ASSO_BITS-1:0]; 
					end

					if (MEM_DONE) begin
						MEM_REQ              <= 1'b0;
						memory_datain        <= MEM_DATA;
						memory_we[cache_mux] <= 1'b1;
						memory_be            <= 4'hF;
						
						tags_dirty_in[cache_mux] <= 1'b0;

						if (fillcount > 0) memory_addr_a <= memory_addr_a + 1'd1;
						if (fillcount < LINESIZE - 1) fillcount <= fillcount + 1'd1;
						else begin 
						   state         <= READCACHE_OUT;
						   update_tag_we <= 1'b1;
						end
					end
				end
			
			READCACHE_OUT :
				begin
					state         <= READONE;
					update_tag_we <= 1'b0;
				end
		endcase
	end
end

// dirty bits: async read (MLAB-like), width=ASSOCIATIVITY, common clock
xpm_memory_dpdistram #(
	.MEMORY_SIZE        (LINES * ASSOCIATIVITY),
	.CLOCKING_MODE      ("common_clock"),
	.MEMORY_INIT_FILE   ("none"),
	.MEMORY_INIT_PARAM  ("0"),
	.USE_MEM_INIT       (0),
	.MESSAGE_CONTROL    (0),

	.WRITE_DATA_WIDTH_A (ASSOCIATIVITY),
	.READ_DATA_WIDTH_A  (ASSOCIATIVITY),
	.BYTE_WRITE_WIDTH_A (ASSOCIATIVITY),
	.ADDR_WIDTH_A       (LINE_BITS),
	.READ_LATENCY_A     (0),

	.READ_DATA_WIDTH_B  (ASSOCIATIVITY),
	.ADDR_WIDTH_B       (LINE_BITS),
	.READ_LATENCY_B     (0)
)
dirtyram (
	.clka       (CLK),
	.rsta       (1'b0),
	.ena        (1'b1),
	.regcea     (1'b1),
	.wea        (update_tag_we),
	.addra      (update_tag_addr),
	.dina       (tags_dirty_in),
	.douta      (),

	.clkb       (CLK),
	.rstb       (1'b0),
	.enb        (1'b1),
	.regceb     (1'b1),
	.addrb      (read_addr[LINEMASKMSB:LINEMASKLSB]),
	.doutb      (tags_dirty_out)
);

generate
	genvar i;
	for (i = 0; i < ASSOCIATIVITY; i = i + 1) begin : gcache
		// tag storage per way: async read (MLAB-like)
		xpm_memory_dpdistram #(
			.MEMORY_SIZE        (LINES * (ADDRBITS - RAMSIZEBITS + 1)),
			.CLOCKING_MODE      ("common_clock"),
			.MEMORY_INIT_FILE   ("none"),
			.MEMORY_INIT_PARAM  ("0"),
			.USE_MEM_INIT       (0),
			.MESSAGE_CONTROL    (0),

			.WRITE_DATA_WIDTH_A (ADDRBITS - RAMSIZEBITS + 1),
			.READ_DATA_WIDTH_A  (ADDRBITS - RAMSIZEBITS + 1),
			.BYTE_WRITE_WIDTH_A (ADDRBITS - RAMSIZEBITS + 1),
			.ADDR_WIDTH_A       (LINE_BITS),
			.READ_LATENCY_A     (0),

			.READ_DATA_WIDTH_B  (ADDRBITS - RAMSIZEBITS + 1),
			.ADDR_WIDTH_B       (LINE_BITS),
			.READ_LATENCY_B     (0)
		)
		tagram (
			.clka       (CLK),
			.rsta       (1'b0),
			.ena        (1'b1),
			.regcea     (1'b1),
			.wea        ((state == READCACHE_OUT) && (cache_mux == i)),
			.addra      (read_addr[LINEMASKMSB:LINEMASKLSB]),
			.dina       (read_addr[ADDRBITS:RAMSIZEBITS]),
			.douta      (),

			.clkb       (CLK),
			.rstb       (1'b0),
			.enb        (1'b1),
			.regceb     (1'b1),
			.addrb      (read_addr[LINEMASKMSB:LINEMASKLSB]),
			.doutb      (tags_read[i])
		);

		// LRU counters per way: async read (MLAB-like)
		xpm_memory_dpdistram #(
			.MEMORY_SIZE        (LINES * ASSO_BITS),
			.CLOCKING_MODE      ("common_clock"),
			.MEMORY_INIT_FILE   ("none"),
			.MEMORY_INIT_PARAM  ("0"),
			.USE_MEM_INIT       (0),
			.MESSAGE_CONTROL    (0),

			.WRITE_DATA_WIDTH_A (ASSO_BITS),
			.READ_DATA_WIDTH_A  (ASSO_BITS),
			.BYTE_WRITE_WIDTH_A (ASSO_BITS),
			.ADDR_WIDTH_A       (LINE_BITS),
			.READ_LATENCY_A     (0),

			.READ_DATA_WIDTH_B  (ASSO_BITS),
			.ADDR_WIDTH_B       (LINE_BITS),
			.READ_LATENCY_B     (0)
		)
		LRUram (
			.clka       (CLK),
			.rsta       (1'b0),
			.ena        (1'b1),
			.regcea     (1'b1),
			.wea        (LRU_we),
			.addra      (LRU_addr),
			.dina       (LRU_in[i]),
			.douta      (),

			.clkb       (CLK),
			.rstb       (1'b0),
			.enb        (1'b1),
			.regceb     (1'b1),
			.addrb      (LRU_addr),
			.doutb      (LRU_out[i])
		);

		// cache line data: true dual-port BRAM, 32bit write / 32bit read, 1 cycle read latency
		xpm_memory_sdpram #(
			.MEMORY_SIZE        ((2**RAMSIZEBITS) * 32),
			.MEMORY_PRIMITIVE   ("auto"),
			.CLOCKING_MODE      ("common_clock"),
			.MEMORY_INIT_FILE   ("none"),
			.MEMORY_INIT_PARAM  ("0"),
			.USE_MEM_INIT       (0),
			.MESSAGE_CONTROL    (0),

			.WRITE_DATA_WIDTH_A (32),
			.BYTE_WRITE_WIDTH_A (8),
			.ADDR_WIDTH_A       (RAMSIZEBITS),

			.READ_DATA_WIDTH_B  (32),
			.ADDR_WIDTH_B       (RAMSIZEBITS),
			.READ_LATENCY_B     (1),
			.WRITE_MODE_B       ("no_change")
		)
		ram (
			.sleep         (1'b0),

			.clka          (CLK),
			.ena           (1'b1),
			.wea           (memory_be & {4{memory_we[i]}}),
			.addra         (memory_addr_a),
			.dina          (memory_datain),
			.injectsbiterra(1'b0),
			.injectdbiterra(1'b0),

			.clkb          (CLK),
			.rstb          (1'b0),
			.enb           (1'b1),
			.regceb        (1'b1),
			.addrb         (read_addr[RAMSIZEBITS - 1:0]),
			.doutb         (readdata_cache[i]),
			.sbiterrb      (),
			.dbiterrb      ()
		);
	end
endgenerate

endmodule
