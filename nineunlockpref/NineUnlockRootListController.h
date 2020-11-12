#import <Preferences/PSListController.h>

@interface NineUnlockRootListController : PSListController

@property (nonatomic, retain) UIBarButtonItem *respringButton;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIImageView *iconView;
@property (nonatomic, retain) NSMutableDictionary *savedSpecifiers;
- (void)respring:(id)sender;

@end
