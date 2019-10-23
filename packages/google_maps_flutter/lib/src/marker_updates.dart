// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of google_maps_flutter;

/// [Marker] update events to be applied to the [GoogleMap].
///
/// Used in [GoogleMapController] when the map is updated.
class _MarkerUpdates {
  /// Computes [_MarkerUpdates] given previous and current [Marker]s.
  _MarkerUpdates.from(Set<Marker> previous, Set<Marker> current) {
    if (previous == null) {
      previous = Set<Marker>.identity();
    }

    if (current == null) {
      current = Set<Marker>.identity();
    }

    final Map<MarkerId, Marker> previousMarkers = _keyByMarkerId(previous);
    final Map<MarkerId, Marker> currentMarkers = _keyByMarkerId(current);

    final Set<MarkerId> prevMarkerIds = previousMarkers.keys.toSet();
    final Set<MarkerId> currentMarkerIds = currentMarkers.keys.toSet();

    Marker idToCurrentMarker(MarkerId id) {
      return currentMarkers[id];
    }

    final Set<MarkerId> _markerIdsToRemove =
        prevMarkerIds.difference(currentMarkerIds);

    final Set<Marker> _markersToAdd = currentMarkerIds
        .difference(prevMarkerIds)
        .map(idToCurrentMarker)
        .toSet();

    /// Returns `true` if [current] is not equals to previous one with the
    /// same id.
    bool hasChanged(Marker current) {
      return current.alpha != null ||
          current.anchor != null ||
          current.draggable != null ||
          current.flat != null ||
          current.icon != null ||
          current.infoWindow != null ||
          current.position != null ||
          current.rotation != null ||
          current.visible != null ||
          current.zIndex != null;
    }

    /// Returns `true` if [current] is not equals to previous one with the
    /// same id.
    Marker filterChanges(Marker current) {
      final Marker previous = previousMarkers[current.markerId];

      return Marker(
        markerId: current.markerId,
        alpha: current.alpha != previous.alpha ? current.alpha : null,
        anchor: current.anchor != previous.alpha ? current.anchor : null,
        draggable: current.draggable != previous.draggable ? current.draggable : null,
        flat: current.flat != previous.flat ? current.flat : null,
        icon: current.icon != previous.icon ? current.icon : null,
        infoWindow: current.infoWindow != previous.infoWindow ? current.infoWindow : null,
        position: current.position != previous.position ? current.position : null,
        rotation: current.rotation != previous.rotation ? current.rotation : null,
        visible: current.visible != previous.visible ? current.visible : null,
        zIndex: current.zIndex != previous.zIndex ? current.zIndex : null,
//          onTap: current.onTap,
//          onDragEnd: current.onDragEnd
      );
    }

    final Set<Marker> _markersToChange = currentMarkerIds
        .intersection(prevMarkerIds)
        .map(idToCurrentMarker)
        .map(filterChanges)
        .where(hasChanged)
        .toSet();

    markersToAdd = _markersToAdd;
    markerIdsToRemove = _markerIdsToRemove;
    markersToChange = _markersToChange;
  }

  Set<Marker> markersToAdd;
  Set<MarkerId> markerIdsToRemove;
  Set<Marker> markersToChange;

  Map<String, dynamic> _toMap() {
    final Map<String, dynamic> updateMap = <String, dynamic>{};

    void addIfNonNull(String fieldName, dynamic value) {
      if (value != null) {
        updateMap[fieldName] = value;
      }
    }

    addIfNonNull('markersToAdd', _serializeMarkerSet(markersToAdd));
    addIfNonNull('markersToChange', _serializeMarkerSet(markersToChange));
    addIfNonNull('markerIdsToRemove',
        markerIdsToRemove.map<dynamic>((MarkerId m) => m.value).toList());

    return updateMap;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final _MarkerUpdates typedOther = other;
    return setEquals(markersToAdd, typedOther.markersToAdd) &&
        setEquals(markerIdsToRemove, typedOther.markerIdsToRemove) &&
        setEquals(markersToChange, typedOther.markersToChange);
  }

  @override
  int get hashCode =>
      hashValues(markersToAdd, markerIdsToRemove, markersToChange);

  @override
  String toString() {
    return '_MarkerUpdates{markersToAdd: $markersToAdd, '
        'markerIdsToRemove: $markerIdsToRemove, '
        'markersToChange: $markersToChange}';
  }
}
