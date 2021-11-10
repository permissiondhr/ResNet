module wrapper #(
	parameter FM_DEPTH  = 64,
	parameter FM_WIDTH  = 56,
	parameter CORE_SIZE = 9
) (
	input       			clk,
	input       			rstn,
	input       			verticle_sync,	// Verticle sync signal, start of one frame
	input       			mode_in,    	// Load parameter when disserted, Calculate when asserted
	input					data_in_valid,	// Data enable signal
	input		[15:0] 		data_in	[FM_DEPTH-1:0],
	output					data_out_valid,
	output					vs_next,
	output 					latch_to_macro,					
	output 					adc_to_macro,
	output					enable_to_macro,
	output reg	[15:0]		data_out[FM_DEPTH-1:0][CORE_SIZE-1:0],
	output reg  [15:0] 		res 	[FM_DEPTH-1:0][3:0]// To residual module
);

// Internal signals
reg [15:0] 	conv_core[FM_DEPTH-1:0][CORE_SIZE-1:0];	// Convolution core
//reg [15:0]	data_in_reg[FM_DEPTH-1:0];	// Store the data_in signal when data_in_valid is asserted
reg	[2:0]	cnt;						// Input data_in comes every 8 cycles
reg [5:0]	row_num, col_num;			// Used to record current conv_core position
reg 		conv_core_invalid;			// Indicates that first 2 row of input is useless, data_out_valid keeps low when this signal is high
reg [6:0]	sram_addr_reg;				// Used to determine the sram r/w address
reg [3:0]	cnt_latch_adc;				// Used to generate latch_to_macro and adc_to_macro signal
wire		edge_l, edge_b;				// 0 indicates normal, 1 indicates conv_core is at left or bottom edge,
//wire		sram_clk;					// Reverse clk, used in sram r/w, so SRAM r/w operations occur at negedge of clk (posedge of clkn)
//wire 		sram_w_en;					// SRAM write enable signal
wire[6:0]	sram_addr;					// Basically equals sram_addr_reg, but has a slight change
//wire[15:0]	sram_data_in [FM_DEPTH-1:0];// Data input to SRAM
//wire[15:0]	sram_data_out[FM_DEPTH-1:0];// Data output from SRAM

// Reverse clk
//assign sram_clk = ~clk;

// Change to register, do not need data_in_reg anymore
//genvar j;
//generate
//	for (j = 0; j < FM_DEPTH; j = j + 1) begin
//		always @(posedge clk or negedge rstn) begin
//			if ((~rstn) | verticle_sync | (~mode_in) )
//				data_in_reg[j] <= 0;
//			else begin
//				if (data_in_valid)
//					data_in_reg[j] <= data_in[j];
//				else
//					data_in_reg[j] <= data_in_reg[j];
//			end		
//		end
//	end
//endgenerate

always @(posedge clk or negedge rstn) begin
	if(~rstn)
		conv_core_invalid <= 1;
	else begin
		if ((row_num == 2) && (col_num == 1))
			conv_core_invalid <= 0;
		else ;
	end
end

// Input data_in comes every 8 cycles (or more cycles in other layer such as layer4)
always @(posedge clk or negedge rstn) begin
	if ((~rstn) | verticle_sync | (~mode_in) )
		cnt <= 0;
	else begin
		if (data_in_valid)
			cnt <= 0;
		else
			cnt <= cnt + 1;
	end
end

// Calculate row & column number
always @(posedge clk or negedge rstn) begin
	if ( (~rstn) | verticle_sync | (~mode_in) )
		col_num <= FM_WIDTH - 1;
	else begin
		if ( data_in_valid ) begin
			if ( col_num == FM_WIDTH-1 )
				col_num <= 0;
			else
				col_num <= col_num + 1;
		end
		else
			col_num <= col_num;
	end
end

always @(posedge clk or negedge rstn) begin
	if ((~rstn) | verticle_sync | (~mode_in))
		row_num <= FM_WIDTH - 1;
	else begin
		if ( data_in_valid & (col_num == FM_WIDTH-1) ) begin
			if ( row_num == FM_WIDTH-1 )
				row_num <= 0;
			else
				row_num <= row_num + 1;
		end
		else
			row_num <= row_num;
	end
