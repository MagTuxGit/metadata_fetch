import 'dart:convert';

import 'package:html/dom.dart';
import 'package:metadata_fetch/src/utils/util.dart';
import 'package:metadata_fetch/src/utils/json_data.dart';

import '../base_parser.dart';

/// Takes a [http.document] and parses [Metadata] from `json-ld` data in `<script>`
class JsonLdProductParser with BaseMetadataParser {
  /// The [document] to be parse
  Document document;
  JsonData _jsonData;

  JsonLdProductParser(this.document) {
    _jsonData = _parseToJson(document);
  }

  JsonData _parseToJson(Document document) {
    var ldJsonItem = document?.head
        ?.querySelectorAll("script[type='application/ld+json']")
        ?.map((e) => jsonDecode(e.innerHtml.replaceAll('\n', ' ')));

    if (ldJsonItem == null) return null;
    if (ldJsonItem is List) {
      ldJsonItem = ldJsonItem.isEmpty ? null : ldJsonItem.first;
    }

    if (ldJsonItem != null && ldJsonItem is Map<String, dynamic>) {
      var ldJsonProductItem = ldJsonItem.firstWhere((e) =>
      e["@type"] == "Product",
          orElse: () => null);
      return ldJsonItem == null ? null : JsonData(ldJsonItem);
    }

    return null;
  }
  
  @override
  String get title => _jsonData?.getValue('name');

  @override
  String get description {
    String description = _jsonData?.getValue('description');

    var offer = _jsonData?.getDynamic('offers');
    if (offer != null) {
      var price = offer.getValue('price');
      if (price != null) {
        return ((description != null && description.isNotEmpty) ? description + '\n\n' : "")
            + offer.getValue('priceCurrency') + ' ' + price;
      }
    }
    return description;
  }

  @override
  String get image => _jsonData?.getValue('image');

  @override
  String get url => _jsonData?.getValue('url');
}
