//
//  OpenCVPrefix.h
//  CrackChess
//
//  Created by stone on 2025/11/11.
//

#pragma once

// ----------------------------------------------------
// Fix for macOS Objective-C macro pollution
// ----------------------------------------------------
#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#endif

#ifdef YES
#undef YES
#endif
#ifdef NO
#undef NO
#endif
#ifdef check
#undef check
#endif
#ifdef interface
#undef interface
#endif
#ifdef ERROR
#undef ERROR
#endif
#ifdef SUCCESS
#undef SUCCESS
#endif
#ifdef Status
#undef Status
#endif
#ifdef min
#undef min
#endif
#ifdef max
#undef max
#endif
