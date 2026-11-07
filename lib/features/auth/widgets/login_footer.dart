import 'package:flutter/material.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: Color(0xFF64748B),
            ),
            SizedBox(width: 6),
            Text(
              'Sistema Institucional de Gestión',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Acceso exclusivo para personal autorizado',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
