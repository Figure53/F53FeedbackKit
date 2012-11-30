//
//  FRProgressWindow.h
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/30/12.
//
//

#import <Foundation/Foundation.h>

@interface FRProgressWindow : NSObject
{
    NSWindow              *_window;
    NSTextField           *_textField;
    NSProgressIndicator   *_progressIndicator;
    NSModalSession        _modalSession;
}
@property(nonatomic, readwrite, retain) NSWindow *window;
@property(nonatomic, readwrite, retain) NSTextField *textField;
@property(nonatomic, readwrite, retain) NSProgressIndicator *progressIndicator;
@property(nonatomic, readwrite) NSModalSession modalSession;

- (id)initWithText:(NSString *)text;
- (void)show;
- (void)hide;

@end
