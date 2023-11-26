module ir(
    input clk,
    input load,
    input[15:0] bus,
    output[15:0] out,
    input reset
);

initial begin
    register = 16'b0;
end

reg[15:0] register;

always @(negedge clk) begin
    if (reset) begin
        register = 16'b0;
    end else if (load) begin
        register <= bus;
    end
end

assign out = register;

endmodule