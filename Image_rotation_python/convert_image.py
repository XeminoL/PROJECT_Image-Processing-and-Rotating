import numpy as np
from PIL import Image
import os

IMG_SIZE = 256
IMG_PATH = 'random.jpg' # đổi ảnh
COE_FILE = 'image_data.coe' # file lưu dữ liệu ảnh

def run():
    # xử lý ảnh
    img = Image.open(IMG_PATH).convert('L').resize((IMG_SIZE, IMG_SIZE)) #gray-scale 256 x 256 img
    img_data = np.array(img, dtype=np.uint8)
    flat_data = img_data.flatten() #.tobytes()
    
    print(f"sending {len(flat_data)} bytes to FPGA...")
    
    # tạo file .coe
    with open(COE_FILE, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        
        # Ghi dữ liệu, phân cách bằng dấu phẩy, kết thúc bằng dấu chấm phẩy
        for i, byte in enumerate(flat_data):
            if i == len(flat_data) - 1:
                f.write(f"{byte:02X};") # Phần tử cuối cùng
            else:
                f.write(f"{byte:02X},")
                if (i + 1) % 16 == 0: # Xuống dòng cho dễ nhìn
                    f.write("\n")
    print(f"-> Đã tạo {COE_FILE}")

if __name__ == "__main__":
    run()