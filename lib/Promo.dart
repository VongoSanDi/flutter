class Promo {
  final String titre;

  Promo({
    this.titre,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
        titre: json['titre']
    );
  }
}