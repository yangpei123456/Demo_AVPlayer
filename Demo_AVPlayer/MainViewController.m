//
//  MainViewController.m
//  Demo_AVPlayer
//
//  Created by caozhenwei on 16/1/27.
//  Copyright © 2016年 caozhenwei. All rights reserved.
//

#import "MainViewController.h"
#import "Myplay.h"
#import "ShareViewControl.h"
#define K_x 0
#define K_w [[UIScreen mainScreen] bounds].size.width
#define K_h [[UIScreen mainScreen] bounds].size.height
#define K_strUrl @"http://mw5.dwstatic.com/2/4/1529/134981-99-1436844583.mp4"
#define K_topViewHeight 80
#define K_rightViewWidth 80
#define K_bottomViewHeight 80
@interface MainViewController ()<UIGestureRecognizerDelegate>
{
    //是否播放
    BOOL isPlay;
    //播放器元素
    AVPlayerItem* playerItem;
    float progressSlider;
}

//上面视图播放正在进行(当播放完成时变成结束提示)
@property (weak, nonatomic) IBOutlet UIButton *Playing;
//播放视频进度条
@property (weak, nonatomic) IBOutlet UISlider *topProgressSlider;
//播放时间
@property (weak, nonatomic) IBOutlet UILabel *playTime;
//播放剩余时间
@property (weak, nonatomic) IBOutlet UILabel *totalPlayTime;
//顶部视图(点击屏幕动漫隐藏)
@property (weak, nonatomic) IBOutlet UIView *topView;
//右边视图(点击屏幕动漫隐藏)
@property (weak, nonatomic) IBOutlet UIView *rightView;
//底部视图
@property (weak, nonatomic) IBOutlet UIView *bottomView;
//播放图层
@property(nonatomic,strong)AVPlayerLayer* playLayer;
//封装的类
@property(nonatomic,strong)Myplay* playerHelp;
//手势横屏下第一次点击
@property(nonatomic,assign)BOOL isFirstRotatorTap;
//竖屏下第一次点击
@property(nonatomic,assign)BOOL isFirstVeticalTap;
//设置总时长
@property(nonatomic,assign)CGFloat totalMovieTime;
//暂停按钮
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;
//继续播放
@property (weak, nonatomic) IBOutlet UIButton *playBtn;


- (IBAction)pauseBtn:(id)sender;

@end

@implementation MainViewController


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //创建一个播放器
    
    [self setMoviePlay];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置播放进度值
    self.topProgressSlider.value = 0.0;
    //添加手势
    [self addGestureRecognizer];
    //添加一个观察者来监控播放和横竖屏事件
    [self addNotificationCenter];
    //添加播放器
    [self addPlayer];
    
}

-(void)addPlayer{
    //通过播放元素监控
    playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:K_strUrl]];
    //设置播放器
    self.playerHelp = [[Myplay alloc] init];
    [self.playerHelp initWithAVPlayerAndAVPlayerItem:playerItem];
    //创建播放图层
    self.playLayer = [AVPlayerLayer playerLayerWithPlayer:self.playerHelp.getAVPlayer];
    //设置播放图层重力
    self.playLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    //设置视图竖屏frame
    [self setFrameVical];
    
    //设置视屏填充模式
    self.playLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //添加到视图上
    //[self.view.layer insertSublayer:self.playLayer below:self.rightView.layer];
    [self.view.layer insertSublayer:self.playLayer atIndex:0];
    //监听slider,设置时间进程，和总时间
    [self addSliderObserver];
}
#pragma mark 设置播放slider
-(void)addSliderObserver{
    //设置每秒执行一次播放
    [self.playerHelp.getAVPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        //此处queue的参数不能指向直线程，则会会出现未被Cash的Bug,会使程序不稳定
        NSLog(@"什么线程%@",[NSThread currentThread]);
        NSLog(@"进度 %f",self.topProgressSlider.value);
        //获取当前播放时间
        CMTime currentTime = self.playerHelp.getAVPlayer.currentItem.currentTime;
        //转化成秒
        CGFloat currentPlayTime = (CGFloat)currentTime.value / currentTime.timescale;
        //总时间---playerItem的值是时刻改变，要设置item
        CMTime totalTime = playerItem.duration;
        _totalMovieTime = (CGFloat)totalTime.value / totalTime.timescale;
        //slider的值
        self.topProgressSlider.value = CMTimeGetSeconds(currentTime) / _totalMovieTime;
        progressSlider = CMTimeGetSeconds(currentTime) / _totalMovieTime;
        //设置播放时间的label
        NSDate *playCurrentTime = [NSDate dateWithTimeIntervalSince1970:currentPlayTime];
        
        self.playTime.text = [self getTimeByDate:playCurrentTime OfProgress:currentPlayTime];
        NSLog(@"时间是 %@",self.playTime.text);
        //设置剩余时间
        CGFloat surplusTime = _totalMovieTime - currentPlayTime;
        NSDate *DateSurplusTime = [NSDate dateWithTimeIntervalSince1970:surplusTime];
        self.totalPlayTime.text = [self getTimeByDate:DateSurplusTime OfProgress:currentPlayTime];
    }];
    
    //设置slider的图片
    [self.topProgressSlider setThumbImage:[UIImage imageNamed:@"media_Player_progress_bar@3x.png"] forState:UIControlStateNormal];
    [self.topProgressSlider setThumbImage:[UIImage imageNamed:@"slider-metal-handle.png"] forState:UIControlStateHighlighted];
    
}
#pragma mark --- 一下三个方法优化程序可有可无
-(void)addPlayerItemObserver:(AVPlayerItem*)playItem{
    
    [playItem addObserver:self forKeyPath:@"status" options: NSKeyValueObservingOptionNew context:nil];
    [playItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
}
-(void)removePlayerItemObserver:(AVPlayerItem*)playItem{
    
    [playItem removeObserver:self forKeyPath:@"status"];
    [playItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    
}
//系统方法--监听status和loadedTimeRanges
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    AVPlayerItem* playItem = (AVPlayerItem*)object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if (status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"视频总长度: %.2f",CMTimeGetSeconds(playItem.duration));
            //视频总长度
            CMTime totalTime = playItem.duration;
            self.totalMovieTime = totalTime.value / totalTime.timescale;
        }
    }if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        //缓冲时间范围
        NSArray* array = playItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //缓冲区总长度
        NSTimeInterval bufferSeconds = startSeconds+durationSeconds;
        NSLog(@"缓冲区总长度 %.2f",bufferSeconds);
        NSLog(@"进度 + %.2f",progressSlider);
        self.topProgressSlider.value = progressSlider;
        
    }
}

