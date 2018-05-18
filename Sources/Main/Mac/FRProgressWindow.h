//
//  FRProgressWindow.h
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/30/12.
//
//


NS_ASSUME_NONNULL_BEGIN

@interface FRProgressWindow : NSObject

@property (nonatomic, strong)   NSWindow *window;
@property (nonatomic, strong)   NSTextField *textField;
@property (nonatomic, strong)   NSProgressIndicator *progressIndicator;
@property (nonatomic)           NSModalSession modalSession;

- (instancetype) initWithText:(NSString *)text;
- (void) show;
- (void) hide;

@end

NS_ASSUME_NONNULL_END
