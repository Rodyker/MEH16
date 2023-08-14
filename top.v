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