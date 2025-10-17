import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const DealOrNotApp());
}

class DealOrNotApp extends StatelessWidget {
  const DealOrNotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DealOptionsProvider()),
      ],
      child: MaterialApp(
        title: 'Deal or Not',
        home: const DealOrNotHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

enum UnitType { oz, g, lbs, kg, ml, l }

double convertToBase(UnitType unit, double value) {
  // All weight units to grams, all volume units to milliliters
  switch (unit) {
    case UnitType.oz:
      return value * 28.3495; // oz to grams
    case UnitType.lbs:
      return value * 453.592; // lbs to grams
    case UnitType.kg:
      return value * 1000.0; // kg to grams
    case UnitType.g:
      return value; // grams
    case UnitType.ml:
      return value; // milliliters
    case UnitType.l:
      return value * 1000.0; // liters to milliliters
  }
}

String unitTypeLabel(UnitType unit) {
  switch (unit) {
    case UnitType.oz:
      return "oz";
    case UnitType.lbs:
      return "lbs";
    case UnitType.kg:
      return "kg";
    case UnitType.g:
      return "g";
    case UnitType.ml:
      return "ml";
    case UnitType.l:
      return "l";
  }
}

class DealOptionsProvider extends ChangeNotifier {
  final List<DealOptionData> options = [DealOptionData(), DealOptionData()];
  int get maxOptions => 10;

  void updateOption(int index, DealOptionData data) {
    options[index] = data;
    notifyListeners();
  }

  void addOption() {
    if (options.length < maxOptions) {
      options.add(DealOptionData());
      notifyListeners();
    }
  }

  void removeOption(int index) {
    if (options.length > 2 && index >= 2 && index < options.length) {
      options.removeAt(index);
      notifyListeners();
    }
  }

  // Returns the difference for the option at the given index
  // Returns null if the option is incomplete or if there are no other complete options
  // Positive difference means more expensive than best
  // Negative difference means this is the best (or tied for best)
  double? getPriceDifference(int index) {
    final option = options[index];
    if (!option.isComplete()) {
      return null;
    }

    final currentPrice = option.getPerUnitPrice()!;
    
    // Get all complete options with their per-unit prices
    final List<double> allPrices = [];
    for (var opt in options) {
      if (opt.isComplete()) {
        allPrices.add(opt.getPerUnitPrice()!);
      }
    }

    if (allPrices.isEmpty) {
      return null;
    }

    allPrices.sort();
    final bestPrice = allPrices.first;
    
    if (currentPrice == bestPrice) {
      // This is the best deal, show difference from next best
      if (allPrices.length > 1) {
        final nextBestPrice = allPrices[1];
        return -(nextBestPrice - bestPrice); // Negative to indicate best
      } else {
        return 0.0; // Only one complete option
      }
    } else {
      // Not the best deal, show difference from best
      return currentPrice - bestPrice;
    }
  }
}

class DealOptionData {
  String? name;
  int? quantity;
  double? amount;
  UnitType unit;
  double? price;
  File? image;
  String? barcode;

  DealOptionData({
    this.name,
    this.quantity,
    this.amount,
    this.unit = UnitType.oz,
    this.price,
    this.image,
    this.barcode,
  });

  DealOptionData copyWith({
    String? name,
    int? quantity,
    double? amount,
    UnitType? unit,
    double? price,
    File? image,
    String? barcode,
  }) {
    return DealOptionData(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      image: image ?? this.image,
      barcode: barcode ?? this.barcode,
    );
  }

  // Returns null if any required field is missing
  double? getPerUnitPrice() {
    if (price == null || amount == null || quantity == null) {
      return null;
    }
    double baseAmount = convertToBase(unit, amount!);
    return price! / (baseAmount * quantity!);
  }

  bool isComplete() {
    return price != null && amount != null && quantity != null;
  }
}

class DealOrNotHomePage extends StatefulWidget {
  const DealOrNotHomePage({super.key});

  @override
  State<DealOrNotHomePage> createState() => _DealOrNotHomePageState();
}

class _DealOrNotHomePageState extends State<DealOrNotHomePage> {
  final ScrollController _scrollController = ScrollController();

  void scrollToNewItem(int newItemIndex, BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final cardWidth = screenWidth * 0.85 + 24;
      final addItemWidth = screenWidth * 0.6 + 24;
      final visibleWidth = screenWidth;

      double offset = cardWidth * newItemIndex - (visibleWidth - cardWidth) / 2;
      double maxOffset = _scrollController.position.maxScrollExtent - addItemWidth * 0.4;
      if (offset > maxOffset) offset = maxOffset;
      if (offset < 0) offset = 0;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  String getComparison(DealOptionData a, DealOptionData b) {
    if (a.price == null || a.amount == null || a.quantity == null || b.price == null || b.amount == null || b.quantity == null) {
      return "Please fill in all fields for both options.";
    }
    // Normalize to price per base unit per item
    double aBaseAmount = convertToBase(a.unit, a.amount!);
    double bBaseAmount = convertToBase(b.unit, b.amount!);
    double aPerUnit = a.price! / (aBaseAmount * (a.quantity ?? 1));
    double bPerUnit = b.price! / (bBaseAmount * (b.quantity ?? 1));

    if (aPerUnit < bPerUnit) {
      return "Option 1 is the better deal";
    } else if (bPerUnit < aPerUnit) {
      return "Option 2 is the better deal";
    } else {
      return "Both options are the same deal";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Deal or Not', style: TextStyle(color: Colors.deepPurple)),
      ),
      body: Consumer<DealOptionsProvider>(
        builder: (context, optionsProvider, child) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: optionsProvider.options.length + (optionsProvider.options.length < optionsProvider.maxOptions ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == optionsProvider.options.length && optionsProvider.options.length < optionsProvider.maxOptions) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        child: AddItemCard(
                          onAdd: () {
                            optionsProvider.addOption();
                            scrollToNewItem(optionsProvider.options.length - 1, context);
                          },
                        ),
                      );
                    }
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: Stack(
                        children: [
                          DealOptionCard(
                            index: index,
                            data: optionsProvider.options[index],
                            onChanged: (data) => optionsProvider.updateOption(index, data),
                          ),
                          if (index >= 2)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => optionsProvider.removeOption(index),
                                child: const CircleAvatar(
                                  radius: 13,
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final deals = optionsProvider.options;
                  String result;
                  if (deals.length >= 2) {
                    result = getComparison(deals[0], deals[1]);
                  } else {
                    result = "Please fill in all fields for both options.";
                  }
                  showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Deal Result"), content: Text(result)));
                },
                child: const Text('Compare Deals'),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class AddItemCard extends StatelessWidget {
  final VoidCallback onAdd;
  const AddItemCard({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Add Item', style: TextStyle(fontSize: 16, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.add, size: 36, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DealOptionCard extends StatefulWidget {
  final int index;
  final DealOptionData data;
  final ValueChanged<DealOptionData> onChanged;

  const DealOptionCard({super.key, required this.index, required this.data, required this.onChanged});

  @override
  State<DealOptionCard> createState() => _DealOptionCardState();
}

class _DealOptionCardState extends State<DealOptionCard> {
  late TextEditingController nameController;
  late TextEditingController quantityController;
  late TextEditingController amountController;
  late TextEditingController priceController;
  UnitType unitType = UnitType.oz;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data.name ?? "");
    quantityController = TextEditingController(text: widget.data.quantity?.toString() ?? "");
    amountController = TextEditingController(text: widget.data.amount?.toString() ?? "");
    priceController = TextEditingController(text: widget.data.price?.toString() ?? "");
    unitType = widget.data.unit;
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    amountController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void updateParent() {
    widget.onChanged(
      widget.data.copyWith(
        name: nameController.text,
        quantity: int.tryParse(quantityController.text),
        amount: double.tryParse(amountController.text),
        unit: unitType,
        price: double.tryParse(priceController.text),
      ),
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        widget.onChanged(
          widget.data.copyWith(
            name: nameController.text,
            quantity: int.tryParse(quantityController.text),
            amount: double.tryParse(amountController.text),
            unit: unitType,
            price: double.tryParse(priceController.text),
            image: File(pickedFile.path),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DealOptionsProvider>(
      builder: (context, optionsProvider, child) {
        final difference = optionsProvider.getPriceDifference(widget.index);
        
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Option ${widget.index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple)),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  onChanged: (_) => updateParent(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'QTY'),
                  onChanged: (_) => updateParent(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        onChanged: (_) => updateParent(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<UnitType>(
                      value: unitType,
                      onChanged: (UnitType? newValue) {
                        setState(() {
                          unitType = newValue!;
                          updateParent();
                        });
                      },
                      items: UnitType.values.map((UnitType unit) {
                        return DropdownMenuItem<UnitType>(
                          value: unit,
                          child: Text(unitTypeLabel(unit)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                  onChanged: (_) => updateParent(),
                ),
                if (difference != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Difference: ${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: difference < 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Add Photo'),
                    ),
                    if (widget.data.image != null)
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(widget.data.image!, fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}