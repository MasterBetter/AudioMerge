//
//  ViewController.m
//  MergeAudio
//
//  Created by wooy on 16/9/9.
//  Copyright © 2016年 wooy. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define kFileManager [NSFileManager defaultManager]

@interface ViewController ()

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, strong) NSMutableArray *audioMixParams;
@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
 
    NSString *audioPath1 = [[NSBundle mainBundle] pathForResource:@"小样_00" ofType:@"wav"];
    NSString *audioPath2 = [[NSBundle mainBundle] pathForResource:@"小样_01" ofType:@"wav"];
    NSString *audioPath3 = [[NSBundle mainBundle] pathForResource:@"小样_02" ofType:@"wav"];
    NSString *audioPath4 = [[NSBundle mainBundle] pathForResource:@"小样_03" ofType:@"wav"];
    NSString *audioPath5 = [[NSBundle mainBundle] pathForResource:@"小样_04" ofType:@"wav"];
    
    NSString *audioPath8 = [[NSBundle mainBundle] pathForResource:@"她的话触动了我" ofType:@"mp3"];
    
    NSArray *fileArr = @[audioPath1,audioPath2,audioPath3,audioPath4,audioPath5];
    
     NSArray *timeArr = @[@1.5,@4.4,@21.566,@24.666,@28.66];
   
    [self bgSound:audioPath8 recordAudio:fileArr starTimeArr:timeArr saveFileName:@"123123"];
    
}

