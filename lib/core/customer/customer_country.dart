import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class CustomerCountry {
  final String isoCode;
  final String name;

  const CustomerCountry({
    required this.isoCode,
    required this.name,
  });

  String get normalizedIsoCode => isoCode.trim().toUpperCase();

  String get flagEmoji {
    final code = normalizedIsoCode;
    if (code.length != 2 ||
        code.codeUnits.any((unit) => unit < 65 || unit > 90)) {
      return '🌐';
    }

    const regionalIndicatorOffset = 127397;
    return String.fromCharCodes(
      code.codeUnits.map((unit) => unit + regionalIndicatorOffset),
    );
  }
}

/// ISO-style country catalog used by the local/demo customer-country picker.
///
/// Keeping the ISO code as the stable key means the UI can later replace this
/// local catalog with Laravel-delivered country configuration without changing
/// Profile widgets or flag generation.
class CustomerCountryCatalog {
  CustomerCountryCatalog._();

  static const List<CustomerCountry> all = <CustomerCountry>[
    CustomerCountry(isoCode: 'EG', name: "Egypt"),
    CustomerCountry(isoCode: 'AF', name: "Afghanistan"),
    CustomerCountry(isoCode: 'AL', name: "Albania"),
    CustomerCountry(isoCode: 'DZ', name: "Algeria"),
    CustomerCountry(isoCode: 'AS', name: "American Samoa"),
    CustomerCountry(isoCode: 'AD', name: "Andorra"),
    CustomerCountry(isoCode: 'AO', name: "Angola"),
    CustomerCountry(isoCode: 'AI', name: "Anguilla"),
    CustomerCountry(isoCode: 'AQ', name: "Antarctica"),
    CustomerCountry(isoCode: 'AG', name: "Antigua and Barbuda"),
    CustomerCountry(isoCode: 'AR', name: "Argentina"),
    CustomerCountry(isoCode: 'AM', name: "Armenia"),
    CustomerCountry(isoCode: 'AW', name: "Aruba"),
    CustomerCountry(isoCode: 'AU', name: "Australia"),
    CustomerCountry(isoCode: 'AT', name: "Austria"),
    CustomerCountry(isoCode: 'AZ', name: "Azerbaijan"),
    CustomerCountry(isoCode: 'BS', name: "Bahamas"),
    CustomerCountry(isoCode: 'BH', name: "Bahrain"),
    CustomerCountry(isoCode: 'BD', name: "Bangladesh"),
    CustomerCountry(isoCode: 'BB', name: "Barbados"),
    CustomerCountry(isoCode: 'BY', name: "Belarus"),
    CustomerCountry(isoCode: 'BE', name: "Belgium"),
    CustomerCountry(isoCode: 'BZ', name: "Belize"),
    CustomerCountry(isoCode: 'BJ', name: "Benin"),
    CustomerCountry(isoCode: 'BM', name: "Bermuda"),
    CustomerCountry(isoCode: 'BT', name: "Bhutan"),
    CustomerCountry(isoCode: 'BO', name: "Bolivia"),
    CustomerCountry(isoCode: 'BQ', name: "Bonaire, Sint Eustatius and Saba"),
    CustomerCountry(isoCode: 'BA', name: "Bosnia and Herzegovina"),
    CustomerCountry(isoCode: 'BW', name: "Botswana"),
    CustomerCountry(isoCode: 'BV', name: "Bouvet Island"),
    CustomerCountry(isoCode: 'BR', name: "Brazil"),
    CustomerCountry(isoCode: 'IO', name: "British Indian Ocean Territory"),
    CustomerCountry(isoCode: 'BN', name: "Brunei"),
    CustomerCountry(isoCode: 'BG', name: "Bulgaria"),
    CustomerCountry(isoCode: 'BF', name: "Burkina Faso"),
    CustomerCountry(isoCode: 'BI', name: "Burundi"),
    CustomerCountry(isoCode: 'CV', name: "Cabo Verde"),
    CustomerCountry(isoCode: 'KH', name: "Cambodia"),
    CustomerCountry(isoCode: 'CM', name: "Cameroon"),
    CustomerCountry(isoCode: 'CA', name: "Canada"),
    CustomerCountry(isoCode: 'KY', name: "Cayman Islands"),
    CustomerCountry(isoCode: 'CF', name: "Central African Republic"),
    CustomerCountry(isoCode: 'TD', name: "Chad"),
    CustomerCountry(isoCode: 'CL', name: "Chile"),
    CustomerCountry(isoCode: 'CN', name: "China"),
    CustomerCountry(isoCode: 'CX', name: "Christmas Island"),
    CustomerCountry(isoCode: 'CC', name: "Cocos (Keeling) Islands"),
    CustomerCountry(isoCode: 'CO', name: "Colombia"),
    CustomerCountry(isoCode: 'KM', name: "Comoros"),
    CustomerCountry(isoCode: 'CK', name: "Cook Islands"),
    CustomerCountry(isoCode: 'CR', name: "Costa Rica"),
    CustomerCountry(isoCode: 'HR', name: "Croatia"),
    CustomerCountry(isoCode: 'CU', name: "Cuba"),
    CustomerCountry(isoCode: 'CW', name: "Cura\u00e7ao"),
    CustomerCountry(isoCode: 'CY', name: "Cyprus"),
    CustomerCountry(isoCode: 'CZ', name: "Czechia"),
    CustomerCountry(isoCode: 'CI', name: "C\u00f4te d\u2019Ivoire"),
    CustomerCountry(isoCode: 'CD', name: "Democratic Republic of the Congo"),
    CustomerCountry(isoCode: 'DK', name: "Denmark"),
    CustomerCountry(isoCode: 'DJ', name: "Djibouti"),
    CustomerCountry(isoCode: 'DM', name: "Dominica"),
    CustomerCountry(isoCode: 'DO', name: "Dominican Republic"),
    CustomerCountry(isoCode: 'EC', name: "Ecuador"),
    CustomerCountry(isoCode: 'SV', name: "El Salvador"),
    CustomerCountry(isoCode: 'GQ', name: "Equatorial Guinea"),
    CustomerCountry(isoCode: 'ER', name: "Eritrea"),
    CustomerCountry(isoCode: 'EE', name: "Estonia"),
    CustomerCountry(isoCode: 'SZ', name: "Eswatini"),
    CustomerCountry(isoCode: 'ET', name: "Ethiopia"),
    CustomerCountry(isoCode: 'FK', name: "Falkland Islands (Malvinas)"),
    CustomerCountry(isoCode: 'FO', name: "Faroe Islands"),
    CustomerCountry(isoCode: 'FJ', name: "Fiji"),
    CustomerCountry(isoCode: 'FI', name: "Finland"),
    CustomerCountry(isoCode: 'FR', name: "France"),
    CustomerCountry(isoCode: 'GF', name: "French Guiana"),
    CustomerCountry(isoCode: 'PF', name: "French Polynesia"),
    CustomerCountry(isoCode: 'TF', name: "French Southern Territories"),
    CustomerCountry(isoCode: 'GA', name: "Gabon"),
    CustomerCountry(isoCode: 'GM', name: "Gambia"),
    CustomerCountry(isoCode: 'GE', name: "Georgia"),
    CustomerCountry(isoCode: 'DE', name: "Germany"),
    CustomerCountry(isoCode: 'GH', name: "Ghana"),
    CustomerCountry(isoCode: 'GI', name: "Gibraltar"),
    CustomerCountry(isoCode: 'GR', name: "Greece"),
    CustomerCountry(isoCode: 'GL', name: "Greenland"),
    CustomerCountry(isoCode: 'GD', name: "Grenada"),
    CustomerCountry(isoCode: 'GP', name: "Guadeloupe"),
    CustomerCountry(isoCode: 'GU', name: "Guam"),
    CustomerCountry(isoCode: 'GT', name: "Guatemala"),
    CustomerCountry(isoCode: 'GG', name: "Guernsey"),
    CustomerCountry(isoCode: 'GN', name: "Guinea"),
    CustomerCountry(isoCode: 'GW', name: "Guinea-Bissau"),
    CustomerCountry(isoCode: 'GY', name: "Guyana"),
    CustomerCountry(isoCode: 'HT', name: "Haiti"),
    CustomerCountry(isoCode: 'HM', name: "Heard Island and McDonald Islands"),
    CustomerCountry(isoCode: 'VA', name: "Holy See (Vatican City State)"),
    CustomerCountry(isoCode: 'HN', name: "Honduras"),
    CustomerCountry(isoCode: 'HK', name: "Hong Kong"),
    CustomerCountry(isoCode: 'HU', name: "Hungary"),
    CustomerCountry(isoCode: 'IS', name: "Iceland"),
    CustomerCountry(isoCode: 'IN', name: "India"),
    CustomerCountry(isoCode: 'ID', name: "Indonesia"),
    CustomerCountry(isoCode: 'IR', name: "Iran"),
    CustomerCountry(isoCode: 'IQ', name: "Iraq"),
    CustomerCountry(isoCode: 'IE', name: "Ireland"),
    CustomerCountry(isoCode: 'IM', name: "Isle of Man"),
    CustomerCountry(isoCode: 'IL', name: "Israel"),
    CustomerCountry(isoCode: 'IT', name: "Italy"),
    CustomerCountry(isoCode: 'JM', name: "Jamaica"),
    CustomerCountry(isoCode: 'JP', name: "Japan"),
    CustomerCountry(isoCode: 'JE', name: "Jersey"),
    CustomerCountry(isoCode: 'JO', name: "Jordan"),
    CustomerCountry(isoCode: 'KZ', name: "Kazakhstan"),
    CustomerCountry(isoCode: 'KE', name: "Kenya"),
    CustomerCountry(isoCode: 'KI', name: "Kiribati"),
    CustomerCountry(isoCode: 'KW', name: "Kuwait"),
    CustomerCountry(isoCode: 'KG', name: "Kyrgyzstan"),
    CustomerCountry(isoCode: 'LA', name: "Laos"),
    CustomerCountry(isoCode: 'LV', name: "Latvia"),
    CustomerCountry(isoCode: 'LB', name: "Lebanon"),
    CustomerCountry(isoCode: 'LS', name: "Lesotho"),
    CustomerCountry(isoCode: 'LR', name: "Liberia"),
    CustomerCountry(isoCode: 'LY', name: "Libya"),
    CustomerCountry(isoCode: 'LI', name: "Liechtenstein"),
    CustomerCountry(isoCode: 'LT', name: "Lithuania"),
    CustomerCountry(isoCode: 'LU', name: "Luxembourg"),
    CustomerCountry(isoCode: 'MO', name: "Macao"),
    CustomerCountry(isoCode: 'MG', name: "Madagascar"),
    CustomerCountry(isoCode: 'MW', name: "Malawi"),
    CustomerCountry(isoCode: 'MY', name: "Malaysia"),
    CustomerCountry(isoCode: 'MV', name: "Maldives"),
    CustomerCountry(isoCode: 'ML', name: "Mali"),
    CustomerCountry(isoCode: 'MT', name: "Malta"),
    CustomerCountry(isoCode: 'MH', name: "Marshall Islands"),
    CustomerCountry(isoCode: 'MQ', name: "Martinique"),
    CustomerCountry(isoCode: 'MR', name: "Mauritania"),
    CustomerCountry(isoCode: 'MU', name: "Mauritius"),
    CustomerCountry(isoCode: 'YT', name: "Mayotte"),
    CustomerCountry(isoCode: 'MX', name: "Mexico"),
    CustomerCountry(isoCode: 'FM', name: "Micronesia, Federated States of"),
    CustomerCountry(isoCode: 'MD', name: "Moldova"),
    CustomerCountry(isoCode: 'MC', name: "Monaco"),
    CustomerCountry(isoCode: 'MN', name: "Mongolia"),
    CustomerCountry(isoCode: 'ME', name: "Montenegro"),
    CustomerCountry(isoCode: 'MS', name: "Montserrat"),
    CustomerCountry(isoCode: 'MA', name: "Morocco"),
    CustomerCountry(isoCode: 'MZ', name: "Mozambique"),
    CustomerCountry(isoCode: 'MM', name: "Myanmar"),
    CustomerCountry(isoCode: 'NA', name: "Namibia"),
    CustomerCountry(isoCode: 'NR', name: "Nauru"),
    CustomerCountry(isoCode: 'NP', name: "Nepal"),
    CustomerCountry(isoCode: 'NL', name: "Netherlands"),
    CustomerCountry(isoCode: 'NC', name: "New Caledonia"),
    CustomerCountry(isoCode: 'NZ', name: "New Zealand"),
    CustomerCountry(isoCode: 'NI', name: "Nicaragua"),
    CustomerCountry(isoCode: 'NE', name: "Niger"),
    CustomerCountry(isoCode: 'NG', name: "Nigeria"),
    CustomerCountry(isoCode: 'NU', name: "Niue"),
    CustomerCountry(isoCode: 'NF', name: "Norfolk Island"),
    CustomerCountry(isoCode: 'KP', name: "North Korea"),
    CustomerCountry(isoCode: 'MK', name: "North Macedonia"),
    CustomerCountry(isoCode: 'MP', name: "Northern Mariana Islands"),
    CustomerCountry(isoCode: 'NO', name: "Norway"),
    CustomerCountry(isoCode: 'OM', name: "Oman"),
    CustomerCountry(isoCode: 'PK', name: "Pakistan"),
    CustomerCountry(isoCode: 'PW', name: "Palau"),
    CustomerCountry(isoCode: 'PS', name: "Palestine"),
    CustomerCountry(isoCode: 'PA', name: "Panama"),
    CustomerCountry(isoCode: 'PG', name: "Papua New Guinea"),
    CustomerCountry(isoCode: 'PY', name: "Paraguay"),
    CustomerCountry(isoCode: 'PE', name: "Peru"),
    CustomerCountry(isoCode: 'PH', name: "Philippines"),
    CustomerCountry(isoCode: 'PN', name: "Pitcairn"),
    CustomerCountry(isoCode: 'PL', name: "Poland"),
    CustomerCountry(isoCode: 'PT', name: "Portugal"),
    CustomerCountry(isoCode: 'PR', name: "Puerto Rico"),
    CustomerCountry(isoCode: 'QA', name: "Qatar"),
    CustomerCountry(isoCode: 'CG', name: "Republic of the Congo"),
    CustomerCountry(isoCode: 'RO', name: "Romania"),
    CustomerCountry(isoCode: 'RU', name: "Russia"),
    CustomerCountry(isoCode: 'RW', name: "Rwanda"),
    CustomerCountry(isoCode: 'RE', name: "R\u00e9union"),
    CustomerCountry(isoCode: 'BL', name: "Saint Barth\u00e9lemy"),
    CustomerCountry(
        isoCode: 'SH', name: "Saint Helena, Ascension and Tristan da Cunha"),
    CustomerCountry(isoCode: 'KN', name: "Saint Kitts and Nevis"),
    CustomerCountry(isoCode: 'LC', name: "Saint Lucia"),
    CustomerCountry(isoCode: 'MF', name: "Saint Martin (French part)"),
    CustomerCountry(isoCode: 'PM', name: "Saint Pierre and Miquelon"),
    CustomerCountry(isoCode: 'VC', name: "Saint Vincent and the Grenadines"),
    CustomerCountry(isoCode: 'WS', name: "Samoa"),
    CustomerCountry(isoCode: 'SM', name: "San Marino"),
    CustomerCountry(isoCode: 'ST', name: "Sao Tome and Principe"),
    CustomerCountry(isoCode: 'SA', name: "Saudi Arabia"),
    CustomerCountry(isoCode: 'SN', name: "Senegal"),
    CustomerCountry(isoCode: 'RS', name: "Serbia"),
    CustomerCountry(isoCode: 'SC', name: "Seychelles"),
    CustomerCountry(isoCode: 'SL', name: "Sierra Leone"),
    CustomerCountry(isoCode: 'SG', name: "Singapore"),
    CustomerCountry(isoCode: 'SX', name: "Sint Maarten (Dutch part)"),
    CustomerCountry(isoCode: 'SK', name: "Slovakia"),
    CustomerCountry(isoCode: 'SI', name: "Slovenia"),
    CustomerCountry(isoCode: 'SB', name: "Solomon Islands"),
    CustomerCountry(isoCode: 'SO', name: "Somalia"),
    CustomerCountry(isoCode: 'ZA', name: "South Africa"),
    CustomerCountry(
        isoCode: 'GS', name: "South Georgia and the South Sandwich Islands"),
    CustomerCountry(isoCode: 'KR', name: "South Korea"),
    CustomerCountry(isoCode: 'SS', name: "South Sudan"),
    CustomerCountry(isoCode: 'ES', name: "Spain"),
    CustomerCountry(isoCode: 'LK', name: "Sri Lanka"),
    CustomerCountry(isoCode: 'SD', name: "Sudan"),
    CustomerCountry(isoCode: 'SR', name: "Suriname"),
    CustomerCountry(isoCode: 'SJ', name: "Svalbard and Jan Mayen"),
    CustomerCountry(isoCode: 'SE', name: "Sweden"),
    CustomerCountry(isoCode: 'CH', name: "Switzerland"),
    CustomerCountry(isoCode: 'SY', name: "Syria"),
    CustomerCountry(isoCode: 'TW', name: "Taiwan"),
    CustomerCountry(isoCode: 'TJ', name: "Tajikistan"),
    CustomerCountry(isoCode: 'TZ', name: "Tanzania"),
    CustomerCountry(isoCode: 'TH', name: "Thailand"),
    CustomerCountry(isoCode: 'TL', name: "Timor-Leste"),
    CustomerCountry(isoCode: 'TG', name: "Togo"),
    CustomerCountry(isoCode: 'TK', name: "Tokelau"),
    CustomerCountry(isoCode: 'TO', name: "Tonga"),
    CustomerCountry(isoCode: 'TT', name: "Trinidad and Tobago"),
    CustomerCountry(isoCode: 'TN', name: "Tunisia"),
    CustomerCountry(isoCode: 'TM', name: "Turkmenistan"),
    CustomerCountry(isoCode: 'TC', name: "Turks and Caicos Islands"),
    CustomerCountry(isoCode: 'TV', name: "Tuvalu"),
    CustomerCountry(isoCode: 'TR', name: "T\u00fcrkiye"),
    CustomerCountry(isoCode: 'UG', name: "Uganda"),
    CustomerCountry(isoCode: 'UA', name: "Ukraine"),
    CustomerCountry(isoCode: 'AE', name: "United Arab Emirates"),
    CustomerCountry(isoCode: 'GB', name: "United Kingdom"),
    CustomerCountry(isoCode: 'US', name: "United States"),
    CustomerCountry(
        isoCode: 'UM', name: "United States Minor Outlying Islands"),
    CustomerCountry(isoCode: 'UY', name: "Uruguay"),
    CustomerCountry(isoCode: 'UZ', name: "Uzbekistan"),
    CustomerCountry(isoCode: 'VU', name: "Vanuatu"),
    CustomerCountry(isoCode: 'VE', name: "Venezuela"),
    CustomerCountry(isoCode: 'VN', name: "Vietnam"),
    CustomerCountry(isoCode: 'VG', name: "Virgin Islands, British"),
    CustomerCountry(isoCode: 'VI', name: "Virgin Islands, U.S."),
    CustomerCountry(isoCode: 'WF', name: "Wallis and Futuna"),
    CustomerCountry(isoCode: 'EH', name: "Western Sahara"),
    CustomerCountry(isoCode: 'YE', name: "Yemen"),
    CustomerCountry(isoCode: 'ZM', name: "Zambia"),
    CustomerCountry(isoCode: 'ZW', name: "Zimbabwe"),
    CustomerCountry(isoCode: 'AX', name: "\u00c5land Islands"),
  ];

