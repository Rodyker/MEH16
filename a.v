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