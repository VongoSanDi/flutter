import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
//import 'Promo.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {

  // Déclaration variable globale
  String barcode = "";
  String url = "http://fda39c7d.ngrok.io/";
  Future<Promo> futurePromo;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          appBar: new AppBar(
            title: new Text('Go Style'),
          ),
          body: new Center(
            child: new Column(
              children: <Widget>[
                new Container(
                  child: FutureBuilder<List<Promo>>(
                      future: getPromo(http.Client()),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) print(snapshot.error);

                        return snapshot.hasData
                            ? ListePromos(promos: snapshot.data)
                            : Center(child: CircularProgressIndicator());
                      }
                  ),
                ),
                /*new Container(
                  child: new MaterialButton(
                      onPressed: scan,
                      child: Container(
                        margin: EdgeInsets.only(top: 200),
                        child: new Icon(Icons.add_a_photo, size: 150.0),
                      )
                  ),
                  padding: const EdgeInsets.all(8.0),
                ),*/
              ],
            ),
          )),
    );
  }

  Future scan() async {
    try {
      //TODO ne pas envoyé si on appuie sur le bouton retour
      String barcode = await BarcodeScanner.scan();
      setState(() => this.barcode = barcode);

    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this.barcode = "Vous n''avez pas donné la permission d''utiliser le micro !!";
        });
      } else {
        setState(() => this.barcode = 'Erreur inconnue: $e');
      }
    } on FormatException{
      setState(() => this.barcode = "Vous avez appuyé sur le bouton retour");//TODO Faire afficher ce message d'erreur lorsque l'on annule la prise de photo
    } catch (e) {
      setState(() => this.barcode = 'Erreur inconnue: $e');
    }

    try {
      String resultat = await getData(barcode);
      showPop(context, resultat);
    } catch(e) {
      //TODO demander au prof ce que l'on peut mettre  dans le catch
      //setState(() => this.resultat = 'Erreur inconnue: $e');
    }
  }

  // Méthde intérogeant la base de donnée
  Future getData(param) async {
    var uri = this.url + "?qrcode="+ param;
    http.Response reponse = await http.get(Uri.encodeFull(uri));
    if(reponse.statusCode == 200) {
      return reponse.body;
    }
    else if(reponse.statusCode == 502) {
      return "Serveur inaccessible";
    }
  }

  Future<List<Promo>> getPromo(http.Client client) async {
    print("test debut");
    //final reponse = await client.get(Uri.encodeFull(this.url + "liste"));
    final reponse = await client.get(this.url + "liste");
    print("reponse Promo "+this.url + "liste = "+reponse.body);

    //return compute(parsePromos, reponse.body);
    return parsePromos(reponse.body);
  }

  List<Promo> parsePromos(String reponseBody) {
    print("test aaaa "+reponseBody);
    final parsed = json.decode(reponseBody).cast<Map<String, dynamic>>();
    //print("test parsed "+parsed);
    print("test reponse "+parsed.map<Promo>((json) => Promo.fromJson(json)).toList());
    return parsed.map<Promo>((json) => Promo.fromJson(json)).toList();
  }

  // Fonction recevant le résultat de l'API et l'affichant en pop-up
  showPop(BuildContext context, param) {
    return showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text("CODE PROMO"),
        content: Text(param),
        actions: <Widget>[
          MaterialButton(
            elevation: 5.0,
            child: Text('Fermer'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }
}

class Promo {
  final String titre;

  Promo({
    this.titre,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
        titre: json['titre'] as String
    );
  }
}

/*class ListePromos extends StatelessWidget {
  final List<Promo> promos;

  ListePromos({Key key, this.promos}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2
        ),
        itemCount: promos.length,
        itemBuilder: (context, index) {
          return Text(promos[index].titre);
        });
  }
}*/

class ListePromos extends StatelessWidget {
  final List<Promo> promos;

  ListePromos({Key key, this.promos}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2
        ),
        itemCount: promos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(promos[index].titre),
          );
        });
  }
}