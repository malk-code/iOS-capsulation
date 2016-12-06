//
//  BaseModel.m
//  Timas
//
//  Created by Timas on 16/8/29.
//  Copyright © 2016年 Malk. All rights reserved.
//

#import "BaseModel.h"
#import <objc/runtime.h>

@interface BaseModel ()

@property (nonatomic, copy)NSArray *arrPropertyValue;
@property (nonatomic, copy)NSArray *arrPropertyKey;
@property (nonatomic, copy)NSDictionary *dicProperty;
@end
@implementation BaseModel

#pragma mark - 子类不需要实现，为空即监听setter做处理
- (instancetype)initWithDic:(NSDictionary *)dic
{
    if (self = [super init])
    {
        [self setValuesForKeysWithDictionary:dic];
    }
    return self;
}

+ (instancetype)modelWithDic:(NSDictionary *)dic
{
    return [[self alloc] initWithDic:dic];
}

#pragma mark - 将模型抽取为obj对象（字典或集合）
- (id)achievePropertyObjWithRange:(NSRange)range ReturnType:(PropertyObjType)returnType
{
    id props = nil;
    
    if (returnType)
    {
        props = [NSMutableArray array];
    } else
    {
        props = [NSMutableDictionary dictionary];
    }
    
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    for (NSInteger i = range.location; i < range.length; i++)
    {
        objc_property_t property = properties[i];
        const char* char_f =property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        id propertyValue = [self valueForKey:(NSString *)propertyName];
       
        if (propertyValue)
        {
            if (returnType)
            {
                if (returnType == PropertyArrTypeValues)
                {
                    [props addObject:propertyValue];
                } else if (returnType == PropertyArrTypeKeys)
                {
                    [props addObject:propertyName];
                }
            } else{
                props[propertyName] = propertyValue;
            }
        }
    }
    free(properties);
    return props;
}

- (id)achievePropertyObjWithReturnType:(PropertyObjType)returnType
{
    return [self achievePropertyObjWithRange:NSMakeRange(0, self.maxPropertyCount) ReturnType:returnType];
}

#pragma mark - 获取当前模型的obj（不能懒加载）
- (NSArray *)arrPropertyKey
{
    return [self achievePropertyObjWithReturnType:PropertyArrTypeKeys];
}

- (NSArray *)arrPropertyValue
{
    return [self achievePropertyObjWithReturnType:PropertyArrTypeValues];
}

- (NSDictionary *)dicProperty
{
    return [self achievePropertyObjWithReturnType:PropertyDicType];
}

- (NSInteger)maxPropertyCount
{
    unsigned int outCount;
    class_copyPropertyList([self class], &outCount);
    
    return outCount;
}
#pragma mark - 数据库
+ (instancetype)DBManager
{
    return nil;
}

+ (instancetype)DBManagerWithTableName:(NSString *)tableName ColumnsName:(NSArray<NSString *> *)columnsName
{
    return [self DBManager];
}

#pragma mark - 数据库单例
#if 0
+ (instancetype)DBManager
{
    [singleTon openDB];
    
    return singleTon;
}

+ (instancetype)DBManagerWithTableName:(NSString *)tableName ColumnsName:(NSArray<NSString *> *)columnsName
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      singleTon = [[self alloc] init];
                      
                      singleTon.DBTableName = tableName;
                      singleTon.DBColumnsName = columnsName;
                      
                      [singleTon createDBWithMainModelClass:NSClassFromString(@"OrderModel")];
                  });
    
    return singleTon;
}
#endif
@end
