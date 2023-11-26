module mar(
    input clk,
    input load,
    input mar_inc,
    input jump,
    input pc_mar_load,
    input mar_a_load,
    input mar_stack,
    input[15:0] sp_out,
    input[9:0] ir_arg,
    input[11:0] a_out,
    input[11:0] pc,
    input[11:0] bus,
    output[11:0] out,
    input reset
);

reg[11:0] register;

initial begin
    register = 12'b0;
end

always @(negedge clk) begin
    if (reset) begin
        register = 12'b0;
    end else if (mar_stack) begin
        register <= sp_out + ir_arg + 1;
    end else if (load) begin
        register <= bus;
    end else if (jump) begin
        register <= register + 2;
    end else if (pc_mar_load) begin
        register <= pc;
    end else if (mar_inc) begin
        register <= register + 1;
    end else if (mar_a_load) begin
        register <= a_out;
    end
end

assign out = register;

endmodule