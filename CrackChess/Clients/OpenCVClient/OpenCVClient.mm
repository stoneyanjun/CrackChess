//
//  OpenCVClient.mm
//  CrackChess
//
//  Created by stone on 2025/11/11.
//

// OpenCVClient.mm
// Objective-C++ implementation for CrackChess OpenCV bridge.

#define __ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORES 0

#import "OpenCVClient.h"

// Bring CoreGraphics only here (not in header) to avoid symbol collisions.
#import <CoreGraphics/CoreGraphics.h>

// Explicit OpenCV includes (avoid using the mega-header only)
#import <opencv2/core/mat.hpp>
#import <opencv2/core/types.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/imgcodecs.hpp>
// Optionally include the aggregate header if your xcframework ships it
#import <opencv2/opencv.hpp>

#import <vector>
#import <algorithm>
#import <cmath>

/*
static inline cv::Mat CGImageToMatRGBA(CGImageRef image) {
    if (!image) return cv::Mat();

    const size_t w = CGImageGetWidth(image);
    const size_t h = CGImageGetHeight(image);

    cv::Mat rgba((int)h, (int)w, CV_8UC4);

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
        rgba.data, w, h, 8, rgba.step,
        cs, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault
    );
    CGColorSpaceRelease(cs);

    if (!ctx) return cv::Mat();

    CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), image);
    CGContextRelease(ctx);
    return rgba;
}

static inline id MatRGBAtoCGImageObj(const cv::Mat &rgba) {
    if (rgba.empty() || rgba.type() != CV_8UC4) return nil;

    const int w = rgba.cols;
    const int h = rgba.rows;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef outCtx = CGBitmapContextCreate(
        (void*)rgba.data, w, h, 8, rgba.step, colorSpace,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault
    );
    CGColorSpaceRelease(colorSpace);
    if (!outCtx) return nil;

    CGImageRef outImg = CGBitmapContextCreateImage(outCtx);
    CGContextRelease(outCtx);

    // Transfer to ARC-managed object
    id obj = CFBridgingRelease(outImg);
    return obj;
}

static inline void orderQuad(std::vector<cv::Point2f> &pts) {
    // Expect 4 points, order: top-left, top-right, bottom-right, bottom-left
    std::sort(pts.begin(), pts.end(), [](const cv::Point2f &a, const cv::Point2f &b){
        if (a.y == b.y) return a.x < b.x;
        return a.y < b.y;
    });
    std::vector<cv::Point2f> upper = { pts[0], pts[1] };
    std::vector<cv::Point2f> lower = { pts[2], pts[3] };
    std::sort(upper.begin(), upper.end(), [](auto &a, auto &b){ return a.x < b.x; });
    std::sort(lower.begin(), lower.end(), [](auto &a, auto &b){ return a.x < b.x; });
    pts = { upper[0], upper[1], lower[1], lower[0] };
}

@implementation OpenCVClient

+ (nullable NSDictionary *)detectBoardQuadFromCGImage:(CGImageRef)image
                                            cannyLow:(int)cannyLow
                                           cannyHigh:(int)cannyHigh
                                        morphKernel3:(int)kernel3
                                    minAreaFraction:(double)minAreaFrac
{
    if (!image) return nil;

    cv::Mat rgba = CGImageToMatRGBA(image);
    if (rgba.empty()) return nil;

    const double imgArea = (double)rgba.cols * (double)rgba.rows;

    cv::Mat gray, edges;
    cv::cvtColor(rgba, gray, cv::COLOR_RGBA2GRAY);
    cv::GaussianBlur(gray, gray, cv::Size(5,5), 0);
    cv::Canny(gray, edges, std::max(0, cannyLow), std::max(cannyHigh, cannyLow+1));

    if (kernel3 > 0) {
        cv::Mat k = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(kernel3, kernel3));
        cv::dilate(edges, edges, k);
        cv::erode(edges, edges, k);
    }

    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(edges.clone(), contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

    double bestScore = -1.0;
    std::vector<cv::Point2f> bestQuad;

    for (auto &c : contours) {
        double area = std::fabs(cv::contourArea(c));
        if (area < imgArea * std::max(0.0, minAreaFrac)) continue;

        std::vector<cv::Point> approx;
        cv::approxPolyDP(c, approx, cv::arcLength(c, true)*0.02, true);
        if (approx.size() != 4) continue;
        if (!cv::isContourConvex(approx)) continue;

        std::vector<cv::Point2f> quad;
        quad.reserve(4);
        for (auto &p : approx) quad.emplace_back((float)p.x, (float)p.y);
        orderQuad(quad);

        auto dist = [](cv::Point2f a, cv::Point2f b){
            return std::hypot((double)a.x - b.x, (double)a.y - b.y);
        };
        double wTop = dist(quad[0], quad[1]);
        double wBot = dist(quad[3], quad[2]);
        double hL   = dist(quad[0], quad[3]);
        double hR   = dist(quad[1], quad[2]);
        double wAvg = (wTop + wBot) * 0.5;
        double hAvg = (hL   + hR  ) * 0.5;

        // Squareness 0..1
        double sq = (std::min(wAvg, hAvg) / std::max(wAvg, hAvg));
        double areaFrac = area / imgArea;

        // Score: squareness × normalized areaFrac (normalize to 0.22 baseline)
        double score = sq * std::min(1.0, std::max(0.0, areaFrac / 0.22));
        if (score > bestScore) {
            bestScore = score;
            bestQuad = quad;
        }
    }

    if (bestScore < 0.0 || bestQuad.size() != 4) return nil;

    // Pack quad as NSArray<NSValue*> (NSPoint on macOS)
    NSMutableArray<NSValue*> *nsPts = [NSMutableArray arrayWithCapacity:4];
    for (auto &p : bestQuad) {
        NSPoint np = NSMakePoint(p.x, p.y);
        [nsPts addObject:[NSValue valueWithPoint:np]];
    }

    return @{
        @"quad": nsPts,
        @"score": @(std::min(1.0, std::max(0.0, bestScore)))
    };
}

+ (nullable NSDictionary *)warpBoard:(CGImageRef)image
                                quad:(NSArray<NSValue*>*)quad
                            outWidth:(int)outW
                           outHeight:(int)outH
{
    if (!image || quad.count != 4 || outW <= 0 || outH <= 0) return nil;

    cv::Mat rgba = CGImageToMatRGBA(image);
    if (rgba.empty()) return nil;

    std::vector<cv::Point2f> src;
    src.reserve(4);
    for (NSValue *v in quad) {
        NSPoint np = [v pointValue];
        CGPoint p = NSPointToCGPoint(np);
        src.emplace_back((float)p.x, (float)p.y);
    }
    
    // Ensure order: tl, tr, br, bl
    orderQuad(src);

    std::vector<cv::Point2f> dst = {
        {0.f, 0.f},
        {(float)outW - 1.f, 0.f},
        {(float)outW - 1.f, (float)outH - 1.f},
        {0.f, (float)outH - 1.f}
    };

    cv::Mat H = cv::getPerspectiveTransform(src, dst); // 3x3, CV_64F
    cv::Mat out(outH, outW, CV_8UC4);
    cv::warpPerspective(rgba, out, H, out.size(), cv::INTER_CUBIC, cv::BORDER_REPLICATE);

    id imgObj = MatRGBAtoCGImageObj(out);
    if (!imgObj) return nil;

    // Export H (row-major doubles)
    NSMutableArray<NSNumber*> *hVals = [NSMutableArray arrayWithCapacity:9];
    for (int r=0; r<3; ++r) {
        for (int c=0; c<3; ++c) {
            hVals[r*3 + c] = @(H.at<double>(r, c));
        }
    }

    return @{
        @"image": imgObj,  // CGImage bridged to ARC object
        @"H": hVals
    };
}

@end
*/


