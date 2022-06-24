// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <GoogleMaps/GoogleMaps.h>
#import "JsonConversions.h"

// Defines polyline UI options writable from Flutter.
@protocol FLTGoogleMapPolylineOptionsSink
- (void)setConsumeTapEvents:(BOOL)consume;
- (void)setVisible:(BOOL)visible;
- (void)setColor:(UIColor *)color;
- (void)setStrokeWidth:(CGFloat)width;
- (void)setPoints:(NSArray<CLLocation *> *)points;
- (void)setStampStyle:(UIImage * _Nonnull)image;
- (void)setZIndex:(int)zIndex;
- (void)setGeodesic:(BOOL)isGeodesic;
- (void)setPattern:(NSArray<FLTPolylinePattern*>*)pattern;
@end

// Defines polyline controllable by Flutter.
@interface FLTGoogleMapPolylineController : NSObject <FLTGoogleMapPolylineOptionsSink>
@property(atomic, readonly) NSString *polylineId;
- (instancetype)initPolylineWithPath:(GMSMutablePath *)path
                          polylineId:(NSString *)polylineId
                             mapView:(GMSMapView *)mapView;
- (void)removePolyline;
- (void)redraw;
@end

@interface FLTPolylinesController : NSObject
- (instancetype)init:(FlutterMethodChannel *)methodChannel
             mapView:(GMSMapView *)mapView
           registrar:(NSObject<FlutterPluginRegistrar> *)registrar;
- (void)addPolylines:(NSArray *)polylinesToAdd;
- (void)changePolylines:(NSArray *)polylinesToChange;
- (void)removePolylineIds:(NSArray *)polylineIdsToRemove;
- (void)onPolylineTap:(NSString *)polylineId;
- (bool)hasPolylineWithId:(NSString *)polylineId;
- (void)redrawPolylines;
@end
