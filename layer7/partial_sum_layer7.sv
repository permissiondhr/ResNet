// Copyright (c) 2021 by the author(s)
//
// Filename  : 	partial_sum_layer5.sv
// Directory : 	C:\Users\seeyo\Desktop\L5
// Author    : 	LiuJintan
// CreateDate: 	11 月 13, 2021	14:59
// Mail: <liujintan@stu.pku.edu.cn>
// -----------------------------------------------------------------------------
// DESCRIPTION:
// This module implements...
//
// -----------------------------------------------------------------------------
// VERSION: 1.0.0
//
`include "defines.v"
module partial_sum_layer7 
#(
    parameter CHANNEL_NUM  = 'd512,         // Channel number of Macro
    parameter MACRO_NUM    = 'd32            // There are 32 Macro in Layer 6, each macro will be used twice
)
(
    // GLOBAL SIGNALS
    input  wire                        clk                                                 , // System Clock
                                       rst_n                                               , // System Reset, Active LOW
                                       mode                                                , // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    // Input From Wrapper
    input  wire [1 : 0]                chs_macro                                           ,
    
    // Input From Decoder
    input  wire                        data_e                                              , // Data Enable From Decoder, Active HIGH.
    input  reg signed [`DECODER_O_DW - 1 : 0] data_in [CHANNEL_NUM - 1 : 0][MACRO_NUM - 1 : 0]    ,
    // Output To Bn_Res
    output reg signed [`DATA_WIDTH   - 1 : 0] data_out[CHANNEL_NUM - 1 : 0]                       , 
    output reg                         data_e_out
);


    // Temporary Data
    reg signed [`DATA_WIDTH - 1 : 0] data_out_tmp[CHANNEL_NUM - 1 : 0];   /// 位宽可以优化！！！
    reg data_e_tmp;
    genvar i;
    generate for(i = 0; i < CHANNEL_NUM; i = i + 1) begin: data_out_temp_loop
        always @(posedge clk or negedge rst_n) begin
            if(rst_n == `RSTVALID) begin
                data_out_tmp[i] <= 16'h0000;
            end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
                data_out_tmp[i] <= {{12{data_in[i][0][3]}}, data_in[i][0]}
                                +  {{12{data_in[i][1][3]}}, data_in[i][1]}
                                +  {{12{data_in[i][2][3]}}, data_in[i][2]}
                                +  {{12{data_in[i][3][3]}}, data_in[i][3]}
                                +  {{12{data_in[i][4][3]}}, data_in[i][4]}
                                +  {{12{data_in[i][5][3]}}, data_in[i][5]}
                                +  {{12{data_in[i][6][3]}}, data_in[i][6]}
                                +  {{12{data_in[i][7][3]}}, data_in[i][7]};
            end else begin
                data_out_tmp[i] <= data_out_tmp[i];
            end // if
        end // always
    end // for i  
    endgenerate // generate 

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_tmp  <= `DATAINVALID;
        end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
            data_e_tmp  <= `DATAVALID;
        end else begin
            data_e_tmp  <= `DATAINVALID;
        end // if
    end // always
     

    genvar j;
    generate for(j = 0; j < CHANNEL_NUM; j = j + 1) begin: data_out_loop
        always @(posedge clk or negedge rst_n) begin
            if(rst_n == `RSTVALID) begin
                data_out[j] <= 16'h0000;
            end else if(mode == `CALCULATE && data_e_tmp == `DATAVALID) begin
                data_out[j] <= (chs_macro == 2'b01) ? data_out_tmp[j]              :      // Initialize data_out 
                                                      data_out_tmp[j] + data_out[j];
            end else begin
                data_out[j] <= data_out[j];
            end
        end // always
    end // for j
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_out  <= `DATAINVALID;
        end else if(mode == `CALCULATE && data_e_tmp == `DATAVALID) begin
            data_e_out  <= (chs_macro == 2'b00) ? `DATAVALID : `DATAINVALID;
        end else begin
            data_e_out  <= `DATAINVALID;
        end
    end // always

endmodule // partial_sum_layer5