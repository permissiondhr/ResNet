// Copyright (c) 2021 by the author(s)
//
// Filename  : 	layer5.sv
// Directory : 	C:\Users\seeyo\Desktop\L5
// Author    : 	LiuJintan
// CreateDate: 	11 月 13, 2021	16:34
// Mail: <liujintan@stu.pku.edu.cn>
// -----------------------------------------------------------------------------
// DESCRIPTION:
// This module implements...
//
// -----------------------------------------------------------------------------
// VERSION: 1.0.0
//

`include"defines.v"
`include"wrapper_layer5.sv"
`include"para_loader_layer5.sv"
`include"RSign_layer5.sv"
`include"macro.sv"
//`include"decoder_layer5.sv"
`include"partial_sum_layer5.sv"
`include"partial_sum.sv"
`include"bn_res_layer5.sv"
`include"RPReLU_layer5.sv"


module layer5
#(
    parameter FM_DEPTH        = 'd128,         // Depth of the Feature Map
    parameter FM_WIDTH        = 'd28 ,         // Width of the Feature Map
    parameter CHANNEL_NUM     = 'd256,         // Channel number of Macro
    parameter LOG2CHANNEL_NUM = 'd8  ,
    parameter MACRO_NUM       = 'd8            // There are 8 Macro in Layer 6, each macro will be used 4 times
)
(
    // GLOBAL SIGNALS
    input  wire                              clk                          , // System Clock
                                             rst_n                        , // System Reset, Active LOW
                                             mode                         , // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
                                             vs                           , // Vsync Signal
                                             data_e_para                  ,
    // INPUTS from previous layer(layer3)
    input  wire                              data_e                       ,
    input  wire signed [`DATA_WIDTH - 1 : 0] data_in[FM_DEPTH - 1 : 0]    ,
    // INPUTS parameter
    input  wire signed [`PARA_WIDTH - 1 : 0] para_in                      ,
    // OUTPUTS to next layer(layer5)
    output wire                              data_e_out                   ,
    output wire signed [`DATA_WIDTH - 1 : 0] data_out[CHANNEL_NUM - 1 : 0],
    output wire                              vs_next                      
    // Output to Macro
    //output wire signed [0 : 0] data_rs2mc[63 : 0][8 : 0],
    //output wire latch,
    //            adc  ,
    //            macro_e,
    //output wire [1 : 0] chs_macro,
    //input  wire signed [`MACRO_O_DW - 1 : 0] data_mc2de[CHANNEL_NUM - 1 : 0][MACRO_NUM - 1 : 0]

);

    
    // Signals From Wrapper to RSign
    wire signed [`DATA_WIDTH - 1 : 0] data_wr2rs[FM_DEPTH - 1 : 0][8 : 0];
    wire                              data_e_wr2rs;
    // Signals From Wrapper to bn_res
    wire signed [`DATA_WIDTH - 1 : 0] res_wr2bn[FM_DEPTH - 1 : 0];
    // Signals From Wrapper to Macro
    //wire latch,
    wire     adc    ,
             macro_e;
    wire [1 : 0] chs_macro_in;
    wire [1 : 0]  chs_macro;
    // Parameter From para_loader
    wire signed [`PARA_WIDTH - 1 : 0] rsign_para    [   FM_DEPTH - 1 : 0];
    wire signed [`PARA_WIDTH - 1 : 0] bn_a          [CHANNEL_NUM - 1 : 0];
    wire signed [`PARA_WIDTH - 1 : 0] bn_b          [CHANNEL_NUM - 1 : 0];
    wire signed [`PARA_WIDTH - 1 : 0] rprelu_beta   [CHANNEL_NUM - 1 : 0];
    wire signed [`PARA_WIDTH - 1 : 0] rprelu_gamma  [CHANNEL_NUM - 1 : 0];
    wire signed [`PARA_WIDTH - 1 : 0] rprelu_zeta   [CHANNEL_NUM - 1 : 0];

    // Signals From RSign to Macro
    wire signed [0 : 0] data_rs2mc[127 : 0][8 : 0];
    // Signals From Rsgin to Decoder
    wire data_e_rs2de;

    // Signals From Macro to decoder
    wire signed [`MACRO_O_DW - 1 : 0] data_mc2ps [7 : 0][63 : 0];


    // Signals From partail_sum to bn_res
    wire data_e_ps2bn;
    wire signed [`DATA_WIDTH - 1 : 0] data_ps2bn[CHANNEL_NUM - 1 : 0];

    // Signals From bn_res to RPReLU
    wire data_e_bn2RP;
    wire signed [`DATA_WIDTH - 1 : 0] data_bn2RP[CHANNEL_NUM - 1 : 0];

    // ****** Instantiation ******
    wrapper_layer5
    #(
        .FM_DEPTH      (FM_DEPTH    ),         // Depth of the Feature Map
        .FM_WIDTH      (FM_WIDTH    )         // Width of the Feature Map
    )
    wrapper_layer5_u0
    (
        // GLOBAL INPUTS
            .clk       (clk         ),      // System Clock
            .rst_n     (rst_n       ),      // System Reset, Active LOW
            .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
            .vs        (vs          ),      // Vsync Signal
            // INPUT FROM previous layer(layer3)
            .data_e    (data_e      ),      // DATA Enable signal, Active HIGH
            .data_in   (data_in     ),
            // OUTPUT TO RSign
            .data_out  (data_wr2rs  ),
            .data_e_out(data_e_wr2rs),
            // OUTPUT TO bn_res
            .res       (res_wr2bn   ),     // Residual
            // OUTPUTS TO next layer(layer5)
            .vs_next   (vs_next     ),
            // OUTPUTS TO Macro
            //.latch     (latch       ),
            .adc       (adc         ),
            .macro_e   (macro_e     ),
            .chs_macro (chs_macro_in ),
            .data_e_out_de(data_e_out_de)
    );

    para_loader_layer5
    #(
        .FM_DEPTH       (FM_DEPTH       ),
        .LOG2CHANNEL_NUM(LOG2CHANNEL_NUM),
        .CHANNEL_NUM    (CHANNEL_NUM    )
    )
    para_loader_layer5_u0
    (
        // GLOBAL INPUTS
        .clk          (clk         ),   // System Clock
        .rst_n        (rst_n       ),   // System Reset, Active LOW
        .data_e_para  (data_e_para ),   // DATA Enable signal, Active HIGH
        .mode         (mode        ),   // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
        // INPUT parameter
        .para_in      (para_in     ),   // Parameter Input, Source: ****
        // OUTPUT parameter
        .rsign_para   (rsign_para  ),   // Hyper-parameter of RSign
        .bn_a         (bn_a        ),   // Hyper-parameter of BN
        .bn_b         (bn_b        ),   // Hyper-parameter of BN
        .rprelu_beta  (rprelu_beta ),   // Hyper-parameter of RPReLU 
        .rprelu_gamma (rprelu_gamma),   // Hyper-parameter of RPReLU
        .rprelu_zeta  (rprelu_zeta )    // Hyper-parameter of RPReLU
    );

    RSign_layer5 
    #(
        .FM_DEPTH     (FM_DEPTH    )
    )
    RSign_layer5_u0
    (
        // GLOBAL INPUTS
        .clk          (clk         ),      // System Clock
        .rst_n        (rst_n       ),      // System Reset, Active LOW
        .mode         (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
        // INPUT parameter
        .para         (rsign_para  ),      // RSign Parameter input
        // INPUT FROM wrapper
        .data_in      (data_wr2rs  ),      // Input Data
        .data_e       (data_e_wr2rs),      // DATA Enable signal, Active HIGH
        .chs_macro_in (chs_macro_in),
        .chs_macro_out(chs_macro   ),
        // OUTPUT TO Macro
        .data_out     (data_rs2mc  )      // Output Data after RSign
        // OUTPUT TO bn_res
        //.data_e_out   (data_e_rs2de)       // Ouput of DATA Enabel signal, Active HIGH
    ); 

    macro macro_layer5_u0(
        .adc     (adc                 ),
        .enable  (macro_e              ),
        //.rst_n   (rst_n               ),
        .chs_ps  (chs_macro           ),
        .data_in (data_rs2mc[31  : 0 ]),
        .data_out(data_mc2ps[0]       )
    );
    macro macro_layer5_u1(
        .adc     (adc                 ),
        .enable  (macro_e              ),
        //.rst_n   (rst_n               ),
        .chs_ps  (chs_macro           ),
        .data_in (data_rs2mc[63  : 32]),
        .data_out(data_mc2ps[1]       )
    );
    macro macro_layer5_u2(
        .adc     (adc                 ),
        .enable  (macro_e              ),
        //.rst_n   (rst_n               ),
        .chs_ps  (chs_macro           ),
        .data_in (data_rs2mc[95  : 64]),
        .data_out(data_mc2ps[2]       )
    );
    macro macro_layer5_u3(
        .adc     (adc                 ),
        .enable  (macro_e              ),
        //.rst_n   (rst_n               ),
        .chs_ps  (chs_macro           ),
        .data_in (data_rs2mc[127 : 96]),
        .data_out(data_mc2ps[3]       )
    );
    macro macro_layer5_u4(
        .adc     (adc                 ),
        .enable  (macro_e              ),
        //.rst_n   (rst_n               ),
        .chs_ps  (chs_macro           ),
        .data_in (data_rs2mc[31  : 0 ]),
        .data_out(data_mc2ps[4]       )
    );
    macro macro_layer5_u5(
        .adc     (adc                 ),
        .enable  (macro_e              ),
        //.rst_n   (rst_n               ),
        .chs_ps  (chs_macro           ),
        .data_in (data_rs2mc[63  : 32]),
        .data_out(data_mc2ps[5]       )
    );
    macro macro_layer5_u6(
        .adc     (adc                 ),
        .enable  (macro_e              ),
        //.rst_n   (rst_n               ),
        .chs_ps  (chs_macro           ),
        .data_in (data_rs2mc[95  : 64]),
        .data_out(data_mc2ps[6]       )
    );
    macro macro_layer5_u7(
        .adc     (adc                 ),
        .enable  (macro_e              ),
        //.rst_n   (rst_n               ),
        .chs_ps  (chs_macro           ),
        .data_in (data_rs2mc[127 : 96]),
        .data_out(data_mc2ps[7]       )
    );


    partial_sum_layer5
    #(
        .CHANNEL_NUM(CHANNEL_NUM),      // Channel number of Macro
        .MACRO_NUM  (MACRO_NUM  )       // There are 8 Macro in Layer 4
    )
    partial_sum_layer5_u0
    (
        // GLOBAL INPUTS
        .clk       (clk         ),      // System Clock
        .rst_n     (rst_n       ),      // System Reset, Active LOW
        .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
        // Input From Wrapper
        // .chs_macro (chs_macro   ), 
        // INPUT From decoder
        .data_e    (data_e_out_de),
        .data_in   (data_mc2ps  ),  
        // OUTPUT to bn_res
        .data_out  (data_ps2bn  ),      // Output data from Partail_sum, 16 bit Width, 128
        .data_e_out(data_e_ps2bn)       // Ouput of DATA Enabel signal
    );

    bn_res_layer5
    #(
        .FM_DEPTH   (FM_DEPTH   ),      // Depth of the Feature Map
        .CHANNEL_NUM(CHANNEL_NUM)       // Channel number of Macro
    )
    bn_res_layer5_u0
    (
    // GLOBAL INPUTS
        .clk       (clk         ),      // System Clock
        .rst_n     (rst_n       ),      // System Reset, Active LOW
        .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    // INPUTS FROM para_loader
        .bn_a      (bn_a        ),      // Hyper-parameter of BN
        .bn_b      (bn_b        ),      // Hyper-parameter of BN
    // INPUTS FROM wrapper
        .res       (res_wr2bn   ),      // Residual
    // INPUTS FROM partail_sum
        .data_in   (data_ps2bn  ),      // Data from partail_sum
        .data_e    (data_e_ps2bn),      // DATA Enable signal, Active HIGH
        //.data_e (data_e_ps_bn)
    // OUTPUTS TO RPReLU
        .data_out  (data_bn2RP  ),      // Data to RPReLU
        .data_e_out(data_e_bn2RP)       // DATA Enable signal to RPReLU
    );

    RPReLU_layer5
    #(
        .CHANNEL_NUM(CHANNEL_NUM)       // Channel number of Macro
    )
    RPReLU_layer5_u0
    (
    // GLOBAL INPUTS
        .clk         (clk         ),    // System Clock
        .rst_n       (rst_n       ),    // System Reset, Active LOW
        .mode        (mode        ),    // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    // INPUT FROM BN
        .data_in     (data_bn2RP  ),    // Data from bn
        .data_e      (data_e_bn2RP),    // DATA Enable signal, Active HIGH
    // INPUTS FROM para_loader
        .rprelu_beta (rprelu_beta ),    // Hyper-parameter of RPReLU 
        .rprelu_gamma(rprelu_gamma),    // Hyper-parameter of RPReLU
        .rprelu_zeta (rprelu_zeta ),    // Hyper-parameter of RPReLU
    // OUTPUT TO next layer(layer5)
        .data_out    (data_out    ),    // DATA to next layer(5)
        .data_e_out  (data_e_out  )     // DATA Enable signals
    );

endmodule // layer5
