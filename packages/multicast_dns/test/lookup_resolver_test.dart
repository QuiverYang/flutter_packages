// Copyright (c) 2015, the Dartino project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:multicast_dns/src/lookup_resolver.dart';
import 'package:multicast_dns/src/resource_record.dart';

void main() {
  testTimeout();
  testResult();
  testResult2();
  testResult3();
}

ResourceRecord ip4Result(String name, InternetAddress address) {
  final int validUntil = DateTime.now().millisecondsSinceEpoch + 2000;
  return IPAddressResourceRecord(name, validUntil, address: address);
}

void testTimeout() {
  test('Resolver does not return with short timeout', () async {
    const Duration shortTimeout = Duration(milliseconds: 1);
    final LookupResolver resolver = LookupResolver();
    final Stream<ResourceRecord> result =
        resolver.addPendingRequest(ResourceRecordType.a, 'xxx', shortTimeout);
    expect(await result.isEmpty, isTrue);
  });
}

// One pending request and one response.
void testResult() {
  test('One pending request and one response', () async {
    const Duration noTimeout = Duration(days: 1);
    final LookupResolver resolver = LookupResolver();
    final Stream<ResourceRecord> futureResult = resolver.addPendingRequest(
        ResourceRecordType.a, 'xxx.local', noTimeout);
    final ResourceRecord response =
        ip4Result('xxx.local', InternetAddress('1.2.3.4'));
    resolver.handleResponse(<ResourceRecord>[response]);
    final IPAddressResourceRecord result = await futureResult.first;
    expect('1.2.3.4', result.address.address);
    resolver.clearPendingRequests();
  });
}

void testResult2() {
  test('Two requests', () async {
    const Duration noTimeout = Duration(days: 1);
    final LookupResolver resolver = LookupResolver();
    final Stream<ResourceRecord> futureResult1 = resolver.addPendingRequest(
        ResourceRecordType.a, 'xxx.local', noTimeout);
    final Stream<ResourceRecord> futureResult2 = resolver.addPendingRequest(
        ResourceRecordType.a, 'yyy.local', noTimeout);
    final ResourceRecord response1 =
        ip4Result('xxx.local', InternetAddress('1.2.3.4'));
    final ResourceRecord response2 =
        ip4Result('yyy.local', InternetAddress('2.3.4.5'));
    resolver.handleResponse(<ResourceRecord>[response2, response1]);
    final IPAddressResourceRecord result1 = await futureResult1.first;
    final IPAddressResourceRecord result2 = await futureResult2.first;
    expect('1.2.3.4', result1.address.address);
    expect('2.3.4.5', result2.address.address);
    resolver.clearPendingRequests();
  });
}

void testResult3() {
  test('Multiple requests', () async {
    const Duration noTimeout = Duration(days: 1);
    final LookupResolver resolver = LookupResolver();
    final ResourceRecord response0 =
        ip4Result('zzz.local', InternetAddress('2.3.4.5'));
    resolver.handleResponse(<ResourceRecord>[response0]);
    final Stream<ResourceRecord> futureResult1 = resolver.addPendingRequest(
        ResourceRecordType.a, 'xxx.local', noTimeout);
    resolver.handleResponse(<ResourceRecord>[response0]);
    final Stream<ResourceRecord> futureResult2 = resolver.addPendingRequest(
        ResourceRecordType.a, 'yyy.local', noTimeout);
    resolver.handleResponse(<ResourceRecord>[response0]);
    final ResourceRecord response1 =
        ip4Result('xxx.local', InternetAddress('1.2.3.4'));
    resolver.handleResponse(<ResourceRecord>[response0]);
    final ResourceRecord response2 =
        ip4Result('yyy.local', InternetAddress('2.3.4.5'));
    resolver.handleResponse(<ResourceRecord>[response0]);
    resolver.handleResponse(<ResourceRecord>[response2, response1]);
    resolver.handleResponse(<ResourceRecord>[response0]);
    final IPAddressResourceRecord result1 = await futureResult1.first;
    final IPAddressResourceRecord result2 = await futureResult2.first;
    expect('1.2.3.4', result1.address.address);
    expect('2.3.4.5', result2.address.address);
    resolver.clearPendingRequests();
  });
}
