module decoder
#(
    parameter CHANNEL_NUM  = 128,         // Channel number of Macro
    parameter MICRO_NUM    = 4            // There are 4 macros in layer3
)
(
    input  wire [4:0] data_in [CHANNEL_NUM - 1 : 0][MICRO_NUM-1:0],  // Output data from Partail_sum, 16 bit Width, 128
    output wire [3:0] data_out[CHANNEL_NUM - 1 : 0][MICRO_NUM-1:0]
);

    genvar  i, j;
    generate
       for(i = 0; i < CHANNEL_NUM; i = i + 1) begin:igen
            for(j = 0; j < MACRO_NUM; j = j + 1) begin:jgen
                assign data_out[i][j] = (data_in[i][j]==5'b00000) ? 4'b1000 : (
                                        (data_in[i][j]==5'b00001) ? 4'b1001 : (
                                        (data_in[i][j]==5'b00010) ? 4'b1010 : (
                                        (data_in[i][j]==5'b00100) ? 4'b1011 : (
                                        (data_in[i][j]==5'b01000) ? 4'b1100 : (
                                        (data_in[i][j]==5'b10000) ? 4'b1101 : (
                                        (data_in[i][j]==5'b10001) ? 4'b1110 : (
                                        (data_in[i][j]==5'b10010) ? 4'b1111 : (
                                        (data_in[i][j]==5'b10100) ? 4'b0000 : (
                                        (data_in[i][j]==5'b11000) ? 4'b0001 : (
                                        (data_in[i][j]==5'b11001) ? 4'b0010 : (
                                        (data_in[i][j]==5'b11010) ? 4'b0011 : (
                                        (data_in[i][j]==5'b11100) ? 4'b0100 : (
                                        (data_in[i][j]==5'b11101) ? 4'b0101 : (
                                        (data_in[i][j]==5'b11110) ? 4'b0110 : (
                                        (data_in[i][j]==5'b11111) ? 4'b0111 : 4'b0000
                )))))))))))))));
            end
        end
    endgenerate
endmodule