//秒的转化
-(NSString*)getTimeByDate:(NSDate*)date OfProgress:(float)progress{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    if (progress / 3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    }else{
        [formatter setDateFormat:@"mm:ss"];
    }
    
    return [formatter stringFromDate:date];
}

//播放器图层
-(void)addNotificationCenter{
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveDidPayEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //监听横竖屏
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
}
//监听横竖屏
-(void)statusBarChange:(NSNotificationCenter*)notifi{
    //定义旋转对象
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait) {
        //设置frame
        [self setFrameVical];
        isPlay = YES;
        
    }if (orientation == UIInterfaceOrientationLandscapeRight) {
        [self setFramehorizontal];
        isPlay = YES;
    }if (orientation == UIInterfaceOrientationLandscapeLeft) {
        [self setFramehorizontal];
        isPlay = YES;
    }
}
//播放完后
-(void)moveDidPayEnd{
    //设置top bottom rightView的显示
    [self setTopBottomRightHiddenShow];
    //播放完后停止播放
    [self.playerHelp.getAVPlayer pause];
    isPlay = NO;
    //循环播放
    //[self.playerHelp.getAVPlayer seekToTime:CMTimeMake(0, 1)];
    //[self.playerHelp.getAVPlayer play];
    
}
-(void)setTopBottomRightHiddenShow{
    self.topView.hidden = NO;
    self.rightView.hidden = NO;
    self.bottomView.hidden = NO;
}
//添加手势
-(void)addGestureRecognizer{
    UIGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissAllSubViews:)];
    tap.delegate = self;
    //将手势添加到视图上
    [self.view addGestureRecognizer:tap];
}
//实现动漫手势消失所有视图
-(void)dismissAllSubViews:(UITapGestureRecognizer*)tap{
    __weak typeof (self)myself = self;
    //设置这个约束，来改变frame值
    myself.topView.translatesAutoresizingMaskIntoConstraints = YES;
    myself.bottomView.translatesAutoresizingMaskIntoConstraints = YES;
    myself.rightView.translatesAutoresizingMaskIntoConstraints = YES;
    if (!self.isFirstRotatorTap) {
        [UIView animateWithDuration:0.2f animations:^{
            myself.topView.frame = CGRectMake(myself.topView.bounds.origin.x, -K_topViewHeight, myself.topView.bounds.size.width, myself.topView.bounds.size.height);
            //myself.rightView.hidden = YES;
            myself.rightView.frame = CGRectMake(K_w, myself.rightView.frame.origin.y, myself.rightView.frame.size.width, myself.rightView.frame.size.height);
            myself.bottomView.frame = CGRectMake(myself.bottomView.bounds.origin.x, K_h, myself.bottomView.bounds.size.width, myself.bottomView.bounds.size.height);
            [myself.view addSubview:myself.bottomView];
        }];
        self.isFirstRotatorTap = YES;
    }else{
        [UIView animateWithDuration:0.2f animations:^{
            myself.topView.frame = CGRectMake(myself.topView.bounds.origin.x, 0,myself.topView.bounds.size.width, myself.topView.bounds.size.height);
            // myself.rightView.hidden = NO;
            myself.rightView.frame = CGRectMake(K_w-K_rightViewWidth, myself.rightView.frame.origin.y, myself.rightView.frame.size.width, myself.rightView.frame.size.height);
            myself.bottomView.frame = CGRectMake(myself.bottomView.bounds.origin.x, K_h-K_bottomViewHeight, myself.bottomView.bounds.size.width, myself.bottomView.bounds.size.height);
            [self.view layoutIfNeeded];
        }];
        //不是第一次响应
        self.isFirstRotatorTap = NO;
    }
}
#pragma mark 播放
-(void)setMoviePlay{
    //播放
    [self.playerHelp.getAVPlayer play];
    //播放的一个标记
    isPlay = YES;
}
#pragma mark 暂停
-(void)setMoviePause{
    
    [self.playerHelp.getAVPlayer pause];
    
}
//设置竖屏播放视图
-(void)setFrameVical{
    CGRect iFrame = self.view.bounds;
    iFrame.origin.x = 0;
    iFrame.origin.y = (K_h - K_w*(K_w)/K_h)/2;
    iFrame.size.width = K_w;
    iFrame.size.height = K_w*(K_w)/K_h;
    self.playLayer.frame = iFrame;
    
}

