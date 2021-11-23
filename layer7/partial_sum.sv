// Copyright (c) 2021 by the author(s)
//
// Filename  : 	partail_sum_layer4.v
// Directory : 	C:\Users\seeyo\Desktop\项目\40\RTL
// Author    : 	LiuJintan
// CreateDate: 	10月 30, 2021	10:59
// Mail: <liujintan@stu.pku.edu.cn>
// -----------------------------------------------------------------------------
// DESCRIPTION:
// This module implements...
//
// -----------------------------------------------------------------------------
// VERSION: 1.0.0
//
`include "defines.v"
module partial_sum
(
    // GLOBAL SIGNALS
    input  wire                                clk                                             , // System Clock
                                               rst_n                                           , // System Reset, Active LOW
                                               // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
                                               mode                                            ,
    input  wire                                data_e                                          , // DATA Enable signal, Active HIGH
    input  wire signed [`MACRO_O_DW   - 1 : 0] data_in [3  : 0][63 : 0],  
                                               // Output data from Partail_sum, 16 bit Width, 128
    output reg  signed [`DATA_WIDTH   - 1 : 0] data_out[63 : 0]                   ,  
    output reg                                 data_e_out                                        // Ouput of DATA Enabel signal
);
    
    wire [`DECODER_O_DW - 1 : 0] data_de[3 : 0][63 : 0];
    genvar i, j;
    generate
        for(i = 0; i < 4; i = i + 1) begin:data_outi_loop
            for(j = 0; j < 64; j = j + 1) begin:data_outj_loop
                assign data_de[i][j] = {data_in[i][j][3], ~{data_in[i][j][2 : 0]}};
            end // for j 
        end // for i
    endgenerate

    genvar  k;
    generate for(k = 0; k < 64; k = k + 1) begin: data_out_loop
        always @(posedge clk or negedge rst_n) begin
            if(rst_n == `RSTVALID) begin
                data_out[k] <= 16'h0000;
            end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
                data_out[k] <= {{12{data_de[0][k][3]}}, data_de[0][k]}
                            +  {{12{data_de[1][k][3]}}, data_de[1][k]}
                            +  {{12{data_de[2][k][3]}}, data_de[2][k]}
                            +  {{12{data_de[3][k][3]}}, data_de[3][k]};
            end else begin
                data_out[k] <= data_out[k];
            end // if
        end // always
    end // for i  
    endgenerate // generate    

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_out  <= `DATAINVALID;
        end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
            data_e_out  <= `DATAVALID;
        end else begin
            data_e_out  <= `DATAINVALID;
        end // if
    end // always

endmodule //module partail_sum_layer4
