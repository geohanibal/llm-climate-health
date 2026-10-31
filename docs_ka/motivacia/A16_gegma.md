# A16 — Provenance (წარმომავლობა) CSV/JSON ექსპორტში

> **ვინ წერს:** სერგი (Dart + მცირე Python). Claude ხსნის და ამოწმებს.
> **პრიორიტეტი:** P0. **სავარაუდო დრო:** 1–2 საათი.
> **რეკომენდაცია:** `docs/thesis/RECOMMENDATIONS.md`, A16.

## რატომ (თეზისისთვის)

- **ხარვეზი (შემოწმდა 2026-10-31):** `climate_health_dataset (4).csv` / `.json`
  შეიცავს მხოლოდ 6 სვეტს. ფაილში არ წერია ქვეყანა, წყაროები, ვერსია, ლიცენზია
  ან ჩამოტვირთვის თარიღი.
- **ლიტერატურა:** Clarke et al. 2024 (OpenDengue):
  - გვ. 4: წყაროს მეტამონაცემები (თარიღი, URL, ნაბიჯები);
  - გვ. 12: ვერსიის მითითება, CC BY-SA ლიცენზია (ადაპტაციაც იმავე პირობებით
    უნდა გავრცელდეს).
- **ჯაჭვი თეზისში:** სტატია → მოთხოვნა → შემოწმება → გამოსწორება. ეს
  მოთხოვნების ლიტერატურიდან გამოყვანის მაგალითია.

## რა არსებობს უკვე

- Backend-ის პასუხში (`IntegrationResult`, `frontend/lib/models/integration_result.dart`)
  უკვე არის: `disease`, `region`, `resolution`, `steps`, `sources`,
  `lastVerified`, `transformationAudit`.
- პრობლემა: `DatasetExportService.export()` იღებს მხოლოდ `List<PeriodRecord>`.
- გამოძახების ადგილები: `widgets/dataset_table_card.dart` (ხაზი ~29, ~34),
  `widgets/chat_copilot_drawer.dart` (ხაზი ~409).

## ნაბიჯები

### 1. Backend (Python), მცირე
- `backend/app/config.py`: თითოეულ წყაროს (დაავადება, კლიმატი, მოსახლეობა)
  დაამატე `license` და (თუ ცნობილია) `dataset_version`.
  - OpenDengue: `license="CC BY-SA"`, `dataset_version="v1.x"` (ზუსტი ვერსია
    ჯერ დასადგენია, იხ. A13), DOI `10.6084/m9.figshare.24259573`.
  - ERA5/Open-Meteo, NASA POWER, World Bank: ლიცენზია მათ საიტზე შეამოწმე,
    არ გამოიგონო.
- `backend/app/models.py`, response: ახალი ველები, მაგ.
  `licenses: list[str]`, `system_version: str` (git commit ან `APP_VERSION`
  env ცვლადი Docker-ისთვის).
- `etl.py`: ეს ველები შეავსე.

### 2. Frontend (Dart), მთავარი
- `integration_result.dart`: ახალი ველები `fromJson`-ში (ნულოვანი/ცარიელი
  default, რომ ძველი ქეში არ გატყდეს).
- `dataset_export_service.dart`:
  - `export()` მიიღებს `IntegrationResult`-ს (ან ცალკე `ExportMetadata` კლასს,
    რაც უფრო სუფთაა: ცალკე ფაილი `models/export_metadata.dart`).
  - `buildMetadata(result)`: region, disease, resolution, პერიოდი (პირველი /
    ბოლო `period`), **მონაცემებით დაფარული პერიოდი** (პირველი / ბოლო არა-null
    `caseCount`), sources, licenses, steps, `retrieved_at` (= `lastVerified`,
    UTC), `exported_at` (= `DateTime.now().toUtc()`), `system_version`.
  - **JSON:** `{"metadata": {...}, "data": [...]}`.
  - **CSV:** CSV უცვლელი რჩება + მეორე ფაილი
    `climate_health_dataset_metadata.json`.
    (`#`-ით დაწყებული კომენტარის ხაზებს Excel/pandas ცუდად კითხულობს.)
- გამოძახების ადგილები განაახლე (2 widget).

### 3. ტესტები
- `frontend/test/dataset_export_service_test.dart`: fake
  `BrowserDownloadService`-ით შეამოწმე:
  - JSON-ში არის `metadata.region == "Thailand"`, `metadata.licenses`;
  - CSV export-ისას გადმოიწერება **ორი** ფაილი;
  - `data` სტრიქონები უცვლელია (regression).
- Backend: ტესტი, რომ response-ში `licenses` არ არის ცარიელი OpenDengue-სთვის.
- გაუშვი: `pytest` (backend), `flutter analyze` და `flutter test` (frontend).

### 4. PDF ანგარიში
- `report_pdf_service.dart`: Sources სექციის ქვეშ დაამატე „License“ და
  „System version“.

### 5. დოკუმენტაცია
- `docs/thesis/CHANGE_DOCUMENTATION_GUIDE.md`, ნაწილი „Task A16“: მოთხოვნების
  კატალოგი (FR-25, DE/EN/KA), `dokumentacia.tex`, README-ები, TESTING_GUIDE.

## მზადყოფნის კრიტერიუმები
- [ ] ექსპორტირებული JSON-იდან შეიძლება გაიგო: რა, სად, საიდან, როდის, რომელი
      ვერსიით, რა ლიცენზიით.
- [ ] არცერთი ლიცენზია/ვერსია მოგონილი არ არის (წყარო კომენტარში).
- [ ] ყველა ტესტი გადის.
- [ ] `THESIS_KNOWLEDGE_BASE.md`-ში TODO მოინიშნა, თეზისში ჩაიწერა როგორც
      „ლიტერატურიდან გამოყვანილი მოთხოვნა“ (FR-new, ტრეისაბილიტის მატრიცა).
