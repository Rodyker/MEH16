module cpu_tb();

reg CLK;
reg[15:0] IN;

cpu cpu(CLK, IN);

integer i;
initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0,cpu_tb);

    IN = 16'b0000000000000000;
    CLK = 0;
	for (i = 0; i < 2048; i++) begin
		#1 CLK = ~CLK;
	end

    $finish();
end

endmodule