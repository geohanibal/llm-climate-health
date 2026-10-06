/// Model representing a scientific literature corpus or custom user-provided publication
/// used for grounding the Climate-Health AI Copilot and statistical analyses.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';

class LiteratureItem {
  final LiteratureCorpus corpus;
  final String id;
  final String tag;
  final String title;
  final String authors;
  final String year;
  final String journal;
  final String citation;
  final String? url;
  final String focusKa;
  final String focusEn;
  final String focusDe;
  final String differencesKa;
  final String differencesEn;
  final String differencesDe;
  final String abstractKa;
  final String abstractEn;
  final String abstractDe;
  final String methodologyKa;
  final String methodologyEn;
  final String methodologyDe;
  final String keyFindingsKa;
  final String keyFindingsEn;
  final String keyFindingsDe;
  final IconData icon;
  final bool isCustom;
  final String? attachedFileName;
  final String? fullContent;

  const LiteratureItem({
    required this.corpus,
    required this.id,
    required this.tag,
    required this.title,
    required this.authors,
    required this.year,
    required this.journal,
    required this.citation,
    this.url,
    required this.focusKa,
    required this.focusEn,
    required this.focusDe,
    required this.differencesKa,
    required this.differencesEn,
    required this.differencesDe,
    required this.abstractKa,
    required this.abstractEn,
    required this.abstractDe,
    required this.methodologyKa,
    required this.methodologyEn,
    required this.methodologyDe,
    required this.keyFindingsKa,
    required this.keyFindingsEn,
    required this.keyFindingsDe,
    this.icon = Icons.menu_book_rounded,
    this.isCustom = false,
    this.attachedFileName,
    this.fullContent,
  });

  String getFocus(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ka:
        return focusKa;
      case AppLanguage.de:
        return focusDe;
      case AppLanguage.en:
        return focusEn;
    }
  }

  String getDifferences(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ka:
        return differencesKa;
      case AppLanguage.de:
        return differencesDe;
      case AppLanguage.en:
        return differencesEn;
    }
  }

  String getAbstract(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ka:
        return abstractKa;
      case AppLanguage.de:
        return abstractDe;
      case AppLanguage.en:
        return abstractEn;
    }
  }

  String getMethodology(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ka:
        return methodologyKa;
      case AppLanguage.de:
        return methodologyDe;
      case AppLanguage.en:
        return methodologyEn;
    }
  }

  String getKeyFindings(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ka:
        return keyFindingsKa;
      case AppLanguage.de:
        return keyFindingsDe;
      case AppLanguage.en:
        return keyFindingsEn;
    }
  }

  String getBibTeX() {
    final firstAuthor = authors.split(',').first.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final citeKey = '$firstAuthor$year';
    return '''@article{$citeKey,
  title = {$title},
  author = {$authors},
  journal = {$journal},
  year = {$year}${url != null ? ',\n  url = {$url}' : ''}
}''';
  }
}

