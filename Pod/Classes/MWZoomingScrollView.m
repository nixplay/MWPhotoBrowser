//
//  ZoomingScrollView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <DACircularProgress/DACircularProgressView.h>
#import "MWCommon.h"
#import "MWZoomingScrollView.h"
#import "MWPhotoBrowser.h"
#import "MWPhoto.h"
#import "MWPhotoBrowserPrivate.h"
#import "UIImage+MWPhotoBrowser.h"
#import "ViewUtils.h"
// Private methods and properties
@interface MWZoomingScrollView () {
    
    MWPhotoBrowser __weak *_photoBrowser;
    MWTapDetectingView *_tapView; // for background taps
    MWTapDetectingImageView *_photoImageView;
    DACircularProgressView *_loadingIndicator;
    UILabel *_label;
    UIImageView *_loadingError;
    UITapGestureRecognizer * _tap;
    
}
@end

@implementation MWZoomingScrollView
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
@synthesize playButton = _playButton;
- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser {
    if ((self = [super init])) {
        
        // Setup
        _index = NSUIntegerMax;
        _photoBrowser = browser;
        
        // Tap view for background
        _tapView = [[MWTapDetectingView alloc] initWithFrame:self.bounds];
        _tapView.tapDelegate = self;
        _tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tapView.backgroundColor = [UIColor blackColor];
        [self addSubview:_tapView];
        
        // Image view
        _photoImageView = [[MWTapDetectingImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.tapDelegate = self;
        _photoImageView.contentMode = UIViewContentModeCenter;
        _photoImageView.backgroundColor = [UIColor blackColor];
        [self addSubview:_photoImageView];
        
        // Loading indicator
        _loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 40.0f, 40.0f)];
        _loadingIndicator.userInteractionEnabled = NO;
        _loadingIndicator.thicknessRatio = 0.1;
        _loadingIndicator.roundedCorners = NO;
        _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_loadingIndicator];
        
        NSBundle* bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[MWPhotoBrowser class]] URLForResource:@"MWPhotoBrowser" withExtension:@"bundle"]];
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(140.0f, 50.0f, 50.0f, 30.0f)];
        [_label setFont:[UIFont systemFontOfSize:12]];
        [_label setTextColor:[UIColor whiteColor]];
        [_label setTextAlignment:NSTextAlignmentCenter];
        _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        
        _label.text = NSLocalizedStringFromTableInBundle(@"Syncing", @"MWPhotoBrowser", bundle, @"Syncing");
        
        [self addSubview:_label];
        
        // Listen progress notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setProgressFromNotification:)
                                                     name:MWPHOTO_PROGRESS_NOTIFICATION
                                                   object:nil];
        
        // Setup
        self.backgroundColor = [UIColor blackColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.isReadyToPlay = NO;
    }
    return self;
}
-(void) didMoveToWindow {
    [super didMoveToWindow]; // (does nothing by default)
    if (self.window == nil) {
        // YOUR CODE FOR WHEN UIVIEW IS REMOVED
        if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
            [_photo cancelAnyLoading];
        }
        [self stopPlaybackTimeChecker];
        _isPlaying = NO;
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
- (void)dealloc {
    [self stopPlaybackTimeChecker];
    if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
        [_photo cancelAnyLoading];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}
    
- (void)prepareForReuse {
    [self stopPlaybackTimeChecker];
    [self hideImageFailure];
    [_asset cancelLoading];
    if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
        [_photo cancelAnyLoading];
    }
    self.photo = nil;
    self.captionView = nil;
    self.selectedButton = nil;
    self.playButton = nil;
    _photoImageView.hidden = NO;
    _photoImageView.image = nil;
    _index = NSUIntegerMax;
}
    
- (BOOL)displayingVideo {
    return [_photo respondsToSelector:@selector(isVideo)] && _photo.isVideo;
}
    
- (void)setImageHidden:(BOOL)hidden {
    _photoImageView.hidden = hidden;
}
    
#pragma mark - Image
    
