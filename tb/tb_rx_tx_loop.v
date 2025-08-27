`timescale 1ns/1ps
//This testbench module takes in serial data, send it to uart receiver. Then, the parallel output from uart rx goes into uart tx.
//Connects RX → TX internally and checks end-to-end communication.
module tb_rx_to_tx();
localparam CLOCK_FREQUENCY = 100_000_000;
localparam BAUD_RATE = 9600;
localparam BITS_PER_NS = 1000_000_000/BAUD_RATE; //Duration of one UART bit in nanoseconds (10^9 / baud rate)
reg r_clk;
reg r_rstn;
reg r_rx_serial;
wire w_data_valid;
wire [7:0] w_data_byte;
wire w_tx_active;
wire w_tx_done;
wire w_tx_serial;

uart_rx#(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY) //100 MHz (In Hz)
)dut_rx(
    .i_clk(r_clk),
    .i_rstn(r_rstn),   //Active low reset
    .i_rx_serial(r_rx_serial),
    .o_rx_dv(w_data_valid),//output data valid, HIGH only when the entire DATA BYTE is completely sent, i.e. in te STOP_BIT state
    .o_rx_byte(w_data_byte)
);

uart_tx#(
    .BAUD_RATE(BAUD_RATE),
    .CLOCK_FREQUENCY(CLOCK_FREQUENCY)
)dut_tx(
    .i_clk(r_clk),
    .i_rstn(r_rstn),   //Active low reset
    .i_tx_dv(w_data_valid),
    .i_tx_byte(w_data_byte),
    .o_tx_active(w_tx_active),
    .o_tx_done(w_tx_done),
    .o_tx_serial(w_tx_serial)
);

task send_serial_data;
    input [7:0] i_data;
    integer i;
begin
    //Start bit
    r_rx_serial <= 1'b0;
    #(BITS_PER_NS);

    //Data byte
    begin
        for(i = 0; i < 8; i = i + 1)begin
            r_rx_serial <= i_data[i];
            #(BITS_PER_NS);
        end
    end

    //Stop bit
    r_rx_serial <= 1'b1;
    #(BITS_PER_NS);
end
endtask

always #5 r_clk = ~r_clk;

initial begin
    $dumpfile("rx_tx.vcd");
    $dumpvars;
    r_clk <= 0;
    r_rstn <= 1;
    r_rx_serial = 1'b1;
    #1000 send_serial_data(8'b01100101);

    #1000000 $finish;
end

endmodule