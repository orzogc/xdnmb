import 'dart:collection';

HashSet<int> intHashSet() => HashSet<int>(
      equals: (value1, value2) => value1 == value2,
      hashCode: (value) => value,
    );

HashSet<int> intHashSetOf(Iterable<int> elements) =>
    intHashSet()..addAll(elements);

HashMap<int, V> intHashMap<V>() => HashMap<int, V>(
      equals: (key1, key2) => key1 == key2,
      hashCode: (key) => key,
    );

HashMap<int, V> intHashMapOf<V>(Map<int, V> other) =>
    intHashMap<V>()..addAll(other);

HashMap<int, V> intHashMapFromEntries<V>(Iterable<MapEntry<int, V>> entries) =>
    intHashMap<V>()..addEntries(entries);

LinkedHashMap<int, V> intLinkedHashMap<V>() => LinkedHashMap<int, V>(
      equals: (key1, key2) => key1 == key2,
      hashCode: (key) => key,
    );

LinkedHashMap<int, V> intLinkedHashMapOf<V>(Map<int, V> other) =>
    intLinkedHashMap<V>()..addAll(other);

LinkedHashMap<int, V> intLinkedHashMapFromEntries<V>(
        Iterable<MapEntry<int, V>> entries) =>
    intLinkedHashMap<V>()..addEntries(entries);
