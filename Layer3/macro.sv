module macro (
    input   wire            enable,
    input   wire            adc,
    input   wire    [1:0]   chs_ps,
    input   wire    [287:0] data_in,
    output  wire    [255:0] data_out
);
    
endmodule

module macro_layer3 (
    input   wire            enable,
    input   wire            adc,
    input   wire    [1:0]   chs_ps,
    input   wire            data_in [FM_DEPTH-1:0][CORE_SIZE-1:0],
    output  wire    [3:0]   data_out[63:0][MACRO_NUM-1:0]
);

wire [FM_DEPTH*CORE_SIZE-1 : 0] data_in_wire;
wire [64*MACRO_NUM*4-1: 0] data_out_wire;

genvar i, j, k, l;
generate
    for (i = 0; i < FM_DEPTH; i = i + 1) begin
        for (j = 0; j < CORE_SIZE; j = j + 1) begin
            assign data_in_wire[i*CORE_SIZE + j] = data_in[i][j];
        end
    end

    for (k = 0; k < MACRO_NUM; k = k + 1) begin
        for (l = 0; l < 64; l = l + 1) begin
            assign data_out[l][k] = data_out_wire[(k*64+l)*4+3 : (k*64+l)*4];
        end
    end
endgenerate

macro u_macro_0(
    .enable     (enable),
    .adc        (adc),
    .chs_ps     (chs_ps),
    .data_in    (data_in_wire[CORE_SIZE*32-1 : 0]),
    .data_out   (data_out_wire[64*4-1 : 0])
);
macro u_macro_1(
    .enable     (enable),
    .adc        (adc),
    .chs_ps     (chs_ps),
    .data_in    (data_in_wire[2*CORE_SIZE*32-1 : CORE_SIZE*32]),
    .data_out   (data_out_wire[2*64*4-1 : 64*4])
);
macro u_macro_2(
    .enable     (enable),
    .adc        (adc),
    .chs_ps     (chs_ps),
    .data_in    (data_in_wire[CORE_SIZE*32-1 : 0]),
    .data_out   (data_out_wire[3*64*4-1 : 2*64*4])
);
macro u_macro_3(
    .enable     (enable),
    .adc        (adc),
    .chs_ps     (chs_ps),
    .data_in    (data_in_wire[2*CORE_SIZE*32-1 : CORE_SIZE*32]),
    .data_out   (data_out_wire[4*64*4-1 : 3*64*4])
);
endmodule