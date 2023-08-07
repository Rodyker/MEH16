module ram(
	input clk,
	input ram_en,
	input mar_load,
	input ram_load,
	input[15:0] bus,
	output[15:0] out
);

/*
NOARG 	0000
LOADA 	0001
LOADB 	0010
STORE 	0011
ADD 	0100
ADDC 	0101
SUB 	0110
SUBB 	0111
MOD 	1000
AND 	1001
OR 		1010
XOR 	1011
JMP 	1100
JMPZ 	1101
JMPC 	1110
JMPS 	1111

NOOP 	000000000000
INC 	000000000001
DEC 	000000000010
SHL 	000000000011
SHR 	000000000100
NOT 	000000000101
COM 	000000000110
MOVBA 	000000000111
*/

reg[11:0] mar;
reg[15:0] ram[0:255];

integer i;
initial begin
    mar = 12'b0;
	for (i = 0; i < 256; i = i + 1) begin
		ram[i] = 16'b0000000000000000;
	end

    //test program with fibonacci
    ram[0]  = 16'b0001000000001101;//load mem1
	ram[1]  = 16'b0100000000001110;//add mem2
	ram[2]  = 16'b0011000000001111;//store mem3
	ram[3]  = 16'b0001000000000000;//load 0
	ram[4]  = 16'b0000000000000001;//inc
	ram[5]  = 16'b0011000000000000;//store 0
	ram[6]  = 16'b0001000000000001;//load 1
	ram[7]  = 16'b0000000000000001;//inc
	ram[8]  = 16'b0011000000000001;//store
    ram[9]  = 16'b0001000000000010;//load 2
    ram[10] = 16'b0000000000000001;//inc
    ram[11] = 16'b0011000000000010;//store 2
    ram[12] = 16'b1100000000000000;//jump 0
    ram[13] = 16'b0000000000000001;
    ram[14] = 16'b0000000000000001;

    //test for conditional jumps
/*
    ram[0] = 16'b0000000000000001;//INC
    ram[1] = 16'b0000000000000100;//SHR
    ram[2] = 16'b1110000000000100;//JMPC 4
    ram[3] = 16'b1100000000000011;//JMP 3
    ram[4] = 16'b1100000000000100;//JMP 4*/

end

reg[15:0] out;
always @(posedge clk) begin
	if (ram_en) begin
		out <= ram[mar];
	end else if (mar_load) begin
		mar <= bus[11:0];
	end else if (ram_load) begin
		ram[mar] <= bus;
	end
end

endmodule