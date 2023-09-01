class UserNotFoundAuthException implements Exception {}
class MissingEmailAuthException implements Exception {}
class MissingPasswordAuthException implements Exception {}
class InvalidEmailAuthException implements Exception {}
class InvalidPasswordAuthException implements Exception {}
class WeakPasswordAuthException implements Exception {}
class AccountAlreadyExistsAuthException implements Exception {}

// generic exceptions
class UnknownAuthException implements Exception {}
class UserNotLoggedInAuthException implements Exception {}