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