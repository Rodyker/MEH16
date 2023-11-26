module sp(
    input clk,
    input stack_load,
    input sp_add,
    input[9:0] ram_arg,
    output[15:0] out,
    input ir_reset
);

reg[11:0] register;

initial begin
    register = 12'b111111111111;
end

always @(posedge clk) begin
    if (ir_reset) begin
        register <= 12'b111111111111;
    end else if (stack_load) begin
        register <= register - 1;
    end else if (sp_add) begin
        register <= register + ram_arg + 1;
    end
end

assign out = {4'b0000, register};

endmodule