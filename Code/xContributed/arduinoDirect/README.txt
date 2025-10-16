This application requires a connection to a computer to work, via USB

you will control the anomalascope using the keyboard on your computer

w=brighter yellow
s=dimmer yellow
a=redder RGB LED
d=greener RGB LED

SPACEBAR = confirm match
n = start new match

1-7 number keys: adjust flicker rate

================================================

The included Arduino file is intended to be easy to modify and extend to suit your needs. Don't be afraid to go in and make changes. There are comments throughout that you can read that may help if it isn't working like you think it should

================================================

You can control the Arduino in two ways

1. Using the Arduino serial monitor (easier, but less recommended)
Steps:
1a: in the Arduino application, click tools->serial monitor. This should open the serial monitor at the bottom of the screen
1b: upload the program to your device by clicking the arrow in the top left corner of the Arduino application
1c: once it has uploaded (you can confirm in the "output" window at the bottom), click the serial monitor window
1d: click on the "message" box, type your desired key and press enter to send it

2. Using Tera Term (more work but recommended)
steps:
2a: download Tera Term https://github.com/TeraTermProject/teraterm/releases
2b: upload the program to the Arduino by clicking the arrow in the top left of the Arduino application
2c: close the Arduino application (you may also need to unplug/replug the Arduino into your usb port)
2d: open tera term, click file->new connection. Choose Serial, and then find your Arduino on the list. Click OK
2e: now you can send messages by simply typing them into the terminal (black screen), no pressing "enter" required
2f: if you want to make changes to the program, close Tera Term, re-open the Arduino program (maybe unplug/replug the Arduino), and upload as normal. You can only have ONE of the Arduino windows application and Tera Term connected to the Arduino device at a time. This is nice when your program is 100% finished and you just want to run it as easily as possible, but when you are iterating on it, it may be easier to just use the Arduino windows application
