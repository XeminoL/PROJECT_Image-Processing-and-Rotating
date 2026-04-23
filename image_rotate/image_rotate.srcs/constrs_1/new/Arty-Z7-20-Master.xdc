# === Clock ===
set_property -dict { PACKAGE_PIN H16    IOSTANDARD LVCMOS33 } [get_ports { clk_125mhz }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk_125mhz }];

# === (Reset Buttons) ===
set_property -dict { PACKAGE_PIN D20    IOSTANDARD LVCMOS33 } [get_ports { BTN1 }];

# === (Switches) ===
set_property -dict { PACKAGE_PIN M20    IOSTANDARD LVCMOS33 } [get_ports { SW[0] }];
set_property -dict { PACKAGE_PIN M19    IOSTANDARD LVCMOS33 } [get_ports { SW[1] }];

# === (LEDs) ===
set_property -dict { PACKAGE_PIN R14    IOSTANDARD LVCMOS33 } [get_ports { LD0 }]; # LED0
set_property -dict { PACKAGE_PIN P14    IOSTANDARD LVCMOS33 } [get_ports { LD1 }]; # LED1

# === UART ===
set_property -dict { PACKAGE_PIN Y19    IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; # PIN 2 cua JA pmod vao RXD cua module ngoai