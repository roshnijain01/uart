module uart_tx#(
    parameter BAUD_RATE = 9600,
    parameter CLOCK_FREQUENCY = 100_000_000 //100 MHz
)(
    input i_clk,
    input i_rstn,   //Active low reset
    input i_tx_dv,  //HIGH after the entire data byte is being sent completely from receiver side
    input [7:0] i_tx_byte,
    output reg o_tx_active, //When HIGH, indicates that this UART transmitter module is sending out bits serially
    output reg o_tx_done,   //HIGH only after the entire data byte is sent out serially
    output reg o_tx_serial
);

localparam CLKS_PER_BIT = CLOCK_FREQUENCY / BAUD_RATE;
localparam IDLE = 2'b00,
           START_BIT = 2'b01,
           DATA_BYTE = 2'b10,
           STOP_BIT = 2'b11;

reg [1:0] state = 0;
reg [$clog2(CLKS_PER_BIT)-1 : 0] clk_cnt = 0;
reg [2:0] bit_index = 0;
reg [7:0] r_tx_byte;    //Stores the incoming data byte

always@(posedge i_clk)begin
    if(~i_rstn)begin
        state <= IDLE;
        clk_cnt <= 1'b0;
        bit_index <= 1'b0;
        o_tx_active <= 1'b0;
        o_tx_done <= 1'b0;
        o_tx_serial <= 1'b1;
        r_tx_byte <= 0;
    end
    else begin
        case(state)
            IDLE: begin
                o_tx_done <= 1'b0;
                o_tx_serial <= 1'b1;
                clk_cnt <= 0;
                bit_index <= 0;
                if(i_tx_dv == 1'b1)begin
                    state <= START_BIT;
                    r_tx_byte <= i_tx_byte;
                    o_tx_active <= 1'b1;
                end
                else begin
                    state <= IDLE;
                    o_tx_active <= 1'b0;
                    r_tx_byte <= 0;
                end
            end

            START_BIT: begin
                o_tx_serial <= 1'b0;
                if(clk_cnt == CLKS_PER_BIT-1)begin
                    state <= DATA_BYTE;
                    clk_cnt <= 0;
                end
                else begin
                    clk_cnt <= clk_cnt + 1;
                    state <= START_BIT;
                end
            end

            DATA_BYTE: begin
                o_tx_serial <= r_tx_byte[bit_index];
                if(clk_cnt == CLKS_PER_BIT-1)begin
                    clk_cnt <= 0;
                    if(bit_index < 7)begin
                        bit_index <= bit_index + 1;
                        state <= DATA_BYTE;
                    end
                    else begin
                        bit_index <= 0;
                        state <= STOP_BIT;
                    end
                end
                else begin
                    clk_cnt <= clk_cnt + 1;
                    state <= DATA_BYTE;
                end
            end

            STOP_BIT: begin
                o_tx_serial <= 1'b1;
                if(clk_cnt == CLKS_PER_BIT-1)begin
                    o_tx_done <= 1'b1;
                    o_tx_active <= 1'b0;
                    clk_cnt <= 0;
                    state <= IDLE;
                end
                else begin
                    state <= STOP_BIT;
                    clk_cnt <= clk_cnt + 1;
                end
            end

            default: state <= IDLE;
        endcase
    end
end
endmodule