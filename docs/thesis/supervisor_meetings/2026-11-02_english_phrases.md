# შეხვედრა 2026-11-02: ინგლისური ფრაზები (B1 დონე, ფურცლიდან წასაკითხად)

> **B1 ენა:** მოკლე წინადადებები და ყოველდღიური სიტყვები. თითოეულ წინადადებაში ერთი აზრია.
> სპეციალური სიტყვები მხოლოდ იქ დავტოვე, სადაც სხვა გზა არ არის; მათი ახსნა ქვემოთ, ლექსიკონშია.
> თითოეულ ფრაზას ქვემოთ ქართული თარგმანი აქვს.
> ნომრები ემთხვევა `2026-11-02_motivacia_da_moTxovnebi.md`-ის კითხვებს. პასუხები იქ ჩაწერე.

---

## ლექსიკონი (ეს სიტყვები შეხვედრაზე ხშირად გაისმება)

| ინგლისური | ქართული |
|---|---|
| paper / study | სტატია / კვლევა |
| data preparation | მონაცემების მომზადება |
| step | ნაბიჯი |
| requirement | მოთხოვნა |
| case study | საქმის შესწავლა (სისტემის ჩვენება მაგალითზე) |
| dataset | მონაცემთა ნაკრები (ცხრილი) |
| source | წყარო |
| feature | ფუნქცია (სისტემაში) |
| gap / missing data | ხარვეზი / გამოტოვებული მონაცემები |
| lag | დაგვიანება (კლიმატის ეფექტი თვეების შემდეგ) |
| limitation | შეზღუდვა |
| future work | სამომავლო სამუშაო |
| evaluation | შეფასება |
| reference / citation | წყარო ლიტერატურის სიაში / ციტირება |
| deadline | ბოლო ვადა |

---

## 0. როცა რამე ვერ გაიგე (ყველაზე მნიშვნელოვანი)

- *Sorry, can you say that again, more slowly?*
  (ბოდიში, შეგიძლიათ გაიმეოროთ, უფრო ნელა?)
- *Sorry, I did not understand the word "…". What does it mean?*
  (ბოდიში, სიტყვა „…“ ვერ გავიგე. რას ნიშნავს?)
- *Do you mean that …?*
  (გულისხმობთ, რომ …?)
- *Can you write it in the chat, please?*
  (შეგიძლიათ ჩატში დაწეროთ?)
- *I need a moment to think.*
  (ერთი წუთით დავფიქრდები.)
- *I am not sure. I will check it and write you an email.*
  (დარწმუნებული არ ვარ. შევამოწმებ და მეილს მოგწერთ.)
- *Okay, I will write that down.*
  (კარგი, ჩავიწერ.)

---

## 1. დასაწყისი (1–2 წუთი)

*Thank you for your time. This morning I sent you an email and a first draft. Here is the short version. I read three
papers. I wrote down all the steps the authors did to prepare their data. From these steps I made the requirements for
my system. Five features were missing, so I built them. I also started to write the first chapters. Today I would like
to hear your opinion.*

(მადლობა დროისთვის. დილით მეილი და პირველი მონახაზი გამოგიგზავნეთ. აი, მოკლედ. სამი სტატია წავიკითხე.
ჩავიწერე ყველა ნაბიჯი, რაც ავტორებმა მონაცემების მოსამზადებლად გააკეთეს. ამ ნაბიჯებიდან ჩემი სისტემის
მოთხოვნები შევადგინე. ხუთი ფუნქცია აკლდა, ამიტომ ავაწყვე. პირველი თავების წერაც დავიწყე. დღეს თქვენი აზრის
მოსმენა მინდა.)

---

## 2. მიდგომა

**2.1** *Is this the motivation you wanted? My idea is: researchers need data for their models. Preparing this data
takes many steps by hand. My system makes these steps easier.*

(ასეთი მოტივაცია გინდოდათ? ჩემი იდეა ასეთია: მკვლევრებს მოდელებისთვის მონაცემები სჭირდებათ. ამ მონაცემების
მომზადებას ბევრი ხელით გადადგმული ნაბიჯი სჭირდება. ჩემი სისტემა ამ ნაბიჯებს ამარტივებს.)

