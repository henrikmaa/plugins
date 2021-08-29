// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'types.dart';

/// [Polyline] update events to be applied to the [GoogleMap].
///
/// Used in [GoogleMapController] when the map is updated.
// (Do not re-export)
class PolylineUpdates extends MapsObjectUpdates<Polyline> {
  /// Computes [PolylineUpdates] given previous and current [Polyline]s.
  PolylineUpdates.from(Map<PolylineId, Polyline> previous, Map<PolylineId, Polyline> current)
      : super.mapFrom(previous, current, objectName: 'polyline');

  /// Set of Polylines to be added in this update.
  Iterable<Polyline> get polylinesToAdd => objectsToAdd;

  /// Set of PolylineIds to be removed in this update.
  Iterable<PolylineId> get polylineIdsToRemove =>
      objectIdsToRemove.cast<PolylineId>();

  /// Set of Polylines to be changed in this update.
  Iterable<Polyline> get polylinesToChange => objectsToChange;
}
