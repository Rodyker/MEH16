module pc(
    input clk,
    input load,
    input inc,
    input jump,
    input[11:0] bus,
    output[15:0] out,
    input reset
);

initial begin
    register = 12'b0;
end

reg[11:0] register;

always @(negedge clk) begin
    if (reset) begin
        register <= 12'b0;
    end else if (load) begin
        register <= bus;
    end else if (jump) begin
        register <= register + 2;
    end else if (inc) begin
        register <= register + 1;
    end
end

assign out = {4'b0000, register};

endmodule