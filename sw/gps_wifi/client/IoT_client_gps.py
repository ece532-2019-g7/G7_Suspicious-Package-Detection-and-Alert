""" Simple Client Example

This script makes three separate connections to a sever
located on the same computer on port 9090. During the
first connection a 'GET' command is issued to receive the
current value in the server. A subsequent connection updates
the value to 0xBAADF00D and this value is read back during
the final connection.
"""

import socket

BUFFER_SIZE = 2048 #4096
SERVER_ADDR = '192.168.43.112'
SERVER_PORT = 44300

# GET current value
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.connect((SERVER_ADDR, SERVER_PORT))
    print("Connection established\n")

    print("Receiving data...\n")
    data = sock.recv(BUFFER_SIZE)
    print("All data received\n")

    byte_arr = bytearray()
    image_size = 0

    if data[:4] == b'SIZE':
        image_size = int(data[4:])
        print("Recv image size is:", image_size)

        num_bytes_read = 0

        while num_bytes_read < image_size:
            frame = sock.recv(BUFFER_SIZE)
            byte_arr += frame
            num_bytes_read += BUFFER_SIZE

    print(data)

    sock.close()
