
`include"defines.v"
module top_layer7
#(
    parameter FM_DEPTH        = 256, // Depth of the Feature Map
    parameter FM_WIDTH        = 14,  // Width of the Feature Map
    parameter CHANNEL_NUM     = 512, // Channel number of Macro
    parameter LOG2CHANNEL_NUM = 9,
    parameter MACRO_NUM       = 32   // There are 32 Macro in Layer 7, each macro will be used twice
)
(
    input  wire                              clk                          , // System Clock
    input  wire                              rst_n                        , // System Reset, Active LOW
    input  wire                              mode                         , // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    input  wire                              vs                           , // Vsync Signal
    input  wire                              data_e_para                  ,
    input  wire                              data_e                       ,
    input  wire signed [`DATA_WIDTH - 1 : 0] data_in[FM_DEPTH - 1 : 0]    ,
    input  wire signed [`PARA_WIDTH - 1 : 0] para_in                      ,
    output wire                              data_e_out                   ,
    output wire signed [`DATA_WIDTH - 1 : 0] data_out[CHANNEL_NUM - 1 : 0],
    output wire                              vs_next                      
);

// Signals From Wrapper to RSign
wire signed [`DATA_WIDTH - 1 : 0] data_wr2rs[FM_DEPTH - 1 : 0][8 : 0];
wire                              data_e_wr2rs;
// Signals From Wrapper to bn_res
wire signed [`DATA_WIDTH - 1 : 0] res_wr2bn[FM_DEPTH - 1 : 0];
// Signals From Wrapper to Macro
//wire latch,
wire         adc, macro_e;
wire [1 : 0] chs_macro_in;
wire [1 : 0] chs_macro;
// Parameter From para_loader
wire signed [`PARA_WIDTH - 1 : 0] rsign_para    [   FM_DEPTH - 1 : 0];
wire signed [`PARA_WIDTH - 1 : 0] bn_a          [CHANNEL_NUM - 1 : 0];
wire signed [`PARA_WIDTH - 1 : 0] bn_b          [CHANNEL_NUM - 1 : 0];
wire signed [`PARA_WIDTH - 1 : 0] rprelu_beta   [CHANNEL_NUM - 1 : 0];
wire signed [`PARA_WIDTH - 1 : 0] rprelu_gamma  [CHANNEL_NUM - 1 : 0];
wire signed [`PARA_WIDTH - 1 : 0] rprelu_zeta   [CHANNEL_NUM - 1 : 0];
// Signals From RSign to Macro
wire signed [0 : 0] data_rs2mc[FM_DEPTH - 1 : 0][8 : 0];
// Signals From Rsgin to Decoder
wire data_e_rs2de;
// Signals From Macro to decoder
wire signed [`MACRO_O_DW - 1 : 0] data_mc2ps [MACRO_NUM - 1 : 0][63 : 0];
// Signals From partail_sum to bn_res
wire data_e_ps2bn;
wire signed [`DATA_WIDTH - 1 : 0] data_ps2bn[CHANNEL_NUM - 1 : 0];
// Signals From bn_res to RPReLU
wire data_e_bn2RP;
wire signed [`DATA_WIDTH - 1 : 0] data_bn2RP[CHANNEL_NUM - 1 : 0];

// ****** Instantiation ******
wrapper_layer7 #(
    .FM_DEPTH      (FM_DEPTH    ),         // Depth of the Feature Map
    .FM_WIDTH      (FM_WIDTH    )         // Width of the Feature Map
)wrapper_layer7_u0(
        .clk       (clk         ),      // System Clock
        .rst_n     (rst_n       ),      // System Reset, Active LOW
        .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
        .vs        (vs          ),      // Vsync Signal
        .data_e    (data_e      ),      // DATA Enable signal, Active HIGH
        .data_in   (data_in     ),
        .data_out  (data_wr2rs  ),
        .data_e_out(data_e_wr2rs),
        .res       (res_wr2bn   ),     // Residual
        .vs_next   (vs_next     ),
        .adc       (adc         ),
        .macro_e   (macro_e     ),
        .chs_macro (chs_macro_in ),
        .data_e_out_de(data_e_out_de)
);

para_loader_layer7 #(
    .FM_DEPTH       (FM_DEPTH       ),
    .LOG2CHANNEL_NUM(LOG2CHANNEL_NUM),
    .CHANNEL_NUM    (CHANNEL_NUM    )
)para_loader_layer7_u0(
    .clk          (clk         ),   // System Clock
    .rst_n        (rst_n       ),   // System Reset, Active LOW
    .data_e_para  (data_e_para ),   // DATA Enable signal, Active HIGH
    .mode         (mode        ),   // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    .para_in      (para_in     ),   // Parameter Input, Source: ****
    .rsign_para   (rsign_para  ),   // Hyper-parameter of RSign
    .bn_a         (bn_a        ),   // Hyper-parameter of BN
    .bn_b         (bn_b        ),   // Hyper-parameter of BN
    .rprelu_beta  (rprelu_beta ),   // Hyper-parameter of RPReLU 
    .rprelu_gamma (rprelu_gamma),   // Hyper-parameter of RPReLU
    .rprelu_zeta  (rprelu_zeta )    // Hyper-parameter of RPReLU
);

RSign_layer7 #(
    .FM_DEPTH     (FM_DEPTH    )
)RSign_layer7_u0(
    .clk          (clk         ),      // System Clock
    .rst_n        (rst_n       ),      // System Reset, Active LOW
    .mode         (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    .para         (rsign_para  ),      // RSign Parameter input
    .data_in      (data_wr2rs  ),      // Input Data
    .data_e       (data_e_wr2rs),      // DATA Enable signal, Active HIGH
    .chs_macro_in (chs_macro_in),
    .chs_macro_out(chs_macro   ),
    .data_out     (data_rs2mc  )      // Output Data after RSign
);

macro macro_layer7_u0(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[31  : 0 ]),
    .data_out(data_mc2ps[0]       )
);
macro macro_layer7_u1(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[63  : 32]),
    .data_out(data_mc2ps[1]       )
);
macro macro_layer7_u2(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[95  : 64]),
    .data_out(data_mc2ps[2]       )
);
macro macro_layer7_u3(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[127 : 96]),
    .data_out(data_mc2ps[3]       )
);
macro macro_layer7_u4(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[159 :128]),
    .data_out(data_mc2ps[4]       )
);
macro macro_layer7_u5(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[191 :160]),
    .data_out(data_mc2ps[5]       )
);
macro macro_layer7_u6(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[223 :192]),
    .data_out(data_mc2ps[6]       )
);
macro macro_layer7_u7(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[255 :224]),
    .data_out(data_mc2ps[7]       )
);

macro macro_layer7_u8(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[31  : 0 ]),
    .data_out(data_mc2ps[8]       )
);
macro macro_layer7_u9(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[63  : 32]),
    .data_out(data_mc2ps[9]       )
);
macro macro_layer7_u10(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[95  : 64]),
    .data_out(data_mc2ps[10]       )
);
macro macro_layer7_u11(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[127 : 96]),
    .data_out(data_mc2ps[11]       )
);
macro macro_layer7_u12(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[159 :128]),
    .data_out(data_mc2ps[12]       )
);
macro macro_layer7_u13(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[191 :160]),
    .data_out(data_mc2ps[13]       )
);
macro macro_layer7_u14(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[223 :192]),
    .data_out(data_mc2ps[14]       )
);
macro macro_layer7_u15(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[255 :224]),
    .data_out(data_mc2ps[15]       )
);

macro macro_layer7_u16(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[31  : 0 ]),
    .data_out(data_mc2ps[16]       )
);
macro macro_layer7_u17(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[63  : 32]),
    .data_out(data_mc2ps[17]       )
);
macro macro_layer7_u18(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[95  : 64]),
    .data_out(data_mc2ps[18]       )
);
macro macro_layer7_u19(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[127 : 96]),
    .data_out(data_mc2ps[19]       )
);
macro macro_layer7_u20(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[159 :128]),
    .data_out(data_mc2ps[20]       )
);
macro macro_layer7_u21(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[191 :160]),
    .data_out(data_mc2ps[21]       )
);
macro macro_layer7_u22(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[223 :192]),
    .data_out(data_mc2ps[22]       )
);
macro macro_layer7_u23(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[255 :224]),
    .data_out(data_mc2ps[23]       )
);

macro macro_layer7_u24(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[31  : 0 ]),
    .data_out(data_mc2ps[24]       )
);
macro macro_layer7_u25(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[63  : 32]),
    .data_out(data_mc2ps[25]       )
);
macro macro_layer7_u26(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[95  : 64]),
    .data_out(data_mc2ps[26]       )
);
macro macro_layer7_u27(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[127 : 96]),
    .data_out(data_mc2ps[27]       )
);
macro macro_layer7_u28(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[159 :128]),
    .data_out(data_mc2ps[28]       )
);
macro macro_layer7_u29(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[191 :160]),
    .data_out(data_mc2ps[29]       )
);
macro macro_layer7_u30(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[223 :192]),
    .data_out(data_mc2ps[30]       )
);
macro macro_layer7_u31(
    .adc     (adc                 ),
    .enable  (macro_e             ),
    .chs_ps  (chs_macro           ),
    .data_in (data_rs2mc[255 :224]),
    .data_out(data_mc2ps[31]       )
);






partial_sum_layer7 #(
    .CHANNEL_NUM(CHANNEL_NUM),      // Channel number of Macro
    .MACRO_NUM  (MACRO_NUM  )       // There are 8 Macro in Layer 4
)partial_sum_layer7_u0(
    .clk       (clk         ),      // System Clock
    .rst_n     (rst_n       ),      // System Reset, Active LOW
    .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    .data_e    (data_e_out_de),
    .data_in   (data_mc2ps  ),  
    .data_out  (data_ps2bn  ),      // Output data from Partail_sum, 16 bit Width, 128
    .data_e_out(data_e_ps2bn)       // Ouput of DATA Enabel signal
);
bn_res_layer7#(
    .FM_DEPTH   (FM_DEPTH   ),      // Depth of the Feature Map
    .CHANNEL_NUM(CHANNEL_NUM)       // Channel number of Macro
)bn_res_layer7_u0(
    .clk       (clk         ),      // System Clock
    .rst_n     (rst_n       ),      // System Reset, Active LOW
    .mode      (mode        ),      // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    .bn_a      (bn_a        ),      // Hyper-parameter of BN
    .bn_b      (bn_b        ),      // Hyper-parameter of BN
    .res       (res_wr2bn   ),      // Residual
    .data_in   (data_ps2bn  ),      // Data from partail_sum
    .data_e    (data_e_ps2bn),      // DATA Enable signal, Active HIGH
    .data_out  (data_bn2RP  ),      // Data to RPReLU
    .data_e_out(data_e_bn2RP)       // DATA Enable signal to RPReLU
);
RPReLU_layer7#(
    .CHANNEL_NUM(CHANNEL_NUM)       // Channel number of Macro
)RPReLU_layer7_u0(
    .clk         (clk         ),    // System Clock
    .rst_n       (rst_n       ),    // System Reset, Active LOW
    .mode        (mode        ),    // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    .data_in     (data_bn2RP  ),    // Data from bn
    .data_e      (data_e_bn2RP),    // DATA Enable signal, Active HIGH
    .rprelu_beta (rprelu_beta ),    // Hyper-parameter of RPReLU 
    .rprelu_gamma(rprelu_gamma),    // Hyper-parameter of RPReLU
    .rprelu_zeta (rprelu_zeta ),    // Hyper-parameter of RPReLU
    .data_out    (data_out    ),    // DATA to next layer(5)
    .data_e_out  (data_e_out  )     // DATA Enable signals
);
endmodule
