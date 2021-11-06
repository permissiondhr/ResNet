`timescale 1ns/1ps
module wrapper_tb #(
    parameter FM_DEPTH  = 64,
    parameter FM_WIDTH  = 56,
    parameter CORE_SIZE = 9
) (
);

reg clk, rstn, mode_in, verticle_sync, data_in_valid;
reg  	[15:0] 	data_in[FM_DEPTH-1:0];
wire data_out_valid, vs_next;
wire 	[15:0]	data_out[FM_DEPTH-1:0][CORE_SIZE-1:0];
wire  	[15:0] 	C [FM_DEPTH-1:0][3:0];

reg [2:0]cnt;

initial begin
    $dumpfile("wrapper.vcd");
    $dumpvars(0, wrapper_tb);
    # 10000
    $finish;
end

initial begin
    clk = 0;
    cnt = 0;
end
always #5 clk = ~clk;

initial begin
    rstn = 1;
    #7
    rstn = ~rstn;
    #7
    rstn = ~rstn;
end

initial begin
    mode_in = 0;
    verticle_sync = 1;
    #15
    mode_in = ~mode_in;
    verticle_sync = ~verticle_sync;
end

always @(posedge clk) begin
    cnt <= cnt + 1;
end

initial begin
    data_in_valid = 0;
end
always @(posedge clk ) begin
    if (cnt == 7)
        data_in_valid <= 1;
    else
        data_in_valid <= 0;
end

genvar i;
generate
    for (i = 0;i < FM_DEPTH ; i=i+1) begin
        always @(posedge clk ) begin
            if (cnt == 7)
                data_in[i] <= $random;
            else
                data_in[i] <= data_in[i];
        end
    end
endgenerate


wrapper #(
	.FM_DEPTH (FM_DEPTH ),
	.FM_WIDTH (FM_WIDTH ),
	.CORE_SIZE(CORE_SIZE)
) u_wrapper(
	.clk            (clk),
	.rstn           (rstn),
	.verticle_sync  (verticle_sync),
	.mode_in        (mode_in),
	.data_in_valid  (data_in_valid),
	.data_in        (data_in),
	.data_out_valid (data_out_valid),
	.vs_next        (vs_next),
	.data_out       (data_out),
	.C              (C)
);


endmodule