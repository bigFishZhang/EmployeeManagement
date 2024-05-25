#import <Foundation/Foundation.h>
#import "SafeCast.h"
id QMSafeCastObject(id obj, Class classType)
{
    if ([obj isKindOfClass:classType])
    {
        return obj;
    }
    return classType ? nil : obj;
}

id QMSafeCastProtocol(id obj, Protocol* protocolType)
{
    if ([obj conformsToProtocol:protocolType])
    {
        return obj;
    }
    return protocolType ? nil : obj;
}