**2.2** *I use two papers with models and one paper about a dataset. Is this enough? Or should I add more papers?*

(ვიყენებ ორ სტატიას მოდელებით და ერთ სტატიას მონაცემთა ნაკრებზე. ეს საკმარისია? თუ მეტი სტატია დავამატო?)

**2.3** *I made a table: on the left the step in the paper, on the right the requirement. Is this a good way? And some
features I added myself to make the system easier to use, like the chat and the map. They do not come from the papers.
Should I explain them as "easy to use" features, or remove them from the thesis?*

(ცხრილი გავაკეთე: მარცხნივ ნაბიჯი სტატიიდან, მარჯვნივ მოთხოვნა. ეს კარგი გზაა? ზოგი ფუნქცია, მაგალითად
ჩატი და რუკა, თვითონ დავამატე, რომ სისტემით სარგებლობა მარტივი ყოფილიყო. ისინი სტატიებიდან არ მოდის.
„მარტივად გამოსაყენებელ“ ფუნქციებად ავხსნა, თუ ნაშრომიდან ამოვიღო?)

---

## 3. Case studies

**3.1** *For case study 1, I want to make the same small dataset two times. First by hand with Python. Then with my
system. After that I compare the time, the number of steps and the results. Is this a good evaluation? Can I do the
test alone, or do I need a second person?*

(case study 1-ისთვის ერთი და იგივე პატარა მონაცემთა ნაკრების ორჯერ შექმნა მინდა. ჯერ ხელით, Python-ით.
შემდეგ ჩემი სისტემით. მერე შევადარებ დროს, ნაბიჯების რაოდენობას და შედეგებს. ეს კარგი შეფასებაა? ტესტის
მარტო ჩატარება შემიძლია, თუ მეორე ადამიანი მჭირდება?)

**3.2** *Can I use the data of Suttirat et al. from Zenodo for the comparison?*

(შედარებისთვის შემიძლია Suttirat et al.-ის მონაცემები Zenodo-დან გამოვიყენო?)

**3.3** (Peter-ს) *Do you know how long the data preparation took in the Suttirat study? Can I write this in my thesis
as "personal communication"?*

(იცი, Suttirat-ის კვლევაში მონაცემების მომზადებას რამდენი დრო დასჭირდა? შემიძლია ეს ნაშრომში „პირადი
კომუნიკაციის“ სახით მივუთითო?)

**3.4** *Which studies do you suggest for case study 2 and 3? I have three ideas. First, Brazil, because Lowe et al.
share their data. Second, malaria or cholera, but the WHO data is only yearly. Third, a researcher's own CSV file, and
the system adds the climate data.*

(case study 2-ისა და 3-ისთვის რომელ კვლევებს მირჩევთ? სამი იდეა მაქვს. პირველი, ბრაზილია, რადგან Lowe et al.
თავიანთ მონაცემებს აზიარებენ. მეორე, მალარია ან ქოლერა, მაგრამ WHO-ს მონაცემები მხოლოდ წლიურია. მესამე,
მკვლევრის საკუთარი CSV ფაილი, რომელსაც სისტემა კლიმატის მონაცემებს უმატებს.)

---

## 4. სისტემის ფარგლები

**4.1** *Both papers use the average climate of the whole region. My system uses only one point for each country. What
do I need to add for a bachelor thesis? And what can I describe as a limitation or as future work? For example: the
average of a region instead of one point, provinces, or weekly data.*

(ორივე სტატია მთელი რეგიონის საშუალო კლიმატს იყენებს. ჩემი სისტემა თითო ქვეყნისთვის მხოლოდ ერთ წერტილს
იყენებს. ბაკალავრის ნაშრომისთვის რა უნდა დავამატო? და რა შემიძლია აღვწერო შეზღუდვად ან სამომავლო სამუშაოდ?
მაგალითად: რეგიონის საშუალო ერთი წერტილის ნაცვლად, პროვინციები ან კვირის მონაცემები.)

(Tmin/Tmax და lag სვეტები უკვე გაკეთებულია, აღარ იკითხო.)

**4.2** *I decided not to fill missing data from another source. The reason is: the sources count cases in different
ways. So the system shows the gaps, and the user can compare two sources. Do you agree?*

