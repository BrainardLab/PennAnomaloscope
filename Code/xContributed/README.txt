
This directory contains code provided by other groups.

arduinoHFP - For running heterochromatic flicker photometry. Contributed by Allie Hexley and students she is working with.  There is a README.txt in the directory.  This is written for Windows and will need a little futzing to get to work on Mac or Linux.  Note that you'll need to manually load the FlickeringLight.ino file onto the Arduino before the Matlab part will work. More direct control of the arduino is needed because the Matlab toolbox interface is not fast enough to flicker at the rates needed for HFP.

arduinoDirect - Direct connection to arduino for control of LEDs and flicker rate. Contributed by Alexander Gokan.  Runs in the arduino application with no additional dependencies.  See README.txt in the folder for more.

lightbulb - Control LEDs directly from python. Contributed by Alexander Gokan. The lightbulb control program should run in python 3 with no dependencies or additional setup at all.

