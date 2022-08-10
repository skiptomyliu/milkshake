
#include "blowfish.h"
#import "Crypt.h"

/* Conversion from hex to int and int to hex */
static char i2h[16] = "0123456789abcdef";
static char h2i[256] = {
    ['0'] = 0, ['1'] = 1, ['2'] = 2, ['3'] = 3, ['4'] = 4, ['5'] = 5, ['6'] = 6,
    ['7'] = 7, ['8'] = 8, ['9'] = 9, ['a'] = 10, ['b'] = 11, ['c'] = 12,
    ['d'] = 13, ['e'] = 14, ['f'] = 15
};

static void appendByte(unsigned char byte, void *_data) {
    NSMutableData *data = (__bridge NSMutableData *)_data;
    [data appendBytes:&byte length:1];
}

static void appendHex(unsigned char byte, void *_data) {
    NSMutableData *data = (__bridge NSMutableData *)_data;
    char bytes[2];
    bytes[1] = i2h[byte % 16];
    bytes[0] = i2h[byte / 16];
    [data appendBytes:bytes length:2];
}

NSData* PandoraDecryptString(NSString *string, NSString *decryptionKey) {
    struct blf_ecb_ctx ctx;
    NSMutableData *mut = [[NSMutableData alloc] init];
    const char *key = decryptionKey.UTF8String;
    
    Blowfish_ecb_start(&ctx, FALSE, (const unsigned char *)key,
                       strlen(key), appendByte,
                       (__bridge void *)mut);
    
    const char *bytes = [string cStringUsingEncoding:NSASCIIStringEncoding];
    NSUInteger len = [string lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
    for (NSUInteger i = 0; i < len; i += 2) {
        Blowfish_ecb_feed(&ctx, h2i[(int) bytes[i]] * 16 + h2i[(int) bytes[i + 1]]);
    }
    Blowfish_ecb_stop(&ctx);
    
    return mut;
}

long PandoraDecryptTime(NSString *string, NSString *decryptionKey) {
    NSData *sync = PandoraDecryptString(string, decryptionKey);
    const char *bytes = [sync bytes];
    long res = strtoul(bytes + 4, NULL, 10);
    long delta = res + ([[NSDate date] timeIntervalSince1970] - res);
    return delta;
}

NSData* PandoraEncryptData(NSData *data, NSString *encryptionKey) {
    struct blf_ecb_ctx ctx;
    NSMutableData *mut = [[NSMutableData alloc] init];
    const char *key = encryptionKey.UTF8String;
    
    Blowfish_ecb_start(&ctx, TRUE, (const unsigned char *)key,
                       strlen(key), appendHex,
                       (__bridge void*)mut);
    
    const char *bytes = [data bytes];
    NSUInteger len = [data length];
    for (NSUInteger i = 0; i < len; i++) {
        Blowfish_ecb_feed(&ctx, bytes[i]);
    }
    Blowfish_ecb_stop(&ctx);
    
    return mut;
}
