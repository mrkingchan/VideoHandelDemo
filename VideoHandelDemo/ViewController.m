//
//  ViewController.m
//  VideoHandelDemo
//
//  Created by Chan on 2017/8/11.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () {
    AVPlayer *_player;
    UIProgressView *_progressView;
    UIButton *_pauseOrPlay;
    UILabel *_currentTimeLabel;
    UILabel *_totalTimeLabel;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(100, [UIScreen mainScreen].bounds.size.height - 20, [UIScreen mainScreen].bounds.size.width - 200, 10.0)];
    _progressView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:_progressView];
    [self setUI];
}

///初始化UI
- (void)setUI {
    if (!_player) {
        NSString *urlStr = @"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4";
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlStr]];
        _player = [AVPlayer playerWithPlayerItem:item];
        _player.volume = 1.0; // 0~1
        [self addObserverForPlayerItem:item];
        //添加进度更新
        [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0)
                                              queue:dispatch_get_main_queue()
                                         usingBlock:^(CMTime time) {
            float currentTime = CMTimeGetSeconds(time);
            float totalTime = CMTimeGetSeconds([item  duration]);
            NSLog(@"当前已经播放了%.fs",currentTime);
            _currentTimeLabel.text = [self getTimeStrWithDuration:currentTime];
            if (currentTime) {
               [_progressView setProgress:currentTime/totalTime animated:YES];
            }
        }];
    }
    //预览
    AVPlayerLayer *playLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:playLayer];
    
    _pauseOrPlay = [UIButton buttonWithType:UIButtonTypeCustom];
    _pauseOrPlay.frame = CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 30 , [UIScreen mainScreen].bounds.size.height - 100, 60, 60);
    [_pauseOrPlay setTitle:@"暂停" forState:UIControlStateNormal];
    [_pauseOrPlay setTitle:@"播放" forState:UIControlStateSelected];
    [_pauseOrPlay setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_pauseOrPlay setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [_pauseOrPlay addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_pauseOrPlay];
    
    
    _currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 40, 100,20 )];
    _currentTimeLabel.textColor = [UIColor whiteColor];
    _currentTimeLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:_currentTimeLabel];
    
    _totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 100, [UIScreen mainScreen].bounds.size.height - 40, 100,20 )];
    _totalTimeLabel.textColor = [UIColor whiteColor];
    _totalTimeLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:_totalTimeLabel];
    
    [_player play];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidFinishAction:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

- (void)playDidFinishAction:(NSNotification *)noti {
    NSLog(@"播放完成!");
}

///添加观察者
- (void)addObserverForPlayerItem:(AVPlayerItem *)item {
    if (item == nil) {
        NSLog(@"item can't be nil!");
        return;
    }
    //添加观察者
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

///观察者
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *item = (AVPlayerItem *)object;
    if ([keyPath rangeOfString:@"status"].length) {
        //监听状态
        AVPlayerStatus status = [change[@"new"] integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            float totalSeconds = CMTimeGetSeconds([item  duration]);
            _totalTimeLabel.text = [self getTimeStrWithDuration:totalSeconds];
            NSLog(@"正在播放中...视频总长度%.f",totalSeconds);
        }
    } else if ([keyPath rangeOfString:@"loadedTimeRanges"].length) {
        //缓冲
        NSArray *array = item.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"共缓冲：%.2f",totalBuffer);
    }
}

#pragma mark --private Method
- (void)buttonAction:(id)sender {
    if ( [sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.selected = !button.selected;
        if (button.selected) {
            [_player pause];
        } else {
            [_player play];
        }
    }
}
#define kIntToStr(X)  [NSString stringWithFormat:@"%zd",X]
#define kIntoStrforZero(X) [NSString stringWithFormat:@"0%zd",X]

- (NSString *)getTimeStrWithDuration:(NSInteger)duration {
    NSInteger hour = duration/3600;
    NSInteger minite = duration/60;
    NSInteger seconds = duration%60;
    NSString *timeStr = [NSString stringWithFormat:@"%@:%@:%@",hour>=10 ?kIntToStr(hour):kIntoStrforZero(hour),
                         minite >9 ? kIntToStr(minite):kIntoStrforZero(minite),
                         seconds >9 ? kIntToStr(seconds):kIntoStrforZero(seconds)];
    return  timeStr;
    
}

-(void)dealloc {
    if (_player) {
        _player = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    CMTime currentTime = _player.currentTime;
    float seconds = CMTimeGetSeconds(currentTime);
    NSString *currentTimeStr = [self getTimeStrWithDuration:seconds];
    NSLog(@"当前播放时长:%@",currentTimeStr);
}

- (AVPlayerItem *)getPlayerItemWithTag:(NSInteger)tag {
    NSString *urlStr = [NSString stringWithFormat:@"http://www.video%zd",tag];
    NSURL *url = [NSURL URLWithString:[urlStr  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    AVPlayerItem *currentItem = _player.currentItem;
    //先移除，然后再替换
    [currentItem removeObserver:self forKeyPath:@"status"];
    [currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_player replaceCurrentItemWithPlayerItem:item];
    return item;
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
}

#define kBoundary @"198596859919834017191791522499"
- (void)test {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]];
    NSMutableData *data = [NSMutableData data];
    //    -----------------------------198596859919834017191791522499
    //    Content-Disposition: form-data; name="userfile"; filename="ViewController.h"
    //    Content-Type: application/octet-stream
    // 1. 拼接上传文件的上边界信息
#warning 有些服务器可以直接使用\n，但是有些POST就比如新浪微博如果使用 \n 上传文件，服务器会返回“没有权限”的错误! 因此一定要注意安全换行:\r\n
    NSMutableString *headerStrM = [NSMutableString stringWithFormat:@"\r\n--%@\r\n", kBoundary];
    // name=%@ :服务器接收参数的key值，后台工作人员告诉我们
    // filename=%@ :文件上传到服务器的存储名，若不设置则为默认名，名称保持不变
    [headerStrM appendFormat:@"Content-Disposition: form-data; name=%@; filename=%@\r\n", @"userfile", @"123" ];
    // Content-Type: application/octet-stream 表明文件的上传类型，乱写类型不会影响上传，但是不符合规范
    [headerStrM appendString:@"Content-Type: application/octet-stream\r\n\r\n"];
    // 将上传文件的上边界信息添加到请求体中
    [data appendData:[headerStrM dataUsingEncoding:NSUTF8StringEncoding]];
    // 2. 设置文件内容
    // 文件地址
    NSString *filePath = [@"/Users/Chan/Desktop/ViewController.h" stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    [data appendData:fileData];
    // 3. 设置文件的下边界
    // -----------------------------198596859919834017191791522499--
    NSString *footerStrM = [NSString stringWithFormat:@"\r\n--%@--", kBoundary];
    [data appendData:[footerStrM dataUsingEncoding:NSUTF8StringEncoding]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                        NSLog(@"resonse = %@ \n data = %@",response,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                    }];
    [task resume];
}

@end
