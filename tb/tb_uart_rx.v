`timescale 1ns/1ps
//This testbench module provides serial bitstream and verifies received byte.
module tb_uart_rx;

parameter CLOCK_FREQ    = 100_000_000;   // 100 MHz clock
parameter BAUD_RATE     = 9600;
parameter BIT_PERIOD_NS  = 1_000_000_000 / BAUD_RATE;

reg clk;
reg rx_serial;
wire rx_dv;
wire [7:0] rx_byte;

uart_rx#(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQUENCY(CLOCK_FREQ) //100 MHz (In Hz)
)dut(
    .i_clk(clk),
    .i_rstn(1'b1),   //Active low reset
    .i_rx_serial(rx_serial),
    .o_rx_dv(rx_dv),
    .o_rx_byte(rx_byte)
);

always #5 clk = ~clk;

// Task: send one byte over the rx_serial line
task send_uart_byte;
  input [7:0] data;
  integer i;
  begin
  // Start bit
  rx_serial <= 1'b0;
  #(BIT_PERIOD_NS);
  // Data bits LSB-first
  for (i = 0; i < 8; i = i + 1) begin
    rx_serial <= data[i];
    #(BIT_PERIOD_NS);
  end
  // Stop bit
  rx_serial <= 1'b1;
  #(BIT_PERIOD_NS);
  end
endtask

initial begin
  $dumpfile("rx.vcd");
  $dumpvars;
  clk = 0;
  rx_serial = 1; // idle line high
  #1000;
  send_uart_byte(8'b11001110);

  #1000000;
  $finish;
end
endmodule