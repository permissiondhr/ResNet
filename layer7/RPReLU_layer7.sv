// Copyright (c) 2021 by the author(s)
//
// Filename  : 	RPReLU_layer5.sv
// Directory : 	C:\Users\seeyo\Desktop\L5
// Author    : 	LiuJintan
// CreateDate: 	11 月 13, 2021	16:02
// Mail: <liujintan@stu.pku.edu.cn>
// -----------------------------------------------------------------------------
// DESCRIPTION:
// This module implements...
//
// -----------------------------------------------------------------------------
// VERSION: 1.0.0
//
`include "defines.v"
module RPReLU_layer5
#(
    parameter CHANNEL_NUM  = 'd256         // Channel number of Macro
)
(
    // GLOBAL SIGNALS
    input  wire                              clk                              ,  // System Clock
                                             rst_n                            ,  // System Reset, Active LOW
                                             // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
                                             mode                             ,
    // SIGNALS FROM BN
    input  wire signed [`DATA_WIDTH - 1 : 0] data_in     [CHANNEL_NUM - 1 : 0],  // Data from bn
    input  wire                              data_e                           ,
    // SIGNALS FROM para_loader
    input  wire signed [`PARA_WIDTH - 1 : 0] rprelu_beta [CHANNEL_NUM - 1 : 0],  // Hyper-parameter of RPReLU 
    input  wire signed [`PARA_WIDTH - 1 : 0] rprelu_gamma[CHANNEL_NUM - 1 : 0],  // Hyper-parameter of RPReLU
    input  wire signed [`PARA_WIDTH - 1 : 0] rprelu_zeta [CHANNEL_NUM - 1 : 0],  // Hyper-parameter of RPReLU
    // OUTPUT SIGNALS TO NEXT LAYER(5)
    output wire signed [`DATA_WIDTH - 1 : 0] data_out    [CHANNEL_NUM - 1 : 0],  // DATA to next layer(5)
    output reg                               data_e_out                          //DATA Enable signals
);
    
    reg signed [`DATA_WIDTH * 2 - 1 : 0] data_out_reg[CHANNEL_NUM - 1 : 0];           // Format: xxxx_xxxx.xxxx_xxxx

    reg signed [`DATA_WIDTH * 2 - 1 : 0] data_gamma[CHANNEL_NUM - 1 : 0];
    reg signed [`DATA_WIDTH * 2 - 1 : 0] beta_data_gamma[CHANNEL_NUM - 1 : 0];
    reg data_e_dg, data_e_bdg;

    genvar i;
    generate
	for(i = 0; i < CHANNEL_NUM; i = i + 1) begin: data_reg_loo
        always @(posedge clk or negedge rst_n) begin: data_gamma_loop
            if(rst_n == `RSTVALID) begin
                data_gamma[i] <= 'b0;
            end else if(mode  == `CALCULATE && data_e == `DATAVALID) begin
                data_gamma[i] <= data_in[i] - rprelu_gamma[i];
            end else begin
                data_gamma[i] <= data_gamma[i];
            end // if
        end // always

        always @(posedge clk or negedge rst_n) begin:beta_data_gamma_loop
            if(rst_n == `RSTVALID) begin
                beta_data_gamma[i] <= 'b0;
            end else if(mode  == `CALCULATE && data_e_dg == `DATAVALID) begin
                beta_data_gamma[i] <= rprelu_beta[i] * data_gamma[i];
            end else begin
                beta_data_gamma[i] <= beta_data_gamma[i];
            end // if
        end // always
        always @(posedge clk or negedge rst_n) begin:data_out_reg_loop
            if(rst_n == `RSTVALID) begin
                data_out_reg[i] <= 'b0;
        	end else if(mode == `CALCULATE && data_e_bdg == `DATAVALID) begin
                data_out_reg[i] <= (data_in[i] > rprelu_gamma[i]) ? (data_gamma[i] + rprelu_zeta[i]) <<< 8 :
                                                                    (beta_data_gamma[i] + (rprelu_zeta[i] <<< 8));
            end else begin
                data_out_reg[i] <= data_out_reg[i] ;
            end // if 
    	end // always
	end // for i
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_dg <= `DATAINVALID;
        end else if(mode  == `CALCULATE && data_e == `DATAVALID) begin
            data_e_dg <= `DATAVALID;
        end else begin
            data_e_dg <= `DATAINVALID;
        end // if
    end // always

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_bdg <= `DATAINVALID;
        end else if(mode  == `CALCULATE && data_e_dg == `DATAVALID) begin
            data_e_bdg <= `DATAVALID;
        end else begin
            data_e_bdg <= `DATAINVALID;
        end // if
    end // always

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            data_e_out  <= `DATAINVALID;
    	end else if(mode == `CALCULATE && data_e_bdg == `DATAVALID) begin
            data_e_out  <= `DATAVALID;
        end else begin
            data_e_out  <= `DATAINVALID;
        end // if 
	end // always

    genvar j;
    generate for(j = 0; j < CHANNEL_NUM; j = j + 1) begin: data_out_loop
            assign data_out[j] = (data_out_reg[j][`DATA_WIDTH * 2 - 1] == 1'b1) ?                               // 
                                    ((data_out_reg[j][`DATA_WIDTH * 2 - 1 : `DATA_WIDTH - 1] == 17'h1ffff) ?    // 
                                        data_out_reg[j][23 : 8] : 16'h8000) :                      // 
                                    ((data_out_reg[j][`DATA_WIDTH * 2 - 1 : `DATA_WIDTH - 1] == 17'h00000) ?    //  
                                        data_out_reg[j][23 : 8] : 16'h7fff) ;                      // 
    end // for i
    endgenerate

endmodule