end

// Decide whether conv_core is at left or bottom edge
assign edge_l = (col_num == 1) ? 1 : 0;
assign edge_b = (row_num == 0) ? 1 : 0;

// Calculate the SRAM address
always @(posedge clk or negedge rstn) begin
	if ((~rstn) | verticle_sync | (~mode_in))
		sram_addr_reg <= 0;
	else begin
		if (cnt == 0)
			sram_addr_reg <= col_num + (!row_num[0]) * FM_WIDTH + 1;
		else begin
			if (cnt == 1)
				sram_addr_reg <= col_num + (row_num[0]) * FM_WIDTH + 1;
			else
				sram_addr_reg <= sram_addr_reg;
		end
	end
end
assign sram_addr = (sram_addr_reg == 2*FM_WIDTH) ? 0 : sram_addr_reg;
//assign sram_w_en = (cnt == 0) ? 0 : 1;
//assign sram_data_in = data_in_reg;

reg	[15:0] sram_data_mem[FM_DEPTH-1 : 0][2*FM_WIDTH-1 : 0];

genvar i, j;
generate
	for (i = 0; i < FM_DEPTH; i=i+1) begin:build_conv_core
	//	S018SP_X32Y4D16_PM SMIC(
	//		. Q(sram_data_out[i]),
	//		. CLK(sram_clk),
	//		. CEN(1'b0),
	//		. WEN(sram_w_en),
	//		. A(sram_addr),
	//		. D(sram_data_in[i])
	//	);
		for (j = 0; j < 2*FM_WIDTH; j=j+1 ) begin
			always @(posedge clk or negedge rstn) begin
				if (~rstn)
					sram_data_mem[i][j] <= 16'b0;
				else begin
					if ((mode_in == 1) && (data_in_valid == 1))
						sram_data_mem[i][sram_addr] <= data_in[i];
					else ;
				end
			end
		end

		always @(posedge clk or negedge rstn) begin
			if((~rstn) | verticle_sync | (~mode_in)) begin
				conv_core[i][0] <= 16'd0 ;
				conv_core[i][1] <= 16'd0 ;
				conv_core[i][2] <= 16'd0 ;
				conv_core[i][3] <= 16'd0 ;
				conv_core[i][4] <= 16'd0 ;
				conv_core[i][5] <= 16'd0 ;
				conv_core[i][6] <= 16'd0 ;
				conv_core[i][7] <= 16'd0 ;
				conv_core[i][8] <= 16'd0 ;
			end
			else begin
				case (cnt)
					0:  begin
							conv_core[i][0] <= conv_core[i][0] ;
							conv_core[i][1] <= conv_core[i][1] ;
							conv_core[i][2] <= conv_core[i][2] ;
							conv_core[i][3] <= conv_core[i][3] ;
							conv_core[i][4] <= conv_core[i][4] ;
							conv_core[i][5] <= conv_core[i][5] ;
							conv_core[i][6] <= conv_core[i][6] ;
							conv_core[i][7] <= conv_core[i][7] ;
							//conv_core[i][8] <= data_in_reg[i]  ;
							conv_core[i][8] <= sram_data_mem[i][sram_addr];
						end
					1:  begin
							conv_core[i][0] <= conv_core[i][1] ;
							conv_core[i][1] <= conv_core[i][2] ;
							conv_core[i][2] <= conv_core[i][2] ;
							conv_core[i][3] <= conv_core[i][4] ;
							conv_core[i][4] <= conv_core[i][5] ;
							//conv_core[i][5] <= sram_data_out[i];
							conv_core[i][5] <= sram_data_mem[i][sram_addr];
							conv_core[i][6] <= conv_core[i][7] ;
							conv_core[i][7] <= conv_core[i][8] ;
							conv_core[i][8] <= conv_core[i][8] ;
						end		
					2:  begin
							conv_core[i][0] <= conv_core[i][0] ;
							conv_core[i][1] <= conv_core[i][1] ;
							//conv_core[i][2] <= sram_data_out[i];
							conv_core[i][2] <= sram_data_mem[i][sram_addr];
							conv_core[i][3] <= conv_core[i][3] ;
							conv_core[i][4] <= conv_core[i][4] ;
							conv_core[i][5] <= conv_core[i][5] ;
							conv_core[i][6] <= conv_core[i][6] ;
							conv_core[i][7] <= conv_core[i][7] ;
							conv_core[i][8] <= conv_core[i][8] ;
						end		
					default: ;
				endcase
			end
		end
		// Output
		always @(posedge clk or negedge rstn) begin
			if (~rstn) begin
				data_out[i][0] <= 16'b0;
				data_out[i][1] <= 16'b0;
				data_out[i][2] <= 16'b0;
				data_out[i][3] <= 16'b0;
				data_out[i][4] <= 16'b0;
				data_out[i][5] <= 16'b0;
				data_out[i][6] <= 16'b0;
				data_out[i][7] <= 16'b0;
				data_out[i][8] <= 16'b0;
				res[i][0] 	   <= 16'b0;
				res[i][1] 	   <= 16'b0;
				res[i][2] 	   <= 16'b0;
				res[i][3] 	   <= 16'b0;				
			end
			else begin
				if ((verticle_sync == 1) || (mode_in == 0)) begin
					data_out[i][0] <= 16'b0;
					data_out[i][1] <= 16'b0;
					data_out[i][2] <= 16'b0;
					data_out[i][3] <= 16'b0;
					data_out[i][4] <= 16'b0;
					data_out[i][5] <= 16'b0;
					data_out[i][6] <= 16'b0;
					data_out[i][7] <= 16'b0;
					data_out[i][8] <= 16'b0;
					res[i][0] 	   <= 16'b0;
					res[i][1] 	   <= 16'b0;
					res[i][2] 	   <= 16'b0;
					res[i][3] 	   <= 16'b0;					
				end
				else begin
					if (cnt == 1) begin
						data_out[i][0] <= (edge_l == 1) 				? 0 : conv_core[i][0];
						data_out[i][1] <= conv_core[i][1];
						data_out[i][2] <= conv_core[i][2];
						data_out[i][3] <= (edge_l == 1) 				? 0 : conv_core[i][3];
						data_out[i][4] <= conv_core[i][4];
						data_out[i][5] <= conv_core[i][5];
						data_out[i][6] <= ((edge_l==1) || (edge_b==1)) ? 0 : conv_core[i][6];
						data_out[i][7] <= (edge_b == 1) 				? 0 : conv_core[i][7];
						data_out[i][8] <= (edge_b == 1) 				? 0 : conv_core[i][8];	
						res[i][0]	   <= conv_core[i][1];
						res[i][1]	   <= conv_core[i][2];
						res[i][2]	   <= conv_core[i][4];
						res[i][3]	   <= conv_core[i][5];											
					end
					else;
				end	
			end
		end
	end
