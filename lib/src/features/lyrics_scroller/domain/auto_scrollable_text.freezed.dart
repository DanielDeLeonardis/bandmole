// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auto_scrollable_text.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AutoScrollableText {

 bool get isScrolling; bool get isAtEnd; bool get isAtStart; int get scrollSpeed; double get textFontSize; ScrollCommand? get pendingCommand;
/// Create a copy of AutoScrollableText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutoScrollableTextCopyWith<AutoScrollableText> get copyWith => _$AutoScrollableTextCopyWithImpl<AutoScrollableText>(this as AutoScrollableText, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutoScrollableText&&(identical(other.isScrolling, isScrolling) || other.isScrolling == isScrolling)&&(identical(other.isAtEnd, isAtEnd) || other.isAtEnd == isAtEnd)&&(identical(other.isAtStart, isAtStart) || other.isAtStart == isAtStart)&&(identical(other.scrollSpeed, scrollSpeed) || other.scrollSpeed == scrollSpeed)&&(identical(other.textFontSize, textFontSize) || other.textFontSize == textFontSize)&&(identical(other.pendingCommand, pendingCommand) || other.pendingCommand == pendingCommand));
}


@override
int get hashCode => Object.hash(runtimeType,isScrolling,isAtEnd,isAtStart,scrollSpeed,textFontSize,pendingCommand);

@override
String toString() {
  return 'AutoScrollableText(isScrolling: $isScrolling, isAtEnd: $isAtEnd, isAtStart: $isAtStart, scrollSpeed: $scrollSpeed, textFontSize: $textFontSize, pendingCommand: $pendingCommand)';
}


}

/// @nodoc
abstract mixin class $AutoScrollableTextCopyWith<$Res>  {
  factory $AutoScrollableTextCopyWith(AutoScrollableText value, $Res Function(AutoScrollableText) _then) = _$AutoScrollableTextCopyWithImpl;
@useResult
$Res call({
 bool isScrolling, bool isAtEnd, bool isAtStart, int scrollSpeed, double textFontSize, ScrollCommand? pendingCommand
});




}
/// @nodoc
class _$AutoScrollableTextCopyWithImpl<$Res>
    implements $AutoScrollableTextCopyWith<$Res> {
  _$AutoScrollableTextCopyWithImpl(this._self, this._then);

  final AutoScrollableText _self;
  final $Res Function(AutoScrollableText) _then;

/// Create a copy of AutoScrollableText
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isScrolling = null,Object? isAtEnd = null,Object? isAtStart = null,Object? scrollSpeed = null,Object? textFontSize = null,Object? pendingCommand = freezed,}) {
  return _then(AutoScrollableText(
isScrolling: null == isScrolling ? _self.isScrolling : isScrolling // ignore: cast_nullable_to_non_nullable
as bool,isAtEnd: null == isAtEnd ? _self.isAtEnd : isAtEnd // ignore: cast_nullable_to_non_nullable
as bool,isAtStart: null == isAtStart ? _self.isAtStart : isAtStart // ignore: cast_nullable_to_non_nullable
as bool,scrollSpeed: null == scrollSpeed ? _self.scrollSpeed : scrollSpeed // ignore: cast_nullable_to_non_nullable
as int,textFontSize: null == textFontSize ? _self.textFontSize : textFontSize // ignore: cast_nullable_to_non_nullable
as double,pendingCommand: freezed == pendingCommand ? _self.pendingCommand : pendingCommand // ignore: cast_nullable_to_non_nullable
as ScrollCommand?,
  ));
}

}


/// Adds pattern-matching-related methods to [AutoScrollableText].
extension AutoScrollableTextPatterns on AutoScrollableText {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutoScrollableText value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutoScrollableText() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutoScrollableText value)  $default,){
final _that = this;
switch (_that) {
case _AutoScrollableText():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutoScrollableText value)?  $default,){
final _that = this;
switch (_that) {
case _AutoScrollableText() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isScrolling,  bool isAtEnd,  bool isAtStart,  int scrollSpeed,  double textFontSize,  ScrollCommand? pendingCommand)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutoScrollableText() when $default != null:
return $default(_that.isScrolling,_that.isAtEnd,_that.isAtStart,_that.scrollSpeed,_that.textFontSize,_that.pendingCommand);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isScrolling,  bool isAtEnd,  bool isAtStart,  int scrollSpeed,  double textFontSize,  ScrollCommand? pendingCommand)  $default,) {final _that = this;
switch (_that) {
case _AutoScrollableText():
return $default(_that.isScrolling,_that.isAtEnd,_that.isAtStart,_that.scrollSpeed,_that.textFontSize,_that.pendingCommand);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isScrolling,  bool isAtEnd,  bool isAtStart,  int scrollSpeed,  double textFontSize,  ScrollCommand? pendingCommand)?  $default,) {final _that = this;
switch (_that) {
case _AutoScrollableText() when $default != null:
return $default(_that.isScrolling,_that.isAtEnd,_that.isAtStart,_that.scrollSpeed,_that.textFontSize,_that.pendingCommand);case _:
  return null;

}
}

}

