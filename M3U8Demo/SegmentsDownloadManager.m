//
//  SegmentDownloadManager.m
//  M3U8Demo
//
//  Created by AdminZhiHua on 16/5/13.
//  Copyright © 2016年 AdminZhiHua. All rights reserved.
//

#import "SegmentsDownloadManager.h"
#import "M3U8Handler.h"
#import "AFNetworking.h"

@interface SegmentsDownloadManager ()

//当前下载分片的索引
@property (nonatomic,assign) NSInteger tsIndex;

//生成新m3u8字符串
@property (nonatomic,copy) NSString *contentString;

//是否停止下载
@property (nonatomic,assign) BOOL stopDownload;

@end

@implementation SegmentsDownloadManager

+ (instancetype)downloadManagerWith:(NSMutableArray *)segments delegate:(id<SegmentsDownloadDelegate>)delegate {
    
    SegmentsDownloadManager *downloadManager = [SegmentsDownloadManager new];
    
    downloadManager.cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
    
    downloadManager.segments = segments;
    
    downloadManager.delegate = delegate;
    
    return downloadManager;
    
}

- (void)startDownloadSegments {
    
    //创建文件夹
    NSString *directory = [self.cachePath stringByAppendingPathComponent:self.fileName];
    
    self.filePath = directory;
    
    [self createDocumentAtPath:directory];
    
    self.tsIndex = 0;
    
    self.contentString = nil;
    
    //开始下载第一个分片
    SegmentInfo *segment = [self.segments firstObject];
    
    [self downloadSegmentWith:segment];
    
}

- (void)downloadSegmentWith:(SegmentInfo *)segmentInfo {
    
    NSString *tsFilePath = [self.filePath stringByAppendingPathComponent:segmentInfo.tsURL.lastPathComponent];
    
    //如果本地有ts文件直接下载完成
    if ([self fileExitAtPath:tsFilePath])
    {
        [self downloadCompleteWith:segmentInfo];
        return;
    }
    
    [self downloadFileWithOption:nil withInferface:segmentInfo.tsURL savedPath:tsFilePath downloadSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        //下载完成的处理
        [self downloadCompleteWith:segmentInfo];
        
    } downloadFailure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        //下载出错
        if ([self.delegate respondsToSelector:@selector(downloadManager:downloadCompleteWith:downloadError:)])
        {
            [self.delegate downloadManager:self downloadCompleteWith:self.tsIndex downloadError:error];
        }
        
        //停止下载
        if (self.stopDownload) return;
        
        //5秒后继续下载
        [self performSelector:@selector(downloadSegmentWith:) withObject:segmentInfo afterDelay:5];
        
    } progress:^(float progress) {
        
    }];
}

- (void)downloadFileWithOption:(NSDictionary *)paramDic
                 withInferface:(NSString*)requestURL
                     savedPath:(NSString*)savedPath
               downloadSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               downloadFailure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                      progress:(void (^)(float progress))progress

{
    
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request =[serializer requestWithMethod:@"POST" URLString:requestURL parameters:paramDic error:nil];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [operation setOutputStream:[NSOutputStream outputStreamToFileAtPath:savedPath append:NO]];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        float p = (float)totalBytesRead / totalBytesExpectedToRead;
        
        progress(p);
        
    }];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        success(operation,responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        failure(operation,error);
        
    }];
    
    [operation start];
    
}

//当前分片下载完成
- (void)downloadCompleteWith:(SegmentInfo *)segmentInfo {
    
    NSString *filePath = [self createNewM3U8FileWith:segmentInfo];
    
    [self.contentString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    //通知代理
    if ([self.delegate respondsToSelector:@selector(downloadManager:downloadCompleteWith:newM3U8Path:)])
    {
        [self.delegate downloadManager:self downloadCompleteWith:self.tsIndex newM3U8Path:filePath];
    }
    
    //下载完成
    if (self.tsIndex >= self.segments.count-1)
    {
        if ([self.delegate respondsToSelector:@selector(segmentsDownloadComplete:)]) {
            [self.delegate segmentsDownloadComplete:self];
        }
        return;
    };
    
    //停止下载
    if (self.stopDownload) return;
    
    //继续下载下一个分片
    self.tsIndex ++;
    
    SegmentInfo *info = self.segments[self.tsIndex];
    
    [self downloadSegmentWith:info];
}

//返回文件路径
- (NSString *)createNewM3U8FileWith:(SegmentInfo *)segmentInfo {
    
    //创建新的m3u8文件
    if (self.tsIndex == 0)
    {
        self.contentString = @"#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-MEDIA-SEQUENCE:0\n#EXT-X-ALLOW-CACHE:YES\n";
        
        [self appendTSInfoWith:segmentInfo];
    }
    else if (self.tsIndex == self.segments.count-1)
    {
        [self appendTSInfoWith:segmentInfo];
        
        self.contentString = [self.contentString stringByAppendingString:@"#EXT-X-ENDLIST\n"];
    }
    else
    {
        [self appendTSInfoWith:segmentInfo];
    }
    
    NSString *filePath = [self.filePath stringByAppendingPathComponent:self.fileName];
    
    return filePath;
}

//拼接分片信息
- (void)appendTSInfoWith:(SegmentInfo *)segmentInfo {
    NSString *tsFilePath = [self.filePath stringByAppendingPathComponent:segmentInfo.tsURL.lastPathComponent];
    tsFilePath = [tsFilePath stringByAppendingString:@"\n"];
    
    NSString *durationInfo = [NSString stringWithFormat:@"#EXTINF:%@,\n",@(segmentInfo.duration)];
    
    self.contentString = [self.contentString stringByAppendingString:durationInfo];
    self.contentString = [self.contentString stringByAppendingString:tsFilePath];

}

- (void)stopDownloadSegments {
    
    self.stopDownload = YES;
}

- (void)cleanDownloadFiles {
    
    //直接删除整个文件夹
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:self.filePath])
    {
        [manager removeItemAtPath:self.filePath error:nil];
    }
    
}

//判断文件是否存在
- (BOOL)fileExitAtPath:(NSString *)path {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL isExit = [manager fileExistsAtPath:path];
    
    return isExit;
}

//创建文件夹
- (void)createDocumentAtPath:(NSString *)path {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:path])
    {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - Getter & Setter 
- (void)setSegments:(NSMutableArray *)segments {
    _segments = segments;
    
    for (SegmentInfo *info in segments)
    {
        self.totalDuration += info.duration;
    }
}

@end
