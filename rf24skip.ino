#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>
#include <AcceleroMMA7361.h>

// NB: This sketch assumes 32 bit addresses

static long int address = 0x66996699L;  // So that's 0x0066996699
const int tries = 10;

AcceleroMMA7361 acc;
RF24 rf(/*ce*/ 8, /*cs*/ 10);

void setup() {
    Serial.begin(115200);
    acc.begin(/*sleep*/ 4, /*test*/ 6, /*0G*/ 8, /*Gselect*/ 5, /*xyz*/A0,A1,A2);
    acc.setSensitivity(LOW);

    rf.begin();
    rf.setRetries(15, 15);
    rf.enableDynamicPayloads();
    rf.openWritingPipe(address);
    char buf[6] = "\x04SKIP";
    for (int i = 0; i < tries; i++)
        rf.write(&buf, 5);
}

void loop() {
    static int oldx = 0, oldy = 0, oldz = 0;
    static unsigned long oldt;
    int x = acc.getXAccel();
    int y = acc.getXAccel();
    int z = acc.getXAccel();
    unsigned long t = millis();
    static bool firstloop = true;
    static unsigned int shakiness = 0;
    
    int dx = x - oldx, dy = y - oldy, dz = z - oldz, dt = t - oldt;
    oldx = x; oldy = y; oldz = z; oldt = t;
    
    if (firstloop) {
      firstloop = false;
      return;
    }
    
    if (millis() >= 2500) {
        char SHUF[6] = "\x04SHUF";
        char STOP[6] = "\x04STOP";
        
        for (int i = 0; i < tries; i++)
            rf.write(shakiness < 900 ? &STOP : &SHUF, 5);
        
        for (;;);  // halt
    }
    
    float shock2 = (float) (dx*dx* + dy*dy + dz*dz)/dt;
    shakiness += abs(shock2) / 100;
    Serial.println(shakiness);
          
    delay(10);

}





// vim: ft=cpp
