`timescale 1ns/1ps
//This testbench module sends predefined bytes and checks serial output.
module tb_uart_tx;

parameter CLOCK_FREQ     = 100_000_000;   // 100 MHz
parameter BAUD_RATE      = 9500;
parameter CLKS_PER_BIT   = CLOCK_FREQ / BAUD_RATE;
parameter BIT_PERIOD_NS  = 1_000_000_000 / BAUD_RATE; // ~105263 ns

reg clk;
reg rst_n;
reg tx_dv;
reg [7:0] tx_byte;
wire tx_active;
wire tx_serial;
wire tx_done;

uart_tx#(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQUENCY(CLOCK_FREQ)
)dut(
    .i_clk(clk),
    .i_rstn(1'b1),   //Active low reset
    .i_tx_dv(tx_dv),
    .i_tx_byte(tx_byte),
    .o_tx_active(tx_active),
    .o_tx_done(tx_done),
    .o_tx_serial(tx_serial)
);

always #5 clk = ~clk;

initial begin
  $dumpfile("tx.vcd");
  $dumpvars;
  clk     = 0;
  rst_n   = 0;
  tx_dv   = 0;
  tx_byte = 8'h00;
  #100;
  rst_n = 1;
  #2000;
  tx_byte = 8'b 10101011;
  tx_dv = 1;
  #10;
  tx_dv = 0; // pulse only one cycle
  #2000000;
  $finish;
end

endmodule
