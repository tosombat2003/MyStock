import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  final Function(String userType, int userId) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _rememberMe = false; // ตัวแปรสำหรับสถานะ "จดจำฉัน"
  bool _obscurePassword = true; // ค่าตั้งต้น ซ่อนรหัสผ่าน

  Future<void> _login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      // ตรวจสอบว่าชื่อผู้ใช้และรหัสผ่านถูกกรอกหรือไม่
      _showAlert('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน');
      return;
    }

    try {
      // Query ตรวจสอบข้อมูลผู้ใช้ใน Supabase
      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        // ถ้าไม่พบผู้ใช้ ให้แจ้งเตือน
        _showAlert('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
        return;
      }

      // ตรวจสอบว่า widget ยัง mounted อยู่ก่อนใช้ context
      if (!mounted) return;

      // ดึง role และ userId จาก response
      String userRole = response['role']; // เช่น 'admin' หรือ 'user'
      int userId = response['id']; // ดึง userId

      if (_rememberMe) {
        // บันทึกสถานะการเข้าสู่ระบบใน SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userType', userRole);
        await prefs.setInt('userId', userId); // บันทึก userId
      }

      // ส่ง role และ userId ไปยังหน้าหลัก
      widget.onLogin(userRole, userId);
    } catch (e) {
      // หากเกิดข้อผิดพลาดอื่น ๆ
      if (mounted) {
        _showAlert('ไม่ได้เชื่อมต่ออินเทอร์เน็ต กรุณาตรวจสอบการเชื่อมต่อ');
      }
      debugPrint('Error caught: $e'); // ใช้ debugPrint แทน print
    }
  }

  // ฟังก์ชันแสดงข้อความแจ้งเตือน
  void _showAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: const Color.fromARGB(255, 247, 141, 54),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ใส่โลโก้ใน Column ด้านบนของ TextField
            Image.asset(
              'assets/icon/mystock_logo.png', // ระบุ path ของโลโก้
              height: 200, // ปรับขนาดโลโก้
            ),
            SizedBox(height: 5), // ระยะห่างระหว่างโลโก้กับ TextField

            // ฟิลด์สำหรับ Username
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                _login();
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                Text('จดจำฉัน'),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
