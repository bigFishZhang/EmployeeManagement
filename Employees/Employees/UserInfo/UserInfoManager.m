//
//  UserInfoManager.m
//  Employees
//
//  Created by fish on 2024/5/25.
//

#import "UserInfoManager.h"

@interface UserInfoManager ()

@property (nonatomic, copy) NSString *userName;
//@property (nonatomic, copy) NSString *passWord;
@property (nonatomic, assign) NSInteger userid;
@property (nonatomic, copy) NSString *token;

@property (nonatomic, strong) NSMutableArray *allImagelocalIdentifier;

@end

static UserInfoManager *manager = nil;

@implementation UserInfoManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allImagelocalIdentifier = [[NSMutableArray alloc] init];
        [self loadLocalMarkKey];
    }
    return self;
}

+ (instancetype)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (void)updateUserInfo:(NSString *)userName userid:(NSInteger)userid token:(NSString *)token
{
    self.userName = userName;
    self.userid = userid;
    self.token = token;
}

- (void)cleanLoginInfo
{
    self.userName = @"";
    self.userid = 0;
    self.token = @"";
}
- (NSInteger )getUserid
{
    return self.userid;
}
- (NSString *)getToken
{
    return self.token;
}


- (NSString*)timestamp
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval time=[date timeIntervalSince1970]*1000;
    return [NSString stringWithFormat:@"%.0f", time];
}

- (void)loadLocalMarkKey
{
    
    if (@available(iOS 12, *))
    {
        NSError *error = nil;
        NSData *storedData = [NSData dataWithContentsOfFile:[self loaclFilePath]];
        NSArray *array = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:storedData error:&error];

        if (error) {
            NSLog(@"Decode failed: %@", error);
        } else {
            // Now array contains the stored items
            [self.allImagelocalIdentifier addObjectsFromArray:array];
        }
    }
    else
    {
        NSArray *laocalMarks = [NSKeyedUnarchiver unarchiveObjectWithFile:[self loaclFilePath]];
        [self.allImagelocalIdentifier addObjectsFromArray:laocalMarks];
     
    }
    
    NSLog(@"local marks %lu",(unsigned long)self.allImagelocalIdentifier.count);
}

- (BOOL)checkNeedUploadWithKey:(NSString *)key;
{
    if(key.length > 0 && [self.allImagelocalIdentifier containsObject:key])
    {
        return NO;
    }
    return YES;
}

- (void)addImageUploadMark:(NSString *)key
{
    if(key.length > 0)
    {
        [self.allImagelocalIdentifier addObject:key];
       
        if (@available(iOS 12, *)){
            
            NSArray *array = [NSArray arrayWithArray:self.allImagelocalIdentifier];
            NSError *error = nil;
            NSData *encodedData = [NSKeyedArchiver archivedDataWithRootObject:array requiringSecureCoding:YES error:&error];

            if (error) {
                NSLog(@"Encode failed: %@", error);
            } else {
                // Save encodedData to disk
                [encodedData writeToFile:[self loaclFilePath] atomically:YES];
            }
        }
        else
        {
        
            [NSKeyedArchiver archiveRootObject:self.allImagelocalIdentifier toFile:[self loaclFilePath]];
        }
      
 
    }
}


- (NSString *)loaclFilePath
{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [path stringByAppendingPathComponent:@"Binterest.data"];
    return filePath;
}

@end
