/*
Copyright 2020-2021 Vishesh Handa <me@vhanda.in>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'package:easy_localization/easy_localization.dart';

import 'package:gitjournal/core/note.dart';

typedef NoteSortingFunction = int Function(Note a, Note b);

class SortingOrder {
  static const Ascending = SortingOrder("settings.sortingOrder.asc", "asc");
  static const Descending = SortingOrder("settings.sortingOrder.desc", "desc");
  static const Default = Descending;

  final String _str;
  final String _publicString;
  const SortingOrder(this._publicString, this._str);

  String toInternalString() {
    return _str;
  }

  String toPublicString() {
    return tr(_publicString);
  }

  static const options = <SortingOrder>[
    Ascending,
    Descending,
  ];

  static SortingOrder fromInternalString(String? str) {
    for (var opt in options) {
      if (opt.toInternalString() == str) {
        return opt;
      }
    }
    return Default;
  }

  static SortingOrder fromPublicString(String str) {
    for (var opt in options) {
      if (opt.toPublicString() == str) {
        return opt;
      }
    }
    return Default;
  }

  @override
  String toString() {
    assert(false, "SortingOrder toString should never be called");
    return "";
  }
}

class SortingField {
  static const Modified = SortingField(
    "settings.sortingField.modified",
    "Modified",
  );
  static const Created = SortingField(
    "settings.sortingField.created",
    "Created",
  );
  static const FileName = SortingField(
    "settings.sortingField.filename",
    "FileName",
  );

  static const Default = Modified;

  final String _str;
  final String _publicString;
  const SortingField(this._publicString, this._str);

  String toInternalString() {
    return _str;
  }

  String toPublicString() {
    return tr(_publicString);
  }

  static const options = <SortingField>[
    Modified,
    Created,
    FileName,
  ];

  static SortingField fromInternalString(String? str) {
    for (var opt in options) {
      if (opt.toInternalString() == str) {
        return opt;
      }
    }
    return Default;
  }

  @override
  String toString() {
    assert(false, "SortingField toString should never be called");
    return "";
  }
}

class SortingMode {
  final SortingField field;
  final SortingOrder order;

  SortingMode(this.field, this.order);

  NoteSortingFunction sortingFunction() {
    switch (field) {
      case SortingField.Created:
        return order == SortingOrder.Descending
            ? _sortCreatedDesc
            : _reverse(_sortCreatedDesc);

      case SortingField.FileName:
        return order == SortingOrder.Descending
            ? _reverse(_sortFileNameAsc)
            : _sortFileNameAsc;

      case SortingField.Modified:
      default:
        return order == SortingOrder.Descending
            ? _sortModifiedDesc
            : _reverse(_sortModifiedDesc);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortingMode && other.field == field && other.order == order;

  @override
  int get hashCode => order.hashCode ^ field.hashCode;
}

int _sortCreatedDesc(Note a, Note b) {
  var aDt = a.created;
  var bDt = b.created;
  if (aDt == null && bDt != null) {
    return 1;
  }
  if (aDt != null && bDt == null) {
    return -1;
  }
  if (bDt == null && aDt == null) {
    return a.fileName.compareTo(b.fileName);
  }
  return bDt!.compareTo(aDt!);
}

int _sortModifiedDesc(Note a, Note b) {
  var aDt = a.modified;
  var bDt = b.modified;
  if (aDt == null && bDt != null) {
    return 1;
  }
  if (aDt != null && bDt == null) {
    return -1;
  }
  if (bDt == null && aDt == null) {
    if (a.fileLastModified != null && b.fileLastModified != null) {
      if (a.fileLastModified == null && b.fileLastModified != null) {
        return 1;
      } else if (a.fileLastModified != null && b.fileLastModified == null) {
        return -1;
      } else if (a.fileLastModified != null && b.fileLastModified != null) {
        if (a.fileLastModified! == b.fileLastModified!) {
          return a.fileName.compareTo(b.fileName);
        }
        return a.fileLastModified!.compareTo(b.fileLastModified!);
      } else {
        return a.fileName.compareTo(b.fileName);
      }
    } else {
      return a.fileName.compareTo(b.fileName);
    }
  }
  return bDt!.compareTo(aDt!);
}

int _sortFileNameAsc(Note a, Note b) {
  var aFileName = a.fileName.toLowerCase();
  var bFileName = b.fileName.toLowerCase();
  return aFileName.compareTo(bFileName);
}

NoteSortingFunction _reverse(NoteSortingFunction func) {
  return (Note a, Note b) {
    int r = func(a, b);
    if (r == 0) {
      return r;
    }
    if (r < 0) {
      return 1;
    } else {
      return -1;
    }
  };
}
