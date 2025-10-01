import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';

void main() {
  runApp(DealOrNotApp());
}

class DealOrNotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deal or Not',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DealComparisonPage(),
    );
  }
}

class DealComparisonPage extends StatefulWidget {
  @override
  _DealComparisonPageState createState() => _DealComparisonPageState();
}

class _DealComparisonPageState extends State<DealComparisonPage> {
  final _formKey = GlobalKey<FormState>();
  final price1Controller = TextEditingController();
  final amount1Controller = TextEditingController();
  final price2Controller = TextEditingController();
  final amount2Controller = TextEditingController();

  String result = '';
  String? barcode1;
  String? barcode2;
  File? photo1;
  File? photo2;

  Future<void> scanBarcode(int deal) async {
    String? scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(),
      ),
    );
    if (scannedCode != null) {
      setState(() {
        if (deal == 1)
          barcode1 = scannedCode;
        else
          barcode2 = scannedCode;
      });
    }
  }

  Future<void> pickPhoto(int deal) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (deal == 1)
          photo1 = File(picked.path);
        else
          photo2 = File(picked.path);
      });
    }
  }

  void compareDeals() {
    if (_formKey.currentState!.validate()) {
      double price1 = double.parse(price1Controller.text);
      double amount1 = double.parse(amount1Controller.text);
      double price2 = double.parse(price2Controller.text);
      double amount2 = double.parse(amount2Controller.text);

      double unitPrice1 = price1 / amount1;
      double unitPrice2 = price2 / amount2;

      String betterDeal;
      if (unitPrice1 < unitPrice2) {
        betterDeal = 'Deal 1 is better!';
      } else if (unitPrice1 > unitPrice2) {
        betterDeal = 'Deal 2 is better!';
      } else {
        betterDeal = 'Both deals are the same!';
      }

      setState(() {
        result =
            'Deal 1 unit price: \$${unitPrice1.toStringAsFixed(2)}\nDeal 2 unit price: \$${unitPrice2.toStringAsFixed(2)}\n$betterDeal';
      });
    }
  }

  @override
  void dispose() {
    price1Controller.dispose();
    amount1Controller.dispose();
    price2Controller.dispose();
    amount2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Deal or Not')), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Enter the price and amount for each deal:',
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: price1Controller,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price 1',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: amount1Controller,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Amount 1',
                            prefixIcon: Icon(Icons.shopping_cart),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.qr_code_scanner),
                              label: Text(barcode1 == null
                                  ? "Scan Barcode"
                                  : "Barcode: $barcode1"),
                              onPressed: () => scanBarcode(1),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton.icon(
                              icon: Icon(Icons.photo_camera),
                              label: Text(photo1 == null
                                  ? "Attach Photo"
                                  : "Photo Added"),
                              onPressed: () => pickPhoto(1),
                            ),
                          ],
                        ),
                        if (photo1 != null)
                          Image.file(photo1!, width: 80, height: 80),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: price2Controller,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price 2',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: amount2Controller,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Amount 2',
                            prefixIcon: Icon(Icons.shopping_cart),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.qr_code_scanner),
                              label: Text(barcode2 == null
                                  ? "Scan Barcode"
                                  : "Barcode: $barcode2"),
                              onPressed: () => scanBarcode(2),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton.icon(
                              icon: Icon(Icons.photo_camera),
                              label: Text(photo2 == null
                                  ? "Attach Photo"
                                  : "Photo Added"),
                              onPressed: () => pickPhoto(2),
                            ),
                          ],
                        ),
                        if (photo2 != null)
                          Image.file(photo2!, width: 80, height: 80),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: compareDeals,
                child: Text('Compare'),
              ),
              SizedBox(height: 20),
              Text(
                result,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Barcode Scanner Page ---
class BarcodeScannerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan Barcode')), 
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          Navigator.of(context).pop(barcode.rawValue);
        },
      ),
    );
  }
}