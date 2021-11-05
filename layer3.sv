module layer3
#(
    parameter FM_DEPTH     = 128,
    parameter FM_WIDTH     = 56 ,
    parameter LOG2FM_DEPTH = 6  ,
    parameter CHANNEL_NUM  = 128,
    parameter MACRO_NUM    = 4  ,
    parameter PARA_NUM     = 6   
) (
    input   wire                        clk    ,
    input   wire                        rstn   , 
    input   wire                        mode_in, // mode_in Switch, LOW -> Reload parameter; HIGH -> Calculate
    input   wire                        vs     ,     // Vsync Signal
    input   wire                        data_e                       ,
    input   wire [DATA_WIDTH - 1 : 0]   data_in[FM_DEPTH - 1 : 0]    ,
    input   wire [PARA_WIDTH - 1 : 0]   para_in                      ,
    output  wire                        data_e_out                   ,
    output  wire [DATA_WIDTH - 1 : 0]   data_out[CHANNEL_NUM - 1 : 0],
    output  wire                        vs_next                    
);

    // Signals From Wrapper to RSign
    wire [DATA_WIDTH - 1 : 0] data_wr2rs[FM_DEPTH - 1 : 0];
    wire                       data_e_wr2rs;
    
    // Signals From Wrapper to bn_res
    wire [DATA_WIDTH - 1 : 0] res_wr2bn[FM_DEPTH - 1 : 0];
    
    // Signals From Wrapper to Macro
    wire latch, adc;   

    // Parameter From para_loader
    wire [PARA_WIDTH - 1 : 0] rsign_para    [FM_DEPTH - 1 : 0];
    wire [PARA_WIDTH - 1 : 0] bn_a          [FM_DEPTH - 1 : 0];
    wire [PARA_WIDTH - 1 : 0] bn_b          [FM_DEPTH - 1 : 0];
    wire [PARA_WIDTH - 1 : 0] rprelu_beta   [FM_DEPTH - 1 : 0];
    wire [PARA_WIDTH - 1 : 0] rprelu_gamma  [FM_DEPTH - 1 : 0];
    wire [PARA_WIDTH - 1 : 0] rprelu_zeta   [FM_DEPTH - 1 : 0];

    // Signals From RSign to Macro
    wire [0 : 0] data_rs2mc[FM_DEPTH - 1 : 0][8 : 0];
    // Signals From Rsgin to bn_res
    wire data_e_rs2bn;

    // Signals From Macro to decoder
    wire data_e_mc2de;
    wire [`MACRO_O_DW - 1 : 0] data_mc2de[CHANNEL_NUM - 1 : 0][MACRO_NUM - 1 : 0];

    // Signals FROM decoder to partail_sum
    wire data_e_de2ps;
    wire [`DECODER_O_DW - 1 : 0] data_de2ps[CHANNEL_NUM - 1 : 0][MACRO_NUM - 1 : 0];

    // Signals From partail_sum to bn_res
    wire data_e_ps2bn;
    wire [DATA_WIDTH - 1 : 0] data_ps2bn[CHANNEL_NUM - 1 : 0];

    // Signals From bn_res to RPReLU
    wire data_e_bn2RP;
    wire [DATA_WIDTH - 1 : 0] data_bn2RP[CHANNEL_NUM - 1 : 0];

    // ****** Instantiation ******

    wrapper_layer4
    #(
        .FM_DEPTH   (FM_DEPTH   ),      // Depth of the Feature Map
        .FM_WIDTH   (FM_WIDTH   ),      // Width of the Feature Map
        .CHANNEL_NUM(CHANNEL_NUM),      // Channel number of Macro
        .MACRO_NUM  (MACRO_NUM  )       // There are 8 Macro in Layer 4
    )
    wrapper_layer4_u0
    (
        // GLOBAL INPUTS
        .clk       (clk         ),      // System Clock
        .rstn     (rstn       ),      // System Reset, Active LOW
        .mode_in      (mode_in        ),      // mode_in Switch, LOW -> Reload parameter; HIGH -> Calculate
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
        .latch     (latch       ),
        .adc       (adc         )
    );



    para_loader_layer4
    #(
        .FM_DEPTH    (FM_DEPTH    ),
        .FM_WIDTH    (FM_WIDTH    ),
        .LOG2FM_DEPTH(LOG2FM_DEPTH),
        .PARA_NUM    (PARA_NUM    )
    )
    para_loader_layer4_u0
    (
        // GLOBAL INPUTS
        .clk          (clk         ),   // System Clock
        .rstn        (rstn       ),   // System Reset, Active LOW
        .data_e       (data_e      ),   // DATA Enable signal, Active HIGH
        .mode_in         (mode_in        ),   // mode_in Switch, LOW -> Reload parameter; HIGH -> Calculate
        // INPUT parameter
        .para_in      (para_in     ),   // Parameter Input, Source: ****
        // OUTPUT parameter
        .rsign_para   (rsign_para  ),   // Hyper-parameter of RSign
        .bn_a         (bn_a        ),   // Hyper-parameter of BN
        .bn_b         (bn_b        ),   // Hyper-parameter of BN
        .rprelu_beta  (rprelu_beta ),   // Hyper-parameter of RPReLU 
        .rprelu_gamma (rprelu_gamma),   // Hyper-parameter of RPReLU
        .rprelu_zeta  (rprelu_zeta ),   // Hyper-parameter of RPReLU
    );

    RSign_layer4
    #(
        .FM_DEPTH     (FM_DEPTH    ),   // Depth of the Feature Map
        .FM_WIDTH     (FM_WIDTH    ),   // Width of the Feature Map
        .LOG2FM_DEPTH (LOG2FM_DEPTH)    // Log2(FM_DEPTH)
    )
    RSign_layer4_u0
    (
        // GLOBAL INPUTS
        .clk       (clk         ),      // System Clock
        .rstn     (rstn       ),      // System Reset, Active LOW
        .mode_in      (mode_in        ),      // mode_in Switch, LOW -> Reload parameter; HIGH -> Calculate
        // INPUT parameter
        .para      (rsign_para  ),      // RSign Parameter input
        // INPUT FROM wrapper
        .data_in   (data_wr2rs  ),      // Input Data
        .data_e    (data_e_wr2rs),      // DATA Enable signal, Active HIGH
        // OUTPUT TO Macro
        .data_out  (data_rs2mc  ),      // Output Data after RSign
        // OUTPUT TO bn_res
        .data_e_out(data_e_rs2bn)       // Ouput of DATA Enabel signal, Active HIGH
    ); 


    decoder_layer4
    #(
        .FM_DEPTH   (FM_DEPTH   ),      // Depth of the Feature Map
        .FM_WIDTH   (FM_WIDTH   ),      // Width of the Feature Map
        .CHANNEL_NUM(CHANNEL_NUM),      // Channel number of Macro
        .MACRO_NUM  (MACRO_NUM  )       // There are 8 Macro in Layer 4
    )
    decoder_layer4_u0
    (
        // INPUT FROM Macro
        .data_e    (data_e_mc2de),
        .data_in   (data_mc2de  ),
        // OUTPUT TO patail_sum
        .data_out  (data_e_de2ps),      // Output data after decode, 4 bit Width, 128 x 8
        .data_e_out(data_de2ps  )       // Ouput of DATA Enabel signal
    );

    partail_sum_layer4
    #(
        .FM_DEPTH   (FM_DEPTH   ),      // Depth of the Feature Map
        .FM_WIDTH   (FM_WIDTH   ),      // Width of the Feature Map
        .CHANNEL_NUM(CHANNEL_NUM),      // Channel number of Macro
        .MACRO_NUM  (MACRO_NUM  )       // There are 8 Macro in Layer 4
    )
    (
        // INPUT From decoder
        .data_e    (data_e_de2ps),
        .data_in   (data_de2ps  ),  
        // OUTPUT to bn_res
        .data_out  (data_e_ps2bn),      // Output data from Partail_sum, 16 bit Width, 128
        .data_e_out(data_ps2bn  )       // Ouput of DATA Enabel signal
    );

    bn_res_layer4
    #(
        .FM_DEPTH   (FM_DEPTH   ),      // Depth of the Feature Map
        .FM_WIDTH   (FM_WIDTH   ),      // Width of the Feature Map
        .CHANNEL_NUM(CHANNEL_NUM),      // Channel number of Macro
        .MACRO_NUM  (MACRO_NUM  )       // There are 8 Macro in Layer 4
    )
    bn_res_layer4_u0
    (
    // GLOBAL INPUTS
        .clk       (clk         ),      // System Clock
        .rstn     (rstn       ),      // System Reset, Active LOW
        .mode_in      (mode_in        ),      // mode_in Switch, LOW -> Reload parameter; HIGH -> Calculate
    // INPUTS FROM para_loader
        .bn_a      (bn_a        ),      // Hyper-parameter of BN
        .bn_b      (bn_b        ),      // Hyper-parameter of BN
    // INPUTS FROM wrapper
        .res       (res_wr2bn   ),      // Residual
    // INPUTS FROM partail_sum
        .data_in   (data_ps2bn  ),      // Data from partail_sum
    // INPUTS FROM RSign
        .data_e    (data_e_rs2bn),      // DATA Enable signal, Active HIGH
        //.data_e (data_e_ps_bn)
    // OUTPUTS TO RPReLU
        .data_out  (data_bn2RP  ),      // Data to RPReLU
        .data_e_out(data_e_bn2RP)       // DATA Enable signal to RPReLU
    );


    RPReLU_layer4
    #(
        .FM_DEPTH   (FM_DEPTH   ),      // Depth of the Feature Map
        .FM_WIDTH   (FM_WIDTH   ),      // Width of the Feature Map
        .CHANNEL_NUM(CHANNEL_NUM),      // Channel number of Macro
        .MACRO_NUM  (MACRO_NUM  )       // There are 8 Macro in Layer 4
    )
    RPReLU_layer4_u0
    (
    // GLOBAL INPUTS
        .clk         (clk         ),    // System Clock
        .rstn       (rstn       ),    // System Reset, Active LOW
        .data_e      (data_e_bn2RP),    // DATA Enable signal, Active HIGH
        .mode_in        (mode_in        ),    // mode_in Switch, LOW -> Reload parameter; HIGH -> Calculate
    // INPUT FROM BN
        .data_in     (data_bn2RP  ),    // Data from bn
    // INPUTS FROM para_loader
        .rprelu_beta (rprelu_beta ),    // Hyper-parameter of RPReLU 
        .rprelu_gamma(rprelu_gamma),    // Hyper-parameter of RPReLU
        .rprelu_zeta (rprelu_zeta ),    // Hyper-parameter of RPReLU
    // OUTPUT TO next layer(layer5)
        .data_out    (data_out    ),    // DATA to next layer(5)
        .data_e_out  (data_e_out  )     // DATA Enable signals
    );

endmodule // layer4