  static CustomerCountry? byIsoCode(String? isoCode) {
    if (isoCode == null) {
      return null;
    }
    final normalized = isoCode.trim().toUpperCase();
    for (final country in all) {
      if (country.normalizedIsoCode == normalized) {
        return country;
      }
    }
    return null;
  }
}

/// Local/demo customer-country state.
///
/// The current demo starts with Egypt. In production Laravel should become the
/// source of truth for the authenticated customer's country and the available
/// country configuration (currency, branches, products and delivery rules).
class CustomerCountryStore {
  CustomerCountryStore._();

  static const String _isoKey = 'getin_demo_customer_country_iso';
  static const String _nameKey = 'getin_demo_customer_country_name';

  static final ValueNotifier<CustomerCountry> current =
      ValueNotifier<CustomerCountry>(
    const CustomerCountry(
      isoCode: 'EG',
      name: 'Egypt',
    ),
  );

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isoCode = prefs.getString(_isoKey);
    if (isoCode == null || isoCode.trim().isEmpty) {
      return;
    }

    final catalogCountry = CustomerCountryCatalog.byIsoCode(isoCode);
    if (catalogCountry != null) {
      current.value = catalogCountry;
      return;
    }

    final name = prefs.getString(_nameKey);
    if (name != null && name.trim().isNotEmpty) {
      current.value = CustomerCountry(isoCode: isoCode, name: name.trim());
    }
  }

  static Future<void> setCountry(CustomerCountry country) async {
    current.value = country;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_isoKey, country.normalizedIsoCode);
    await prefs.setString(_nameKey, country.name);
  }
}
