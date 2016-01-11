//
//  ViewController.m
//  GoogleMapsTesting
//
//  Created by Alexander on 12/7/15.
//  Copyright © 2015 mac-179. All rights reserved.
//

#import "ViewController.h"
#import "DetailViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "GClusterManager.h"
#import "NonHierarchicalDistanceBasedAlgorithm.h"
#import "GDefaultClusterRenderer.h"
#import "CustomMarker.h"
#import "GCluster.h"
#import "GQuadItem.h"
#import "PopoverViewController.h"
#import "WYPopoverController.h"
#import "RouteManager.h"

static NSString *keyPathNameForMyLocation = @"myLocation";
static NSString *cellIdentifier = @"Cell";

@interface ViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, UIGestureRecognizerDelegate, WYPopoverControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property BOOL markerTapped;
@property (strong, nonatomic) GMSCircle *startPositionCircle;
@property (strong, nonatomic) GMSCircle *finishPositionCircle;
@property (strong, nonatomic) UIButton *carButton;
@property (strong, nonatomic) UIButton *pedestrianButton;
@property (strong, nonatomic) UIButton *bicycleButton;
@property (nonatomic, assign) BOOL isResultTableView;
@property (assign, nonatomic) BOOL isAnimationInfoView;
@property (strong, nonatomic) UIView *routeView;
@property (strong, nonatomic) UITableView *searchTableView;
@property (strong, nonatomic) WYPopoverController *customPopoverController;
@property (nonatomic, strong) PopoverViewController *popOverViewController;
@property (nonatomic, strong) UIPopoverPresentationController *popoverPresentationController;
@property (strong, nonatomic) GMSMapView *allAnnotationMapView;
@property (strong, nonatomic) GMSMarker *currentlyTappedMarker;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *arrayOfMarkers;
@property (strong, nonatomic) GClusterManager *clusterManager;
@property (strong, nonatomic) UIView *displayedInfoWindow;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSTimer *searchTimer;
@property (strong, nonatomic) NSArray *filteredData;
@property (assign, nonatomic) BOOL isShowOneSearchMarker;
@property (strong, nonatomic) GMSPolyline *polyline;
@property (strong, nonatomic) UILabel *startPositionOfRoute;
@property (strong, nonatomic) UILabel *endPositionOfRoute;
@property (strong, nonatomic) GMSMarker *startPositionOfRouteMarker;
@property (strong, nonatomic) GMSMarker *endPositionOfRouteMarker;
@property (strong, nonatomic) NSString *modeForRoute;
@end

@implementation ViewController

#pragma mark - Default View Controller's methods

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePositionWithoutZoom) name:@"MapView was changed without zoom" object:nil];
    self.clusterManager = [GClusterManager managerWithMapView:self.mapView
                                                algorithm:[[NonHierarchicalDistanceBasedAlgorithm alloc] init]
                                                 renderer:[[GDefaultClusterRenderer alloc] initWithMapView:self.mapView]];
    self.mapView.delegate = self.clusterManager;
    self.arrayOfMarkers = [[NSMutableArray alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self creatingMarkersWithAddingToMarkersArray:YES];
    [self.clusterManager cluster];
    [self.clusterManager setDelegate:self];
}


#pragma mark - Map View's methods

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.myLocationEnabled = YES;
        //self.mapView.settings.myLocationButton = YES;
        [self performSelector:@selector(animateCameraToMyPosition) withObject:nil afterDelay:2];
    }
    else {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)animateCameraToMyPosition {
    [self.mapView animateToCameraPosition:[GMSCameraPosition cameraWithLatitude:self.mapView.myLocation.coordinate.latitude
                                                                      longitude:self.mapView.myLocation.coordinate.longitude
                                                                           zoom:10.0f]];
}

- (void)creatingMarkersWithAddingToMarkersArray: (BOOL)addingToMarkersArray {
    for (int i = 0; i<240; i++) {
        [self createMarkerWithLocation:CLLocationCoordinate2DMake([self randomFloatBetween:40.0f and:65.0f], [self randomFloatBetween:15.0f and:40.0f])
                             withTitle:[NSString stringWithFormat:@"Test %d",i]
                           withSnippet:[NSString stringWithFormat:@"Detail info for test %d",i]withAddingToMarkersArray:addingToMarkersArray];
    }
    
//    [self createMarkerWithLocation:CLLocationCoordinate2DMake(53.910620, 27.437100)
//                         withTitle:@"My House"
//                       withSnippet:@"Kyncevschina, 4"];
//    [self createMarkerWithLocation:CLLocationCoordinate2DMake(53.894006, 27.547085)
//                         withTitle:@"My University"
//                       withSnippet:@"BSU Main Building, Independence av., 4"];
}

