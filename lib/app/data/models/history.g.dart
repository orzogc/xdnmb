// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBrowseHistoryCollection on Isar {
  IsarCollection<BrowseHistory> get browseHistorys => this.collection();
}

const BrowseHistorySchema = CollectionSchema(
  name: r'BrowseHistory',
  id: -8719495174162917793,
  properties: {
    r'browsePage': PropertySchema(
      id: 0,
      name: r'browsePage',
      type: IsarType.long,
    ),
    r'browsePostId': PropertySchema(
      id: 1,
      name: r'browsePostId',
      type: IsarType.long,
    ),
    r'browseTime': PropertySchema(
      id: 2,
      name: r'browseTime',
      type: IsarType.dateTime,
    ),
    r'content': PropertySchema(
      id: 3,
      name: r'content',
      type: IsarType.string,
    ),
    r'forumId': PropertySchema(
      id: 4,
      name: r'forumId',
      type: IsarType.long,
    ),
    r'hasImage': PropertySchema(
      id: 5,
      name: r'hasImage',
      type: IsarType.bool,
    ),
    r'image': PropertySchema(
      id: 6,
      name: r'image',
      type: IsarType.string,
    ),
    r'imageExtension': PropertySchema(
      id: 7,
      name: r'imageExtension',
      type: IsarType.string,
    ),
    r'isAdmin': PropertySchema(
      id: 8,
      name: r'isAdmin',
      type: IsarType.bool,
    ),
    r'isHidden': PropertySchema(
      id: 9,
      name: r'isHidden',
      type: IsarType.bool,
    ),
    r'isSage': PropertySchema(
      id: 10,
      name: r'isSage',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 11,
      name: r'name',
      type: IsarType.string,
    ),
    r'onlyPoBrowsePage': PropertySchema(
      id: 12,
      name: r'onlyPoBrowsePage',
      type: IsarType.long,
    ),
    r'onlyPoBrowsePostId': PropertySchema(
      id: 13,
      name: r'onlyPoBrowsePostId',
      type: IsarType.long,
    ),
    r'postTime': PropertySchema(
      id: 14,
      name: r'postTime',
      type: IsarType.dateTime,
    ),
    r'replyCount': PropertySchema(
      id: 15,
      name: r'replyCount',
      type: IsarType.long,
    ),
    r'title': PropertySchema(
      id: 16,
      name: r'title',
      type: IsarType.string,
    ),
    r'userHash': PropertySchema(
      id: 17,
      name: r'userHash',
      type: IsarType.string,
    )
  },
  estimateSize: _browseHistoryEstimateSize,
  serialize: _browseHistorySerialize,
  deserialize: _browseHistoryDeserialize,
  deserializeProp: _browseHistoryDeserializeProp,
  idName: r'id',
  indexes: {
    r'browseTime': IndexSchema(
      id: -9172530118405459750,
      name: r'browseTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'browseTime',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _browseHistoryGetId,
  getLinks: _browseHistoryGetLinks,
  attach: _browseHistoryAttach,
  version: '3.1.7',
);

int _browseHistoryEstimateSize(
  BrowseHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.image.length * 3;
  bytesCount += 3 + object.imageExtension.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.userHash.length * 3;
  return bytesCount;
}

void _browseHistorySerialize(
  BrowseHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.browsePage);
  writer.writeLong(offsets[1], object.browsePostId);
  writer.writeDateTime(offsets[2], object.browseTime);
  writer.writeString(offsets[3], object.content);
  writer.writeLong(offsets[4], object.forumId);
  writer.writeBool(offsets[5], object.hasImage);
  writer.writeString(offsets[6], object.image);
  writer.writeString(offsets[7], object.imageExtension);
  writer.writeBool(offsets[8], object.isAdmin);
  writer.writeBool(offsets[9], object.isHidden);
  writer.writeBool(offsets[10], object.isSage);
  writer.writeString(offsets[11], object.name);
  writer.writeLong(offsets[12], object.onlyPoBrowsePage);
  writer.writeLong(offsets[13], object.onlyPoBrowsePostId);
  writer.writeDateTime(offsets[14], object.postTime);
  writer.writeLong(offsets[15], object.replyCount);
  writer.writeString(offsets[16], object.title);
  writer.writeString(offsets[17], object.userHash);
}

BrowseHistory _browseHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BrowseHistory(
    browsePage: reader.readLongOrNull(offsets[0]),
    browsePostId: reader.readLongOrNull(offsets[1]),
    browseTime: reader.readDateTime(offsets[2]),
    content: reader.readString(offsets[3]),
    forumId: reader.readLong(offsets[4]),
    hasImage: reader.readBoolOrNull(offsets[5]) ?? false,
    id: id,
    image: reader.readStringOrNull(offsets[6]) ?? '',
    isAdmin: reader.readBoolOrNull(offsets[8]) ?? false,
    isHidden: reader.readBoolOrNull(offsets[9]) ?? false,
    isSage: reader.readBoolOrNull(offsets[10]) ?? false,
    name: reader.readStringOrNull(offsets[11]) ?? '',
    onlyPoBrowsePage: reader.readLongOrNull(offsets[12]),
    onlyPoBrowsePostId: reader.readLongOrNull(offsets[13]),
    postTime: reader.readDateTime(offsets[14]),
    replyCount: reader.readLong(offsets[15]),
    title: reader.readStringOrNull(offsets[16]) ?? '',
    userHash: reader.readString(offsets[17]),
  );
  object.imageExtension = reader.readString(offsets[7]);
  return object;
}

