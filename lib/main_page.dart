import 'dart:async';
import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'Promo.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {

  // Déclaration variable globale
  bool _loadingMessage;
  String barcode = "";
  String url = "http://cd03bca4.ngrok.io/";
  Future<Promo> futurePromo;
  final double sizeSubTitle = 25;

  @override
  initState() {
    super.initState();
    startTimer();
    _loadingMessage = false;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.red
      ),
      home: new Scaffold(
          appBar: new AppBar(
            title: new Text('Go Style'),
          ),
          body: Container(
            //color: Colors.red,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      child: Text(
                          "Voici les promotions en cours",
                      style: (TextStyle(fontSize: sizeSubTitle))
                      ),
                    )
                  ],
                ),
                Expanded(
                  flex: 5,
                  child: FutureBuilder(
                    future: getPromo(),
                    builder: (context, snapshot) {
                      if(snapshot.data == null) {
                        if(_loadingMessage == true) {
                          return Container(
                              child: Center(
                                child: CircularProgressIndicator(),
                              )
                          );
                        } else {
                          return Container(
                            child: Text("Un problème est survenu",
                            style: (TextStyle(fontSize: 30, color: Colors.red)), textAlign: TextAlign.center,),
                          );
                        }
                      }
                      else {
                        return ListView.separated(
                            itemCount: snapshot.data.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(snapshot.data[index].titre),
                              );
                            },
                          separatorBuilder: (context, index) => const Divider(),
                            );
                      }
                    },
                  ),
                ),
                Row(
                  children: <Widget>[
                    Container(
                      child: Text(
                          "Nouveau code à scanner ?",
                          style: (TextStyle(fontSize: sizeSubTitle)),
                        textAlign: TextAlign.justify,
                      ),
                    )
                  ],
                ),
                Expanded(
                  flex: 5,
                  child: new MaterialButton(
                    onPressed: scan,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 300),
                      child: new Icon(Icons.add_a_photo, size: 150.0,),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
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
      setState(() => this.barcode = "Vous avez appuyé sur le bouton retour");//TODO Afficher ce message lorsque l'on fais des messages d'erreurs
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

  Future<List<Promo>> getPromo() async {
    final reponse = await http.get(Uri.encodeFull(this.url + "liste"));
    print("reponse Promo "+this.url + "liste");
    return listPromos(reponse.body);
  }

  List<Promo> listPromos(String param) {
    final parsed = json.decode(param).cast<Map<String, dynamic>>();

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

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    var temps = 0;
    new Timer.periodic(oneSec, (Timer t) {
      setState(() {
        _loadingMessage = true;
        temps += 1;
        if(temps == 10) {
          _loadingMessage = false;
          t.cancel();
          return;
        }
      });
    });
  }
}