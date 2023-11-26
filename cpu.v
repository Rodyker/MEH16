//used for loading onto FPGA

module top(
    input CLK,
    output LED1,
    output LED2,
    output LED3,
    output LED4,
    output LED5,
    output LED6,
    output LED7,
    output LED8,
    output LED9,
    output LED10,
    input IN1,
    input IN2,
    input IN3,
    input IN4,
    input IN5,
    input IN6,
    input IN7,
    input IN8,
    input IN9,
    input IN10
);
assign {LED10, LED8, LED6, LED4, LED2, LED9, LED7, LED5, LED3, LED1} = out_out[9:0];

assign in[9:0] = ~{IN10, IN8, IN6, IN4, IN2, IN9, IN7, IN5, IN3, IN1};

wire clk;
clock clock(
    .clk_in(CLK),
    .clk_out(clk)
);

//used for testbench
/*
module cpu(input CLK, input[15:0] IN);
assign clk = CLK;
assign in = IN;
*/

wire[15:0] in;


reg[15:0] bus;
always @(*) begin
    if (a_en) begin
        bus = a_out;
    end else if (ram_en) begin
        bus = ram_out;
    end else if (mar_en) begin
        bus = {4'b0, mar_out};
    end else if (ir_en) begin
        bus = ir_out;
    end else begin
        bus = 16'b0;
    end
end



wire ram_en;
wire ram_load;
wire stack_load;
wire mar_stack;
wire[15:0] ram_out;
ram ram(
    .clk(clk),
    .ram_en(ram_en),
    .ram_load(ram_load),
    .stack_load(stack_load),
    .mar_stack(mar_stack),
    .mar(mar_out),
    .bus(bus),
    .out(ram_out)
);

wire mar_load;
wire pc_mar_load;
wire mar_en;
wire mar_inc;
wire mar_a_load;
wire[11:0] mar_out;
mar mar(
    .clk(clk),
    .load(mar_load),
    .pc_mar_load(pc_mar_load),
    .mar_a_load(mar_a_load),
    .mar_inc(mar_inc),
    .jump(jump),
    .ir_arg(ir_out[9:0]),
    .sp_out(sp_out),
    .a_out(a_out[11:0]),
    .pc(pc_out[11:0]),
    .bus(bus[11:0]),
    .out(mar_out),
    .reset(reset)
);

wire reset;
controller controller(
    .clk(clk),
    .ir_out(ir_out),
    .ram_out(ram_out),
    //.ir_opcode(ir_out[15:12]),
    //.ram_opcode(ram_out[15:12]),
    //.ram_arg(ram_out[11:0]),
    //.stack_opcode(ir_out[11:10]),
    .flags(flags),
    .a_out(a_out),
    .in(in),
    .a_op(a_op),
    .reset(reset),
    .out({
        out_clr_all,
        jump,
        mar_a_load,
        out_mwo,
        out_clear,
        out_set,
        mar_inc,
        pc_mar_load,
        stack_load,
        mar_stack,
        sp_add,
        ram_en,
        mar_load,
        ram_load,
        a_en,
        a_load,
        mar_en,
        pc_load,
        pc_inc,
        ir_en,
        ir_load
    })
);

wire[4:0] a_op;
wire a_en;
wire a_load;
wire[15:0] a_out;
wire[2:0] flags;
a reg_a(
    .clk(clk),
    .load(a_load),
    .a_op(a_op),
    .bus(bus),
    .in(in),
    .out(a_out),
    .flags(flags),
    .reset(reset)
);

wire ir_en;
wire ir_load;
wire[15:0] ir_out;
ir ir(
    .clk(clk),
    .load(ir_load),
    .bus(bus),
    .out(ir_out),
    .reset(reset)
);

wire jump;
wire pc_load;
wire pc_inc;
wire[15:0] pc_out;
pc pc(
    .clk(clk),
    .load(pc_load),
    .inc(pc_inc),
    .jump(jump),
    .bus(bus[11:0]),
    .out(pc_out),
    .reset(reset)
);

wire sp_add;
wire[15:0] sp_out;
sp sp(
    .clk(clk),
    .stack_load(stack_load),
    .sp_add(sp_add),
    .ram_arg(ram_out[9:0]),
    .out(sp_out),
    .ir_reset(ir_out[3:0] == 4'b1111)
);

wire out_set;
wire out_clear;
wire out_clr_all;
wire out_mwo;
wire[15:0] out_out;
out out(
    .clk(clk),
    .bus(bus),
    .a_out(a_out),
    .out_set(out_set),
    .out_clear(out_clear),
    .out_clr_all(out_clr_all),
    .out_mwo(out_mwo),
    .out(out_out),
    .reset(reset)
);

endmodule

module clock(
    input clk_in,
    output clk_out
);

reg [5:0] delay;
reg [20:0] register;
reg clk_out;

always @(posedge clk_in) begin
  if (delay < 63) begin
    delay <= delay + 1;
  end else begin
    clk_out <= register[0];
    register <= register + 1;
  end
end

endmodule

module ram(
	input clk,
	input ram_en,
	input ram_load,
    input stack_load,
    input mar_stack,
    input[11:0] mar,
    input[15:0] sp_out,
	input[15:0] bus,
	output[15:0] out
);

/*

0001MMMMMMMMMMMM	LDW
0010MMMMMMMMMMMM	STW
0011MMMMMMMMMMMM	ADD
0100MMMMMMMMMMMM	ADC
0101MMMMMMMMMMMM	SUB
0110MMMMMMMMMMMM	SBB
0111MMMMMMMMMMMM	MOD
1000MMMMMMMMMMMM	AND
1001MMMMMMMMMMMM	OR
1010MMMMMMMMMMMM	XOR
1011MMMMMMMMMMMM	JMP
1100MMMMMMMMMMMM	JPZ
1101MMMMMMMMMMMM	JPC
1110MMMMMMMMMMMM	JPS
1111MMMMMMMMMMMM	CAL
	
ZZZZ01SSSSSSSSSS	MSW
ZZZZ10SSSSSSSSSS	POP
ZZZZ11SSSSSSSSSS	RET
	
ZZZZZZ___001BBBB	BWS
ZZZZZZ___010BBBB	BWC
ZZZZZZ___011BBBB	BWJ
ZZZZZZ___100BBBB	BOS
ZZZZZZ___101BBBB	BOC
ZZZZZZ___110BBBB	BIJ
ZZZZZZ___111BBBB	BSL
	
ZZZZZZZZZZZZ0000	NOP
ZZZZZZZZZZZZ0001	INC
ZZZZZZZZZZZZ0010	DEC
ZZZZZZZZZZZZ0011	RTL
ZZZZZZZZZZZZ0100	RTR
ZZZZZZZZZZZZ0101	NOT
ZZZZZZZZZZZZ0110	COM
ZZZZZZZZZZZZ0111	LDP
ZZZZZZZZZZZZ1000	STP
ZZZZZZZZZZZZ1001	MWO
ZZZZZZZZZZZZ1010	MIW
ZZZZZZZZZZZZ1011	CLW
ZZZZZZZZZZZZ1100	CLO
ZZZZZZZZZZZZ1101	
ZZZZZZZZZZZZ1110	PSH
ZZZZZZZZZZZZ1111	RST

Z: unused opcode space
M: memory adress
S: distance above SP
B: bit in register

*/

reg[15:0] ram[0:12'b111111111111];

integer i;
initial begin
	$readmemb("program.bin", ram);
end

reg[15:0] out;
always @(posedge clk) begin
    if (ram_en) begin
		out <= ram[mar];
	end if (ram_load) begin
		ram[mar] <= bus;
    end if (stack_load) begin
        ram[sp_out] <= bus;
    end
end

endmodule

module mar(
    input clk,
    input load,
    input mar_inc,
    input jump,
    input pc_mar_load,
    input mar_a_load,
    input mar_stack,
    input[15:0] sp_out,
    input[9:0] ir_arg,
    input[11:0] a_out,
    input[11:0] pc,
    input[11:0] bus,
    output[11:0] out,
    input reset
);

reg[11:0] register;

initial begin
    register = 12'b0;
end

always @(negedge clk) begin
    if (reset) begin
        register = 12'b0;
    end else if (mar_stack) begin
        register <= sp_out + ir_arg + 1;
    end else if (load) begin
        register <= bus;
    end else if (jump) begin
        register <= register + 2;
    end else if (pc_mar_load) begin
        register <= pc;
    end else if (mar_inc) begin
        register <= register + 1;
    end else if (mar_a_load) begin
        register <= a_out;
    end
end

assign out = register;

endmodule

module controller(
    input clk,
    input[15:0] a_out,
    input[15:0] in,
    input[15:0] ir_out,
    input[15:0] ram_out,
    input[2:0] flags,
    output[4:0] a_op,
    output[20:0] out,
    output reset
);

//opcodes
localparam OP_NOARG = 4'b0000;
localparam OP_LDW   = 4'b0001;
localparam OP_STW   = 4'b0010;
localparam OP_ADD   = 4'b0011;
localparam OP_ADC   = 4'b0100;
localparam OP_SUB   = 4'b0101;
localparam OP_SBB   = 4'b0110;
localparam OP_MOD   = 4'b0111;
localparam OP_AND   = 4'b1000;
localparam OP_OR    = 4'b1001;
localparam OP_XOR   = 4'b1010;
localparam OP_JMP   = 4'b1011;
localparam OP_JPZ   = 4'b1100;
localparam OP_JPC   = 4'b1101;
localparam OP_JPS   = 4'b1110;
localparam OP_CAL   = 4'b1111;

localparam OP_NOST  = 2'b00;
localparam OP_MSW   = 2'b01;
localparam OP_POP   = 2'b10;
localparam OP_RET   = 2'b11;

localparam OP_NOBIT = 3'b000;
localparam OP_BWS   = 3'b001;
localparam OP_BWC   = 3'b010;
localparam OP_BWJ   = 3'b011;
localparam OP_BOS   = 3'b100;
localparam OP_BOC   = 3'b101;
localparam OP_BIJ   = 3'b110;
localparam OP_BSL   = 3'b111;

localparam OP_NOP   = 4'b0000;
localparam OP_INC   = 4'b0001;
localparam OP_DEC   = 4'b0010;
localparam OP_RTL   = 4'b0011;
localparam OP_RTR   = 4'b0100;
localparam OP_NOT   = 4'b0101;
localparam OP_COM   = 4'b0110;
localparam OP_LDP   = 4'b0111;
localparam OP_STP   = 4'b1000;
localparam OP_MWO   = 4'b1001;
localparam OP_MIW   = 4'b1010;
localparam OP_CLW   = 4'b1011;
localparam OP_CLO   = 4'b1100;
localparam OP_IDK   = 4'b1101;
localparam OP_PSH   = 4'b1110;
localparam OP_RST   = 4'b1111;

//signals
localparam SIG_OUT_CLR_ALL  = 20;
localparam SIG_JUMP         = 19;
localparam SIG_MAR_A_LOAD   = 18;
localparam SIG_OUT_MWO      = 17;
localparam SIG_OUT_CLEAR    = 16;
localparam SIG_OUT_SET      = 15;
localparam SIG_MAR_INC      = 14;
localparam SIG_PC_MAR_LOAD  = 13;
localparam SIG_STACK_LOAD   = 12;
localparam SIG_MAR_STACK    = 11;
localparam SIG_SP_ADD       = 10;
localparam SIG_RAM_EN       = 9;
localparam SIG_MAR_LOAD     = 8;
localparam SIG_RAM_LOAD     = 7;
localparam SIG_A_EN         = 6;
localparam SIG_A_LOAD       = 5;
localparam SIG_MAR_EN       = 4;
localparam SIG_PC_LOAD      = 3;
localparam SIG_PC_INC       = 2;
localparam SIG_IR_EN        = 1;
localparam SIG_IR_LOAD      = 0;

//a ops
localparam A_INC = 1;
localparam A_DEC = 2;
localparam A_RTL = 3;
localparam A_RTR = 4;
localparam A_NOT = 5;
localparam A_COM = 6;
localparam A_ADD = 7;
localparam A_ADC = 8;
localparam A_SUB = 9;
localparam A_SBB = 10;
localparam A_MOD = 11;
localparam A_AND = 12;
localparam A_OR = 13;
localparam A_XOR = 14;
localparam A_SET = 15;
localparam A_CLR = 16;
localparam A_BSL = 17;
localparam A_CLW = 18;
localparam A_IN_LOAD = 19;

//flags
localparam FLAG_Z = 0;
localparam FLAG_C = 1;
localparam FLAG_S = 2;


reg stage;
reg[20:0] ctrl_word;
reg[4:0] a_op;
reg stage_rst;
reg reset;

wire[3:0] ram_type_ram;
wire[1:0] ram_type_stack;
wire[2:0] ram_type_bit;
wire[3:0] ram_type_noarg;
wire[3:0] ir_type_ram;
wire[1:0] ir_type_stack;
wire[3:0] ir_type_noarg;

assign ram_type_ram = ram_out[15:12];
assign ram_type_stack = ram_out[11:10];
assign ram_type_bit = ram_out[6:4];
assign ram_type_noarg = ram_out[3:0];
assign ir_type_ram = ir_out[15:12];
assign ir_type_stack = ir_out[11:10];
assign ir_type_noarg = ir_out[3:0];

initial begin
    stage = 0;
end

always @(negedge clk) begin
    if (stage_rst) begin
        stage <= 0;
    end else begin
        stage <= stage + 1;
    end
end

always @(*) begin
    ctrl_word = 0;
    a_op = 0;
    stage_rst = 0;
    reset = 0;
    case (stage)
        0: begin
            ctrl_word[SIG_RAM_EN] = 1;
            ctrl_word[SIG_IR_LOAD] = 1;
            ctrl_word[SIG_PC_INC] = 1;
            ctrl_word[SIG_MAR_INC] = 1;
            case (ram_type_ram)
                OP_JMP: begin
                    ctrl_word[SIG_PC_LOAD] = 1;
                    ctrl_word[SIG_MAR_LOAD] = 1;
                    stage_rst = 1;
                end
                OP_JPZ: begin
                    if (flags[FLAG_Z]) begin
                        ctrl_word[SIG_PC_LOAD] = 1;
                        ctrl_word[SIG_MAR_LOAD] = 1;
                    end
                    stage_rst = 1;
                end
                OP_JPC: begin
                    if (flags[FLAG_C]) begin
                        ctrl_word[SIG_PC_LOAD] = 1;
                        ctrl_word[SIG_MAR_LOAD] = 1;
                    end
                    stage_rst = 1;
                end
                OP_JPS: begin
                    if (flags[FLAG_S]) begin
                        ctrl_word[SIG_PC_LOAD] = 1;
                        ctrl_word[SIG_MAR_LOAD] = 1;
                    end
                    stage_rst = 1;
                end
                OP_CAL: begin
                    ctrl_word[SIG_PC_LOAD] = 1;
                end
                OP_NOARG: begin
                    if (ram_type_stack == OP_NOST) begin
                        case (ram_type_bit)
                            OP_BWS: begin
                                a_op = A_SET;
                                stage_rst = 1;
                            end
                            OP_BWC: begin
                                a_op = A_CLR;  
                                stage_rst = 1;
                            end
                            OP_BWJ: begin
                                if (a_out[ram_type_noarg]) begin
                                    ctrl_word[SIG_JUMP] = 1;
                                end
                                stage_rst = 1;
                            end
                            OP_BOS: begin
                                ctrl_word[SIG_OUT_SET] = 1;
                                stage_rst = 1;
                            end
                            OP_BOC: begin
                                ctrl_word[SIG_OUT_CLEAR] = 1;
                                stage_rst = 1;
                            end
                            OP_BIJ: begin
                                if (in[ram_type_noarg]) begin
                                    ctrl_word[SIG_JUMP] = 1;
                                end
                                stage_rst = 1;
                            end
                            OP_BSL: begin
                                a_op = A_BSL;
                                stage_rst = 1;
                            end
                            default: begin
                                case (ram_type_noarg)
                                    OP_NOP: begin
                                        stage_rst = 1;
                                    end
                                    OP_INC: begin
                                        a_op = A_INC;
                                        stage_rst = 1;
                                    end
                                    OP_DEC: begin
                                        a_op = A_DEC;
                                        stage_rst = 1;
                                    end
                                    OP_RTL: begin
                                        a_op = A_RTL;
                                        stage_rst = 1;
                                    end
                                    OP_RTR: begin
                                        a_op = A_RTR;
                                        stage_rst = 1;
                                    end
                                    OP_NOT: begin
                                        a_op = A_NOT;
                                        stage_rst = 1;
                                    end
                                    OP_COM: begin
                                        a_op = A_COM;
                                        stage_rst = 1;
                                    end
                                    OP_LDP: begin
                                        ctrl_word[SIG_MAR_A_LOAD] = 1;
                                    end
                                    OP_STP: begin
                                        ctrl_word[SIG_MAR_A_LOAD] = 1;
                                    end
                                    OP_MWO: begin
                                        ctrl_word[SIG_OUT_MWO] = 1;
                                        stage_rst = 1;
                                    end
                                    OP_MIW: begin
                                        a_op = A_IN_LOAD;
                                        stage_rst = 1;
                                    end
                                    OP_CLW: begin
                                        a_op = A_CLW;
                                        stage_rst = 1;
                                    end
                                    OP_CLO: begin
                                        ctrl_word[SIG_OUT_CLR_ALL] = 1;
                                        stage_rst = 1;
                                    end
                                    OP_PSH: begin
                                        ctrl_word[SIG_MAR_LOAD] = 1;
                                    end
                                    OP_RST: begin
                                        reset = 1;
                                    end
                                endcase
                            end
                        endcase

                    end else begin
                        ctrl_word[SIG_MAR_STACK] = 1;
                    end
                end
                default: begin
                    ctrl_word[SIG_MAR_LOAD] = 1;
                end      
            endcase
        end
        1: begin
            stage_rst = 1;
            ctrl_word[SIG_PC_MAR_LOAD] = 1;
            case (ir_type_ram)
                OP_LDW: begin
                    ctrl_word[SIG_RAM_EN] = 1;
                    ctrl_word[SIG_A_LOAD] = 1;
                end
                OP_STW: begin
                    ctrl_word[SIG_A_EN] = 1;
                    ctrl_word[SIG_RAM_LOAD] = 1;
                end
                OP_ADD: begin
                    a_op = A_ADD;
                    ctrl_word[SIG_RAM_EN] = 1;
                end
                OP_ADC: begin
                    a_op = A_ADC;
                    ctrl_word[SIG_RAM_EN] = 1;
                end
                OP_SUB: begin
                    a_op = A_SUB;
                    ctrl_word[SIG_RAM_EN] = 1;
                end
                OP_SBB: begin
                    a_op = A_SBB;
                    ctrl_word[SIG_RAM_EN] = 1;
                end
//                OP_MOD: begin
//                    a_op = A_MOD;
//                    ctrl_word[SIG_RAM_EN] = 1;
//                end
                OP_AND: begin
                    a_op = A_AND;
                    ctrl_word[SIG_RAM_EN] = 1;
                end
                OP_OR: begin
                    a_op = A_OR;
                    ctrl_word[SIG_RAM_EN] = 1;
                end
                OP_XOR: begin
                    a_op = A_XOR;
                    ctrl_word[SIG_RAM_EN] = 1;
                end
                OP_CAL: begin
                    ctrl_word[SIG_MAR_EN] = 1;
                    ctrl_word[SIG_STACK_LOAD] = 1;
                    ctrl_word[SIG_PC_MAR_LOAD] = 1;
                end
                OP_NOARG: begin
                    case (ir_type_stack)
                        OP_MSW: begin
                            ctrl_word[SIG_RAM_EN] = 1;
                            ctrl_word[SIG_A_LOAD] = 1;
                        end
                        OP_POP: begin
                            ctrl_word[SIG_RAM_EN] = 1;
                            ctrl_word[SIG_A_LOAD] = 1;
                            ctrl_word[SIG_SP_ADD] = 1;
                        end
                        OP_RET: begin
                            ctrl_word[SIG_RAM_EN] = 1;
                            ctrl_word[SIG_PC_LOAD] = 1;
                            ctrl_word[SIG_MAR_LOAD] = 1;
                            ctrl_word[SIG_SP_ADD] = 1;
                        end
                        OP_NOST: begin
                            case (ir_type_noarg)
                                OP_LDP: begin
                                    ctrl_word[SIG_RAM_EN] = 1;
                                    ctrl_word[SIG_A_LOAD] = 1;
                                end
                                OP_STP: begin
                                    ctrl_word[SIG_A_EN] = 1;
                                    ctrl_word[SIG_RAM_LOAD] = 1;
                                end
                                OP_PSH: begin
                                    ctrl_word[SIG_A_EN] = 1;
                                    ctrl_word[SIG_STACK_LOAD] = 1;
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
    endcase
end

assign out = ctrl_word;

endmodule

module a(
    input clk,
    input load,
    input[4:0] a_op,
    input[15:0] bus,
    input[15:0] in,
    output[15:0] out,
    output[2:0] flags,
    input reset
);

//a ops
localparam A_INC = 1;
localparam A_DEC = 2;
localparam A_RTL = 3;
localparam A_RTR = 4;
localparam A_NOT = 5;
localparam A_COM = 6;
localparam A_ADD = 7;
localparam A_ADC = 8;
localparam A_SUB = 9;
localparam A_SBB = 10;
localparam A_MOD = 11;
localparam A_AND = 12;
localparam A_OR = 13;
localparam A_XOR = 14;
localparam A_SET = 15;
localparam A_CLR = 16;
localparam A_BSL = 17;
localparam A_CLW = 18;
localparam A_IN_LOAD = 19;

//flags
localparam FLAG_Z = 0;
localparam FLAG_C = 1;
localparam FLAG_S = 2;

reg[15:0] a;
reg[2:0] flags;

initial begin
    a = 16'b0;
    flags = 3'b0;
end
always @(negedge clk) begin
    if (reset) begin
        a = 16'b0;
        flags = 3'b0;
    end else if (load) begin
        a <= bus;
    end else begin
        case (a_op)
            A_INC: begin
                {flags[FLAG_C], a} = a + 1;
            end
            A_DEC: begin
                flags[FLAG_C] = (a < 1);
                a = a - 1;
            end
            A_RTL: begin
                flags[FLAG_C] = a[15];
                a = a << 1;
            end
            A_RTR: begin
                flags[FLAG_C] = a[0];
                a = a >> 1;
            end
            A_NOT: begin
                a = ~a;
            end
            A_COM: begin
                a = ~a + 1;
            end 
            A_ADD: begin
                {flags[FLAG_C], a} = a + bus;
            end
            A_ADC: begin
                {flags[FLAG_C], a} = a + bus + flags[FLAG_C];
            end
            A_SUB: begin
                flags[FLAG_C] = (a < bus);
                a = a - bus;
            end
            A_SBB: begin
                flags[FLAG_C] = (a < (bus + flags[FLAG_C]));
                a = a - bus - flags[FLAG_C];
            end
//            A_MOD: begin
//                a = a % bus;
//            end
            A_AND: begin
                a = a & bus;
            end
            A_OR: begin
                a = a | bus;
            end
            A_XOR: begin
                a = a ^ bus;
            end
            A_SET: begin
                a[bus[3:0]] = 1;
            end
            A_CLR: begin
                a[bus[3:0]] = 0;
            end
            A_BSL: begin
                {flags[FLAG_C], a} = a << bus[3:0];//TODO: modify carry flag to detect overflow when the lowest lost bit is 0
            end
            A_CLW: begin
                a = 16'b0;
            end
            A_IN_LOAD: begin
                a = in;
            end
        endcase
    end
    flags[FLAG_Z] = (a == 0);
    flags[FLAG_S] = a[15];
end

assign out = a;

endmodule

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

module out(
    input clk,
    input out_set,
    input out_clear,
    input out_clr_all,
    input out_mwo,
    input[15:0] a_out,
    input[15:0] bus,
    output[15:0] out,
    input reset
);

reg[15:0] out_reg;

initial begin
    out_reg = 16'b0;
end

always @(negedge clk) begin
    if (reset) begin
        out_reg = 16'b0;
    end else if (out_set) begin
        out_reg[bus[3:0]] = 1;
    end else if (out_clear) begin
        out_reg[bus[3:0]] = 0;
    end else if (out_mwo) begin
        out_reg = a_out;
    end else if (out_clr_all) begin
        out_reg = 16'b0;
    end
end

assign out = out_reg;

endmodule