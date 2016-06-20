//
//  GFBackgroundBlockOperation.h
//  Geofancy
//
//  Created by Marcus Kida on 25.12.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GFBackgroundBlockOperation : NSBlockOperation

@property (assign) BOOL automaticallyEndsBackgroundTask;

- (void)endBackgroundTask;

@end