- (void )bgSound:(NSString*)bgSound recordAudio:(NSArray*)fileArr starTimeArr:(NSArray*)starTimeArr saveFileName:(NSString *)fileName{
    
    
    
    NSMutableArray *audioAssetTrackArr = [NSMutableArray arrayWithCapacity:fileArr.count];
    
    NSMutableArray *audioTrackArr = [NSMutableArray arrayWithCapacity:fileArr.count];
    
    NSMutableArray *audioAssetArr = [NSMutableArray arrayWithCapacity:fileArr.count];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    for (int i=0; i<fileArr.count; i++) {
        
        AVURLAsset *audioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:fileArr[i]]];
        
        // 音频通道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
        
        // 音频采集通道
        AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        
        
        [audioAssetArr addObject:audioAsset];
        [audioTrackArr addObject:audioTrack];
        [audioAssetTrackArr addObject:audioAssetTrack];
    }
    
    for (int i=0; i<starTimeArr.count; i++) {
        
        CMTime t = CMTimeMake([starTimeArr[i] integerValue], 1);
        
        AVURLAsset *audioAsset = audioAssetArr[i];
        // 音频合并 - 插入音轨文件
        [audioTrackArr[i] insertTimeRange:CMTimeRangeMake(kCMTimeZero,audioAsset.duration) ofTrack:audioAssetTrackArr[i] atTime:t error:nil];
    }
    
    // 合并后的文件导出 - `presetName`要和之后的`session.outputFileType`相对应。
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    NSString *outPutFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmple.m4a"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPutFilePath error:nil];
    }
    
    // 查看当前session支持的fileType类型
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A; //与上述的`present`相对应
    session.shouldOptimizeForNetworkUse = YES;   //优化网络
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        //完成输出后打印出输出的各种状态
        int exportStatus = session.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed:{
                NSError *exportError = session.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
            }break;
            case AVAssetExportSessionStatusCompleted:{
                
                NSLog (@"AVAssetExportSessionStatusCompleted1");
                NSLog(@"%@",outPutFilePath);
                [self exportAudioWithURL:bgSound otherAssetURL:outPutFilePath saveFileName:fileName];
            }  break;
            case AVAssetExportSessionStatusUnknown: NSLog (@"AVAssetExportSessionStatusUnknown"); break;
            case AVAssetExportSessionStatusExporting: NSLog (@"AVAssetExportSessionStatusExporting"); break;
            case AVAssetExportSessionStatusCancelled: NSLog (@"AVAssetExportSessionStatusCancelled"); break;
            case AVAssetExportSessionStatusWaiting: NSLog (@"AVAssetExportSessionStatusWaiting"); break;
            default:  NSLog (@"didn't get export status"); break;
        }
    }];
}
- (void) exportAudioWithURL:(NSString *)asset1 otherAssetURL:(NSString *)asset2 saveFileName:(NSString *)fileName {
    
    AVMutableComposition *composition =[AVMutableComposition composition];
    _audioMixParams =[NSMutableArray arrayWithCapacity:0];
    
    //录制的视频
    NSURL *audio_inputFileUrl = [NSURL fileURLWithPath:asset1];
    AVURLAsset *bgAudioAsset = [AVURLAsset URLAssetWithURL:audio_inputFileUrl options:nil];
    
    CMTime startTime = CMTimeMakeWithSeconds(0,bgAudioAsset.duration.timescale);
    CMTime trackDuration = bgAudioAsset.duration;
    
    //获取背景音频素材
    [self setUpAndAddAudioAtPath:audio_inputFileUrl toComposition:composition start:startTime dura:trackDuration offset:CMTimeMake(0,44100)];
    
    //本地要插入的音
    NSURL *assetURL2 =[NSURL fileURLWithPath:asset2];
    //获取设置完的本地音乐素材
    [self setUpAndAddAudioAtPath:assetURL2 toComposition:composition start:startTime dura:trackDuration offset:CMTimeMake(0,44100)];
    
    //创建一个可变的音频混合
    AVMutableAudioMix *audioMix =[AVMutableAudioMix audioMix];
    audioMix.inputParameters =[NSArray arrayWithArray:_audioMixParams];//从数组里取出处理后的音频轨道参数
    
    //创建一个输出
    AVAssetExportSession *exporter =[[AVAssetExportSession alloc]
                                     initWithAsset:composition
                                     presetName:AVAssetExportPresetAppleM4A];
    //存储的具体路径
    NSString *componet = [NSString stringWithFormat:@"%@.m4a",fileName];
    NSString *exportFile = [NSTemporaryDirectory() stringByAppendingPathComponent:componet];
    
    
    if([[NSFileManager defaultManager]fileExistsAtPath:exportFile]) {
        [[NSFileManager defaultManager]removeItemAtPath:exportFile error:nil];
    }
    exporter.audioMix = audioMix;
    exporter.outputFileType = AVFileTypeAppleM4A;
    exporter.outputURL = [NSURL fileURLWithPath:exportFile];
    exporter.shouldOptimizeForNetworkUse = YES;   //优化网络
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        //完成输出后打印出输出的各种状态
        int exportStatus = exporter.status;
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed:{
                NSError *exportError = exporter.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
            }break;
            case AVAssetExportSessionStatusCompleted:{
                
                NSLog (@"AVAssetExportSessionStatusCompleted");
                NSLog(@"---  %@",exportFile);
                AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:exportFile] error:nil];
                [player play];
            }break;
            case AVAssetExportSessionStatusUnknown: NSLog (@"AVAssetExportSessionStatusUnknown"); break;
            case AVAssetExportSessionStatusExporting: NSLog (@"AVAssetExportSessionStatusExporting"); break;
            case AVAssetExportSessionStatusCancelled: NSLog (@"AVAssetExportSessionStatusCancelled"); break;
            case AVAssetExportSessionStatusWaiting: NSLog (@"AVAssetExportSessionStatusWaiting"); break;
            default:  NSLog (@"didn't get export status"); break;
        }
    }];
    
   
}

//通过文件路径建立和添加音频素材
- (void)setUpAndAddAudioAtPath:(NSURL*)assetURL toComposition:(AVMutableComposition*)composition start:(CMTime)start dura:(CMTime)dura offset:(CMTime)offset{
    
    AVURLAsset *songAsset =[AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    AVMutableCompositionTrack *track =[composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceAudioTrack =[[songAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
    
    NSError *error =nil;
    BOOL ok =NO;
    
    CMTime startTime = start;
    CMTime trackDuration = dura;
    CMTimeRange tRange =CMTimeRangeMake(startTime,trackDuration);
    
    //设置音量
    //AVMutableAudioMixInputParameters（输入参数可变的音频混合）
    //audioMixInputParametersWithTrack（音频混音输入参数与轨道）
    AVMutableAudioMixInputParameters *trackMix =[AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    [trackMix setVolume:1.0f atTime:startTime];
    
    //素材加入数组
    [_audioMixParams addObject:trackMix];
    
    //Insert audio into track  //offsetCMTimeMake(0, 44100)
    ok = [track insertTimeRange:tRange ofTrack:sourceAudioTrack atTime:kCMTimeInvalid error:&error];
}

- (NSMutableArray *)audioMixParams{
    
    if (!_audioMixParams) {
        _audioMixParams = [NSMutableArray array];
    }
    
    return _audioMixParams;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
