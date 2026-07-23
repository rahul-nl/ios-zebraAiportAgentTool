#import "ZebraPrinterBridge.h"

#if __has_include("MfiBtPrinterConnection.h")
#import "MfiBtPrinterConnection.h"
#define ZEBRA_SDK_AVAILABLE 1
#else
#define ZEBRA_SDK_AVAILABLE 0
#endif

@implementation ZebraPrinterBridge

+ (BOOL)printZpl:(NSData *)zplData printerSerial:(NSString *)printerSerial error:(NSError * _Nullable __autoreleasing *)error {
#if ZEBRA_SDK_AVAILABLE
    MfiBtPrinterConnection *connection = [[MfiBtPrinterConnection alloc] initWithSerialNumber:printerSerial];
    BOOL opened = [connection open];
    if (!opened) {
        if (error) {
            *error = [NSError errorWithDomain:@"ZebraPrinterBridge"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unable to open Zebra Bluetooth connection for serial: %@", printerSerial]}];
        }
        return NO;
    }

    @try {
        NSError *writeError = nil;
        BOOL writeSucceeded = [connection write:zplData error:&writeError];
        if (writeError) {
            if (error) {
                *error = writeError;
            }
            return NO;
        }

        if (!writeSucceeded && error) {
            *error = [NSError errorWithDomain:@"ZebraPrinterBridge"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"Zebra print write failed: write returned false"}];
        }

        return writeSucceeded;
    } @finally {
        [connection close];
    }
#else
    if (error) {
        *error = [NSError errorWithDomain:@"ZebraPrinterBridge"
                                     code:1000
                                 userInfo:@{NSLocalizedDescriptionKey: @"Zebra SDK is not linked. Add ZSDK_API.xcframework to your Xcode target."}];
    }
    return NO;
#endif
}

@end