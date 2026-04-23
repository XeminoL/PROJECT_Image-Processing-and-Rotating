import serial
import numpy as np
from PIL import Image
import time

PORT = 'COM3' # lấy COM USB to TTL
BAUD = 115200
IMG_SIZE = 256
OUTPUT_IMG = 'image_result.jpg' # đổi tên

def run():
    print("giữ BTN1 cho đến khi có lệnh thả nút")

    try:
        with serial.Serial(PORT, BAUD, timeout=20) as ser:
            print("thả nút BTN1")

            expected_bytes = IMG_SIZE * IMG_SIZE
            data = ser.read(expected_bytes)
        
            print("received enough bytes")

        # chuyển bytes sang ảnh
        arr = np.frombuffer(data, dtype=np.uint8).reshape((IMG_SIZE, IMG_SIZE))
        img = Image.fromarray(arr)

        # lưu và hiện ảnh
        img.save(OUTPUT_IMG)
        img.show()
        print ("img saved as", OUTPUT_IMG)

    except serial.SerialException as e:
        print("error port COM", e)

if __name__ == '__main__':
    run()