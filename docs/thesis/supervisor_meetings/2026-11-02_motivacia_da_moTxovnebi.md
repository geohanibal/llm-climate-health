# შეხვედრა 2026-11-02 (ორშაბათი): მოტივაცია, მოთხოვნები, Case Studies

**დავალება წინა შეხვედრიდან** (Barkowsky-ს მეილი, ოქტ. 2026, იხ. KB §3): სანიმუშო პუბლიკაციები (data-based modeling)
გამოვიყენო (1) მოტივაციისთვის, (2) მოთხოვნების გამოსაყვანად, (3) Case Study-ებად სისტემის დემონსტრაციისთვის.

> **ენა:** კითხვები ქართულადაა, რომ კარგად გაიგო, თითოეულს ქვეშ კი მოკლე გერმანული ფორმულირება აქვს, რომელიც
> შეხვედრაზე შეგიძლია პირდაპირ გამოიყენო. თუ შეხვედრა ინგლისურად იქნება, მითხარი და ინგლისურ ვერსიას დავამატებ.

---

## 1. რას ვაჩვენებ (5–10 წუთი)

1. **არგუმენტაციის ჯაჭვი** (KB §3.1): მკვლევარი ქმნის მოდელს → მანამდე ბევრი მონაცემთა მომზადების ნაბიჯი
   → ნაბიჯები ტიპურია → პროგრამირებას და დროს მოითხოვს → სისტემა მათ ავტომატიზებს.
2. **სამი წაკითხული სტატია**:
   - Suttirat et al. 2026 (დენგე, ტაილანდი): მთავარი Case Study, 13 ნაბიჯი;
   - Lowe et al. 2021 (დენგე, ბრაზილია): იგივე ნაბიჯები, ანუ ტიპურია;
   - Clarke et al. 2024 (OpenDengue): „Locating, extracting, processing and standardising data all takes time“ (p. 2).
3. **ლიტერატურიდან გამოყვანილი მოთხოვნები**: ცხრილი „ნაბიჯი სტატიაში → მოთხოვნა → სისტემის სტატუსი“
   (lag სვეტები, Tmin/Tmax, lag buffer, provenance/ლიცენზია, ხარვეზების აღმოჩენა). ყოველ მოთხოვნას სტატია და გვერდი აქვს.
4. **Case Study 1-ის გეგმა**: ხელით vs. სისტემით, დროისა და სისწორის შედარება (`evaluation_protocol_CS1.md`).
5. **ლიტერატურიდან აღმოჩენილი სისტემის ხარვეზები**: ერთი კლიმატის წერტილი, მოსახლეობა არ ინტერპოლირდება, ექსპორტში
   წყარო, ვერსია და ლიცენზია არ ჩანს. ესენი ახლა გასწორების პროცესშია.

---

## 2. კითხვები: მიდგომის დადასტურება (ყველაზე მნიშვნელოვანი)

**2.1** სწორად გავიგე დავალება? მოტივაცია ასე ავაგე: „მეცნიერს მოდელისთვის მონაცემები სჭირდება, მათი მომზადება ბევრ
ხელით და განმეორებად ნაბიჯს მოიცავს, ჩემი სისტემა ამ ნაბიჯებს ამარტივებს“. ეს არის ის, რაც იგულისხმეთ?
> *„Ich habe die Motivation so aufgebaut: Forschende brauchen für ihre Modelle Daten, deren Aufbereitung viele manuelle,
> wiederkehrende Schritte erfordert – mein System vereinfacht diese Schritte. Entspricht das Ihrer Vorstellung?“*

**პასუხი:** …

**2.2** საკმარისია მოტივაციისთვის **ორი მოდელირების სტატია + ერთი მონაცემთა სტატია**, თუ კიდევ 1–2 სტატია მოვძებნო,
რომ „ნაბიჯები ტიპურია“ უფრო ძლიერად გამოჩნდეს?
> *„Reichen zwei Modellierungsstudien und ein Data Descriptor als Grundlage, oder soll ich weitere Studien hinzunehmen,
> um zu zeigen, dass die Schritte typisch sind?“*

**პასუხი:** …

**2.3** მოთხოვნების გამოყვანა: საკმარისია ცხრილი „ნაბიჯი სტატიაში → მოთხოვნა“ (traceability matrix)? და რა ვუყო
**ძველ** მოთხოვნებს, რომლებიც ლიტერატურიდან არ მოდის (მაგ. რუკა, PDF ანგარიში, ჩატი)? შევინარჩუნო, როგორც
„გამოყენებადობის მოთხოვნები“, თუ ამოვიღო?
> *„Genügt eine Traceability-Matrix (Schritt in der Publikation → Anforderung)? Wie gehe ich mit bestehenden
> Anforderungen um, die nicht aus der Literatur stammen (Karte, PDF-Bericht, Chat) – als Usability-Anforderungen
> begründen oder streichen?“*

**პასუხი:** …

---

## 3. კითხვები: Case Studies

