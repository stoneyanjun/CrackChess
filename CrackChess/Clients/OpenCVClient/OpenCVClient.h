//
//  OpenCVClient.h
//  CrackChess
//
//  Created by stone on 2025/11/11.
//

#import "OpenCVPrefix.h"
#import <Foundation/Foundation.h>

/*
NS_ASSUME_NONNULL_BEGIN

/// Forward declare CGImageRef to avoid importing CoreGraphics in header.
typedef struct CGImage *CGImageRef;

@interface OpenCVClient : NSObject

/// Fallback board-quad detection using OpenCV (Canny -> contours -> approxPolyDP).
/// @param image       Input CGImage
/// @param cannyLow    Canny low threshold (e.g., 80)
/// @param cannyHigh   Canny high threshold (e.g., 160)
/// @param kernel3     Morph kernel size (e.g., 3; 0 to disable)
/// @param minAreaFrac Minimal area fraction of the candidate quad vs image (e.g., 0.22)
/// @return NSDictionary or nil on failure.
///         Keys:
///           - @"quad": NSArray<NSValue*> of CGPoint (ordered: tl,tr,br,bl)
///           - @"score": NSNumber (0~1)
+ (nullable NSDictionary *)detectBoardQuadFromCGImage:(CGImageRef)image
                                            cannyLow:(int)cannyLow
                                           cannyHigh:(int)cannyHigh
                                        morphKernel3:(int)kernel3
                                    minAreaFraction:(double)minAreaFrac;

/// Perspective warp to a rectified square board (outW x outH).
/// @param image    Input CGImage
/// @param quad     NSArray<NSValue*> of CGPoint in order (tl,tr,br,bl)
/// @param outW     Output width (e.g., 1024)
/// @param outH     Output height (e.g., 1024)
/// @return NSDictionary with:
///           - @"image": CGImage (rectified)
///           - @"H": NSArray<NSNumber*> of 9 doubles (row-major 3x3 homography)
+ (nullable NSDictionary *)warpBoard:(CGImageRef)image
                                quad:(NSArray<NSValue*>*)quad
                            outWidth:(int)outW
                           outHeight:(int)outH;

@end

NS_ASSUME_NONNULL_END
*/

NS_ASSUME_NONNULL_BEGIN
typedef struct CGImage *CGImageRef;

@interface OpenCVClient : NSObject
+ (nullable NSDictionary *)detectBoardQuadFromCGImage:(CGImageRef)image
                                            cannyLow:(int)cannyLow
                                           cannyHigh:(int)cannyHigh
                                        morphKernel3:(int)kernel3
                                    minAreaFraction:(double)minAreaFrac;

+ (nullable NSDictionary *)warpBoard:(CGImageRef)image
                                quad:(NSArray<NSValue*>*)quad   // NSValue(valueWithPoint:)
                            outWidth:(int)outW
                           outHeight:(int)outH;
@end

NS_ASSUME_NONNULL_END
