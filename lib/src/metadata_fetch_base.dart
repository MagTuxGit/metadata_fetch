import 'dart:async';
import 'dart:convert';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:metadata_fetch/src/parsers/parsers.dart';
import 'package:metadata_fetch/src/utils/util.dart';
import 'package:string_validator/string_validator.dart';

/// Fetches a [url], validates it, and returns [Metadata].
Future<Metadata> extract(String url) async {
  if (!isURL(url)) {
    return null;
  }

  /// Sane defaults; Always return the Domain name as the [title], and a [description] for a given [url]
  final defaultOutput = Metadata();
  defaultOutput.title = getDomain(url);
  defaultOutput.description = url;

  // fetch
  // Safari 14 Web Browser Mobile
  String defaultUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.1 Mobile/15E148 Safari/604.1";
  Document document;
  DocumentFetchResult result = await fetchDocument(url, userAgent: "Googlebot");

  if (result.type == DocumentFetchResultType.ROBOTS_DENIED) {
    result = await fetchDocument(url, userAgent: defaultUserAgent);
  }
  if (result.type == DocumentFetchResultType.GET_ERROR) {
    result = await fetchDocument(url);
  }

  switch (result.type) {
    case DocumentFetchResultType.ROBOTS_DENIED:
    case DocumentFetchResultType.GET_ERROR:
    case DocumentFetchResultType.PARSE_ERROR:
    case DocumentFetchResultType.TIMEOUT:
      return defaultOutput;
      break;
    case DocumentFetchResultType.IMAGE:
      defaultOutput.title = '';
      defaultOutput.description = '';
      defaultOutput.image = url;
      return defaultOutput;
      break;
    case DocumentFetchResultType.SUCCESS:
      document = result.document;
      break;
  }

  final data = _extractMetadata(document);
  if (data == null) {
    return defaultOutput;
  }

  return data;
}

/// Takes an [http.Response] and returns a [html.Document]
Document responseToDocument(http.Response response) {
  if (response.statusCode != 200) {
    return null;
  }

  Document document;
  try {
    document = parser.parse(utf8.decode(response.bodyBytes));
    document.requestUrl = response.request.url.toString();
  } catch (err) {
    return document;
  }

  return document;
}

/// Returns instance of [Metadata] with data extracted from the [html.Document]
///
/// Future: Can pass in a strategy i.e: to retrieve only OpenGraph, or OpenGraph and Json+LD only
Metadata _extractMetadata(Document document) {
  return MetadataParser.parse(document);
}

Future<DocumentFetchResult> fetchDocument(url, {String userAgent}) async {
  http.Response response;

  try {
    response = await http.get(url, headers: {
      'User-Agent': userAgent
    }).timeout(const Duration(seconds: 10));
  } on TimeoutException catch (_) {
    return DocumentFetchResult.timeout();
  }

  if (response == null || response.statusCode >= 400) {
    return DocumentFetchResult.getError();
  }

  // image
  if (response.headers['content-type'].startsWith(r'image/')) {
    return DocumentFetchResult.image();
  }

  final document = responseToDocument(response);

  if (document == null) {
    return DocumentFetchResult.parseError();
  }

  final robotsAttributes = document.head
      ?.querySelector("meta[name='ROBOTS']")
      ?.attributes;
  if (robotsAttributes != null) {
    if (robotsAttributes["content"]?.contains("NOINDEX") ?? false) {
      return DocumentFetchResult.robotsDenied();
    }
  }

  return DocumentFetchResult.success(document);
}

class DocumentFetchResult {
  DocumentFetchResultType type;
  Document document;

  DocumentFetchResult(this.type, {this.document});

  factory DocumentFetchResult.timeout() =>
      DocumentFetchResult(DocumentFetchResultType.TIMEOUT);

  factory DocumentFetchResult.getError() =>
      DocumentFetchResult(DocumentFetchResultType.GET_ERROR);

  factory DocumentFetchResult.parseError() =>
      DocumentFetchResult(DocumentFetchResultType.PARSE_ERROR);

  factory DocumentFetchResult.image() =>
      DocumentFetchResult(DocumentFetchResultType.IMAGE);

  factory DocumentFetchResult.robotsDenied() =>
      DocumentFetchResult(DocumentFetchResultType.ROBOTS_DENIED);

  factory DocumentFetchResult.success(Document document) =>
      DocumentFetchResult(DocumentFetchResultType.SUCCESS, document: document);
}

enum DocumentFetchResultType {
  SUCCESS,
  IMAGE,
  TIMEOUT,
  GET_ERROR,
  ROBOTS_DENIED,
  PARSE_ERROR
}
