class ApiResponse<T> {
  final bool success;
  final String? message;
  final PaginationMeta? meta;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.meta,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'])
          : null,
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : json['data'],
    );
  }
}

class PaginationMeta {
  final int page;
  final int limit;
  final int totalPage;
  final int total;

  PaginationMeta({
    required this.page,
    required this.limit,
    required this.totalPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPage: json['totalPage'] ?? 1,
      total: json['total'] ?? 0,
    );
  }
}
