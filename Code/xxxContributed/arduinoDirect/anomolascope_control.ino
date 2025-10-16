
uint8_t R_pin = 6;
uint8_t G_pin = 5;
uint8_t B_pin = 3;
uint8_t Y_pin = 9;
//these values may need to be adjusted or swapped. Requires trial and error

int ylum = 80;
float rg_ratio = 0.25;
bool on = true;
bool allow_adjust = true;

float rgb_dimmer = 0.5;//this allows you to dim the rgb by a preset static amount

//these variables control how fast the lights blink. Each cycle is "maxval" loops long
//the lights will be on for "onoff" loops, and off for (maxval-onoff) loops
//"counter" just counts the loops to coordinate this
int counter = 0;
int maxval = 500;
int onoff = 250;

/*
Note: for some reason, some boards need you to negate the voltage sent to the pins. I have no idea why. Probably a bug in my code or something
if that is the case, replace all instances of analogWrite(pin,value) with analogWrite(pin,255-value)

for example, 
  analogWrite(R_pin,r_value) ---> analogWrite(R_pin,255-r_value)
*/



void setup() {
  pinMode(LED_BUILTIN, OUTPUT);

  pinMode(Y_pin,OUTPUT);
  pinMode(R_pin,OUTPUT);
  pinMode(G_pin,OUTPUT);
  pinMode(B_pin,OUTPUT);

  Serial.begin(9600);

  restart_matching();


}

void print_results(){
  Serial.print("R/G Ratio: ");
  Serial.println(rg_ratio,3);

  Serial.print("Y lum: ");
  Serial.println(ylum);
}

void pause_matching(){
  allow_adjust = false;
  maxval = 100;
  onoff = 0;
  print_results();  
}

void restart_matching(){
  //these numbers chosen based on vibes, feel free to adjust
  rg_ratio = random(10,50)/100.0;
  ylum = random(75,115);

  allow_adjust = true;

  maxval = 100;//make the lights constant
  onoff = 100;

}

void adjust_rg(float amount){
  if(allow_adjust){
    rg_ratio += amount;
  }
  rg_ratio = min(1.0,rg_ratio);
  rg_ratio = max(0.0,rg_ratio);
}

void adjust_lum(int amount){
  if(allow_adjust){
    ylum += amount;
  }
  ylum = min(255,ylum);
  ylum = max(0,ylum);

}

char get_serial_input(){
  int serial_data = 0;
  if(Serial.available() > 0){
    serial_data = Serial.read();
    if(serial_data<0 || serial_data>127){//out of ascii range
      return NULL;
    }
    char c = (char)serial_data;
    

    return c;
  }else{
    return NULL;
  }
}

void loop(){
  char c_in = get_serial_input();

  if(c_in == 'a'){
    adjust_rg(-0.06);
  }
  if(c_in == 'd'){
    adjust_rg(0.06);
  }
  if(c_in == 'w'){
    adjust_lum(8);
  }
  if(c_in == 's'){
    adjust_lum(-8);
  }
  if(c_in == ' '){
    pause_matching();
  }
  if(c_in == 'n'){
    restart_matching();
  }
  if(c_in == '1'){
    maxval = 100;
    onoff = 100;
  }
  if(c_in == '2'){
    maxval = 50;
    onoff = 25;
  }
  if(c_in == '3'){
    maxval = 200;
    onoff = 100;
  }
  if(c_in == '4'){
    maxval = 500;
    onoff = 250;
  }
  if(c_in == '5'){
    maxval = 1000;
    onoff = 500;
  }
  if(c_in == '6'){
    maxval = 2000;
    onoff = 1000;
  }
  if(c_in == '7'){
    maxval = 4000;
    onoff = 2000;
  }

  float r_level = rg_ratio * 255.0;
  float g_level = (1.0-rg_ratio)*255.0;

  r_level *= rgb_dimmer;
  g_level *= rgb_dimmer;

  if(counter < onoff){//turn the lights on

    //for some reason you need to analogWrite the inverse of the value (ie 255-value). Writing 255 turns it off, and 0 turns it on
    //probably a bug in my code but who knows why
    
    analogWrite(R_pin,r_level);
    analogWrite(G_pin,g_level);
    analogWrite(B_pin,0);

    analogWrite(Y_pin,ylum);

  }else{//turn the lights off
    analogWrite(R_pin,0);
    analogWrite(G_pin,0);
    analogWrite(B_pin,0);
    analogWrite(Y_pin,0);
  }

  counter += 1;
  if(counter > maxval){
    counter = 0;
  }

}
