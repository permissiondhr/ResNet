// Copyright (c) 2021 by the author(s)
//
// Filename  : 	RSign_layer5.sv
// Directory : 	C:\Users\seeyo\Desktop\L5
// Author    : 	LiuJintan
// CreateDate: 	11 月 13, 2021	14:22
// Mail: <liujintan@stu.pku.edu.cn>
// -----------------------------------------------------------------------------
// DESCRIPTION:
// This module implements...
//
// -----------------------------------------------------------------------------
// VERSION: 1.0.0
//
`include "defines.v"
module RSign_layer7
#(
    parameter FM_DEPTH     = 'd256           // Depth of the Feature Map
)
(
    input  wire                              clk                              , // System Clock
                                             rst_n                            , // System Reset, Active LOW
                                             data_e                           , // DATA Enable signal, Active HIGH
                                             // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
                                             mode                             ,  
    input  wire signed [`PARA_WIDTH - 1 : 0] para    [FM_DEPTH - 1 : 0]       , // RSign Parameter input
    input  wire signed [`DATA_WIDTH - 1 : 0] data_in [FM_DEPTH - 1 : 0][8 : 0], // Input Data
    input  wire        [1               : 0] chs_macro                        , // counter == 1 indicate that the data is after down simpling.
    output reg  signed [0               : 0] data_out[FM_DEPTH/2-1 : 0][8 : 0]  // Output Data after RSign
    //output wire                              data_e_out                         // Enable Signal for decoder, Active HIGH                     
);

    reg signed [0 : 0] data_out_reg[FM_DEPTH - 1 : 0][8 : 0];
    //reg data_e_out_tmp;
    genvar  i, j;
    generate 
        for(i = 0; i < FM_DEPTH; i = i + 1) begin: data_out_loop
            for(j = 0; j< 9; j = j + 1) begin
                always @(posedge clk or negedge rst_n) begin
                    if(rst_n == `RSTVALID) begin    // When RESET is valid, reset data_out, data_e_out
                        data_out_reg[i][j] <= 1'b0;
                    end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
                        data_out_reg[i][j] <= data_in[i][j] > para[i] ? 1'b1 : 1'b0;
                    end else begin
                        data_out_reg[i][j] <= data_out_reg[i][j];
                    end//if
                end //always
            end // for j
        end // for i
    endgenerate // generate

    assign data_out = (chs_macro[0] == 1'b0) ? data_out_reg[127  : 0 ] :   // When chs_macro[0] equal to 1'b0, send [63  : 0 ] to eight Macro
                                               data_out_reg[255 : 128] ;   // When chs_macro[0] equal to 1'b1, send [127 : 64] to eight Macro

endmodule // RSign_layer5