- (void)setPhoto:(id<MWPhoto>)photo {
    // Cancel any loading on old photo
    if (_photo && photo == nil) {
        if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
            [_photo cancelAnyLoading];
        }
    }
    _photo = photo;
    if(self.photo == nil){
        return;
    }
    UIImage *img = [_photoBrowser imageForPhoto:_photo];
    if (img) {
        [self displayImage];
    } else {
        // Will be loading so show loading
        [self showLoadingIndicator];
    }
    //    if(photo.isVideo){
    //
    //        typeof(self) __weak weakSelf = self;
    //        dispatch_group_async(dispatch_group_create(), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    //            [self.photo getVideoURL:^(NSURL *url, AVURLAsset *__nullable avurlAsset) {
    //
    //                dispatch_async(dispatch_get_main_queue(), ^{
    //                    // If the video is not playing anymore then bail
    //
    //                    typeof(self) strongSelf = weakSelf;
    //                    if (!strongSelf) return;
    //
    //                    if (url) {
    //                        ((MWPhoto*)strongSelf.photo).videoURL = url;
    //                        [strongSelf setupVideoPreviewUrl:url avurlAsset:avurlAsset photoImageViewFrame:self.frame];
    //
    //                    } else {
    //
    //                    }
    //                });
    //            }];
    //        });
    //    }
}
    
    // Get and display image
- (void)displayImage {
    if (_photo && _photoImageView.image == nil) {
        
        // Reset
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.contentSize = CGSizeMake(0, 0);
        
        // Get image from browser as it handles ordering of fetching
        UIImage *img = [_photoBrowser imageForPhoto:_photo];
        if (img) {
            
            // Hide indicator
            [self hideLoadingIndicator];
            
            // Set image
                _photoImageView.image = img;
            _photoImageView.hidden = NO;
            
            // Setup photo frame
            CGRect photoImageViewFrame;
            photoImageViewFrame.origin = CGPointZero;
            photoImageViewFrame.size = img.size;
            _photoImageView.frame = photoImageViewFrame;
            self.contentSize = photoImageViewFrame.size;
            [self displaySubView:photoImageViewFrame];
            // Set zoom to minimum zoom
            [self setMaxMinZoomScalesForCurrentBounds];
            
        } else  {
            
            // Show image failure
            [self displayImageFailure];
            
        }
        [self setNeedsLayout];
    }
}
-(void) displaySubView:(CGRect)photoImageViewFrame{
}
    
    // Image failed so just show black!
- (void)displayImageFailure {
    [self hideLoadingIndicator];
    _photoImageView.image = nil;
    
    // Show if image is not empty
    if (![_photo respondsToSelector:@selector(emptyImage)] || !_photo.emptyImage) {
        if (!_loadingError) {
            _loadingError = [UIImageView new];
            _loadingError.image = [UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/ImageError" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
            _loadingError.userInteractionEnabled = NO;
            _loadingError.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            [_loadingError sizeToFit];
            [self addSubview:_loadingError];
        }
        _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2),
                                         _loadingError.frame.size.width,
                                         _loadingError.frame.size.height);
    }
}
    
- (void)hideImageFailure {
    if (_loadingError) {
        [_loadingError removeFromSuperview];
        _loadingError = nil;
    }
}
    
#pragma mark - Loading Progress
    
- (void)setProgressFromNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dict = [notification object];
        if([dict objectForKey:@"photo"] != nil){
            id <MWPhoto> photoWithProgress = [dict objectForKey:@"photo"];
            if (photoWithProgress == self.photo) {
                float progress = [[dict valueForKey:@"progress"] floatValue];
                _loadingIndicator.progress = MAX(MIN(1, progress), 0);
                 if(progress < 1 ){
                     _playButton.hidden = YES;
                 }else{
                     _playButton.hidden = NO;
                 }
            }
        }else  if([dict objectForKey:@"video"] != nil){
            id <MWPhoto> photoWithProgress = [dict objectForKey:@"video"];
            if (photoWithProgress == _photo) {
                float progress = [[dict valueForKey:@"progress"] floatValue];
                if(progress < 1 ){
                    _loadingIndicator.hidden = NO;
                    _label.hidden = NO;
                    _loadingIndicator.progress = MAX(MIN(1, progress), 0);
                    _playButton.hidden = YES;
                }else{
                    _loadingIndicator.hidden = YES;
                    _label.hidden = NO;
                    _playButton.hidden = NO;
                }
            }
        }
    });
}
    
