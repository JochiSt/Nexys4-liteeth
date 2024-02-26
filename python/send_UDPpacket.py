import socket
import threading
import signal
import sys
import time

# Set the target IP address and port
target_ip = '192.168.1.12'
target_port = 14000

UDP_RX = False

# Create a UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

if UDP_RX:
    sock.bind(('0.0.0.0', target_port))

stop_thread = False

# Function to receive UDP packets
def receive_packets():
    global stop_thread
    sock.settimeout(1)
    while not stop_thread:
        try:
            data, server_address = sock.recvfrom(1024)
            response = data.decode('utf-8')
            print(time.time(), response)
        except TimeoutError:
            pass

# Function to handle CTRL-C
def signal_handler(sig, frame):
    global stop_thread
    stop_thread = True
    print('Terminating the script...')

# Register the signal handler for CTRL-C
signal.signal(signal.SIGINT, signal_handler)

if UDP_RX:
    # Create a thread for receiving packets
    receive_thread = threading.Thread(target=receive_packets)
    receive_thread.start()

counter = 0
# send UDP messages
while not stop_thread:

    for target_port in range(1024,15000):
        msg_bytes = bytearray()
        msg_bytes.append(counter)

        print("%10d"%(target_port))

        sock.sendto(msg_bytes, (target_ip, target_port))
        if counter > 999:
            counter = 0
        time.sleep(.001)

        if stop_thread:
            break

if UDP_RX:
    # Wait for the receive thread to finish
    receive_thread.join()

# Close the socket
sock.close()

sys.exit(0)
