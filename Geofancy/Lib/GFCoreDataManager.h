//
//  GFCoreDataManager.h
//  Locative
//
//  Created by Marcus Kida on 1/12/2015.
//  Copyright © 2015 Marcus Kida. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ObjectiveRecord/CoreDataManager.h>

@interface GFCoreDataManager : NSObject

@property (nonatomic, strong) CoreDataManager *coreDataManager;

- (instancetype)initWithModel:(NSString *)model;

@end