- (float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

- (void)createMarkerWithLocation:(CLLocationCoordinate2D)location
                       withTitle:(NSString *)title
                     withSnippet:(NSString *)snippet
        withAddingToMarkersArray: (BOOL)addingToMarkersArray{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = location;
    marker.title = title;
    marker.snippet = snippet;
    CustomMarker* spot = [[CustomMarker alloc] init];
    spot.location = marker.position;
    spot.marker = marker;
    [self.clusterManager addItem:spot];
    if (addingToMarkersArray) {
        [self.arrayOfMarkers addObject:marker];
    }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    if (marker.icon) {
        id <GCluster> cluster = marker.userData;
        NSArray *array = [[NSArray alloc] initWithArray:[cluster.items allObjects]];
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];
        for (GQuadItem *item in array) {
            bounds = [bounds includingCoordinate:item.position];
        }
        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:50.0f]];
    }
    else {
        if([self.displayedInfoWindow isDescendantOfView:self.view]) {
            [self hideDetailInfoViewForMarkerWithAnimation:YES];
        }
        else {
            if ((self.mapView.layer.cameraLatitude == marker.position.latitude) && (self.mapView.layer.cameraLongitude== marker.position.longitude)) {
                [self changePositionWithoutZoom];
            }
        }
        self.markerTapped = YES;
        if(self.currentlyTappedMarker) {
            self.currentlyTappedMarker = nil;
        }
        self.currentlyTappedMarker = marker;
        [self.mapView animateToLocation:marker.position];
    }
    return YES;
}

    //call when camera changed zoom
- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
    [self hideDetailInfoViewForMarkerWithAnimation:NO];
    if (self.startPositionCircle) {
        CLLocationCoordinate2D circleCenter = self.startPositionCircle.position;
        self.startPositionCircle.map = nil;
        self.startPositionCircle = [GMSCircle circleWithPosition:circleCenter
                                                          radius:(1/self.mapView.camera.zoom)*200];
        self.startPositionCircle.fillColor = [UIColor colorWithRed:0.25 green:0 blue:0 alpha:1.0];
        self.startPositionCircle.strokeColor = [UIColor redColor];
        self.startPositionCircle.strokeWidth = 5;
        self.startPositionCircle.map = mapView;
    }
    
    if (self.finishPositionCircle) {
        CLLocationCoordinate2D circleCenter = self.finishPositionCircle.position;
        self.finishPositionCircle.map = nil;
        self.finishPositionCircle = [GMSCircle circleWithPosition:circleCenter
                                                          radius:(1/self.mapView.camera.zoom)*200];
        self.finishPositionCircle.fillColor = [UIColor colorWithRed:0.25 green:0 blue:0 alpha:1.0];
        self.finishPositionCircle.strokeColor = [UIColor greenColor];
        self.finishPositionCircle.strokeWidth = 5;
        self.finishPositionCircle.map = mapView;
    }
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self hideDetailInfoViewForMarkerWithAnimation:YES];
}

    //call when camera changed position without zoom
- (void)changePositionWithoutZoom {
    if (self.markerTapped && ![self.displayedInfoWindow isDescendantOfView:self.view]) {
        [self showDetailInfoViewForMarker];
        // reset our state first
        self.markerTapped = NO;
    }
    else if ([self.displayedInfoWindow isDescendantOfView:self.view]) {
        [self hideDetailInfoViewForMarkerWithAnimation:YES];
    }
}

    //call during camera change position
- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    [self hideDetailInfoViewForMarkerWithAnimation:NO];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    
    [self performSegueWithIdentifier:@"ShowDetailViewController" sender:self.currentlyTappedMarker];
    //Do stuff here...
}

#pragma mark - Segue methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"ShowDetailViewController"]) {
        DetailViewController *controller = (DetailViewController *)segue.destinationViewController;
        controller.marker  = sender;
    }
}

