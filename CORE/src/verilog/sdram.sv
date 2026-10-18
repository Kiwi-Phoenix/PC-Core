//
// sdram.v
//
// Static RAM controller implementation using SDRAM MT48LC16M16A2
//
// Copyright (c) 2015-2019 Sorgelig
//
// Some parts of SDRAM code used from project:
// http://hamsterworks.co.nz/mediawiki/index.php/Simple_SDRAM_Controller
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version. 
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// ------------------------------------------
//
// v2.1 - Add universal 8/16 bit mode.
//
// Sept 2026   - David Raynor (Kiwi)
// Changed to use Artix-7 IP core for SDRAM interface.


module sdram
(
   input             init,        // reset to initialize RAM
   input             clk,         // clock ~100MHz

   // SDRAM_* - signals to the MT48LC16M16 chip
   inout  wire [15:0] SDRAM_DQ,   // 16 bit bidirectional data bus
   output logic [12:0] SDRAM_A,   // 13 bit multiplexed address bus
   output logic        SDRAM_DQML,// two byte masks
   output logic        SDRAM_DQMH,
   output logic  [1:0] SDRAM_BA,  // two banks
   output logic        SDRAM_nCS, // chip select
   output logic        SDRAM_nWE, // write enable
   output logic        SDRAM_nRAS,// row address select
   output logic        SDRAM_nCAS,// column address select
   output logic        SDRAM_CKE, // clock enable
   output logic        SDRAM_CLK,

   // CPU interface
   input      [24:0]  addr,       // 25-bit address (8-bit mode). addr[0]=0 for 16-bit mode.
   output logic [15:0] dout,      // data output to CPU
   input      [15:0]  din,        // data input from CPU
   input              we,         // CPU write request
   input              rd,         // CPU read request
   input              refresh,    // refresh requests (unused in original, kept for interface)
   input              word,       // 16-bit write
   output logic       ready       // dout valid / ready for new read/write
);

   // -------------------------------------------------------------------------
   // Mode register and timing constants
   // -------------------------------------------------------------------------

   localparam BURST_LENGTH        = 3'b000;   // 000=1, 001=2, 010=4, 011=8
   localparam ACCESS_TYPE         = 1'b0;     // 0=sequential, 1=interleaved
   localparam CAS_LATENCY         = 3'd2;     // 2 for <100MHz, 3 for >100MHz
   localparam OP_MODE             = 2'b00;    // standard operation
   localparam NO_WRITE_BURST      = 1'b1;     // 1=single write only
   localparam [12:0] MODE         = {3'b000, NO_WRITE_BURST, OP_MODE,
                                     CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};

   localparam [13:0] sdram_startup_cycles = 14'd12100; // ~100us @ 100MHz
   localparam [13:0] cycles_per_refresh   = 14'd780;   // (64ms @ 100MHz)/8192
   localparam [13:0] startup_refresh_max  = 14'b1111_1111_1111_11;

   // SDRAM commands
   localparam [2:0] CMD_NOP          = 3'b111;
   localparam [2:0] CMD_ACTIVE       = 3'b011;
   localparam [2:0] CMD_READ         = 3'b101;
   localparam [2:0] CMD_WRITE        = 3'b100;
   localparam [2:0] CMD_PRECHARGE    = 3'b010;
   localparam [2:0] CMD_AUTO_REFRESH = 3'b001;
   localparam [2:0] CMD_LOAD_MODE    = 3'b000;

   // -------------------------------------------------------------------------
   // Internal signals
   // -------------------------------------------------------------------------

   typedef enum logic [3:0] {
      STATE_STARTUP,
      STATE_OPEN_1, STATE_OPEN_2,
      STATE_IDLE,   STATE_IDLE_1, STATE_IDLE_2, STATE_IDLE_3,
      STATE_IDLE_4, STATE_IDLE_5, STATE_IDLE_6, STATE_IDLE_7
   } state_t;

   state_t        state;

   logic [13:0]   refresh_count;
   logic [2:0]    command;
   logic [24:0]   save_addr;
   logic          save_word;
   logic          save_we;

   logic [15:0]   data;
   logic [CAS_LATENCY:0] data_ready_delay;

   logic          old_we, old_rd;
   logic [15:0]   new_data;
   logic          new_we, new_rd;

   // SDRAM DQ tri-state handling
   logic [15:0]   dq_out;
   logic          dq_oe;
   wire  [15:0]   dq_in = SDRAM_DQ;

   // -------------------------------------------------------------------------
   // Static assignments
   // -------------------------------------------------------------------------

   assign SDRAM_CKE  = 1'b1;
   assign SDRAM_nCS  = 1'b0;
   assign SDRAM_nRAS = command[2];
   assign SDRAM_nCAS = command[1];
   assign SDRAM_nWE  = command[0];

   // byte masks from address bits
   always_comb begin
      {SDRAM_DQMH, SDRAM_DQML} = SDRAM_A[12:11];
   end

   // Tri-state DQ bus
   assign SDRAM_DQ = dq_oe ? dq_out : 16'hZZZZ;

   // CPU data output
   assign dout = data;

   // -------------------------------------------------------------------------
   // Main SDRAM control state machine
   // -------------------------------------------------------------------------

   always_ff @(posedge clk) begin
      // default values each cycle
      command          <= CMD_NOP;
      dq_oe            <= 1'b0;
      dq_out           <= 16'h0000;
      refresh_count    <= refresh_count + 14'd1;
      data_ready_delay <= {1'b0, data_ready_delay[CAS_LATENCY:1]};

      // data ready pipeline
      if (data_ready_delay[0]) begin
         ready <= 1'b1;
         data  <= dq_in;
      end

      case (state)
         // --------------------------------------------------------------
         // Startup sequence
         // --------------------------------------------------------------
         STATE_STARTUP: begin
            SDRAM_A  <= 13'd0;
            SDRAM_BA <= 2'b00;

            if (refresh_count == startup_refresh_max - 14'd31) begin
               command     <= CMD_PRECHARGE;
               SDRAM_A[10] <= 1'b1;  // all banks
               SDRAM_BA    <= 2'b00;
            end
            if (refresh_count == startup_refresh_max - 14'd23) begin
               command     <= CMD_AUTO_REFRESH;
            end
            if (refresh_count == startup_refresh_max - 14'd15) begin
               command     <= CMD_AUTO_REFRESH;
            end
            if (refresh_count == startup_refresh_max - 14'd7) begin
               command     <= CMD_LOAD_MODE;
               SDRAM_A     <= MODE;
            end

            if (!refresh_count) begin
               state         <= STATE_IDLE;
               ready         <= 1'b1;
               refresh_count <= 14'd0;
            end
         end

         // --------------------------------------------------------------
         // Idle / refresh handling
         // --------------------------------------------------------------
         STATE_IDLE_7: state <= STATE_IDLE_6;
         STATE_IDLE_6: state <= STATE_IDLE_5;
         STATE_IDLE_5: state <= STATE_IDLE_4;
         STATE_IDLE_4: state <= STATE_IDLE_3;
         STATE_IDLE_3: state <= STATE_IDLE_2;
         STATE_IDLE_2: state <= STATE_IDLE_1;

         STATE_IDLE_1: begin
            state <= STATE_IDLE;
            // mask possible refresh to reduce collisions
            if (refresh_count > cycles_per_refresh) begin
               state         <= STATE_IDLE_7;
               command       <= CMD_AUTO_REFRESH;
               refresh_count <= 14'd0;
            end
         end

         STATE_IDLE: begin
            // Priority: issue refresh if overdue
            if (refresh_count > (cycles_per_refresh << 1)) begin
               state <= STATE_IDLE_1;
            end
            else if (new_rd || new_we) begin
               new_we    <= 1'b0;
               new_rd    <= 1'b0;
               save_addr <= addr;
               save_we   <= new_we;
               save_word <= word;

               state     <= STATE_OPEN_1;
               command   <= CMD_ACTIVE;
               SDRAM_A   <= addr[13:1];
               SDRAM_BA  <= addr[24:23];
            end
         end

         // --------------------------------------------------------------
         // Row open / column access
         // --------------------------------------------------------------
         STATE_OPEN_1: begin
            state <= STATE_OPEN_2;
         end

         STATE_OPEN_2: begin
            SDRAM_A <= { save_word ? 2'b00 :
                         {save_we & ~save_addr[0], save_we & save_addr[0]},
                         2'b10, save_addr[22:14] };

            if (save_we) begin
               command <= CMD_WRITE;
               dq_out  <= new_data;
               dq_oe   <= 1'b1;
               ready   <= 1'b1;
               state   <= STATE_IDLE_2;
            end
            else begin
               command                 <= CMD_READ;
               data_ready_delay[CAS_LATENCY] <= 1'b1;
               state                   <= STATE_IDLE_5;
            end
         end

      endcase

      // --------------------------------------------------------------
      // Async init
      // --------------------------------------------------------------
      if (init) begin
         state         <= STATE_STARTUP;
         refresh_count <= startup_refresh_max - sdram_startup_cycles;
         ready         <= 1'b0;
         data_ready_delay <= '0;
      end

      // --------------------------------------------------------------
      // Edge detection for we/rd
      // --------------------------------------------------------------
      old_we <= we;
      if (we && !old_we) begin
         ready   <= 1'b0;
         new_we  <= 1'b1;
         new_data<= din;
      end

      old_rd <= rd;
      if (rd && !old_rd) begin
         if (ready && !save_we && (save_addr[24:1] == addr[24:1])) begin
            save_addr <= addr;
         end
         else begin
            ready  <= 1'b0;
            new_rd <= 1'b1;
         end
      end
   end

   // -------------------------------------------------------------------------
   // SDRAM clock generation (same-edge DDR)
   // -------------------------------------------------------------------------

   ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE")
   ) sdramclk_ddr (
      .C  (clk),
      .CE (1'b1),
      .D1 (1'b0),
      .D2 (1'b1),
      .Q  (SDRAM_CLK),
      .R  (1'b0),
      .S  (1'b0)
   );

endmodule
