module flag_merger(
    input clk,
    input[15:0] a_out,
    input alu_op,
    input a_load,
    input a_op,
    input alu_c_flag,
    input a_c_flag,
    output[2:0] out
);

localparam FLAG_Z = 0;
localparam FLAG_C = 1;
localparam FLAG_S = 2;

initial begin
    flags = 3'b001;
end

reg[2:0] flags;
assign out = flags;

reg load_from_a;
reg load_from_alu;

initial begin
    load_from_a = 0;
    load_from_alu = 0;
end

always @(clk) begin
    flags[FLAG_S] = a_out[15];

    if (a_out == 0) begin
        flags[FLAG_Z] = 1;
    end else begin
        flags[FLAG_Z] = 0;
    end

    if (alu_op) begin
        load_from_alu <= 1;
    end else if (a_op) begin
        load_from_a <= 1;
    end
    
    if (load_from_alu) begin
        flags[FLAG_C] <= alu_c_flag;
        load_from_alu = 0;
    end else if (load_from_a) begin
        flags[FLAG_C] <= a_c_flag;
        load_from_a = 0;
    end
end

endmodule