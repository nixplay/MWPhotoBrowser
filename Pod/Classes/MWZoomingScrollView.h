//
//  ZoomingScrollView.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhotoProtocol.h"
#import "MWTapDetectingImageView.h"
#import "MWTapDetectingView.h"
@import AVKit;
@import AVFoundation;

@class MWPhotoBrowser, MWPhoto, MWCaptionView;

@interface MWZoomingScrollView : UIScrollView <UIScrollViewDelegate, MWTapDetectingImageViewDelegate, MWTapDetectingViewDelegate> {
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

@property () NSUInteger index;
@property (nonatomic) id <MWPhoto> photo;
@property (nonatomic, weak) MWCaptionView *captionView;
@property (nonatomic, weak) UIButton *selectedButton;
@property (nonatomic, weak) UIButton *playButton;

@property (nonatomic , strong) AVPlayer *player;
@property (nonatomic , strong) AVPlayerItem *playerItem;
@property (nonatomic , strong) AVPlayerLayer *playerLayer;
@property (nonatomic , strong) NSTimer *playbackTimeCheckerTimer;
@property (assign, nonatomic) CGFloat videoPlaybackPosition;
@property (nonatomic , strong) UIView *videoPlayer;
@property (nonatomic , strong) UIView *videoLayer;
@property (nonatomic , strong) NSString *tempVideoPath;
@property (nonatomic , strong) AVAsset *asset;
@property (assign, nonatomic) BOOL isPlaying;


- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser;
- (void)displayImage;
- (void)displayImageFailure;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;
- (BOOL)displayingVideo;
- (void)setImageHidden:(BOOL)hidden;
- (void)displaySubView:(CGRect)photoImageViewFrame;
- (void) onVideoTapped;
- (void)startPlaybackTimeChecker;
- (void)stopPlaybackTimeChecker;
- (void)seekVideoToPos:(CGFloat)pos;
- (void)resetPlayer;
@end