/// @nodoc


class _AutoScrollableText implements AutoScrollableText {
  const _AutoScrollableText({required this.isScrolling, required this.isAtEnd, required this.isAtStart, required this.scrollSpeed, required this.textFontSize, this.pendingCommand = null});
  

@override final  bool isScrolling;
@override final  bool isAtEnd;
@override final  bool isAtStart;
@override final  int scrollSpeed;
@override final  double textFontSize;
@override@JsonKey() final  ScrollCommand? pendingCommand;

/// Create a copy of AutoScrollableText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutoScrollableTextCopyWith<_AutoScrollableText> get copyWith => __$AutoScrollableTextCopyWithImpl<_AutoScrollableText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutoScrollableText&&(identical(other.isScrolling, isScrolling) || other.isScrolling == isScrolling)&&(identical(other.isAtEnd, isAtEnd) || other.isAtEnd == isAtEnd)&&(identical(other.isAtStart, isAtStart) || other.isAtStart == isAtStart)&&(identical(other.scrollSpeed, scrollSpeed) || other.scrollSpeed == scrollSpeed)&&(identical(other.textFontSize, textFontSize) || other.textFontSize == textFontSize)&&(identical(other.pendingCommand, pendingCommand) || other.pendingCommand == pendingCommand));
}


@override
int get hashCode => Object.hash(runtimeType,isScrolling,isAtEnd,isAtStart,scrollSpeed,textFontSize,pendingCommand);

@override
String toString() {
  return 'AutoScrollableText(isScrolling: $isScrolling, isAtEnd: $isAtEnd, isAtStart: $isAtStart, scrollSpeed: $scrollSpeed, textFontSize: $textFontSize, pendingCommand: $pendingCommand)';
}


}

/// @nodoc
abstract mixin class _$AutoScrollableTextCopyWith<$Res> implements $AutoScrollableTextCopyWith<$Res> {
  factory _$AutoScrollableTextCopyWith(_AutoScrollableText value, $Res Function(_AutoScrollableText) _then) = __$AutoScrollableTextCopyWithImpl;
@override @useResult
$Res call({
 bool isScrolling, bool isAtEnd, bool isAtStart, int scrollSpeed, double textFontSize, ScrollCommand? pendingCommand
});




}
/// @nodoc
class __$AutoScrollableTextCopyWithImpl<$Res>
    implements _$AutoScrollableTextCopyWith<$Res> {
  __$AutoScrollableTextCopyWithImpl(this._self, this._then);

  final _AutoScrollableText _self;
  final $Res Function(_AutoScrollableText) _then;

/// Create a copy of AutoScrollableText
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isScrolling = null,Object? isAtEnd = null,Object? isAtStart = null,Object? scrollSpeed = null,Object? textFontSize = null,Object? pendingCommand = freezed,}) {
  return _then(_AutoScrollableText(
isScrolling: null == isScrolling ? _self.isScrolling : isScrolling // ignore: cast_nullable_to_non_nullable
as bool,isAtEnd: null == isAtEnd ? _self.isAtEnd : isAtEnd // ignore: cast_nullable_to_non_nullable
as bool,isAtStart: null == isAtStart ? _self.isAtStart : isAtStart // ignore: cast_nullable_to_non_nullable
as bool,scrollSpeed: null == scrollSpeed ? _self.scrollSpeed : scrollSpeed // ignore: cast_nullable_to_non_nullable
as int,textFontSize: null == textFontSize ? _self.textFontSize : textFontSize // ignore: cast_nullable_to_non_nullable
as double,pendingCommand: freezed == pendingCommand ? _self.pendingCommand : pendingCommand // ignore: cast_nullable_to_non_nullable
as ScrollCommand?,
  ));
}


}

// dart format on
