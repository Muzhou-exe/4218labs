`timescale 1ns / 1ps

/* 
----------------------------------------------------------------------------------
--	(c) Rajesh C Panicker, NUS
--  Description : Template for the Matrix Multiply unit for the AXI Stream Coprocessor
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post a modified version of this on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of any entity.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course EE4218 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

// those outputs which are assigned in an always block of matrix_multiply shoud be changes to reg (such as output reg Done).

module matrix_multiply
	#(	parameter width = 8, 
		parameter A_depth_bits = 3, 
		parameter B_depth_bits = 2, 
		parameter RES_depth_bits = 1
	) 
	(
		input wire clk,										
		input wire Start,
		output reg Done,
		
		output reg A_read_en,
		output reg [A_depth_bits-1:0] A_read_address, 
		input wire [width-1:0] A_read_data_out,
		
		output reg B_read_en, 
		output reg [B_depth_bits-1:0] B_read_address, 
		input wire [width-1:0] B_read_data_out,
		
		output reg RES_write_en, 
		output reg [RES_depth_bits-1:0] RES_write_address, 
		output reg [width-1:0] RES_write_data_in 
	);
	
    localparam integer N = (1<<B_depth_bits);
    localparam integer M = (1<<RES_depth_bits);
    
    localparam S_IDLE  = 3'd0;
    localparam S_READ  = 3'd1;
    localparam S_WAIT  = 3'd5; 
    localparam S_ACCUM = 3'd2;
    localparam S_WRITE = 3'd3;
    localparam S_DONE  = 3'd4;
    
    reg [2:0] state = S_IDLE;
    reg [RES_depth_bits-1:0] row;
    reg [B_depth_bits-1:0]   k;
    reg [17:0] acc;
    
    wire [A_depth_bits-1:0] a_addr = row * N + k;
    
    always @(posedge clk) begin
        Done         <= 0;
        A_read_en    <= 0;
        B_read_en    <= 0;
        RES_write_en <= 0;
    
        case (state)
          S_IDLE: begin
            row <= 0;
            k   <= 0;
            acc <= 0;
            if (Start) state <= S_READ;
          end
    
          S_READ: begin
            A_read_en      <= 1;
            A_read_address <= a_addr;
            B_read_en      <= 1;
            B_read_address <= k;
            state <= S_WAIT; 
          end
          
          S_WAIT: begin
            A_read_en <= 1;
            B_read_en <= 1;
            state <= S_ACCUM;
          end
    
          S_ACCUM: begin
            acc <= acc + (A_read_data_out * B_read_data_out);
            if (k == N-1) begin
              state <= S_WRITE;
            end else begin
              k <= k + 1;
              state <= S_READ; 
            end
          end
    
          S_WRITE: begin
            RES_write_en      <= 1;
            RES_write_address <= row;
            RES_write_data_in <= acc[7:0]; 
            
            acc <= 0;
            k   <= 0;
            
            if (row == M-1) begin
              state <= S_DONE;
            end else begin
              row <= row + 1;
              state <= S_READ; 
            end
          end
    
          S_DONE: begin
            Done  <= 1;
            state <= S_IDLE;
          end
    
          default: state <= S_IDLE;
        endcase
    end

endmodule
