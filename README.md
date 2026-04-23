# Image Rotation and Mirroring on FPGA

A hardware-accelerated image processing system implemented on the **Arty Z7-20 (Zynq-7020)** FPGA. The design rotates a grayscale image by 90° (clockwise / counter-clockwise) and mirrors it horizontally or vertically using pure RTL logic, then streams the transformed image back to a host PC over UART for visualization.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Repository Structure](#repository-structure)
- [Requirements](#requirements)
- [Installation and Build](#installation-and-build)
- [How It Works](#how-it-works)
- [Operation Modes](#operation-modes)
- [Authors](#authors)
- [License](#license)

---

## Overview

This project implements an image transformation block in Verilog that runs on the Zynq-7020 PL (Programmable Logic). The flow is:

1. A Python script converts a grayscale image into a `.coe` file.
2. The `.coe` file initializes the input BRAM inside the FPGA.
3. The hardware performs coordinate remapping (`x, y → x', y'`) for each pixel and writes the result into the output BRAM.
4. A Python script receives the transformed image back over UART and displays it.

- **Input:** 8-bit grayscale image (max 512 × 512, recommended 256 × 256).
- **Output:** Rotated (90° CW / CCW) or mirrored (horizontal / vertical) image.
- **Algorithm:** Per-pixel coordinate remapping inside the rotate controller.

---

## Features

- 90° clockwise rotation
- 90° counter-clockwise rotation
- Horizontal mirroring
- Vertical mirroring
- 2-bit mode select switch interface (uses on-board switches of Arty Z7-20)
- UART transmission of processed image back to host PC
- Configurable image size up to 512 × 512
- Block-diagram included (`BlockDiagram.drawio`)

---

## System Architecture

The design consists of the following main blocks:

| Block | Role |
|---|---|
| `bram_in` | Input BRAM, initialized at synthesis time from `image_data.coe` |
| `rotate_controller` | Generates read addresses for `bram_in` and write addresses for `bram_out` based on the selected mode (00 / 01 / 10 / 11) |
| `bram_out` | Output BRAM that stores the transformed image |
| `uart_tx` | Reads pixels from `bram_out` and serializes them over UART (115200 8N1) to the host PC |
| Top module | Wires all sub-modules together and exposes switches / UART pins |

A high-level block diagram is provided in `BlockDiagram.drawio` (open with [draw.io](https://app.diagrams.net/) or VS Code's Draw.io Integration extension).

---

## Repository Structure

```
PROJECT_Image-Processing-and-Rotating/
├── Image_rotation_python/        # Host-side Python scripts
│   ├── convert_image.py          # JPG/PNG  →  image_data.coe
│   └── receive_image.py          # UART receiver + image display
├── image_rotate.srcs/            # Vivado RTL sources (Verilog)
├── image_rotate.cache/           # Vivado cache files
├── image_rotate.hw/              # Vivado hardware handoff
├── image_rotate.sim/             # Simulation files (xsim)
├── BlockDiagram.drawio           # System block diagram
└── README.md
```

---

## Requirements

### Hardware

- **FPGA Board:** Digilent Arty Z7-20 (Xilinx Zynq-7020)
- USB cable (for programming + UART)
- 4 on-board slide switches (used for mode select and start signal)

### Software

- **Vivado** 2020.x or newer (project was developed and tested with the toolchain bundled in this repo's `image_rotate.cache` / `image_rotate.hw` folders)
- **Python** 3.8 or newer with the following libraries:

```bash
pip install pyserial numpy matplotlib pillow
```

---

## Installation and Build

### Step 1 — Clone the repository

```bash
git clone https://github.com/XeminoL/PROJECT_Image-Processing-and-Rotating.git
cd PROJECT_Image-Processing-and-Rotating
```

### Step 2 — Prepare the input image

- Pick any image you like (max **512 × 512**, recommended **256 × 256** for fastest UART transfer).
- Place it inside the `Image_rotation_python/` folder.

### Step 3 — Convert the image to a `.coe` file

Open `Image_rotation_python/convert_image.py` and update these two lines to match your image:

```python
IMG_SIZE = 256          # image dimension (square)
IMG_PATH = 'random.jpg' # your image file name
```

Then run:

```bash
cd Image_rotation_python
python convert_image.py
```

This generates `image_data.coe` in the same folder.

### Step 4 — Load the `.coe` file into BRAM

1. Open the `image_rotate` project in **Vivado**.
2. In the IP Sources tab, double-click on `bram_in`.
3. Go to **Other Options** → tick **Load Init File** → browse to the `image_data.coe` you just generated → click **OK**.
4. Re-generate the IP if Vivado prompts you.

### Step 5 — Generate bitstream and program the board

1. Click **Generate Bitstream** in Vivado.
2. Connect the **Arty Z7-20** to your PC via USB.
3. Open the **Hardware Manager** → **Auto Connect** → **Program Device** with the generated `.bit` file.

### Step 6 — Receive and display the rotated image

1. Set the slide switches on the Arty Z7-20 to choose a mode (see [Operation Modes](#operation-modes) below).
2. On your PC, open `Image_rotation_python/receive_image.py` and make sure the COM port matches the one assigned to your board (check **Device Manager** on Windows or `ls /dev/tty*` on Linux).
3. Run:

```bash
python receive_image.py
```

4. The transformed image will be plotted on screen via Matplotlib once UART transfer finishes.

---

## How It Works

For each output pixel `(x', y')`, the `rotate_controller` computes the corresponding input coordinate `(x, y)` according to the selected transformation:

| Mode | Transformation | Formula |
|---|---|---|
| `00` | 90° Clockwise | `x = y'`, `y = (N-1) - x'` |
| `01` | 90° Counter-clockwise | `x = (N-1) - y'`, `y = x'` |
| `10` | Horizontal Mirror | `x = (N-1) - x'`, `y = y'` |
| `11` | Vertical Mirror | `x = x'`, `y = (N-1) - y'` |

Where `N` is the image size (e.g. 256). The controller then reads `bram_in[y * N + x]` and writes the value into `bram_out[y' * N + x']`. Once the entire frame is processed, `uart_tx` streams the contents of `bram_out` to the PC.

---

## Operation Modes

| Switch (SW1, SW0) | Mode |
|:---:|---|
| `00` | Rotate Clockwise (90°) |
| `01` | Rotate Counter-clockwise (90°) |
| `10` | Mirror Horizontal |
| `11` | Mirror Vertical |

---

## Authors

- **XeminoL** — [GitHub Profile](https://github.com/XeminoL)

---

## License

This project is released for educational purposes. Feel free to fork, study, and modify.
