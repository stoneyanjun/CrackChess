//
//  OpenCVWrapper.h
//  CrackChess
//
//  Created by stone on 2025/11/11.
//

#import "OpenCVPrefix.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+ (NSImage *)convertToGrayscale:(NSImage *)image;
+ (NSString *)openCVVersionString;
@end

NS_ASSUME_NONNULL_END
