//
//  AVPlayerView.h
//  MWPhotoBrowser
//
//  Created by James Kong on 19/3/2018.
//

@import UIKit;
@import AVKit;
@class AVPlayer;

@interface AVPlayerView : UIView
@property AVPlayer *player;
@property (readonly) AVPlayerLayer *playerLayer;
@end

