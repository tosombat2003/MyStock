import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManagePage extends StatefulWidget {
  const UserManagePage({super.key});

  @override
  UserManagePageState createState() => UserManagePageState();
}

class UserManagePageState extends State<UserManagePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> users = [];
  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserRole(); // ดึง role ของผู้ใช้ปัจจุบันจาก SharedPreferences
    fetchUsers(); // ดึงข้อมูลผู้ใช้จากฐานข้อมูล
  }

  // ฟังก์ชันดึง role ของผู้ใช้ปัจจุบันจาก SharedPreferences
  Future<void> fetchCurrentUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserRole = prefs.getString('userType'); // 'admin' หรือ 'user'
    });
  }

  // ฟังก์ชันดึงข้อมูลผู้ใช้จากตาราง 'users'
  Future<void> fetchUsers() async {
    final response =
        await supabase.from('users').select().order('id', ascending: true);
    setState(() {
      users = response;
    });
  }

  // ฟังก์ชันแก้ไขข้อมูลผู้ใช้
  void editUser(Map<String, dynamic> user) {
    // กำหนดตัวแปรใหม่เพื่อเก็บค่า role ที่เลือก
    String? newRole = user['role'];

    TextEditingController nameController =
        TextEditingController(text: user['name']);
    TextEditingController usernameController =
        TextEditingController(text: user['username']);
    TextEditingController passwordController =
        TextEditingController(text: user['password']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("แก้ไขข้อมูลผู้ใช้"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: "Password"),
                ),
                // ใช้ DropdownButtonFormField เพื่อเลือก role
                DropdownButtonFormField<String>(
                  value: newRole,
                  items: [
                    DropdownMenuItem(value: 'user', child: Text("user")),
                    DropdownMenuItem(value: 'admin', child: Text("admin")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        newRole = value; // อัปเดตค่า role เมื่อเลือก
                      });
                    }
                  },
                  decoration: InputDecoration(labelText: "Role"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("ยกเลิก"),
            ),
            TextButton(
              onPressed: () async {
                // อัพเดตข้อมูลผู้ใช้ใน Supabase
                await supabase.from('users').update({
                  'name': nameController.text,
                  'username': usernameController.text,
                  'password': passwordController.text,
                  'role': newRole, // ส่งค่า role ที่เลือกจาก dropdown
                }).eq('id', user['id']);
                Navigator.of(context).pop();
                fetchUsers(); // ดึงข้อมูลผู้ใช้ใหม่
              },
              child: Text("บันทึก"),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันลบผู้ใช้
  void deleteUser(Map<String, dynamic> user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? currentUserId = prefs.getInt('userId');

    if (user['role'] == 'admin' && user['id'] == currentUserId) {
      showAlert("คุณไม่สามารถลบตัวเองได้");
      return;
    }

    await supabase.from('users').delete().eq('id', user['id']);
    fetchUsers();
  }

  // ฟังก์ชันแสดงข้อความแจ้งเตือน
  void showAlert(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ฟังก์ชันแสดงป๊อปอัปยืนยันก่อนลบ
  void confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("ยืนยันการลบ"),
          content: Text("คุณต้องการลบ ${user['name']} จริงหรือไม่?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // ปิดป๊อปอัป
              child: Text("ยกเลิก"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // ปิดป๊อปอัป
                if (user['role'] == 'admin') {
                  showAlert("ไม่สามารถลบผู้ใช้ที่เป็น admin ได้");
                } else {
                  await supabase.from('users').delete().eq('id', user['id']);
                  fetchUsers(); // อัปเดตรายชื่อผู้ใช้หลังลบ
                }
              },
              child: Text("ลบ", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

//ฟังก์ชัน เพิ่ม user ใหม่
  void showAddUserDialog() {
    String newName = '';
    String newUsername = '';
    String newPassword = '';
    String newRole = 'user'; // ค่าเริ่มต้นของ role

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("เพิ่มผู้ใช้ใหม่"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: "ชื่อ"),
                  onChanged: (value) => newName = value,
                ),
                TextField(
                  decoration:
                      InputDecoration(labelText: "ชื่อผู้ใช้ (Username)"),
                  onChanged: (value) => newUsername = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: "รหัสผ่าน"),
                  obscureText: true,
                  onChanged: (value) => newPassword = value,
                ),
                DropdownButtonFormField<String>(
                  value: newRole,
                  items: [
                    DropdownMenuItem(value: 'user', child: Text("user")),
                    DropdownMenuItem(value: 'admin', child: Text("admin")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      newRole = value;
                    }
                  },
                  decoration: InputDecoration(labelText: "Role"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // ปิดป๊อปอัป
                if (newName.isNotEmpty &&
                    newUsername.isNotEmpty &&
                    newPassword.isNotEmpty) {
                  // เพิ่มข้อมูลผู้ใช้ใน Supabase
                  final response = await supabase.from('users').insert({
                    'name': newName,
                    'username': newUsername,
                    'password': newPassword,
                    'role': newRole,
                  });

                  if (response == null) {
                    // เช็คว่าไม่มี error
                    showAlert("เพิ่มผู้ใช้ใหม่สำเร็จ");
                    await fetchUsers(); // รีเฟรชรายชื่อผู้ใช้ทันที
                  } else {
                    showAlert("เกิดข้อผิดพลาด: ไม่สามารถเพิ่มผู้ใช้ได้");
                  }
                } else {
                  showAlert("กรุณากรอกข้อมูลให้ครบทุกช่อง");
                }
              },
              child: Text("ยืนยัน"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการuser'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: showAddUserDialog, // เรียกฟังก์ชันเพิ่มผู้ใช้ใหม่
          ),
        ],
      ),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, id) {
                final user = users[id];
                final userName = user['name'] ?? 'No name';
                final userEmail = user['username'] ?? 'No username';
                final userPassword = user['password'] ?? 'No password';
                final userRole = user['role'] ?? 'No role';

                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(userName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Username: $userEmail"),
                        Text("Password: $userPassword"),
                        Text("Role: $userRole"),
                      ],
                    ),
                    leading: Icon(Icons.person),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                          ),
                          onPressed: () => editUser(user),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            if (currentUserRole == 'admin' &&
                                userRole == 'admin') {
                              showAlert('ไม่สามารถลบผู้ใช้ที่เป็น admin ได้');
                            } else {
                              confirmDeleteUser(user);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
