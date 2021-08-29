// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

import '../types.dart';
import 'maps_object.dart';

/// Converts an [Iterable] of Markers in a Map of MarkerId -> Marker.
Map<MarkerId, Marker> keyByMarkerId(Iterable<Marker> markers) {
  return keyByMapsObjectId<Marker>(markers).cast<MarkerId, Marker>();
}

/// Converts a Set of Markers into something serializable in JSON.
Object serializeMarkerSet(Map<MarkerId, Marker> markers) {
  return serializeMapsObjectSet(
      MapValueSet<MarkerId, Marker>(markers, (marker) => marker.markerId));
}