#pragma mark - WYPopoverController methods

- (IBAction)listOfMarkerButtonWasPressed:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PopoverViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"Pop"];
    controller.arrayOfMarkers = [[NSArray alloc] initWithArray:self.arrayOfMarkers];
    self.customPopoverController = [[WYPopoverController alloc] initWithContentViewController:controller];
    self.customPopoverController.animationDuration = 2.0f;
    self.customPopoverController.delegate = self;
    CGRect frame = [[sender valueForKey:@"view"] frame];
    frame.origin.y = frame.origin.y + 20;
    [self.customPopoverController presentPopoverFromBarButtonItem:sender
                                         permittedArrowDirections:WYPopoverArrowDirectionAny
                                                         animated:YES
                                                          options:WYPopoverAnimationOptionScale];
}


- (BOOL)popoverControllerShouldDismissPopover:(WYPopoverController *)controller
{
    return YES;
}

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)controller
{
    self.customPopoverController.delegate = nil;
    self.customPopoverController = nil;
}

#pragma mark - UIView detail info methods

- (void)showDetailInfoViewForMarker {
    // create our custom info window UIView and set the color
    self.displayedInfoWindow = [[UIView alloc] init];
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleSingleTap:)];
    [self.displayedInfoWindow addGestureRecognizer:singleFingerTap];
    self.displayedInfoWindow.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:50.0/255.0 blue:255.0/255.0 alpha:1];
    
    /* Maps an Earth coordinate to a point coordinate in the map's view. */
    CGPoint markerPoint = [self.mapView.projection pointForCoordinate:self.currentlyTappedMarker.position];
    self.displayedInfoWindow.frame = CGRectMake(markerPoint.x-100, markerPoint.y - 80, 200, 100);
    self.displayedInfoWindow.layer.cornerRadius = 5.f;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 180, 21)];
    label.textColor = [UIColor whiteColor];
    [label setFont:[UIFont fontWithName:@"Arial-BoldMT" size:18]];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = [NSString stringWithFormat:@"%@",self.currentlyTappedMarker.title];
    [self.displayedInfoWindow addSubview:label];
    UIButton *startRouteButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 31, 180, 34)];
    [startRouteButton setTitle:@"Start Marker" forState:UIControlStateNormal];
    startRouteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [startRouteButton addTarget:self action:@selector(didPressStartRouteMarker) forControlEvents:UIControlEventTouchUpInside];
    //startRouteButton.titleLabel.text = @"Start Marker";
    [self.displayedInfoWindow addSubview:startRouteButton];
    UIButton *endRouteButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 65, 180, 34)];
    [endRouteButton setTitle:@"End Marker" forState:UIControlStateNormal];
    [endRouteButton addTarget:self action:@selector(didPressEndRouteMarker) forControlEvents:UIControlEventTouchUpInside];
    endRouteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    //startRouteButton.titleLabel.text = @"Start Marker";
    [self.displayedInfoWindow addSubview:endRouteButton];
    [self.view addSubview:self.displayedInfoWindow];
    self.displayedInfoWindow.alpha = 0;
    self.isAnimationInfoView = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.displayedInfoWindow.alpha = 0.95;
    } completion:^(BOOL finished) {
        self.isAnimationInfoView = NO;
    }];
}

-(void)didPressStartRouteMarker {
    [self hideDetailInfoViewForMarkerWithAnimation:YES];
    if (!self.routeView) {
        [self showBottomViewForRouteWithStartPosition:YES];
    }
    else {
        self.startPositionOfRouteMarker = self.currentlyTappedMarker;
        [self drawStartCircle];
        if (self.polyline) {
            self.polyline.map = nil;
            self.polyline = nil;
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(didPressStartBarButtonItemForRoute)];
        }
    }
}

-(void)drawStartCircle {
    CLLocationCoordinate2D circleCenter = self.currentlyTappedMarker.position;
    if (self.startPositionCircle) {
        self.startPositionCircle.map = nil;
    }
    self.startPositionCircle = [GMSCircle circleWithPosition:circleCenter
                                                          radius:(1/self.mapView.camera.zoom)*200];
    self.startPositionCircle.fillColor = [UIColor colorWithRed:0.25 green:0 blue:0 alpha:1.0];
    self.startPositionCircle.strokeColor = [UIColor redColor];
    self.startPositionCircle.strokeWidth = 5;
    self.startPositionCircle.map = self.mapView;
}

