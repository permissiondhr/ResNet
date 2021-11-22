module wrapper #(
	parameter FM_DEPTH  = 64,
	parameter FM_WIDTH  = 56,
	parameter CORE_SIZE = 9
) (
	input  wire 		      	clk,
	input  wire 		      	rstn,
	input  wire 		      	verticle_sync,				// Verticle sync signal, start of one frame
	input  wire 		      	mode_in,    				// Load parameter when disserted, Calculate when asserted
	input  wire					data_in_valid,				// Data enable signal
	input  wire	signed	[15:0] 	data_in	[FM_DEPTH-1:0],
	output wire					data_out_valid,
	output wire					vs_next,
	output wire 				adc_to_macro,
	output wire					enable_to_macro,
	output wire					data_to_partial_valid,
	output wire signed	[15:0]	data_out[FM_DEPTH-1:0][CORE_SIZE-1:0],
	output wire signed  [15:0] 	res 	[FM_DEPTH-1:0][3:0]	// To residual module
);

// Internal signals
reg			[15:0] 	data_mem[FM_DEPTH-1:0][2*FM_WIDTH+2:0];
wire		[15:0]	conv_core[FM_DEPTH-1:0][CORE_SIZE-1:0];
reg			[2:0]	cnt;						// Input data_in comes every 2 cycles
reg 		[5:0]	row_num, col_num;			// Used to record current conv_core position
reg 				conv_core_invalid;			// Indicates that first 2 row of input is useless, data_out_valid keeps low when this signal is high
reg  signed	[7:0]	mem_addr;				// Used to determine register array address
reg 		[3:0]	cnt_adc;				// Used to generate latch_to_macro and adc_to_macro signal
wire				edge_l, edge_b;				// 0 indicates normal, 1 indicates conv_core is at left or bottom edge,

always @(posedge clk or negedge rstn) begin
	if(~rstn)
		conv_core_invalid <= 1;
	else begin
		if ((row_num == 2) && (col_num == 0))
			conv_core_invalid <= 0;
		else ;
	end
end

// Input data_in comes every 2 cycles
always @(posedge clk or negedge rstn) begin
	if (~rstn)
		cnt <= 0;
	else begin
		if (verticle_sync || (~mode_in))
			cnt <= 0;
		else begin
			if (data_in_valid)
				cnt <= 1;
			else begin
				if( cnt == 0)
					cnt <= 0;
				else
					cnt <= cnt + 1;
			end
		end
	end
end

// Calculate row & column number
always @(posedge clk or negedge rstn) begin
	if (~rstn)
		col_num <= FM_WIDTH - 1;
	else begin
		if (verticle_sync || (~mode_in))
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
end

always @(posedge clk or negedge rstn) begin
	if (~rstn)
		row_num <= FM_WIDTH - 1;
	else begin
		if (verticle_sync || (~mode_in))
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
end

// Decide whether conv_core is at left or bottom edge
assign edge_l = (col_num == 1) ? 1 : 0;
assign edge_b = (row_num == 0) ? 1 : 0;

// Calculate the memory address, mem_addr counts from 0 to 2*FMWIDTH+2
always @(posedge clk or negedge rstn) begin
	if (~rstn)
		mem_addr <= 0;
	else begin
		if (verticle_sync || (~mode_in))
			mem_addr <= 0;
		else begin
			if (data_in_valid) begin
				if (mem_addr == 2*FM_WIDTH+2)
					mem_addr <= 0;
				else
					mem_addr <= mem_addr + 1;
			end
			else ;
		end
	end
end

