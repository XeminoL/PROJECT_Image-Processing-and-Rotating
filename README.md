# Image Rotation and Mirroring
## Requirement
 Design a hardware block to rotate an image by 90° (clockwise/counterclockwise) and to mirror it horizontally or vertically. The design fetches pixels from memory,
computes new coordinates, and stores the transformed image back.
- Input: Grayscale image stored in memory.
- Output: Rotated (90° CW/CCW) or mirrored image saved back to memory.
- Algorithm: Perform coordinate remapping for each pixel (x,y → x’,y’).
## Installation and Build
### Step 1: Install Python library
Open VS Code terminal and run the following:
```bash
pip install pyserial numpy matplotlib pillow
```

### Step 2: Get the image
- Find the image you want on Internet, the max image size is 512x512.
- Put the image in the same Python code folder (Image_rotation_python).

### Step 3: Convert the image
In convert_image.py, change the size of the image and the image name 'random.jpg' to the name of your image.
```bash
# change it here
IMG_SIZE = 256 # đổi kích cỡ ảnh
IMG_PATH = 'random.jpg' # đổi ảnh
```
After done changing the name, run the following in the terminal:
```bash
python convert_image.py
```
There will be a file named "image_data.coe" in that same folder.

### Step 4: Store the image
- Go to Vivado and open image_rotate project -> double click on bram_in -> Other options -> Choose load init file and press OK to generate.
- Generate Bitstream and connect Arty-Z7 20 -> Program device.

### Step 5: Rotate the image
- Open Python code "receive_image.py".
- Switch for modes:
  - 00: rotate Clockwise
  - 01: rotate Counter-clockwise
  - 10: mirror Horizontal
  - 11: mirror Vertical
- After choosing the rotate mode, run the following in the terminal:
```bash
python receive_image.py
```
