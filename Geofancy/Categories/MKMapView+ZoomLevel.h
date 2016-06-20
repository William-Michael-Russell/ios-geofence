//
//  MKMapView+ZoomLevel.h
//  Geofancy
//
//  Created by Marcus Kida on 03.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)

- (void) setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                   zoomLevel:(NSUInteger)zoomLevel
                    animated:(BOOL)animated;

-(NSInteger) zoomLevel;

- (CGFloat) radiusMultiplier;

-(void) zoomToLocation:(CLLocation *)location withMarginInMeters:(CGFloat)meters animated:(BOOL)animated;

@end
