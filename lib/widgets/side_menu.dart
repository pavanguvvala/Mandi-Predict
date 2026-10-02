import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/localization.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/chat_screen.dart';

// import '../main.dart'; // Removed to fix circular dependency

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    // In a real app with multi-user, this key should likely include the user ID.
    // For this simple demo, we share one profile pic or link it to current user.
    final user = AuthService.currentUser;
    if (user != null) {
      final path = prefs.getString('user_image_${user['name']}');
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          setState(() {
            _imageFile = file;
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final user = AuthService.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_image_${user['name']}', image.path);

        setState(() {
          _imageFile = File(image.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final name = user != null ? user['name'] : 'Guest';
    final currentLocale = localeNotifier.value;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name),
            accountEmail: const Text("Farmer Account"),
            currentAccountPicture: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : null,
                child: _imageFile == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 30,
                        color: Color(0xFF1B5E20),
                      )
                    : null,
              ),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/splash_bg.png',
                ), // Reuse splash bg for header? nice touch
                fit: BoxFit.cover,
                opacity: 0.2,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: Text(AppLocalizations.get(currentLocale, 'dashboard')),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: Text(AppLocalizations.get(currentLocale, 'farmer_advisor')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(AppLocalizations.get(currentLocale, 'profile')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: Text(AppLocalizations.get(currentLocale, 'field_assistant')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),

          // Languages Expansion Tile
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.get(currentLocale, 'change_ling')),
              children: AppLocalizations.languages.entries.map((entry) {
                final code = entry.key;
                final name = entry.value;
                final isSelected = code == currentLocale;

                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 72),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.green : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green, size: 16)
                      : null,
                  onTap: () {
                    localeNotifier.value = code;
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // Hide Chatbot for now per cleaning, or keep if requested?
          // User didn't ask to remove it, but it was there in old files.
          // I will keep it simple.
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppLocalizations.get(currentLocale, 'logout')),
            onTap: () {
              AuthService().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
