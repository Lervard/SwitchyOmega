part of switchy_profile;

/*!
 * Copyright (C) 2012, The SwitchyOmega Authors. Please see the AUTHORS file
 * for details.
 *
 * This file is part of SwitchyOmega.
 *
 * SwitchyOmega is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SwitchyOmega is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SwitchyOmega.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * Selects the result profile of the first matching [Rule],
 * or the [defaultProfile] if no rule matches.
 */
class SwitchProfile extends InclusiveProfile implements List<Rule> {
  String get profileType => 'SwitchProfile';

  List<Rule> _rules;

  Map<String, int> _refCount;

  void _addReference(String name) {
    _refCount[name] = ifNull(_refCount[name], 0) + 1;
  }

  void _removeReference(String name) {
    var c = _refCount[name];
    if (c == null) return;
    if (c > 1) {
      _refCount[name] = c - 1;
    } else {
      _refCount.remove(name);
    }
  }

  void _flushReference() {
    _refCount.clear();
    _addReference(_defaultProfileName);
    this._rules.forEach((rule) => _addReference(rule.profileName));
  }

  String _defaultProfileName;
  String get defaultProfileName => _defaultProfileName;
  void set defaultProfile(String value) {
    _refCount.remove(_defaultProfileName);
    _addReference(value);
    _defaultProfileName = value;
  }

  bool containsProfileName(String name) {
    return _refCount.containsKey(name);
  }

  List<String> getProfileNames() {
    return _refCount.keys.toList();
  }

  void writeTo(CodeWriter w) {
    w.code('function (url, host, scheme) {');
    w.code("'use strict';");

    for (var rule in _rules) {
      w.inline('if (');
      rule.condition.writeTo(w);
      w.code(')').indent();
      var ip = getProfileByName(rule.profileName);
      w.code('return ${ip.getScriptName()};')
       .outdent();
    }

    var dp = getProfileByName(defaultProfileName);
    w.code('return ${dp.getScriptName()};');
    w.inline('}');
  }

  String choose(String url, String host, String scheme, Date datetime) {
    for (var rule in _rules) {
      if (rule.condition.match(url, host, scheme, datetime)) {
        return rule.profileName;
      }
    }
    return defaultProfileName;
  }

  Map<String, Object> toPlain([Map<String, Object> p]) {
    p = super.toPlain(p);
    p['defaultProfileName'] = defaultProfileName;
    p['rules'] = this.mappedBy((r) => r.toPlain()).toList();

    return p;
  }

  SwitchProfile(String name, String defaultProfileName, ProfileResolver resolver)
      : super(name, resolver) {
    this._refCount = new Map<String, int>();
    this._defaultProfileName = defaultProfileName;
    _addReference(_defaultProfileName);
    this._rules = <Rule>[];
  }

  void loadPlain(Map<String, Object> p) {
    super.loadPlain(p);
    var rl = p['rules'] as List<Map<String, Object>>;
    this.addAll(rl.mappedBy((r) => new Rule.fromPlain(r)));
  }

  factory SwitchProfile.fromPlain(Map<String, Object> p) {
    var f = new SwitchProfile(p['name'], p['defaultProfileName'], p['resolver']);
    f.loadPlain(p);
    return f;
  }

  int get length => _rules.length;

  void set length(int newLength) {
    this._rules.length = newLength;
  }

  void remove(Rule rule) {
    int old_length = this._rules.length;
    this._rules.remove(rule);
    if (this._rules.length < old_length) {
      _removeReference(rule.profileName);
    }
  }

  Iterator<Rule> get iterator => this._rules.iterator;

  List<Rule> toList() => this._rules.toList();

  Set<Rule> toSet() => this._rules.toSet();

  Rule operator [](int i) => this._rules[i];

  void operator []=(int i, Rule rule) {
    _removeReference(this[i].profileName);
    this._rules[i] = rule;
    _addReference(rule.profileName);
  }

  void add(Rule rule) {
    this._rules.add(rule);
    _addReference(rule.profileName);
  }

  void addLast(Rule rule) {
    this._rules.addLast(rule);
    _addReference(rule.profileName);
  }

