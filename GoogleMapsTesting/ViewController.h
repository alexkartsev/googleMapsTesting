//
//  ViewController.h
//  GoogleMapsTesting
//
//  Created by Alexander on 12/7/15.
//  Copyright © 2015 mac-179. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *markersBarButtonItem;

@end

