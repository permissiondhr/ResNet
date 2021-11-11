`timescale 1ns/1ns
module partial_sum_tb #(
    parameter CHANNEL_NUM  = 128,
    parameter MACRO_NUM = 4
) (
);

reg 		clk, rstn, data_in_valid;
reg  [3:0] 	data_in [CHANNEL_NUM-1:0][MACRO_NUM-1:0];
wire [5:0]	data_out[CHANNEL_NUM-1:0];
wire		data_out_valid;

reg  [3:0] 	cnt;
initial begin
    clk = 0;
	cnt = 0;
end
always #5 clk = ~clk;

initial begin
    #44
    rstn = 0;
    #50
    rstn = ~rstn;
end

always @(posedge clk) begin
    cnt <= cnt + 1;
end

initial begin
    data_in_valid = 0;
end
always @(posedge clk ) begin
    if (cnt == 15)
        data_in_valid <= 1;
    else
        data_in_valid <= 0;
end

genvar i, j;
generate
    for (i = 0; i < CHANNEL_NUM; i=i+1) begin
		for (j = 0; j < MACRO_NUM; j=j+1 ) begin
        	always @(posedge clk ) begin
        	    if (cnt == 15)
        	        data_in[i][j] <= $random;
        	    else
        	        data_in[i][j] <= data_in[i][j];
        	end
		end
    end
endgenerate

partial_sum #(
	.CHANNEL_NUM (CHANNEL_NUM),
	.MACRO_NUM	 (MACRO_NUM)
) u_partial_sum(
	.clk            (clk),
	.rstn           (rstn),
	.data_in_valid  (data_in_valid),
	.data_in        (data_in),
	.data_out_valid (data_out_valid),
	.data_out       (data_out)
);

endmodule