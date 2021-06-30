class JsonData {
  final dynamic data;
  
  JsonData(this.data);

  factory JsonData.fromData(dynamic data) {
    return data == null ? null : JsonData(data);
  }
  
  String getValue(String key) {
    var value = getDynamic(key)?.data;
    if (value is List && value.isNotEmpty) {
      return value.first;
    }
    return value.toString();
  }

  JsonData getDynamic(String key) {
    if (data is List && data.isNotEmpty()) {
      var value = data.first[key];
      return JsonData.fromData(value);
    } else if (data is Map) {
      return JsonData.fromData(data[key]);
    }
    return null;
  }
}