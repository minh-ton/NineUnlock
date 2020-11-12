#import <Preferences/PSHeaderFooterView.h>

@interface NineUnlockRootHeaderView : UITableViewHeaderFooterView <PSHeaderFooterView> {
	UIImageView* _headerImageView;
	CGFloat _currentWidth;
	CGFloat _aspectRatio;
}

@end