(გადავწყვიტე, რომ გამოტოვებული მონაცემები სხვა წყაროდან არ შევავსო. მიზეზი ასეთია: წყაროები შემთხვევებს
სხვადასხვანაირად ითვლიან. ამიტომ სისტემა ხარვეზებს აჩვენებს და მომხმარებელს ორი წყაროს შედარება შეუძლია.
ეთანხმებით?)

---

## 5. ფორმალური საკითხები

**5.1** *How many references do you expect, more or less? Which topics must I write about? For example other tools, or
LLMs for data work?*

(დაახლოებით რამდენ წყაროს ელით? რომელ თემებზე უნდა დავწერო? მაგალითად სხვა ხელსაწყოებზე ან LLM-ებზე
მონაცემებთან მუშაობისთვის?)

**5.2** *Which citation style should I use: numbers, or author and year? Is there a template?*

(ციტირების რომელი სტილი გამოვიყენო: ნომრები, თუ ავტორი და წელი? არის შაბლონი?)

(მონახაზში ახლა „ავტორი და წელი“ არის.)

**5.3** *Peter, my main case study is a paper where you are a co-author. Is this okay?*

(პიტერ, ჩემი მთავარი case study სტატიაა, რომლის თანაავტორიც ხარ. ეს მისაღებია?)

**5.4** *Are there rules for the structure and the number of pages? And when is the deadline?*

(არის წესები სტრუქტურასა და გვერდების რაოდენობაზე? და როდის არის ბოლო ვადა?)

**5.5** *I use AI tools, Claude and Gemini. I use them for code, for help with writing and translating, and for grammar.
The decisions, the papers and the checking of the results are my own work. What are the rules at the university? And
how should I write this in the thesis?*

(AI ხელსაწყოებს ვიყენებ, Claude-ს და Gemini-ს. ვიყენებ კოდისთვის, წერასა და თარგმნაში დასახმარებლად და
გრამატიკისთვის. გადაწყვეტილებები, სტატიები და შედეგების შემოწმება ჩემი სამუშაოა. რა წესები აქვს უნივერსიტეტს?
და როგორ დავწერო ეს ნაშრომში?)

---

## 6. თუ გკითხეს: „რატომ მხოლოდ დენგე?“

*I use dengue as my main example because OpenDengue has free monthly data. In the papers, the weather affects dengue
after zero to six months. With yearly data you cannot see this. The WHO data for malaria and cholera is only yearly.
Malaria and cholera are already in the system. Users can also upload their own monthly data as a CSV file. I plan a
second case study to show that the system works for other diseases too.*

(დენგეს მთავარ მაგალითად ვიყენებ, რადგან OpenDengue-ს უფასო თვიური მონაცემები აქვს. სტატიებში ამინდი დენგეზე
ნულიდან ექვს თვემდე პერიოდის შემდეგ მოქმედებს. წლიური მონაცემებით ამას ვერ დაინახავ. WHO-ს მონაცემები
მალარიასა და ქოლერაზე მხოლოდ წლიურია. მალარია და ქოლერა სისტემაში უკვე არის. მომხმარებლებს საკუთარი თვიური
მონაცემების CSV ფაილად ატვირთვაც შეუძლიათ. მეორე case study-ს ვგეგმავ, რომ ვაჩვენო, რომ სისტემა სხვა
დაავადებებისთვისაც მუშაობს.)

**თუ მალარიაზე გკითხეს:** *The WHO malaria numbers are estimates from a model. They are not counted cases. So I would
be careful to use them for a new model.*

(WHO-ს მალარიის რიცხვები მოდელით გამოთვლილი შეფასებებია. ისინი დათვლილი შემთხვევები არ არის. ამიტომ ახალი
მოდელისთვის მათ ფრთხილად გამოვიყენებდი.)

(WHO-ს შეფასების მეთოდი ჯერ არ წაგიკითხავს: არ თქვა, რომ ისინი კლიმატს იყენებენ.)

---

## 7. დასასრული

*Thank you very much. I will write down what we decided and send it to you by email. When can we meet next time?*

(დიდი მადლობა. რაც გადავწყვიტეთ, ჩავიწერ და მეილით გამოგიგზავნით. შემდეგ როდის შეგვიძლია შეხვედრა?)
