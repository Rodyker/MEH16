module top(
    input CLK,
    output RED1,
    output RED2,
    output RED3,
    output RED4,
    output GREEN
);

assign {RED1, RED2, RED3, RED4, GREEN} = b_out[4:0];

reg[15:0] bus;
always @(*) begin
    if (a_en) begin
        bus = a_out;
    end else if (b_en) begin
        bus = b_out;
    end else if (alu_en) begin
        bus = alu_out;
    end else if (ram_en) begin
        bus = ram_out;
    end else if (pc_en) begin
        bus = pc_out;
    end else if (ir_en) begin
        bus = ir_out;
    end else begin
        bus = 16'b0;
    end
end

wire clk;
clock clock(
    .clk_in(CLK),
    .clk_out(clk)
);

localparam FLAG_C = 1;
wire[2:0] alu_op;
wire alu_en;
wire[15:0] alu_out;
wire alu_c_flag;
alu alu(
    .clk(clk),
    .a(a_out),
    .b(b_out),
    .alu_op(alu_op),
    .out(alu_out),
    .flag_c_in(flags[FLAG_C]),
    .flag_c_out(alu_c_flag)
);

wire[2:0] flags;
flags flags(
    .clk(clk),
    .a_out(a_out),
    .alu_op(alu_op != 0),
    .a_load(a_load),
    .a_op(a_op != 0),
    .alu_c_flag(alu_c_flag),
    .a_c_flag(a_c_flag),
    .out(flags)
);

wire ram_en;
wire mar_load;
wire ram_load;
wire[15:0] ram_out;
ram ram(
    .clk(clk),
    .ram_en(ram_en),
    .mar_load(mar_load),
    .ram_load(ram_load),
    .bus(bus),
    .out(ram_out)
);

controller controller(
    .clk(clk),
    .ir_opcode(ir_out[15:12]),
    .ram_opcode(ram_out[15:12]),
    .ram_arg(ram_out[11:0]),
    .flags(flags),
    .alu_op(alu_op),
    .a_op(a_op),
    .out({
        alu_en,
        ram_en,
        mar_load,
        ram_load,
        a_en,
        a_load,
        b_en,
        b_load,
        pc_en,
        pc_load,
        pc_inc,
        ir_en,
        ir_load
    })
);

wire[2:0] a_op;
wire a_en;
wire a_load;
wire[15:0] a_out;
wire a_c_flag;
a reg_a(
    .clk(clk),
    .load(a_load),
    .a_op(a_op),
    .bus(bus),
    .out(a_out),
    .flag_c_in(flags[FLAG_C]),
    .flag_c_out(a_c_flag)
);

wire b_en;
wire b_load;
wire[15:0] b_out;
register reg_b(
    .clk(clk),
    .load(b_load),
    .bus(bus),
    .out(b_out)
);

wire ir_en;
wire ir_load;
wire[15:0] ir_out;
register ir(
    .clk(clk),
    .load(ir_load),
    .bus(bus),
    .out(ir_out)
);

wire pc_en;
wire pc_load;
wire pc_inc;
wire[15:0] pc_out;
pc pc(
    .clk(clk),
    .load(pc_load),
    .inc(pc_inc),
    .bus(bus[11:0]),
    .out(pc_out)
);

endmodule

module clock(
    input clk_in,
    output clk_out
);

reg [22:0] counter;
reg [5:0] delay;
reg clk_out;

always @(posedge clk_in) begin
  if (delay < 63) begin
    delay <= delay + 1;
  end else begin
    counter <= counter + 1;
    clk_out <= counter[18];//change number to change clock speed
  end
end

endmodule

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

module controller(
    input clk,
    input[3:0] ir_opcode,
    input[3:0] ram_opcode,
    input[11:0] ram_arg,
    input[2:0] flags,
    output[2:0] alu_op,
    output[2:0] a_op,
    output[12:0] out
);

