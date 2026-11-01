# წერილის მონახაზი ხელმძღვანელებს (შეხვედრამდე, 2026-11-02)

> **როგორ გამოიყენო:** ქვემოთ ინგლისური ტექსტია, მის ქვეშ კი ქართული თარგმანი, რომ ზუსტად იცოდე, რას აგზავნი.
> ინგლისური განზრახ მარტივია: მოკლე წინადადებები, ჩვეულებრივი სიტყვები. ასე შენს ლაპარაკს ემთხვევა და
> შეხვედრაზე იგივე სიტყვებით შეგიძლია ლაპარაკი. შეცვალე, რაც შენს სტილს არ ჰგავს, და დაამატე შენი აზრები.
> დანართად მიამაგრე `docs/thesis/entwurf/entwurf_motivation_anforderungen.pdf`.

---

**Subject:** Update before our meeting on Monday – motivation and requirements

Dear Professor Haddawy, dear Dr. Barkowsky,

before our meeting on Monday I would like to give you a short update, so that we can use the time for your feedback.

After your last feedback I worked on the motivation. I read three papers in detail:

- Suttirat et al. (2026), dengue in Thailand – I use it as the main case study,
- Lowe et al. (2021), dengue in Brazil,
- Clarke et al. (2024), the OpenDengue dataset.

From the methods sections I listed all data preparation steps that the authors did before the modelling. Both modelling papers do very similar steps: getting monthly case counts, calculating incidence per 100,000, adding Tmin and Tmax, creating lagged climate variables, and in Lowe et al. also loading climate data one year before the case data starts, because of the lags. Clarke et al. write that locating, extracting, processing and standardising data takes time, and they stress that the source of every record should be traceable.

I used these steps to derive requirements. For each requirement I noted the paper and the page. Some of them were missing in my system, so I implemented them:

- lagged climate variables (lag 1–6) as columns in the dataset, with a buffer before the start date (Suttirat, Lowe),
- daily minimum and maximum temperature (Suttirat, Lowe),
- export with metadata: sources, licences, processing steps and software version (Clarke),
- detection of missing periods in the data, with a possible reason (Clarke),
- a comparison of two data sources over the same period, for example ERA5 and NASA POWER for climate, or the built-in case data and the user's own file (Clarke).

I decided not to fill missing data automatically from another source, because the sources use different case definitions (for example, OpenDengue counts all reported cases, while Suttirat et al. use only DHF). The system shows the gaps and lets the user compare sources instead.

I also started writing. The attached PDF is a first draft (in German) of the introduction and the requirements chapter, with a table that links each step in the papers to a requirement. Some parts are still open and marked in red.

On Monday I would like to ask you mainly about these points:

1. Is this the kind of motivation you had in mind?
2. Are two modelling papers and one dataset paper enough, or should I add more studies?
3. What should I do with the older requirements that do not come from the literature (for example the chat or the map)? Should I justify them as usability requirements or remove them?
4. For case study 1, I plan to build the same simplified dataset once by hand with Python and once with the system, and to compare time, steps and results. Is this a suitable evaluation?

The current version is online: https://llm-climate-health.onrender.com/

Best regards,
Sergi Koniashvili

---

## ქართული თარგმანი (მხოლოდ შენთვის, არ გააგზავნო)

**თემა:** განახლება ორშაბათის შეხვედრამდე – მოტივაცია და მოთხოვნები

პატივცემულო პროფესორო ჰადავი, პატივცემულო დოქტორო ბარკოვსკი,

ორშაბათის შეხვედრამდე მინდა მოკლედ მოგიყვეთ, რა გავაკეთე, რომ შეხვედრის დრო თქვენს შენიშვნებს დავუთმოთ.

თქვენი ბოლო შენიშვნის შემდეგ მოტივაციაზე ვიმუშავე. სამი სტატია დეტალურად წავიკითხე:

- Suttirat et al. (2026), დენგე ტაილანდში, მთავარ case study-დ ვიყენებ;
- Lowe et al. (2021), დენგე ბრაზილიაში;
- Clarke et al. (2024), OpenDengue-ს მონაცემთა ნაკრები.

