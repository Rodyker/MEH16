module register(
    input clk,
    input load,
    input[15:0] bus,
    output[15:0] out
);

reg[15:0] register;

always @(negedge clk) begin
    if (load) begin
        register <= bus;
    end
end

assign out = register;

endmodule