-(void)drawFinishCircle {
    CLLocationCoordinate2D circleCenter = self.currentlyTappedMarker.position;
    if (self.finishPositionCircle) {
        self.finishPositionCircle.map = nil;
    }
    self.finishPositionCircle = [GMSCircle circleWithPosition:circleCenter
                                                      radius:(1/self.mapView.camera.zoom)*200];
    self.finishPositionCircle.fillColor = [UIColor colorWithRed:0.25 green:0 blue:0 alpha:1.0];
    self.finishPositionCircle.strokeColor = [UIColor greenColor];
    self.finishPositionCircle.strokeWidth = 5;
    self.finishPositionCircle.map = self.mapView;
}

-(void)didPressEndRouteMarker {
    [self hideDetailInfoViewForMarkerWithAnimation:YES];
    [self drawFinishCircle];
    if (!self.routeView) {
        [self showBottomViewForRouteWithStartPosition:NO];
    }
    else {
        self.endPositionOfRouteMarker = self.currentlyTappedMarker;
        if (self.polyline) {
            self.polyline.map = nil;
            self.polyline = nil;
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(didPressStartBarButtonItemForRoute)];
        }
    }
}

-(void)hideDetailInfoViewForMarkerWithAnimation:(BOOL) animation {
    
    if ([self.displayedInfoWindow isDescendantOfView:self.view]) {
        if (animation) {
            self.isAnimationInfoView = YES;
            [UIView animateWithDuration:0.2 animations:^{
                self.displayedInfoWindow.alpha = 0;
            } completion:^(BOOL finished) {
                [self.displayedInfoWindow removeFromSuperview];
                self.displayedInfoWindow = nil;
                self.isAnimationInfoView = NO;
            }];
        }
        else {
            if (self.isAnimationInfoView) {
                [self.displayedInfoWindow.layer removeAllAnimations];
                [self.view.layer removeAllAnimations];
            }
            [self.displayedInfoWindow removeFromSuperview];
            self.displayedInfoWindow = nil;
        }
    }
}

#pragma mark - Route methods

-(void)didPressCancelBarButtonItemForRoute {
    if (self.polyline) {
        self.polyline.map = nil;
        self.polyline = nil;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(didPressStartBarButtonItemForRoute)];
    }
    else {
        [self hideBottomViewForRoute];
        if (self.startPositionCircle) {
            self.startPositionCircle.map=nil;
            self.startPositionCircle=nil;
        }
        if (self.finishPositionCircle) {
            self.finishPositionCircle.map=nil;
            self.finishPositionCircle=nil;
        }
    }
}

-(void)didPressStartBarButtonItemForRoute {
    if (self.startPositionOfRouteMarker && self.endPositionOfRouteMarker) {
        [[RouteManager sharedManager] getRouteFromGoogleWithAtartPosition:self.startPositionOfRouteMarker.position
                                                          withEndPosition:self.endPositionOfRouteMarker.position
                                                                 withMode:self.modeForRoute
                                                    withCompletitionBlock:^(GMSPolyline *polyline, NSError *error) {
            self.polyline = polyline;
            self.polyline.strokeWidth = 3;
            self.polyline.strokeColor = [UIColor blueColor];
            self.polyline.map = self.mapView;
            self.navigationItem.rightBarButtonItem = nil;
            if (!polyline) {
                [self showAlertViewWithMessage:@"Google can't create a route between this markers"];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(didPressStartBarButtonItemForRoute)];
            }
        }];
    }
    else {
        [self showAlertViewWithMessage:@"Please, choose start and finish position"];
    }
}

-(void)routeForCarButton {
    self.modeForRoute = @"driving";
    self.carButton.selected = YES;
    if (self.bicycleButton.selected || self.pedestrianButton.selected) {
        self.bicycleButton.selected = NO;
        self.pedestrianButton.selected = NO;
        if (self.polyline) {
            self.polyline.map=nil;
            self.polyline = nil;
            [self didPressStartBarButtonItemForRoute];
        }
    }
}

