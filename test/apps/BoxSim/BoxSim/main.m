//
//  main.m
//  BoxSim
//
//  Copyright 2016 PreEmptive Solutions, LLC
//  See LICENSE.txt for licensing information
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

// A -> B by property type
@class BSClassB;

@interface BSClassA : NSObject
@property (atomic) int squaredA;
- (void)methodA:(int)value;
@property (atomic) BSClassB * chainA2B;
@end
@implementation BSClassA
- (void)methodA:(int)value { _squaredA = value * value; }
@end

@interface BSClassB : NSObject
@property (atomic) int squaredB;
- (void)methodB:(int)value;
@end
@implementation BSClassB
- (void)methodB:(int)value { _squaredB = value * value; }
@end

// C -> D by method return type
@class BSClassD;

@interface BSClassC : NSObject
@property (atomic) int squaredC;
- (void)methodC:(int)value;
- (BSClassD *)chainC2D;
@end
@implementation BSClassC
- (void)methodC:(int)value { _squaredC = value * value; }
- (BSClassD *)chainC2D { return nil; }
@end

@interface BSClassD : NSObject
@property (atomic) int squaredD;
- (void)methodD:(int)value;
@end
@implementation BSClassD
- (void)methodD:(int)value { _squaredD = value * value; }
@end

// E -> F by method parameter type
@class BSClassF;

@interface BSClassE : NSObject
@property (atomic) int squaredE;
- (void)methodE:(int)value;
- (void)chainE2F:(BSClassF *)ignored;
@end
@implementation BSClassE
- (void)methodE:(int)value { _squaredE = value * value; }
- (void)chainE2F:(BSClassF *)ignored {}
@end

@interface BSClassF : NSObject
@property (atomic) int squaredF;
- (void)methodF:(int)value;
@end
@implementation BSClassF
- (void)methodF:(int)value { _squaredF = value * value; }
@end

// G -> H by protocol usage
@protocol BSClassH
- (void)methodH:(int)value;
@end

@interface BSClassG : NSObject <BSClassH>
@property (atomic) int squaredG;
- (void)methodG:(int)value;
@property id<BSClassH> chainG2H;
@end
@implementation BSClassG
- (void)methodG:(int)value { _squaredG = value * value; }
- (void)methodH:(int)value { [self methodG:value]; }
@end

// I -> J by subclassing
@class BSClassI;
@class BSClassJ;

@interface BSClassJ : NSObject
@property (atomic) int squaredJ;
- (void)methodJ:(int)value;
@end
@implementation BSClassJ
- (void)methodJ:(int)value { _squaredJ = value * value; }
@end

@interface BSClassI : BSClassJ
@property (atomic) int squaredI;
- (void)methodI:(int)value;
@end
@implementation BSClassI
- (void)methodI:(int)value { _squaredI = value * value; }
@end


@interface NSString (MoreTrimmable)
- (NSString *)trimEvenMore;
@end
@implementation NSString (MoreTrimmable)
- (NSString *)trimEvenMore
{
    return [NSString stringWithString:self];
}
@end


int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
