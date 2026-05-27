import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductPage extends StatefulWidget {
  final int stockNumber;

  const ProductPage({super.key, required this.stockNumber});

  @override
  ProductPageState createState() => ProductPageState();
}

class ProductPageState extends State<ProductPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> products = [];
  Map<int, int> productQuantities = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // ดึงข้อมูลสินค้า
  // ดึงข้อมูลสินค้าและเรียงลำดับตาม id_pro
  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    final response = await supabase
        .from('products')
        .select()
        .eq('stock_number', widget.stockNumber)
        .order('id_pro', ascending: true); // เพิ่มการเรียงลำดับตาม id_pro

    setState(() {
      isLoading = false;
      products = response;
      for (var product in products) {
        productQuantities[product['id_pro']] =
            product['amount']; // ดึงจำนวนสินค้าที่มี
      }
    });
  }

  // ฟังก์ชันแสดงข้อความแจ้งเตือน
  void showStockDialog({
    required int productId,
    required String productName,
    required bool isIncrement, // true = เพิ่มสินค้า, false = เบิกสินค้า
  }) {
    int selectedAmount = 1; // ตัวแปรเก็บจำนวนเริ่มต้น
    TextEditingController amountController =
        TextEditingController(text: selectedAmount.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
            return AlertDialog(
              title: Text(isIncrement ? "เพิ่มสินค้า" : "เบิกสินค้า"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      "คุณต้องการ${isIncrement ? 'เพิ่ม' : 'เบิก'} '$productName' จำนวนเท่าไหร่?"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (selectedAmount > 1) {
                            setState(() {
                              selectedAmount--;
                              amountController.text = selectedAmount.toString();
                            });
                          }
                        },
                        icon: Icon(Icons.remove),
                      ),
                      // TextField สำหรับแก้ไขตัวเลข
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: amountController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            int? newAmount = int.tryParse(value);
                            if (newAmount != null && newAmount > 0) {
                              setState(() {
                                selectedAmount = newAmount;
                              });
                            } else if (value.isEmpty) {
                              setState(() {
                                selectedAmount = 0;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            border: UnderlineInputBorder(),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedAmount++;
                            amountController.text = selectedAmount.toString();
                          });
                        },
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("ยกเลิก"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (isIncrement) {
                      confirmIncrement(productId, productName, selectedAmount);
                    } else {
                      confirmDecrement(productId, productName, selectedAmount);
                    }
                  },
                  child: Text("ยืนยัน"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> confirmIncrement(int productId, String productName, int amount) async {
    try {
      final currentAmount = productQuantities[productId] ?? 0;
      final newAmount = currentAmount + amount;

      final response = await supabase
          .from('products')
          .update({'amount': newAmount}).eq('id_pro', productId);

      if (response == null) {
        setState(() {
          productQuantities[productId] = newAmount;
        });
        _recordTransaction(productId, productName, amount, 'เพิ่ม'); // บันทึกการทำรายการ
        showAlert('เพิ่ม $productName จำนวน $amount สำเร็จ');
        fetchProducts();
      } else {
        showAlert('เกิดข้อผิดพลาดในการเพิ่ม $productName');
      }
    } catch (e) {
      showAlert('เกิดข้อผิดพลาด: $e');
    }
  }

  // เบิกสินค้าในฐานข้อมูล
  Future<void> confirmDecrement(int productId, String productName, int amount) async {
    try {
      final currentAmount = productQuantities[productId] ?? 0;

      if (currentAmount >= amount && currentAmount - amount >= 0) {
        final newAmount = currentAmount - amount;

        final response = await supabase
            .from('products')
            .update({'amount': newAmount}).eq('id_pro', productId);

        if (response == null) {
          setState(() {
            productQuantities[productId] = newAmount;
          });
          _recordTransaction(productId, productName, amount, 'เบิก'); // บันทึกการทำรายการ
          showAlert('เบิก $productName จำนวน $amount สำเร็จ');
          fetchProducts();
        } else {
          showAlert('เกิดข้อผิดพลาดในการเบิก $productName');
        }
      } else {
        showAlert('สินค้าไม่เพียงพอสำหรับการเบิก');
      }
    } catch (e) {
      showAlert('เกิดข้อผิดพลาด: $e');
    }
  }

 // บันทึกการทำรายการ
Future<void> _recordTransaction(
    int productId, String productName, int amount, String transactionType) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId'); // ดึง userId
    if (userId == null) {
      showAlert('ไม่พบข้อมูลผู้ใช้');
      return;
    }

    // 🔥 ดึงชื่อผู้ใช้จากตาราง users
    final userResponse = await supabase
        .from('users')
        .select('name')
        .eq('id', userId)
        .maybeSingle();

    final userName = userResponse?['name'] ?? 'Unknown'; // ถ้าไม่เจอชื่อ ใช้ 'Unknown'

    final now = DateTime.now();

    final transaction = {
      'name_pro': productName,
      'user_name': userName,
      'describe': transactionType,
      'amount': amount,
      'stock_number': widget.stockNumber,
      'date': now.toIso8601String().split('T')[0], // วันที่
      'time': now.toIso8601String().split('T')[1].split('.')[0], // เวลา
    };

    final response = await supabase.from('transaction').insert(transaction);

    if (response == null) {
      // สำเร็จในการบันทึก
    } else {
      showAlert('เกิดข้อผิดพลาดในการบันทึกการทำรายการ');
    }
  } catch (e) {
    showAlert('เกิดข้อผิดพลาด: $e');
  }
}

  // แสดงข้อความแจ้งเตือน
  void showAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('เบิก/เพิ่มสินค้า')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // สเต็ป 1: ถ้า isLoading เป็น true ให้หมุนติ้วๆ
          : products.isEmpty 
              ? const Center( // สเต็ป 2: ถ้าโหลดเสร็จแล้ว แต่ไม่มีสินค้า ให้ขึ้นข้อความ
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
              : GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final productId = product['id_pro'];
                final productName = product['name_pro'];
                final quantity = productQuantities[productId] ?? 0;
                final unit = product['unit'] ?? '';
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: product['pic'] != null &&
                                  product['pic'].isNotEmpty
                              ? Image.network(
                                  product['pic'],
                                  fit: BoxFit.cover,
                                  height: 100,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child; // เมื่อโหลดเสร็จแล้วแสดงภาพ
                                    } else {
                                      return Center(
                                          child:
                                              CircularProgressIndicator()); // แสดงวงกลมโหลด
                                    }
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons
                                            .image_not_supported, // แสดงไอคอนหากไม่สามารถโหลดรูป
                                        color: Colors.grey,
                                        size: 50,
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                      'ไม่มีรูปภาพ'), // แสดงข้อความเมื่อไม่มีรูป
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Text(
                              productName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'คงเหลือ: $quantity $unit',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => showStockDialog(
                              productId: productId,
                              productName: productName,
                              isIncrement: false,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .red, // เปลี่ยนสีพื้นหลังของปุ่ม 'เบิก' เป็นสีแดง
                              foregroundColor:
                                  Colors.white, // เปลี่ยนสีข้อความในปุ่ม
                            ),
                            child: Text("เบิก"),
                          ),
                          ElevatedButton(
                            onPressed: () => showStockDialog(
                              productId: productId,
                              productName: productName,
                              isIncrement: true,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .green, // เปลี่ยนสีพื้นหลังของปุ่ม 'เติม' เป็นสีเขียว
                              foregroundColor:
                                  Colors.white, // เปลี่ยนสีข้อความในปุ่ม
                            ),
                            child: Text("เพิ่ม"),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
