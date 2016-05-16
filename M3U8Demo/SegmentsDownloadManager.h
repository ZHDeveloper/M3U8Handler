//
//  SegmentDownloadManager.h
//  M3U8Demo
//
//  Created by AdminZhiHua on 16/5/13.
//  Copyright © 2016年 AdminZhiHua. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SegmentsDownloadManager;
@protocol SegmentsDownloadDelegate <NSObject>

//当前下载完成第几个分片，生成一个m3u8的文件
- (void)downloadManager:(SegmentsDownloadManager *)manager downloadCompleteWith:(NSUInteger)idx newM3U8Path:(NSString *)path;

//下载出错
- (void)downloadManager:(SegmentsDownloadManager *)manager downloadCompleteWith:(NSUInteger)idx downloadError:(NSError *)error;

//所有的分片下载完成
- (void)segmentsDownloadComplete:(SegmentsDownloadManager *)manager;

@end

@interface SegmentsDownloadManager : NSObject

//所有分片的总时长
@property (nonatomic,assign) NSTimeInterval totalDuration;

@property (nonatomic,strong) NSMutableArray *segments;

//文件夹名称
@property (nonatomic,copy) NSString *fileName;

//下载保存的路劲
@property (nonatomic,copy) NSString *filePath;

//缓存的路劲，cachePath/fileName = filePath
@property (nonatomic,copy) NSString *cachePath;

@property (nonatomic,weak) id<SegmentsDownloadDelegate> delegate;

+ (instancetype)downloadManagerWith:(NSMutableArray *)segments delegate:(id<SegmentsDownloadDelegate>)delegate;

- (void)startDownloadSegments;

//如果是ts分片一直下载不下来，需要调用此方法，否则，会一直循环调用下载。
- (void)stopDownloadSegments;

//删除本地缓存文件
- (void)cleanDownloadFiles;

@end
