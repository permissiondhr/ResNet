module rsign #(
    parameter FM_DEPTH  = 64,
    parameter CORE_SIZE = 9
) (
    input   wire                clk,
    input   wire                rstn,
    input   wire                data_in_valid,
    input   wire                mode_in,        // Load parameter when low, calculate when asserted
    input   wire signed [15:0]  para_in [FM_DEPTH-1:0],
    input   wire signed [15:0]  data_in [FM_DEPTH-1:0][CORE_SIZE-1:0],
    output  reg  signed         data_out[FM_DEPTH-1:0][CORE_SIZE-1:0],
    output  reg                 data_out_valid
);
genvar i, j;
generate 
    for(i = 0; i < FM_DEPTH; i = i + 1) begin: Rsign_for
        for(j = 0; j< 9; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if(~rstn) begin    // When RESET is valid, reset data_out, data_e_out
                    data_out[i][j] <= 1'b0;
                    data_out_valid <= 0;
                end else if(mode_in && data_in_valid) begin
                    data_out[i][j] <= data_in[i][j] > para_in[i] ? 1'b1 : 1'b0;
                    data_out_valid <= 1;
                end else begin
                    data_out[i][j] <= data_out[i][j];
                    data_out_valid <= 0;
                end//if
            end //always
        end // for j
    end // for i
endgenerate // generate

endmodule