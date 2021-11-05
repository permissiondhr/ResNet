module bn_res_layer4
#(
    parameter DATA_WIDTH   = 16,
    parameter PARA_WIDTH   = 16,
    parameter CHANNEL_NUM  = 128
)
(
    // GLOBAL SIGNALS
    input   wire                    			clk             ,    			// System Clock
    input   wire                    			rstn            ,    			// System Reset, Active LOW
    input   wire                    			data_in_valid   ,    			// DATA Enable signal, Active HIGH
    input   wire                    			mode_in         ,
    input   wire signed [PARA_WIDTH - 1 : 0] 	bn_a     [CHANNEL_NUM - 1 : 0],	// Parameter of BN
    input   wire signed [PARA_WIDTH - 1 : 0] 	bn_b     [CHANNEL_NUM - 1 : 0],	// Parameter of BN
    input   wire signed [DATA_WIDTH - 1 : 0] 	res      [CHANNEL_NUM - 1 : 0],	// Residual
    input   wire signed [DATA_WIDTH - 1 : 0] 	data_in  [CHANNEL_NUM - 1 : 0],	// Data from partial_sum
    output  wire signed [DATA_WIDTH - 1 : 0] 	data_out [CHANNEL_NUM - 1 : 0],	// Data to RPReLU
    output  reg                     			data_out_valid              	// DATA Enable signal to RPReLU
);

reg signed [PARA_WIDTH + DATA_WIDTH : 0] product [CHANNEL_NUM - 1 : 0];

genvar i;
generate
	for(i = 0; i < CHANNEL_NUM; i = i + 1) begin
		always @(posedge clk or negedge rstn) begin    
	        if(~rstn) begin
	            data_out_valid  <= 0;
	            product[i] 		<= 0;
	        end else if(mode_in && data_in_valid) begin
	            data_out_valid  <= 1;
	            product[i] 		<= bn_a[i] * data_in[i];
	        end else begin
	            data_out_valid  <= 0;
	            product[i] 		<= data_out[i];
	        end
	    end
		if (i < CHANNEL_NUM/2)
			assign data_out[i] = {{product[i] + bn_b[i]} >> 8 } + res[i];
		else
			assign data_out[i] = {product[i] + bn_b[i]} >> 8;
	end
endgenerate

endmodule // bn_res_layer4