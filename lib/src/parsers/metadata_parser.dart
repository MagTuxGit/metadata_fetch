import 'package:html/dom.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

/// Does Works with `BaseMetadataParser`
class MetadataParser {
  /// This is the default strategy for building our [Metadata]
  ///
  /// It tries [OpenGraphParser], then [TwitterCardParser], then [JsonLdParser], and falls back to [HTMLMetaParser] tags for missing data.
  /// You may optionally provide a URL to the function, used to resolve relative images or to compensate for the lack of URI identifiers
  /// from the metadata parsers.
  static Metadata parse(Document? document, {String? url}) {
    final output = Metadata();

    final parsers = [
      jsonLdProduct(document),
      openGraph(document),
      twitterCard(document),
      jsonLdSchema(document),
      htmlMeta(document),
    ];

    for (final p in parsers) {
      output.title ??= _notNull(p.title);
      output.description ??= _notNull(p.description);
      output.image ??= p.image;
      output.url ??= _notNull(p.url);

      if (output.hasAllMetadata) {
        break;
      }
    }
    // If the parsers did not extract a URL from the metadata, use the given
    // url, if available. This is used to attempt to resolve relative images.
    final _url = output.url ?? url;
    final image = output.image;
    if (_url != null && image != null) {
      output.image = Uri.parse(_url).resolve(image).toString();
    }

    return output;
  }

  static String? _notNull(String? value) {
    if (value == null || value == "" || value == "null") {
      return null;
    }
    return value;
  }

  // static String _imageUrl(Metadata data) {
  //   String imageLink = _notNull(data.image);
  //   if (imageLink == null) return null;
  //   if (imageLink.startsWith("http")) return imageLink;
  //   var pageUrl = Uri.parse(data.url);
  //   if (!imageLink.startsWith("/")) {
  //     // Some image srcs don't begin with a slash, so the image url ends up being
  //     // weirdly mangled if it's just appended to the page host. Example:
  //     // imageLink = "assets/someImg.png"
  //     // http://example.comassets/someImg.png
  //     // So this should fix that
  //     imageLink = "/$imageLink";
  //   }
  // }

  static Metadata jsonLdProduct(Document? document) {
    return JsonLdProductParser(document).parse();
  }

  static Metadata openGraph(Document? document) {
    return OpenGraphParser(document).parse();
  }

  static Metadata htmlMeta(Document? document) {
    return HtmlMetaParser(document).parse();
  }

  static Metadata jsonLdSchema(Document? document) {
    return JsonLdParser(document).parse();
  }

  static Metadata twitterCard(Document? document) {
    return TwitterCardParser(document).parse();
  }
}