final List<LiteratureItem> kScientificCorpora = [
  const LiteratureItem(
    corpus: LiteratureCorpus.who,
    id: 'who_guidelines',
    tag: 'WHO 2020 / 2024',
    title: 'Global Vector Control Response 2017–2030 & Operational Guidelines',
    authors: 'World Health Organization (WHO)',
    year: '2020',
    journal: 'WHO Technical Report Series & Guidelines Review Committee',
    citation:
        'World Health Organization. (2020). Global vector control response 2017–2030. WHO Guidelines Approved by the Guidelines Review Committee.',
    url: 'https://www.who.int/publications/i/item/9789241512978',
    focusKa:
        'კლინიკური მეთვალყურეობა, ეპიდემიოლოგიური ზღვრები (outbreak alert thresholds) და გადაუდებელი ვექტორული ინტერვენციები.',
    focusEn:
        'Clinical disease surveillance, epidemiological outbreak alert thresholds, and immediate vector control interventions.',
    focusDe:
        'Klinische Krankheitsüberwachung, epidemiologische Ausbruchsschwellenwerte und sofortige Vektorkontrollmaßnahmen.',
    differencesKa:
        'აქცენტი კეთდება რეალურ-დროის შემთხვევების რეგისტრაციაზე, საზოგადოებრივი ჯანდაცვის რეაგირებაზე და ლოკალურ ზღვრულ მაჩვენებლებზე.',
    differencesEn:
        'Emphasizes operational public health actions, case reporting protocols, and immediate larval reduction rather than climate projections.',
    differencesDe:
        'Konzentriert sich auf operative Maßnahmen des öffentlichen Gesundheitswesens und Meldeschwellen anstelle von Klimaprojektionen.',
    abstractKa:
        'WHO-ს გლობალური სტრატეგიული გზამკვლევი ადგენს ეპიდემიოლოგიური მონიტორინგის სტანდარტებს ვექტორული დაავადებების წინააღმდეგ. დოკუმენტი დეტალურად აღწერს ეპიდემიური აფეთქების ადრეული გაფრთხილების სისტემებს, შემთხვევათა რეგისტრაციის პროტოკოლებს და ლარვების განადგურების სასწრაფო ღონისძიებებს.',
    abstractEn:
        'The WHO strategic guidance establishes epidemiological monitoring benchmarks against vector-borne pathogens. The guidelines detail early warning epidemic alert systems, notification tracking, and targeted community-level vector control operations.',
    abstractDe:
        'Die strategische Leitlinie der WHO legt Benchmarks für die epidemiologische Überwachung vektorgebundener Krankheiten fest. Sie definiert Frühwarnsysteme, Meldeprotokolle und gezielte Maßnahmen zur Larvenbekämpfung.',
    methodologyKa:
        'პასიური და აქტიური კლინიკური ზედამხედველობა, ბრეტოს ინდექსის (Breteau Index) და სახლის ინდექსის მონიტორინგი, ზღვრული მაჩვენებლების გამოთვლა (საშუალო + 2 სტანდარტული გადახრა წინა 5 წლის ბაზაზე).',
    methodologyEn:
        'Passive and active clinical surveillance, entomological larval surveys (Breteau Index, House Index), and endemic channel alert thresholds (mean + 2 standard deviations over a 5-year baseline).',
    methodologyDe:
        'Passive und aktive klinische Überwachung, entomologische Larvenerhebungen (Breteau-Index) und Schwellenwert-Berechnungen (Mittelwert + 2 Standardabweichungen).',
    keyFindingsKa:
        'შემთხვევათა დროული გამოვლენა პირველი 2 კვირის განმავლობაში ამცირებს სიკვდილიანობას 50%-ზე მეტით. ვექტორული კონტროლის დაწყება წვიმების სეზონამდე (Pre-monsoon) კრიტიკულია ეპიდემიური პიკის შესაკავებლად.',
    keyFindingsEn:
        'Prompt detection within the initial 2 weeks reduces severe mortality by >50%. Initiating vector control operations in the pre-monsoon period is critical to flattening the epidemic curve.',
    keyFindingsDe:
        'Eine frühzeitige Erkennung in den ersten 2 Wochen senkt die Mortalität um über 50%. Vektorkontrollmaßnahmen vor Beginn der Regenzeit sind entscheidend zur Eindämmung.',
    icon: Icons.local_hospital_outlined,
  ),
  const LiteratureItem(
    corpus: LiteratureCorpus.lancet,
    id: 'lancet_countdown',
    tag: 'The Lancet 2023',
    title: 'The 2023 Report of the Lancet Countdown on Health and Climate Change',
    authors: 'Romanello, M., Di Napoli, C., Drummond, P., et al.',
    year: '2023',
    journal: 'The Lancet, 402(10419), 2346-2394',
    citation:
        'Romanello, M., et al. (2023). The 2023 report of the Lancet Countdown on health and climate change: the imperative for a health-centred response. The Lancet, 402(10419), 2346-2394.',
    url: 'https://doi.org/10.1016/S0140-6736(23)01859-4',
    focusKa:
        'კლიმატის ცვლილების ატრიბუცია, დაავადების გადაცემის ეკოლოგიური ხელსაყრელობის (R0) ზრდა და მოსახლეობის მოწყვლადობა.',
    focusEn:
        'Climate change attribution, shifts in environmental transmission suitability (R0), and population exposure metrics.',
    focusDe:
        'Klimawandel-Attribution, Veränderungen der Umweltübertragungseignung (R0) und Exposition der Bevölkerung.',
    differencesKa:
        'ფოკუსირებულია გლობალურ და რეგიონულ ტენდენციებზე, ტემპერატურისა და ნალექების ცვლილების გავლენაზე გადამტანების გავრცელების არეალზე.',
    differencesEn:
        'Focuses on macro-level climate attribution, quantifying how anthropogenic global warming increases transmission suitability.',
    differencesDe:
        'Fokussiert auf Makro-Klimaattribution und quantifiziert, wie die Erwärmung die Übertragungseignung global erhöht.',
    abstractKa:
        'Lancet Countdown-ის ყოველწლიური სამეცნიერო ანგარიში წარმოადგენს გლობალურ კვლევას კლიმატის ცვლილების გავლენაზე ადამიანის ჯანმრთელობაზე. კვლევა ზომავს ტემპერატურისა და ტენიანობის ზრდის გავლენას დენგეს, მალარიისა და სხვა ვექტორული დაავადებების გადაცემის ეკოლოგიურ პოტენციალზე.',
    abstractEn:
        'The Lancet Countdown comprehensive annual report monitors the emerging health impacts of climate change globally. It quantitatively tracks environmental transmission suitability for dengue, malaria, and vibrio pathogens under changing thermodynamic baselines.',
    abstractDe:
        'Der jährliche Bericht des Lancet Countdown quantifiziert die globalen gesundheitlichen Auswirkungen der Klimaerwärmung und modelliert die klimatische Eignung für Vektorübertragungen.',
    methodologyKa:
        'მათემატიკური ეპიდემიოლოგიური მოდელირება (R0 სიმულაციები), დაფუძნებული ECMWF ERA5 კლიმატურ რეანალიზზე, ორთქლის წნევასა და ნალექების გლობალურ ბადურ მონაცემებზე.',
    methodologyEn:
        'Mathematical transmission modeling (R0 suitability index) parameterized by ERA5 gridded reanalysis temperature, vapor pressure, and precipitation fields over multidecadal observation periods.',
    methodologyDe:
        'Mathematische Übertragungsmodellierung (R0-Eignungsindex) basierend auf ERA5-Reanalysedaten für Temperatur, Dampfdruck und Niederschlag.',
    keyFindingsKa:
        'Aedes aegypti-ით დენგეს გადაცემის კლიმატური ხელსაყრელობა 28.6%-ით, ხოლო Aedes albopictus-ით 43.1%-ით გაიზარდა 1951-1960 წლების საბაზისო პერიოდთან შედარებით.',
    keyFindingsEn:
        'Global climate suitability for dengue transmission has increased by 28.6% for Aedes aegypti and 43.1% for Aedes albopictus relative to the 1951–1960 baseline.',
    keyFindingsDe:
        'Die klimatische Übertragungseignung für Dengue stieg um 28,6% für Aedes aegypti und 43,1% für Aedes albopictus im Vergleich zum Zeitraum 1951–1960.',
    icon: Icons.public_outlined,
  ),
  const LiteratureItem(
    corpus: LiteratureCorpus.ipcc,
    id: 'ipcc_ar6_wg2',
    tag: 'IPCC AR6 2022',
    title: 'Climate Change 2022: Impacts, Adaptation and Vulnerability (Chapter 7: Health)',
    authors: 'Intergovernmental Panel on Climate Change (IPCC WGII)',
    year: '2022',
    journal: 'Cambridge University Press (IPCC Sixth Assessment Report)',
    citation:
        'IPCC. (2022). Climate Change 2022: Impacts, Adaptation and Vulnerability. Contribution of Working Group II to the Sixth Assessment Report. Cambridge Univ. Press.',
    url: 'https://www.ipcc.ch/report/ar6/wg2/chapter/chapter-7/',
    focusKa:
        'გრძელვადიანი კლიმატური პროექციები (2030–2100), ექსტრემალური ნალექები, წყალდიდობები და კომპლექსური რისკები (Compound hazards).',
    focusEn:
        'Multi-decadal climate projections (2030–2100), extreme rainfall events, floodings, and compound cascading health risks.',
    focusDe:
        'Mehrdekadische Klimaprojektionen (2030–2100), Starkregenereignisse, Überschwemmungen und kaskadierende Gesundheitsrisiken.',
    differencesKa:
        'იკვლევს მრავალათწლიან სცენარებს (SSPs) და ადაპტაციის პოლიტიკას, განსხვავებით ყოველთვიური ეპიდემიოლოგიური რყევებისგან.',
    differencesEn:
        'Evaluates multi-decadal Shared Socioeconomic Pathways (SSPs) and structural resilience rather than monthly surveillance cycles.',
    differencesDe:
        'Bewertet mehrdekadische sozioökonomische Pfade (SSPs) und Anpassungsresilienz anstelle monatlicher Überwachungszyklen.',
    abstractKa:
        'გაეროს კლიმატის ცვლილების სამთავრობათაშორისო ექსპერტთა ჯგუფის (IPCC) მეექვსე ანგარიშის მე-7 თავი ეძღვნება ჯანმრთელობას. მასში გაანალიზებულია გლობალური დათბობის გავლენა ინფექციურ დაავადებებზე 2030, 2050 და 2100 წლების ჰორიზონტზე.',
    abstractEn:
        'Chapter 7 of the IPCC WGII Sixth Assessment Report evaluates observed and projected impacts of climate change on human health, well-being, and healthcare system resilience across Shared Socioeconomic Pathways (SSPs).',
    abstractDe:
        'Kapitel 7 des sechsten IPCC-Sachstandsberichts analysiert beobachtete und prognostizierte Auswirkungen des Klimawandels auf die menschliche Gesundheit und Anpassungsstrategien.',
    methodologyKa:
        'კლიმატური მოდელების ანსამბლი (CMIP6), სოციო-ეკონომიკური განვითარების სცენარები (SSP1-2.6-დან SSP5-8.5-მდე) და მეტა-ანალიზი ათასობით რეცენზირებული კვლევისა.',
    methodologyEn:
        'Coupled model intercomparison ensemble (CMIP6), multi-scenario projections (SSP1-2.6 through SSP5-8.5), and systematic evidence synthesis across global health datasets.',
    methodologyDe:
        'CMIP6-Klimamodellensemble, sozioökonomische Szenarien (SSP1-2.6 bis SSP5-8.5) und systematische Synthese weltweiter Gesundheitsstudien.',
    keyFindingsKa:
        'ექსტრემალური ნალექები და წყალდიდობები, რასაც მოსდევს გახანგრძლივებული სიცხე, ქმნის „კომპლექსურ კასკადურ საფრთხეს“. ტროპიკულ და სუბტროპიკულ ზონებში ვექტორული დაავადებების სეზონი გახანგრძლივდება 1-4 თვით.',
    keyFindingsEn:
        'Compound climate hazards (heavy rainfall followed by persistent heat) generate cascading vulnerabilities. Transmission seasons for vector-borne diseases will lengthen by 1–4 months in subtropical transition zones.',
    keyFindingsDe:
        'Kaskadierende Extremereignisse (Starkregen gefolgt von Hitzewellen) verlängern die Übertragungssaison in subtropischen Zonen um 1 bis 4 Monate.',
    icon: Icons.shield_outlined,
  ),
  const LiteratureItem(
    corpus: LiteratureCorpus.mordecai,
    id: 'mordecai_2019',
    tag: 'Ecology Letters 2019',
    title: 'Thermal Biology of Mosquito-Borne Disease',
    authors: 'Mordecai, E. A., Caldwell, J. M., Grossman, M. K., et al.',
    year: '2019',
    journal: 'Ecology Letters, 22(10), 1690-1708',
    citation:
        'Mordecai, E. A., et al. (2019). Thermal biology of mosquito-borne disease. Ecology Letters, 22(10), 1690-1708.',
    url: 'https://doi.org/10.1111/ele.13330',
    focusKa:
        'კოღოს თერმული ბიოლოგია, არაწრფივი ოპტიმალური ტემპერატურა (24°C–29°C) და 1–3 თვიანი ბიოლოგიური დროითი დაყოვნება (Lags).',
    focusEn:
        'Mosquito thermal biology, non-linear optimal temperature curves (24°C–29°C), and 1–3 month biological transmission lags.',
    focusDe:
        'Thermale Biologie von Stechmücken, nicht-lineare optimale Temperaturkurven (24°C–29°C) und 1–3 monatige biologische Verzögerungen (Lags).',
    differencesKa:
        'უზრუნველყოფს ფიზიოლოგიურ მტკიცებულებას იმისა, თუ რატომ მოქმედებს წვიმა და ტემპერატურა დაგვიანებით (Lag 1-3 თვე) დაავადების შემთხვევებზე.',
    differencesEn:
        'Provides mechanistic biological proof for why precipitation and warmth drive disease peaks after a 1–3 month lag (breeding cycle).',
    differencesDe:
        'Liefert den mechanistischen biologischen Beweis für zeitverzögerte Effekte (Lags 1–3 Monate) zwischen Niederschlag und Fallzahlen.',
    abstractKa:
        'ფუნდამენტური ბიოფიზიკური კვლევა, რომელმაც ექსპერიმენტულად დაამტკიცა, რომ ტემპერატურის გავლენა კოღოზე და ვირუსზე არაწრფივია (Uni-modal thermal performance curve). კვლევა ადგენს ოპტიმალურ, მინიმალურ და მაქსიმალურ ტემპერატურულ ზღვრებს დენგესა და ზიკას გადაცემისთვის.',
    abstractEn:
        'Groundbreaking biophysical study demonstrating that temperature drives mosquito-borne disease transmission via unimodal, non-linear thermal performance curves. It mechanistically characterizes optimal, critical minimum, and critical maximum temperatures.',
    abstractDe:
        'Grundlegende biophysikalische Studie, die nachweist, dass Temperatur Vektorübertragungen über nicht-lineare, unimodale thermische Leistungskurven steuert.',
    methodologyKa:
        'ბაიესის თერმული მოდელირება (Bayesian fitting of thermal performance curves) ლაბორატორიულ ექსპერიმენტებზე: კბენის სიხშირე, კვერცხმდებლობა, ლარვის განვითარება, ზრდასრული კოღოს სიცოცხლის ხანგრძლივობა და ექსტრისული ინკუბაციის პერიოდი (EIP).',
    methodologyEn:
        'Bayesian synthesis and fitting of thermal traits across empirical datasets: mosquito biting rate, fecundity, larval development rate, adult daily survival, and pathogen extrinsic incubation period (EIP).',
    methodologyDe:
        'Bayessche Modellierung experimenteller Labordaten zu Stechrate, Larvenentwicklung, Überlebensrate und extrinsischer Inkubationszeit.',
    keyFindingsKa:
        'დენგეს გადაცემის თერმული ოპტიმუმია 29.1°C (Aedes aegypti) და 26.4°C (Aedes albopictus). ტემპერატურის 32°C-ზე ზემოთ აწევისას გადაცემა მკვეთრად ეცემა. ეს მოდელი ხსნის, რატომ ჩნდება ეპიდემიური პიკი წვიმისა და სითბოს მატებიდან 1-3 თვის შემდეგ (Lag effect).',
    keyFindingsEn:
        'Thermal transmission optima peak at 29.1°C for Aedes aegypti and 26.4°C for Aedes albopictus, collapsing above 32°C. Directly provides mechanistic biological proof for why peak clinical cases occur 1–3 months after temperature and rainfall surges.',
    keyFindingsDe:
        'Das thermische Optimum für Dengue liegt bei 29,1°C (Ae. aegypti) bzw. 26,4°C (Ae. albopictus) und bricht über 32°C ein. Dies erklärt die biologischen Verzögerungseffekte von 1–3 Monaten.',
    icon: Icons.biotech_outlined,
  ),
];

class CustomLiteratureStore extends ChangeNotifier {
  static final CustomLiteratureStore instance = CustomLiteratureStore._();
  CustomLiteratureStore._();

  final List<LiteratureItem> _customItems = [];
  List<LiteratureItem> get customItems => List.unmodifiable(_customItems);

  void addCustomItem(LiteratureItem item) {
    _customItems.insert(0, item);
    notifyListeners();
  }

  void removeCustomItem(String id) {
    _customItems.removeWhere((it) => it.id == id);
    notifyListeners();
  }

  void clear() {
    _customItems.clear();
    notifyListeners();
  }
}