P _browseHistoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 6:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 9:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 10:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 11:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readLongOrNull(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 17:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _browseHistoryGetId(BrowseHistory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _browseHistoryGetLinks(BrowseHistory object) {
  return [];
}

void _browseHistoryAttach(
    IsarCollection<dynamic> col, Id id, BrowseHistory object) {}

extension BrowseHistoryQueryWhereSort
    on QueryBuilder<BrowseHistory, BrowseHistory, QWhere> {
  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhere> anyBrowseTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'browseTime'),
      );
    });
  }
}

extension BrowseHistoryQueryWhere
    on QueryBuilder<BrowseHistory, BrowseHistory, QWhereClause> {
  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause>
      browseTimeEqualTo(DateTime browseTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'browseTime',
        value: [browseTime],
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause>
      browseTimeNotEqualTo(DateTime browseTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'browseTime',
              lower: [],
              upper: [browseTime],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'browseTime',
              lower: [browseTime],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'browseTime',
              lower: [browseTime],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'browseTime',
              lower: [],
              upper: [browseTime],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause>
      browseTimeGreaterThan(
    DateTime browseTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'browseTime',
        lower: [browseTime],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause>
      browseTimeLessThan(
    DateTime browseTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'browseTime',
        lower: [],
        upper: [browseTime],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterWhereClause>
      browseTimeBetween(
    DateTime lowerBrowseTime,
    DateTime upperBrowseTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'browseTime',
        lower: [lowerBrowseTime],
        includeLower: includeLower,
        upper: [upperBrowseTime],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension BrowseHistoryQueryFilter
    on QueryBuilder<BrowseHistory, BrowseHistory, QFilterCondition> {
  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'browsePage',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'browsePage',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePageEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'browsePage',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePageGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'browsePage',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePageLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'browsePage',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePageBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'browsePage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePostIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'browsePostId',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePostIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'browsePostId',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePostIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'browsePostId',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePostIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'browsePostId',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePostIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'browsePostId',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browsePostIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'browsePostId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browseTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'browseTime',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browseTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'browseTime',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browseTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'browseTime',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      browseTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'browseTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      forumIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'forumId',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      forumIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'forumId',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      forumIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'forumId',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      forumIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'forumId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      hasImageEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasImage',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'image',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'image',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'image',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'image',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'image',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageExtension',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageExtension',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageExtension',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageExtension',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageExtension',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageExtension',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageExtension',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageExtension',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageExtension',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      imageExtensionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageExtension',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      isAdminEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAdmin',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      isHiddenEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isHidden',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      isSageEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSage',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlyPoBrowsePage',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlyPoBrowsePage',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePageEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlyPoBrowsePage',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePageGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlyPoBrowsePage',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePageLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlyPoBrowsePage',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePageBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlyPoBrowsePage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePostIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'onlyPoBrowsePostId',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePostIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'onlyPoBrowsePostId',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePostIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'onlyPoBrowsePostId',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePostIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'onlyPoBrowsePostId',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePostIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'onlyPoBrowsePostId',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      onlyPoBrowsePostIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'onlyPoBrowsePostId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      postTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'postTime',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      postTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'postTime',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      postTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'postTime',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      postTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'postTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      replyCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replyCount',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      replyCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replyCount',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      replyCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replyCount',
        value: value,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      replyCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replyCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userHash',
        value: '',
      ));
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterFilterCondition>
      userHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userHash',
        value: '',
      ));
    });
  }
}

extension BrowseHistoryQueryObject
    on QueryBuilder<BrowseHistory, BrowseHistory, QFilterCondition> {}

extension BrowseHistoryQueryLinks
    on QueryBuilder<BrowseHistory, BrowseHistory, QFilterCondition> {}