**3.1** CS1 (Suttirat-ის მონაცემთა მომზადების გამარტივებული რეპროდუქცია ქვეყნის დონეზე, ხელით vs. სისტემით): ეს
შეფასების მიდგომა მისაღებია? საკმარისია, რომ ტესტერი მე ვარ (დეველოპერი), თუ მეორე ტესტერი სჭირდება?
> *„Ist der Vergleich manuell vs. System für CS1 als Evaluation akzeptabel? Reiche ich als einziger Tester (Entwickler)
> oder brauche ich eine zweite Person?“*

**პასუხი:** …

**3.2** Suttirat-ის Zenodo-ს მონაცემები შეიძლება გამოვიყენო შედარებისთვის (პროვინციების მონაცემების ეროვნულ დონეზე შეკრება და
ჩემი სისტემის შედეგთან შედარება)?
> *„Darf ich die Zenodo-Daten von Suttirat et al. zum Vergleich verwenden?“*

**პასუხი:** …

**3.3** (Haddawy-ს) რამდენი დრო დასჭირდა Suttirat et al.-ის ჯგუფს მონაცემთა მომზადებას? ამის მიახლოებითი ციფრიც
ძალიან გამაძლიერებს არგუმენტს. შეიძლება ჩემი ნაშრომის ციტირება, როგორც „personal communication“?
> *„Wie viel Zeit hat die Datenaufbereitung in der Studie von Suttirat et al. ungefähr gekostet? Darf ich das als
> persönliche Mitteilung zitieren?“*

**პასუხი:** …

**3.4** CS2 და CS3: რომელი შემთხვევები მირჩევთ? ჩემი იდეები:
- **ბრაზილია** (Lowe 2021): მონაცემები და კოდი ღიაა (GitHub/Zenodo);
- **მალარია ან ქოლერა**: სისტემა სხვა დაავადებასაც რომ ამუშავებს. პრობლემა ისაა, რომ WHO GHO-ს მონაცემები წლიურია;
- **მკვლევრის საკუთარი CSV** + ავტომატური კლიმატი.
> *„Welche Fallstudien empfehlen Sie für CS2/CS3? Ideen: Brasilien (Lowe 2021, offene Daten), Malaria/Cholera
> (aber WHO-Daten nur jährlich), eigene CSV-Daten mit automatischem Klima-Matching.“*

**პასუხი:** …

---

## 4. კითხვები: სისტემის ფარგლები (რა გავაკეთო და რა ჩავწერო შეზღუდვად)

ორივე სტატია კლიმატს **რეგიონის მთელ ფართობზე** აშუალოებს, ჩემი სისტემა კი **ერთ წერტილს** იღებს. ასევე იყენებენ
პროვინციის დონის მონაცემებს და Tmin/Tmax-ს.

**4.1** რომელია ბაკალავრის ნაშრომის ფარგლებში აუცილებელი, და რომელი შეიძლება Limitation / Future Work იყოს?

| # | ფუნქცია | ჩემი შეფასება |
|---|---|---|
| a | Tmin/Tmax | მარტივია, გავაკეთებ |
| b | lag სვეტები (+ lag buffer) | მარტივია, გავაკეთებ |
| c | რამდენიმე წერტილი ან რეგიონის საშუალო (A6) | საშუალო სირთულე |
| d | პროვინციის დონე (A8) | რთულია |
| e | კვირეული რეზოლუცია (A4) | საშუალო სირთულე |
| f | გვალვის ინდექსი (A23) | რთულია, Future Work |

> *„Welche Erweiterungen sind im Rahmen der Bachelorarbeit notwendig, welche kann ich als Limitation/Future Work
> behandeln? (Tmin/Tmax, Lag-Spalten, Flächenmittel statt Einzelpunkt, Provinzebene, wöchentliche Auflösung,
> Dürreindex)“*

**პასუხი:** …

**4.2** ავტომატური ხარვეზების შევსება სხვა წყაროდან **განზრახ არ** გავაკეთე (განსხვავებული განსაზღვრებები და
რეზოლუციები). ეთანხმებით ამ გადაწყვეტილებას?
> *„Ich fülle Datenlücken bewusst nicht automatisch aus anderen Quellen (unterschiedliche Falldefinitionen und
> Auflösungen), sondern zeige Lücken an und schlage Alternativen vor. Einverstanden?“*

**პასუხი:** …

---

## 5. კითხვები: ლიტერატურა და ფორმალური საკითხები

**5.1** რამდენი წყაროა მოსალოდნელი? რომელ თემებზე მჭირდება აუცილებლად: Related Work (არსებული ინსტრუმენტები),
LLM მონაცემთა დამუშავებაში?
> *„Wie viele Quellen werden ungefähr erwartet, und zu welchen Themen unbedingt (Related Work, LLMs in der
> Datenaufbereitung)?“*

**პასუხი:** …

