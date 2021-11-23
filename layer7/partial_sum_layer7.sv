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
`include "partial_sum.sv"
module partial_sum_layer5 
#(
    parameter CHANNEL_NUM  = 'd256,         // Channel number of Macro
    parameter MACRO_NUM    = 'd8            // There are 8 Macro in Layer 6, each macro will be used 4 times
)
(
    // GLOBAL SIGNALS
    input  wire                        clk                                                 , // System Clock
                                       rst_n                                               , // System Reset, Active LOW
                                       mode                                                , // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    // Input From Wrapper
    // input  wire [1 : 0]                chs_macro                                           ,
    
    // Input From Decoder
    input  wire                              data_e                       , // Data Enable From Decoder, Active HIGH.
    input  wire signed [`MACRO_O_DW - 1 : 0] data_in [7 : 0][63 : 0]      ,
    // Output To Bn_Res
    output reg  signed [`DATA_WIDTH - 1 : 0] data_out[CHANNEL_NUM - 1 : 0], 
    output reg                               data_e_out
);

    
    wire signed [`DATA_WIDTH   - 1 : 0] data_out0[127 : 0];
    reg data_e_tmp;

    partial_sum ps_layer5_u0
    (
        // GLOBAL INPUTS
        .clk       (clk         ),      // System Clock
        .rst_n     (rst_n       ),      // System Reset, Active LOW
        .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
        // INPUT From decoder
        .data_e    (data_e),
        .data_in   (data_in[3 : 0]   ),  
        // OUTPUT to bn_res
        .data_out  (data_out0[63 : 0]),      // Output data from Partail_sum, 16 bit Width, 128
        .data_e_out()       // Ouput of DATA Enabel signal
    );

    partial_sum ps_layer5_u1
    (
        // GLOBAL INPUTS
        .clk       (clk         ),      // System Clock
        .rst_n     (rst_n       ),      // System Reset, Active LOW
        .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
        // INPUT From decoder
        .data_e    (data_e),
        .data_in   (data_in[7 : 4]     ),  
        // OUTPUT to bn_res
        .data_out  (data_out0[127 : 64]),      // Output data from Partail_sum, 16 bit Width, 128
        .data_e_out()       // Ouput of DATA Enabel signal
    );

    reg counter;
    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_tmp  <= `DATAINVALID;
        end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
            data_e_tmp  <= `DATAVALID;
        end else begin
            data_e_tmp  <= `DATAINVALID;
        end // if
    end // always

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            counter <= 1'b1;
        end else if(mode == `CALCULATE && data_e_tmp == `DATAVALID) begin
            counter <= counter + 1'b1;
        end else begin
            counter <= counter;
        end // if
    end // always
    
    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            for(int j = 0; j < CHANNEL_NUM; j = j + 1)
                data_out[j] <= 16'h0000;
        end else if(mode == `CALCULATE && data_e_tmp == `DATAVALID) begin
            if(counter == 1'b1)
                data_out[127 : 0  ] <= data_out0;
            else
                data_out[255 : 128] <= data_out0;
        end else begin
            for(int j = 0; j < CHANNEL_NUM; j = j + 1)
                data_out[j] <= data_out[j];
        end
    end // always


    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_out  <= `DATAINVALID;
        end else if(mode == `CALCULATE && data_e_tmp == `DATAVALID) begin
            data_e_out  <= (counter == 1'b0) ? `DATAVALID : `DATAINVALID;
        end else begin
            data_e_out  <= `DATAINVALID;
        end
    end // always

endmodule // partial_sum_layer5