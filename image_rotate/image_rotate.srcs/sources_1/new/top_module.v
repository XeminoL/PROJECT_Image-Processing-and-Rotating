`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2025 05:19:52 PM
// Design Name: 
// Module Name: top_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_module #(
    parameter img_x = 256,
    parameter img_y = 256,
    parameter data = 8
)
(
    input clk_125mhz,
    input BTN1, // start button
    input [1:0] SW, // mode button

    output uart_tx,
    output LD0,
    output LD1
);
    
    localparam img_size = img_x * img_y;
    localparam addr_size = $clog2(img_size);
        
    wire clk = clk_125mhz;
    wire reset = BTN1; // active low (reset when pressed)
    
    wire rotate_done;
    wire [7:0] data_in_A;
    wire [addr_size-1 :0] addr_A;
    wire rd_en_A;
    wire [7:0] data_out_B;
    wire [addr_size-1 :0] addr_B_write;
    wire wr_en_B;
    wire [7:0] data_in_B;
    wire [addr_size-1 :0] addr_B_read;
    
    reg rd_en_B_uart;
    reg [3:0] state;
    localparam IDLE = 4'd0;
    localparam ROTATE_START = 4'd1;
    localparam ROTATE_WAIT = 4'd2;
    localparam SEND_ADDR = 4'd3;   
    localparam SEND_WAIT_BRAM = 4'd4; // Wait for BRAM latency
    localparam SEND_TX = 4'd5;     
    localparam WAIT_TX = 4'd6;
    
    //reg [addr_size-1 :0] rx_counter;
    reg [addr_size-1 :0] tx_counter;
    reg rotate_start;
    
    wire [7:0] rx_byte;
    wire rx_dv;
    reg [7:0] tx_byte;
    reg tx_dv;
    wire tx_active;
    wire tx_done;
    
    // FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            //rx_counter <= 0;
            tx_counter <= 0;
            rotate_start <= 0;
            tx_dv <= 0;
            rd_en_B_uart <= 0;
        end
        else begin
            rotate_start <= 0;
            tx_dv <= 0;
            rd_en_B_uart <= 0;
            
            case (state)
                IDLE: begin
                    //rx_counter <= 0;
                    tx_counter <= 0;
                        state <= ROTATE_START;
                end
                
                ROTATE_START: begin
                    rotate_start <= 1;
                    state <= ROTATE_WAIT;
                end
                
                ROTATE_WAIT: begin
                    if (rotate_done) begin
                        state <= SEND_ADDR;
                    end
                end
                
                SEND_ADDR: begin
                    rd_en_B_uart <= 1;
                    state <= SEND_WAIT_BRAM;
                end
                
                SEND_WAIT_BRAM: begin
                    state <= SEND_TX; // wait 1 cycle for BRAM read latency
                end
                
                SEND_TX: begin
                    tx_byte <= data_in_B;
                    tx_dv <= 1;
                    state <= WAIT_TX;
                end
                
                WAIT_TX: begin
                    if (tx_done) begin
                        if(tx_counter == (img_size - 1)) begin
                            state <= IDLE;
                        end
                        else begin
                            tx_counter <= tx_counter + 1;
                            state <= SEND_ADDR;
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    assign LD0 = (state != IDLE);
    assign LD1 = state[1];          // sang
    
    // IMAGE_ROTATE MODULE
    image_rotate #(
        .img_x(img_x), .img_y(img_y), .data(data)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(rotate_start),
        .mode(SW),
        .done(rotate_done),
        .addr_A(addr_A),
        .addr_B(addr_B_write),
        .data_in(data_in_A),
        .data_out(data_out_B),
        .rd_en(rd_en_A),
        .wr_en(wr_en_B)
    );
    
    // BRAM_IN MODULE (original img)
    bram_in uuut (
        .clka(clk),
        .ena(1'b0),
        .wea(1'b0),
        .addra(0),
        .dina(0),
        
        .clkb(clk),
        .enb(rd_en_A),
        .addrb(addr_A),
        .doutb(data_in_A)
    );
    
    // BRAM_OUT MODULE (rotated img)
    bram_out uuuut (
        .clka(clk),
        .ena(wr_en_B),
        .wea(wr_en_B),
        .addra(addr_B_write),
        .dina(data_out_B),
        
        .clkb(clk),
        .enb(rd_en_B_uart),
        .addrb(tx_counter),
        .doutb(data_in_B)
    );
    
    // UART_TX MODULE
    uart_tx #(
        .TICKS_PER_BIT(1085),      // 125MHz / 115200 = 1085
        .TICKS_PER_BIT_SIZE(11)     
    ) tx (
        .i_clk(clk),
        .i_rst(reset),              // BTN1 to reset
        .i_start(tx_dv),            // 
        .i_data(tx_byte),           // 
        
        .o_done(tx_done),           // 
        .o_busy(tx_active),         // 
        .o_dout(uart_tx)            // 
    );
endmodule
