module uart_rx#(
    parameter BAUD_RATE = 9600,
    parameter CLOCK_FREQUENCY = 100_000_000 //100 MHz
)(
    input i_clk,
    input i_rstn,       //Active low reset
    input i_rx_serial,
    output reg o_rx_dv, //Data valid, HIGH only after sending the whole DATA BYTE
    output reg [7:0] o_rx_byte
);
localparam CLOCKS_PER_BIT = CLOCK_FREQUENCY / BAUD_RATE;
localparam IDLE = 2'b00,
           START_BIT = 2'b01,
           DATA_BYTE = 2'b10,
           STOP_BIT = 2'b11;

reg [1:0] state = 0;
reg [2:0] bit_index = 0;    //Tracking the bit index of data byte
reg [($clog2(CLOCKS_PER_BIT))-1 : 0] clk_cnt = 0;   //To keep count of number of cycles per bit

always@(posedge i_clk)begin
    if(~i_rstn)begin
        o_rx_byte <= 0;
        state <= IDLE;
        bit_index <= 0;
        clk_cnt <= 0;
    end
    else begin
        case(state)
            IDLE: begin
                clk_cnt <= 0;
                bit_index <= 0;
                o_rx_dv <= 0;
                if(i_rx_serial == 1'b0)
                    state <= START_BIT;
                else
                    state <= IDLE;
            end

            START_BIT: begin
                if(clk_cnt == CLOCKS_PER_BIT / 2) begin
                    state <= DATA_BYTE;
                    clk_cnt <= 0;
                end
                else begin
                    clk_cnt <= clk_cnt + 1;
                    state <= START_BIT;
                end
            end

            DATA_BYTE: begin
                if(clk_cnt == CLOCKS_PER_BIT-1)begin
                    clk_cnt <= 0;
                    o_rx_byte[bit_index] <= i_rx_serial;
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
                if(clk_cnt == CLOCKS_PER_BIT-1)begin
                    clk_cnt <= 0;
                    o_rx_dv <= 1'b1;
                    state <= IDLE;
                end
                else begin
                    clk_cnt <= clk_cnt + 1;
                    state <= STOP_BIT;
                end
            end

            default: state <= IDLE;

        endcase
    end
end
endmodule