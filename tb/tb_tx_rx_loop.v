`timescale 1ns/1ps
//This testbench takes in parallel data, and send it to uart transmitter. Then the serial output from uart tx goes into uart rx.
//Connects TX → RX internally and checks end-to-end communication.
module tb_tx_to_rx();

localparam BAUD_RATE = 9600;
localparam CLOCK_FREQUENCY = 100_000_000;

reg r_clk = 0;
reg r_rstn = 0;
reg [7:0] r_byte = 0;
reg r_tx_dv;
wire w_dv;
wire w_tx_serial;
wire w_tx_active;
wire w_tx_done;
wire [7:0] w_rx_byte;

//uart transmitter module
uart_tx#(
    .BAUD_RATE(9600),
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY)
)dut_tx(
    .i_clk(r_clk),
    .i_rstn(r_rstn),   //Active low reset
    .i_tx_dv(r_tx_dv),
    .i_tx_byte(r_byte),
    .o_tx_active(w_tx_active),
    .o_tx_done(w_tx_done),
    .o_tx_serial(w_tx_serial)
);

//uart receiver module
uart_rx#(
    .BAUD_RATE(9600),
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY) //100 MHz (In Hz)
)dut_rx(
    .i_clk(r_clk),
    .i_rstn(r_rstn),   //Active low reset
    .i_rx_serial(w_tx_serial),
    .o_rx_dv(w_dv),//output data valid, HIGH only when the entire DATA BYTE is completely sent, i.e. in te STOP_BIT state
    .o_rx_byte(w_rx_byte)
);

task send_bytes;
    input [7:0] i_data;
    begin
        @(posedge r_clk);
        #100 r_byte <= i_data;
               r_tx_dv <= 1;
        @(posedge r_clk);
        #10 r_tx_dv <= 0;
        #10000000 $finish;
    end
endtask

always #5 r_clk = ~r_clk;   //10 ns time period -> 100 MHz clock frequency

initial begin
    $dumpfile("tx_rx.vcd");
    $dumpvars;
    r_clk <= 0;
    r_rstn <= 0;
    #10 r_rstn <= 1;
    #50 send_bytes(8'hA1);
    #1000000 $finish;
end

endmodule