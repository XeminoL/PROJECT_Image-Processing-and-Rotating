`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_image_rotate
// Description: Testbench ki?m tra logic xoay ?nh v?i b? nh? gi? l?p
//////////////////////////////////////////////////////////////////////////////////

module image_rotate_tb;

    // --- 1. C?u hình Kích th??c Test (Ch?n ?nh nh? ?? d? xem) ---
    // Th? nghi?m v?i ?nh 4 hàng x 3 c?t ?? th?y rõ vi?c ??i chi?u khi xoay
    parameter TB_M = 4; // Chi?u cao (S? hàng)
    parameter TB_N = 3; // Chi?u r?ng (S? c?t)
    parameter TB_DATA_WIDTH = 8;
    
    // T? ??ng tính toán các thông s? khác
    localparam TB_IMG_SIZE = TB_M * TB_N;
    localparam TB_ADDR_WIDTH = $clog2(TB_IMG_SIZE);

    // Các ch? ?? ho?t ??ng (Kh?p v?i file design)
    localparam MODE_CW  = 2'b00;
    localparam MODE_CCW = 2'b01;
    localparam MODE_H   = 2'b10;
    localparam MODE_V   = 2'b11;

    // --- 2. Khai báo Tín hi?u ---
    reg clk;
    reg reset;
    reg start;
    reg [1:0] mode;
    wire done;

    // K?t n?i t?i c?ng ??C c?a module (Port A)
    wire [TB_ADDR_WIDTH-1:0] addr_A;
    reg  [TB_DATA_WIDTH-1:0] data_in;
    wire                     rd_en;

    // K?t n?i t?i c?ng GHI c?a module (Port B)
    wire [TB_ADDR_WIDTH-1:0] addr_B;
    wire [TB_DATA_WIDTH-1:0] data_out;
    wire                     wr_en;

    // --- 3. B? nh? Gi? l?p (Mock Memory) ---
    // memory_in: Ch?a ?nh g?c (Ch? ??c)
    // memory_out: Ch?a ?nh k?t qu? (Ch? ghi)
    reg [TB_DATA_WIDTH-1:0] memory_in  [0:TB_IMG_SIZE-1];
    reg [TB_DATA_WIDTH-1:0] memory_out [0:TB_IMG_SIZE-1];

    // --- 4. K?t n?i Module (DUT) ---
    image_rotate #(
        .img_x(TB_M), 
        .img_y(TB_N), 
        .data(TB_DATA_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .mode(mode),
        .done(done),
        
        // C?ng ??c
        .addr_A(addr_A),
        .data_in(data_in), // Chú ý tên c?ng trong file design c?a b?n
        .rd_en(rd_en),
        
        // C?ng Ghi
        .addr_B(addr_B),
        .data_out(data_out),
        .wr_en(wr_en)
    );

    // --- 5. T?o xung Clock (100MHz) ---
    always #5 clk = ~clk;

    // --- 6. Mô ph?ng hành vi c?a BRAM ---
    always @(posedge clk) begin
        // Logic ??c: N?u module yêu c?u ??c, tr? d? li?u t? memory_in
        if (rd_en) begin
            data_in <= memory_in[addr_A];
        end
        
        // Logic Ghi: N?u module yêu c?u ghi, l?u d? li?u vào memory_out
        if (wr_en) begin
            memory_out[addr_B] <= data_out;
        end
    end

    // --- 7. K?ch b?n Test ---
    initial begin
        // Kh?i t?o
        clk = 0;
        reset = 1;
        start = 0;
        mode = 0;
        data_in = 0;
        
        // Reset h? th?ng
        #20 reset = 0;
        #10;

        // === TEST CASE 1: XOAY PH?I (CW) ===
        $display("\n--- TEST 1: Xoay Phai (CW) 90 do ---");
        init_memory(); // N?p d? li?u m?u
        $display("Anh goc (%0dx%0d):", TB_N, TB_M);
        print_mem_in(TB_N, TB_M); // In ?nh g?c (R?ng=3, Cao=4)
        
        mode = MODE_CW;
        pulse_start(); // Nh?n nút start
        wait(done);    // Ch? x? lý xong
        #20;
        
        $display("Ket qua (%0dx%0d):", TB_M, TB_N);
        print_mem_out(TB_M, TB_N); // In k?t qu? (R?ng=4, Cao=3 - ?ã ??o chi?u)


        // === TEST CASE 2: L?T NGANG (MIRROR H) ===
        $display("\n--- TEST 2: Lat Ngang (Mirror H) ---");
        // Không c?n n?p l?i b? nh? g?c vì nó không b? thay ??i
        mode = MODE_H;
        pulse_start();
        wait(done);
        #20;
        
        $display("Ket qua (%0dx%0d):", TB_N, TB_M);
        print_mem_out(TB_N, TB_M); // Kích th??c gi? nguyên


        // K?t thúc
        #100;
        $display("\n--- MO PHONG HOAN TAT ---");
        $finish;
    end

    // --- Các hàm h? tr? (Tasks) ---

    // Task nh?n nút Start
    task pulse_start;
        begin
            start = 1;
            #10; // Gi? trong 1 chu k? clock
            start = 0;
        end
    endtask

    // Task n?p d? li?u m?u (S? ??m t? 1 -> N)
    task init_memory;
        integer i;
        begin
            for (i = 0; i < TB_IMG_SIZE; i = i + 1) begin
                memory_in[i] = i + 1;
                memory_out[i] = 0; // Xóa b? nh? k?t qu?
            end
        end
    endtask

    // Task in ma tr?n ??u vào
    task print_mem_in;
        input integer w, h;
        integer r, c;
        begin
            for (r = 0; r < h; r = r + 1) begin
                for (c = 0; c < w; c = c + 1) begin
                    $write("%2x ", memory_in[r*w + c]);
                end
                $display("");
            end
        end
    endtask

    // Task in ma tr?n ??u ra
    task print_mem_out;
        input integer w, h;
        integer r, c;
        begin
            for (r = 0; r < h; r = r + 1) begin
                for (c = 0; c < w; c = c + 1) begin
                    $write("%2x ", memory_out[r*w + c]);
                end
                $display("");
            end
        end
    endtask

endmodule