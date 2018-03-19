//
//  AVPlayerView.m
//  MWPhotoBrowser
//
//  Created by James Kong on 19/3/2018.
//

#import "AVPlayerView.h"

@import Foundation;
@import AVFoundation;



@implementation AVPlayerView

- (AVPlayer *)player {
    return self.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player {
    self.playerLayer.player = player;
}

// override UIView
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

@end

