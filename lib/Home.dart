import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:btc_stats/GraphPage.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool connected = true;
  String dropdownValue = '';
  Map btcRateData;
  Map btcPriceData;
  Map mktCap;
  Map totalBtc;
  Map trade;
  List<String> currencies = [];
  List<Prices> pricesList = [];
  List<Prices> mktCapList = [];
  List<Prices> totalList = [];
  List<Prices> tradeList = [];

  Timer timer;

  TextEditingController currency = TextEditingController();
  TextEditingController btc = TextEditingController();

  checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        getbtcRateData().then((n) {
          setState(() {
            currency.text = btcRateData[dropdownValue]['last'].toString();
            btc.text = '1';
          });
        });
      }
    } on SocketException catch (_) {
      setState(() {
        connected = false;
      });
    }
  }

  Future getbtcRateData() async {
    http.Response data = await http.get('https://blockchain.info/ticker');
    http.Response priceData = await http.get('https://api.blockchain.info/charts/market-price?timespan=1week&rollingAverage=8hours');
    http.Response mktCapData = await http.get('https://api.blockchain.info/charts/market-cap?timespan=1week&rollingAverage=8hours');
    http.Response totalBtcData = await http.get('https://api.blockchain.info/charts/total-bitcoins?timespan=1week&rollingAverage=8hours');
    http.Response tradeData = await http.get('https://api.blockchain.info/charts/trade-volume?timespan=1week&rollingAverage=8hours');
    setState(() {
      btcRateData = json.decode(data.body);
      btcPriceData = json.decode(priceData.body);
      mktCap = json.decode(mktCapData.body);
      totalBtc = jsonDecode(totalBtcData.body);
      trade = jsonDecode(tradeData.body);
      btcRateData.keys.forEach((key) => currencies.add(key));
      for (var p in btcPriceData['values']) {
        pricesList.add(Prices(DateTime.fromMillisecondsSinceEpoch(p['x'] * 1000).toString().substring(0, 10), p['y']));
      }
      for (var p in mktCap['values']) {
        mktCapList.add(Prices(DateTime.fromMillisecondsSinceEpoch(p['x'] * 1000).toString().substring(0, 10), p['y']));
      }
      for (var p in totalBtc['values']) {
        totalList.add(Prices(DateTime.fromMillisecondsSinceEpoch(p['x'] * 1000).toString().substring(0, 10), p['y']));
      }
      for (var p in trade['values']) {
        tradeList.add(Prices(DateTime.fromMillisecondsSinceEpoch(p['x'] * 1000).toString().substring(0, 10), p['y']));
      }
      dropdownValue = currencies[0];
    });
    print(currencies);
    timer = Timer.periodic(Duration(minutes: 15), (t) {
      var n = 1;
      print(n++);

      dropdownValue = '';
      btcRateData = null;
      btcPriceData = null;
      mktCap = null;
      totalBtc = null;
      trade = null;
      currencies = [];
      pricesList = [];
      mktCapList = [];
      totalList = [];
      tradeList = [];
      getbtcRateData();
    });
  }

  @override
  void initState() {
    checkConnection();
    super.initState();
  }

  dispose() {
    timer.cancel();
    super.dispose();
  }

  Widget chartMaker(i) {
    var l, head, next, detail;
    switch (i) {
      case 1:
        l = pricesList;
        head = 'Market price(USD)';
        next = 'market-price';
        detail = 'Average USD market price across major \nbitcoin exchanges.';
        break;
      case 2:
        l = mktCapList;
        head = 'Market Capitalization(USD)';
        next = 'market-cap';
        detail = 'The total USD value of bitcoin supply in \ncirculation.';
        break;
      case 3:
        l = tradeList;
        head = 'USD Exchange Trade Volume';
        next = 'trade-volume';
        detail = 'The total USD value of trading volume on major \nbitcoin exchanges.';
        break;
      case 4:
        l = totalList;
        head = 'Total bitcoins in circulation';
        next = 'total-bitcoins';
        detail = 'The total number of bitcoins that have already \nbeen mined.';
        break;
      default:
    }
    return Card(
        elevation: 100,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.orange[700] : Colors.orange[100],
        child: Container(
          child: Column(
          children: <Widget>[
            Padding(padding: EdgeInsets.all(5)),
            Text(
              head,
              style: TextStyle(fontSize: 20,)
            ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Text(
            //     detail,
            //     textWidthBasis: TextWidthBasis.longestLine,
            //     softWrap: true,
            //     maxLines: 2,
            //     style: TextStyle(
            //       fontSize: 15,
            //     )
            //   ),
            // ),
            Padding(padding: EdgeInsets.all(5)),
            Stack(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.all(10),
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.yellow[100],
                  child: SfCartesianChart(
                    // Initialize category axis
                    primaryXAxis: CategoryAxis(),
                    series: <LineSeries<Prices, String>>[
                      LineSeries<Prices, String>(
                        // Bind data source
                        color: Colors.blue,
                        dataSource: l,
                        xValueMapper: (Prices prices, _) => prices.date,
                        yValueMapper: (Prices prices, _) => prices.price
                      )
                    ]
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Padding(padding: EdgeInsets.only(left: 270)),
                    IconButton(
                      icon: Icon(Icons.launch), 
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => GraphPage(next, head)));
                      }
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight, 
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown, 
    ]);

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
                        Text('Check your internet connection'),
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
                            OutlineButton.icon(onPressed: () => exit(0), icon: Icon(Icons.close), label: Text('Exit')),
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
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange))
            ]
          )
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('BTC Stats'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        actions: <Widget>[
          IconButton(
            icon: Theme.of(context).brightness == Brightness.dark ? Icon(Icons.wb_sunny, size: 30,) : Icon(Icons.brightness_3),
            onPressed: () {
              DynamicTheme.of(context).setBrightness(Theme.of(context).brightness == Brightness.dark? Brightness.light: Brightness.dark);
              // DynamicTheme.of(context).setThemeData(new ThemeData(
              //     primaryColor: Theme.of(context).primaryColor == Colors.indigo? Colors.red: Colors.indigo
              // ));
              // Theme.of(context).brightness == Brightness.dark ? Theme.of(context).brightness = Brightness.light : Theme.of(context).brightness = Brightness.dark;  
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Card(
                  elevation: 5,
                  child: Container(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: DropdownButton<String>(
                      value: dropdownValue,
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        fontSize: 20
                      ),
                      underline: Container(
                        height: 0,
                      ),
                      onChanged: (String newValue) {
                        setState(() {
                          dropdownValue = newValue;
                          setState(() {
                            currency.text = btcRateData[dropdownValue]['last'].toString();
                            btc.text = '1';
                          });
                        });
                      },
                      items: currencies
                        .map<DropdownMenuItem<String>>((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(10)),
                TextFormField(
                  controller: currency,
                  // initialValue: btcRateData[dropdownValue]['last'].toString(),
                  keyboardType: TextInputType.number,
                  enableInteractiveSelection: false,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    labelText: dropdownValue,
                    hintText: dropdownValue,
                    border: OutlineInputBorder(),
                    suffixText: btcRateData != null ? btcRateData[dropdownValue]['symbol'].toString() : '',
                    suffixStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 20)
                  ),
                  onChanged: (value) {
                    value = value.replaceAll(' ', '');
                    value = value.replaceAll(',', '');
                    setState(() {
                      btc.text = value == '' ? '' : (double.parse(value) * (1 / btcRateData[dropdownValue]['last'])).toString();
                    });
                  },
                ),
                Padding(padding: EdgeInsets.all(5)),
                TextFormField(
                  controller: btc,
                  // initialValue: '1',
                  keyboardType: TextInputType.number,
                  enableInteractiveSelection: false,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    labelText: 'BTC',
                    hintText: 'BTC',
                    border: OutlineInputBorder(),
                    suffixText: '₿',
                    suffixStyle: TextStyle(fontWeight: FontWeight.w300, fontSize: 20)
                  ),
                  onChanged: (value) {
                    value = value.replaceAll(' ', '');
                    value = value.replaceAll(',', '');
                    setState(() {
                      currency.text = value == '' ? '' : (double.parse(value) * btcRateData[dropdownValue]['last']).toString();
                    });
                  },
                ),
                Padding(padding: EdgeInsets.all(10)),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      chartMaker(1),
                      chartMaker(2),
                      chartMaker(3),
                      chartMaker(4),
                    ],
                  ),
                ), 
                // Expanded(
                //   child: ListView.builder(
                //     scrollDirection: Axis.horizontal,
                //     itemCount: 4,
                //     itemBuilder: (context, index) {
                //       return chartMaker();
                //     },
                    
                //   ),
                // )             
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Prices {
  var date;
  var price;
  Prices(this.date, this.price);    
}