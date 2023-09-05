class CloudStorageException implements Exception {
  const CloudStorageException();
}

class CannotCreateNote extends CloudStorageException {} 

class CannotGetAllNotes extends CloudStorageException {} 

class CannotUpdateNote extends CloudStorageException {} 

class CannotDeleteNote extends CloudStorageException {} 

