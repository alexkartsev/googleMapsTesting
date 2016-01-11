//
//  RouteManager.h
//  GoogleMapsTesting
//
//  Created by Alexander on 12/17/15.
//  Copyright © 2015 mac-179. All rights reserved.
//

#import "AFNetworking/AFNetworking.h"
#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface RouteManager : NSObject

+ (instancetype) sharedManager;

- (void)getRouteFromGoogleWithAtartPosition:(CLLocationCoordinate2D)startPosition
                            withEndPosition:(CLLocationCoordinate2D)endPosition
                                   withMode:(NSString *)mode
                      withCompletitionBlock:(void (^)(GMSPolyline *polyline, NSError *error))completitionBlock;

@end
