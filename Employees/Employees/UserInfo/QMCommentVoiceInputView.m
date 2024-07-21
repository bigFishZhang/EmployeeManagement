//
//  QMCommentVoiceInputView.m
//  QQMusic
//
//  Created by leozbzhang on 2024/6/19.
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "QMCommentVoiceInputView.h"
#import "QMVoiceTouchButton.h"
#import "UIView+Position.h"
#import "ColorDefine.h"


@interface QMCommentVoiceInputView ()

@property (nonatomic, strong) QMVoiceTouchButton *voiceTouchButton;

// 大标题
@property (nonatomic, strong) UILabel *firstLabel;

// 小标题
@property (nonatomic, strong) UILabel *secondLabel;

/// 重录
@property (nonatomic, strong) UIButton *reRecordButton;

/// 发送消息按钮
@property (nonatomic, strong) UIButton *sendButton;

/// 录制好的音频视图
@property (nonatomic, strong) UIButton *voiceBtn;
@property (nonatomic, strong) UIImageView *voiceIcon;
@property (nonatomic, strong) UILabel *voiceLabel;

@property (nonatomic, assign) BOOL isRecording;

//TODO:leo 倒计时
@end

@implementation QMCommentVoiceInputView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.isRecording = NO;
        [self buildAllSubview];
    }
    return self;
}


- (void)buildAllSubview
{
    
    self.voiceBtn.layer.masksToBounds = YES;
    self.voiceBtn.layer.cornerRadius = 17.5;
    self.voiceBtn.frame = CGRectMake((self.width - 200) /2 , 0, 200, 35);
    self.voiceBtn.centerY = self.centerY;
    
    self.voiceIcon = [[UIImageView alloc] init];
    self.voiceIcon.image = [UIImage imageNamed:@"11"];
    self.voiceIcon.frame = CGRectMake(12, 9.5, 11, 16);
    self.voiceIcon.centerY = self.voiceIcon.centerY;
    [self.voiceBtn addSubview:self.voiceIcon];
    
    self.voiceLabel = [[UILabel alloc] init];
    self.voiceLabel.text = @"语音长度...";
    self.voiceLabel.frame = CGRectMake(self.voiceIcon.getRight + 10, 9.5, 200 - self.voiceIcon.getRight - 20, 16);
    self.voiceLabel.centerY = self.voiceIcon.centerY;
    [self.voiceBtn addSubview:self.voiceIcon];
    
    self.firstLabel.centerX = self.voiceTouchButton.centerX;
    self.secondLabel.centerX = self.voiceTouchButton.centerX;
    
    [self addSubview:self.voiceTouchButton];
    [self addSubview:self.firstLabel];
    [self addSubview:self.secondLabel];
    [self addSubview:self.voiceBtn];
    [self addSubview:self.reRecordButton];
    [self addSubview:self.sendButton];
    
        
    // 默认展示录制按钮和2行标题
    [self updateStarRecordUI];
    
}


- (void)updateStarRecordUI
{
    AudioComment(@"开始录制更新UI");
    self.firstLabel.hidden = NO;
    self.secondLabel.hidden = NO;
    self.voiceTouchButton.hidden = NO;
    self.sendButton.hidden = YES;
    self.reRecordButton.hidden = YES;
    self.voiceBtn.hidden = YES;
    
    self.voiceTouchButton.frame = CGRectMake(0, 0, 85, 85);
    self.voiceTouchButton.centerX = self.centerX;
    self.voiceTouchButton.centerY = self.centerY - 24;
    
    self.firstLabel.frame = CGRectMake(0,  self.voiceTouchButton.getBottom + 14, SCREEN_WIDTH, 22);
    self.secondLabel.frame = CGRectMake(0,  self.firstLabel.getBottom + 10, SCREEN_WIDTH, 15);

}

- (void)updateEndRecordUIWithTimeStr:(NSString *)timeStr
{
    //显示录制结果
    AudioComment(@"录制完成更新UI,录制时长%@",timeStr);
    self.firstLabel.hidden = YES;
    self.secondLabel.hidden = YES;
    self.voiceTouchButton.hidden = YES;
    self.sendButton.hidden = NO;
    self.reRecordButton.hidden = NO;
    self.voiceBtn.hidden = NO;
    
}

- (void)voicePlayBtnPressed:(id)sender
{
    //DOTO:leo
    AudioComment(@"点击播放音频");
    if ([self.delegate respondsToSelector:@selector(didClickedPlayVoice)])
    {
        [self.delegate didClickedPlayVoice];
    }
}

