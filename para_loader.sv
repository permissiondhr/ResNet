module para_loader #(
    parameter FM_DEPTH     = 64,
    parameter PARA_WIDTH   = 16,
    parameter LOG2CHANNEL_NUM = 7,
    parameter CHANNEL_NUM  = 128, 
    parameter PARA_NUM     = 6  
)
(
    input  wire                             clk,
    input  wire                             rstn,
    input  wire                             data_in_valid,
    input  wire                             mode_in,
    input  wire signed [PARA_WIDTH-1 : 0]   para_in,
    output reg  signed [PARA_WIDTH-1 : 0]   rsign_para  [FM_DEPTH - 1 : 0],
    output reg  signed [PARA_WIDTH-1 : 0]   bn_a        [CHANNEL_NUM - 1 : 0],
    output reg  signed [PARA_WIDTH-1 : 0]   bn_b        [CHANNEL_NUM - 1 : 0],
    output reg  signed [PARA_WIDTH-1 : 0]   beta        [CHANNEL_NUM - 1 : 0],
    output reg  signed [PARA_WIDTH-1 : 0]   gamma       [CHANNEL_NUM - 1 : 0],
    output reg  signed [PARA_WIDTH-1 : 0]   zeta        [CHANNEL_NUM - 1 : 0]
);

reg [LOG2CHANNEL_NUM-1 : 0] cnt_depth; // Counter of Depth
reg [2 : 0]                 cnt_para;  // Counter of Parameter

always@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        cnt_depth <= 'b0;
        cnt_para  <= 'b0;
    end 
    else begin
        if((mode_in == 0) && (data_in_valid == 1)) begin
            cnt_depth <= (cnt_para == 0 && cnt_depth == FM_DEPTH-1) ? 0 : cnt_depth + 1;
            cnt_para  <= (cnt_para == 5 && cnt_depth == CHANNEL_NUM-1) ? cnt_para :
                         (cnt_para == 0 && cnt_depth == FM_DEPTH-1 )   ? cnt_para + 1 :
                         (cnt_depth == CHANNEL_NUM - 1)                ? cnt_para + 1 : cnt_para;
        end 
        else begin
            cnt_depth <= cnt_depth;
            cnt_para  <= cnt_para ;
        end
    end
end

always@(posedge clk or negedge rstn) begin
    if(~rstn) begin
        for(int i = 0; i < CHANNEL_NUM; i = i + 1) begin
            bn_a[i]  <= 0;
            bn_b[i]  <= 0;
            beta[i]  <= 0;
            gamma[i] <= 0;
            zeta[i]  <= 0;
        end
        for(int j = 0; j < FM_DEPTH; j = j + 1) begin
            rsign_para[j]  <= 'b0;
        end
    end 
    else begin
        if(mode == 0 && data_in_valid == 1) begin
            rsign_para[cnt_depth]   <= (cnt_para == 0) ? para_in : rsign_para[cnt_depth];
            bn_a[cnt_depth]         <= (cnt_para == 1) ? para_in : bn_a[cnt_depth];
            bn_b[cnt_depth]         <= (cnt_para == 2) ? para_in : bn_b[cnt_depth];
            beta[cnt_depth]         <= (cnt_para == 3) ? para_in : beta[cnt_depth];
            gamma[cnt_depth]        <= (cnt_para == 4) ? para_in : gamma[cnt_depth];
            zeta[cnt_depth]         <= (cnt_para == 5) ? para_in : zeta[cnt_depth];
        end 
        else begin
            rsign_para[cnt_depth]   <= rsign_para[cnt_depth]  ;
            bn_a[cnt_depth]         <= bn_a[cnt_depth]        ;
            bn_b[cnt_depth]         <= bn_b[cnt_depth]        ;
            beta[cnt_depth]         <= beta[cnt_depth] ;
            gamma[cnt_depth]        <= gamma[cnt_depth];
            zeta[cnt_depth]         <= zeta[cnt_depth] ;
        end
    end
end

endmodule