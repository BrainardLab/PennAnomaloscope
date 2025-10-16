


import socket
import math
import time


UDP_IP = '255.255.255.255'
UDP_PORT = 56700


"""
To use this program
connect your computer to the wifi network that is your lightbulb
run this program using IDE or terminal of your choice

it should work with no dependencies although you are free to add your own to extend the functionality

to change the behavior, go to the section
    if __name__ == "__main__"

and use whatever function you like. You can use the included functions like hue_loop(), america(), etc to see how it works and write your own color functions

if for some reason, its not working, try replacing the "sock" variable with "None" in your function call
This will force it to create a new connection to the bulb every time it sends a color
This will slow it down somewhat, but can occasionally fix problems

for example
    hue_loop(sock) ----> hue_loop(None)
    send_color(*cGREEN,sock) ---> send_color(*cGREEN,None)

"""

def lifx_udp(h, s, b, k, send_packet=True, sock=None, ip_address='255.255.255.255'):
    
    packet = [
        0x31, 0x00, 0x00, 0x34, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x66, 0x00, 0x00, 0x00, 0x00, 0x55, 0x55, 0xFF,
        0xFF, 0xFF, 0xFF, 0xAC, 0x0D, 0x00, 0x00, 0x00,
        0x00
    ]
    
    #HUE (bytes 37-38, little-endian)
    hue = int(math.floor(h / 360.0 * 65535))
    hue = max(0, min(65535, hue))  # Clamp to valid range
    packet[37] = hue & 0xFF  # Low byte
    packet[38] = (hue >> 8) & 0xFF  # High byte
    
    #SATURATION (bytes 39-40, little-endian)
    sat = int(math.floor(s * 65535))
    sat = max(0, min(65535, sat))  # Clamp to valid range
    packet[39] = sat & 0xFF  # Low byte
    packet[40] = (sat >> 8) & 0xFF  # High byte
    
    #BRIGHTNESS (bytes 41-42, little-endian)
    bright = int(math.floor(b * 65535))
    bright = max(0, min(65535, bright))  # Clamp to valid range
    packet[41] = bright & 0xFF  # Low byte
    packet[42] = (bright >> 8) & 0xFF  # High byte
    
    # KELVIN (bytes 43-44, little-endian)
    kelvin = int(math.floor(k))
    kelvin = max(2500, min(9000, kelvin))  # Clamp to valid range
    packet[43] = kelvin & 0xFF  # Low byte
    packet[44] = (kelvin >> 8) & 0xFF  # High byte
    
    packet_bytes = bytes(packet)
    
    if send_packet:
        try:
            # Create UDP socket if none is given
            if sock is None:
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
                new_connection = True
            else:
                new_connection = False
        
            sock.sendto(packet_bytes, (ip_address, 56700))
            

            if new_connection:
                sock.close()
                #the operating system should automatically close unused sockets after program termination
                #but if we create a new connection every time we send a color we will end up with a lot of sockets, so its probably best to just close them here
            
            print(f"Packet sent to {ip_address}:56700")
        except Exception as e:
            print(f"Error sending packet: {e}")
    
    return packet_bytes




def linspace(start,stop,num_steps):#to remove numpy dependancy, here's a stupid version of np.linspace
    #this will give you "num_steps" values, evenly spaced between "start" and "stop"
    a = []
    delta = (stop-start)/num_steps
    for i in range(num_steps):
        a.append(start+(i*delta))
    return a

def send_color(h,s,v,sock):
    lifx_udp(h,s,v,600,send_packet=True,ip_address=UDP_IP,sock=sock)

def hue_loop(sock):
    while True:
        for i in linspace(0,360,720):
            send_color(i,1,1,sock)
            time.sleep(0.125)

def crazy_wheel(sock):
    while True:
        for i in linspace(0,360,45):
            send_color(i,0.5,1,sock)
            time.sleep(0.05)


def flicker(sock):
    for i in range(100):
        send_color(*cGREEN,sock)
        time.sleep(0.1)
        send_color(*cRED,sock)


def america(sock):
    while True:
        send_color(*cRED,sock)
        time.sleep(0.2)
        send_color(*cBLUE,sock)
        time.sleep(0.2)
        send_color(*cWHITE,sock)

def strobe(sock):
    while True:
        send_color(*cYELLOW,sock)
        time.sleep(0.1)
        send_color(*cBLUE,sock)
        time.sleep(0.1)


cRED = (0,1,1)
cCYAN = (180,1,1)
cWHITE = (0,0,1)
cGREEN = (140,1,1)
cBLUE = (220,1,1)
cORANGE = (30,1,1)
cYELLOW = (50,1,1)
cPURPLE = (280,1,1)
cOFF = (0,0,0)

#colors are defined by h (0-360), s (0-1), b (0-1). Feel free to define your own
#the lightbulb api only accepts colors in hsb format, so if you want to specify them in for example rgb, you will need to implement your own conversion (have fun :)

if __name__ == "__main__":
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

    #---^^ don't mess with stuff above here unless you know what you're doing ^^-----

    #---feel free to mess with stuff below here------

    send_color(*cRED,sock)#this star syntax just means to unpack the tuple into individual values, don't worry about it if you are new to python
    time.sleep(2)

    send_color(180,1,1,sock)
    time.sleep(2)

    hue_loop(sock)