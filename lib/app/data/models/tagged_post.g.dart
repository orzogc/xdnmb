// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tagged_post.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetTaggedPostCollection on Isar {
  IsarCollection<TaggedPost> get taggedPosts => this.collection();
}

const TaggedPostSchema = CollectionSchema(
  name: r'TaggedPost',
  id: 1218952108238509051,
  properties: {
    r'content': PropertySchema(
      id: 0,
      name: r'content',
      type: IsarType.string,
    ),
    r'forumId': PropertySchema(
      id: 1,
      name: r'forumId',
      type: IsarType.long,
    ),
    r'hasImage': PropertySchema(
      id: 2,
      name: r'hasImage',
      type: IsarType.bool,
    ),
    r'hashCode': PropertySchema(
      id: 3,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'isAdmin': PropertySchema(
      id: 4,
      name: r'isAdmin',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'postTime': PropertySchema(
      id: 6,
      name: r'postTime',
      type: IsarType.dateTime,
    ),
    r'taggedTime': PropertySchema(
      id: 7,
      name: r'taggedTime',
      type: IsarType.dateTime,
    ),
    r'tags': PropertySchema(
      id: 8,
      name: r'tags',
      type: IsarType.longList,
    ),
    r'title': PropertySchema(
      id: 9,
      name: r'title',
      type: IsarType.string,
    ),
    r'userHash': PropertySchema(
      id: 10,
      name: r'userHash',
      type: IsarType.string,
    )
  },
  estimateSize: _taggedPostEstimateSize,
  serialize: _taggedPostSerialize,
  deserialize: _taggedPostDeserialize,
  deserializeProp: _taggedPostDeserializeProp,
  idName: r'id',
  indexes: {
    r'taggedTime': IndexSchema(
      id: 6401288868361657321,
      name: r'taggedTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'taggedTime',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'tags': IndexSchema(
      id: 4029205728550669204,
      name: r'tags',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'tags',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _taggedPostGetId,
  getLinks: _taggedPostGetLinks,
  attach: _taggedPostAttach,
  version: '3.0.5',
);

int _taggedPostEstimateSize(
  TaggedPost object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.tags.length * 8;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.userHash.length * 3;
  return bytesCount;
}

void _taggedPostSerialize(
  TaggedPost object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.content);
  writer.writeLong(offsets[1], object.forumId);
  writer.writeBool(offsets[2], object.hasImage);
  writer.writeLong(offsets[3], object.hashCode);
  writer.writeBool(offsets[4], object.isAdmin);
  writer.writeString(offsets[5], object.name);
  writer.writeDateTime(offsets[6], object.postTime);
  writer.writeDateTime(offsets[7], object.taggedTime);
  writer.writeLongList(offsets[8], object.tags);
  writer.writeString(offsets[9], object.title);
  writer.writeString(offsets[10], object.userHash);
}

TaggedPost _taggedPostDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TaggedPost(
    content: reader.readString(offsets[0]),
    forumId: reader.readLongOrNull(offsets[1]),
    hasImage: reader.readBool(offsets[2]),
    id: id,
    isAdmin: reader.readBool(offsets[4]),
    name: reader.readString(offsets[5]),
    postTime: reader.readDateTime(offsets[6]),
    taggedTime: reader.readDateTime(offsets[7]),
    tags: reader.readLongList(offsets[8]) ?? [],
    title: reader.readString(offsets[9]),
    userHash: reader.readString(offsets[10]),
  );
  return object;
}

P _taggedPostDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readLongList(offset) ?? []) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _taggedPostGetId(TaggedPost object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _taggedPostGetLinks(TaggedPost object) {
  return [];
}

void _taggedPostAttach(IsarCollection<dynamic> col, Id id, TaggedPost object) {}

extension TaggedPostQueryWhereSort
    on QueryBuilder<TaggedPost, TaggedPost, QWhere> {
  QueryBuilder<TaggedPost, TaggedPost, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhere> anyTaggedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'taggedTime'),
      );
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhere> anyTagsElement() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'tags'),
      );
    });
  }
}

