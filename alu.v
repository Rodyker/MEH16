module alu(
    input clk,
    input[15:0] a,
    input[15:0] b,
    input[2:0] alu_op,
    input flag_c_in,
    output[15:0] out,
    output flag_c_out
);

localparam ALU_ADD = 0;
localparam ALU_ADDC = 1;
localparam ALU_SUB = 2;
localparam ALU_SUBB = 3;
localparam ALU_MOD = 4;
localparam ALU_AND = 5;
localparam ALU_OR = 6;
localparam ALU_XOR = 7;

reg flag_c_out;
reg[15:0] out;
always @(posedge clk) begin
    flag_c_out = flag_c_in;
    case (alu_op)
        ALU_ADD: begin
            {flag_c_out, out} = a + b;
        end
        ALU_ADDC: begin
            {flag_c_out, out} = a + b + flag_c_in;
        end
        ALU_SUB: begin
            {flag_c_out, out} = a - b;
        end
        ALU_SUBB: begin
            {flag_c_out, out} = a - b - flag_c_in;
        end
        ALU_MOD: begin
            out = a % b;
        end
        ALU_AND: begin
            out = a & b;
        end
        ALU_OR: begin
            out = a | b;
        end
        ALU_XOR: begin
            out = a ^ b;
        end
		default: begin
			out = 0;
		end
    endcase
end

endmodule