//opcodes
localparam OP_NOARG = 4'b0000;
localparam OP_LOADA = 4'b0001;
localparam OP_LOADB = 4'b0010;
localparam OP_STORE = 4'b0011;
localparam OP_ADD = 4'b0100;
localparam OP_ADDC = 4'b0101;
localparam OP_SUB = 4'b0110;
localparam OP_SUBB = 4'b0111;
localparam OP_MOD = 4'b1000;
localparam OP_AND = 4'b1001;
localparam OP_OR = 4'b1010;
localparam OP_XOR = 4'b1011;
localparam OP_JMP = 4'b1100;
localparam OP_JMPZ = 4'b1101;
localparam OP_JMPC = 4'b1110;
localparam OP_JMPS = 4'b1111;

localparam OP_NOOP = 12'b000000000000;
localparam OP_INC = 12'b000000000001;
localparam OP_DEC = 12'b000000000010;
localparam OP_SHL = 12'b000000000011;
localparam OP_SHR = 12'b000000000100;
localparam OP_NOT = 12'b000000000101;
localparam OP_COM = 12'b000000000110;
localparam OP_MOVBA = 12'b000000000111;

//signals
localparam SIG_ALU_EN =     12;
localparam SIG_RAM_EN =     11;
localparam SIG_MAR_LOAD =   10;
localparam SIG_RAM_LOAD =   9;
localparam SIG_A_EN =       8;
localparam SIG_A_LOAD =     7;
localparam SIG_B_EN =       6;
localparam SIG_B_LOAD =     5;
localparam SIG_PC_EN =      4;
localparam SIG_PC_LOAD =    3;
localparam SIG_PC_INC =     2;
localparam SIG_IR_EN =      1;
localparam SIG_IR_LOAD =    0;

//alu ops
localparam ALU_ADD = 0;
localparam ALU_ADDC = 1;
localparam ALU_SUB = 2;
localparam ALU_SUBB = 3;
localparam ALU_MOD = 4;
localparam ALU_AND = 5;
localparam ALU_OR = 6;
localparam ALU_XOR = 7;

//a ops
localparam A_INC = 1;
localparam A_DEC = 2;
localparam A_SHL = 3;
localparam A_SHR = 4;
localparam A_NOT = 5;
localparam A_COM = 6;

//flags
localparam FLAG_Z = 0;
localparam FLAG_C = 1;
localparam FLAG_S = 2;


reg[2:0] stage;
reg[12:0] ctrl_word;
reg[2:0] alu_op;
reg[2:0] a_op;
reg stage_rst;
wire[3:0] ir_opcode;
wire[3:0] ram_opcode;
wire[11:0] ram_arg;

always @(negedge clk) begin
    if (stage_rst) begin
        stage <= 0;
    end else begin
        stage <= stage + 1;
    end
end

initial begin
    stage <= 0;
end

