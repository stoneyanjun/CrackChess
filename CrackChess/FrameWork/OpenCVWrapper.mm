//
//  OpenCVWrapper.mm
//  CrackChess (macOS)
//
//  Created by stone on 2025/11/11.
//
//  This file acts as the Objective-C++ bridge between Swift/NSImage and OpenCV/cv::Mat.


#import "OpenCVWrapper.h"
#import "OpenCVWrapper_Internal.h"  // ✅ only used here
#import <opencv2/opencv.hpp>
#import <Cocoa/Cocoa.h>        // For NSImage
#import <CoreGraphics/CoreGraphics.h> // For accessing pixel data
#import <Foundation/Foundation.h>

// We remove: #import <opencv2/imgcodecs/ios.h> as it is for iOS.

using namespace cv;

// --- Helper Functions for NSImage <-> cv::Mat Conversion ---
// These functions use Core Graphics to access and modify pixel data.

// 1. Converts NSImage to cv::Mat
static cv::Mat nsImageToMat(NSImage *image) {
    if (!image) {
        return cv::Mat();
    }
    
    // Get the CGImageRef from the NSImage
    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:NULL hints:NULL];
    if (!cgImage) {
        NSLog(@"[OpenCVWrapper] Error: Could not get CGImage from NSImage.");
        return cv::Mat();
    }

    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    // Core Graphics uses 8 bits per component (typically 4 components: BGRA)
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create an OpenCV Mat (4-channel BGRA)
    cv::Mat mat(height, width, CV_8UC4);
    
    // Create a graphics context for drawing the CGImage into our Mat's memory
    CGContextRef context = CGBitmapContextCreate(
        mat.data,
        width,
        height,
        bitsPerComponent,
        bytesPerRow,
        colorSpace,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host // BGRA
    );
    
    if (!context) {
        NSLog(@"[OpenCVWrapper] Error: Could not create CGBitmapContext.");
        CGColorSpaceRelease(colorSpace);
        return cv::Mat();
    }
    
    // Draw the CGImage into the context, which directly loads data into mat.data
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(context, rect, cgImage);

    // Clean up
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    return mat;
}

// 2. Converts cv::Mat to NSImage
static NSImage *matToNSImage(const cv::Mat& mat) {
    if (mat.empty()) {
        return nil;
    }
    
    // We assume the input mat is 8-bit, single or multi-channel
    int matType = mat.type();
    
    // If the mat is grayscale (1 channel), convert it to 4 channels (BGRA) for NSImage compatibility
    cv::Mat convertedMat;
    if (matType == CV_8UC1) {
        // Grayscale (1-channel) to BGRA (4-channel)
        cvtColor(mat, convertedMat, COLOR_GRAY2BGRA);
    } else if (matType == CV_8UC3) {
        // BGR (3-channel) to BGRA (4-channel)
        cvtColor(mat, convertedMat, COLOR_BGR2BGRA);
    } else if (matType == CV_8UC4) {
        // Already BGRA (4-channel)
        convertedMat = mat;
    } else {
        NSLog(@"[OpenCVWrapper] Error: Unsupported Mat type for NSImage conversion.");
        return nil;
    }

    size_t width = convertedMat.cols;
    size_t height = convertedMat.rows;
    size_t bytesPerRow = convertedMat.step[0];
    
    // Create a data provider
    CGDataProviderRef provider = CGDataProviderCreateWithData(
        NULL,
        convertedMat.data,
        height * bytesPerRow,
        NULL
    );
    
    // Create the CGImage
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(
        width,
        height,
        8, // bitsPerComponent
        32, // bitsPerPixel (8 * 4 channels)
        bytesPerRow,
        colorSpace,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host,
        provider,
        NULL,
        false,
        kCGRenderingIntentDefault
    );

    // Clean up
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    if (!cgImage) {
        NSLog(@"[OpenCVWrapper] Error: Could not create CGImage from Mat.");
        return nil;
    }

    // Create the NSImage
    NSSize size = NSMakeSize((CGFloat)width, (CGFloat)height);
    NSImage *image = [[NSImage alloc] initWithCGImage:cgImage size:size];

    // Clean up CGImage
    CGImageRelease(cgImage);

    return image;
}

// --- Objective-C++ Wrapper Implementation ---

@implementation OpenCVWrapper

+ (NSImage *)convertToGrayscale:(NSImage *)image {
    if (!image) {
        return nil;
    }
    
    // 1. Convert NSImage to cv::Mat (BGRA 4-channel)
    cv::Mat inputMat = nsImageToMat(image);
    
    if (inputMat.empty()) {
        NSLog(@"[OpenCVWrapper] Error: Input Mat is empty after conversion.");
        return nil;
    }

    // 2. Perform OpenCV operation: Convert BGRA to Grayscale (1-channel)
    cv::Mat grayMat;
    // BGRA -> Grayscale
    cv::cvtColor(inputMat, grayMat, cv::COLOR_BGRA2GRAY);

    // 3. Convert cv::Mat back to NSImage (The helper function handles 1-channel Mat)
    NSImage *grayImage = matToNSImage(grayMat);

    return grayImage;
}

+ (NSString *)openCVVersionString {
    // Simple function to confirm the link works
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

@end
