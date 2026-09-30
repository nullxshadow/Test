import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // গুগল অ্যাডমব ইনিশিয়ালাইজ করুন
  await MobileAds.instance.initialize();
  
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'স্মার্ট ক্যালকুলেটর',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String display = '0';
  String previousValue = '';
  String operation = '';
  bool shouldResetDisplay = false;
  int tabIndex = 0;
  List<String> history = [];
  
  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;
  bool bannerAdLoaded = false;

  // গুগল অ্যাডমব IDs (আপনার আসল ID বসাবেন)
  static const String bannerAdUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy';
  static const String interstitialAdUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzzzzzz';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  // ব্যানার অ্যাড লোড করুন
  void _loadBannerAd() {
    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => bannerAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    bannerAd?.load();
  }

  // ইন্টারস্টিশিয়াল অ্যাড লোড করুন
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  // ইন্টারস্টিশিয়াল অ্যাড দেখান
  void _showInterstitialAd() {
    if (interstitialAd != null) {
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      interstitialAd!.show();
      interstitialAd = null;
    }
  }

  void appendNumber(String num) {
    setState(() {
      if (shouldResetDisplay) {
        display = num;
        shouldResetDisplay = false;
      } else {
        display = display == '0' ? num : display + num;
      }
    });
  }

  void appendOperator(String op) {
    setState(() {
      if (operation.isNotEmpty) {
        calculate();
      }
      previousValue = display;
      operation = op;
      shouldResetDisplay = true;
    });
  }

  void calculate() {
    if (operation.isEmpty || shouldResetDisplay) return;

    try {
      double prev = double.parse(previousValue);
      double current = double.parse(display);
      double result = 0;

      switch (operation) {
        case '+':
          result = prev + current;
          break;
        case '-':
          result = prev - current;
          break;
        case '×':
          result = prev * current;
          break;
        case '÷':
          result = current != 0 ? prev / current : 0;
          break;
      }

      setState(() {
        history.insert(0, '$previousValue $operation $display = ${result.toStringAsFixed(8)}');
        if (history.length > 50) history.removeLast();
        
        display = result.toStringAsFixed(8).replaceAll(RegExp(r'\.?0+$'), '');
        if (display.isEmpty) display = '0';
        
        operation = '';
        shouldResetDisplay = true;
      });

      // প্রতি ৫টি ক্যালকুলেশনের পর অ্যাড দেখান
      if (history.length % 5 == 0) {
        _showInterstitialAd();
      }
    } catch (e) {
      setState(() => display = 'Error');
    }
  }

  void clearDisplay() {
    setState(() {
      display = '0';
      previousValue = '';
      operation = '';
      shouldResetDisplay = false;
    });
  }

  void calculatePercentage() {
    try {
      double value = double.parse(display);
      setState(() {
        display = (value / 100).toString();
      });
    } catch (e) {
      setState(() => display = 'Error');
    }
  }

  void scientificFunction(String func) {
    try {
      double value = double.parse(display);
      double result = 0;

      switch (func) {
        case 'sqrt':
          result = sqrt(value);
          break;
        case 'square':
          result = value * value;
          break;
        case 'reciprocal':
          result = 1 / value;
          break;
        case 'sin':
          result = sin(value * pi / 180);
          break;
        case 'cos':
          result = cos(value * pi / 180);
          break;
        case 'tan':
          result = tan(value * pi / 180);
          break;
        case 'log':
          result = log(value) / log(10);
          break;
        case 'ln':
          result = log(value);
          break;
        case 'factorial':
          result = factorial(value.toInt()).toDouble();
          break;
        case 'pi':
          setState(() => display = pi.toString());
          return;
        case 'exp':
          setState(() => display = e.toString());
          return;
      }

      setState(() {
        history.insert(0, '$func($value) = ${result.toStringAsFixed(8)}');
        display = result.toStringAsFixed(8).replaceAll(RegExp(r'\.?0+$'), '');
        if (display.isEmpty) display = '0';
      });
    } catch (e) {
      setState(() => display = 'Error');
    }
  }

  double factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
  }

  void convertKmToMile() {
    try {
      double km = double.parse(_kmController.text);
      double miles = km * 0.621371;
      setState(() {
        _kmResult = '${_kmController.text} কিমি = ${miles.toStringAsFixed(2)} মাইল';
      });
      history.insert(0, '${_kmController.text} km = ${miles.toStringAsFixed(2)} miles');
    } catch (e) {
      setState(() => _kmResult = 'Error');
    }
  }

  void convertCelToFar() {
    try {
      double cel = double.parse(_celController.text);
      double far = (cel * 9 / 5) + 32;
      setState(() {
        _celResult = '${_celController.text}°C = ${far.toStringAsFixed(2)}°F';
      });
      history.insert(0, '${_celController.text}°C = ${far.toStringAsFixed(2)}°F');
    } catch (e) {
      setState(() => _celResult = 'Error');
    }
  }

  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _celController = TextEditingController();
  String _kmResult = '';
  String _celResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧮 স্মার্ট ক্যালকুলেটর'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ব্যানার অ্যাড
          if (bannerAdLoaded)
            Container(
              alignment: Alignment.center,
              child: AdWidget(ad: bannerAd!),
              width: bannerAd!.size.width.toDouble(),
              height: bannerAd!.size.height.toDouble(),
            ),

          // মেইন কন্টেন্ট
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ডিসপ্লে
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        display,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ট্যাব
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTabButton('বেসিক', 0),
                          const SizedBox(width: 10),
                          _buildTabButton('বৈজ্ঞানিক', 1),
                          const SizedBox(width: 10),
                          _buildTabButton('রূপান্তর', 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // কন্টেন্ট
                    if (tabIndex == 0) _buildBasicCalculator(),
                    if (tabIndex == 1) _buildScientificCalculator(),
                    if (tabIndex == 2) _buildConverter(),

                    const SizedBox(height: 20),

                    // ইতিহাস
                    if (history.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📋 ইতিহাস',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...history.take(10).map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 13),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    return ElevatedButton(
      onPressed: () => setState(() => tabIndex = index),
      style: ElevatedButton.styleFrom(
        backgroundColor: tabIndex == index ? Colors.indigo : Colors.grey[200],
        foregroundColor: tabIndex == index ? Colors.white : Colors.grey[700],
      ),
      child: Text(label),
    );
  }

  Widget _buildBasicCalculator() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildButton('AC', Colors.red, () => clearDisplay(), columnSpan: 2),
        _buildButton('÷', Colors.indigo, () => appendOperator('÷')),
        _buildButton('×', Colors.indigo, () => appendOperator('×')),
        _buildButton('7', Colors.grey[300]!, () => appendNumber('7')),
        _buildButton('8', Colors.grey[300]!, () => appendNumber('8')),
        _buildButton('9', Colors.grey[300]!, () => appendNumber('9')),
        _buildButton('−', Colors.indigo, () => appendOperator('-')),
        _buildButton('4', Colors.grey[300]!, () => appendNumber('4')),
        _buildButton('5', Colors.grey[300]!, () => appendNumber('5')),
        _buildButton('6', Colors.grey[300]!, () => appendNumber('6')),
        _buildButton('+', Colors.indigo, () => appendOperator('+')),
        _buildButton('1', Colors.grey[300]!, () => appendNumber('1')),
        _buildButton('2', Colors.grey[300]!, () => appendNumber('2')),
        _buildButton('3', Colors.grey[300]!, () => appendNumber('3')),
        _buildButton('%', Colors.orange, () => calculatePercentage()),
        _buildButton('0', Colors.grey[300]!, () => appendNumber('0'), columnSpan: 2),
        _buildButton('.', Colors.grey[300]!, () => appendNumber('.')),
        _buildButton('=', Colors.green, () => calculate(), columnSpan: 2),
      ],
    );
  }

  Widget _buildScientificCalculator() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildButton('√', Colors.orange, () => scientificFunction('sqrt')),
        _buildButton('x²', Colors.orange, () => scientificFunction('square')),
        _buildButton('1/x', Colors.orange, () => scientificFunction('reciprocal')),
        _buildButton('n!', Colors.orange, () => scientificFunction('factorial')),
        _buildButton('sin', Colors.orange, () => scientificFunction('sin')),
        _buildButton('cos', Colors.orange, () => scientificFunction('cos')),
        _buildButton('tan', Colors.orange, () => scientificFunction('tan')),
        _buildButton('log', Colors.orange, () => scientificFunction('log')),
        _buildButton('ln', Colors.orange, () => scientificFunction('ln')),
        _buildButton('π', Colors.orange, () => scientificFunction('pi')),
        _buildButton('e', Colors.orange, () => scientificFunction('exp')),
        _buildButton('AC', Colors.red, () => clearDisplay(), columnSpan: 2),
        _buildButton('=', Colors.green, () => calculate(), columnSpan: 2),
      ],
    );
  }

  Widget _buildConverter() {
    return Column(
      children: [
        TextField(
          controller: _kmController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'কিমি',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: convertKmToMile,
          child: const Text('কিমি → মাইল'),
        ),
        if (_kmResult.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _kmResult,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 30),
        TextField(
          controller: _celController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '°C',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: convertCelToFar,
          child: const Text('°C → °F'),
        ),
        if (_celResult.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _celResult,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildButton(String label, Color bgColor, VoidCallback onPressed,
      {int columnSpan = 1}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: bgColor == Colors.grey[300] ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    interstitialAd?.dispose();
    _kmController.dispose();
    _celController.dispose();
    super.dispose();
  }
}
