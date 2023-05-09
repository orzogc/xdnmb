// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReferenceDataCollection on Isar {
  IsarCollection<ReferenceData> get referenceDatas => this.collection();
}

const ReferenceDataSchema = CollectionSchema(
  name: r'ReferenceData',
  id: 7496384896085969613,
  properties: {
    r'accuratePage': PropertySchema(
      id: 0,
      name: r'accuratePage',
      type: IsarType.long,
    ),
    r'fuzzyPage': PropertySchema(
      id: 1,
      name: r'fuzzyPage',
      type: IsarType.long,
    ),
    r'mainPostId': PropertySchema(
      id: 2,
      name: r'mainPostId',
      type: IsarType.long,
    ),
    r'postTime': PropertySchema(
      id: 3,
      name: r'postTime',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _referenceDataEstimateSize,
  serialize: _referenceDataSerialize,
  deserialize: _referenceDataDeserialize,
  deserializeProp: _referenceDataDeserializeProp,
  idName: r'id',
  indexes: {
    r'mainPostId': IndexSchema(
      id: 8011467706681590527,
      name: r'mainPostId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mainPostId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _referenceDataGetId,
  getLinks: _referenceDataGetLinks,
  attach: _referenceDataAttach,
  version: '3.1.0+1',
);

int _referenceDataEstimateSize(
  ReferenceData object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _referenceDataSerialize(
  ReferenceData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accuratePage);
  writer.writeLong(offsets[1], object.fuzzyPage);
  writer.writeLong(offsets[2], object.mainPostId);
  writer.writeDateTime(offsets[3], object.postTime);
}

ReferenceData _referenceDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReferenceData(
    accuratePage: reader.readLongOrNull(offsets[0]),
    fuzzyPage: reader.readLongOrNull(offsets[1]),
    id: id,
    mainPostId: reader.readLongOrNull(offsets[2]),
    postTime: reader.readDateTimeOrNull(offsets[3]),
  );
  return object;
}

P _referenceDataDeserializeProp<P>(
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
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _referenceDataGetId(ReferenceData object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _referenceDataGetLinks(ReferenceData object) {
  return [];
}

void _referenceDataAttach(
    IsarCollection<dynamic> col, Id id, ReferenceData object) {}

extension ReferenceDataQueryWhereSort
    on QueryBuilder<ReferenceData, ReferenceData, QWhere> {
  QueryBuilder<ReferenceData, ReferenceData, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhere> anyMainPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'mainPostId'),
      );
    });
  }
}

extension ReferenceDataQueryWhere
    on QueryBuilder<ReferenceData, ReferenceData, QWhereClause> {
  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause> idBetween(
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

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause>
      mainPostIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mainPostId',
        value: [null],
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause>
      mainPostIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mainPostId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause>
      mainPostIdEqualTo(int? mainPostId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mainPostId',
        value: [mainPostId],
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause>
      mainPostIdNotEqualTo(int? mainPostId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mainPostId',
              lower: [],
              upper: [mainPostId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mainPostId',
              lower: [mainPostId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mainPostId',
              lower: [mainPostId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mainPostId',
              lower: [],
              upper: [mainPostId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause>
      mainPostIdGreaterThan(
    int? mainPostId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mainPostId',
        lower: [mainPostId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause>
      mainPostIdLessThan(
    int? mainPostId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mainPostId',
        lower: [],
        upper: [mainPostId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterWhereClause>
      mainPostIdBetween(
    int? lowerMainPostId,
    int? upperMainPostId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mainPostId',
        lower: [lowerMainPostId],
        includeLower: includeLower,
        upper: [upperMainPostId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ReferenceDataQueryFilter
    on QueryBuilder<ReferenceData, ReferenceData, QFilterCondition> {
  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      accuratePageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accuratePage',
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      accuratePageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accuratePage',
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      accuratePageEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accuratePage',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      accuratePageGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accuratePage',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      accuratePageLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accuratePage',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      accuratePageBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accuratePage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      fuzzyPageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fuzzyPage',
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      fuzzyPageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fuzzyPage',
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      fuzzyPageEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fuzzyPage',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      fuzzyPageGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fuzzyPage',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      fuzzyPageLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fuzzyPage',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      fuzzyPageBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fuzzyPage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
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

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      mainPostIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mainPostId',
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      mainPostIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mainPostId',
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      mainPostIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mainPostId',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      mainPostIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mainPostId',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      mainPostIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mainPostId',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      mainPostIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mainPostId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      postTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'postTime',
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      postTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'postTime',
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      postTimeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'postTime',
        value: value,
      ));
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      postTimeGreaterThan(
    DateTime? value, {
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

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      postTimeLessThan(
    DateTime? value, {
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

  QueryBuilder<ReferenceData, ReferenceData, QAfterFilterCondition>
      postTimeBetween(
    DateTime? lower,
    DateTime? upper, {
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
}

extension ReferenceDataQueryObject
    on QueryBuilder<ReferenceData, ReferenceData, QFilterCondition> {}

extension ReferenceDataQueryLinks
    on QueryBuilder<ReferenceData, ReferenceData, QFilterCondition> {}

extension ReferenceDataQuerySortBy
    on QueryBuilder<ReferenceData, ReferenceData, QSortBy> {
  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      sortByAccuratePage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuratePage', Sort.asc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      sortByAccuratePageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuratePage', Sort.desc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy> sortByFuzzyPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuzzyPage', Sort.asc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      sortByFuzzyPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuzzyPage', Sort.desc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy> sortByMainPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainPostId', Sort.asc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      sortByMainPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainPostId', Sort.desc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy> sortByPostTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.asc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      sortByPostTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.desc);
    });
  }
}

extension ReferenceDataQuerySortThenBy
    on QueryBuilder<ReferenceData, ReferenceData, QSortThenBy> {
  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      thenByAccuratePage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuratePage', Sort.asc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      thenByAccuratePageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accuratePage', Sort.desc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy> thenByFuzzyPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuzzyPage', Sort.asc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      thenByFuzzyPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fuzzyPage', Sort.desc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy> thenByMainPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainPostId', Sort.asc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      thenByMainPostIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mainPostId', Sort.desc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy> thenByPostTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.asc);
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QAfterSortBy>
      thenByPostTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.desc);
    });
  }
}

extension ReferenceDataQueryWhereDistinct
    on QueryBuilder<ReferenceData, ReferenceData, QDistinct> {
  QueryBuilder<ReferenceData, ReferenceData, QDistinct>
      distinctByAccuratePage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accuratePage');
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QDistinct> distinctByFuzzyPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fuzzyPage');
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QDistinct> distinctByMainPostId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mainPostId');
    });
  }

  QueryBuilder<ReferenceData, ReferenceData, QDistinct> distinctByPostTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postTime');
    });
  }
}

extension ReferenceDataQueryProperty
    on QueryBuilder<ReferenceData, ReferenceData, QQueryProperty> {
  QueryBuilder<ReferenceData, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReferenceData, int?, QQueryOperations> accuratePageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accuratePage');
    });
  }

  QueryBuilder<ReferenceData, int?, QQueryOperations> fuzzyPageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fuzzyPage');
    });
  }

  QueryBuilder<ReferenceData, int?, QQueryOperations> mainPostIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mainPostId');
    });
  }

  QueryBuilder<ReferenceData, DateTime?, QQueryOperations> postTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postTime');
    });
  }
}
