//
//  PopoverViewController.h
//  GoogleMapsTesting
//
//  Created by Alexander on 12/10/15.
//  Copyright © 2015 mac-179. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PopoverViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIContentContainer>

@property (strong, nonatomic) NSArray *arrayOfMarkers;

@end
