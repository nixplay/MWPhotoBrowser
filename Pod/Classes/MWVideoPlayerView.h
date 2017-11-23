//
//  VideoPlayerView.h
//  MWPhotoBrowser
//
//  Created by James Kong on 21/11/2017.
//

#import <UIKit/UIKit.h>
@import AVKit;
@import AVFoundation;

@interface MWVideoPlayerView : UIView{
@protected
    AVPlayer *player;
    AVPlayerItem *playerItem;
    AVPlayerLayer *playerLayer;
    NSTimer *playbackTimeCheckerTimer;
    CGFloat videoPlaybackPosition;
    UIView *videoPlayer;
    UIView *videoLayer;
    NSString *tempVideoPath;
    AVAsset *asset;
    BOOL isPlaying;
}

@property (nonatomic , strong) AVPlayer *player;
@property (nonatomic , strong) AVPlayerItem *playerItem;
@property (nonatomic , strong) AVPlayerLayer *playerLayer;
@property (nonatomic , strong) NSTimer *playbackTimeCheckerTimer;
@property (assign, nonatomic) CGFloat videoPlaybackPosition;
@property (nonatomic , strong) NSString *tempVideoPath;
@property (nonatomic , strong) AVAsset *asset;
@property (assign, nonatomic) BOOL isPlaying;
@property (nonatomic, copy  ) void(^playBlock)(BOOL isPlaying);
- (id)initWithFrame:(CGRect)frame url:(NSURL*)url;
- (id)initWithFrame:(CGRect)frame asset:(AVAsset*)asset;
- (void)play;
- (void)pause;
- (void)startPlaybackTimeChecker;
- (void)stopPlaybackTimeChecker;
- (void)seekVideoToPos:(CGFloat)pos;
- (void)resetPlayer;
@end
