//
//  RouteManager.m
//  GoogleMapsTesting
//
//  Created by Alexander on 12/17/15.
//  Copyright © 2015 mac-179. All rights reserved.
//

#import "RouteManager.h"

@interface RouteManager()


@property (strong, nonatomic) AFHTTPSessionManager* sessionManager;

@end

@implementation RouteManager

static NSString *kDirectionsURL = @"https://maps.googleapis.com/maps/api/directions/json?";
static NSString *kKey = @"AIzaSyASl8LH8r0EPawmoz9qrDoyg_M7IBP-hI4";

+ (instancetype)sharedManager {
    
    static RouteManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[RouteManager alloc] init];
    });
    
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.sessionManager = [AFHTTPSessionManager manager];
    }
    return self;
}

- (void)getRouteFromGoogleWithAtartPosition:(CLLocationCoordinate2D)startPosition
                            withEndPosition:(CLLocationCoordinate2D)endPosition
                                   withMode:(NSString *)mode
                      withCompletitionBlock:(void (^)(GMSPolyline *polyline, NSError *error))completitionBlock {
    NSDictionary* params =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSString stringWithFormat:@"%f,%f",startPosition.latitude, startPosition.longitude], @"origin",
     [NSString stringWithFormat:@"%f,%f",endPosition.latitude, endPosition.longitude], @"destination",
     mode, @"mode",
     kKey, @"key", nil];
    [self.sessionManager GET:kDirectionsURL
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionTask *task, id responseObject) {
         NSArray *routesArray = [responseObject objectForKey:@"routes"];
         if ([routesArray count] > 0)
         {
             NSDictionary *routeDict = [routesArray objectAtIndex:0];
             NSDictionary *routeOverviewPolyline = [routeDict objectForKey:@"overview_polyline"];
             NSString *points = [routeOverviewPolyline objectForKey:@"points"];
             GMSPath *path = [GMSPath pathFromEncodedPath:points];
             GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
             completitionBlock(polyline, nil);
         }
         else
         {
             completitionBlock(nil, nil);
         }
    }
                     failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