- (void)hideLoadingIndicator {
    _loadingIndicator.hidden = YES;
    _label.hidden = YES;
}
    
- (void)showLoadingIndicator {
    
    _loadingIndicator.center = _tapView.center;
    _label.center = _loadingIndicator.center;
    _label.top = _loadingIndicator.bottom + 10;
    self.zoomScale = 0;
    self.minimumZoomScale = 0;
    self.maximumZoomScale = 0;
    _loadingIndicator.progress = 0;
    _loadingIndicator.hidden = NO;
    _label.hidden = NO;
    [self hideImageFailure];
}
    
#pragma mark - Setup
    
- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (_photoImageView && _photoBrowser.zoomPhotosToFill) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}
    
- (void)setMaxMinZoomScalesForCurrentBounds {
    
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    // Bail if no image
    if (_photoImageView.image == nil) return;
    
    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // Image is smaller than screen so no zooming!
    if (xScale >= 1 && yScale >= 1) {
        minScale = 1.0;
    }
    
    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScale];
    
    // If we're zooming to fill then centralise
    if (self.zoomScale != minScale) {
        
        // Centralise
        self.contentOffset = CGPointMake((imageSize.width * self.zoomScale - boundsSize.width) / 2.0,
                                         (imageSize.height * self.zoomScale - boundsSize.height) / 2.0);
        
    }
    
    // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
    self.scrollEnabled = NO;
    
    // If it's a video then disable zooming
    if ([self displayingVideo]) {
        self.maximumZoomScale = self.zoomScale;
        self.minimumZoomScale = self.zoomScale;
    }
    
    // Layout
    [self setNeedsLayout];
    
}
    
#pragma mark - Layout
    
- (void)layoutSubviews {
    
    // Update tap view frame
    _tapView.frame = self.bounds;
    
    
    // Super
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
    _photoImageView.frame = frameToCenter;
    
    [self setFrameToCenter:frameToCenter];
    // Position indicators (centre does not seem to work!)
    
    if (!_loadingIndicator.hidden){
        
        _loadingIndicator.center = _tapView.center;
        _label.center = _loadingIndicator.center;
        _label.top = _loadingIndicator.bottom + 5;
    }
    if (_loadingError){
        
        _loadingError.frame = CGRectMake(self.bounds.origin.x + floorf((self.bounds.size.width * .5f - _loadingError.frame.size.width * .5f) ),
                                         floorf((self.bounds.size.height * .5f - _loadingError.frame.size.height * .5f) ),
                                         _loadingError.frame.size.width,
                                         _loadingError.frame.size.height);
    }
}
    
    
-(void) setFrameToCenter:(CGRect)frame{
    if(self.photo.isVideo){
        if(self.videoPlayer != nil && self.videoLayer != nil && self.playerLayer != nil){
            self.videoLayer.frame = frame;
            if(self.playerLayer.superlayer != nil){
                [self.playerLayer removeFromSuperlayer];
            }
            self.playerLayer.frame = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
            [self.videoLayer.layer addSublayer:self.playerLayer];
        }
    }
}
    
#pragma mark - UIScrollViewDelegate
    
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _photoImageView;
}
    
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_photoBrowser cancelControlHiding];
}
    
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
    [_photoBrowser cancelControlHiding];
}
    
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [_photoBrowser hideControlsAfterDelay];
}
    
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}
    
#pragma mark - Tap Detection
    
- (void)handleSingleTap:(CGPoint)touchPoint {
    
    if(self.isPlaying){
        [self onVideoTapped];
    }else{
        [_photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
    }
}
    
- (void)handleDoubleTap:(CGPoint)touchPoint {
    
    // Dont double tap to zoom if showing a video
    if ([self displayingVideo]) {
        return;
    }
    
    // Cancel any single tap handling
    [NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
    
    // Zoom
    if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {
        
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
        
    } else {
        
        // Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        
    }
    
    // Delay controls
    [_photoBrowser hideControlsAfterDelay];
    
}
    
    // Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch {
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}
    
    // Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleSingleTap:CGPointMake(touchX, touchY)];
}
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleDoubleTap:CGPointMake(touchX, touchY)];
}
    
