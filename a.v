module a(
    input clk,
    input load,
    input[2:0] a_op,
    input[15:0] bus,
    input flag_c_in,
    output[15:0] out,
    output flag_c_out
);

//a ops
localparam A_INC = 1;
localparam A_DEC = 2;
localparam A_SHL = 3;
localparam A_SHR = 4;
localparam A_NOT = 5;
localparam A_COM = 6;

reg[15:0] a;
assign out = a;
reg flag_c_out;

initial begin
    a = 16'b0;
end

always @(negedge clk) begin
    if (load) begin
        a <= bus;
    end else begin
        flag_c_out = flag_c_in;
        case (a_op)
            A_INC: begin
                {flag_c_out, a} = a + 1;
            end
            A_DEC: begin
                {flag_c_out, a} = a - 1;
            end
            A_SHL: begin
                flag_c_out = a[15];
                a = a << 1;
            end
            A_SHR: begin
                flag_c_out = a[0];
                a = a >> 1;
            end
            A_NOT: begin
                a = ~a;
            end
            A_COM: begin
                a = ~a + 1;
            end
        endcase
    end
end

endmodule