endgenerate

assign data_out_valid = (~rstn) 			? 0 : (
						(~mode_in)			? 0 : (
						verticle_sync		? 0 : (
						row_num[0]			? 0 : (
						~col_num[0]			? 0 : (
						conv_core_invalid 	? 0 : (
						(cnt == 2)			? 1 : 0))))));

// cnt_latch_adc starts counting when data_out_valid is high, continue for 12 clock cycles and return to 0
always @(posedge clk or negedge rstn) begin
	if (~rstn)
		cnt_latch_adc <= 0;
	else begin
		if (data_out_valid == 1)
			cnt_latch_adc <= 1;
		else begin
			case (cnt_latch_adc)
				0:  	 cnt_latch_adc <= 0;
				11: 	 cnt_latch_adc <= 0;
				default: cnt_latch_adc <= cnt_latch_adc + 1;
			endcase
		end	
	end
end

assign adc_to_macro = ((cnt_latch_adc > 4) && (cnt_latch_adc < 8)) ? 1 : 0;	// adc high when cntla 5~7
assign latch_to_macro   = (cnt_latch_adc > 7) ? 1 : 0;						// latch high when cntla 8~11 
assign enable_to_macro = ((cnt_latch_adc == 0) && (data_out_valid == 0)) ? 0 : 1;						// enable hign wehn cntla != 0
assign vs_next = (conv_core_invalid == 0) && (row_num == 2) && (col_num == 0) && (cnt == 7);

endmodule