extension BrowseHistoryQuerySortBy
    on QueryBuilder<BrowseHistory, BrowseHistory, QSortBy> {
  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByBrowsePage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browsePage', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByBrowsePageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browsePage', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByBrowsePostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browsePostId', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByBrowsePostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browsePostId', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByBrowseTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browseTime', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByBrowseTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browseTime', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByForumId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'forumId', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByForumIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'forumId', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByHasImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasImage', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByHasImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasImage', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByImageExtension() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageExtension', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByImageExtensionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageExtension', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByIsAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdmin', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByIsAdminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdmin', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByIsHiddenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByIsSage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSage', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByIsSageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSage', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByOnlyPoBrowsePage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyPoBrowsePage', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByOnlyPoBrowsePageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyPoBrowsePage', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByOnlyPoBrowsePostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyPoBrowsePostId', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByOnlyPoBrowsePostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyPoBrowsePostId', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByPostTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByPostTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByReplyCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCount', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByReplyCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCount', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> sortByUserHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userHash', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      sortByUserHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userHash', Sort.desc);
    });
  }
}

extension BrowseHistoryQuerySortThenBy
    on QueryBuilder<BrowseHistory, BrowseHistory, QSortThenBy> {
  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByBrowsePage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browsePage', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByBrowsePageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browsePage', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByBrowsePostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browsePostId', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByBrowsePostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browsePostId', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByBrowseTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browseTime', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByBrowseTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'browseTime', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByForumId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'forumId', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByForumIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'forumId', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByHasImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasImage', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByHasImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasImage', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByImageExtension() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageExtension', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByImageExtensionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageExtension', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByIsAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdmin', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByIsAdminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdmin', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByIsHiddenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHidden', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByIsSage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSage', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByIsSageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSage', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByOnlyPoBrowsePage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyPoBrowsePage', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByOnlyPoBrowsePageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyPoBrowsePage', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByOnlyPoBrowsePostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyPoBrowsePostId', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByOnlyPoBrowsePostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyPoBrowsePostId', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByPostTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByPostTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByReplyCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCount', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByReplyCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyCount', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy> thenByUserHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userHash', Sort.asc);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QAfterSortBy>
      thenByUserHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userHash', Sort.desc);
    });
  }
}

extension BrowseHistoryQueryWhereDistinct
    on QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> {
  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByBrowsePage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'browsePage');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct>
      distinctByBrowsePostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'browsePostId');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByBrowseTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'browseTime');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByForumId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'forumId');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByHasImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasImage');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByImage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'image', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct>
      distinctByImageExtension({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageExtension',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByIsAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAdmin');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByIsHidden() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isHidden');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByIsSage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSage');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct>
      distinctByOnlyPoBrowsePage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlyPoBrowsePage');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct>
      distinctByOnlyPoBrowsePostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlyPoBrowsePostId');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByPostTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postTime');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByReplyCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replyCount');
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BrowseHistory, BrowseHistory, QDistinct> distinctByUserHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userHash', caseSensitive: caseSensitive);
    });
  }
}

extension BrowseHistoryQueryProperty
    on QueryBuilder<BrowseHistory, BrowseHistory, QQueryProperty> {
  QueryBuilder<BrowseHistory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BrowseHistory, int?, QQueryOperations> browsePageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'browsePage');
    });
  }

  QueryBuilder<BrowseHistory, int?, QQueryOperations> browsePostIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'browsePostId');
    });
  }

  QueryBuilder<BrowseHistory, DateTime, QQueryOperations> browseTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'browseTime');
    });
  }

  QueryBuilder<BrowseHistory, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<BrowseHistory, int, QQueryOperations> forumIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'forumId');
    });
  }

  QueryBuilder<BrowseHistory, bool, QQueryOperations> hasImageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasImage');
    });
  }

  QueryBuilder<BrowseHistory, String, QQueryOperations> imageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'image');
    });
  }

  QueryBuilder<BrowseHistory, String, QQueryOperations>
      imageExtensionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageExtension');
    });
  }

  QueryBuilder<BrowseHistory, bool, QQueryOperations> isAdminProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAdmin');
    });
  }

  QueryBuilder<BrowseHistory, bool, QQueryOperations> isHiddenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isHidden');
    });
  }

  QueryBuilder<BrowseHistory, bool, QQueryOperations> isSageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSage');
    });
  }

  QueryBuilder<BrowseHistory, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<BrowseHistory, int?, QQueryOperations>
      onlyPoBrowsePageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlyPoBrowsePage');
    });
  }

  QueryBuilder<BrowseHistory, int?, QQueryOperations>
      onlyPoBrowsePostIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlyPoBrowsePostId');
    });
  }

  QueryBuilder<BrowseHistory, DateTime, QQueryOperations> postTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postTime');
    });
  }

  QueryBuilder<BrowseHistory, int, QQueryOperations> replyCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replyCount');
    });
  }

  QueryBuilder<BrowseHistory, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<BrowseHistory, String, QQueryOperations> userHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userHash');
    });
  }
}
