//
//  NSDictionary+Json.m
//
//  Created by leo on 2019/5/27.

//

#import "NSDictionary+Json.h"

@implementation NSDictionary (Json)

#pragma mark - NSDictionary

- (NSDictionary *)dicForKey:(NSString *)key
{
    return [JsonHelper getDicFromDictionaryWithDefaultNil:self forKey:key];
}

- (NSDictionary *)dicNotNilForKey:(NSString *)key
{
    return [JsonHelper getDicFromDictionaryWithDefaultEmptyDictionary:self forKey:key];
}

- (NSDictionary *)dicForKey:(NSString *)key ifNilThen:(NSDictionary *)defaultDic
{
    return [JsonHelper getDicFromDictionary:self forKey:key withDefault:defaultDic];
}

- (void)enumerateDicForKey:(NSString *)key usingBlock:(void (^)(id<NSCopying> key, id obj, BOOL *stop))block;
{
    if (block)
    {
        NSDictionary *dic = [JsonHelper getDicFromDictionaryWithDefaultEmptyDictionary:self forKey:key];
        [dic enumerateKeysAndObjectsUsingBlock:block];
    }
}

#pragma mark - NSArray

- (NSArray *)arrayForKey:(NSString *)key
{
    return [JsonHelper getArrayFromDictionaryWithDefaultNil:self forKey:key];
}

- (NSArray *)arrayNotNilForKey:(NSString *)key
{
    return [JsonHelper getArrayFromDictionaryWithDefaultEmptyArray:self forKey:key];
}

- (NSArray *)arrayForKey:(NSString *)key ifNilThen:(NSArray *)defaultArray
{
    return [JsonHelper getArrayFromDictionary:self forKey:key withDefault:defaultArray];
}

- (NSArray *)arrayForKey:(NSString *)key withElementClass:(Class)classType
{
    NSArray *array = [JsonHelper getArrayFromDictionaryWithDefaultNil:self forKey:key];
    if (classType == nil || array.count == 0)
    {
        return array;
    }
    
    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isKindOfClass:classType])
        {
            [indexes addIndex:idx];
        }
    }];
    
    if (indexes.count == array.count)
    {
        return nil;
    }
    
    NSMutableArray *marray = [array mutableCopy];
    [marray removeObjectsAtIndexes:indexes];
    return marray.copy;
}

- (void)enumerateArrayForKey:(NSString *)key usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block
{
    if (block)
    {
        NSArray *array = [JsonHelper getArrayFromDictionaryWithDefaultEmptyArray:self forKey:key];
        [array enumerateObjectsUsingBlock:block];
    }
}

- (void)enumerateDicInArrayForKey:(NSString *)arrayKey usingBlock:(void (^)(NSDictionary *dic, NSUInteger idx, BOOL *stop))block
{
    if (block)
    {
        NSArray *array = [JsonHelper getArrayFromDictionaryWithDefaultEmptyArray:self forKey:arrayKey];
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger originalIdx, BOOL * _Nonnull originalStop) {
            NSDictionary *dic = SAFE_CAST(obj, NSDictionary);
            if (dic)
            {
                block(dic, originalIdx, originalStop);
            }
        }];
    }
}

#pragma mark - NSString

- (NSString *)stringForKey:(NSString *)key
{
    return [JsonHelper getStringFromDictionaryWithDefaultNil:self forKey:key isBase64Format:NO];
}

- (NSString *)stringNotNilForKey:(NSString *)key
{
    return [JsonHelper getStringFromDictionaryWithDefaultEmptyString:self forKey:key isBase64Format:NO];
}

- (NSString *)stringForKey:(NSString *)key ifNilThen:(NSString *)defaultString
{
    return [JsonHelper getStringFromDictionary:self forKey:key isBase64Format:NO withDefault:defaultString];
}

- (NSString *)stringForKeys:(NSArray<NSString *> *)keys ifNilThen:(NSString *)defaultString
{
    return [JsonHelper getStringFromDictionary:self forKeys:keys isBase64Format:NO withDefault:defaultString];
}
#pragma mark Base64

- (NSString *)stringBase64DecodeForKey:(NSString *)key
{
    return [JsonHelper getStringFromDictionaryWithDefaultNil:self forKey:key isBase64Format:YES];
}

- (NSString *)stringNotNilBase64DecodeForKey:(NSString *)key
{
    return [JsonHelper getStringFromDictionaryWithDefaultEmptyString:self forKey:key isBase64Format:YES];
}

- (NSString *)stringBase64DecodeForKey:(NSString *)key ifNilThen:(NSString *)defaultString
{
    return [JsonHelper getStringFromDictionary:self forKey:key isBase64Format:YES withDefault:defaultString];
}

- (NSString *)stringBase64DecodeForKeys:(NSArray<NSString *> *)keys ifNilThen:(NSString *)defaultString
{
    return [JsonHelper getStringFromDictionary:self forKeys:keys isBase64Format:YES withDefault:defaultString];
}

#pragma mark - int64_t

- (int64_t)intForKey:(NSString *)key
{
    return [JsonHelper getIntegerFromDictionary:self forKey:key];
}

- (int64_t)intForKey:(NSString *)key ifNilThen:(int64_t)defaultInt
{
    return [JsonHelper getIntegerFromDictionary:self forKey:key withDefault:defaultInt];
}

#pragma mark - uint64_t

- (uint64_t)uintForKey:(NSString *)key
{
    return [JsonHelper getUnsignedIntegerFromDictionary:self forKey:key];
}

- (uint64_t)uintForKey:(NSString *)key ifNilThen:(uint64_t)defaultUInt
{
    return [JsonHelper getUnsignedIntegerFromDictionary:self forKey:key withDefault:defaultUInt];
}

#pragma mark - double

- (double)doubleForKey:(NSString *)key
{
    return [JsonHelper getDoubleFromDictionary:self forKey:key];
}

- (double)doubleForKey:(NSString *)key ifNilThen:(double)defaultDouble
{
    return [JsonHelper getDoubleFromDictionary:self forKey:key withDefault:defaultDouble];
}

-(NSString*)toJsonString
{
    if ([NSJSONSerialization isValidJSONObject:self])
    {
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
        ASSERT(error == nil);
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else
    {
        return nil;
    }
}

@end