**5.2** ციტირების სტილი: რიცხვითი (IEEE) თუ author-year (APA ან მსგავსი)? არის უნივერსიტეტის/ფაკულტეტის შაბლონი?
> *„Welcher Zitierstil (numerisch oder Autor-Jahr)? Gibt es eine Vorlage?“*

**პასუხი:** …

**5.3** შეიძლება, რომ Suttirat et al. 2026 (Prof. Haddawy თანაავტორია) იყოს მთავარი Case Study? ეს პრობლემა ხომ არ
არის თეზისის დამოუკიდებლობისთვის?
> *„Ist es in Ordnung, dass eine Publikation mit Prof. Haddawy als Koautor die zentrale Fallstudie ist?“*

**პასუხი:** …

**5.4** თეზისის სავარაუდო სტრუქტურა და მოცულობა (გვერდები)? ჩაბარების თარიღი?
> *„Gibt es Vorgaben zu Gliederung und Umfang? Wann ist der Abgabetermin?“*

**პასუხი:** …

---

## 6. მოსალოდნელი კითხვები და მომზადებული პასუხები

### „რატომ მხოლოდ დენგე? მალარია და ქოლერა რატომ არა?“

**ფაქტები სისტემიდან (შემოწმებულია 2026-10-31, `config.py`, `backend/app/data/`):**
- მალარია და ქოლერა სისტემაში **ჩართულია** (WHO GHO), მაგრამ მხოლოდ **წლიური, ქვეყნის დონის** მონაცემებით.
- მალარია: WHO-ს **მოდელირებული შეფასებებია** („estimated number of malaria cases (modelled)“), და არა
  დარეგისტრირებული შემთხვევები. ფაილში 110 ქვეყანაა.
- ქოლერა: დარეგისტრირებული შემთხვევები, მაგრამ ძალიან **მწირი**: 216 ჩანაწერი, 71 ქვეყანა.
- დენგე: OpenDengue, **თვიური**, 39 რეგიონი.

**პასუხი (სამი არგუმენტი):**
1. **დროითი რეზოლუცია.** ორივე სტატიაში კლიმატის ეფექტი **0–6 თვის** დაგვიანებით ჩანს (Suttirat 2026; Lowe 2021,
   p. e212). წლიურ მონაცემებში ასეთი ეფექტი ვერ გამოჩნდება. ამიტომ ვალიდაცია ისეთ დაავადებაზე გავაკეთე, რომლისთვისაც
   ღია თვიური მონაცემები არსებობს.
2. **სისტემა დაავადებაზე დამოკიდებული არ არის** (FR-12). მალარია და ქოლერა უკვე მუშაობს; ტექნიკურად ახალი დაავადება
   მხოლოდ ახალი წყაროს რეგისტრაციაა. თვიური მონაცემების CSV ატვირთვით ნებისმიერი დაავადება მუშავდება.
3. **ხელმძღვანელის კვლევითი კონტექსტი.** მთავარი სანიმუშო სტატია (Suttirat et al. 2026) დენგეზეა, ამიტომ მასზე
   მოთხოვნების გამოყვანა და შედარება ყველაზე ზუსტად ხერხდება.

**ღიად აღიარე:** ეს შეზღუდვაა. ზოგადობის საჩვენებლად Case Study 2 დაგეგმილია მეორე დაავადებაზე (კითხვა 3.4).

> *„Dengue ist der Validierungsfall, weil es dafür mit OpenDengue offene, monatliche Falldaten gibt. Die Klimaeffekte
> treten in den Studien mit 0–6 Monaten Verzögerung auf (Lowe et al. 2021, S. e212) – mit Jahresdaten, wie sie die WHO
> für Malaria und Cholera bereitstellt, wären sie nicht sichtbar. Malaria und Cholera sind im System bereits
> angebunden; das System ist krankheitsunabhängig, eigene Monatsdaten können per CSV hochgeladen werden. Um die
> Übertragbarkeit zu zeigen, plane ich eine zweite Fallstudie mit einer anderen Krankheit.“*

**თუ ჰკითხავენ „მალარიაზე რატომ არ გამოიყენე WHO-ს მონაცემები?“:** ეს WHO-ს მოდელით შეფასებული რიცხვებია და არა
დაკვირვებები. თუ მათ ახალი კლიმატ-ჯანმრთელობის მოდელის შესაქმნელად გამოვიყენებ, ერთი მოდელის შედეგი მეორეს
შესავალი გახდება. ამიტომ ასეთი მონაცემები სიფრთხილით უნდა იქნას გამოყენებული. (WHO-ს შეფასების მეთოდი ჯერ არ
წამიკითხავს: არ თქვა, რომ ისინი კლიმატს იყენებენ.)

---

## 7. შეხვედრის შემდეგ (შეავსე)

- **მთავარი გადაწყვეტილებები:** …
- **ახალი დავალებები შემდეგი შეხვედრისთვის:** …
- **შემდეგი შეხვედრის თარიღი:** …

შემდეგ Claude-ს უთხარი „შეხვედრის შედეგები ჩაწერე“.
