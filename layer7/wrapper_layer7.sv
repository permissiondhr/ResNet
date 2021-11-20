`include "defines.v"
module wrapper_layer7
#(
    parameter FM_DEPTH     = 'd256,         // Depth of the Feature Map
    parameter FM_WIDTH     = 'd14          // Width of the Feature Map
)
(
    // GLOBAL SIGNALS
    input  wire                              clk                              , // System Clock
                                             rst_n                            , // System Reset, Active LOW
                                             mode                             , // Mode Switch, LOW -> Reload parameter; HIGH -> Calculate
    // Input from previous layer(layer5)
    input  wire                              data_e                           , // DATA Enable signal, Active HIGH
                                             vs                               , // Vsync Signal
    input  wire signed [`DATA_WIDTH - 1 : 0] data_in [FM_DEPTH - 1 : 0]       ,
    // Outputs to RSign
    output wire signed [`DATA_WIDTH - 1 : 0] data_out[FM_DEPTH - 1 : 0][8 : 0], // FM_DEPTH / 4
    output reg                               data_e_out                       , // DATA Enable signal, Active HIGH
    // Outputs to bn_res
    output reg  signed [`DATA_WIDTH - 1 : 0] res     [FM_DEPTH - 1 : 0]       ,
    // Outputs to macro
    output wire                              latch                            ,
                                             adc                              ,
                                             macro_e                          ,
    // Outputs to next layer
    output wire                              vs_next                          ,
    output reg         [1 : 0]               chs_macro                        ,
    // Outputs to decoder
    output wire                              data_e_out_de
);

    // counter
    reg [3 : 0] w_r;
    reg [4 : 0] row,
                col;
    //reg counter_ds; // counter for down simple

    // Location of the Conv Core
    wire edg_n_r, // 1 -> left  , 0 -> others
         edg_n_c; // 1 -> bottom, 0 -> others

    // Addr
    reg  [5 : 0] addr_reg;
    wire [5 : 0] addr    ;

    // Conv Matrix
    reg [`DATA_WIDTH - 1 : 0] matrix[FM_DEPTH - 1 : 0][8 : 0];

    // First pic Flag
    reg first_pic_n;

    // Data_reg
    // reg signed [`DATA_WIDTH - 1 : 0] data_out_reg[FM_DEPTH - 1 : 0][8 : 0];
    reg signed [`DATA_WIDTH - 1 : 0] data_mem[2 * FM_WIDTH - 1 : 0][FM_DEPTH - 1 : 0];
    // Res
    reg signed [17 : 0] res_reg[FM_DEPTH - 1 : 0];

    // ****** First picture flag ******
    always @(posedge clk or negedge rst_n) begin    // first picture flag, Active LOW
        if(rst_n == `RSTVALID) begin
            first_pic_n = 1'b0; 
        end else if(row == 0 && col == 2 && w_r == 15) begin
            first_pic_n = 1'b1;
        end else begin
            first_pic_n = first_pic_n;
        end// if
    end // always

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            chs_macro <= 2'b00;
        end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
            chs_macro[0] <= chs_macro[0] + 1'b1;
        end else begin
            chs_macro[0] <= chs_macro[0];
        end // if
    end // always

    assign data_e_out = (w_r == 0) && first_pic_n && (col[0] == 1'b0) && (row[0] == 1'b1);

    // ****** w_r counter generator ******
    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID ) begin
	        w_r <= 'd15;
	    end else if(vs == `VSVALID) begin
            w_r <= 'd15;
        end else if(data_e == `DATAVALID) begin
            w_r <= 'b0 ;
        end else if(mode == `CALCULATE && w_r < 'd15) begin
            w_r <= w_r + 1'b1;
        end else begin
            w_r <= w_r;
        end //if
    end // always

// ***** Coordinate of Input data *****
    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID ) begin
            row <= FM_WIDTH - 1;
            col <= FM_WIDTH - 1;
	    end else if( vs == `VSVALID) begin
            row <= FM_WIDTH - 1;
            col <= FM_WIDTH - 1;
        end else if(mode == `CALCULATE && data_e == `DATAVALID) begin
            row <= (row < FM_WIDTH - 1) ? row + 1'b1 : 5'b00000;
            col <= (row < FM_WIDTH - 1) ? col        :
                   (col < FM_WIDTH - 1) ? col + 1'b1 :
                                          5'b00000   ;
        end else begin
            row <= row;
            col <= col;
        end // if
    end // always


    // ***** Location of Next Matrix *****
    assign edg_n_r = (row == 0) ? 1 :     // row == 1 indicate that the Matrix is on the LEFT of FM
                                  0 ;     // other cases indicate that the Matrix is in the MIDDLE of FM
    assign edg_n_c = (col == 0) ? 1 :     // col == 1 indicate that the Matrix is on the BOTTOM of FM
                                  0 ;     // other cases indicate that the Matrix is in the MIDDLE of FM

    // ****** Location Current Matrix
    assign edg_r = (row == 1) ? 1 :
                                0 ;
    assign edg_c = (row == 0) ? ((col == 1) ? 1 :
                                              0):
                   (col == 0) ?               1 : 
                                              0 ;

    // ***** addr_generator *****
    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID)begin
	        addr_reg <= 0;
        end else if(vs == `VSVALID) begin
            addr_reg <= 0;
        end else if(w_r == 1) begin // Caculate Addr for reading data of Matrix[5]
            addr_reg <= row + (!col[0]) * FM_WIDTH + 1;
        end else if(w_r == 2) begin // Caculate Addr for reading data of Matrix[2]
            addr_reg <= row +   col[0]  * FM_WIDTH + 1;
        end else begin
            addr_reg <= addr_reg;
        end// if
    end // always

    assign addr = (addr_reg == 2 * FM_WIDTH) ? 0 : addr_reg;

    //reg signed [`DATA_WIDTH - 1 : 0] data_mem[2 * FM_WIDTH - 1 : 0][FM_DEPTH - 1 : 0];

    genvar m;
    generate for(m = 0; m < FM_DEPTH; m = m + 1) begin: data_mem_loop
        integer n;
        always @(posedge clk or negedge rst_n) begin
            if(rst_n == `RSTVALID) begin
                for(n = 0; n < 2 * FM_WIDTH; n = n + 1) begin
                    data_mem[n][m] <= 16'b0;
                end // for n
            end else if (mode == `CALCULATE && data_e == `DATAVALID) begin    // indicate that when w_r == 2, read register
                data_mem[addr][m] <= data_in[m]; 
            end else begin
                for(n = 0; n < 2 * FM_WIDTH; n = n + 1) begin
                    data_mem[n][m] <= data_mem[n][m];
                end // for n
            end // if
        end // always
    end // for m
    endgenerate

    // ****** Signals To Macro ******
    assign latch   = ((mode == `CALCULATE) && (w_r >  0) && (w_r <  5)) ? 1'b1 : 1'b0;
    assign adc     = ((mode == `CALCULATE) && (w_r >  0) && (w_r <  6)) ? 1'b0 : 1'b1;
    assign macro_e = first_pic_n && (w_r > 0) && (w_r < 9);
    assign vs_next = ( row  == 3         ) && (col == 2) && (w_r == 5);


    // ****** Matrix / Data_out Generator
    genvar i;
    generate for(i = 0; i < FM_DEPTH; i = i + 1) begin: matrix_data_out_loop
        // generate Matrix
        always @(posedge clk or negedge rst_n) begin
            if(rst_n == `RSTVALID) begin
                matrix[i][0] <= 16'h0000;
                matrix[i][1] <= 16'h0000;
                matrix[i][2] <= 16'h0000;
                matrix[i][3] <= 16'h0000;
                matrix[i][4] <= 16'h0000;
                matrix[i][5] <= 16'h0000;
                matrix[i][6] <= 16'h0000;
                matrix[i][7] <= 16'h0000;
                matrix[i][8] <= 16'h0000;
            end else if(mode == `CALCULATE && w_r == 0) begin
                matrix[i][8] <= data_mem[addr][i];
	        end else if(mode == `CALCULATE && w_r == 2) begin
                matrix[i][0] <= matrix[i][1];
                matrix[i][3] <= matrix[i][4];
                matrix[i][6] <= matrix[i][7];
                matrix[i][1] <= matrix[i][2];
                matrix[i][4] <= matrix[i][5];
                matrix[i][7] <= matrix[i][8];
                matrix[i][5] <= data_mem[addr][i];
            end else if(mode == `CALCULATE && w_r == 3) begin
                matrix[i][2] <= data_mem[addr][i];
            end else begin
		        matrix[i][0] <= matrix[i][0];
                matrix[i][1] <= matrix[i][1];
                matrix[i][2] <= matrix[i][2];
                matrix[i][3] <= matrix[i][3];
                matrix[i][4] <= matrix[i][4];
                matrix[i][5] <= matrix[i][5];
                matrix[i][6] <= matrix[i][6];
                matrix[i][7] <= matrix[i][7];
                matrix[i][8] <= matrix[i][8];
	        end // if
        end // always

        // ****** Pooling ******
        always @(posedge clk or negedge rst_n) begin
            if(rst_n == `RSTVALID) begin
                res_reg[i] <= 18'b0;
            end else if(data_e_out == `DATAVALID) begin
                res_reg[i] <= matrix[i][1] + matrix[i][2] + matrix[i][4] + matrix[i][5];
            end else begin
                res_reg[i] <= res_reg[i];
            end // if
        end // always

        always @(posedge clk or negedge rst_n) begin
            if(rst_n == `RSTVALID) begin
                res[i] <= 16'b0;
            end else if(data_e_out == `DATAVALID) begin
                res[i] <= res_reg[i][17 : 2];
            end else begin
                res[i] <= res[i];
            end // if
        end // always

        // ****** Data_out ******

        // For saving area, ALL output data will be send to the RSign module to storage
        assign data_out[i][0] = (edg_r == 1              ) ? 0 : matrix[i][0];
        assign data_out[i][1] =                                  matrix[i][1];
        assign data_out[i][2] =                                  matrix[i][2];
        assign data_out[i][3] = (edg_r == 1              ) ? 0 : matrix[i][3];
        assign data_out[i][4] =                                  matrix[i][4];
        assign data_out[i][5] =                                  matrix[i][5];
        assign data_out[i][6] = (edg_r == 1 || edg_c == 1) ? 0 : matrix[i][6];
        assign data_out[i][7] = (              edg_c == 1) ? 0 : matrix[i][7];
        assign data_out[i][8] = (              edg_c == 1) ? 0 : data_mem[addr][i];

    end // for i
    endgenerate // generate



    // ****** Data_Enable for decoder ******
    assign data_e_out_de_tmp = (w_r == 1) && first_pic_n;

    reg first_flag_de;

    always @(posedge clk or negedge rst_n) begin
        if(rst_n == `RSTVALID) begin
            first_flag_de <= 1'b0;
        end else if (data_e_out_de_tmp == `DATAVALID || first_flag_de == 1'b1) begin
            first_flag_de <= 1'b1;
        end else begin
            first_flag_de <= first_flag_de;
        end
    end // always

    assign data_e_out_de = first_flag_de && (data_e_out_de_tmp == `DATAVALID);




endmodule // wrapper_layer5