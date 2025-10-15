import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:math';

class StelacomApiService {
  static final String apiBaseUrl =
      'https://4669300-sb1.restlets.api.netsuite.com/app/site/hosting/';

  static const String consumerKey =
      '6a648c5a35b1a19d702f195bae5d5d02ed4a03b31e8977822d276bdf344384c4';
  static const String consumerSecret =
      '9dea60602c06a397df914f4d4e3f53a60a6c38bcd1f9190d100ceee872c2b932';
  static const String tokenId =
      '61d5751a148f9afb4b5fa93775556ce4022a1fc87191fd7d94aa028531bfd836';
  static const String tokenSecret =
      '4980cc8212fe887ddd3ee701048f40119a940da2ce1507b0585b919774d2f064';
  static const String realm = '4669300_SB1'; // e.g., '4669300_SB1'

  static String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  static String _generateTimestamp() {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  }

  static String _generateSignature(
    String method,
    String url,
    Map<String, String> params,
  ) {
    // Sort parameters
    final sortedParams = params.keys.toList()..sort();
    final paramString = sortedParams
        .map((key) => '$key=${Uri.encodeComponent(params[key]!)}')
        .join('&');

    // Create signature base string
    final signatureBaseString = [
      method.toUpperCase(),
      Uri.encodeComponent(url),
      Uri.encodeComponent(paramString),
    ].join('&');

    // Create signing key
    final signingKey =
        '${Uri.encodeComponent(consumerSecret)}&${Uri.encodeComponent(tokenSecret)}';

    // Generate signature
    final hmac = Hmac(sha256, utf8.encode(signingKey));
    final signature = hmac.convert(utf8.encode(signatureBaseString));
    return base64.encode(signature.bytes);
  }

  static Map<String, String> _generateOAuthHeaders(
    String method,
    String url,
    Map<String, String> queryParams,
  ) {
    final nonce = _generateNonce();
    final timestamp = _generateTimestamp();

    // OAuth parameters
    final oauthParams = {
      'oauth_consumer_key': consumerKey,
      'oauth_token': tokenId,
      'oauth_signature_method': 'HMAC-SHA256',
      'oauth_timestamp': timestamp,
      'oauth_nonce': nonce,
      'oauth_version': '1.0',
    };

    // Combine OAuth params with query params for signature
    final allParams = {...oauthParams, ...queryParams};

    // Generate signature
    final signature = _generateSignature(method, url, allParams);
    oauthParams['oauth_signature'] = signature;

    // Build Authorization header
    final authHeader =
        'OAuth realm="$realm",' +
        oauthParams.entries
            .map((e) => '${e.key}="${Uri.encodeComponent(e.value)}"')
            .join(',');

    return {'Authorization': authHeader, 'Content-Type': 'application/json'};
  }

  static Future<dynamic> loadDeviceListOfLocation(int locationId) async {
    try {
      final scriptId = '1918';
      final deployId = '1';

      final url = apiBaseUrl + 'restlet.nl';

      // Query parameters
      final queryParams = {
        'script': scriptId,
        'deploy': deployId,
        'locationid': locationId.toString(),
      };

      // Build full URL with query parameters
      final uri = Uri.parse(url).replace(queryParameters: queryParams);

      // Generate OAuth headers
      final headers = _generateOAuthHeaders('GET', url, queryParams);

      // Make the request
      var response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }
}