always @(*) begin
    ctrl_word = 0;
    alu_op = 0;
    a_op = 0;
    stage_rst = 0;
    case (stage)
        0: begin
            ctrl_word[SIG_PC_EN] = 1;
            ctrl_word[SIG_MAR_LOAD] = 1;
        end
        1: begin
            ctrl_word[SIG_RAM_EN] = 1;
            ctrl_word[SIG_IR_LOAD] = 1;
            case (ram_opcode)
                OP_NOARG: begin
                    ctrl_word[SIG_PC_INC] = 1;
                    stage_rst = 1;
                    case (ram_arg)
                        OP_INC: begin
                            a_op = A_INC;
                        end
                        OP_DEC: begin
                            a_op = A_DEC;
                        end
                        OP_SHL: begin
                            a_op = A_SHL;
                        end
                        OP_SHR: begin
                            a_op = A_SHR;
                        end
                        OP_NOT: begin
                            a_op = A_NOT;
                        end
                        OP_COM: begin
                            a_op = A_COM;
                        end
                    endcase
                end
                OP_JMP: begin
                    ctrl_word[SIG_PC_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_JMPZ: begin
                    if (flags[FLAG_Z]) begin
                        ctrl_word[SIG_PC_LOAD] = 1;
                    end else begin
                        ctrl_word[SIG_PC_INC] = 1;
                    end
                    stage_rst = 1;
                end
                OP_JMPC: begin
                    if (flags[FLAG_C]) begin
                        ctrl_word[SIG_PC_LOAD] = 1;
                    end else begin
                        ctrl_word[SIG_PC_INC] = 1;
                    end
                    stage_rst = 1;
                end
                OP_JMPS: begin
                    if (flags[FLAG_S]) begin
                        ctrl_word[SIG_PC_LOAD] = 1;
                    end else begin
                        ctrl_word[SIG_PC_INC] = 1;
                    end
                    stage_rst = 1;
                end  
                default: begin
                    ctrl_word[SIG_PC_INC] = 1;
                end      
            endcase
        end
        2: begin
            if (ir_opcode == OP_NOARG) begin
                ctrl_word[SIG_B_EN] = 1;
                ctrl_word[SIG_A_LOAD] = 1;
                stage_rst = 1;
            end else begin
                ctrl_word[SIG_IR_EN] = 1;
                ctrl_word[SIG_MAR_LOAD] = 1;
            end
        end
        3: begin
            case (ir_opcode)
                OP_LOADA: begin
                    ctrl_word[SIG_RAM_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_LOADB: begin
                    ctrl_word[SIG_RAM_EN] = 1;
                    ctrl_word[SIG_B_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_STORE: begin
                    ctrl_word[SIG_A_EN] = 1;
                    ctrl_word[SIG_RAM_LOAD] = 1;
                    stage_rst = 1;
                end
                default: begin
                    ctrl_word[SIG_RAM_EN] = 1;
                    ctrl_word[SIG_B_LOAD] = 1;
                end
            endcase
        end
        4: begin
            case (ir_opcode)
                OP_ADD: begin
                    alu_op = ALU_ADD;
                    ctrl_word[SIG_ALU_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_ADDC: begin
                    alu_op = ALU_ADDC;
                    ctrl_word[SIG_ALU_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_SUB: begin
                    alu_op = ALU_SUB;
                    ctrl_word[SIG_ALU_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_SUBB: begin
                    alu_op = ALU_SUBB;
                    ctrl_word[SIG_ALU_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_MOD: begin
                    alu_op = ALU_MOD;
                    ctrl_word[SIG_ALU_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_AND: begin
                    alu_op = ALU_AND;
                    ctrl_word[SIG_ALU_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_OR: begin
                    alu_op = ALU_OR;
                    ctrl_word[SIG_ALU_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_XOR: begin
                    alu_op = ALU_XOR;
                    ctrl_word[SIG_ALU_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                    stage_rst = 1;
                end
            endcase
        end
    endcase
end

assign out = ctrl_word;

endmodule

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

assign out = a;

endmodule

module flags(
    input clk,
    input[15:0] a_out,
    input alu_op,
    input a_load,
    input a_op,
    input alu_c_flag,
    input a_c_flag,
    output[2:0] out
);

localparam FLAG_Z = 0;
localparam FLAG_C = 1;
localparam FLAG_S = 2;

reg[2:0] flags;
reg load_from_alu;
reg load_from_a;

initial begin
    flags = 3'b001;
    load_from_a = 0;
    load_from_alu = 0;
end

always @(posedge clk) begin
    flags[FLAG_S] = a_out[15];
    flags[FLAG_Z] = (a_out == 0);

    if (alu_op) begin
        load_from_alu <= 1;
    end else if (a_op) begin
        load_from_a <= 1;
    end
    if (load_from_alu) begin
        flags[FLAG_C] <= alu_c_flag;
        load_from_alu = 0;
    end else if (load_from_a) begin
        flags[FLAG_C] <= a_c_flag;
        load_from_a = 0;
    end
end

assign out = flags;

endmodule

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