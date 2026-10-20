import 'package:flutter/material.dart';

class EmergencyContact {
  final String title;
  final String subtitle;
  final String phoneNumber;
  final IconData icon;
  final Color color;

  const EmergencyContact({
    required this.title,
    required this.subtitle,
    required this.phoneNumber,
    required this.icon,
    required this.color,
  });

  static const List<EmergencyContact> lpuContacts = [
    EmergencyContact(
      title: 'Uni Health Care (Hospital)',
      subtitle: '24x7 Campus Medical & Ambulance Service',
      phoneNumber: '01824517100',
      icon: Icons.local_hospital_rounded,
      color: Colors.red,
    ),
    EmergencyContact(
      title: 'LPU Security Control Room',
      subtitle: 'Campus Gate & Perimeter Emergency Response',
      phoneNumber: '01824517000',
      icon: Icons.security_rounded,
      color: Colors.blueAccent,
    ),
    EmergencyContact(
      title: 'Proctorial Cell',
      subtitle: 'Student Safety, Discipline & Assistance',
      phoneNumber: '01824517200',
      icon: Icons.gavel_rounded,
      color: Colors.orange,
    ),
    EmergencyContact(
      title: 'Women Safety Helpline',
      subtitle: 'Dedicated 24/7 Support Line for Women',
      phoneNumber: '1091',
      icon: Icons.shield_rounded,
      color: Colors.purple,
    ),
    EmergencyContact(
      title: 'Fire & Disaster Management',
      subtitle: 'Campus Fire Department & Disaster Help',
      phoneNumber: '101',
      icon: Icons.local_fire_department_rounded,
      color: Colors.deepOrange,
    ),
  ];
}
