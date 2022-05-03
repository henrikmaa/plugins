// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "GoogleMapPolylineController.h"
#import "JsonConversions.h"

static UIImage *ExtractIcon(NSObject<FlutterPluginRegistrar> *registrar, NSArray *icon);

@implementation FLTGoogleMapPolylineController {
  GMSPolyline *_polyline;
  GMSMapView *_mapView;
}
- (instancetype)initPolylineWithPath:(GMSMutablePath *)path
                          polylineId:(NSString *)polylineId
                             mapView:(GMSMapView *)mapView {
  self = [super init];
  if (self) {
    _polyline = [GMSPolyline polylineWithPath:path];
    _mapView = mapView;
    _polylineId = polylineId;
    _polyline.userData = @[ polylineId ];
  }
  return self;
}

- (void)removePolyline {
  _polyline.map = nil;
}

#pragma mark - FLTGoogleMapPolylineOptionsSink methods

- (void)setConsumeTapEvents:(BOOL)consumes {
  _polyline.tappable = consumes;
}
- (void)setVisible:(BOOL)visible {
  _polyline.map = visible ? _mapView : nil;
}

- (void)setStampStyle:(UIImage *)icon {
    GMSTextureStyle *stampStyle = [GMSTextureStyle textureStyleWithImage:icon];
    GMSStrokeStyle *strokeStyle = [GMSStrokeStyle solidColor:[UIColor clearColor]];
    strokeStyle.stampStyle = stampStyle;
    NSArray *spans = @[[GMSStyleSpan spanWithStyle:strokeStyle]];
    _polyline.spans = spans;
}

- (void)setZIndex:(int)zIndex {
  _polyline.zIndex = zIndex;
}
- (void)setPoints:(NSArray<CLLocation *> *)points {
  GMSMutablePath *path = [GMSMutablePath path];

  for (CLLocation *location in points) {
    [path addCoordinate:location.coordinate];
  }
  _polyline.path = path;
}

- (void)setColor:(UIColor *)color {
  _polyline.strokeColor = color;
}
- (void)setStrokeWidth:(CGFloat)width {
  _polyline.strokeWidth = width;
}

- (void)setGeodesic:(BOOL)isGeodesic {
  _polyline.geodesic = isGeodesic;
}
@end

static int ToInt(NSNumber *data) { return [FLTGoogleMapJsonConversions toInt:data]; }

static BOOL ToBool(NSNumber *data) { return [FLTGoogleMapJsonConversions toBool:data]; }

static NSArray<CLLocation *> *ToPoints(NSArray *data) {
  return [FLTGoogleMapJsonConversions toPoints:data];
}

static UIColor *ToColor(NSNumber *data) { return [FLTGoogleMapJsonConversions toColor:data]; }

static void InterpretPolylineOptions(NSDictionary *data, id<FLTGoogleMapPolylineOptionsSink> sink,
                                     NSObject<FlutterPluginRegistrar> *registrar) {
  NSNumber *consumeTapEvents = data[@"consumeTapEvents"];
  if (consumeTapEvents != nil) {
    [sink setConsumeTapEvents:ToBool(consumeTapEvents)];
  }

  NSNumber *visible = data[@"visible"];
  if (visible != nil) {
    [sink setVisible:ToBool(visible)];
  }

    NSArray *icon = data[@"iosStampStyle"];
    if (icon != nil) {
        UIImage *image = ExtractIcon(registrar, icon);
        [sink setStampStyle:image];
    }

  NSNumber *zIndex = data[@"zIndex"];
  if (zIndex != nil) {
    [sink setZIndex:ToInt(zIndex)];
  }

  NSArray *points = data[@"points"];
  if (points) {
    [sink setPoints:ToPoints(points)];
  }

  NSNumber *strokeColor = data[@"color"];
  if (strokeColor != nil) {
    [sink setColor:ToColor(strokeColor)];
  }

  NSNumber *strokeWidth = data[@"width"];
  if (strokeWidth != nil) {
    [sink setStrokeWidth:ToInt(strokeWidth)];
  }

  NSNumber *geodesic = data[@"geodesic"];
  if (geodesic != nil) {
    [sink setGeodesic:geodesic.boolValue];
  }
}