-(void)routeForPedestrianButton {
    self.modeForRoute = @"walking";
    if (self.carButton.selected || self.bicycleButton.selected) {
        self.carButton.selected = NO;
        self.bicycleButton.selected = NO;
        if (self.polyline) {
            self.polyline.map=nil;
            self.polyline = nil;
            [self didPressStartBarButtonItemForRoute];
        }
    }
    self.pedestrianButton.selected = YES;
}

-(void)routeForBicycleWithSender: (UIButton *) sender {
    self.modeForRoute = @"bicycling";
    if (self.pedestrianButton.selected || self.carButton.selected) {
        self.pedestrianButton.selected = NO;
        self.carButton.selected = NO;
        if (self.polyline) {
            self.polyline.map=nil;
            self.polyline = nil;
            [self didPressStartBarButtonItemForRoute];
        }
    }
    self.bicycleButton.selected = YES;
}

-(void)showBottomViewForRouteWithStartPosition:(BOOL)startPosition {
    self.routeView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 150)];
    self.routeView.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:50.0/255.0 blue:255.0/255.0 alpha:1];
    self.startPositionOfRoute = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, self.view.bounds.size.width-40, 30)];
    self.endPositionOfRoute = [[UILabel alloc] initWithFrame:CGRectMake(20, 110, self.view.bounds.size.width-40, 30)];
    
    [self addObserver:self forKeyPath:@"startPositionOfRouteMarker" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
    [self addObserver:self forKeyPath:@"endPositionOfRouteMarker" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
    
    self.startPositionOfRoute.textColor = [UIColor whiteColor];
    self.startPositionOfRoute.textAlignment = NSTextAlignmentCenter;
    [self.startPositionOfRoute setFont:[UIFont fontWithName:@"Arial-BoldMT" size:18]];
    [self.routeView addSubview:self.startPositionOfRoute];
    
    self.endPositionOfRoute.textColor = [UIColor whiteColor];
    self.endPositionOfRoute.textAlignment = NSTextAlignmentCenter;
    [self.endPositionOfRoute setFont:[UIFont fontWithName:@"Arial-BoldMT" size:18]];
    [self.routeView addSubview:self.endPositionOfRoute];
    
    self.carButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.carButton addTarget:self
               action:@selector(routeForCarButton)
     forControlEvents:UIControlEventTouchUpInside];
    [self.carButton setBackgroundImage:[UIImage imageNamed:@"car"] forState:UIControlStateNormal];
    [self.carButton setBackgroundImage:[UIImage imageNamed:@"carSelected"] forState:UIControlStateSelected];
    self.carButton.frame = CGRectMake((self.view.bounds.size.width/4)-20.0, 20.0, 40.0, 40.0);
    //[self.carButton setHighlighted:YES];
    self.carButton.selected = YES;
    self.modeForRoute = @"driving";
    [self.routeView addSubview:self.carButton];
    
    self.pedestrianButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.pedestrianButton addTarget:self
                  action:@selector(routeForPedestrianButton)
        forControlEvents:UIControlEventTouchUpInside];
    UIImage *buttonPedestrianImage = [UIImage imageNamed:@"pedestrian"];
    [self.pedestrianButton setBackgroundImage:buttonPedestrianImage forState:UIControlStateNormal];
    [self.pedestrianButton setBackgroundImage:[UIImage imageNamed:@"pedestrianSelected"] forState:UIControlStateSelected];
    self.pedestrianButton.frame = CGRectMake(((self.view.bounds.size.width/4))*2-17.0, 20.0, 20.0, 35.0);
    [self.routeView addSubview:self.pedestrianButton];
    
    self.bicycleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.bicycleButton addTarget:self
                           action:@selector(routeForBicycleWithSender:)
        forControlEvents:UIControlEventTouchUpInside];
    UIImage *bicycleImage = [UIImage imageNamed:@"bicycle"];
    [self.bicycleButton setBackgroundImage:bicycleImage forState:UIControlStateNormal];
    [self.bicycleButton setBackgroundImage:[UIImage imageNamed:@"bicycleSelected"] forState:UIControlStateSelected];
    self.bicycleButton.frame = CGRectMake(((self.view.bounds.size.width/4))*3-20.0, 20.0, 40.0, 40.0);
    [self.routeView addSubview:self.bicycleButton];
    
    [self.view addSubview:self.routeView];
    if (startPosition) {
        self.startPositionOfRouteMarker = self.currentlyTappedMarker;
        self.endPositionOfRoute.text = @"To:";
        [self drawStartCircle];
    }
    else {
        self.endPositionOfRouteMarker = self.currentlyTappedMarker;
        self.startPositionOfRoute.text = @"From:";
    }
    [UIView animateWithDuration:0.4 animations:^{
        self.routeView.frame = CGRectMake(0, self.view.bounds.size.height-150, self.view.bounds.size.width, 150);
    } completion:^(BOOL finished) {
    }];
    if (self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = nil;
    }
    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(didPressCancelBarButtonItemForRoute)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(didPressStartBarButtonItemForRoute)];
}

