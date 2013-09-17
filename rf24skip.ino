#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

// NB: This sketch assumes 32 bit addresses

static long int address = 0x66996699L;  // So that's 0x0066996699
const int tries = 10;

RF24 rf(/*ce*/ 8, /*cs*/ 10);

void setup() {
    Serial.begin(115200);
    rf.begin();
    rf.setRetries(15, 15);
    rf.enableDynamicPayloads();
    rf.openWritingPipe(address);
    char buf[6] = "\x04SKIP";
    for (int i = 0; i < tries; i++)
        rf.write(&buf, 5);
}

void loop() {
    if (millis() >= 2500) {
        char buf[6] = "\x04STOP";
        for (int i = 0; i < tries; i++)
            rf.write(&buf, 5);
        for (;;);  // halt
    }

}





// vim: ft=cpp
