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
  double? price;
  double? amount;
  File? image;
  String? barcode;

  DealOptionData({this.name, this.price, this.amount, this.image, this.barcode});
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
      final cardWidth = screenWidth * 0.85 + 24; // card + margin
      final addItemWidth = screenWidth * 0.6 + 24;
      final visibleWidth = screenWidth;

      // Center the new card, but keep some of AddItem showing
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
                    // Add Item Card
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
                    // Deal Option Cards
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
                  if (deals.length >= 2 && deals[0].price != null && deals[0].amount != null && deals[1].price != null && deals[1].amount != null) {
                    double value0 = deals[0].price! / deals[0].amount!;
                    double value1 = deals[1].price! / deals[1].amount!;
                    result = value0 < value1 ? "Option 1 is the better deal" : "Option 2 is the better deal";
                  } else {
                    result = "Please fill in price and amount for both options.";
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
  late TextEditingController priceController;
  late TextEditingController amountController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data.name);
    priceController = TextEditingController(text: widget.data.price?.toString() ?? '');
    amountController = TextEditingController(text: widget.data.amount?.toString() ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        widget.onChanged(
          DealOptionData(
            name: nameController.text,
            price: double.tryParse(priceController.text),
            amount: double.tryParse(amountController.text),
            image: File(pickedFile.path),
            barcode: widget.data.barcode,
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
              onChanged: (_) => widget.onChanged(
                DealOptionData(
                  name: nameController.text,
                  price: double.tryParse(priceController.text),
                  amount: double.tryParse(amountController.text),
                  image: widget.data.image,
                  barcode: widget.data.barcode,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
              onChanged: (_) => widget.onChanged(
                DealOptionData(
                  name: nameController.text,
                  price: double.tryParse(priceController.text),
                  amount: double.tryParse(amountController.text),
                  image: widget.data.image,
                  barcode: widget.data.barcode,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
              onChanged: (_) => widget.onChanged(
                DealOptionData(
                  name: nameController.text,
                  price: double.tryParse(priceController.text),
                  amount: double.tryParse(amountController.text),
                  image: widget.data.image,
                  barcode: widget.data.barcode,
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
  }
}