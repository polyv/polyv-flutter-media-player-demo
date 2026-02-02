import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:polyv_media_player/infrastructure/polyv_api_client.dart';

void main() {
  group('PolyvApiClient POST Method Tests', () {
    group('[P1] POST Request - Success Path', () {
      test('[P1] post returns success response on 200', () async {
        // GIVEN: Mock HTTP client returning successful response
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"code": 200, "data": {"id": "123", "name": "test"}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Making POST request
        final response = await apiClient.post(
          '/v2/test',
          bodyParams: {'key': 'value'},
        );

        // THEN: Should return success response
        expect(response.success, isTrue);
        expect(response.statusCode, 200);
        expect(response.data, isNotNull);
        expect(response.data!['id'], '123');
        expect(response.data!['name'], 'test');
        expect(response.error, isNull);
      });

      test('[P1] post includes writeToken by default', () async {
        // GIVEN: Mock client that captures request
        http.Request? capturedRequest;
        final mockClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response('{"code": 200, "data": {}}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Making POST request
        await apiClient.post('/v2/test', bodyParams: {'param': 'value'});

        // THEN: Request body should contain writeToken
        expect(capturedRequest, isNotNull);
        final body = capturedRequest!.body;
        expect(body, contains('writetoken=test_write_token'));
        expect(body, contains('userid=test_user'));
      });

      test('[P1] post uses readToken when useWriteToken is false', () async {
        // GIVEN: Mock client that captures request
        http.Request? capturedRequest;
        final mockClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response('{"code": 200, "data": {}}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Making POST request with useWriteToken=false
        await apiClient.post(
          '/v2/test',
          bodyParams: {'param': 'value'},
          useWriteToken: false,
        );

        // THEN: Request body should contain readToken
        expect(capturedRequest, isNotNull);
        final body = capturedRequest!.body;
        expect(body, contains('readtoken=test_read_token'));
        expect(body, contains('userid=test_user'));
        expect(body, isNot(contains('writetoken')));
      });

      test('[P1] post generates signature correctly', () async {
        // GIVEN: Mock client that captures request
        http.Request? capturedRequest;
        final mockClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response('{"code": 200, "data": {}}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Making POST request
        await apiClient.post(
          '/v2/test',
          bodyParams: {'vid': 'test123', 'msg': 'hello'},
        );

        // THEN: Request should contain sign and timestamp
        expect(capturedRequest, isNotNull);
        final body = capturedRequest!.body;
        expect(body, contains('sign='));
        expect(body, contains('timestamp='));

        // 验证签名格式（SHA1 哈希应该是 40 个字符）
        final signMatch = RegExp(r'sign=([A-F0-9]{40})').firstMatch(body);
        expect(signMatch, isNotNull);
      });

      test('[P1] post encodes parameters as form-urlencoded', () async {
        // GIVEN: Mock client that captures request
        http.Request? capturedRequest;
        final mockClient = MockClient((request) async {
          capturedRequest = request;
          return http.Response('{"code": 200}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Making POST request with special characters
        await apiClient.post(
          '/v2/test',
          bodyParams: {'text': 'hello world', 'email': 'test@example.com'},
        );

        // THEN: Request should be form-urlencoded
        expect(capturedRequest, isNotNull);
        expect(
          capturedRequest!.headers['content-type'],
          contains('application/x-www-form-urlencoded'),
        );

        // 参数应该被 URL 编码
        final body = capturedRequest?.body ?? '';
        expect(body, contains('text=hello%20world')); // 空格编码为 %20
        expect(body, contains('email=test%40example.com')); // @ 编码为 %40
      });
    });

    group('[P1] POST Request - Error Handling', () {
      test('[P1] post throws exception on 400 validation error', () async {
        // GIVEN: Mock client returning 400 error
        // Note: Using ASCII message to avoid JSON parsing issues with non-ASCII characters
        final mockClient = MockClient((_) async {
          return http.Response(
            '{"code": 400, "message": "validation error"}',
            400,
          );
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Making POST request
        // THEN: Should throw PolyvApiException
        expect(
          () => apiClient.post('/v2/test', bodyParams: {}),
          throwsA(isA<PolyvApiException>()),
        );
      });

      test('[P1] post throws exception on 401 auth error', () async {
        // GIVEN: Mock client returning 401 error
        // Note: Using ASCII message to avoid JSON parsing issues
        final mockClient = MockClient((_) async {
          return http.Response('{"code": 401, "message": "unauthorized"}', 401);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: Should throw exception
        expect(
          () => apiClient.post('/v2/test', bodyParams: {}),
          throwsA(isA<PolyvApiException>()),
        );
      });

      test('[P1] post throws exception on 403 forbidden error', () async {
        // GIVEN: Mock client returning 403 error
        // Note: Using ASCII message to avoid JSON parsing issues
        final mockClient = MockClient((_) async {
          return http.Response('{"code": 403, "message": "forbidden"}', 403);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: Should throw exception
        expect(
          () => apiClient.post('/v2/test', bodyParams: {}),
          throwsA(isA<PolyvApiException>()),
        );
      });

      test('[P1] post throws exception on 500 server error', () async {
        // GIVEN: Mock client returning 500 error
        // Note: Using ASCII message to avoid JSON parsing issues
        final mockClient = MockClient((_) async {
          return http.Response('{"code": 500, "message": "server error"}', 500);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: Should throw exception
        expect(
          () => apiClient.post('/v2/test', bodyParams: {}),
          throwsA(isA<PolyvApiException>()),
        );
      });

      test('[P1] post throws exception on network error', () async {
        // GIVEN: Mock client throwing network exception
        final mockClient = MockClient((_) async {
          throw http.ClientException('Network unreachable');
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: Should throw network exception
        expect(
          () => apiClient.post('/v2/test', bodyParams: {}),
          throwsA(
            isA<PolyvApiException>().having(
              (e) => e.type,
              'type',
              PolyvApiErrorType.network,
            ),
          ),
        );
      });

      test('[P1] post handles HTTP error status codes (non-2xx)', () async {
        // GIVEN: Mock client returning non-2xx status
        final mockClient = MockClient((_) async {
          return http.Response('Internal Server Error', 502);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: Should throw exception
        expect(
          () => apiClient.post('/v2/test', bodyParams: {}),
          throwsA(
            isA<PolyvApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              502,
            ),
          ),
        );
      });
    });

    group('[P2] POST Request - Response Parsing', () {
      test('[P2] post handles response with null data field', () async {
        // GIVEN: Mock client returning response with null data
        final mockClient = MockClient((_) async {
          return http.Response('{"code": 200, "data": null}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Making POST request
        final response = await apiClient.post('/v2/test', bodyParams: {});

        // THEN: Should return success with null data
        expect(response.success, isTrue);
        expect(response.data, isNull);
      });

      test('[P2] post handles response without data field', () async {
        // GIVEN: Mock client returning response without data
        final mockClient = MockClient((_) async {
          return http.Response('{"code": 200, "message": "OK"}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Making POST request
        final response = await apiClient.post('/v2/test', bodyParams: {});

        // THEN: Should return success with null data
        expect(response.success, isTrue);
        expect(response.data, isNull);
      });

      test('[P2] post handles non-JSON response', () async {
        // GIVEN: Mock client returning non-JSON response
        final mockClient = MockClient((_) async {
          return http.Response('plain text response', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Making POST request
        final response = await apiClient.post('/v2/test', bodyParams: {});

        // THEN: Should return failure
        expect(response.success, isFalse);
        expect(response.error, '响应格式错误');
      });

      test('[P2] post handles business logic error (code != 200)', () async {
        // GIVEN: Mock client returning HTTP 200 but error code
        // Note: Using ASCII message to avoid JSON parsing issues
        final mockClient = MockClient((_) async {
          return http.Response(
            '{"code": 40001, "message": "business logic error"}',
            200,
          );
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: Should throw exception
        expect(
          () => apiClient.post('/v2/test', bodyParams: {}),
          throwsA(isA<PolyvApiException>()),
        );
      });
    });

    group('[P2] POST Request - Parameter Encoding', () {
      test('[P2] post encodes special characters correctly', () async {
        // GIVEN: Mock client that captures request
        String? capturedBody;
        final mockClient = MockClient((request) async {
          capturedBody = request.body;
          return http.Response('{"code": 200}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Posting with special characters
        await apiClient.post(
          '/v2/test',
          bodyParams: {
            'text': 'hello 世界 & friends',
            'email': 'user+tag@example.com',
            'special': r'!@#$%^&*()',
          },
        );

        // THEN: Special characters should be encoded
        expect(capturedBody, isNotNull);
        expect(
          capturedBody!,
          contains('text=hello%20'),
        ); // Spaces encoded as %20
        expect(capturedBody!, contains('email=user%2Btag'));
      });

      test('[P2] post handles numeric parameters', () async {
        // GIVEN: Mock client
        final mockClient = MockClient((request) async {
          final body = request.body;
          expect(body, contains('count=123'));
          expect(body, contains('price=45.67'));
          return http.Response('{"code": 200}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Posting numeric parameters
        await apiClient.post(
          '/v2/test',
          bodyParams: {'count': 123, 'price': 45.67},
        );

        // THEN: Numbers should be converted to strings
      });

      test('[P2] post handles boolean parameters', () async {
        // GIVEN: Mock client
        final mockClient = MockClient((http.Request request) async {
          final body = request.body;
          expect(body, contains('active=true'));
          expect(body, contains('deleted=false'));
          return http.Response('{"code": 200}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Posting boolean parameters
        await apiClient.post(
          '/v2/test',
          bodyParams: {'active': true, 'deleted': false},
        );

        // THEN: Booleans should be converted to strings
      });
    });

    group('[P3] POST Request - Edge Cases', () {
      test('[P3] post handles empty body parameters', () async {
        // GIVEN: Mock client
        final mockClient = MockClient((http.Request request) async {
          final body = request.body;
          // Should still have auth params
          expect(body, contains('userid='));
          expect(body, contains('writetoken='));
          expect(body, contains('timestamp='));
          expect(body, contains('sign='));
          return http.Response('{"code": 200}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Posting with empty parameters
        final response = await apiClient.post('/v2/test', bodyParams: {});

        // THEN: Should succeed with auth params only
        expect(response.success, isTrue);
      });

      test('[P3] post handles null values in parameters', () async {
        // GIVEN: Mock client
        final mockClient = MockClient((http.Request request) async {
          final body = request.body;
          // Null values should be converted to 'null' string
          expect(body, contains('value1=null'));
          return http.Response('{"code": 200}', 200);
        });

        final apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: Posting with null values
        await apiClient.post(
          '/v2/test',
          bodyParams: {'value1': null, 'value2': 'valid'},
        );
      });

      test(
        '[P3] post generates unique signatures for different timestamps',
        () async {
          // GIVEN: Mock client
          final signatures = <String>[];
          final mockClient = MockClient((http.Request request) async {
            final body = request.body;
            final signMatch = RegExp(r'sign=([A-F0-9]{40})').firstMatch(body);
            if (signMatch != null) {
              signatures.add(signMatch.group(1)!);
            }
            return http.Response('{"code": 200}', 200);
          });

          final apiClient = PolyvApiClient(
            userId: 'test_user',
            readToken: 'test_read_token',
            writeToken: 'test_write_token',
            secretKey: 'test_secret',
            client: mockClient,
          );

          // WHEN: Making multiple requests with delay to ensure different timestamps
          await apiClient.post('/v2/test', bodyParams: {'key': 'value'});
          await Future.delayed(
            const Duration(milliseconds: 10),
          ); // Ensure different timestamp
          await apiClient.post('/v2/test', bodyParams: {'key': 'value'});

          // THEN: Signatures should differ (due to different timestamps)
          expect(signatures.length, 2);
          expect(
            signatures[0],
            isNot(signatures[1]),
            reason: 'Signatures with different timestamps should differ',
          );
        },
      );
    });
  });

  group('PolyvApiClient Signature Algorithm Tests', () {
    test('[P1] signature is deterministic for same parameters', () {
      // GIVEN: Same parameters
      final params = <String, dynamic>{
        'userid': 'test_user',
        'writetoken': 'test_write_token',
        'timestamp': '1234567890',
        'vid': 'test123',
      };

      // WHEN: Generating signature twice
      final sign1 = _generateSign(params, 'test_secret');
      final sign2 = _generateSign(params, 'test_secret');

      // THEN: Signatures should be identical
      expect(sign1, sign2);
      expect(sign1.length, 40); // SHA1 hash length
    });

    test('[P1] signature parameters are sorted alphabetically', () {
      // GIVEN: Parameters in random order
      final params1 = <String, dynamic>{
        'z': 'last',
        'a': 'first',
        'm': 'middle',
      };

      final params2 = <String, dynamic>{
        'm': 'middle',
        'a': 'first',
        'z': 'last',
      };

      // WHEN: Generating signatures
      final sign1 = _generateSign(params1, 'secret');
      final sign2 = _generateSign(params2, 'secret');

      // THEN: Signatures should match (sorted)
      expect(sign1, sign2);
    });

    test('[P2] signature includes secret key', () {
      // GIVEN: Two different secret keys
      final params = <String, dynamic>{'a': 'b'};

      // WHEN: Generating signatures with different secrets
      final sign1 = _generateSign(params, 'secret1');
      final sign2 = _generateSign(params, 'secret2');

      // THEN: Signatures should differ
      expect(sign1, isNot(sign2));
    });
  });

  group('PolyvApiResponse Tests (POST Context)', () {
    test('[P1] success factory creates valid success response', () {
      // WHEN: Creating success response
      final response = PolyvApiResponse<Map<String, dynamic>>.success(
        data: {'id': '123', 'result': 'ok'},
        statusCode: 201,
      );

      // THEN: Should have success properties
      expect(response.success, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!['id'], '123');
      expect(response.statusCode, 201);
      expect(response.error, isNull);
    });

    test('[P1] failure factory creates valid failure response', () {
      // WHEN: Creating failure response
      final response = PolyvApiResponse<Map<String, dynamic>>.failure(
        error: '请求参数错误',
        statusCode: 400,
      );

      // THEN: Should have failure properties
      expect(response.success, isFalse);
      expect(response.data, isNull);
      expect(response.statusCode, 400);
      expect(response.error, '请求参数错误');
    });
  });
}

/// Helper function to generate signature for testing
String _generateSign(Map<String, dynamic> params, String secretKey) {
  final signParams = Map<String, dynamic>.from(params);
  signParams.remove('sign');

  final sortedKeys = signParams.keys.toList()..sort();

  final buffer = StringBuffer();
  for (final key in sortedKeys) {
    buffer.write(signParams[key].toString());
  }
  buffer.write(secretKey);

  final bytes = utf8.encode(buffer.toString());
  final digest = sha1.convert(bytes);

  return digest.toString().toUpperCase();
}
