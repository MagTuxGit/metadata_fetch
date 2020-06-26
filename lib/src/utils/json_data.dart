class JsonData {
  final dynamic data;
  
  JsonData(this.data);

  factory JsonData.fromData(dynamic data) {
    return data == null ? null : JsonData(data);
  }
  
  String getValue(String key) {
    return getDynamic(key)?.data;
  }

  JsonData getDynamic(String key) {
    if (data is List && data.isNotEmpty()) {
      var value = data.first[key];
      return JsonData.fromData(value);
    } else if (data is Map) {
      return JsonData.fromData(data[key]);
    }
  }
}