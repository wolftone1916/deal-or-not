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
  switch (unit) {
    case UnitType.oz:
      return value * 28.3495;
    case UnitType.lbs:
      return value * 453.592;
    case UnitType.kg:
      return value * 1000.0;
    case UnitType.g:
      return value;
    case UnitType.ml:
      return value;
    case UnitType.l:
      return value * 1000.0;
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

String displayUnitName(UnitType unit) {
  switch (unit) {
    case UnitType.oz:
    case UnitType.lbs:
    case UnitType.kg:
    case UnitType.g:
      return "gram";
    case UnitType.ml:
    case UnitType.l:
      return "milliliter";
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

  Tuple2<int?, List<double?>> getDealComparisons(List<DealOptionData> deals) {
    List<double?> pricesPerUnit = deals.map((deal) {
      if (deal.price == null || deal.amount == null || deal.quantity == null || deal.amount == 0 || deal.quantity == 0) {
        return null;
      }
      double baseAmount = convertToBase(deal.unit, deal.amount!);
      double totalBase = baseAmount * deal.quantity!;
      return deal.price! / totalBase;
    }).toList();

    int? bestIndex;
    double? bestValue;
    for (int i = 0; i < pricesPerUnit.length; i++) {
      if (pricesPerUnit[i] != null) {
        if (bestValue == null || pricesPerUnit[i]! < bestValue) {
          bestValue = pricesPerUnit[i];
          bestIndex = i;
        }
      }
    }

    List<double?> differences = pricesPerUnit.map((price) {
      if (bestValue == null || price == null) return null;
      return price - bestValue;
    }).toList();

    return Tuple2(bestIndex, differences);
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
          final deals = optionsProvider.options;
          final Tuple2<int?, List<double?>> comparison = getDealComparisons(deals);

          return Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: deals.length + (deals.length < optionsProvider.maxOptions ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == deals.length && deals.length < optionsProvider.maxOptions) {
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
                    final displayUnit = displayUnitName(deals[index].unit);
                    final bestIndex = comparison.item1;
                    final differences = comparison.item2;

                    Widget resultWidget;
                    if (deals[index].price == null || deals[index].amount == null || deals[index].quantity == null || deals[index].amount == 0 || deals[index].quantity == 0) {
                      resultWidget = Text(
                        "Please fill all fields above.",
                        style: TextStyle(fontSize: 22, color: Colors.grey, fontWeight: FontWeight.bold),
                      );
                    } else if (differences[index] != null) {
                      double diff = differences[index]!;
                      double pricePerUnit = diff + (bestIndex != null ? differences[bestIndex]! : 0.0);
                      String formattedDiff = "\$\${diff.abs().toStringAsFixed(2)} per $displayUnit";
                      String formattedPrice = "\$\${pricePerUnit.toStringAsFixed(2)} per $displayUnit";
                      TextStyle style = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

                      if (bestIndex == index) {
                        double nextBestDiff = 0.0;
                        for (int i = 0; i < differences.length; i++) {
                          if (i != index && differences[i] != null && (nextBestDiff == 0.0 || differences[i]! < nextBestDiff)) {
                            nextBestDiff = differences[i]!;
                          }
                        }
                        resultWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Best Deal!",
                              style: style.copyWith(color: Colors.green[700]),
                            ),
                            if (nextBestDiff > 0.0)
                              Text(
                                "You save \$\${nextBestDiff.toStringAsFixed(2)} per $displayUnit compared to other options.",
                                style: style.copyWith(color: Colors.green[700]),
                              ),
                            Text(
                              "Unit price: $formattedPrice",
                              style: style.copyWith(color: Colors.green[700], fontSize: 18, fontWeight: FontWeight.normal),
                            ),
                          ],
                        );
                      } else {
                        resultWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "More expensive by $formattedDiff compared to the best deal.",
                              style: style.copyWith(color: Colors.red[700]),
                            ),
                            Text(
                              "Unit price: $formattedPrice",
                              style: style.copyWith(color: Colors.red[700], fontSize: 18, fontWeight: FontWeight.normal),
                            ),
                          ],
                        );
                      }
                    } else {
                      resultWidget = SizedBox.shrink();
                    }

                    return Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: Stack(
                        children: [
                          DealOptionCard(
                            index: index,
                            data: deals[index],
                            onChanged: (data) => optionsProvider.updateOption(index, data),
                            resultWidget: resultWidget,
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
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (deals.length < 2) {
                    showDialog(context: context, builder: (_) => const AlertDialog(title: Text("Deal Result"), content: Text("Please fill in all fields for both options.")));
                    return;
                  }
                  final Tuple2<int?, List<double?>> comparison = getDealComparisons(deals);
                  final bestIndex = comparison.item1;
                  final differences = comparison.item2;
                  String result;
                  if (bestIndex == null) {
                    result = "Please fill in all fields for both options.";
                  } else {
                    final displayUnit = displayUnitName(deals[bestIndex].unit);
                    result = "Option \\$bestIndex! + 1 is the best deal!\nUnit price: \\$\${(differences[bestIndex]! + (differences[bestIndex] ?? 0.0)).toStringAsFixed(2)} per $displayUnit";
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

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple2(this.item1, this.item2);
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
  final Widget? resultWidget;

  const DealOptionCard({
    super.key,
    required this.index,
    required this.data,
    required this.onChanged,
    this.resultWidget,
  });

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
              style: const TextStyle(fontSize: 18),
              onChanged: (_) => updateParent(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'QTY'),
              style: const TextStyle(fontSize: 18),
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
                    style: const TextStyle(fontSize: 18),
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
                      child: Text(unitTypeLabel(unit), style: const TextStyle(fontSize: 18)),
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
              style: const TextStyle(fontSize: 18),
              onChanged: (_) => updateParent(),
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 18),
            if (widget.resultWidget != null) widget.resultWidget!,
          ],
        ),
      ),
    );
  }
}