-(void)hideBottomViewForRoute {
    [UIView animateWithDuration:0.4 animations:^{
        self.routeView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 150);
    } completion:^(BOOL finished) {
        [self.routeView removeFromSuperview];
        self.routeView = nil;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Markers" style:UIBarButtonItemStylePlain target:self action:@selector(listOfMarkerButtonWasPressed:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(didPressSearchBarButtonItem:)];
        [self removeObserver:self forKeyPath:@"startPositionOfRouteMarker"];
        [self removeObserver:self forKeyPath:@"endPositionOfRouteMarker"];
        self.startPositionOfRouteMarker = nil;
        self.endPositionOfRouteMarker = nil;
    }];
}

#pragma mark - Alert View

- (void) showAlertViewWithMessage:(NSString *) message
{
    UIAlertController *alertController = [UIAlertController  alertControllerWithTitle:@"Attention!"  message:message  preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"startPositionOfRouteMarker"]) {
        GMSMarker *temp = [change valueForKey:@"new"];
        self.startPositionOfRoute.text =[NSString stringWithFormat:@"From: %@",temp.title];
//        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
//        attachment.image = [UIImage imageNamed:@"menu-icon"];
//        attachment.bounds = CGRectMake(self.view.bounds.size.width-140, -3, attachment.image.size.width, attachment.image.size.height);
//        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
//        
//        NSMutableAttributedString *myString= [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"From: %@",temp.title]];
//        [myString appendAttributedString:attachmentString];
//        
//        self.startPositionOfRoute.attributedText = myString;
    }
    if ([keyPath isEqualToString:@"endPositionOfRouteMarker"]) {
        GMSMarker *temp = [change valueForKey:@"new"];
        self.endPositionOfRoute.text =[NSString stringWithFormat:@"To: %@",temp.title];
    }
}

#pragma mark - Search bar and search table view methods

- (IBAction)didPressSearchBarButtonItem:(id)sender {
    if (!self.searchController) {
        self.navigationItem.leftBarButtonItem = nil;
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        self.searchController.searchResultsUpdater = self;
        self.searchController.searchBar.clipsToBounds = YES;
        self.searchController.searchBar.returnKeyType = UIReturnKeyDone;
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.searchController.searchBar.delegate = self;
        self.searchController.hidesNavigationBarDuringPresentation = NO;
        self.searchTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 63, self.view.bounds.size.width, 1)];
        self.searchTableView.delegate = self;
        self.searchTableView.dataSource = self;
        [self.view addSubview:self.searchTableView];
        self.navigationItem.titleView = self.searchController.searchBar;
        self.definesPresentationContext = YES;
        [self.searchController.searchBar sizeToFit];
    }
    else {
        [self hideSearchTableViewWithSearchBar:YES];
        self.navigationItem.titleView = nil;
        if (self.isShowOneSearchMarker) {
            [self.clusterManager removeItems];
            [self creatingMarkersWithAddingToMarkersArray:NO];
            [self.clusterManager cluster];
            self.isShowOneSearchMarker = NO;
        }
    }
}

- (void)hideSearchTableViewWithSearchBar:(BOOL)searchBar {
    if (searchBar) {
        [UIView animateWithDuration:.5 animations:^{
            self.searchTableView.frame = CGRectMake(0, 63, self.view.bounds.size.width, 1);
        } completion:^(BOOL finished) {
            [self.searchController.view removeFromSuperview];
            [self.searchTableView removeFromSuperview];
            self.isResultTableView = NO;
            self.searchTableView = nil;
            self.searchController = nil;
            if (!self.navigationItem.leftBarButtonItem) {
                self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Markers" style:UIBarButtonItemStylePlain target:self action:@selector(listOfMarkerButtonWasPressed:)];
            }
            if (!self.navigationItem.rightBarButtonItem) {
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(didPressSearchBarButtonItem:)];
            }
            
        }];
    }
    else {
        [UIView animateWithDuration:.5 animations:^{
            self.searchTableView.frame = CGRectMake(0, 63, self.view.bounds.size.width, 1);
        } completion:^(BOOL finished) {
            self.isShowOneSearchMarker = YES;
            self.isResultTableView = NO;
        }];
    }
}

