// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues, hashList;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart'
    show listEquals, objectRuntimeType, setEquals;

import 'maps_object.dart';
import 'utils/maps_object.dart';

/// Update specification for a set of objects.
class MapsObjectUpdates<T extends MapsObject> {
  MapsObjectUpdates.from(
    Set<T> previous,
    Set<T> current, {
    required this.objectName,
  }) {
    final Map<MapsObjectId<T>, T> previousObjects = keyByMapsObjectId(previous);
    final Map<MapsObjectId<T>, T> currentObjects = keyByMapsObjectId(current);

    _apply(previousObjects, currentObjects);
  }

  /// Computes updates given previous and current object sets.
  ///
  /// [objectName] is the prefix to use when serializing the updates into a JSON
  /// dictionary. E.g., 'circle' will give 'circlesToAdd', 'circlesToUpdate',
  /// 'circleIdsToRemove'.
  MapsObjectUpdates.mapFrom(
    Map<MapsObjectId<T>, T> previousObjects,
    Map<MapsObjectId<T>, T> currentObjects, {
    required this.objectName,
  }) {
    _apply(previousObjects, currentObjects);
  }

  void _apply(Map<MapsObjectId<T>, T> previousObjects,
      Map<MapsObjectId<T>, T> currentObjects) {
    final Set<MapsObjectId<T>> previousObjectIds = MapKeySet(previousObjects);
    final Set<MapsObjectId<T>> currentObjectIds = MapKeySet(currentObjects);

    /// Maps an ID back to a [T] in [currentObjects].
    ///
    /// It is a programming error to call this with an ID that is not guaranteed
    /// to be in [currentObjects].
    T _idToCurrentObject(MapsObjectId<T> id) {
      return currentObjects[id]!;
    }

    _objectIdsToRemove = [];
    for (final id in previousObjectIds) {
      if (!currentObjectIds.contains(id)) {
        _objectIdsToRemove.add(id);
      }
    }

    _objectsToAdd = [];
    _objectsToChange = [];

    for (final current in currentObjects.values) {
      final previous = previousObjects[current.mapsId];

      if (previous != null) {
        final hasChanged = !identical(current, previous) && current != previous;

        if (hasChanged) {
          _objectsToChange.add(current);
        }
      } else {
        _objectsToAdd.add(current);
      }
    }

    _previousObjects = previousObjects;
  }

  /// The name of the objects being updated, for use in serialization.
  final String objectName;

  /// Set of objects to be added in this update.
  List<T> get objectsToAdd {
    return _objectsToAdd;
  }

  late List<T> _objectsToAdd;

  /// Set of objects to be removed in this update.
  List<MapsObjectId<T>> get objectIdsToRemove {
    return _objectIdsToRemove;
  }

  late List<MapsObjectId<T>> _objectIdsToRemove;

  /// Set of objects to be changed in this update.
  List<T> get objectsToChange {
    return _objectsToChange;
  }

  late Map<MapsObjectId<T>, T> _previousObjects;
  late List<T> _objectsToChange;

  /// Converts this object to JSON.
  Object toJson() {
    final Map<String, Object> updateMap = <String, Object>{};

    void addIfNonNull(String fieldName, Object? value) {
      if (value != null) {
        updateMap[fieldName] = value;
      }
    }

    addIfNonNull('${objectName}sToAdd', serializeMapsObjectSet(_objectsToAdd));
    addIfNonNull('${objectName}sToChange',
        serializeMapsObjectSet(_objectsToChange, _previousObjects));
    addIfNonNull(
        '${objectName}IdsToRemove',
        _objectIdsToRemove
            .map<String>((MapsObjectId<T> m) => m.value)
            .toList());

    return updateMap;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MapsObjectUpdates &&
        listEquals(_objectsToAdd, other._objectsToAdd) &&
        listEquals(_objectIdsToRemove, other._objectIdsToRemove) &&
        listEquals(_objectsToChange, other._objectsToChange);
  }

  @override
  int get hashCode => hashValues(hashList(_objectsToAdd),
      hashList(_objectIdsToRemove), hashList(_objectsToChange));

  @override
  String toString() {
    return '${objectRuntimeType(this, 'MapsObjectUpdates')}(add: $objectsToAdd, '
        'remove: $objectIdsToRemove, '
        'change: $objectsToChange)';
  }

  bool get isNotEmpty =>
      objectsToAdd.isNotEmpty ||
      objectsToChange.isNotEmpty ||
      objectIdsToRemove.isNotEmpty;
}
