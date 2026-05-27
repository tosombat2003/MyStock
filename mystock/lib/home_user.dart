import 'package:flutter/material.dart';
import 'package:mystock/menu_stock.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'login.dart';
import 'main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeUserScreen extends StatefulWidget {
  final int userId; // เพิ่มตัวแปร userId

  const HomeUserScreen({super.key, required this.userId});

  @override
  HomeUserScreenState createState() => HomeUserScreenState();
}

class HomeUserScreenState extends State<HomeUserScreen> {
  Future<String> _fetchUsername(int userId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('users')
        .select('name')
        .eq('id', userId)
        .single();

    if (response.isEmpty) {
      throw 'error!';
    }

    final data = response as Map<String, dynamic>?;

    if (data != null && data.containsKey('name')) {
      return data['name'];
    } else {
      throw Exception('name not found');
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(Duration(seconds: 2)); // จำลองการโหลดใหม่
    setState(() {}); // รีเฟรช UI
  }

  Future<void> _logout(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 247, 141, 54),
        title: FutureBuilder<String>(
          future: _fetchUsername(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            } else if (snapshot.hasError) {
              return Text('กรุณาเชื่อมต่ออินเทอร์เน็ต');
            } else if (snapshot.hasData) {
              return Text(
                'Home (${snapshot.data})',
                style: TextStyle(fontSize: 24),
              );
            } else {
              return Text('No username found');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // คลัง 1
            _buildButton(
                context,
                'คลัง 1',
                Colors.red,
                MenuStockScreen(
                    stockNumber: 1,
                    stockName: 'คลัง 1',
                    themeColor: Colors.red)),

// คลัง 2
            _buildButton(
                context,
                'คลัง 2',
                Colors.pinkAccent,
                MenuStockScreen(
                    stockNumber: 2,
                    stockName: 'คลัง 2',
                    themeColor: Colors.pinkAccent)),

// คลัง 3
            _buildButton(
                context,
                'ห้องเย็น',
                Colors.teal,
                MenuStockScreen(
                    stockNumber: 3,
                    stockName: 'ห้องเย็น',
                    themeColor: Colors.teal)),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
