module RPReLU_layer4
#(
    parameter DATA_WIDTH   = 16,
    parameter PARA_WIDTH   = 16,
    parameter CHANNEL_NUM  = 128
)
(
    input   wire                    			clk             ,    			    // System Clock
    input   wire                    			rstn            ,    			    // System Reset, Active LOW
    input   wire                    			data_in_valid   ,    			    // DATA Enable signal, Active HIGH
    input   wire                    			mode_in         ,
    input   wire signed [DATA_WIDTH - 1 : 0]   data_in      [CHANNEL_NUM - 1 : 0],  // Data from bn
    input   wire signed [PARA_WIDTH - 1 : 0]   rprelu_beta  [CHANNEL_NUM - 1 : 0],  // Hyper-parameter of RPReLU 
    input   wire signed [PARA_WIDTH - 1 : 0]   rprelu_gamma [CHANNEL_NUM - 1 : 0],  // Hyper-parameter of RPReLU
    input   wire signed [PARA_WIDTH - 1 : 0]   rprelu_zeta  [CHANNEL_NUM - 1 : 0],  // Hyper-parameter of RPReLU
    output  reg  signed [DATA_WIDTH - 1 : 0]   data_out     [CHANNEL_NUM - 1 : 0],  // DATA to next layer(5)
    output  reg                                data_out_valid                       //DATA Enable signals
);

    integer i;
    always @(posedge clk or negedge rstn) begin
        for(i = 0; i < CHANNEL_NUM; i = i + 1) begin
            if(~rstn) begin
                data_out_valid  <= 0;
                data_out[i]     <= 0;
            end else if(mode  && data_in_valid) begin
                data_out_valid  <= 1;
                data_out[i]     <= (data_in[i] > rprelu_gamma) ? (data_in[i] - rprelu_gamma[i] + rprelu_zeta[i)] : (rprelu_beta * (data_in[i] - rprelu_gamma[i]) + rprelu_zeta[i]);
            end else begin
                data_out_valid  <= 0;
                data_out[i]     <= data_out[i] ;
            end // if 
        end // for i
    end // always

endmodule // model RPReLU_layer4