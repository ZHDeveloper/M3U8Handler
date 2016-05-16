//
//  ViewController.m
//  M3U8Demo
//
//  Created by AdminZhiHua on 16/5/13.
//  Copyright © 2016年 AdminZhiHua. All rights reserved.
//

#import "ViewController.h"
#import "M3U8Handler.h"
#import "SegmentsDownloadManager.h"
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface ViewController () <M3U8HandlerDelegate,SegmentsDownloadDelegate>

@property(atomic, retain) id<IJKMediaPlayback> player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - Action

- (IBAction)pauseButtonAction:(id)sender {
    [self.player pause];
}

- (IBAction)playButtonAction:(id)sender {
    [self.player play];
}

- (IBAction)startButtonAction:(id)sender {
    
    NSURL *url = [NSURL URLWithString:@"http://software.swwy.com/Oz08NDRyNiY.m3u8"];
    
    M3U8Handler *m3u8Handler = [M3U8Handler new];
    
    [m3u8Handler praseM3U8With:url handlerDelegate:self];
    
}

- (void)initPlayer:(NSURL *)url {
#ifdef DEBUG
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    // [IJKFFMoviePlayerController checkIfPlayerVersionMatch:YES major:1 minor:0 micro:0];
    
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:options];
    
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    
    [self.playerContentView addSubview:self.player.view];
    
    //添加约束
    UIView *playerView = self.player.view;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSString *hVFL = @"H:|-(0)-[playerView]-(0)-|";
    NSString *vVFL = @"V:|-(0)-[playerView]-(0)-|";

    NSArray *hConst = [NSLayoutConstraint constraintsWithVisualFormat:hVFL options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)];
    
    NSArray *vConst = [NSLayoutConstraint constraintsWithVisualFormat:vVFL options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)];
    
    [self.playerContentView addConstraints:hConst];
    [self.playerContentView addConstraints:vConst];
    
    [self.player prepareToPlay];
}

#pragma mark - Delegate

- (void)M3U8Handler:(M3U8Handler *)handler praseError:(NSError *)error {
    
    NSLog(@"解析错误:%@",error);
    
}

- (void)praseM3U8InfoFinish:(M3U8Handler *)handler {
    
    //选择是否下载
    NSLog(@"解析完成");
    
    SegmentsDownloadManager *manager = [SegmentsDownloadManager downloadManagerWith:handler.segments delegate:self];
    
    manager.fileName = [handler.urlString lastPathComponent];
    
    NSLog(@"%lf",manager.totalDuration);
    
    [manager startDownloadSegments];
    
}

- (void)downloadManager:(SegmentsDownloadManager *)manager downloadCompleteWith:(NSUInteger)idx newM3U8Path:(NSString *)path {
    NSLog(@"分片%ld下载完成",idx);
    NSLog(@"%@",path);
    
    if (idx != 0) return;

    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    
    [self initPlayer:fileUrl];
    
}

- (void)segmentsDownloadComplete:(SegmentsDownloadManager *)manager {
    NSLog(@"所有分片下载完成");
}

- (void)downloadManager:(SegmentsDownloadManager *)manager downloadCompleteWith:(NSUInteger)idx downloadError:(NSError *)error {
    NSLog(@"%@",error);
}

@end
