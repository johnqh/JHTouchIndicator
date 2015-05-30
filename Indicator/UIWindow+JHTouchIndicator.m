//
//  UIWindow+JHTouchIndicator.m
//  JHTouchIndicator
//
//  Created by John Huang on 5/29/15.
//  Copyright (c) 2015 John Huang. All rights reserved.
//

#import "UIWindow+JHTouchIndicator.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSMapTable * _touches = nil;
static UIImage * _blueCircle = nil;

@implementation UIWindow (JHTouchIndicator)

+ (void)enableIndicator
{
    Method method = class_getInstanceMethod(UIWindow.class, @selector(sendEvent:));
    SEL selector = method_getName(method);
    if (method != nil)
    {
        IMP originalImp = method_getImplementation(method);
        
        void(^block)(id self, id event) = ^void(id _self, id _event)
        {
            UIEvent * event = _event;
            UIWindow * window = _self;
            
            if (!_touches)
            {
                _touches = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
            }
            NSSet * touches = [event touchesForWindow:window];
            for (UITouch * touch in touches)
            {
                [window updateTouch:touch];
            }
            
            ((void(*)(id, SEL, id))originalImp)(_self, selector, _event);
            
            
        };
        IMP newImp = imp_implementationWithBlock(block);
        method_setImplementation(method, newImp);
    }
    
}


- (void)updateTouch:(UITouch *)touch
{
    UIImageView * dot = [_touches objectForKey:touch];
    if (dot)
    {
        switch (touch.phase)
        {
            case UITouchPhaseBegan:
            case UITouchPhaseMoved:
            case UITouchPhaseStationary:
            {
                CGPoint pt = [touch locationInView:self];
                CGFloat radius = touch.majorRadius;
                if (radius < 10)
                {
                    radius = 10;
                }
                CGRect frame = CGRectMake(pt.x - radius, pt.y - radius, radius * 2, radius * 2);
                dot.frame = frame;
//                dot.image = self.blueCircle;
                [self bringSubviewToFront:dot];
            }
                break;
                
            case UITouchPhaseCancelled:
            case UITouchPhaseEnded:
            {
//                dot.image = self.blueCircle;
                [_touches removeObjectForKey:touch];
                [dot performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.05];
                //                [dot removeFromSuperview];
            }
                break;
                
            default:
                break;
        }
    }
    else
    {
        switch (touch.phase)
        {
            case UITouchPhaseBegan:
            case UITouchPhaseMoved:
            case UITouchPhaseStationary:
            {
                CGPoint pt = [touch locationInView:self];
                CGFloat radius = touch.majorRadius;
                if (radius < 10)
                {
                    radius = 10;
                }
                CGRect frame = CGRectMake(pt.x - radius, pt.y - radius, radius * 2, radius * 2);
                
                UIImageView * dot = [[UIImageView alloc] initWithFrame:frame];
                dot.image = self.blueCircle;
                dot.userInteractionEnabled = false;
                dot.contentMode = UIViewContentModeScaleToFill;
                [self addSubview:dot];
                [self bringSubviewToFront:dot];
                [_touches setObject:dot forKey:touch];
            }
                break;
                
            default:
                break;
        }
        
    }
}

- (UIImage *)blueCircle
{
    if (!_blueCircle)
    {
        _blueCircle = [self circle:[UIColor blueColor]];
    }
    return _blueCircle;
}

- (UIImage *)circle:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(60, 60), NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGRect rect = CGRectMake(3, 3, 54, 54);
    CGContextSetLineWidth(ctx, 3);
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextStrokeEllipseInRect(ctx, rect);
    
    CGContextRestoreGState(ctx);
    UIImage * circle = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return circle;
}

@end
