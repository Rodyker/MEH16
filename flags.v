module flags(
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

reg[2:0] flags;
reg load_from_alu;
reg load_from_a;

initial begin
    flags = 3'b001;
    load_from_a = 0;
    load_from_alu = 0;
end

always @(posedge clk) begin
    flags[FLAG_S] = a_out[15];
    flags[FLAG_Z] = (a_out == 0);

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

assign out = flags;

endmodule