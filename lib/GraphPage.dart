import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;

class GraphPage extends StatefulWidget {
  String page, head;
  GraphPage(this.page, this.head);
  @override
  _GraphPageState createState() => _GraphPageState(page, head);
}

class _GraphPageState extends State<GraphPage> {
  bool connected = true;

  String page, head;
  _GraphPageState(this.page, this.head);
  String url;
  String dropdownValue = '1 Week', timePeriod = '1week';
  Map btcPriceData;
  bool showOps = false;
  List<Prices> pricesList = [];

  checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) { 
        getbtcRateData();
      }
    } on SocketException catch (_) {
      setState(() {
        connected = false;
      });
    }
  }



  Future getbtcRateData() async {
    http.Response priceData = await http.get(url);
    setState(() {
      btcPriceData = json.decode(priceData.body);
      for (var p in btcPriceData['values']) {
        pricesList.add(Prices(DateTime.fromMillisecondsSinceEpoch(p['x'] * 1000).toString().substring(0, 10), p['y']));
      }
    });
  }


  Widget Options() {    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Column(
          children: <Widget>[
            AnimatedContainer(
              curve: Curves.easeOut,
              duration: Duration(milliseconds: 300),
              height: showOps ? 76 : 0,
              width: 300,//showOps ? 323 : 0,
              child: showOps == false ? null : Card(
                elevation: 20,
                child: ListTile(
                  title: Column(
                    children: <Widget>[
                      Text(
                        head,
                        style: TextStyle(
                          fontSize: 17,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black
                        ),
                      ),
                      DropdownButton<String>(
                        value: dropdownValue,
                        icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                        iconSize: 24,
                        elevation: 16,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black
                        ),
                        underline: Container(
                          height: 0,
                        ),
                        onChanged: (String newValue) {
                          setState(() {
                            dropdownValue = newValue;
                            btcPriceData = null;
                            pricesList = [];
                            timePeriod = newValue.replaceAll(' ', '').toLowerCase();
                            url = 'https://api.blockchain.info/charts/$page?timespan=$timePeriod&rollingAverage=8hours';
                          });
                          checkConnection();
                        },
                        items: ['1 Week', '1 Months', '1 Year', '10 Years']
                          .map<DropdownMenuItem<String>>((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),),
                            );
                          }).toList(),
                
                      ),
                    ],
                  ),
                )
              ),
            ),
            IconButton(
              icon: showOps ? Icon(Icons.keyboard_arrow_up, size: 30) : Icon(Icons.keyboard_arrow_down, size: 30),
              onPressed: () {
                setState(() {
                  showOps = !showOps;
                });
              }
            ),
          ],
        ),
      ],
    );    
  }
  
  @override
  void initState() {
    setState(() {
      url = 'https://api.blockchain.info/charts/$page?timespan=$timePeriod&rollingAverage=8hours';
      // animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    });
    checkConnection();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight, 
    ]);
    
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   systemNavigationBarColor: Colors.black, // navigation bar color
    //   statusBarColor: Colors.black, // status bar color
    // )); 
    
    if (!connected) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.signal_cellular_connected_no_internet_4_bar, size: 50),
                        Padding(padding: EdgeInsets.all(5)),
                        Text('Check your internet connection.'),
                        Padding(padding: EdgeInsets.all(10)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            OutlineButton.icon(
                              onPressed: () {
                                setState(() {
                                  connected = true;
                                });
                                checkConnection();
                              }, 
                              icon: Icon(Icons.replay), 
                              label: Text('Retry')
                            ),
                            OutlineButton.icon(onPressed: () => Navigator.pop(context), icon: Icon(Icons.exit_to_app), label: Text('Go back')),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }
    
    else if (btcPriceData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),)
            ]
          )
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                // trackballBehavior: TrackballBehavior(
                //   enable: true,
                //   shouldAlwaysShow: true,
                //   lineColor: Colors.purple,
                //   tooltipSettings: InteractiveTooltip(
                //     color: Colors.white,
                //     borderColor: Colors.black
                //   )
                // ),
                zoomPanBehavior: ZoomPanBehavior(
                  enablePanning: true,
                  enablePinching: true
                ),
                crosshairBehavior: CrosshairBehavior(
                  enable: true,
                  shouldAlwaysShow: true,
                  lineType: CrosshairLineType.both,
                  lineColor: Colors.orange,
                ),
                series: <LineSeries<Prices, String>>[
                  LineSeries<Prices, String>(
                    // Bind data source
                    color: pricesList[0].price > pricesList[pricesList.length - 1].price ? Colors.redAccent : Colors.greenAccent,
                    dataSource:  pricesList,
                    xValueMapper: (Prices prices, _) => prices.date,
                    xAxisName: 'Time',
                    yValueMapper: (Prices prices, _) => prices.price,
                    yAxisName: 'USD'
                  )
                ]
              )
            ),
            Options(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.clear),
                )
              ],
            )
          ],
        ),
      )
    );
  }
}


class Prices {
  var date;
  var price;
  Prices(this.date, this.price);    
}