class Result {
  static convertResult(data) {
    var datas = {
      "id": RegExp(r'var (k__id = ".*?");')
          .stringMatch(data)
          .toString()
          .split('"')[1],
      "v_id": RegExp(r'var (k_data_vid = ".*?");')
          .stringMatch(data)
          .toString()
          .split('"')[1],
      "v_title": RegExp(r'var (k_data_vtitle = ".*?");')
          .stringMatch(data)
          .toString()
          .split('"')[1],
      "duration": RegExp(r'>Duration:.(.*?)<').firstMatch(data)!.group(1),
    };
    return datas;
  }
}
