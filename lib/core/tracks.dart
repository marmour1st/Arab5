import 'package:flutter/material.dart';

/// The seven training tracks. Keep in sync with the server (config/constants.js).
class TrackInfo {
  const TrackInfo(this.id, this.ar, this.en, this.shortAr, this.shortEn, this.color, this.icon);
  final String id;
  final String ar;
  final String en;
  final String shortAr;
  final String shortEn;
  final Color color;
  final IconData icon;

  String name(String lang) => lang == 'en' ? en : ar;
  String shortName(String lang) => lang == 'en' ? shortEn : shortAr;
}

const List<TrackInfo> tracks = [
  TrackInfo('lab', 'القياسات والمختبرات', 'Laboratory & Metrology', 'المختبرات', 'Labs', Color(0xFFC08A2E), Icons.science_outlined),
  TrackInfo('tech', 'التكنولوجيا المتقدمة', 'Advanced Technologies', 'التكنولوجيا', 'Tech', Color(0xFF3D8F7A), Icons.biotech_outlined),
  TrackInfo('eng', 'الهندسة والصناعة', 'Engineering & Industry', 'الهندسة', 'Engineering', Color(0xFF4A74C9), Icons.precision_manufacturing_outlined),
  TrackInfo('qhse', 'الجودة والسلامة والبيئة', 'Quality, Safety & Environment', 'الجودة', 'QHSE', Color(0xFFB0563F), Icons.health_and_safety_outlined),
  TrackInfo('mgmt', 'الإدارة والمالية', 'Management & Finance', 'الإدارة', 'Management', Color(0xFF7A5CC2), Icons.business_center_outlined),
  TrackInfo('it', 'تقنية المعلومات والبيانات', 'IT & Data', 'تقنية المعلومات', 'IT & Data', Color(0xFF2B8BB3), Icons.computer_outlined),
  TrackInfo('lang', 'اللغات والتواصل', 'Languages & Communication', 'اللغات', 'Languages', Color(0xFF8A8F2E), Icons.translate_rounded),
];

TrackInfo trackOf(String id) => tracks.firstWhere((t) => t.id == id, orElse: () => tracks.first);

int trackIndex(String id) {
  final i = tracks.indexWhere((t) => t.id == id);
  return i < 0 ? tracks.length : i;
}

const List<String> levels = ['foundation', 'intermediate', 'advanced', 'expert'];
const List<String> modes = ['onsite', 'online', 'blended'];
const List<String> registrationStatuses = ['new', 'contacted', 'enrolled', 'completed', 'cancelled'];
const List<String> corporateStatuses = ['new', 'in_discussion', 'proposal_sent', 'won', 'closed'];
