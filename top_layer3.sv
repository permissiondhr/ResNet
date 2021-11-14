module top_layer3 #(
	parameter FM_DEPTH 	  = 64,
	parameter FM_WIDTH 	  = 56,
	parameter CHANNEL_NUM = 128,
	parameter LOG2CHANNEL_NUM = 7,
	parameter MACRO_NUM   = 4,
	parameter PARA_NUM		= 6,
	parameter DATA_WIDTH  = 16,
	parameter PARA_WIDTH  = 16,
	parameter CORE_SIZE   = 9
) (
	input 	wire							clk,
	input 	wire							rstn,
	input 	wire							mode_in,
	input 	wire							verticle_sync,
	input 	wire							data_in_valid,
	input 	wire signed [DATA_WIDTH-1 : 0]	data_in			[FM_DEPTH-1 : 0],
	input 	wire signed [PARA_WIDTH-1 : 0]	para_in,
	output	wire							data_out_valid,
	output	wire signed [DATA_WIDTH-1 : 0]	data_out		[CHANNEL_NUM-1 : 0],
	output	wire							vs_next
);

wire signed  [PARA_WIDTH-1 : 0] rsign_para  [FM_DEPTH-1    : 0];
wire signed  [PARA_WIDTH-1 : 0] bn_a        [CHANNEL_NUM-1 : 0];
wire signed  [PARA_WIDTH-1 : 0] bn_b        [CHANNEL_NUM-1 : 0];
wire signed  [PARA_WIDTH-1 : 0] beta   		[CHANNEL_NUM-1 : 0];
wire signed  [PARA_WIDTH-1 : 0] gamma  		[CHANNEL_NUM-1 : 0];
wire signed  [PARA_WIDTH-1 : 0] zeta   		[CHANNEL_NUM-1 : 0];

wire 							latch_to_macro;
wire 							adc_to_macro;
wire 							enable_to_macro;
wire 							data_to_partial_valid;
wire signed [DATA_WIDTH-1 : 0]	data_wrapper_rsign	[CHANNEL_NUM-1 : 0];
wire							valid_wrapper_rsign;
wire signed [15:0] 				res_wrapper_pooling [FM_DEPTH-1:0][3:0];

wrapper #(
	.FM_DEPTH 		(FM_DEPTH ),
	.FM_WIDTH 		(FM_WIDTH ),
	.CORE_SIZE		(CORE_SIZE)
) inst_wrapper(
	.clk					(clk),
	.rstn					(rstn),
	.verticle_sync			(verticle_sync),
	.mode_in 				(mode_in ),
	.data_in_valid			(data_in_valid),
	.data_in				(data_in),
	.data_out_valid			(valid_wrapper_rsign),
	.vs_next				(vs_next),
	.latch_to_macro			(latch_to_macro),
	.adc_to_macro			(adc_to_macro),
	.enable_to_macro		(enable_to_macro),
	.data_to_partial_valid	(data_to_partial_valid),
	.data_out				(data_wrapper_rsign),
	.res					(res_wrapper_pooling)
);

wire data_rsign_macro	[FM_DEPTH-1:0][CORE_SIZE-1:0];

rsign #(
    .FM_DEPTH 		(FM_DEPTH ),
    .CORE_SIZE		(CORE_SIZE)
) inst_rsign(
    .clk			(clk),
    .rstn			(rstn),
    .data_in_valid	(data_in_valid),
    .para_in 		(rsign_para),
    .data_in 		(data_wrapper_rsign),
    .data_out		(data_rsign_macro)
);

wire [4:0] data_macro_decoder 	[CHANNEL_NUM - 1 : 0][MACRO_NUM-1:0];
wire [3:0] data_decoder_partial	[CHANNEL_NUM - 1 : 0][MACRO_NUM-1:0];

decoder #(
    .CHANNEL_NUM	(CHANNEL_NUM),
    .MACRO_NUM  	(MACRO_NUM  )
) inst_decoder(
    .data_in 		(data_macro_decoder),
    .data_out		(data_decoder_partial)
);

wire 		valid_partial_bn;
wire [7:0]	data_partial_bn	[CHANNEL_NUM-1:0];

partial_sum #(
    .CHANNEL_NUM	(CHANNEL_NUM),
    .MACRO_NUM  	(MACRO_NUM  )
) inst_partial_sum (
    .clk			(clk),
    .rstn			(rstn),
    .data_in_valid	(data_to_partial_valid),
    .data_in		(data_decoder_partial),
    .data_out_valid	(valid_partial_bn),
    .data_out		(data_partial_bn)
);

wire signed [DATA_WIDTH - 1 : 0] 	data_bn_rprelu [CHANNEL_NUM - 1 : 0];
wire								valid_bn_rprelu;
bn_res #(
    .DATA_WIDTH 	(DATA_WIDTH ),
    .PARA_WIDTH 	(PARA_WIDTH ),
    .CHANNEL_NUM	(CHANNEL_NUM),
	.FM_DEPTH		(FM_DEPTH	)
) inst_bn_res (
    .clk          	(clk          ),
    .rstn         	(rstn         ),
    .data_in_valid	(data_partial_bn),
    .bn_a     		(bn_a     ),
    .bn_b     		(bn_b     ),
    .res      		(res_pooling_bn),
    .data_in  		(data_partial_bn),
    .data_out 		(data_bn_rprelu),
    .data_out_valid	(valid_bn_rprelu)
);

pooling #(
    .FM_DEPTH		(FM_DEPTH)
) inst_pooling (
    .clk			(clk),
    .rstn			(rstn),
    .data_in_valid	(valid_wrapper_rsign),
    .pooling_in		(res_wrapper_pooling),
    .pooling_out	(res_pooling_bn)
);

rprelu #(
    .DATA_WIDTH 	(DATA_WIDTH ),
    .PARA_WIDTH 	(PARA_WIDTH ),
    .CHANNEL_NUM	(CHANNEL_NUM)
) inst_rprelu (
    .clk			(clk),
    .rstn			(rstn),
    .data_in_valid	(valid_bn_rprelu),
    .data_in		(data_bn_rprelu),
    .beta			(beta),
    .gamma			(gamma),
    .zeta			(zeta),
    .data_out		(data_out),
    .data_out_valid	(data_out_valid)
);

para_loader #(
    .FM_DEPTH     	(FM_DEPTH     ),
    .PARA_WIDTH   	(PARA_WIDTH   ),
    .LOG2CHANNEL_NUM(LOG2CHANNEL_NUM), 
    .CHANNEL_NUM  	(CHANNEL_NUM  ),
    .PARA_NUM     	(PARA_NUM     )
) inst_para_loader (
    .clk			(clk),
    .rstn			(rstn),
    .data_in_valid	(data_in_valid),
    .mode_in		(mode_in),
    .para_in		(para_in),
    .rsign_para		(rsign_para),
    .bn_a      		(bn_a      ),
    .bn_b      		(bn_b      ),
    .beta      		(beta      ),
    .gamma     		(gamma     ),
    .zeta      		(zeta      )
);

endmodule