import socket
import threading
import signal
import sys
import time

# Set the target IP address and port
target_ip = '192.168.1.12'
target_port = 2000
sleep_time = .001   # time to sleep between to TX packets

UDP_RX = True

# Create a UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

if UDP_RX:
    sock.bind(('0.0.0.0', target_port))

stop_thread = False

# Function to receive UDP packets
def receive_packets():
    global stop_thread
    sock.settimeout(10)
    while not stop_thread:
        try:
            data, server_address = sock.recvfrom(1024)
            response = data.decode('utf-8')
            print(time.time(), server_address, response, data)
        except TimeoutError:
            print("... timeout")
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
    msg_bytes = bytearray([counter, 0xFF])

    #print(msg_bytes)

    sock.sendto(msg_bytes, (target_ip, target_port))
    counter += 1

    if counter > 0xFF:
        counter = 0

    time.sleep(sleep_time)

    if stop_thread:
        break

if UDP_RX:
    # Wait for the receive thread to finish
    receive_thread.join()

# Close the socket
sock.close()

sys.exit(0)
