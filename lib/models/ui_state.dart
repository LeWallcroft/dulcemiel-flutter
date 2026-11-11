enum UiStatus { initial, loading, success, empty, error }

/// Estado común para representar carga, éxito con datos, lista vacía y error.
/// [data] conserva el último valor mientras se refrescan datos en caché.
class UiState<T> {
  const UiState._({required this.status, this.data, this.message});

  factory UiState.initial() => UiState._(status: UiStatus.initial);

  factory UiState.loading({T? previous}) =>
      UiState._(status: UiStatus.loading, data: previous);

  factory UiState.success(T data, {String? message}) =>
      UiState._(status: UiStatus.success, data: data, message: message);

  factory UiState.empty(T data, {String? message}) =>
      UiState._(status: UiStatus.empty, data: data, message: message);

  factory UiState.error(String message, {T? previous}) =>
      UiState._(status: UiStatus.error, data: previous, message: message);

  final UiStatus status;
  final T? data;
  final String? message;

  bool get isInitial => status == UiStatus.initial;
  bool get isLoading => status == UiStatus.loading;
  bool get isSuccess => status == UiStatus.success;
  bool get isEmpty => status == UiStatus.empty;
  bool get hasError => status == UiStatus.error;
}
