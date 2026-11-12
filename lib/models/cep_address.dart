class CepAddress {
  final String cep;
  final String street;
  final String neighborhood;
  final String city;
  final String state;

  const CepAddress({
    required this.cep,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  factory CepAddress.fromJson(Map<String, dynamic> json) => CepAddress(
        cep: (json['cep'] ?? '') as String,
        street: (json['logradouro'] ?? '') as String,
        neighborhood: (json['bairro'] ?? '') as String,
        city: (json['localidade'] ?? '') as String,
        state: (json['uf'] ?? '') as String,
      );

  String get fullAddress => [street, neighborhood, '$city - $state']
      .where((part) => part.trim().isNotEmpty)
      .join(', ');
}
