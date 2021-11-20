// Copyright (c) 2021 by the author(s)
//
// Filename  : 	decoder_layer5.sv
// Directory : 	C:\Users\seeyo\Desktop\L5
// Author    : 	LiuJintan
// CreateDate: 	11 月 13, 2021	14:55
// Mail: <liujintan@stu.pku.edu.cn>
// -----------------------------------------------------------------------------
// DESCRIPTION:
// This module implements...
//
// -----------------------------------------------------------------------------
// VERSION: 1.0.0
//
`include "defines.v"
module decoder_layer7
#(
    parameter CHANNEL_NUM  = 'd512,         // Channel number of Macro
    parameter MACRO_NUM    = 'd32            // There are 8 Macro in Layer 6, each macro will be used 4 times
)
(
    // GLOBAL SIGNALS
    // Input From RSign
    input  wire                                data_e                                          , // Data Enable From RSign, Active HIGH.
    // Input From Macro
    input  wire signed [`MACRO_O_DW - 1 : 0]   data_in [CHANNEL_NUM - 1 : 0][MACRO_NUM - 1 : 0], // Data From 8 Macros.
    // Output To Partial_sum
    output reg  signed [`DECODER_O_DW - 1 : 0] data_out[CHANNEL_NUM - 1 : 0][MACRO_NUM - 1 : 0], // To Partial Sum, Data Ouput After Decode.
    output reg                                 data_e_out                                        // Data Enable To partial sum, Active HIGH.
);

    genvar i, j;
    generate for(i = 0; i < CHANNEL_NUM; i = i + 1) begin:data_out_tmp_loopi
        for(j = 0; j < MACRO_NUM; j = j + 1) begin:data_out_tmp_loopj
            assign data_out[i][j] = data_in[i][j] == 5'b00000 ? 4'b1000 :
                                    data_in[i][j] == 5'b00001 ? 4'b1001 :
                                    data_in[i][j] == 5'b00010 ? 4'b1010 :
                                    data_in[i][j] == 5'b00011 ? 4'b1011 :
                                    data_in[i][j] == 5'b00100 ? 4'b1011 :
                                    data_in[i][j] == 5'b00101 ? 4'b1100 :
                                    data_in[i][j] == 5'b00110 ? 4'b1101 :
                                    data_in[i][j] == 5'b00111 ? 4'b1110 :
                                    data_in[i][j] == 5'b01000 ? 4'b1100 :
                                    data_in[i][j] == 5'b01001 ? 4'b1101 :
                                    data_in[i][j] == 5'b01010 ? 4'b1110 :
                                    data_in[i][j] == 5'b01011 ? 4'b1111 :
                                    data_in[i][j] == 5'b01100 ? 4'b1111 :
                                    data_in[i][j] == 5'b01101 ? 4'b0000 :
                                    data_in[i][j] == 5'b01110 ? 4'b0001 :
                                    data_in[i][j] == 5'b01111 ? 4'b0010 :
                                    data_in[i][j] == 5'b10000 ? 4'b1101 :
                                    data_in[i][j] == 5'b10001 ? 4'b1110 :
                                    data_in[i][j] == 5'b10010 ? 4'b1111 :
                                    data_in[i][j] == 5'b10011 ? 4'b0000 :
                                    data_in[i][j] == 5'b10100 ? 4'b0000 :
                                    data_in[i][j] == 5'b10101 ? 4'b0001 :
                                    data_in[i][j] == 5'b10110 ? 4'b0010 :
                                    data_in[i][j] == 5'b10111 ? 4'b0011 :
                                    data_in[i][j] == 5'b11000 ? 4'b0001 :
                                    data_in[i][j] == 5'b11001 ? 4'b0010 :
                                    data_in[i][j] == 5'b11010 ? 4'b0011 :
                                    data_in[i][j] == 5'b11011 ? 4'b0100 :
                                    data_in[i][j] == 5'b11100 ? 4'b0100 :
                                    data_in[i][j] == 5'b11101 ? 4'b0101 :
                                    data_in[i][j] == 5'b11110 ? 4'b0110 :
                                                                4'b0111 ;
        end // for j 
    end // for i
    endgenerate
    
    assign data_e_out = data_e;


endmodule
