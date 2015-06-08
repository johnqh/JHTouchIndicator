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
static char _eventViewKey = 0;
static bool _highlighting = false;

@implementation UIWindow (JHTouchIndicator)

+ (void)enableIndicator
{
    Method method = class_getInstanceMethod(UIWindow.class, @selector(sendEvent:));
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
            
            SEL selector = method_getName(method);
            ((void(*)(id, SEL, id))originalImp)(_self, selector, _event);
        };
        IMP newImp = imp_implementationWithBlock(block);
        method_setImplementation(method, newImp);
    }
//    [self enableHighlighting];
}

+ (void)enableHighlighting
{
    _highlighting = true;
}

- (void)addEventView:(UIView *)view
{
    if (_highlighting)
    {
        NSMapTable * eventViews = objc_getAssociatedObject(self, &_eventViewKey);
        if (!eventViews)
        {
            eventViews = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
            objc_setAssociatedObject(self, &_eventViewKey, eventViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        UIImageView * imageView = [eventViews objectForKey:view];
        if (!imageView)
        {
            imageView = [[UIImageView alloc] init];
            [eventViews setObject:imageView forKey:view];
            [self addSubview:imageView];
        }
        CGRect viewFrame = [view convertRect:view.bounds toView:nil];
        UIImage * image = [self rectImage:viewFrame];
        imageView.image = image;
        imageView.frame = viewFrame;
        [self bringSubviewToFront:imageView];
    }
}

- (void)removeEventView:(UIView *)view
{
    if (_highlighting)
    {
        NSMapTable * eventViews = objc_getAssociatedObject(self, &_eventViewKey);
        if (eventViews)
        {
            UIImageView * imageView = [eventViews objectForKey:view];
            if (imageView)
            {
                [eventViews removeObjectForKey:view];
                [imageView removeFromSuperview];
            }
        }
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
                
                [self addEventView:touch.view];
            }
                break;
                
            case UITouchPhaseCancelled:
            case UITouchPhaseEnded:
            {
//                dot.image = self.blueCircle;
                [_touches removeObjectForKey:touch];
                [dot performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.05];
                //                [dot removeFromSuperview];
                
                [self removeEventView:touch.view];
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
                
                
                [self addEventView:touch.view];
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


- (UIImage *)rectImage:(CGRect)rect
{
    UIColor * color = [UIColor redColor];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(rect.size.width, 60), NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextStrokeRectWithWidth(ctx, rect, 2);
    
    CGContextRestoreGState(ctx);
    UIImage * circle = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return circle;
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
