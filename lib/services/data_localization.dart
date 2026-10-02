class DataLocalization {
  static String get(String key, String locale) {
    if (locale == 'en') return key;

    // Normalize keys (trim, lowercase) for lookup if needed,
    // but here we expect exact match or we can try case-insensitive.
    // We will stick to exact match for performance, simplified.

    // Check States
    if (_states.containsKey(key)) {
      return _states[key]?[locale] ?? key;
    }

    // Check Mandis
    if (_mandis.containsKey(key)) {
      return _mandis[key]?[locale] ?? key;
    }

    // Check Commodities
    if (_commodities.containsKey(key)) {
      return _commodities[key]?[locale] ?? key;
    }

    return key;
  }

  static const Map<String, Map<String, String>> _states = {
    "Andhra Pradesh": {"hi": "आंध्र प्रदेश", "te": "ఆంధ్ర ప్రదేశ్"},
    "Maharashtra": {"hi": "महाराष्ट्र", "te": "మహారాష్ట్ర"},
    "Uttar Pradesh": {"hi": "उत्तर प्रदेश", "te": "ఉత్తర ప్రదేశ్"},
    "Punjab": {"hi": "पंजाब", "te": "పంజాబ్"},
    "Karnataka": {"hi": "कर्नाटक", "te": "కర్ణాటక"},
    "Telangana": {"hi": "तेलंगाना", "te": "తెలంగాణ"},
    "Madhya Pradesh": {"hi": "मध्य प्रदेश", "te": "మధ్య ప్రదేశ్"},
    "Gujarat": {"hi": "गुजरात", "te": "గుజరాత్"},
  };

  static const Map<String, Map<String, String>> _mandis = {
    // Andhra Pradesh
    "Adoni": {"hi": "अदोनी", "te": "ఆదోని"},
    "Anantapur": {"hi": "अनंतपुर", "te": "అనంతపురం"},
    "Guntur": {"hi": "गुंटूर", "te": "గుంటూరు"},
    "Madanapalle": {"hi": "मदनपल्ले", "te": "మదనపల్లె"},
    "Vijayawada": {"hi": "विजयवाड़ा", "te": "విజయవాడ"},
    "Rajahmundry": {"hi": "राजमुंदरी", "te": "రాజమండ్రి"},
    "Ongole": {"hi": "ओंगोल", "te": "ఒంగోలు"},
    "Tirupati": {"hi": "तिरुपति", "te": "తిరుపతి"},
    "Kadapa": {"hi": "कड़पा", "te": "కడప"},
    "Eluru": {"hi": "एलुरु", "te": "ఏలూరు"},

    // Telangana
    "Hyderabad": {"hi": "हैदराबाद", "te": "హైదరాబాదు"},
    "Warangal": {"hi": "वारंगल", "te": "వరంగల్"},
    "Nizamabad": {"hi": "निजामाबाद", "te": "నిజామాబాద్"},
    "Khammam": {"hi": "खम्मम", "te": "ఖమ్మం"},
    "Karimnagar": {"hi": "करीमनगर", "te": "కరీంనగర్"},

    // Maharashtra
    "Lasalgaon": {"hi": "लासलगांव", "te": "లాసల్‌గావ్"},
    "Pune": {"hi": "पुणे", "te": "పూణే"},
    "Nagpur": {"hi": "नागपुर", "te": "నాగపూర్"},
    "Nashik": {"hi": "नासिक", "te": "నాసిక్"},
    "Solapur": {"hi": "सोलापुर", "te": "షోలాపూర్"},
    "Kolhapur": {"hi": "कोल्हापुर", "te": "కొల్హాపూర్"},
    "Mumbai": {"hi": "मुंबई", "te": "ముంబై"},
    "Aurangabad": {"hi": "औरंगाबाद", "te": "ఔరంగాబాద్"},

    // Karnataka
    "Bengaluru": {"hi": "बेंगलुरु", "te": "బెంగళూరు"},
    "Mysuru": {"hi": "मैसूर", "te": "మైసూరు"},
    "Hubballi": {"hi": "हुबली", "te": "హుబ్బళ్ళి"},
    "Belagavi": {"hi": "बेलगावी", "te": "బెలగావి"},
    "Kolar": {"hi": "कोलार", "te": "కోలార్"},
    "Shivamogga": {"hi": "शिमोगा", "te": "శివమొగ్గ"},
    "Bagalkot": {"hi": "बागलकोट", "te": "బాగల్‌కోట్"},

    // Punjab
    "Khanna": {"hi": "खन्ना", "te": "ఖన్నా"},
    "Ludhiana": {"hi": "लुधियाना", "te": "లూధియానా"},
    "Amritsar": {"hi": "अमृतसर", "te": "అమృతసర్"},
    "Bhatinda": {"hi": "भठिंडा", "te": "భటిండా"},
    "Jalandhar": {"hi": "जालंधर", "te": "జలంధర్"},
    "Patiala": {"hi": "पटियाला", "te": "పాటియాలా"},

    // Uttar Pradesh
    "Agra": {"hi": "आगरा", "te": "ఆగ్రా"},
    "Kanpur": {"hi": "कानपुर", "te": "కాన్పూర్"},
    "Lucknow": {"hi": "लखनऊ", "te": "లక్నో"},
    "Varanasi": {"hi": "वाराणसी", "te": "వారణాసి"},
    "Prayagraj": {"hi": "प्रयागराज", "te": "ప్రయాగరాజ్"},
    "Meerut": {"hi": "मेरठ", "te": "మీరట్"},
    "Bareilly": {"hi": "बरेली", "te": "బరేలీ"},

    // Madhya Pradesh
    "Indore": {"hi": "इंदौर", "te": "ఇండోర్"},
    "Bhopal": {"hi": "भोपाल", "te": "భోపాల్"},
    "Ujjain": {"hi": "उज्जैन", "te": "ఉజ్జయిని"},
    "Mandsaur": {"hi": "मंदसौर", "te": "మందసౌర్"},

    // Gujarat
    "Ahmedabad": {"hi": "अहमदाबाद", "te": "అహ్మదాబాద్"},
    "Surat": {"hi": "सूरत", "te": "సూరత్"},
    "Rajkot": {"hi": "राजकोट", "te": "రాజ్‌కోట్"},
    "Unjha": {"hi": "ऊंझा", "te": "ఉంఝా"},
  };

  static const Map<String, Map<String, String>> _commodities = {
    "Paddy": {"hi": "धान", "te": "వరి"},
    "Rice": {"hi": "चावल", "te": "బియ్యం"},
    "Wheat": {"hi": "गेंहू", "te": "గోధుమలు"},
    "Maize": {"hi": " मक्का", "te": "మొక్కజొన్న"},
    "Cotton": {"hi": "कपास", "te": "పత్తి"},
    "Red Chilli": {"hi": "लाल मिर्च", "te": "ఎండు మిర్చి"},
    "Turmeric": {"hi": "हल्दी", "te": "పసుపు"},
    "Groundnut": {"hi": "मूंगफली", "te": "వేరుశనగ"},
    "Tomato": {"hi": "टमाटर", "te": "టమోటా"},
    "Onion": {"hi": "प्याज़", "te": "ఉల్లిపాయలు"},
    "Potato": {"hi": "आलू", "te": "బంగాళదుంప"},
    "Banana": {"hi": "केला", "te": "అరటిపండు"},
    "Mango": {"hi": "आम", "te": "మామిడి"},
    "Coconut": {"hi": "नारियल", "te": "కొబ్బరి"},
    "Soybean": {"hi": "सोयाबीन", "te": "సోయాబీన్"},
    "Sunflower": {"hi": "सूरजमुखी", "te": "పొద్దుతిరుగుడు"},
    "Black Gram": {"hi": "उड़द", "te": "మినుములు"},
    "Bengal Gram": {"hi": "चना", "te": "శనగలు"},
    "Pomegranate": {"hi": "अनार", "te": "దానిమ్మ"},
    "Grape": {"hi": "अंगूर", "te": "ద్రాక్ష"},
    "Jowar": {"hi": "ज्वार", "te": "జొన్నలు"},
    "Bajra": {"hi": "बाजरा", "te": "సజ్జలు"},
    "Jaggery": {"hi": "गुड़", "te": "బెల్లం"},
    "Vegetables": {"hi": "सब्जियां", "te": "కూరగాయలు"},
    "Mustard": {"hi": "सरसों", "te": "ఆవాలు"},
    "Peas": {"hi": "मटर", "te": "బఠానీలు"},
    "Guava": {"hi": "अमरूद", "te": "జామకాయ"},
    "Sugarcane": {"hi": "गन्ना", "te": "చెరకు"},
    "Mentha Oil": {"hi": "मेंथा तेल", "te": "మెంత ఆయిల్"},
    "Dry Chilli": {"hi": "सूखी मिर्च", "te": "ఎండు మిర్చి"},
    "Arecanut": {"hi": "सुपारी", "te": "వక్క"},
    "Ginger": {"hi": "अदरक", "te": "అల్లం"},
    "Fruits": {"hi": "फल", "te": "పండ్లు"},
    "Castor Seed": {"hi": "अरंडी बीज", "te": "ఆముదాలు"},
    "Cummin": {"hi": "जीरा", "te": "జీలకర్ర"},
    "Jeera (Cumin)": {"hi": "जीरा", "te": "జీలకర్ర"},
    "Fennel": {"hi": "सौंफ", "te": "సోంపు"},
    "Isabgol": {"hi": "इसबगोल", "te": "ఇసబ్గోల్"},
    "Sesame seed": {"hi": "तिल", "te": "నువ్వులు"},
    "Ragi": {"hi": "रागी", "te": "రాగులు"},
    "Moong Dal Split": {"hi": "मूंग दाल", "te": "పెసర పప్పు"},
    "Chana Dal Split": {"hi": "चना दाल", "te": "శనగ పప్పు"},
    "Urad Dal Split": {"hi": "उड़द दाल", "te": "మినప పప్పు"},
    "Toor Dal": {"hi": "तूअर दाल", "te": "కంది పప్పు"},
    "Arhar": {"hi": "अरहर", "te": "కందులు"},
    "Masoor whole": {"hi": "मसूर", "te": "ఎర్ర కందిపప్పు"},
    "Lemon": {"hi": "नींबू", "te": "నిమ్మకాయ"},
    "Garlic": {"hi": "लहसुन", "te": "వెల్లుల్లి"},
  };
}
