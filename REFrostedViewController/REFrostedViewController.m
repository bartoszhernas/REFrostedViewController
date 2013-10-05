//
// REFrostedViewController.m
// REFrostedViewController
//
// Copyright (c) 2013 Roman Efimov (https://github.com/romaonthego)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "REFrostedViewController.h"
#import "UIImage+REFrostedViewController.h"
#import "UIView+REFrostedViewController.h"

@interface REFrostedViewController ()

@property (assign, readwrite, nonatomic) CGFloat toolbarViewWidth;
@property (strong, readwrite, nonatomic) UIToolbar *toolbarView;
@property (assign, readwrite, nonatomic) BOOL visible;
@property (assign, readwrite, nonatomic) CGFloat minimumChildViewWidth;

@end

@implementation REFrostedViewController

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    if ((self = [super initWithCoder:coder])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(void)commonInit
{
    self.animationDuration = 0.35f;
    self.blurTintColor = [UIColor colorWithWhite:1 alpha:0.75f];
    self.blurSaturationDeltaFactor = 1.8f;
    self.threshold = 50.0f;
    self.blurRadius = 10.0f;
    self.toolbarView = ({
        UIToolbar *imageView = [[UIToolbar alloc] initWithFrame:CGRectNull];
        imageView.contentMode = UIViewContentModeLeft;
        imageView.clipsToBounds = YES;
        imageView;
    });
    [self.view addSubview:self.toolbarView];
    
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerDidRecognize:)]];
}

- (BOOL)isHidden
{
    return !self.visible;
}

- (void)addToParentViewController:(UIViewController *)parentViewController callingAppearanceMethods:(BOOL)callAppearanceMethods
{
    if (self.parentViewController != nil) {
        [self removeFromParentViewControllerCallingAppearanceMethods:callAppearanceMethods];
    }
    
    if (callAppearanceMethods)
        [self beginAppearanceTransition:YES animated:NO];
    [parentViewController addChildViewController:self];
    [parentViewController.view addSubview:self.view];
    [self didMoveToParentViewController:self];
    if (callAppearanceMethods)
        [self endAppearanceTransition];
}

- (void)removeFromParentViewControllerCallingAppearanceMethods:(BOOL)callAppearanceMethods
{
    if (callAppearanceMethods)
        [self beginAppearanceTransition:NO animated:NO];
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    if (callAppearanceMethods)
        [self endAppearanceTransition];
}

- (void)presentFromViewController:(UIViewController *)controller
{
    self.view.backgroundColor = [UIColor clearColor];
    controller.view.backgroundColor = [UIColor clearColor];
    self.visible = YES;
    self.toolbarViewWidth = 0;
    self.view.frame = controller.view.bounds;
    [self addToParentViewController:controller callingAppearanceMethods:YES];
    
    self.toolbarView.frame = CGRectMake(0, 0, 0, controller.view.frame.size.height);
    
    self.minimumChildViewWidth = self.view.frame.size.width - self.threshold;
    [self updateChildViewLayout];
    [self.view.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        if (![view isEqual:self.toolbarView]) {
            [self.view bringSubviewToFront:view];
            self.view.backgroundColor = [UIColor clearColor];
        }
    }];
}

- (void)presentFromViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void(^)(void))completionHandler
{
    [self presentFromViewController:controller];
    
    void (^completionHandlerBlock)(BOOL finished) = ^(BOOL finished) {
        if (completionHandler)
            completionHandler();
    };
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration animations:^{
            [self updateViewsWithThreshold:self.threshold];
        } completion:completionHandlerBlock];
    } else {
        [self updateViewsWithThreshold:self.threshold];
        completionHandlerBlock(YES);
    }
}

- (void)presentFromViewController:(UIViewController *)controller panGestureRecognizer:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self presentFromViewController:controller];
    } else {
        [self panGestureRecognizerDidRecognize:recognizer];
    }
}



- (void)dismissAnimated:(BOOL)animated animationDuration:(CGFloat)duration completion:(void(^)(void))completionHandler
{
    self.visible = NO;
    void (^hideBlock)(void) = ^{
        [self updateViewsWithThreshold:self.view.frame.size.width];
    };
    void (^completionHandlerBlock)(BOOL finished) = ^(BOOL finished) {
        [self removeFromParentViewControllerCallingAppearanceMethods:YES];
        if (completionHandler)
            completionHandler();
    };
    
    if (animated) {
        [UIView animateWithDuration:duration animations:^{
            hideBlock();
        } completion:completionHandlerBlock];
    } else {
        if (completionHandlerBlock)
            completionHandlerBlock(YES);
    }
}

- (void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    [self dismissAnimated:animated animationDuration:self.animationDuration completion:completion];
}

- (void)updateViewsWithThreshold:(CGFloat)threshold
{
    CGFloat offset = self.view.frame.size.width - threshold;
    
    CGRect frame = self.toolbarView.frame;
    frame.size.width = offset;
    self.toolbarView.frame = frame;
    
    [self updateChildViewLayout];
}

- (void)updateChildViewLayout
{
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UIToolbar class]])
            continue;
        CGFloat width = self.toolbarView.frame.size.width < self.minimumChildViewWidth ? self.minimumChildViewWidth : self.toolbarView.frame.size.width;
        CGFloat x = self.toolbarView.frame.size.width < self.minimumChildViewWidth ? self.toolbarView.frame.size.width - self.minimumChildViewWidth : 0;
        
        CGRect frame = CGRectMake(x, 0, width, self.view.frame.size.height);
        view.frame = frame;
        view.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark -
#pragma mark Button action

- (void)fadedViewPressed:(id)sender
{
    [self dismissAnimated:YES animationDuration:self.animationDuration completion:nil];
}

#pragma mark -
#pragma mark Gesture recognizer

- (void)panGestureRecognizerDidRecognize:(UIPanGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer translationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.toolbarViewWidth = self.toolbarView.frame.size.width;
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        CGFloat offset = self.toolbarViewWidth + point.x;
        if (offset > self.view.frame.size.width)
            offset = self.view.frame.size.width;
        
        if (offset < 0)
            return;
        
        CGRect frame = self.toolbarView.frame;
        frame.size.width = offset;
        self.toolbarView.frame = frame;
        
        [self updateChildViewLayout];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([recognizer velocityInView:self.view].x < 0) {
            [self dismissAnimated:YES animationDuration:0.2f completion:nil];
        } else {
            [UIView animateWithDuration:0.2f animations:^{
                [self updateViewsWithThreshold:self.threshold];
            }];
        }
    }
}

@end
