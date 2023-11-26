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