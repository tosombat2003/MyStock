import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key, this.stockNumber});
  final int? stockNumber;

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactions = [];
  int currentPage = 0;
  final int itemsPerPage = 12; 
  String userType = '';

  // ✅ 1. เพิ่มตัวแปรสำหรับเก็บชื่อสินค้าทั้งหมด และชื่อที่ถูกเลือกฟิลเตอร์
  List<String> _uniqueProductNames = [];
  List<String> _selectedProductFilters = [];

  @override
  void initState() {
    super.initState();
    _fetchUserType();
    _fetchTransactions();
  }

  Future<void> _fetchUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('userType') ?? '';
    });
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await supabase
          .from('transaction')
          .select('id, date, time, name_pro, user_name, describe, amount, stock_number')
          .order('id', ascending: false);

      if (response.isNotEmpty) {
        setState(() {
          transactions = response.map<Map<String, dynamic>>((t) {
            return {
              ...t,
              'date': t['date'] != null
                  ? DateFormat('dd-MM-yyyy').format(DateTime.parse(t['date']))
                  : '',
            };
          }).toList();

          // ✅ 2. ดึงชื่อสินค้าแบบไม่ซ้ำกัน ออกมาเก็บไว้ทำตัวเลือกฟิลเตอร์
          _uniqueProductNames = transactions
              .map((t) => t['name_pro']?.toString() ?? 'Unknown')
              .toSet()
              .toList();
          _uniqueProductNames.sort(); // เรียงลำดับตัวอักษรให้หาง่ายๆ
        });
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
  }

  Future<void> _deleteTransaction(int id) async {
    bool confirmDelete = await _showDeleteConfirmation();
    if (confirmDelete) {
      await supabase.from('transaction').delete().eq('id', id);
      _fetchTransactions();
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'ยืนยันการลบ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('แน่ใจหรือไม่ว่าต้องการลบรายการนี้?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ลบ', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _editTransaction(int id) {
    final transaction = transactions.firstWhere((t) => t['id'] == id);
    TextEditingController nameController =
        TextEditingController(text: transaction['name_pro']);
    TextEditingController userController =
        TextEditingController(text: transaction['user_name']);
    TextEditingController amountController =
        TextEditingController(text: transaction['amount'].toString());

    List<String> options = ['เบิก', 'เพิ่ม'];
    options.sort((a, b) => a == transaction['describe'] ? -1 : 1);
    String selectedDescribe = transaction['describe'] ?? 'เบิก';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขรายการ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'สินค้า'),
            ),
            TextField(
              controller: userController,
              decoration: const InputDecoration(labelText: 'ผู้ใช้'),
            ),
            DropdownButtonFormField<String>(
              value: selectedDescribe,
              items: options
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedDescribe = value;
                }
              },
              decoration: const InputDecoration(labelText: 'คำอธิบาย'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'จำนวน'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              await supabase.from('transaction').update({
                'name_pro': nameController.text,
                'user_name': userController.text,
                'describe': selectedDescribe,
                'amount': int.tryParse(amountController.text) ??
                    transaction['amount'],
              }).eq('id', id);
              _fetchTransactions();
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('คำแนะนำ'),
        content: RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.black),
            children: [
              TextSpan(
                  text: 'หากมีการแก้ไขจำนวนการเบิก/เพิ่มสินค้า ต้องเข้าไปแก้ไขจำนวนในหน้า '),
              TextSpan(
                text: 'จัดการสินค้า',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' ด้วย'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  // ✅ 3. ฟังก์ชันแสดงหน้าต่าง (Dialog) สำหรับเลือกติ๊กชื่อสินค้า
  void _showProductFilterDialog() {
    // ใช้ตัวแปรชั่วคราวเก็บค่าตอนที่กำลังติ๊ก เพื่อไม่ให้โหลดข้อมูลจนกว่าจะกด "ตกลง"
    List<String> tempSelected = List.from(_selectedProductFilters);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // StatefulBuilder ช่วยให้ Checkbox เปลี่ยนสถานะในป๊อปอัปได้
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('กรองตามชื่อสินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: _uniqueProductNames.isEmpty
                    ? const Text('ไม่มีข้อมูลสินค้า')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _uniqueProductNames.length,
                        itemBuilder: (context, index) {
                          final productName = _uniqueProductNames[index];
                          return CheckboxListTile(
                            title: Text(productName),
                            value: tempSelected.contains(productName),
                            activeColor: Colors.blueGrey,
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                if (value == true) {
                                  tempSelected.add(productName);
                                } else {
                                  tempSelected.remove(productName);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setStateDialog(() {
                      tempSelected.clear(); // ล้างการเลือกทั้งหมด
                    });
                  },
                  child: const Text('ล้างทั้งหมด', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedProductFilters = tempSelected; // อัปเดตตัวแปรหลัก
                      currentPage = 0; // รีเซ็ตหน้ากลับไปหน้าที่ 1
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('ตกลง', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
            icon: const Icon(Icons.calendar_today, size: 16),
            onPressed: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedStartDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                setState(() => selectedStartDate = pickedDate);
              }
            },
            label: Text(
              selectedStartDate != null
                  ? 'เริ่ม: ${DateFormat('dd/MM/yyyy').format(selectedStartDate!)}'
                  : 'เริ่ม',
            ),
          ),
          const SizedBox(width: 8),
          const Text('ถึง'),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
            icon: const Icon(Icons.calendar_today, size: 16),
            onPressed: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedEndDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                setState(() => selectedEndDate = pickedDate);
              }
            },
            label: Text(
              selectedEndDate != null
                  ? 'สิ้นสุด: ${DateFormat('dd/MM/yyyy').format(selectedEndDate!)}'
                  : 'สิ้นสุด',
            ),
          ),
          if (selectedStartDate != null || selectedEndDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                setState(() {
                  selectedStartDate = null;
                  selectedEndDate = null;
                });
              },
            )
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    int totalPages = (_filteredTransactionsFull.length / itemsPerPage).ceil();
    if (totalPages == 0) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0
                ? () => setState(() => currentPage--)
                : null,
          ),
          Text('หน้า ${currentPage + 1} จาก $totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () => setState(() => currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  // ✅ 4. อัปเดตฟิลเตอร์ให้รองรับทั้ง วันที่ และ ชื่อสินค้า
  List<Map<String, dynamic>> get _filteredTransactionsFull {
    List<Map<String, dynamic>> filtered = transactions;

    // กรองตามวันที่
    if (selectedStartDate != null && selectedEndDate != null) {
      filtered = filtered.where((transaction) {
        DateTime transactionDate = DateFormat('dd-MM-yyyy').parse(transaction['date']);
        return transactionDate.isAfter(selectedStartDate!.subtract(const Duration(days: 1))) &&
               transactionDate.isBefore(selectedEndDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // กรองตามชื่อสินค้าที่ติ๊กเลือก (ถ้าไม่ได้ติ๊กอะไรเลย จะแสดงทั้งหมด)
    if (_selectedProductFilters.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return _selectedProductFilters.contains(transaction['name_pro']);
      }).toList();
    }

    return filtered;
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    final filtered = _filteredTransactionsFull;
    final startIndex = currentPage * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    
    if (startIndex >= filtered.length) {
      currentPage = 0; 
      return filtered.sublist(0, itemsPerPage.clamp(0, filtered.length));
    }
    
    return filtered.sublist(startIndex, endIndex.clamp(0, filtered.length));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติทำรายการ (รวมคลัง)'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          // ✅ 5. เพิ่มไอคอนฟิลเตอร์มุมขวาบน
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'กรองสินค้า',
                onPressed: _showProductFilterDialog,
              ),
              // มีจุดสีแดงแจ้งเตือนเล็กๆ ถ้ามีการเปิดใช้งานฟิลเตอร์อยู่
              if (_selectedProductFilters.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
            ],
          ),
          if (userType == 'admin')
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelpDialog,
              tooltip: 'คำแนะนำ',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDateFilter(),
          
          // โชว์ป้ายกำกับด้านบนตารางว่ากำลังฟิลเตอร์สินค้าอะไรอยู่บ้าง
          if (_selectedProductFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text('กำลังแสดง: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  Expanded(
                    child: Text(
                      _selectedProductFilters.join(', '),
                      style: const TextStyle(color: Colors.blueGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(child: Text('ไม่มีรายการ'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Card(
                        margin: const EdgeInsets.all(12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                          dataRowMinHeight: 50,
                          dataRowMaxHeight: 60,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('วันที่', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('เวลา', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('คลัง', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('รายการ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ชื่อสินค้า', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('จำนวน', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ผู้ทำรายการ', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('')), 
                          ],
                          rows: _filteredTransactions.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> transaction = entry.value;

                            bool isAdd = transaction['describe'] == 'เพิ่ม';
                            Color actionColor = isAdd ? Colors.green : Colors.red;
                            IconData actionIcon = isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline;

                            int stockNum = transaction['stock_number'] ?? 1;
                            Color stockColor = stockNum == 1 ? Colors.redAccent : (stockNum == 2 ? Colors.pinkAccent : Colors.teal);

                            Color rowBackgroundColor = index % 2 == 0 ? Colors.white : Colors.grey.shade50;

                            return DataRow(
                              color: WidgetStateProperty.all(rowBackgroundColor),
                              cells: [
                                DataCell(Text(transaction['date'] ?? '')),
                                DataCell(Text(transaction['time'] ?? '')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: stockColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('คลัง $stockNum', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      Icon(actionIcon, color: actionColor, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        transaction['describe'] ?? '',
                                        style: TextStyle(color: actionColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(transaction['name_pro'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(
                                  '${isAdd ? '+' : '-'}${transaction['amount']}', 
                                  style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 16)
                                )),
                                DataCell(Text(transaction['user_name'] ?? 'Unknown')),
                                DataCell(
                                  userType == 'admin'
                                      ? Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              onPressed: () => _editTransaction(transaction['id']),
                                              splashRadius: 20,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              onPressed: () => _deleteTransaction(transaction['id']),
                                              splashRadius: 20,
                                            ),
                                          ],
                                        )
                                      : const SizedBox(),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
          _buildPaginationControls(),
        ],
      ),
    );
  }
}