//设置横屏frame
-(void)setFramehorizontal{
    CGRect iFrame = self.view.frame;
    iFrame.origin.x = 0;
    iFrame.origin.y = 0;
    iFrame.size.width = K_w;
    iFrame.size.height = K_h;
    self.playLayer.frame = iFrame;
    
}
//点击播放进度条改变播放进度
- (IBAction)changePlayProgressSlider:(id)sender {
    UISlider* slider = (UISlider*)sender;
    //获取当前slider的值对应的播放时长
    double currentTime = floor(self.totalMovieTime*slider.value);
    //当拖到currentTime位置时，播放器从此位置开始播放并且到1停止
    CMTime currentTimePlay = CMTimeMake(currentTime, 1);
    [self.playerHelp.getAVPlayer seekToTime:currentTimePlay completionHandler:^(BOOL finished) {
        [self.playerHelp.getAVPlayer play];
    }];
}
//点击分享
- (IBAction)shareContent:(id)sender {
    //点击分享弹出提示框
    UIAlertController* aler = [UIAlertController alertControllerWithTitle:nil message:@"是否分享" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* canceAction = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"取消");
    }];
    UIAlertAction* tureAcion = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"确定");
        //分享就要停止视频播放
        [self.playerHelp.getAVPlayer pause];
        //多个storyboard之间跳转设置
        UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"ShareStoryboard" bundle:nil];
        ShareViewControl* share = [secondStoryBoard instantiateViewControllerWithIdentifier:@"ShareStoryboard"];  //test2为viewcontroller的StoryboardId
        [self presentViewController:share animated:YES completion:nil];
    }];
    //添加
    [aler addAction:canceAction];
    [aler addAction:tureAcion];
    //推出
    [self presentViewController:aler animated:YES completion:nil];
    
}
//点击收藏--存储在手机相册中
- (IBAction)Collection:(id)sender {
}
//缓存
- (IBAction)Save:(id)sender {
}


#pragma mark UIGestureRecognizerDelegate协议
-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    //停止子视图手势响应--UIGestureRecognizerDelegate有一个方法
    if (CGRectContainsPoint(self.topView.frame, [gestureRecognizer locationInView:self.view]) || CGRectContainsPoint(self.rightView.frame, [gestureRecognizer locationInView:self.view]) || CGRectContainsPoint(self.bottomView.frame, [gestureRecognizer locationInView:self.view])) {
        return NO;
    }else{
        return YES;
    };
}

//当不在使用观察者模式时需移除并释放内存
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //移除改变屏幕横屏竖屏播放状态时的监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    //返回界面时释放播放内存
    [self.playerHelp.getAVPlayer replaceCurrentItemWithPlayerItem:nil];
    NSLog(@"----内存释放----");
    
}
/**
 暂停,播放按钮设置
 */
- (IBAction)playBtn:(id)sender {
    [self.playerHelp.getAVPlayer play];
    self.playBtn.hidden = YES;
    self.pauseBtn.hidden = NO;
}
- (IBAction)pauseBtn:(id)sender {
    self.pauseBtn.hidden = YES;
    self.playBtn.hidden = NO;
    [self setMoviePause];
    
}
@end
