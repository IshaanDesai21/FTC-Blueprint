#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Swift's `do/catch` only catches Swift `Error`s, it cannot catch Objective-C
/// `NSException`s, which is what SceneKit/Model I/O raise on malformed 3D files.
/// An uncaught NSException terminates the process (SIGABRT), bypassing any
/// surrounding Swift `do/catch`. This shim traps it at the Objective-C layer
/// so it can be surfaced as a normal Swift error instead of crashing the app.
@interface ExceptionCatcher : NSObject

+ (BOOL)catchException:(void (NS_NOESCAPE ^)(void))tryBlock error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
