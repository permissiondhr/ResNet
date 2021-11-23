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
module RSign_layer5
#(
    parameter FM_DEPTH     = 'd128           // Depth of the Feature Map
)
(
    input  wire                              clk                              , // System Clock
                                             rst_n                            , // System Reset, Active LOW
                                             data_e                           , // DATA Enable signal, Active HIGH
                                             // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
                                             mode                             ,  
    input  wire signed [`PARA_WIDTH - 1 : 0] para    [FM_DEPTH - 1 : 0]       , // RSign Parameter input
    input  wire signed [`DATA_WIDTH - 1 : 0] data_in [FM_DEPTH - 1 : 0][8 : 0], // Input Data
    input  wire        [1               : 0] chs_macro_in                     , // counter == 1 indicate that the data is after down simpling.
    output reg         [1               : 0] chs_macro_out                    ,
    output reg  signed [0               : 0] data_out[FM_DEPTH - 1 : 0][8 : 0]  // Output Data after RSign                 
);

    //reg signed [0 : 0] data_out_reg[FM_DEPTH - 1 : 0][8 : 0];
    //reg data_e_out_tmp;
    genvar  i, j;
    generate 
        for(i = 0; i < FM_DEPTH; i = i + 1) begin: data_out_loop
            for(j = 0; j< 9; j = j + 1) begin
                always @(posedge clk or negedge rst_n) begin
                    if(rst_n == `RSTVALID) begin    // When RESET is valid, reset data_out, data_e_out
                        data_out[i][j] <= 1'b0;
                        //data_e_out_tmp     <= `DATAINVALID;
                    end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
                        data_out[i][j] <= data_in[i][j] > para[i] ? 1'b1 : 1'b0;
                        //data_e_out_tmp     <= `DATAVALID;
                    end else begin
                        data_out[i][j] <= data_out[i][j];
                        //data_e_out_tmp     <= `DATAINVALID;
                    end//if
                end //always
            end // for j
        end // for i
    endgenerate // generate

    //assign data_out = (chs_macro_out[0] == 1'b0) ? data_out_reg[63  : 0 ] :   // When chs_macro[0] equal to 1'b0, send [63  : 0 ] to eight Macro
    //                                               data_out_reg[127 : 64] ;   // When chs_macro[0] equal to 1'b1, send [127 : 64] to eight Macro

    always @(posedge clk) begin
        chs_macro_out <= chs_macro_in;
    end //always 

    /*reg first_flag;

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            first_flag <= 1'b0;
        end else if (data_e_out_tmp == `DATAVALID || first_flag == 1'b1) begin
            first_flag <= 1'b1;
        end else begin
            first_flag <= first_flag;
        end
    end // always

    //assign data_e_out = first_flag && (data_e_out_tmp == `DATAVALID);*/

endmodule // RSign_layer5