  void addAll(Iterable<Rule> rules) {
    this._rules.addAll(rules);
    rules.forEach((r) => _addReference(r.profileName));
  }

  int indexOf(Rule rule, [int start = 0]) => this._rules.indexOf(rule, start);

  int lastIndexOf(Rule rule, [int start]) =>
      this._rules.lastIndexOf(rule, start);

  void clear() {
    this._rules.clear();
    _flushReference();
  }

  Rule removeAt(int i) {
    var rule = this._rules.removeAt(i);
    if (rule != null) _removeReference(rule.profileName);
    return rule;
  }

  Rule removeLast() {
    var rule = this._rules.removeLast();
    if (rule != null) _removeReference(rule.profileName);
    return rule;
  }

  List<Rule> getRange(int start, int length) {
    return this._rules.getRange(start, length);
  }

  void setRange(int start, int length, List<Rule> from, [int startFrom]) {
    for (var i = start; i < start + length; i++) {
      _removeReference(this._rules[i].profileName);
    }
    this._rules.setRange(start, length, from, startFrom);
    for (var i = start; i < start + length; i++) {
      _addReference(this._rules[i].profileName);
    }
  }

  void removeRange(int start, int length) {
    for (var i = start; i < start + length; i++) {
      _removeReference(this._rules[i].profileName);
    }
    this._rules.removeRange(start, length);
  }

  void insertRange(int start, int length, [Rule fill]) {
    if (fill != null) {
      for (var i = 0; i < length; i++) {
        _addReference(fill.profileName);
      }
    }
    this._rules.insertRange(start, length, fill);
  }

  void removeAll(Iterable<Rule> elementsToRemove) {
    this._rules.removeAll(elementsToRemove);
    _flushReference();
  }

  bool contains(Rule rule) {
    return this._rules.contains(rule);
  }

  bool get isEmpty => this.length > 0;

  Rule get first => this._rules.first;

  Rule get last => this._rules.last;

  Rule elementAt(int index) => this[index];

  // Implementation using IterableMixinWorkaround:

  void forEach(void f(Rule o)) => IterableMixinWorkaround.forEach(this, f);

  bool any(bool f(Rule o)) => IterableMixinWorkaround.any(this, f);

  bool every(bool f(Rule o)) => IterableMixinWorkaround.every(this, f);

  dynamic reduce(initialValue, combine(previousValue, Rule element)) =>
    IterableMixinWorkaround.reduce(this, initialValue, combine);

  void retainAll(Iterable<Rule> elementsToRetain) {
    IterableMixinWorkaround.retainAll(this, elementsToRetain);
  }

  void removeMatching(bool test(Rule element)) {
    IterableMixinWorkaround.removeMatching(this, test);
  }

  void retainMatching(bool test(Rule element)) {
    IterableMixinWorkaround.retainMatching(this, test);
  }

  Rule min([int compare(Rule a, Rule b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Rule max([int compare(Rule a, Rule b)]) =>
      IterableMixinWorkaround.max(this, compare);

  Rule get single => IterableMixinWorkaround.single(this);

  Rule firstMatching(bool test(Rule value), {orElse()}) =>
      IterableMixinWorkaround.firstMatching(this, test, orElse);

  Rule lastMatching(bool test(Rule value), {orElse()}) =>
      IterableMixinWorkaround.lastMatchingInList(this, test, orElse);

  Rule singleMatching(bool test(Rule value)) =>
      IterableMixinWorkaround.singleMatching(this, test);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable<Rule> where(bool f(Rule element)) =>
      IterableMixinWorkaround.where(this, f);

  List mappedBy(f(Rule element)) =>
      IterableMixinWorkaround.mappedByList(this, f);

  List<Rule> take(int n) =>
      IterableMixinWorkaround.takeList(this, n);

  Iterable takeWhile(bool test(Rule value)) =>
      IterableMixinWorkaround.takeWhile(this, test);

  List<Rule> skip(int n) =>
      IterableMixinWorkaround.skipList(this, n);

  Iterable<Rule> skipWhile(bool test(value)) =>
      IterableMixinWorkaround.skipWhile(this, test);

  void sort([int compare(Rule a, Rule b)]) {
    IterableMixinWorkaround.sortList(this, compare);
  }
}