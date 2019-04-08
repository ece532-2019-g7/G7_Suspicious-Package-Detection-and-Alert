""" Client to connect to microblaze
"""

import socket
import sys

IMAGE_SIZE = 108800
BUFFER_SIZE = 4096
SERVER_ADDR = '192.168.1.10'
SERVER_PORT = 7

# GET current value
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.connect((SERVER_ADDR, SERVER_PORT))
    print("Connected to Remote Suspicioius Object Detector!")

    sock.send(b'Waiting')

    num_bytes_received = 0
    data = bytearray()

    while num_bytes_received < IMAGE_SIZE:
        try:
            frame = sock.recv(BUFFER_SIZE)
        except socket.error:
            continue
        #print("data: ", frame)
        data += frame
        num_bytes_received += sys.getsizeof(frame)
        print(num_bytes_received, "total bytes received")

    print("\nImage written to disk")

    # write to ppm file
    with open(".\\image_received_client.ppm", "w") as f_rec:
        # PPM header
        width = 320
        height = 165
        max_colour_val = 15 #VGA444
        ppm_header = f'P3 {width} {height} {max_colour_val}\n'
        f_rec.write(ppm_header)
        for h in range(height):
            for w in range(width):
                first_8bits = data[h*width*2 + w*2]
                last_8bits = data[h*width*2 + w*2 + 1]
                r = first_8bits & 0xF #0xF
                g = (last_8bits & 0xF0) >> 4 #0xF0
                b = last_8bits & 0x0F #0x0F
                f_rec.write("%s %s %s " %(r, g, b))
            f_rec.write("\n")
