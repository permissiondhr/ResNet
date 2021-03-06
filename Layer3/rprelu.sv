module rprelu
#(
    parameter DATA_WIDTH   = 16,
    parameter PARA_WIDTH   = 16,
    parameter CHANNEL_NUM  = 128
)
(
    input   wire                    		clk,    			                 // System Clock
    input   wire                    		rstn,    			                 // System Reset, Active LOW
    input   wire                    		data_in_valid,    			         // DATA Enable signal, Active HIGH
    input   wire signed [DATA_WIDTH-1 : 0]  data_in         [CHANNEL_NUM-1 : 0], // Data from bn
    input   wire signed [PARA_WIDTH-1 : 0]  beta            [CHANNEL_NUM-1 : 0], // Hyper-parameter of RPReLU 
    input   wire signed [PARA_WIDTH-1 : 0]  gamma           [CHANNEL_NUM-1 : 0], // Hyper-parameter of RPReLU
    input   wire signed [PARA_WIDTH-1 : 0]  zeta            [CHANNEL_NUM-1 : 0], // Hyper-parameter of RPReLU
    output  reg  signed [DATA_WIDTH-1 : 0]  data_out        [CHANNEL_NUM-1 : 0], // DATA to next layer(5)
    output  reg                             data_out_valid                       // DATA Enable signals
);

reg  signed [DATA_WIDTH     : 0] data_gamma [CHANNEL_NUM-1 : 0]; // MSB extends 1bit for substraction
reg  signed [DATA_WIDTH*2-1 : 0] prelu_mul  [CHANNEL_NUM-1 : 0]; // 2*data_width for multiplication
wire signed [DATA_WIDTH*2-9 : 0] prelu_sr   [CHANNEL_NUM-1 : 0]; // 23:0 for shift right
wire signed [DATA_WIDTH*2-8 : 0] rprelu     [CHANNEL_NUM-1 : 0];
wire signed [DATA_WIDTH-1   : 0] data_cut   [CHANNEL_NUM-1 : 0];
reg                              temp_valid1;
reg                              temp_valid2;

always @(posedge clk or negedge rstn) begin    
    if(~rstn)
        temp_valid1  <= 0;
	else begin
		if(data_in_valid)
        	temp_valid1  <= 1;
		else
        	temp_valid1  <= 0;
    end
end

always @(posedge clk or negedge rstn) begin    
    if(~rstn)
        temp_valid2  <= 0;
	else begin
		if(temp_valid1)
        	temp_valid2  <= 1;
		else
        	temp_valid2  <= 0;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn)
        data_out_valid  <= 0;
    else begin 
        if(temp_valid2)
            data_out_valid  <= 1;
        else
            data_out_valid  <= 0;
    end
end

genvar i;
generate
    for(i = 0; i < CHANNEL_NUM; i = i + 1) begin
        //assign data_gamma[i] = data_in[i] - gamma[i];
        always @(posedge clk or negedge rstn) begin
            if(~rstn)
                data_gamma[i] <= 0;
            else begin
                if (data_in_valid)
                    data_gamma[i] <= data_in[i] - gamma[i];
                else ;
            end
        end

        always @(posedge clk or negedge rstn) begin
            if(~rstn)
                prelu_mul[i] <= 0;
            else begin
                if (temp_valid1)
                    prelu_mul[i] <= beta[i] * data_gamma[i];
                else ;
            end
        end

        assign prelu_sr  [i] = prelu_mul[i] >>> 8;
        assign rprelu    [i] = (data_in[i] > gamma[i]) ? (data_gamma[i] + zeta[i]) : (prelu_sr[i] + zeta[i]);
        assign data_cut  [i] = (rprelu[i][24] == 1) ? ((rprelu[i][23:15] == 9'h1ff) ? rprelu[i][15:0] : 16'h8000)
				   					                : ((rprelu[i][23:15] == 9'h000) ? rprelu[i][15:0] : 16'h7fff);
        always @(posedge clk or negedge rstn) begin
            if(~rstn)
                data_out[i] <= 0;
            else begin 
                if(temp_valid2)
                    data_out[i] <= data_cut[i];
                else ;
            end
        end
    end
endgenerate

endmodule