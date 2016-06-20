//
//  MKMapView+ZoomLevel.m
//  Geofancy
//
//  Created by Marcus Kida on 03.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import "MKMapView+ZoomLevel.h"

#define MERCATOR_RADIUS 85445659.44705395
#define MILES_CONST 0.621371192

@implementation MKMapView (ZoomLevel)

- (void) setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                   zoomLevel:(NSUInteger)zoomLevel
                    animated:(BOOL)animated
{
    MKCoordinateSpan span = MKCoordinateSpanMake(0, 360/pow(2, zoomLevel)*self.frame.size.width/256);
    [self setRegion:MKCoordinateRegionMake(centerCoordinate, span) animated:animated];
}

-(NSInteger) zoomLevel
{
	return 21 - round(log2(self.region.span.longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * self.bounds.size.width)));
}

- (CGFloat) radiusMultiplier
{
    return (15.0f / (float)[self zoomLevel]) * pow(fmax(1, (15 - [self zoomLevel])), 2);
}

-(void) zoomToLocation:(CLLocation *)location withMarginInMeters:(CGFloat)meters animated:(BOOL)animated
{
    double scalingFactor = ABS( (cos(2 * M_PI * self.userLocation.coordinate.latitude / 360.0) ));
    
    MKCoordinateSpan span;
    span.latitudeDelta = (meters/1000)/69.0;
    span.longitudeDelta = (meters/1000)/(scalingFactor * 69.0);
    
    MKCoordinateRegion region;
    region.span = span;
    region.center = location.coordinate;
    
    [self setRegion:region animated:animated];
}

@end
