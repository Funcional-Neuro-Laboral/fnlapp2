import 'package:flutter/material.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final bool showExitTest;
  final bool isExitTestEnabled;

  CustomNavigationBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.showExitTest,
    required this.isExitTestEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          width: MediaQuery.of(context).size.width * 0.85,
          height: 70,
          constraints: BoxConstraints(maxWidth: 400, minWidth: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(70),
            boxShadow: [
              BoxShadow(
                color: Color(0x3D000000),
                spreadRadius: 0,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(showExitTest ? 5 : 4, (index) {
              return _buildRoundedIcon(context, index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedIcon(BuildContext context, int index) {
    List<Map<String, dynamic>> items = [
      {'icon': Icons.self_improvement, 'label': 'Mi plan'},
      {'icon': Icons.chat_outlined, 'label': 'Chat'},
      {'icon': Icons.assignment_outlined, 'label': 'Test'},
      {'icon': Icons.account_circle_outlined, 'label': 'Perfil'},
      {'icon': Icons.check_circle, 'label': 'Test Salida'},
    ];

    if (index >= items.length) return Container();

    bool isExitTest = index == 4;
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: isExitTest && !isExitTestEnabled
          ? null
          : () => onItemTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 20 : 12,
        vertical: isSelected ? 12 : 10,
      ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6D4BD8)
              : const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              items[index]['icon'],
              color: isExitTest && !isExitTestEnabled
                  ? Colors.grey.shade700
                  : (isSelected ? Colors.white : const Color(0xFF1C1B1F)),
              size: 24,
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Text(
                items[index]['label'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
