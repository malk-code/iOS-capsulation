//
//  BaseModel.h
//  Timas
//
//  Created by Timas on 16/8/29.
//  Copyright © 2016年 Malk. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PropertyObjType)
{
    PropertyDicType = 0,      // unordered property
    PropertyArrTypeValues,    // Orderly property: value
    PropertyArrTypeKeys,      // Orderly property: key
};
@interface BaseModel : NSObject

@property (nonatomic)NSInteger maxPropertyCount;

// 获取当前模型的obj
@property (nonatomic, readonly, copy)NSArray *arrPropertyValue;
@property (nonatomic, readonly, copy)NSArray *arrPropertyKey;
@property (nonatomic, readonly, copy)NSDictionary *dicProperty;

/** 将属性转为obj (字典或集合, 开始但不包含长度位置的属性_从0开始) */
- (id)achievePropertyObjWithRange:(NSRange)range ReturnType:(PropertyObjType)returnType;
/** 将属性转为obj (字典或集合：key或value, 所有属性) */
- (id)achievePropertyObjWithReturnType:(PropertyObjType)returnType;

/** 模型化为避免难处理空情况，可以使用MJExtension给属性赋值 */
+ (instancetype)modelWithDic:(NSDictionary *)dic;

#pragma mark - 数据库
// 单例携带参数 (只需要赋值)
@property (nonatomic, copy)NSString *DBTableName;
@property (nonatomic, copy)NSArray  *DBColumnsName;

// 初始化操作对象（子类实现）
+ (instancetype)DBManager;
+ (instancetype)DBManagerWithTableName:(NSString *)tableName ColumnsName:(NSArray<NSString *> *)columnsName;
@end
