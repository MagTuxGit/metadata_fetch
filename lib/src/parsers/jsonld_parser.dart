import 'dart:convert';

import 'package:html/dom.dart';
import 'package:metadata_fetch/src/utils/util.dart';

import 'base_parser.dart';

/// Takes a [http.document] and parses [Metadata] from `json-ld` data in `<script>`
class JsonLdParser with BaseMetadataParser {
  /// The [document] to be parse
  Document document;
  Map<String, dynamic> _jsonData;

  JsonLdParser(this.document) {
    var jsonData = _parseToJson(document);

    if (jsonData is List) {
      jsonData = jsonData.first as Map<String, dynamic>;
    }
    if (jsonData == null) return;

    var graphList = jsonData["@graph"] as List;
    if (graphList != null) {
      List<String> metaDataNodes = ["website", "newsarticle"];

      for (var graphNode in graphList) {
        if (graphNode is Map<String, dynamic>) {
          String nodeType = (graphNode["@type"] as String)?.toLowerCase();
          if (nodeType != null && metaDataNodes.contains(nodeType)) {
            jsonData = graphNode;
            break;
          }
        }
      }
    }

    _jsonData = jsonData;
  }

  dynamic _parseToJson(Document document) {
    final data = document?.head
        ?.querySelector("script[type='application/ld+json']")
        ?.innerHtml
        ?.replaceAll('\n', ' ');
    if (data == null) {
      return null;
    }
    var d = jsonDecode(data);
    return d;
  }

  /// Get the [Metadata.title] from the [<title>] tag
  @override
  String get title {
    return _jsonData?.get('headline') ?? _jsonData?.get('name');
  }

  /// Get the [Metadata.description] from the <meta name="description" content=""> tag
  @override
  String get description {
    return _jsonData?.get('description');
  }

  /// Get the [Metadata.image] from the first <img> tag in the body;s
  @override
  String get image {
    var imageNode = _jsonData?.getDynamic('image') ??
        _jsonData?.getDynamic('logo');
    return _imageResultToString(imageNode);
  }

  String _imageResultToString(dynamic result) {
    if (result is List && result.isNotEmpty) {
      result = result.first;
    }

    if (result is Map<String, dynamic>) {
      result = result["url"];
    }

    if (result is String) {
      return result;
    }

    return null;
  }

  /// Get the document request URL from Document's [HttpRequestData] extension.
  @override
  String get url => document?.requestUrl;

  @override
  String toString() => parse().toString();
}