@implementation FLTPolylinesController {
  NSMutableDictionary *_polylineIdToController;
  FlutterMethodChannel *_methodChannel;
  NSObject<FlutterPluginRegistrar> *_registrar;
  GMSMapView *_mapView;
}
- (instancetype)init:(FlutterMethodChannel *)methodChannel
             mapView:(GMSMapView *)mapView
           registrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  self = [super init];
  if (self) {
    _methodChannel = methodChannel;
    _mapView = mapView;
    _polylineIdToController = [NSMutableDictionary dictionaryWithCapacity:1];
    _registrar = registrar;
  }
  return self;
}
- (void)addPolylines:(NSArray *)polylinesToAdd {
  for (NSDictionary *polyline in polylinesToAdd) {
    GMSMutablePath *path = [FLTPolylinesController getPath:polyline];
    NSString *polylineId = [FLTPolylinesController getPolylineId:polyline];
    FLTGoogleMapPolylineController *controller =
        [[FLTGoogleMapPolylineController alloc] initPolylineWithPath:path
                                                          polylineId:polylineId
                                                             mapView:_mapView];
    InterpretPolylineOptions(polyline, controller, _registrar);
    _polylineIdToController[polylineId] = controller;
  }
}
- (void)changePolylines:(NSArray *)polylinesToChange {
  for (NSDictionary *polyline in polylinesToChange) {
    NSString *polylineId = [FLTPolylinesController getPolylineId:polyline];
    FLTGoogleMapPolylineController *controller = _polylineIdToController[polylineId];
    if (!controller) {
      continue;
    }
    InterpretPolylineOptions(polyline, controller, _registrar);
  }
}
- (void)removePolylineIds:(NSArray *)polylineIdsToRemove {
  for (NSString *polylineId in polylineIdsToRemove) {
    if (!polylineId) {
      continue;
    }
    FLTGoogleMapPolylineController *controller = _polylineIdToController[polylineId];
    if (!controller) {
      continue;
    }
    [controller removePolyline];
    [_polylineIdToController removeObjectForKey:polylineId];
  }
}
- (void)onPolylineTap:(NSString *)polylineId {
  if (!polylineId) {
    return;
  }
  FLTGoogleMapPolylineController *controller = _polylineIdToController[polylineId];
  if (!controller) {
    return;
  }
  [_methodChannel invokeMethod:@"polyline#onTap" arguments:@{@"polylineId" : polylineId}];
}
- (bool)hasPolylineWithId:(NSString *)polylineId {
  if (!polylineId) {
    return false;
  }
  return _polylineIdToController[polylineId] != nil;
}
+ (GMSMutablePath *)getPath:(NSDictionary *)polyline {
  NSArray *pointArray = polyline[@"points"];
  NSArray<CLLocation *> *points = ToPoints(pointArray);
  GMSMutablePath *path = [GMSMutablePath path];
  for (CLLocation *location in points) {
    [path addCoordinate:location.coordinate];
  }
  return path;
}
+ (NSString *)getPolylineId:(NSDictionary *)polyline {
  return polyline[@"polylineId"];
}
@end

static double ToDouble(NSNumber *data) { return [FLTGoogleMapJsonConversions toDouble:data]; }


static UIImage *scaleImage(UIImage *image, NSNumber *scaleParam) {
  double scale = 1.0;
  if ([scaleParam isKindOfClass:[NSNumber class]]) {
    scale = scaleParam.doubleValue;
  }
  if (fabs(scale - 1) > 1e-3) {
    return [UIImage imageWithCGImage:[image CGImage]
                               scale:(image.scale * scale)
                         orientation:(image.imageOrientation)];
  }
  return image;
}

static UIImage *ExtractIcon(NSObject<FlutterPluginRegistrar> *registrar, NSArray *iconData) {
  UIImage *image;
  if ([iconData.firstObject isEqualToString:@"defaultMarker"]) {
    CGFloat hue = (iconData.count == 1) ? 0.0f : ToDouble(iconData[1]);
    image = [GMSMarker markerImageWithColor:[UIColor colorWithHue:hue / 360.0
                                                       saturation:1.0
                                                       brightness:0.7
                                                            alpha:1.0]];
  } else if ([iconData.firstObject isEqualToString:@"fromAsset"]) {
    if (iconData.count == 2) {
      image = [UIImage imageNamed:[registrar lookupKeyForAsset:iconData[1]]];
    } else {
      image = [UIImage imageNamed:[registrar lookupKeyForAsset:iconData[1]
                                                   fromPackage:iconData[2]]];
    }
  } else if ([iconData.firstObject isEqualToString:@"fromAssetImage"]) {
    if (iconData.count == 3) {
      image = [UIImage imageNamed:[registrar lookupKeyForAsset:iconData[1]]];
      NSNumber *scaleParam = iconData[2];
      image = scaleImage(image, scaleParam);
    } else {
      NSString *error =
          [NSString stringWithFormat:@"'fromAssetImage' should have exactly 3 arguments. Got: %lu",
                                     (unsigned long)iconData.count];
      NSException *exception = [NSException exceptionWithName:@"InvalidBitmapDescriptor"
                                                       reason:error
                                                     userInfo:nil];
      @throw exception;
    }
  } else if ([iconData[0] isEqualToString:@"fromBytes"]) {
    if (iconData.count == 2) {
      @try {
        FlutterStandardTypedData *byteData = iconData[1];
        CGFloat screenScale = [[UIScreen mainScreen] scale];
        image = [UIImage imageWithData:[byteData data] scale:screenScale];
      } @catch (NSException *exception) {
        @throw [NSException exceptionWithName:@"InvalidByteDescriptor"
                                       reason:@"Unable to interpret bytes as a valid image."
                                     userInfo:nil];
      }
    } else {
      NSString *error = [NSString
          stringWithFormat:@"fromBytes should have exactly one argument, the bytes. Got: %lu",
                           (unsigned long)iconData.count];
      NSException *exception = [NSException exceptionWithName:@"InvalidByteDescriptor"
                                                       reason:error
                                                     userInfo:nil];
      @throw exception;
    }
  }

  return image;
}