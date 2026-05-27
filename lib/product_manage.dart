import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductManagePage extends StatefulWidget {
  const ProductManagePage({super.key, required this.stockNumber,required this.stockName, required this.themeColor});

  final int stockNumber;
  final String stockName;
  final Color themeColor;

  @override
  ProductManagePageState createState() => ProductManagePageState();
}

class ProductManagePageState extends State<ProductManagePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> products = [];
  File? selectedImage; // ใช้ตัวแปร State เก็บภาพ
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });
    final response = await supabase.from('products').select().eq('stock_number', widget.stockNumber);
    setState(() {
      isLoading = false;
      products = response;
    });
  }

  Future<String?> uploadImage(File image) async {
    final fileExt = image.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final storageResponse = await supabase.storage.from('products_pic').upload(fileName, image);

    if (storageResponse.isNotEmpty) {
      return supabase.storage.from('products_pic').getPublicUrl(fileName);
    }
    return null;
  }

  Future<void> deleteImage(String imageUrl) async {
    final filePath = Uri.parse(imageUrl).pathSegments.last;
    await supabase.storage.from('products_pic').remove([filePath]);
  }

  Future<void> addProduct(String name, File? image, int quantity, String unit) async {
    String? imageUrl;
    if (image != null) {
      imageUrl = await uploadImage(image);
    }

    await supabase.from('products').insert({
      'name_pro': name,
      'pic': imageUrl ?? '',
      'amount': quantity,
      'unit': unit,
      'stock_number' : widget.stockNumber
    });
    fetchProducts();
  }

  // 1. เพิ่ม String newName และ String newUnit เข้ามาในวงเล็บ
  Future<void> updateProduct(int id, String newName, int newQuantity, String newUnit, File? newImage, String? currentImageUrl) async {
    String? imageUrl;
    if (newImage != null) {
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        await deleteImage(currentImageUrl);
      }
      imageUrl = await uploadImage(newImage);
    }

    await supabase.from('products').update({
      'name_pro': newName, // ✅ เพิ่มการอัปเดตชื่อ
      'amount': newQuantity,
      'unit': newUnit,     // ✅ เพิ่มการอัปเดตหน่วย
      if (imageUrl != null) 'pic': imageUrl
    }).eq('id_pro', id);
    
    fetchProducts();
  }

  Future<void> deleteProduct(int id, String? imageUrl) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await deleteImage(imageUrl);
    }
    await supabase.from('products').delete().eq('id_pro', id);
    fetchProducts();
  }

  void confirmDelete(int id, String? imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("ยืนยันการลบ"),
          content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบสินค้านี้?"),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("ยกเลิก")),
            TextButton(
              onPressed: () {
                deleteProduct(id, imageUrl);
                Navigator.of(context).pop();
              },
              child: Text("ลบ", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

void showProductDialog({int? id, String? name, int? quantity, String? unit, String? currentPic}) {
  TextEditingController nameController = TextEditingController(text: name ?? "");
  TextEditingController quantityController = TextEditingController(text: quantity?.toString() ?? "");
  TextEditingController unitController = TextEditingController(text: unit ?? "");
  
  File? imageFile; // ใช้ตัวแปรนี้เก็บรูปใหม่ที่เลือกมา

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder( // ใช้ StatefulBuilder เพื่อให้ setState() ใช้ได้
        builder: (context, setState) {
          Future<void> pickImage() async {
            final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              setState(() {
                imageFile = File(pickedFile.path);
              });
            }
          }

          return AlertDialog(
            title: Text(id == null ? "เพิ่มสินค้าใหม่" : "แก้ไขสินค้า"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: nameController, decoration: InputDecoration(labelText: "ชื่อสินค้า")),
                  TextField(controller: quantityController, decoration: InputDecoration(labelText: "จำนวน"), keyboardType: TextInputType.number),
                  TextField(controller: unitController, decoration: InputDecoration(labelText: "หน่วย")),
                  SizedBox(height: 10),
                  // แสดงรูปภาพที่เลือก
                  if (imageFile != null)
                    Image.file(imageFile!, width: 100, height: 100, fit: BoxFit.cover)
                  // แสดงภาพจาก URL ถ้ามี (เฉพาะตอนแก้ไขสินค้า)
                  else if (currentPic != null && currentPic.isNotEmpty)
                    Image.network(currentPic, width: 100, height: 100, fit: BoxFit.cover)
                  else
                    Icon(Icons.image, size: 50), // แสดงไอคอนแทนถ้ายังไม่มีภาพ
                  
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: Icon(Icons.image),
                    label: Text("เลือกรูปภาพ"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("ยกเลิก")),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && quantityController.text.isNotEmpty && unitController.text.isNotEmpty) {
                    if (id == null) {
                      addProduct(nameController.text, imageFile, int.parse(quantityController.text), unitController.text);
                    } else {
                      updateProduct(
                        id, 
                        nameController.text, 
                        int.parse(quantityController.text), 
                        unitController.text, 
                        imageFile, 
                        currentPic
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: Text(id == null ? "เพิ่มสินค้า" : "บันทึก"),
              ),
            ],
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('จัดการสินค้า - ${widget.stockName}'), backgroundColor: widget.themeColor),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'ยังไม่มีสินค้าในคลัง',
                        style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: product['pic'] != null && product['pic'].isNotEmpty
                        ? Image.network(product['pic'], width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.image),
                    title: Text(product['name_pro']),
                    subtitle: Text("จำนวน: ${product['amount']} ${product['unit']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => showProductDialog(
                            id: product['id_pro'],
                            name: product['name_pro'],
                            quantity: product['amount'],
                            unit: product['unit'],
                            currentPic: product['pic'],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => confirmDelete(product['id_pro'], product['pic']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
