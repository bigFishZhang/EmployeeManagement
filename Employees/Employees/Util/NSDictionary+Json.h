//
//  NSDictionary+Json.h
//
//  Created by leo on 2019/5/27.
//


@interface NSDictionary (Json)

#pragma mark - NSDictionary

// JSON取Dic，可能为nil
- (NSDictionary *)dicForKey:(NSString *)key;

// JSON取Dic，至少为空Dic
- (NSDictionary *)dicNotNilForKey:(NSString *)key;

// JSON取Dic，nil则用default
- (NSDictionary *)dicForKey:(NSString *)key ifNilThen:(NSDictionary *)defaultDic;

// JSON对Dic进行遍历
- (void)enumerateDicForKey:(NSString *)key usingBlock:(void (^)(id<NSCopying> key, id obj, BOOL *stop))block;

// 转换成JSON字符串
-(NSString*)toJsonString;

#pragma mark - NSArray

// JSON取Array，可能为nil
- (NSArray *)arrayForKey:(NSString *)key;

// JSON取Array，至少为空Array
- (NSArray *)arrayNotNilForKey:(NSString *)key;

// JSON取Array，nil则用default
- (NSArray *)arrayForKey:(NSString *)key ifNilThen:(NSArray *)defaultArray;

// JSON取Array，可能为nil，会确保返回的数组中的子元素一定是classType类型。
// 如果JSON里有对应的array，但是子元素都不符合特定类型，返回nil。
// 如果classType为nil，则等同于arrayForKey:方法。
- (NSArray *)arrayForKey:(NSString *)key withElementClass:(Class)classType;

// JSON对Array进行遍历
- (void)enumerateArrayForKey:(NSString *)key usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;

// JSON对Array进行遍历，一定会是Dic
- (void)enumerateDicInArrayForKey:(NSString *)arrayKey usingBlock:(void (^)(NSDictionary *dic, NSUInteger idx, BOOL *stop))block;

#pragma mark - NSString

// JSON取String，可能为nil
- (NSString *)stringForKey:(NSString *)key;

// JSON取String，至少为@""
- (NSString *)stringNotNilForKey:(NSString *)key;

// JSON取String，nil则用default
- (NSString *)stringForKey:(NSString *)key ifNilThen:(NSString *)defaultString;

// JSON取String，其中一个Key有值即可，没有Key有值则用default
- (NSString *)stringForKeys:(NSArray<NSString *> *)keys ifNilThen:(NSString *)defaultString;

#pragma mark Base64

// JSON取String，并Base64解码，可能为nil
- (NSString *)stringBase64DecodeForKey:(NSString *)key;

// JSON取String，并Base64解码，至少为@""
- (NSString *)stringNotNilBase64DecodeForKey:(NSString *)key;

// JSON取String，并Base64解码，nil则用default
- (NSString *)stringBase64DecodeForKey:(NSString *)key ifNilThen:(NSString *)defaultString;

// JSON取String，并Base64解码，其中一个Key有值即可，没有Key有值则用default
- (NSString *)stringBase64DecodeForKeys:(NSArray<NSString *> *)keys ifNilThen:(NSString *)defaultString;

#pragma mark - int64_t

// JSON取int64_t
- (int64_t)intForKey:(NSString *)key;

// JSON取int64_t，没有值则用default
- (int64_t)intForKey:(NSString *)key ifNilThen:(int64_t)defaultInt;

#pragma mark - uint64_t

// JSON取uint64_t
- (uint64_t)uintForKey:(NSString *)key;

// JSON取uint64_t，没有值则用default
- (uint64_t)uintForKey:(NSString *)key ifNilThen:(uint64_t)defaultUInt;

#pragma mark - double

// JSON取double
- (double)doubleForKey:(NSString *)key;

// JSON取double，没有值则用default
- (double)doubleForKey:(NSString *)key ifNilThen:(double)defaultDouble;

@end
