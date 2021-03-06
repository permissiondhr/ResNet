`timescale 1ns/1ns
module wrapper_tb #(
    parameter FM_DEPTH  = 64,
    parameter FM_WIDTH  = 56,
    parameter CORE_SIZE = 9
) (
);

reg clk, rstn, mode_in, verticle_sync, data_in_valid;
reg  	[15:0] 	data_in[FM_DEPTH-1:0];
wire data_out_valid, vs_next, adc_to_macro;
wire 	[15:0]	data_out[FM_DEPTH-1:0][CORE_SIZE-1:0];
wire  	[15:0] 	res [FM_DEPTH-1:0][3:0];

reg cnt;

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

initial begin
    mode_in = 0;
    verticle_sync = 1;
    #122
    mode_in = ~mode_in;
    #10
    verticle_sync = ~verticle_sync;
end

always @(posedge clk) begin
    cnt <= cnt + 1;
end

initial begin
    data_in_valid = 0;
end
always @(posedge clk ) begin
    if (cnt == 1)
        data_in_valid <= 1;
    else
        data_in_valid <= 0;
end

genvar i;
generate
    for (i = 0;i < FM_DEPTH ; i=i+1) begin
        always @(posedge clk ) begin
            if (cnt == 1)
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
	.res            (res),
    .adc_to_macro   (adc_to_macro)
);


endmodule