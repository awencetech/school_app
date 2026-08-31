class LibraryBook {
  const LibraryBook({
    this.id,
    required this.bookName,
    required this.author,
    required this.bookId,
    this.publisher = '',
    this.availability = 'available',
  });

  final String? id;
  final String bookName;
  final String author;
  final String bookId;
  final String publisher;
  final String availability;

  bool get isReserved => availability == 'reserved';

  factory LibraryBook.fromJson(Map<String, dynamic> json) => LibraryBook(
        id: (json['_id'] ?? json['id'])?.toString(),
        bookName: (json['bookName'] ?? '').toString(),
        author: (json['author'] ?? '').toString(),
        bookId: (json['bookId'] ?? '').toString(),
        publisher: (json['publisher'] ?? '').toString(),
        availability: json['availability'] == 'reserved' ? 'reserved' : 'available',
      );

  Map<String, dynamic> toJson() => {
        'bookName': bookName,
        'author': author,
        'bookId': bookId,
        'publisher': publisher,
        'availability': availability,
      };
}
