import 'package:flutter/material.dart';
import '../services/localization.dart';

class LanguageDrawer extends StatelessWidget {
  final String currentLocale;
  final Function(String) onLanguageChanged;

  const LanguageDrawer({
    super.key,
    required this.currentLocale,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeys = AppLocalizations.languages.keys.toList();
    // Sort logic can be added here if needed, currently manual order

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            color: Colors.green,
            child: const Column(
              children: [
                Icon(Icons.language, size: 60, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  "Select Language",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "भाषा चुनें / భాషను ఎంచుకోండి",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: sortedKeys.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final key = sortedKeys[index];
                final name = AppLocalizations.languages[key]!;
                final isSelected = key == currentLocale;

                return ListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.green : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    onLanguageChanged(key);
                    Navigator.pop(context); // Close drawer
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