// Store input data to data_mem[mem_addr]
genvar i;
generate
	integer j, k;
	for (i = 0; i < FM_DEPTH; i=i+1) begin:build_conv_core
		always @(posedge clk or negedge rstn) begin
			if (~rstn)
				for (j = 0; j < 2*FM_WIDTH+3; j=j+1 ) begin
					data_mem[i][j] <= 16'b0;
				end
			else begin
				if (verticle_sync || (~mode_in))
					for (k = 0; k < 2*FM_WIDTH+3; k=k+1 ) begin
						data_mem[i][k] <= 16'b0;
					end
				else begin
					if (data_in_valid == 1)
						data_mem[i][mem_addr] <= data_in[i];
					else ;
				end
			end
		end
		assign conv_core[i][0] = (mem_addr-1-114 < 0) ? data_mem[i][mem_addr-1-114+115] : data_mem[i][mem_addr-1-114] ;
		assign conv_core[i][1] = (mem_addr-1-113 < 0) ? data_mem[i][mem_addr-1-113+115] : data_mem[i][mem_addr-1-113] ;
		assign conv_core[i][2] = (mem_addr-1-112 < 0) ? data_mem[i][mem_addr-1-112+115] : data_mem[i][mem_addr-1-112] ;
		assign conv_core[i][3] = (mem_addr-1-58  < 0) ? data_mem[i][mem_addr-1-58 +115] : data_mem[i][mem_addr-1-58 ] ;
		assign conv_core[i][4] = (mem_addr-1-57  < 0) ? data_mem[i][mem_addr-1-57 +115] : data_mem[i][mem_addr-1-57 ] ;
		assign conv_core[i][5] = (mem_addr-1-56  < 0) ? data_mem[i][mem_addr-1-56 +115] : data_mem[i][mem_addr-1-56 ] ;
		assign conv_core[i][6] = (mem_addr-1-2   < 0) ? data_mem[i][mem_addr-1-2  +115] : data_mem[i][mem_addr-1-2  ] ;
		assign conv_core[i][7] = (mem_addr-1-1   < 0) ? data_mem[i][mem_addr-1-1  +115] : data_mem[i][mem_addr-1-1  ] ;
		assign conv_core[i][8] = data_mem[i][mem_addr-1];

		assign data_out[i][0] = (edge_l == 1) 				? 0 : conv_core[i][0];
		assign data_out[i][1] = conv_core[i][1];
		assign data_out[i][2] = conv_core[i][2];
		assign data_out[i][3] = (edge_l == 1) 				? 0 : conv_core[i][3];
		assign data_out[i][4] = conv_core[i][4];
		assign data_out[i][5] = conv_core[i][5];
		assign data_out[i][6] = ((edge_l==1) || (edge_b==1))? 0 : conv_core[i][6];
		assign data_out[i][7] = (edge_b == 1) 				? 0 : conv_core[i][7];
		assign data_out[i][8] = (edge_b == 1) 				? 0 : conv_core[i][8];	
		assign res[i][0]	  = conv_core[i][1];
		assign res[i][1]	  = conv_core[i][2];
		assign res[i][2]	  = conv_core[i][4];
		assign res[i][3]	  = conv_core[i][5];
	end
endgenerate

assign data_out_valid = (~rstn) 			? 0 : (
						(~mode_in)			? 0 : (
						verticle_sync		? 0 : (
						row_num[0]			? 0 : (
						~col_num[0]			? 0 : (
						conv_core_invalid 	? 0 : (
						(cnt == 1)			? 1 : 0))))));

// cnt_adc starts counting when data_out_valid is high, continue for 12 clock cycles and return to 0
always @(posedge clk or negedge rstn) begin
	if (~rstn)
		cnt_adc <= 0;
	else begin
		if (data_out_valid == 1)
			cnt_adc <= 1;
		else begin
			case (cnt_adc)
				0:  	 cnt_adc <= 0;
				2: 	 	 cnt_adc <= 0;
				default: cnt_adc <= cnt_adc + 1;
			endcase
		end	
	end
end

assign adc_to_macro 	= (cnt_adc == 1) ? 0 : 1;
assign enable_to_macro 	= (cnt_adc == 0) ? 0 : 1;	// enable hign wehn cnt_adc != 0
assign data_to_partial_valid = (cnt_adc == 2) ? 1 : 0;
assign vs_next 			= (conv_core_invalid == 0) && (row_num == 2) && (col_num == 0) && (cnt == 2);

endmodule