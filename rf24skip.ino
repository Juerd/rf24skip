#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

// NB: This sketch assumes 32 bit addresses

static long int address = 0x66996699L;  // So that's 0x0066996699

RF24 rf(/*ce*/ 8, /*cs*/ 10);

void setup() {
    pinMode(9, OUTPUT);
    digitalWrite(9, HIGH);
    Serial.begin(115200);
    rf.begin();
    rf.setRetries(15, 15);
    rf.enableDynamicPayloads();
    rf.openWritingPipe(address);
    char buf[6] = "\x04SKIP";
    for (int i = 0; i < 4; i++)
        rf.write(&buf, 5);
    digitalWrite(9, LOW);
}

void loop() {
}





// vim: ft=cpp
