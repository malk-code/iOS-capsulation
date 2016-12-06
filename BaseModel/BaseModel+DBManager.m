//
//  BaseModel+DBManager.m
//  Timas
//
//  Created by Timas on 16/10/14.
//  Copyright © 2016年 Timas. All rights reserved.
//

#import "BaseModel+DBManager.h"
#import "FMDB.h"
#import "ModelService.h"
#import "UserInfo.h"

#define ID_MODEL(clas)   [NSString stringWithFormat:@"ID%@",  [NSStringFromClass([clas class]) uppercaseString]]
#define TAB_NAME(name)   [NSString stringWithFormat:@"%@TABLE", name.uppercaseString]

    FMDatabase *db;
    NSString *pathDB;

@implementation BaseModel (DBManager)

#pragma mark - 数据库初始化
- (void)createDB
{
    NSString *sqliteName = [UserInfo infoUser].sqliteFileName;  // 文件名唯一
    
    NSMutableString *strM = [NSMutableString string];
    
    [strM appendFormat:@"%@ integer primary key autoincrement, ", ID_MODEL(self)];
    for (NSString *propertyName in self.DBColumnsName)
    {
        [strM appendFormat:@"%@ varchar(50), ", propertyName.uppercaseString];
    }
   
    [strM deleteCharactersInRange:NSMakeRange(strM.length-2, 2)];
    
    pathDB = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:sqliteName];
    db = [FMDatabase databaseWithPath:pathDB];
    
    if ([db open])
    {
        NSString *sql  = [NSString stringWithFormat:@"create table if not exists %@ (%@)", TAB_NAME(self.DBTableName), strM];
        [db executeUpdate:sql];
    }
    
    [db close];
}

- (void)createDBWithMainModelClass:(Class)c
{
    NSMutableArray *arrM = [[self DBColumnsName] mutableCopy];
    [arrM addObject:ID_MODEL(c)];
    
    self.DBColumnsName = arrM;
    
    [self createDB];  // 添加关联列
}

- (void)openDB
{
    if ([db close])
    {
        [db open];
    }
}

- (void)closeDB
{
    if ([db open])
    {
        [db close];
    } 
}

#pragma mark - 数据库单表操作
- (NSArray *)getAllModel
{
    NSMutableArray *arrSrc = [NSMutableArray array];

    if ([db open])
    {
        NSString *sql = [NSString stringWithFormat:@"select * from %@", TAB_NAME(self.DBTableName)];

        FMResultSet *resultSet = [db executeQuery:sql];

        while (resultSet.next)
        {
            NSMutableDictionary *dicM = [NSMutableDictionary dictionaryWithObject: [resultSet stringForColumn:ID_MODEL(self)] forKey:ID_MODEL(self)];
            
            for (NSString *columnName in self.DBColumnsName)
            {
                dicM[columnName] = [resultSet stringForColumn:columnName.uppercaseString];

            }
            [arrSrc addObject:dicM];
        }
    }
    
    [db close];
    return [ModelService modelWithClassName:NSStringFromClass([self class]) arrSource:arrSrc];
}

- (BOOL)insertModel:(BaseModel *)model
{
    BOOL isSucess = NO;
    
    if ([db open])
    {
        NSDictionary *dicModel =  model.dicProperty;
        
        NSMutableString *strMKey = [NSMutableString string];
        NSMutableString *strMValue = [NSMutableString string];

        for (NSString *columnName in self.DBColumnsName)
        {
            [strMKey appendFormat:@"%@, ", columnName.uppercaseString];
            [strMValue appendFormat:@"'%@', ", dicModel[columnName]];
        }
        
        [strMKey deleteCharactersInRange:NSMakeRange(strMKey.length -2, 2)];
        [strMValue deleteCharactersInRange:NSMakeRange(strMValue.length -2, 2)];

        NSString *sql = [NSString stringWithFormat:@"insert into %@(%@) values(%@)", TAB_NAME(self.DBTableName), strMKey, strMValue];
        
        isSucess = [db executeUpdate:sql];
    }
    
    [db close];
    return isSucess;
}

- (BOOL)deleteModel:(NSInteger)IDModel
{
    BOOL isSucess = NO;

    if ([db open])
    {
        NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = %lu", TAB_NAME(self.DBTableName), ID_MODEL(self), (long)IDModel];
        isSucess = [db executeUpdate:sql];
    }
    
    [db close];
    return isSucess;
}

- (BOOL)updateModel:(BaseModel *)model
{
    BOOL isSucess = NO;

    //NSInteger idModel = [[model performSelector:NSSelectorFromString(ID_MODEL(self))] integerValue];
    NSInteger idModel = [[model valueForKey:ID_MODEL(self)] integerValue];
    
    if ([db open])
    {
        NSDictionary *dicModel =  model.dicProperty;
        
        NSMutableString *strMKeyValue = [NSMutableString string];
        
        for (NSString *columnName in self.DBColumnsName)
        {
            [strMKeyValue appendFormat:@"%@ = '%@', ", columnName.uppercaseString, dicModel[columnName]];
        }
        
        [strMKeyValue deleteCharactersInRange:NSMakeRange(strMKeyValue.length -2, 2)];
        
        NSString *sql = [NSString stringWithFormat:@"update %@ set %@ where %@ = %lu", TAB_NAME(self.DBTableName), strMKeyValue, ID_MODEL(self), (long)idModel];
        isSucess = [db executeUpdate:sql];
    }
    [db close];
    
    return isSucess;
}

