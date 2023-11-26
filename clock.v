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
    clk_out <= counter[0];//change number to change clock speed
  end
end

endmodule