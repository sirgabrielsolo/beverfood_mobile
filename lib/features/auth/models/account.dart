/// The signed-in client, as `/api/v1/me` returns it (beverfood_web's
/// `app_client`).
class Account {
  const Account({
    required this.id,
    required this.status,
    required this.isTest,
    required this.phoneVerified,
    required this.emailVerified,
    required this.profileEditable,
    this.erpClientId,
    this.reviewNote,
    this.phone,
    this.email,
    this.firstName,
    this.lastName,
    this.companyName,
    this.vatNumber,
    this.address,
  });

  factory Account.fromJson(Map<String, Object?> json) {
    final profile = json['profile'] as Map<String, Object?>? ?? const {};
    final address = json['address'] as Map<String, Object?>?;
    return Account(
      id: json['id'] as int,
      status:
          AccountStatus.values.asNameMap()[json['status']] ??
          AccountStatus.registered,
      isTest: json['is_test'] as bool? ?? false,
      erpClientId: json['erp_client_id'] as int?,
      reviewNote: json['review_note'] as String?,
      phone: json['phone'] as String?,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      email: json['email'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      profileEditable: json['profile_editable'] as bool? ?? false,
      firstName: profile['first_name'] as String?,
      lastName: profile['last_name'] as String?,
      companyName: profile['company_name'] as String?,
      vatNumber: profile['vat_number'] as String?,
      address: address == null ? null : DeliveryAddress.fromJson(address),
    );
  }

  final int id;
  final AccountStatus status;

  /// The shared test account: approved, cannot be deleted.
  final bool isTest;

  /// The client's code in the ERP, assigned on approval.
  final int? erpClientId;

  /// Why the profile was rejected or the account suspended.
  final String? reviewNote;

  /// +39… mobile number and lower-cased email; verified ones only count.
  final String? phone;
  final bool phoneVerified;
  final String? email;
  final bool emailVerified;

  /// Whether the profile can still be (re)sent; after approval only the
  /// address changes.
  final bool profileEditable;

  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String? vatNumber;
  final DeliveryAddress? address;

  bool get canOrder => status == AccountStatus.approved;

  String? get fullName {
    final name = [firstName, lastName].whereType<String>().join(' ').trim();
    return name.isEmpty ? null : name;
  }
}

enum AccountStatus {
  /// Contact verified; the profile hasn't been sent.
  registered,

  /// Profile sent, waiting for Beverfood to check it.
  pending,

  /// Checked: the client may order.
  approved,

  /// Not accepted: [Account.reviewNote] says why; it can be fixed and resent.
  rejected,

  /// May not order for now; [Account.reviewNote] says why.
  suspended,
}

/// A delivery address in the province of Torino.
class DeliveryAddress {
  const DeliveryAddress({
    required this.comuneIstat,
    required this.comune,
    required this.street,
    required this.streetUnlisted,
    required this.civic,
    required this.cap,
    this.notes,
  });

  factory DeliveryAddress.fromJson(Map<String, Object?> json) =>
      DeliveryAddress(
        comuneIstat: json['comune_istat'] as String,
        comune: json['comune'] as String,
        street: json['street'] as String,
        streetUnlisted: json['street_unlisted'] as bool? ?? false,
        civic: json['civic'] as String,
        cap: json['cap'] as String,
        notes: json['notes'] as String?,
      );

  final String comuneIstat;
  final String comune;
  final String street;

  /// Typed by hand: the street isn't in the list.
  final bool streetUnlisted;
  final String civic;
  final String cap;
  final String? notes;

  Map<String, Object?> toJson() => {
    'comune_istat': comuneIstat,
    'street': street,
    'street_unlisted': streetUnlisted,
    'civic': civic,
    'cap': cap,
    'notes': notes,
  };

  /// "Via Nizza 112, 10126 Torino".
  String get oneLine => '$street $civic, $cap $comune';
}

/// A comune of the province of Torino, with its CAPs.
class Comune {
  const Comune({required this.istat, required this.name, required this.caps});

  factory Comune.fromJson(Map<String, Object?> json) => Comune(
    istat: json['istat'] as String,
    name: json['name'] as String,
    caps: [for (final cap in json['caps'] as List) cap as String],
  );

  final String istat;
  final String name;
  final List<String> caps;
}

/// A street of a comune; [caps] is filled for Torino, where they differ.
class Street {
  const Street({required this.name, required this.caps});

  factory Street.fromJson(Map<String, Object?> json) => Street(
    name: json['name'] as String,
    caps: [for (final cap in json['caps'] as List) cap as String],
  );

  final String name;
  final List<String> caps;
}