static inline cv::Mat CGImageToMatRGBA(CGImageRef image) {
    if (!image) return cv::Mat();
    size_t w = CGImageGetWidth(image), h = CGImageGetHeight(image);
    cv::Mat rgba((int)h, (int)w, CV_8UC4);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(rgba.data, w, h, 8, rgba.step, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGColorSpaceRelease(cs);
    if (!ctx) return cv::Mat();
    CGContextDrawImage(ctx, CGRectMake(0,0,w,h), image);
    CGContextRelease(ctx);
    return rgba;
}

static inline id MatRGBAtoCGImageObj(const cv::Mat &rgba) {
    if (rgba.empty() || rgba.type() != CV_8UC4) return nil;
    int w = rgba.cols, h = rgba.rows;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate((void*)rgba.data, w, h, 8, rgba.step, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGColorSpaceRelease(cs);
    if (!ctx) return nil;
    CGImageRef out = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return CFBridgingRelease(out);
}

static inline void orderQuad(std::vector<cv::Point2f> &pts) {
    std::sort(pts.begin(), pts.end(), [](auto &a, auto &b){ return (a.y==b.y)? a.x<b.x : a.y<b.y; });
    std::vector<cv::Point2f> u{pts[0],pts[1]}, l{pts[2],pts[3]};
    std::sort(u.begin(), u.end(), [](auto&a,auto&b){return a.x<b.x;});
    std::sort(l.begin(), l.end(), [](auto&a,auto&b){return a.x<b.x;});
    pts = {u[0],u[1],l[1],l[0]};
}

@implementation OpenCVClient

+ (nullable NSDictionary *)detectBoardQuadFromCGImage:(CGImageRef)image
                                            cannyLow:(int)cannyLow
                                           cannyHigh:(int)cannyHigh
                                        morphKernel3:(int)kernel3
                                    minAreaFraction:(double)minAreaFrac {
    if (!image) return nil;
    cv::Mat rgba = CGImageToMatRGBA(image);
    if (rgba.empty()) return nil;

    const double imgArea = (double)rgba.cols * (double)rgba.rows;
    cv::Mat gray, edges;
    cv::cvtColor(rgba, gray, cv::COLOR_RGBA2GRAY);
    cv::GaussianBlur(gray, gray, cv::Size(5,5), 0);
    cv::Canny(gray, edges, std::max(0, cannyLow), std::max(cannyHigh, cannyLow+1));
    if (kernel3 > 0) {
        cv::Mat k = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(kernel3, kernel3));
        cv::dilate(edges, edges, k);
        cv::erode(edges, edges, k);
    }

    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(edges.clone(), contours, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);

    double bestScore = -1.0;
    std::vector<cv::Point2f> bestQuad;

    for (auto &c : contours) {
        double area = std::fabs(cv::contourArea(c));
        if (area < imgArea * std::max(0.0, minAreaFrac)) continue;

        std::vector<cv::Point> approx;
        cv::approxPolyDP(c, approx, cv::arcLength(c, true)*0.02, true);
        if (approx.size() != 4) continue;
        if (!cv::isContourConvex(approx)) continue;

        std::vector<cv::Point2f> q; q.reserve(4);
        for (auto &p : approx) q.emplace_back((float)p.x, (float)p.y);
        orderQuad(q);

        auto dist = [](cv::Point2f a, cv::Point2f b){ return std::hypot((double)a.x-b.x, (double)a.y-b.y); };
        double wTop = dist(q[0], q[1]), wBot = dist(q[3], q[2]);
        double hL = dist(q[0], q[3]), hR = dist(q[1], q[2]);
        double wAvg = (wTop+wBot)*0.5, hAvg = (hL+hR)*0.5;
        double sq = std::min(wAvg, hAvg) / std::max(wAvg, hAvg);
        double areaFrac = area / imgArea;
        double score = sq * std::min(1.0, std::max(0.0, areaFrac/0.22));

        if (score > bestScore) { bestScore = score; bestQuad = q; }
    }

    if (bestScore < 0.0 || bestQuad.size() != 4) return nil;

    NSMutableArray<NSValue*> *nsPts = [NSMutableArray arrayWithCapacity:4];
    for (auto &p : bestQuad) {
        NSPoint np = NSMakePoint(p.x, p.y);
        [nsPts addObject:[NSValue valueWithPoint:np]]; // macOS：NSValue+NSPoint
    }
    return @{@"quad": nsPts, @"score": @(std::min(1.0, std::max(0.0, bestScore)))};
}

+ (nullable NSDictionary *)warpBoard:(CGImageRef)image
                                quad:(NSArray<NSValue*>*)quad
                            outWidth:(int)outW
                           outHeight:(int)outH {
    if (!image || quad.count != 4 || outW <= 0 || outH <= 0) return nil;
    cv::Mat rgba = CGImageToMatRGBA(image);
    if (rgba.empty()) return nil;

    std::vector<cv::Point2f> src; src.reserve(4);
    for (NSValue *v in quad) {
        NSPoint np = [v pointValue]; // macOS
        src.emplace_back((float)np.x, (float)np.y);
    }
    orderQuad(src);

    std::vector<cv::Point2f> dst = {
        {0.f, 0.f}, {(float)outW-1, 0.f}, {(float)outW-1, (float)outH-1}, {0.f, (float)outH-1}
    };

    cv::Mat H = cv::getPerspectiveTransform(src, dst);
    cv::Mat out(outH, outW, CV_8UC4);
    cv::warpPerspective(rgba, out, H, out.size(), cv::INTER_CUBIC, cv::BORDER_REPLICATE);

    id imgObj = MatRGBAtoCGImageObj(out);
    if (!imgObj) return nil;

    NSMutableArray<NSNumber*> *hVals = [NSMutableArray arrayWithCapacity:9];
    for (int r=0;r<3;r++) for (int c=0;c<3;c++) hVals[r*3+c] = @(H.at<double>(r,c));
    return @{@"image": imgObj, @"H": hVals};
}
@end
