module bn_res
#(
    parameter DATA_WIDTH   = 16,
    parameter PARA_WIDTH   = 16,
    parameter CHANNEL_NUM  = 128,
	parameter FM_DEPTH	   = 64
)
(
    // GLOBAL SIGNALS
    input   wire                    			clk             ,    			// System Clock
    input   wire                    			rstn            ,    			// System Reset, Active LOW
    input   wire                    			data_in_valid   ,    			// DATA Enable signal, Active HIGH
    input   wire signed [PARA_WIDTH - 1 : 0] 	bn_a     [CHANNEL_NUM - 1 : 0],	// Parameter of BN
    input   wire signed [PARA_WIDTH - 1 : 0] 	bn_b     [CHANNEL_NUM - 1 : 0],	// Parameter of BN
    input   wire signed [DATA_WIDTH - 1 : 0] 	res      [FM_DEPTH - 1    : 0],	// Residual
    input   wire signed [7 : 0] 				data_in  [CHANNEL_NUM - 1 : 0],	// Data from partial_sum
    output  wire signed [DATA_WIDTH - 1 : 0] 	data_out [CHANNEL_NUM - 1 : 0],	// Data to RPReLU
    output  reg                     			data_out_valid              	// DATA Enable signal to RPReLU
);

reg  signed [23 : 0] product  [CHANNEL_NUM - 1 : 0];
wire signed [23 : 0] data_tmp [CHANNEL_NUM - 1 : 0];

genvar i;
generate
	for(i = 0; i < CHANNEL_NUM; i = i + 1) begin
		always @(posedge clk or negedge rstn) begin    
	        if(~rstn) begin
	            data_out_valid  <= 0;
	            product[i] 		<= 0;
	        end 
			else begin
				if(data_in_valid) begin
	            	data_out_valid  <= 1;
	            	product[i] 		<= bn_a[i] * data_in[i];
	        	end 
				else begin
	            	data_out_valid  <= 0;
	            	product[i] 		<= product[i];
				end
	        end
	    end

		if (i < FM_DEPTH)
			assign data_tmp[i] = product[i] + bn_b[i]  + res[i];
		else
			assign data_tmp[i] = product[i] + bn_b[i];
		
		assign data_out[i] = (data_tmp[i][23]==1) ? ((data_tmp[i][22:15] == 8'hff) ? data_tmp[i][15:0] : 16'h8000)
						   					      : ((data_tmp[i][22:15] == 8'h00) ? data_tmp[i][15:0] : 16'h7fff);
	end
endgenerate

endmodule // bn_res_layer4