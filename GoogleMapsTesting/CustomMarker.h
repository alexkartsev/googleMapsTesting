//
//  CustomMarker.h
//  GoogleMapsTesting
//
//  Created by Alexander on 12/8/15.
//  Copyright © 2015 mac-179. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;
#import "GClusterItem.h"

@interface CustomMarker : NSObject <GClusterItem>

@property (nonatomic) CLLocationCoordinate2D location;

@property (nonatomic, strong) GMSMarker *marker;

@end
