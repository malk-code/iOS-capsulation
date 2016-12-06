//
//  BaseModel+DBManager.h
//  Timas
//
//  Created by Timas on 16/10/14.
//  Copyright © 2016年 Timas. All rights reserved.
//

#import "BaseModel.h"

// 模型单例：实现两个管理方法即可关联数据库
// 子模型创建表需要添加主表ID：调用带有主键初始化方法
// 主模型中子模型属性重写需要添加判断：数据库查询返回模型
// 数据库文件唯一：可针对不同用户添加唯一数据库文件

@interface BaseModel (DBManager)

#pragma mark - 数据库初始化
- (void)createDB;
- (void)openDB;
- (void)closeDB;
- (void)createDBWithMainModelClass:(Class)c;  // 从表


#pragma mark - 数据库单表操作
- (NSArray *)getAllModel;
- (BOOL)insertModel:(BaseModel *)model;
- (BOOL)deleteModel:(NSInteger)IDModel;
- (BOOL)updateModel:(BaseModel *)model;
- (BaseModel *)selectModelWithID:(NSInteger)IDModel;
- (BOOL)insertUseTransactionWithModels:(NSArray *)models;
- (NSArray *)selectModelWithModelProperty:(NSString *)field Value:(NSString *)value;
- (BOOL)deleteModelWithModelProperty:(NSString *)field Value:(NSString *)value;
- (BaseModel *)selectedModelMaxID;  // 最新插入
- (BOOL)deleteAllModelUseTransaction;

#pragma mark - 数据库主从表操作：对单表进行再次封装
// 在操作时进行关联，未在数据库内建立关联，采用单线程操作（KVC+子模型添加主模型ID进行关联）：因此主表中子模型字段可为空（KVC）
- (BOOL)insertWithModel:(BaseModel *)model SubModelClass:(Class)c SubModelProperty:(NSString *)p;
- (NSArray *)getAllModelWithSubModelClass:(Class)c SubModelProperty:(NSString *)p;
- (BaseModel *)selectModelWithID:(NSInteger)IDModel SubModelClass:(Class)c SubModelProperty:(NSString *)p;
- (BOOL)insertUseTransactionWithModels:(NSArray *)models SubModelClass:(Class)c SubModelProperty:(NSString *)p;
- (BOOL)deleteMainModelWithMainID:(NSInteger)mianID SubModelClass:(Class)c;
- (BOOL)updateMainModelWith:(BaseModel *)mainModel SubModelClass:(Class)c SubModelProperty:(NSString *)p;
- (NSArray *)selectMianModelWithModelProperty:(NSString *)field Value:(NSString *)value SubModelClass:(Class)c SubModelProperty:(NSString *)p;
- (BaseModel *)selectedMainModelMaxIDWithSubModelClass:(Class)c SubModelProperty:(NSString *)p;  // 最新插入

#pragma mark - 审核订单和预订订单存同一张表，去重处理：1.审核和预订为同一人；2.只是初始化从服务器拉取数据；3.只负责
@end
