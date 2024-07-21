//
//  QMCommentVoiceInputView.h
//  QQMusic
//
//  Created by leozbzhang on 2024/6/19.
//  Copyright © 2024 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol QMCommentVoiceInputViewDeleagte <NSObject>

- (void)didClickedPlayVoice;
- (void)didClickedSendVoiceComment;

@end

@interface QMCommentVoiceInputView : UIView

@property (nonatomic, weak) id<QMCommentVoiceInputViewDeleagte> delegate;

- (void)updateStarRecordUI;

- (void)updateEndRecordUIWithTimeStr:(NSString *)timeStr;




@end

NS_ASSUME_NONNULL_END
