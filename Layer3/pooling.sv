module pooling #(
    parameter FM_DEPTH = 64
) (
    input   wire clk,
    input   wire rstn,
    input   wire data_in_valid,
    input   wire signed [15:0] pooling_in[FM_DEPTH-1:0][3:0],
    output  wire signed [15:0] pooling_out[FM_DEPTH-1:0]
);

reg signed [17:0] pooling_out_reg[FM_DEPTH-1:0];

genvar i;
generate
	for (i = 0; i< FM_DEPTH; i=i+1) begin:build_pooling_core
        always @(posedge clk or negedge rstn) begin
            if (~rstn)
                pooling_out_reg[i] <= 18'b0;
            else begin
                if (data_in_valid)
                    pooling_out_reg[i] <= (pooling_in[i][0] + pooling_in[i][1] + pooling_in[i][2] + pooling_in[i][3]);
                else
                    pooling_out_reg[i] <= pooling_out_reg[i];
            end     
        end
        assign pooling_out[i] =  pooling_out_reg[i][17:2];
    end
    
endgenerate

endmodule