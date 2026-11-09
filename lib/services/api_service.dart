import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zelo/models/cep_address.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Consome a API REST pública ViaCEP.
class ApiService {
  Future<CepAddress> buscarCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) {
      throw const ApiException('CEP inválido. Digite os 8 números do CEP.');
    }

    try {
      final response = await http
          .get(Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ApiException('Serviço indisponível no momento (erro ${response.statusCode}).');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['erro'] != null) {
        throw const ApiException('CEP não encontrado. Confira os números digitados.');
      }
      return CepAddress.fromJson(json);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('A busca demorou demais. Tente novamente.');
    } catch (_) {
      throw const ApiException('Não foi possível conectar. Verifique sua internet.');
    }
  }
}
