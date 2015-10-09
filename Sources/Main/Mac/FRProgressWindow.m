//
//  FRProgressWindow.m
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/30/12.
//
//

#import "FRProgressWindow.h"

@implementation FRProgressWindow

- (instancetype) initWithText:(NSString *)text
{
    self = [super init];
    if (self) {
        [self finishInitWithText:text];
    }
    return self;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self finishInitWithText:@""];
    }
    return self;
}

- (void) finishInitWithText:(NSString *)text
{
    const CGFloat windowWidth = 300.0;
    const CGFloat textHeight = 20.0;
    const CGFloat margin = 20.0;
    CGFloat windowHeight = (textHeight * 2.0) + (margin * 3.0);
    
    NSTextField *tf = [[NSTextField alloc] initWithFrame:NSMakeRect(margin, windowHeight - margin - textHeight, windowWidth - (margin * 2.0), textHeight)];
    [tf setStringValue:text];
    [tf setEditable:NO];
    [tf setSelectable:NO];
    [tf setAlignment:NSCenterTextAlignment];
    [tf setFont:[NSFont labelFontOfSize:14.0]];
    [tf setBordered:NO];
    [tf setBackgroundColor:[NSColor clearColor]];
    [self setTextField:tf];
    
    NSProgressIndicator *progIndic = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(windowWidth / 8.0, windowHeight - ((margin + textHeight) * (CGFloat)2.0), windowWidth * 3.0 / 4.0, textHeight)];
    [progIndic setStyle:NSProgressIndicatorBarStyle];
    [progIndic setUsesThreadedAnimation:YES];
    [progIndic setIndeterminate:YES];
    [self setProgressIndicator:progIndic];
    
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, windowWidth, windowHeight) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:YES];
    [[window contentView] addSubview:[self textField]];
    [[window contentView] addSubview:[self progressIndicator]];
    [self setWindow:window];
}

- (void) show
{
    [self setModalSession:[[NSApplication sharedApplication] beginModalSessionForWindow:[self window]]];
    [[self progressIndicator] startAnimation:self];
}

- (void) hide
{
    [[self progressIndicator] stopAnimation:self];
    [[NSApplication sharedApplication] endModalSession:[self modalSession]];
    [[self window] orderOut:self];
}

@end
