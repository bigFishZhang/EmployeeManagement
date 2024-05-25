#ifdef __cplusplus
extern "C" {
#endif

id QMSafeCastObject(id obj, Class classType);
id QMSafeCastProtocol(id obj, Protocol *protocolType);

#ifdef __cplusplus
}
#endif

#ifndef SAFE_CAST

/**
 安全无比的类型转换
 
 @b Tag 类型转换 安全
 */
#define SAFE_CAST(obj, asClass)  QMSafeCastObject(obj, [asClass class])
#define SAFE_CAST_PROTOCOL(obj, asClass)  QMSafeCastProtocol(obj, @protocol(asClass))
#endif
