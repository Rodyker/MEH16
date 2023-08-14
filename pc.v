module pc(
    input clk,
    input load,
    input inc,
    input[11:0] bus,
    output[15:0] out
);

reg[11:0] register;
initial begin
    register = 12'b0;
end

always @(negedge clk) begin
    if (load) begin
        register <= bus;
    end else if (inc) begin
        register <= register + 1;
    end
end

assign out = {4'b0000, register};

endmodule