#pragma mark - Video
-(void) setAsset:(AVAsset *)asset{
    _asset = asset;
}
-(void) setPlayButton:(UIButton*)button{
    _playButton = button;
    [_playButton addTarget:self action:@selector(onPlayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _loadingIndicator.center = _tapView.center;
    _label.center = _loadingIndicator.center;
    _label.top = _loadingIndicator.bottom + 10;
}
    
-(void) setupVideoPreviewAsset:(AVAsset*)avurlAsset photoImageViewFrame:(CGRect)photoImageViewFrame{
    if(self.photo.isVideo){
//        if(avurlAsset != nil){
//            _asset = avurlAsset;
//        }
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:_asset];
        
        AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
        self.player  = player;
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        self.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        self.videoLayer = [[UIView alloc] initWithFrame:CGRectZero];
        self.videoPlayer = [[UIView alloc] initWithFrame:CGRectZero];
        [self.playerLayer setFrame:CGRectZero];
        [self.videoPlayer setBackgroundColor:[UIColor clearColor]];
        [self addSubview:self.videoPlayer];
        
        [self insertSubview:self.videoPlayer atIndex:[[self subviews] indexOfObject:_photoImageView]];
        [self.videoLayer.layer addSublayer:self.playerLayer];
        
        self.videoLayer.tag = 1;
        
        self.videoPlaybackPosition = 0;
        
        [self seekVideoToPos:0];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:item];
         self.playButton.hidden = NO;
    }
    
}
    
-(void) playerItemDidReachEnd:(NSNotification *)notification {
    
    NSLog(@"IT REACHED THE END");
    [self.player pause];
    [self stopPlaybackTimeChecker];
    [self playButton].hidden = NO;
    self.videoPlayer.hidden = YES;
    _photoImageView.hidden = NO;
    [self seekVideoToPos:0];
    
}
- (void) tapOnVideoLayer:(UITapGestureRecognizer *)tap
    {
        [self onVideoTapped];
    }
    
-(void) onPlayButtonPressed:(id) sender{
    [self onVideoTapped];
}
- (void) onVideoTapped{
    
    
    if(self.photo.isVideo){
        if (self.isPlaying) {
            
            [self.player pause];
            [self stopPlaybackTimeChecker];
            [self playButton].hidden = NO;
            _photoImageView.hidden = NO;
            _isPlaying = NO;
        }else {
            typeof(self) __weak weakSelf = self;
            if(self.videoPlayer == nil && self.videoLayer == nil && self.player == nil){
                _loadingIndicator.center = _tapView.center;
                _label.center = _loadingIndicator.center;
                _label.top = _loadingIndicator.bottom + 5;
                [self.photo getVideoURL:^(NSURL *url, AVAsset * _Nullable avAsset) {
//                    if(url)
                    {
                        if(!avAsset && url){
                            weakSelf.asset = [AVURLAsset assetWithURL:url];
                        } else if (avAsset){
                            weakSelf.asset = avAsset;
                        }
                        typeof(self) strongSelf = weakSelf;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [strongSelf setupVideoPreviewAsset:strongSelf.asset photoImageViewFrame:strongSelf.frame];
                            [strongSelf onVideoTapped];
                        });
                    }
                }];
                
            }else{
                _isPlaying = YES;
                self.videoPlayer.hidden = NO;
                if(self.videoLayer.superview == nil){
                    [self.videoPlayer addSubview:self.videoLayer];
                }
                [self playButton].hidden = YES;
                
                
                [self startPlaybackTimeChecker];
                [self.player play];
                _photoImageView.hidden = YES;
            }
        }
        
        
    }
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
        [_playButton setHidden:NO];
        [_player pause];
        [self seekVideoToPos: 0];
    }
}
    
- (void)seekVideoToPos:(CGFloat)pos
{
    _videoPlaybackPosition = pos;
    CMTime time = CMTimeMakeWithSeconds(_videoPlaybackPosition, self.asset.duration.timescale);
    NSLog(@"seekVideoToPos time:%.2f", CMTimeGetSeconds(time));
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)resetPlayer
{
    if(self.isReadyToPlay){
        self.isReadyToPlay = NO;
        [self.player play];
    }else{
        if(self.player != nil){
            [self.player pause];
            CMTime time = CMTimeMakeWithSeconds(0, self.asset.duration.timescale);
            [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        }
        
    }
}
@end

