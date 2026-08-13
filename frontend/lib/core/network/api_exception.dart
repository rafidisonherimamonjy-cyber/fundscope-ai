/// Exception levée par la couche réseau, avec un message déjà adapté à
/// l'affichage utilisateur (extrait du champ `detail` renvoyé par l'API
/// FastAPI, ou message générique si indisponible).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
