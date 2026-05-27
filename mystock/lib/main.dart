import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_user.dart';
import 'home_admin.dart';
import 'login.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // เพื่อให้ async ใช้งานได้ใน main()

  // ตั้งค่า Supabase
  await Supabase.initialize(
    url:  //your URL ของ Supabase Project
    anonKey:
         //your Anon Key ของ Supabase
  );
  SystemChrome.setPreferredOrientations([]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyStock',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  String? userType;
  int? currentUserId;
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _monitorNetwork();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('userType');
      currentUserId = prefs.getInt('userId');
    });
  }

  void _monitorNetwork() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      bool connected = results.contains(ConnectivityResult.mobile) || 
                       results.contains(ConnectivityResult.wifi);
      if (_isConnected != connected) {
        setState(() {
          _isConnected = connected;
        });

        if (!connected) {
          _showSnackBar("ไม่มีการเชื่อมต่ออินเทอร์เน็ต");
        } else {
          _showSnackBar("กลับมาเชื่อมต่ออินเทอร์เน็ตแล้ว", isError: false);
        }
      }
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userType == null || currentUserId == null) {
      return LoginScreen(
        onLogin: (String type, int userId) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', type);
          await prefs.setInt('userId', userId);
          setState(() {
            userType = type;
            currentUserId = userId;
          });
        },
      );
    } else if (userType == 'admin') {
      return HomeAdminScreen(userId: currentUserId!);
    } else {
      return HomeUserScreen(userId: currentUserId!);
    }
  }
}