- (BaseModel *)selectModelWithID:(NSInteger)IDModel
{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    
    if ([db open])
    {
        NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ = %lu", TAB_NAME(self.DBTableName), ID_MODEL(self), (long)IDModel];
        
        FMResultSet *resultSet = [db executeQuery:sql];
        while (resultSet.next)
        {
            dicM[ID_MODEL(self)] = [resultSet stringForColumn:ID_MODEL(self)];
            
            for (NSString *columnName in self.DBColumnsName)
            {
                dicM[columnName] = [resultSet stringForColumn:columnName.uppercaseString];
            }
        }
    }
    return [ModelService modelWithClassName:NSStringFromClass([self class]) DicSource:dicM];
}

- (BaseModel *)selectedModelMaxID
{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    
    // select max(id) from table | select * from table where id = (select max(id) from table)
    if ([db open])
    {
        NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ = (select max(%@) from %@)", TAB_NAME(self.DBTableName), ID_MODEL(self), ID_MODEL(self), TAB_NAME(self.DBTableName)];
        
        FMResultSet *resultSet = [db executeQuery:sql];
        while (resultSet.next)
        {
            dicM[ID_MODEL(self)] = [resultSet stringForColumn:ID_MODEL(self)];
            
            for (NSString *columnName in self.DBColumnsName)
            {
                dicM[columnName] = [resultSet stringForColumn:columnName.uppercaseString];
            }
        }
    }
    return [ModelService modelWithClassName:NSStringFromClass([self class]) DicSource:dicM];
}


- (BOOL)insertUseTransactionWithModels:(NSArray *)models
{
    BOOL isSucess = NO;
    BOOL isRollBack = NO;       // 回滚
    
    if ([db open])
    {
        [db beginTransaction];  // 事件
        
        NSMutableString *strMKey = [NSMutableString string];
        
        for (NSString *columnName in self.DBColumnsName)
        {
            [strMKey appendFormat:@"%@, ", columnName.uppercaseString];
        }
        
        [strMKey deleteCharactersInRange:NSMakeRange(strMKey.length -2, 2)];
        
        @try
        {
            for (BaseModel *model in models)
            {
                NSMutableString *strMValue = [NSMutableString string];
                
                NSDictionary *dicModel =  model.dicProperty;

                for (NSString *columnName in self.DBColumnsName)
                {
                    [strMValue appendFormat:@"'%@', ", dicModel[columnName]];
                }
                
                [strMValue deleteCharactersInRange:NSMakeRange(strMValue.length -2, 2)];
                
                NSString *sql = [NSString stringWithFormat:@"insert into %@(%@) values(%@)", TAB_NAME(self.DBTableName), strMKey, strMValue];
                isSucess = [db executeUpdate:sql];
            }
        }
        @catch (NSException *exception)
        {
            isRollBack = YES;
            [db rollback];
        }
        @finally
        {
            if (!isRollBack)
            {
                [db commit];
            }
        }
    }
    
    [db close];
    return isSucess && isRollBack;
}

- (NSArray *)selectModelWithModelProperty:(NSString *)field Value:(NSString *)value
{
    NSMutableArray *arrSrc = [NSMutableArray array];
    
    if ([db open])
    {
        NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ = '%@'", TAB_NAME(self.DBTableName), field.uppercaseString, value];
        
        FMResultSet *resultSet = [db executeQuery:sql];
        
        while (resultSet.next)
        {
            NSMutableDictionary *dicM = [NSMutableDictionary dictionaryWithObject: [resultSet stringForColumn:ID_MODEL(self)] forKey:ID_MODEL(self)];
            
            for (NSString *columnName in self.DBColumnsName)
            {
                dicM[columnName] = [resultSet stringForColumn:columnName.uppercaseString];
                
            }
            [arrSrc addObject:dicM];
        }
    }
    
    [db close];
    return [ModelService modelWithClassName:NSStringFromClass([self class]) arrSource:arrSrc];
}

- (BOOL)deleteModelWithModelProperty:(NSString *)field Value:(NSString *)value
{
    BOOL isSucess = NO;
    
    if ([db open])
    {
        NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = '%@'", TAB_NAME(self.DBTableName), field.uppercaseString, value];
        isSucess = [db executeUpdate:sql];
    }
    
    [db close];
    return isSucess;
}

