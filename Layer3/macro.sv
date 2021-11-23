module macro (
    input   wire                enable,
    input   wire                adc,
    input   wire        [1:0]   chs_ps,
    input   wire                data_in[31:0][8:0],
    output  wire signed [3:0]   data_out[63:0]
);
endmodule

module macro_layer3 #(
    parameter   FM_DEPTH = 64,
    parameter   CORE_SIZE = 9,
    parameter   MACRO_NUM = 4
) (
    input   wire                enable,
    input   wire                adc,
    input   wire        [1:0]   chs_ps,
    input   wire                data_in [FM_DEPTH-1:0][CORE_SIZE-1:0],
    output  wire signed [3:0]   data_out[MACRO_NUM-1:0][63:0]
);

macro u_macro_0(
    .enable     (enable),
    .adc        (adc),
    .chs_ps     (chs_ps),
    .data_in    (data_in[31:0]),
    .data_out   (data_out[0])
);
macro u_macro_1(
    .enable     (enable),
    .adc        (adc),
    .chs_ps     (chs_ps),
    .data_in    (data_in[63:32]),
    .data_out   (data_out[1])
);
macro u_macro_2(
    .enable     (enable),
    .adc        (adc),
    .chs_ps     (chs_ps),
    .data_in    (data_in[31:0]),
    .data_out   (data_out[2])
);
macro u_macro_3(
    .enable     (enable),
    .adc        (adc),
    .chs_ps     (chs_ps),
    .data_in    (data_in[63:32]),
    .data_out   (data_out[3])
);
endmodule