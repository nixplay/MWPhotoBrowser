//
//  MWCaptionView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 30/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MWCommon.h"
#import "MWCaptionView.h"
#import "MWPhoto.h"
#import "Masonry.h"
static const CGFloat labelPadding = 10;

// Private
@interface MWCaptionView () {
    id <MWPhoto> _photo;
//    UILabel *_label;
}
@end

@implementation MWCaptionView

- (id)initWithPhoto:(id<MWPhoto>)photo {
    self = [super initWithFrame:CGRectMake(0, 0, 320, 44)]; // Random initial frame
    if (self) {
        self.userInteractionEnabled = NO;
        _photo = photo;
//        self.barStyle = UIBarStyleBlackTranslucent;
//        self.tintColor = nil;
//        self.barTintColor = nil;
//        self.barStyle = UIBarStyleBlackTranslucent;
//        [self setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
//        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [self setupCaption];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat maxHeight = 9999;
    if (self.numberOfLines > 0) maxHeight = self.font.leading*self.numberOfLines;
    CGSize textSize = [self.text boundingRectWithSize:CGSizeMake(size.width - labelPadding*2, maxHeight)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName:self.font}
                                                context:nil].size;
    return CGSizeMake(size.width, textSize.height + labelPadding * 2);
}

- (void)setupCaption {
//    _label = [[UILabel alloc] initWithFrame:CGRectIntegral(CGRectMake(labelPadding, 0,
//                                                       self.bounds.size.width-labelPadding*2,
//                                                       self.bounds.size.height))];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.opaque = NO;
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    self.textAlignment = NSTextAlignmentCenter;
    self.lineBreakMode = NSLineBreakByWordWrapping;

    self.numberOfLines = 0;
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont systemFontOfSize:17];
    if ([_photo respondsToSelector:@selector(caption)]) {
        self.text = [_photo caption] ? [_photo caption] : @" ";
    }
    UIEdgeInsets myLabelInsets = {5, 10, 5, 10};
    [super drawTextInRect:UIEdgeInsetsInsetRect(self.frame, myLabelInsets)];
//    [self addSubview:_label];
//    [_label mas_makeConstraints:^(MASConstraintMaker *make) {
//        if(@available(iOS 11, *)){
//            make.left.equalTo(self.superview.mas_left).with.offset(20);
//            make.right.equalTo(self.superview.mas_right).with.offset(-20);
//            
//            make.top.equalTo(self.superview.mas_top);
//            make.bottom.equalTo(self.superview.mas_bottom);
//        }
//    }];
}


@end