მეთოდების ნაწილებიდან ამოვწერე მონაცემთა მომზადების ყველა ნაბიჯი, რაც ავტორებმა მოდელირებამდე გააკეთეს. ორივე მოდელირების სტატია ძალიან მსგავს ნაბიჯებს აკეთებს: თვიური შემთხვევების მოპოვება, ინციდენტობის გამოთვლა 100 000-ზე, Tmin-ისა და Tmax-ის დამატება, დაგვიანებული (lag) კლიმატის ცვლადების შექმნა. Lowe et al. ამას გარდა კლიმატის მონაცემებს შემთხვევების დაწყებამდე ერთი წლით ადრეც იღებენ, lag-ების გამო. Clarke et al. წერენ, რომ მონაცემების მოძიება, ამოღება, დამუშავება და სტანდარტიზაცია დროს მოითხოვს, და ხაზს უსვამენ, რომ ყოველი ჩანაწერის წყარო მიკვლევადი უნდა იყოს.

ამ ნაბიჯებიდან მოთხოვნები გამოვიყვანე. ყოველ მოთხოვნას სტატია და გვერდი მივუწერე. ზოგი მათგანი ჩემს სისტემას აკლდა, ამიტომ დავნერგე:

- lag-იანი კლიმატის ცვლადები (1–6) სვეტებად, საწყისი თარიღის წინ ბუფერით (Suttirat, Lowe);
- დღიური მინიმალური და მაქსიმალური ტემპერატურა (Suttirat, Lowe);
- ექსპორტი metadata-თი: წყაროები, ლიცენზიები, დამუშავების ნაბიჯები და პროგრამის ვერსია (Clarke);
- მონაცემებში გამოტოვებული პერიოდების აღმოჩენა შესაძლო მიზეზით (Clarke);
- ორი წყაროს შედარება ერთსა და იმავე პერიოდში, მაგ. ERA5 და NASA POWER კლიმატისთვის, ან ჩაშენებული შემთხვევები და მომხმარებლის საკუთარი ფაილი (Clarke).

გადავწყვიტე, რომ გამოტოვებული მონაცემები სხვა წყაროდან ავტომატურად არ შევავსო, რადგან წყაროები შემთხვევის სხვადასხვა განსაზღვრებას იყენებენ (მაგ. OpenDengue ყველა რეგისტრირებულ შემთხვევას ითვლის, Suttirat et al. კი მხოლოდ DHF-ს). სისტემა ხარვეზებს აჩვენებს და მომხმარებელს წყაროების შედარების საშუალებას აძლევს.

წერაც დავიწყე. თანდართული PDF შესავლისა და მოთხოვნების თავის პირველი მონახაზია (გერმანულად), ცხრილით, რომელიც სტატიების თითოეულ ნაბიჯს მოთხოვნას უკავშირებს. ზოგი ნაწილი ჯერ ღიაა და წითლად არის მონიშნული.

ორშაბათს ძირითადად ამ საკითხებზე მინდა გკითხოთ:

1. ასეთ მოტივაციას გულისხმობდით?
2. საკმარისია ორი მოდელირების სტატია და ერთი მონაცემთა სტატია, თუ მეტი კვლევა დავამატო?
3. რა ვუყო ძველ მოთხოვნებს, რომლებიც ლიტერატურიდან არ მოდის (მაგ. ჩატი ან რუკა)? გამოყენებადობის მოთხოვნებად დავასაბუთო თუ ამოვიღო?
4. Case study 1-ისთვის ვგეგმავ, რომ ერთი და იგივე გამარტივებული მონაცემთა ნაკრები ერთხელ ხელით ავაწყო Python-ით და ერთხელ სისტემით, და შევადარო დრო, ნაბიჯები და შედეგები. ეს შეფასების შესაფერისი მეთოდია?

მიმდინარე ვერსია ონლაინ არის: https://llm-climate-health.onrender.com/

პატივისცემით,
სერგი კონიაშვილი
