import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:logging/logging.dart';

final _logger = Logger('OpenFoodFactsService');

/// Service to interact with OpenFoodFacts API for food and nutrition data
class OpenFoodFactsService {
  /// Search for products by name or keyword
  Future<List<dynamic>> searchProducts(String query, {int pageSize = 10}) async {
    _logger.info('Searching for products with query: $query, pageSize: $pageSize');
    try {
      final parameter = SearchTerms(terms: [query]);
      final configuration = ProductSearchQueryConfiguration(
        parametersList: <Parameter>[parameter, PageSize(size: pageSize)],
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.ALL],
        version: ProductQueryVersion.v3,
      );
      final result = await OpenFoodAPIClient.searchProducts(
        const User(userId: '', password: ''),
        configuration,
      );
      if (result.products != null) {
        _logger.info('Found ${result.products!.length} products for query: "$query"');
        return result.products!;
      }
    } catch (e) {
      _logger.severe('Error searching for products: $e');
    }
    return [];
  }

  /// Get detailed product info by barcode
  Future<dynamic> getProductByBarcode(String barcode) async {
    _logger.info('Getting product details for barcode: $barcode');
    try {
      final configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.ALL],
        version: ProductQueryVersion.v3,
      );
      
      final result = await OpenFoodAPIClient.getProduct(
        configuration,
        user: const User(userId: '', password: ''),
      );
      
      if (result.status == 1) {
        _logger.info('Successfully retrieved product for barcode: $barcode');
        return result.product;
      } else {
        _logger.warning('No product found for barcode: $barcode');
      }
    } catch (e) {
      _logger.severe('Error getting product by barcode: $e');
    }
    return null;
  }
}