extension TaggedPostQueryWhere
    on QueryBuilder<TaggedPost, TaggedPost, QWhereClause> {
  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> idBetween(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> taggedTimeEqualTo(
      DateTime taggedTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'taggedTime',
        value: [taggedTime],
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> taggedTimeNotEqualTo(
      DateTime taggedTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taggedTime',
              lower: [],
              upper: [taggedTime],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taggedTime',
              lower: [taggedTime],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taggedTime',
              lower: [taggedTime],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taggedTime',
              lower: [],
              upper: [taggedTime],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> taggedTimeGreaterThan(
    DateTime taggedTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'taggedTime',
        lower: [taggedTime],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> taggedTimeLessThan(
    DateTime taggedTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'taggedTime',
        lower: [],
        upper: [taggedTime],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> taggedTimeBetween(
    DateTime lowerTaggedTime,
    DateTime upperTaggedTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'taggedTime',
        lower: [lowerTaggedTime],
        includeLower: includeLower,
        upper: [upperTaggedTime],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> tagsElementEqualTo(
      int tagsElement) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'tags',
        value: [tagsElement],
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> tagsElementNotEqualTo(
      int tagsElement) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tags',
              lower: [],
              upper: [tagsElement],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tags',
              lower: [tagsElement],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tags',
              lower: [tagsElement],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tags',
              lower: [],
              upper: [tagsElement],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause>
      tagsElementGreaterThan(
    int tagsElement, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tags',
        lower: [tagsElement],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> tagsElementLessThan(
    int tagsElement, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tags',
        lower: [],
        upper: [tagsElement],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterWhereClause> tagsElementBetween(
    int lowerTagsElement,
    int upperTagsElement, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tags',
        lower: [lowerTagsElement],
        includeLower: includeLower,
        upper: [upperTagsElement],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TaggedPostQueryFilter
    on QueryBuilder<TaggedPost, TaggedPost, QFilterCondition> {
  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> contentEqualTo(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> contentLessThan(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> contentBetween(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> contentStartsWith(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> contentEndsWith(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> contentContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> contentMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> forumIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'forumId',
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      forumIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'forumId',
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> forumIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'forumId',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      forumIdGreaterThan(
    int? value, {
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> forumIdLessThan(
    int? value, {
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> forumIdBetween(
    int? lower,
    int? upper, {
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> hasImageEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasImage',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> hashCodeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> idBetween(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> isAdminEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAdmin',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> postTimeEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'postTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> postTimeLessThan(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> postTimeBetween(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> taggedTimeEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taggedTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      taggedTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taggedTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      taggedTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taggedTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> taggedTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taggedTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      tagsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      tagsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      tagsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      tagsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> tagsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> titleEqualTo(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> titleGreaterThan(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> titleLessThan(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> titleBetween(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> titleStartsWith(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> titleEndsWith(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> userHashEqualTo(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> userHashLessThan(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> userHashBetween(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> userHashEndsWith(
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

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> userHashContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition> userHashMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      userHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userHash',
        value: '',
      ));
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterFilterCondition>
      userHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userHash',
        value: '',
      ));
    });
  }
}

extension TaggedPostQueryObject
    on QueryBuilder<TaggedPost, TaggedPost, QFilterCondition> {}

extension TaggedPostQueryLinks
    on QueryBuilder<TaggedPost, TaggedPost, QFilterCondition> {}

extension TaggedPostQuerySortBy
    on QueryBuilder<TaggedPost, TaggedPost, QSortBy> {
  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByForumId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'forumId', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByForumIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'forumId', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByHasImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasImage', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByHasImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasImage', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByIsAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdmin', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByIsAdminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdmin', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByPostTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByPostTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByTaggedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taggedTime', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByTaggedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taggedTime', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByUserHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userHash', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> sortByUserHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userHash', Sort.desc);
    });
  }
}

extension TaggedPostQuerySortThenBy
    on QueryBuilder<TaggedPost, TaggedPost, QSortThenBy> {
  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByForumId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'forumId', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByForumIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'forumId', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByHasImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasImage', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByHasImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasImage', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByIsAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdmin', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByIsAdminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdmin', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByPostTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByPostTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'postTime', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByTaggedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taggedTime', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByTaggedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taggedTime', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByUserHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userHash', Sort.asc);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QAfterSortBy> thenByUserHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userHash', Sort.desc);
    });
  }
}

extension TaggedPostQueryWhereDistinct
    on QueryBuilder<TaggedPost, TaggedPost, QDistinct> {
  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByForumId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'forumId');
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByHasImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasImage');
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByIsAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAdmin');
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByPostTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'postTime');
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByTaggedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taggedTime');
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TaggedPost, TaggedPost, QDistinct> distinctByUserHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userHash', caseSensitive: caseSensitive);
    });
  }
}

extension TaggedPostQueryProperty
    on QueryBuilder<TaggedPost, TaggedPost, QQueryProperty> {
  QueryBuilder<TaggedPost, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TaggedPost, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<TaggedPost, int?, QQueryOperations> forumIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'forumId');
    });
  }

  QueryBuilder<TaggedPost, bool, QQueryOperations> hasImageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasImage');
    });
  }

  QueryBuilder<TaggedPost, int, QQueryOperations> hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<TaggedPost, bool, QQueryOperations> isAdminProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAdmin');
    });
  }

  QueryBuilder<TaggedPost, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<TaggedPost, DateTime, QQueryOperations> postTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'postTime');
    });
  }

  QueryBuilder<TaggedPost, DateTime, QQueryOperations> taggedTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taggedTime');
    });
  }

  QueryBuilder<TaggedPost, List<int>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<TaggedPost, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<TaggedPost, String, QQueryOperations> userHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userHash');
    });
  }
}