- (void)updateTableView {
    self.filteredData = nil;
    [UIView animateWithDuration:1 animations:^{
        self.searchTableView.frame = CGRectMake(0, 64, self.view.bounds.size.width, self.view.bounds.size.height-280);
    } completion:^(BOOL finished) {
        [self hideDetailInfoViewForMarkerWithAnimation:NO];
        self.isResultTableView = YES;
        [self.searchTimer invalidate];
        self.searchTimer = nil;
        NSString* filter = @"%K CONTAINS[c] %@";
        NSPredicate* predicate = [NSPredicate predicateWithFormat:filter, @"title", self.searchController.searchBar.text];
        self.filteredData = [self.arrayOfMarkers filteredArrayUsingPredicate:predicate];
        [self.searchTableView reloadData];
    }];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    if (self.searchTimer) {
        [self.searchTimer invalidate];
        self.searchTimer = nil;
    }
    if (searchController.searchBar.text.length>=2 && !self.isResultTableView) {
        self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                         target:self
                                       selector:@selector(updateTableView)
                                       userInfo:nil
                                        repeats:NO];
    }
    else if (self.isResultTableView)
    {
        NSString* filter = @"%K CONTAINS[c] %@";
        NSPredicate* predicate = [NSPredicate predicateWithFormat:filter, @"title", searchController.searchBar.text];
        self.filteredData = [self.arrayOfMarkers filteredArrayUsingPredicate:predicate];
        [self.searchTableView reloadData];
    }
}

#pragma mark - UISearchBarDelegate


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (!self.isResultTableView) {
        NSString* filter = @"%K CONTAINS[c] %@";
        NSPredicate* predicate = [NSPredicate predicateWithFormat:filter, @"title", self.searchController.searchBar.text];
        self.filteredData = [self.arrayOfMarkers filteredArrayUsingPredicate:predicate];
        if (self.searchTimer) {
            [self.searchTimer invalidate];
            self.searchTimer = nil;
        }
    }
    [self.clusterManager removeItems];
    self.isShowOneSearchMarker = YES;
    for (GMSMarker *marker in self.filteredData) {
        CustomMarker* spot = [[CustomMarker alloc] init];
        spot.location = marker.position;
        spot.marker = marker;
        [self.clusterManager addItem:spot];
    }
    self.isShowOneSearchMarker = YES;
    [self hideSearchTableViewWithSearchBar:NO];
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];
    for (GMSMarker *item in self.filteredData) {
        bounds = [bounds includingCoordinate:item.position];
    }
    [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:50.0f]];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar; {
    [self hideSearchTableViewWithSearchBar:YES];
    self.navigationItem.titleView = nil;
    if (self.isShowOneSearchMarker) {
        [self.clusterManager removeItems];
        [self creatingMarkersWithAddingToMarkersArray:NO];
        [self.clusterManager cluster];
        self.isShowOneSearchMarker = NO;
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier: cellIdentifier];
    }
    GMSMarker *marker = [self.filteredData objectAtIndex:indexPath.row];
    cell.textLabel.text = marker.title;
    cell.detailTextLabel.text = marker.snippet;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GMSMarker *marker = [self.filteredData objectAtIndex:indexPath.row];
    self.searchController.searchBar.text = marker.title;
    [self.clusterManager removeItems];
    self.isShowOneSearchMarker = YES;
    CustomMarker* spot = [[CustomMarker alloc] init];
    spot.location = marker.position;
    spot.marker = marker;
    [self.clusterManager addItem:spot];
    [self hideSearchTableViewWithSearchBar:NO];
    [self.mapView animateToCameraPosition:[GMSCameraPosition cameraWithLatitude:marker.position.latitude
                                                                      longitude:marker.position.longitude
                                                                           zoom:10.0f]];
    [self.searchController.searchBar resignFirstResponder];
}

@end
