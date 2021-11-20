`timescale 1ns/1ns
module rsign_tb #(
    parameter FM_DEPTH  = 64,
    parameter CORE_SIZE = 9
) (
);

reg 		clk, rstn, data_in_valid;
reg  [15:0] para_in [FM_DEPTH-1:0];
reg  [15:0] data_in [FM_DEPTH-1:0][CORE_SIZE-1:0];
wire 		data_out[FM_DEPTH-1:0][CORE_SIZE-1:0];

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
	for (k = 0; k < FM_DEPTH; k=k+1) begin
		para_in[k] = $random;
	end
end

genvar i, j;
generate
    for (i = 0; i < FM_DEPTH; i=i+1) begin
		for (j = 0; j < CORE_SIZE; j=j+1 ) begin
        	always @(posedge clk ) begin
        	    if (cnt == 15)
        	        data_in[i][j] <= $random;
        	    else
        	        data_in[i][j] <= data_in[i][j];
        	end
		end
    end
endgenerate

rsign #(
	.FM_DEPTH (FM_DEPTH ),
	.CORE_SIZE(CORE_SIZE)
) u_rsign(
	.clk            (clk),
	.rstn           (rstn),
	.data_in_valid  (data_in_valid),
	.para_in		(para_in),
	.data_in        (data_in),
	.data_out       (data_out)
);

endmodule