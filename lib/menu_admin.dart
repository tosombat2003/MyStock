import 'package:flutter/material.dart';
import 'user_manage.dart';
import 'product_manage.dart';


class MenuAdminScreen extends StatefulWidget {
  const MenuAdminScreen({super.key,});

  @override
  MenuAdminScreenState createState() => MenuAdminScreenState();
}

class MenuAdminScreenState extends State<MenuAdminScreen> {
  Future<void> _refreshData() async {
    await Future.delayed(Duration(seconds: 2)); // จำลองการโหลดข้อมูลใหม่
    setState(() {
      print("รีเฟรชข้อมูลแล้ว!"); // ลองให้แสดงผลใน console
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text('Admin'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserManagePage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color:Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'จัดการ user',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductManagePage(stockNumber: 1, stockName: 'คลัง 1', themeColor: Colors.red),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'จัดการสินค้าคลัง 1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductManagePage(stockNumber: 2, stockName: 'คลัง 2', themeColor: Colors.pinkAccent),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color:  Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'จัดการสินค้าคลัง 2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductManagePage(stockNumber: 3, stockName: 'ห้องเย็น', themeColor: Colors.teal),
                    //แก้ด้วย
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'จัดการสินค้าห้องเย็น',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
