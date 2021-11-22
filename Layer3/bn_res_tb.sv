`timescale 1ns/1ns
module bn_res_tb #(
	parameter DATA_WIDTH   = 16,
	parameter PARA_WIDTH   = 16,
	parameter CHANNEL_NUM  = 128,
	parameter FM_DEPTH = 64
) (
);

reg 								clk, rstn, data_in_valid;
reg 		[PARA_WIDTH - 1 : 0] 	bn_a     [CHANNEL_NUM - 1 : 0];
reg 		[PARA_WIDTH - 1 : 0] 	bn_b     [CHANNEL_NUM - 1 : 0];
reg 		[DATA_WIDTH - 1 : 0] 	res      [FM_DEPTH - 1 : 0];
reg  signed	[7 : 0]					data_in  [CHANNEL_NUM-1:0];
wire signed	[DATA_WIDTH - 1 : 0]	data_out [CHANNEL_NUM-1:0];
wire								data_out_valid;

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

integer k;
initial begin
	for (k = 0; k < CHANNEL_NUM; k=k+1) begin
		bn_a[k] = $random;
		bn_b[k] = $random;
		res [k] = $random;
	end
end

genvar i, j;
generate
    for (i = 0; i < CHANNEL_NUM; i=i+1) begin
		always @(posedge clk ) begin
			if (cnt == 15)
				data_in[i] <= $random;
			else
				data_in[i] <= data_in[i];
		end
    end
endgenerate

bn_res #(
	.DATA_WIDTH  (DATA_WIDTH ),
	.PARA_WIDTH 	(PARA_WIDTH ),
	.CHANNEL_NUM (CHANNEL_NUM)
) u_bn_res(
	.clk            (clk),
	.rstn           (rstn),
	.data_in_valid  (data_in_valid),
	.data_in        (data_in),
	.bn_a			(bn_a),
	.bn_b			(bn_b),
	.res			(res),
	.data_out_valid (data_out_valid),
	.data_out       (data_out)
);

endmodule