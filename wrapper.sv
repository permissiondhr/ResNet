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
	input		[15:0] 	data_in[FM_DEPTH-1:0],
	output					data_out_valid,
	output					vs_next,
	output 		[15:0]	data_out[FM_DEPTH-1:0][CORE_SIZE-1:0],
	output 	 	[15:0] 	C [FM_DEPTH-1:0][3:0]// To residual module
);

// Internal signals
reg [15:0] 	conv_core[FM_DEPTH-1:0][CORE_SIZE-1:0];	// Convolution core
reg [15:0]	data_in_reg[FM_DEPTH-1:0];	// Store the data_in signal when data_in_valid is asserted
reg	[2:0]	cnt;						// Input data_in comes every 8 cycles
reg [5:0]	row_num, col_num;			// Used to record current conv_core position
reg [6:0]	sram_addr_reg;				// Used to determine the sram r/w address
wire		edge_l, edge_b;				// 0 indicates normal, 1 indicates conv_core is at left or bottom edge,
wire		sram_clk;					// Reverse clk, used in sram r/w, so SRAM r/w operations occur at negedge of clk (posedge of clkn)
wire 		sram_w_en;					// SRAM write enable signal
wire[6:0]	sram_addr;					// Basically equals sram_addr_reg, but has a slight change
wire[15:0]	sram_data_in [FM_DEPTH-1:0];// Data input to SRAM
wire[15:0]	sram_data_out[FM_DEPTH-1:0];// Data output from SRAM
// Reverse clk
assign sram_clk = ~clk;

// Data_in_reg

genvar j, k;
generate
	for (j = 0; j < FM_DEPTH; j = j + 1) begin
		for (k = 0; k < CORE_SIZE; k = k + 1) begin
			always @(posedge clk or negedge rstn) begin
				if ((~rstn) | verticle_sync | (~mode_in) )
					data_in_reg[j][k] <= 0;
				else begin
					if (data_in_valid)
						data_in_reg[j][k] <= data_in[j][k];
					else
						data_in_reg[j][k] <= data_in_reg[j][k];
				end
			end			
		end
	end
endgenerate

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
		col_num <= 0;
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
		row_num <= 0;
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
assign edge_b = (row_num == FM_WIDTH-1) ? 1 : 0;

// Calculate the SRAM address
always @(posedge clk or negedge rstn) begin
	if ((~rstn) | verticle_sync | (~mode_in))
		sram_addr_reg <= 0;
	else begin
		if (cnt == 1)
			sram_addr_reg <= col_num + (~row_num[0]) * FM_WIDTH + 1;
		else begin
			if (cnt == 2)
				sram_addr_reg <= col_num + (row_num[0]) * FM_WIDTH + 1;
			else
				sram_addr_reg <= sram_addr_reg;
		end
	end
end
assign sram_addr = (sram_addr_reg == 2*FM_WIDTH) ? 0 : sram_addr_reg;
assign sram_w_en = (cnt == 0) ? 0 : 1;
assign sram_data_in = data_in_reg;

genvar i ;
generate
	for (i = 0; i < FM_DEPTH; i=i+1) begin:build_conv_core
		S018SP_X32Y4D16_PM SMIC(
			. Q(sram_data_out[i]),
			. CLK(sram_clk),
			. CEN(1'b0),
			. WEN(sram_w_en),
			. A(sram_addr),
			. D(sram_data_in[i])
		);

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
				if(cnt == 0) begin
					conv_core[i][0] <= conv_core[i][0] ;
					conv_core[i][1] <= conv_core[i][1] ;
					conv_core[i][2] <= conv_core[i][2] ;
					conv_core[i][3] <= conv_core[i][3] ;
					conv_core[i][4] <= conv_core[i][4] ;
					conv_core[i][5] <= conv_core[i][5] ;
					conv_core[i][6] <= conv_core[i][6] ;
					conv_core[i][7] <= conv_core[i][7] ;						 
					conv_core[i][8] <= data_in_reg[i]  ;
				end
				if(cnt == 1) begin
					conv_core[i][0] <= conv_core[i][1] ;
					conv_core[i][3] <= conv_core[i][4] ;
					conv_core[i][6] <= conv_core[i][7] ;
					conv_core[i][1] <= conv_core[i][2] ;
					conv_core[i][4] <= conv_core[i][5] ;
					conv_core[i][7] <= conv_core[i][8] ;
					conv_core[i][5] <= sram_data_out[i];
					conv_core[i][2] <= conv_core[i][2] ;
					conv_core[i][8] <= conv_core[i][8] ;
				end 
				if(cnt == 2) begin
					conv_core[i][0] <= conv_core[i][0] ;
					conv_core[i][1] <= conv_core[i][1] ;
					conv_core[i][2] <= sram_data_out[i];
					conv_core[i][3] <= conv_core[i][3] ;
					conv_core[i][4] <= conv_core[i][4] ;
					conv_core[i][5] <= conv_core[i][5] ;
					conv_core[i][6] <= conv_core[i][6] ;
					conv_core[i][7] <= conv_core[i][7] ;
					conv_core[i][8] <= conv_core[i][8] ;
				end
				else begin
					conv_core[i][0] <= conv_core[i][0] ;
					conv_core[i][1] <= conv_core[i][1] ;
					conv_core[i][2] <= conv_core[i][2] ;
					conv_core[i][3] <= conv_core[i][3] ;
					conv_core[i][4] <= conv_core[i][4] ;
					conv_core[i][5] <= conv_core[i][5] ;
					conv_core[i][6] <= conv_core[i][6] ;
					conv_core[i][7] <= conv_core[i][7] ;
					conv_core[i][8] <= conv_core[i][8] ;
				end
			end
		end
		// Output
		assign data_out[i][0] = (edge_l == 1) 				? 0 : conv_core[i][0];
		assign data_out[i][1] = conv_core[i][1];
		assign data_out[i][2] = conv_core[i][2];
		assign data_out[i][3] = (edge_l == 1) 				? 0 : conv_core[i][3];
		assign data_out[i][4] = conv_core[i][4];
		assign data_out[i][5] = conv_core[i][5];
		assign data_out[i][6] = ((edge_l==1) | (edge_b==0)) ? 0 : conv_core[i][6];
		assign data_out[i][7] = (edge_b == 1) 				? 0 : conv_core[i][7];
		assign data_out[i][8] = (edge_b == 1) 				? 0 : conv_core[i][8];

		assign C[i][0]		  = conv_core[i][1];
		assign C[i][1]		  = conv_core[i][2];
		assign C[i][2]		  = conv_core[i][4];
		assign C[i][3]		  = conv_core[i][5];
	end
endgenerate

assign data_out_valid = (~rstn) 		? 0 : (
						(~mode_in)		? 0 : (
						(verticle_sync)	? 0 : (
						row_num[0]		? 0 : (
						~col_num[0]		? 0 : (
						(cnt == 1)		? 1 : 0)))));

endmodule