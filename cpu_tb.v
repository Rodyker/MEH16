module cpu_tb();

reg CLK;

cpu cpu(CLK);

integer i;
initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0,cpu_tb);

    CLK = 1;
	for (i = 0; i < 2048; i++) begin
		#1 CLK = ~CLK;
	end

    $finish();
end

endmodule