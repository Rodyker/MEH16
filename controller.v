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