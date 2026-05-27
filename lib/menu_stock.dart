import 'package:flutter/material.dart';
import 'transaction.dart';
import 'product.dart';

class MenuStockScreen extends StatefulWidget {
  final int stockNumber; // รับเบอร์คลัง (1, 2, 3...)
  final String stockName; // รับชื่อคลัง
  final Color themeColor; // รับสีธีมประจำคลัง

  const MenuStockScreen({
    super.key, 
    required this.stockNumber, 
    required this.stockName,
    required this.themeColor,
  });

  @override
  State<MenuStockScreen> createState() => _MenuStockScreenState();
}

class _MenuStockScreenState extends State<MenuStockScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        title: Text(widget.stockName), // ชื่อจะเปลี่ยนไปตามที่ส่งมา
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // กดไปหน้าจัดการสินค้า พร้อมส่ง stockNumber ไปด้วย
          _buildMenuCard(
            context: context,
            title: 'เบิก/เพิ่มสินค้า',
            icon: Icons.inventory_2,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProductPage(stockNumber: widget.stockNumber)),
            ),
          ),
          _buildMenuCard(
            context: context,
            title: 'ข้อมูลการทำรายการ',
            icon: Icons.history,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              // ใน TransactionPage คุณอาจจะต้องปรับให้รับ stockNumber ไปฟิลเตอร์ด้วยเช่นกัน
              MaterialPageRoute(builder: (context) => TransactionPage(stockNumber: widget.stockNumber)), 
            ),
          ),
        ],
      ),
    );
  }

  // แยก Widget ปุ่มออกมาให้ดูสะอาดขึ้น
  Widget _buildMenuCard({required BuildContext context, required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}