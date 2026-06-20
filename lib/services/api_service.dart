// BACKWARD COMPATIBILITY LAYER
// This file re-exports ApiDataService as ApiService for existing code
// 
// MIGRATION PATH:
// Old way: final _apiService = ApiService();
// New way:  late final _dataService = getIt<IDataService>();
//
// This file allows old code to keep working while we gradually migrate

export 'implementations/api_data_service.dart';
export 'interfaces/i_data_service.dart' show BooksResponse;

// Re-export as ApiService for backward compatibility
import 'implementations/api_data_service.dart';
typedef ApiService = ApiDataService;
