//
//  PopoverViewController.m
//  GoogleMapsTesting
//
//  Created by Alexander on 12/10/15.
//  Copyright © 2015 mac-179. All rights reserved.
//

#import "PopoverViewController.h"
#import <GoogleMaps/GoogleMaps.h>

static NSString * cellIdentifier = @"Cell";

@interface PopoverViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation PopoverViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrayOfMarkers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    GMSMarker *marker = [self.arrayOfMarkers objectAtIndex:indexPath.row];
    cell.textLabel.text = marker.title;
    return cell;
}

@end
