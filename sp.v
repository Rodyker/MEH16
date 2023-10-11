module sp(
    input clk,
    input load,
    input dec,
    input add,
    input[15:0] bus,
    output[15:0] out
);

reg[15:0] register;

always @(negedge clk) begin
    if (load) begin
        register <= bus;
    end else if (dec) begin
        register <= register - 1;
    end else if (add) begin
        register <= register + bus;
    end
end

assign out = register;

endmodule