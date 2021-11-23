
`include "defines.v"
module para_loader_layer7
#(
    parameter FM_DEPTH        = 256,         // Depth of the Feature Map
    parameter LOG2CHANNEL_NUM = 9  ,
    parameter CHANNEL_NUM     = 512          // Channel number of Macro
)
(
    input  wire                              clk                              , // System Clock
    input  wire                              rst_n                            , // System Reset, Active LOW
    input  wire                              mode                             , // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    input  wire                              data_e_para                      , // Para data Enable signal, Active HIGH
    input  wire signed [`PARA_WIDTH - 1 : 0] para_in                          , // Parameter input
    output reg  signed [`PARA_WIDTH - 1 : 0] rsign_para  [   FM_DEPTH - 1 : 0],    
    output reg  signed [`PARA_WIDTH - 1 : 0] bn_a        [CHANNEL_NUM - 1 : 0],
    output reg  signed [`PARA_WIDTH - 1 : 0] bn_b        [CHANNEL_NUM - 1 : 0],
    output reg  signed [`PARA_WIDTH - 1 : 0] rprelu_beta [CHANNEL_NUM - 1 : 0],
    output reg  signed [`PARA_WIDTH - 1 : 0] rprelu_gamma[CHANNEL_NUM - 1 : 0],
    output reg  signed [`PARA_WIDTH - 1 : 0] rprelu_zeta [CHANNEL_NUM - 1 : 0]
);

    // Counter of Depth
    reg [LOG2CHANNEL_NUM - 1 : 0] cnt_depth;
    // Counter of Parameter
    reg [2 : 0] cnt_para;

    // Counter
    always@(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            cnt_depth <= 'b0;
            cnt_para  <= 'b0;
        end else if(mode == `LOAD_PARA && data_e_para == `DATAVALID) begin
            cnt_depth <= (cnt_para == 'd0 && cnt_depth == FM_DEPTH - 1) ? 'b0 :
                                                                          cnt_depth + 1;
            cnt_para  <= (cnt_para == 'd5 && cnt_depth == CHANNEL_NUM - 1) ? cnt_para     :
                         (cnt_para == 'd0 && cnt_depth == FM_DEPTH - 1   ) ? cnt_para + 1 :
                         (cnt_depth == CHANNEL_NUM - 1                   ) ? cnt_para + 1 :
                                                                             cnt_para     ;
        end else begin
            cnt_depth <= cnt_depth;
            cnt_para  <= cnt_para ;
        end // if
    end // always

    // Parameter Loader
    always@(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin // When reset is RSTVALID, reset all parameters
            for(int i = 0; i < CHANNEL_NUM; i = i + 1) begin: rst_para_loop
                bn_a[i]         <= 'b0;
                bn_b[i]         <= 'b0;
                rprelu_beta[i]  <= 'b0;
                rprelu_gamma[i] <= 'b0;
                rprelu_zeta[i]  <= 'b0;
            end // for i
            for(int j = 0; j < FM_DEPTH; j = j + 1) begin: rst_rsign_para_loop
                rsign_para[j]  <= 'b0;
            end // fot j
        end else if(mode == `LOAD_PARA && data_e_para == `DATAVALID) begin // LOAD_PARA mode, load each parameters
            rsign_para[cnt_depth]   <= (cnt_para == 'd0) ? para_in : rsign_para[cnt_depth]  ;
            bn_a[cnt_depth]         <= (cnt_para == 'd1) ? para_in : bn_a[cnt_depth]        ;
            bn_b[cnt_depth]         <= (cnt_para == 'd2) ? para_in : bn_b[cnt_depth]        ;
            rprelu_beta[cnt_depth]  <= (cnt_para == 'd3) ? para_in : rprelu_beta[cnt_depth] ;
            rprelu_gamma[cnt_depth] <= (cnt_para == 'd4) ? para_in : rprelu_gamma[cnt_depth];
            rprelu_zeta[cnt_depth]  <= (cnt_para == 'd5) ? para_in : rprelu_zeta[cnt_depth] ;
        end else begin
            rsign_para[cnt_depth]   <= rsign_para[cnt_depth]  ;
            bn_a[cnt_depth]         <= bn_a[cnt_depth]        ;
            bn_b[cnt_depth]         <= bn_b[cnt_depth]        ;
            rprelu_beta[cnt_depth]  <= rprelu_beta[cnt_depth] ;
            rprelu_gamma[cnt_depth] <= rprelu_gamma[cnt_depth];
            rprelu_zeta[cnt_depth]  <= rprelu_zeta[cnt_depth] ;
        end // if
    end // always

endmodule // module para_loader