- (void)voiceSendBtnPressed:(id)sender
{
    //DOTO:leo
    AudioComment(@"点击播放音频");
    if ([self.delegate respondsToSelector:@selector(didClickedSendVoiceComment)])
    {
        [self.delegate didClickedSendVoiceComment];
    }
}



- (void)voiceTouchButtonPressed:(id)sender
{
    self.firstLabel.hidden = NO;
    self.secondLabel.hidden = NO;
    self.voiceTouchButton.hidden = NO;
    //TODO:leo 按钮放大 标题下移？
    self.isRecording = !self.isRecording;
    if(self.isRecording)
    {
        _firstLabel.text = @"正在识别";
        _firstLabel.text = @"60秒";
        self.voiceTouchButton.frame = CGRectMake(0, 0, 152, 152);
        self.voiceTouchButton.centerX = self.centerX;
        self.voiceTouchButton.centerY = self.centerY - 24;
        
        self.firstLabel.frame = CGRectMake(0,  self.voiceTouchButton.getBottom + 14, self.width, 22);
        self.secondLabel.frame = CGRectMake(0,  self.firstLabel.getBottom + 10, self.width, 15);
        self.firstLabel.centerX = self.centerX;
        self.secondLabel.centerX = self.centerX;
    }
    else
    {
        _firstLabel.text = @"按住识别";
        _firstLabel.text = @"最长60秒，录完松开后点击发送";
        self.voiceTouchButton.frame = CGRectMake(0, 0, 85, 85);
        self.voiceTouchButton.centerX = self.centerX;
        self.voiceTouchButton.centerY = self.centerY;
        
        self.firstLabel.frame = CGRectMake(0,  self.voiceTouchButton.getBottom + 14, self.width, 22);
        self.secondLabel.frame = CGRectMake(0,  self.firstLabel.getBottom + 10, self.width, 15);

    }
    
}
#pragma mark - Lazy

- (QMVoiceTouchButton *)voiceTouchButton
{
    if (!_voiceTouchButton)
    {
        _voiceTouchButton = [[QMVoiceTouchButton alloc] initWithFrame:CGRectZero];
        [_voiceTouchButton addTarget:self action:@selector(voiceTouchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _voiceTouchButton;
}

- (UILabel *)firstLabel
{
    if(!_firstLabel)
    {
        _firstLabel = [[UILabel alloc] init];
        _firstLabel.font = [ComHelper regularSystemFontOfSize:16];
        _firstLabel.textColor = RGB(0, 0, 0);
        _firstLabel.text = @"按住识别";
        _firstLabel.textAlignment = NSTextAlignmentCenter;
        // r 16
    }
    return _firstLabel;
}


- (UILabel *)secondLabel
{
    if(!_secondLabel)
    {
        _secondLabel = [[UILabel alloc] init];
        _secondLabel.font = [ComHelper regularSystemFontOfSize:12];
        _secondLabel.textColor = RGBA(0, 0, 0, 255*0.6);
        _secondLabel.text = @"最长60秒，录完松开后点击发送";
        _secondLabel.textAlignment = NSTextAlignmentCenter;
        // r 16
    }
    return _secondLabel;
}


- (UIButton *)reRecordButton
{
    if(!_reRecordButton)
    {
        _reRecordButton = [[UIButton alloc] init];
        _reRecordButton.titleLabel.text = @"重录";
        _reRecordButton.titleLabel.font = [ComHelper mediumSystemFontOfSize:15];
        _reRecordButton.backgroundColor = [UIColor whiteColor];
        _reRecordButton.hidden = YES;
    }
    return _reRecordButton;
}

- (UIButton *)sendButton
{
    if(!_sendButton)
    {
        _sendButton = [[UIButton alloc] init];
        _sendButton.titleLabel.text = @"发送";
        _sendButton.titleLabel.font = [ComHelper mediumSystemFontOfSize:15];
        _sendButton.backgroundColor = COM_GLOBAL_GREEN_COLOR;
        _sendButton.hidden = YES;
        [_sendButton addTarget:self action:@selector(voiceSendBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

- (UIButton *)voiceBtn
{
    if(!_voiceBtn)
    {
        _voiceBtn = [[UIButton alloc] init];
        _voiceBtn.backgroundColor = [UIColor whiteColor];
        [_voiceBtn addTarget:self action:@selector(voicePlayBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        _voiceBtn.hidden = YES;
    }
    return _voiceBtn;
}



@end
