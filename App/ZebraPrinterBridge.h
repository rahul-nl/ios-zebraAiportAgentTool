#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZebraPrinterBridge : NSObject

+ (BOOL)printZpl:(NSData *)zplData printerSerial:(NSString *)printerSerial error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END