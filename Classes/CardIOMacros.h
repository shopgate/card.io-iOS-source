//
//  CardIOMacros.h
//  See the file "LICENSE.md" for the full license governing this code.
//

// CardIOLog is a replacement for NSLog that logs iff CARDIO_DEBUG is set.
// CardIOLogWithLevel will always log

#if CARDIO_DEBUG
#import "CardIOLogger.h"
#define CardIOLog(format, args...) [CardIOLogger logMessage:format, ## args];
#else
#define CardIOLog(format, args...)
#endif
#define CardIOLogWithLevel(level,format, args...) [CardIOLogger logWithLevel:level message:format, ## args]
#define CardIOLogVerbose(format, args...) [CardIOLogger logWithLevel:CardIOLogLevelVerbose message:format, ## args]
#define CardIOLogDebug(format, args...) [CardIOLogger logWithLevel:CardIOLogLevelDebug message:format, ## args]
#define CardIOLogInfo(format, args...) [CardIOLogger logWithLevel:CardIOLogLevelInfo message:format, ## args]
#define CardIOLogWarn(format, args...) [CardIOLogger logWithLevel:CardIOLogLevelWarning message:format, ## args]
#define CardIOLogError(format, args...) [CardIOLogger logWithLevel:CardIOLogLevelError message:format, ## args]

@interface CardIOMacros : NSObject

+ (id)localSettingForKey:(NSString *)key defaultValue:(NSString *)defaultValue productionValue:(NSString *)productionValue;

+ (NSUInteger)deviceSystemMajorVersion;

+ (BOOL)appHasViewControllerBasedStatusBar;

@end

#define iOS_MAJOR_VERSION  [CardIOMacros deviceSystemMajorVersion]
#define iOS_8_PLUS         (iOS_MAJOR_VERSION >= 8)
#define iOS_7_PLUS         (iOS_MAJOR_VERSION >= 7)
#define iOS_6              (iOS_MAJOR_VERSION == 6)
#define iOS_5              (iOS_MAJOR_VERSION == 5)




#define IS_CARDIOOUTPUT(output) [[output class] isSubclassOfClass:[CardIOOutput class]]
#define ClassStringFromObject(object) NSStringFromClass([object class])