- (BOOL)deleteAllModelUseTransaction
{
    BOOL isSucess = NO;
    BOOL isRollBack = NO;       // 回滚
    
    if ([db open])
    {
        [db beginTransaction];  // 事件
        @try
        {
            for (BaseModel *model in [self getAllModel])
            {
                NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = %ld", TAB_NAME(self.DBTableName), ID_MODEL(self), [[model valueForKeyPath:ID_MODEL(self)] integerValue]];
                isSucess = [db executeUpdate:sql];
            }
        }
        @catch (NSException *exception)
        {
            isRollBack = YES;
            [db rollback];
        }
        @finally
        {
            if (!isRollBack)
            {
                [db commit];
            }
        }
    }
    
    [db close];
    return isSucess && isRollBack;
}

#pragma mark - 数据库主从表操作
// KVC+子模型添加主模型ID进行关联，对单表进行再次封装
- (BOOL)insertWithModel:(BaseModel *)model SubModelClass:(Class)c SubModelProperty:(NSString *)p
{
    BOOL isSucess = [self insertModel:model];
    
    NSString *primaryValue = [[self selectedModelMaxID] valueForKey:ID_MODEL(self)];
   
    for (BaseModel *subModel in [model valueForKey:p])
    {
        [subModel setValue:primaryValue forKey:ID_MODEL(self)];
    }
    
    isSucess = [[c DBManager] insertUseTransactionWithModels:[model valueForKey:p]];
    
    return isSucess;
}

- (NSArray *)getAllModelWithSubModelClass:(Class)c SubModelProperty:(NSString *)p;
{
    NSArray *arrM = [[self getAllModel] mutableCopy];
    
    for (BaseModel *model in arrM)
    {
        NSArray *subModels = [[c DBManager] selectModelWithModelProperty:ID_MODEL(self) Value:[model valueForKey:ID_MODEL(self)]];
       
        // 数据库返回是model，KCV访问也会调用重写的setter方法：因此需要在setter进行判断且该列在数据库可为空

        [model setValue:subModels forKey:p];
    }
    
    return arrM;
}

- (BaseModel *)selectModelWithID:(NSInteger)IDModel SubModelClass:(Class)c SubModelProperty:(NSString *)p
{
    BaseModel *model = [self selectModelWithID:IDModel];
    [model setValue:[[c DBManager] selectModelWithModelProperty:ID_MODEL(self) Value:[model valueForKey:ID_MODEL(self)]] forKey:p];
    
    return model;
}

- (BOOL)insertUseTransactionWithModels:(NSArray *)models SubModelClass:(Class)c SubModelProperty:(NSString *)p;
{
    __block BOOL isSucess = [self insertUseTransactionWithModels:models];
    
    NSArray *arrModel = [self getAllModel];
    
    // 去主模型的ID做子模型的关联键：遍历models而不是arrModel（arrM中为空值/空建）
    [models enumerateObjectsUsingBlock:^(id  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop)
    {
        NSString *primaryValue = [arrModel[idx] valueForKey:ID_MODEL(self)];
        
        for (BaseModel *subModel in [model valueForKey:p])
        {
            [subModel setValue:primaryValue forKeyPath:ID_MODEL(self)];
        }
        
        isSucess = [[c DBManager] insertUseTransactionWithModels:[model valueForKey:p]];
    }];

    return isSucess;
}

- (BOOL)deleteMainModelWithMainID:(NSInteger)mianID SubModelClass:(Class)c
{
     BOOL isSucess = [self deleteModel:mianID];
    
    isSucess = [[c DBManager] deleteModelWithModelProperty:ID_MODEL(self) Value:[NSString stringWithFormat:@"%lu", (long)mianID]];
    
    return isSucess;
}

- (BOOL)updateMainModelWith:(BaseModel *)mainModel SubModelClass:(Class)c SubModelProperty:(NSString *)p
{
    BOOL isSucess = [self updateModel:mainModel];
    
    for (BaseModel *subModel in [mainModel valueForKey:p])
    {
       isSucess = [[c DBManager] updateModel:subModel];
    }
    
    return isSucess;
}

- (NSArray *)selectMianModelWithModelProperty:(NSString *)field Value:(NSString *)value SubModelClass:(Class)c SubModelProperty:(NSString *)p
{
    NSArray *arrM = [[self selectModelWithModelProperty:field Value:p] mutableCopy];
    
    for (BaseModel *model in arrM)
    {
        NSArray *subModels = [[c DBManager] selectModelWithModelProperty:ID_MODEL(self) Value:[model valueForKey:ID_MODEL(self)]];
        
        // 数据库返回是model，KVC访问也会调用重写的setter方法：因此需要在setter进行判断且该列在数据库可为空
        
        [model setValue:subModels forKey:p];
    }
    
    return arrM;
}

- (BaseModel *)selectedMainModelMaxIDWithSubModelClass:(Class)c SubModelProperty:(NSString *)p;
{
    BaseModel *model = [self selectedModelMaxID];
    [model setValue:[[c DBManager] selectModelWithModelProperty:ID_MODEL(self) Value:[model valueForKey:ID_MODEL(self)]] forKey:p];
    
    return model;
}
@end
