import socket
import datetime as dtm

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Bind the socket to the port
server_address = ('localhost', 17000)
print('Starting logging server')
sock.bind(server_address)

while True:
    data, address = sock.recvfrom(4096)
    print("%s: %s" % (f'{dtm.datetime.now():%Y-%m-%d %H:%M:%S}', data))
