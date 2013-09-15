#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

// NB: This sketch assumes 32 bit addresses

static long int address = 0x66996699L;  // So that's 0x0066996699
const int payload = 16;  // 32 is supported but not very reliable

RF24 rf(/*ce*/ 8, /*cs*/ 10);

static union {
    unsigned char buf[36];
    struct {
        uint32_t address;
        unsigned char message[payload];
    } packet;
} in;

unsigned char hexdigit(byte c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
}

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
