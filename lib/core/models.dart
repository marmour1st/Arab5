/// Data models mirroring the server's JSON.

String _str(dynamic v) => v == null ? '' : v.toString();
int _int(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : int.tryParse(_str(v)) ?? fallback;
bool _bool(dynamic v) => v == true;
DateTime _date(dynamic v) => DateTime.tryParse(_str(v))?.toLocal() ?? DateTime.now();
List<String> _list(dynamic v) => v is List ? v.map(_str).toList() : <String>[];

/// Text in Arabic and English.
class Bi {
  const Bi(this.ar, this.en);
  final String ar;
  final String en;

  factory Bi.from(dynamic json) {
    if (json is Map) return Bi(_str(json['ar']), _str(json['en']));
    return const Bi('', '');
  }

  String pick(String lang) {
    if (lang == 'en') return en.isNotEmpty ? en : ar;
    return ar.isNotEmpty ? ar : en;
  }
}

class Program {
  const Program({
    required this.id,
    required this.code,
    required this.track,
    required this.title,
    required this.summary,
    required this.audience,
    required this.outcomesAr,
    required this.outcomesEn,
    required this.level,
    required this.hours,
    required this.modes,
    required this.featured,
    required this.active,
    required this.order,
  });

  final String id;
  final String code;
  final String track;
  final Bi title;
  final Bi summary;
  final Bi audience;
  final List<String> outcomesAr;
  final List<String> outcomesEn;
  final String level;
  final int hours;
  final List<String> modes;
  final bool featured;
  final bool active;
  final int order;

  List<String> outcomes(String lang) {
    if (lang == 'en' && outcomesEn.isNotEmpty) return outcomesEn;
    return outcomesAr.isNotEmpty ? outcomesAr : outcomesEn;
  }

  Program copyWith({bool? active}) => Program(
        id: id,
        code: code,
        track: track,
        title: title,
        summary: summary,
        audience: audience,
        outcomesAr: outcomesAr,
        outcomesEn: outcomesEn,
        level: level,
        hours: hours,
        modes: modes,
        featured: featured,
        active: active ?? this.active,
        order: order,
      );

  factory Program.fromJson(Map<String, dynamic> j) {
    final outcomes = j['outcomes'];
    final modes = _list(j['modes']);
    return Program(
      id: _str(j['id']),
      code: _str(j['code']),
      track: _str(j['track']),
      title: Bi.from(j['title']),
      summary: Bi.from(j['summary']),
      audience: Bi.from(j['audience']),
      outcomesAr: outcomes is Map ? _list(outcomes['ar']) : <String>[],
      outcomesEn: outcomes is Map ? _list(outcomes['en']) : <String>[],
      level: _str(j['level']).isEmpty ? 'foundation' : _str(j['level']),
      hours: _int(j['hours']),
      modes: modes.isEmpty ? <String>['onsite'] : modes,
      featured: _bool(j['featured']),
      active: j['active'] == null ? true : _bool(j['active']),
      order: _int(j['order']),
    );
  }
}

class AdminUser {
  const AdminUser({required this.email, required this.name, required this.role});
  final String email;
  final String name;
  final String role;

  factory AdminUser.fromJson(Map<String, dynamic> j) =>
      AdminUser(email: _str(j['email']), name: _str(j['name']), role: _str(j['role']));
}

class Registration {
  const Registration({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.programCode,
    required this.programTitle,
    required this.mode,
    required this.notes,
    required this.lang,
    required this.status,
    required this.adminNote,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String programCode;
  final Bi programTitle;
  final String mode;
  final String notes;
  final String lang;
  final String status;
  final String adminNote;
  final DateTime createdAt;

  factory Registration.fromJson(Map<String, dynamic> j) => Registration(
        id: _str(j['id']),
        fullName: _str(j['fullName']),
        phone: _str(j['phone']),
        email: _str(j['email']),
        programCode: _str(j['programCode']),
        programTitle: Bi.from(j['programTitle']),
        mode: _str(j['mode']).isEmpty ? 'onsite' : _str(j['mode']),
        notes: _str(j['notes']),
        lang: _str(j['lang']),
        status: _str(j['status']).isEmpty ? 'new' : _str(j['status']),
        adminNote: _str(j['adminNote']),
        createdAt: _date(j['createdAt']),
      );
}

class ContactMessage {
  const ContactMessage({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String message;
  final bool read;
  final DateTime createdAt;

  factory ContactMessage.fromJson(Map<String, dynamic> j) => ContactMessage(
        id: _str(j['id']),
        name: _str(j['name']),
        phone: _str(j['phone']),
        email: _str(j['email']),
        message: _str(j['message']),
        read: _bool(j['read']),
        createdAt: _date(j['createdAt']),
      );
}

class CorporateRequest {
  const CorporateRequest({
    required this.id,
    required this.company,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.trainees,
    required this.topic,
    required this.details,
    required this.status,
    required this.adminNote,
    required this.createdAt,
  });

  final String id;
  final String company;
  final String contactName;
  final String phone;
  final String email;
  final int trainees;
  final String topic;
  final String details;
  final String status;
  final String adminNote;
  final DateTime createdAt;

  factory CorporateRequest.fromJson(Map<String, dynamic> j) => CorporateRequest(
        id: _str(j['id']),
        company: _str(j['company']),
        contactName: _str(j['contactName']),
        phone: _str(j['phone']),
        email: _str(j['email']),
        trainees: _int(j['trainees'], 1),
        topic: _str(j['topic']),
        details: _str(j['details']),
        status: _str(j['status']).isEmpty ? 'new' : _str(j['status']),
        adminNote: _str(j['adminNote']),
        createdAt: _date(j['createdAt']),
      );
}

class Certificate {
  const Certificate({
    required this.id,
    required this.code,
    required this.holderName,
    required this.programCode,
    required this.programTitle,
    required this.hours,
    required this.issuedAt,
    required this.revoked,
  });

  final String id;
  final String code;
  final String holderName;
  final String programCode;
  final Bi programTitle;
  final int hours;
  final DateTime issuedAt;
  final bool revoked;

  factory Certificate.fromJson(Map<String, dynamic> j) => Certificate(
        id: _str(j['id']),
        code: _str(j['code']),
        holderName: _str(j['holderName']),
        programCode: _str(j['programCode']),
        programTitle: Bi.from(j['programTitle']),
        hours: _int(j['hours']),
        issuedAt: _date(j['issuedAt']),
        revoked: _bool(j['revoked']),
      );
}
