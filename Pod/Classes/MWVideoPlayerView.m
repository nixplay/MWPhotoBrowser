//
//  VideoPlayerView.m
//  MWPhotoBrowser
//
//  Created by James Kong on 21/11/2017.
//

#import "MWVideoPlayerView.h"

@implementation MWVideoPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
@synthesize player = _player;
@synthesize playerItem = _playerItem;
@synthesize playerLayer = _playerLayer;
@synthesize playbackTimeCheckerTimer = _playbackTimeCheckerTimer;
@synthesize videoPlaybackPosition = _videoPlaybackPosition;
@synthesize videoPlayer = _videoPlayer;
@synthesize videoLayer = _videoLayer;
@synthesize tempVideoPath = _tempVideoPath;
@synthesize asset = _asset;
@synthesize isPlaying = _isPlaying;
- (id)initWithFrame:(CGRect)frame url:(NSURL*)url{
    return [self initWithFrame:frame asset:[AVAsset assetWithURL:url]];
}
- (id)initWithFrame:(CGRect)frame asset:(AVAsset*)asset{
    if ((self = [super initWithFrame:frame])) {
        _asset = asset;
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:_asset];
        
        _player = [AVPlayer playerWithPlayerItem:item];
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
        _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        _videoLayer = [[UIView alloc] initWithFrame:frame];
        _videoPlayer = [[UIView alloc] initWithFrame:frame];
        [_playerLayer setFrame:frame];
        [_videoPlayer setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_videoPlayer];
        [_videoLayer.layer addSublayer:_playerLayer];
        
        _videoLayer.tag = 1;
        
        _videoPlaybackPosition = 0;
        
        [self seekVideoToPos:0];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:item];
    }
    return self;
}
-(void) play{
    if(self.videoLayer.superview == nil){
        [self.videoPlayer addSubview:self.videoLayer];
    }
    [self.player play];
    [self startPlaybackTimeChecker];
    _isPlaying = YES;
    if (self.playBlock) {
        self.playBlock(self.isPlaying);
    }
}
-(void) pause{
    [self.player pause];
    [self stopPlaybackTimeChecker];
    _isPlaying = NO;
    if (self.playBlock) {
        self.playBlock(self.isPlaying);
    }
}
-(void) didMoveToWindow {
    [super didMoveToWindow]; // (does nothing by default)
    if (self.window == nil) {
        // YOUR CODE FOR WHEN UIVIEW IS REMOVED
        
        _isPlaying = NO;
        
        if (self.playBlock) {
            self.playBlock(self.isPlaying);
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self  name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
        [_player seekToTime:CMTimeMake(0, 1)];
        [_player pause];
        [_player replaceCurrentItemWithPlayerItem:nil];
        [_asset cancelLoading];
        _asset = nil;
        _player = nil;
        _playerLayer = nil;
        _videoLayer = nil;
        _videoPlayer = nil;
    }
}
- (void)prepareForReuse {
    [_asset cancelLoading];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    NSUInteger tapCount = touch.tapCount;
    switch (tapCount) {
        case 1:
        [self pause];
        break;
    }
}
-(void) playerItemDidReachEnd:(NSNotification *)notification {
    
    NSLog(@"IT REACHED THE END");
    _isPlaying = NO;
    if (self.playBlock) {
        self.playBlock(self.isPlaying);
    }
    [self.player pause];
    [self stopPlaybackTimeChecker];
    self.videoPlayer.hidden = YES;
    [self seekVideoToPos:0];
    
}
- (void)startPlaybackTimeChecker
{
    [self stopPlaybackTimeChecker];
    
    _playbackTimeCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(onPlaybackTimeCheckerTimer) userInfo:nil repeats:YES];
}

- (void)stopPlaybackTimeChecker
{
    if (_playbackTimeCheckerTimer) {
        [_playbackTimeCheckerTimer invalidate];
        _playbackTimeCheckerTimer = nil;
    }
}


#pragma mark - PlaybackTimeCheckerTimer

- (void)onPlaybackTimeCheckerTimer
{
    CMTime curTime = [_player currentTime];
    Float64 seconds = CMTimeGetSeconds(curTime);
    if (seconds < 0){
        seconds = 0; // this happens! dont know why.
    }
    _videoPlaybackPosition = seconds;
    if (_videoPlaybackPosition >= CMTimeGetSeconds([_asset duration])) {
        [_player pause];
        [self seekVideoToPos:0];
    }
}

- (void)seekVideoToPos:(CGFloat)pos
{
    _videoPlaybackPosition = pos;
    CMTime time = CMTimeMakeWithSeconds(_videoPlaybackPosition, _player.currentTime.timescale);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)resetPlayer
{
    if(self.player != nil){
        [self.player pause];
        [self.player seekToTime:CMTimeMakeWithSeconds(0, _player.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}
@end
