`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 03:03:00 PM
// Design Name: 
// Module Name: image_rotate
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

module image_rotate #(
    parameter img_x = 256, // row M (height)
    parameter img_y = 256, // column N (width)
    parameter data = 8, // 2^8 = 256 -> grayscale image

    localparam img_size = img_x * img_y,
    localparam addr_size = $clog2(img_size) // bit size of pixel's coordinate
)
(
    input clk,
    input reset,
    input start,
    input [1:0]mode,
    output done,
    
    // original img
    input [data - 1 :0] data_in, // send original img pixel in to process
    output reg [addr_size-1 :0] addr_A,// pixel's location for reading
    output reg rd_en,
    
    // new img
    output reg [data - 1 :0] data_out, // send new img pixel out after process
    output reg [addr_size-1 :0] addr_B, // pixel's location for writing
    output reg wr_en
 );
  
    // modes
    localparam rotate_cw = 2'b00;
    localparam rotate_ccw = 2'b01;
    localparam mirror_h = 2'b10;
    localparam mirror_v = 2'b11;
    
        // 1. CONTROLLER FSM
    localparam INIT = 3'b000;
    localparam READ = 3'b001;
    localparam WAIT_READ = 3'b010; // wait for BRAM to return the data
    localparam WRITE_NEXT = 3'b011;
    localparam DONE = 3'b100;
    
    // FSM registers
    reg [2:0] state, next_state;
    reg [addr_size-1 :0] counter_x;
    reg [addr_size-1 :0] counter_y;
    reg [data - 1 :0] temp_data; // store pixels read from RAM (FIFO/buffer)
    //reg done_reg;
    
    reg [addr_size-1 :0] x_new;
    reg [addr_size-1 :0] y_new;
    wire [addr_size-1 :0] addr_in;
    wire [addr_size-1 :0] addr_out;
    reg [addr_size-1 :0] img_y_out; // handle non-square images
    wire img_done;
    
    // FSM update state
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INIT;
        end
        else begin
            state <= next_state;
        end
    end
    
    // FSM next state
    always @(*) begin
        next_state = state;
        case (state)
            INIT: begin
                if (start) begin
                    next_state = READ;
                end
            end
            
            READ: begin
                next_state = WAIT_READ;
            end
            
            WAIT_READ: begin
                next_state = WRITE_NEXT;
            end
            
            WRITE_NEXT: begin
                if (img_done) begin
                    next_state = DONE;
                end
                else begin
                    next_state = READ;
                end
            end
            
            DONE: begin
                next_state = INIT;
            end
            
            default: next_state = INIT;
          endcase
      end
          
      // FSM update reg and counter
      always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_x <= 0;
            counter_y <= 0;
            temp_data <= 0;
            //done_reg <= 0;
        end
        else begin
            //done_reg <= 0;
            case (state)
                INIT: begin
                    if (start) begin
                        counter_x <= 0;
                        counter_y <= 0;
                    end
                end
                
                WAIT_READ: begin
                    temp_data <= data_in;
                end
                
                WRITE_NEXT: begin
                        if (counter_y == img_y - 1) begin // da toi cot cuoi cung
                            counter_y <= 0;
                            counter_x <= counter_x + 1; // xuong hang tiep theo
                        end
                        else begin
                            counter_y <= counter_y + 1; // cot tiep theo
                        end
                end
                
            endcase
          end
      end
        assign done = (state == DONE);
      
        // 2. ADDRESS GENERATOR
      assign img_done = (counter_x == img_x - 1) && (counter_y == img_y - 1); // img_done when at the last row and column
      assign addr_in = (counter_x * img_y) + counter_y; // addr = x * N + y
      
        // 3. COORDINATE MAPPER
      always @(*) begin
        case (mode)
            // rotate right
            rotate_cw: begin // x' = y, y' = M-1-x
                x_new = counter_y;
                y_new = img_x - 1 - counter_x;
            end
            
            // rotate left
            rotate_ccw: begin // x' = N-1-y, y' = x
                x_new = img_y - 1 - counter_y;
                y_new = counter_x;
            end
            
            // mirror horizontal
            mirror_h: begin // x' = x, y' = N-1-y
                x_new = counter_x;
                y_new = img_y - 1 - counter_y;
            end
            
            // mirror vertical
            mirror_v: begin // x' = M-1-x, y' = y
                x_new = img_x - 1 - counter_x;
                y_new = counter_y;
            end
            
            default: begin
                x_new = 0;
                y_new = 0;
            end
        endcase
     end
        
        // 4. ADDRESS CONVERTER
        always @(*) begin
            if (mode == rotate_cw || mode == rotate_ccw) begin
                img_y_out = img_x; // rotate => N' = M
            end
            else begin
                img_y_out = img_y; // mirror => N' = N
            end
        end
        
        assign addr_out = (x_new * img_y_out) + y_new; // addr_out = x' * N_out + y'
        
        // 5. MEMORY INTERFACE
    always @(*) begin
        addr_A = 0;
        addr_B = 0;
        data_out = 0;
        rd_en = 0;
        wr_en = 0;
        
        case (state)
            READ: begin
                addr_A = addr_in;
                rd_en = 1;
            end
            
            WRITE_NEXT: begin
                addr_B = addr_out;
                data_out = temp_data;
                wr_en = 1;
            end
        endcase
    end
    
endmodule
