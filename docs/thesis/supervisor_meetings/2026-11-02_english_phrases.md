# შეხვედრა 2026-11-02: ინგლისური ფრაზები (ფურცლიდან წასაკითხად)

> მოკლე, მარტივი წინადადებებია, რომ ხმამაღლა მარტივად წაიკითხო. ქართული განმარტება ფრჩხილებშია.
> ნომრები ემთხვევა `2026-11-02_motivacia_da_moTxovnebi.md`-ის კითხვებს. პასუხები იქ ჩაწერე.

---

## 0. როცა რამე ვერ გაიგე (ყველაზე მნიშვნელოვანი)

- *Sorry, could you say that again more slowly?* (გაიმეორეთ ნელა)
- *Just to make sure I understood: you mean that …?* (სწორად გავიგე, რომ …?)
- *Could you write that in the chat, please?* (ჩატში დაწერეთ, თუ შეიძლება; ონლაინ შეხვედრაზე ძალიან გამოსადეგია)
- *Let me think about it and answer by email.* (დავფიქრდები და მეილით გიპასუხებთ)
- *I will note that down.* (ჩავიწერ)

---

## 1. დასაწყისი (1–2 წუთი)

*Thank you for your time. I sent you an email with a short update and a first draft. In short: I read three papers,
listed the data preparation steps, and derived requirements from them. I implemented five missing features and
started writing the introduction and the requirements chapter. Today I would mainly like your feedback.*

(მადლობა დროისთვის. მეილი გამოგიგზავნეთ მოკლე განახლებით და პირველი მონახაზით. მოკლედ: სამი სტატია
წავიკითხე, მონაცემთა მომზადების ნაბიჯები ამოვწერე და მათგან მოთხოვნები გამოვიყვანე. ხუთი ფუნქცია, რომელიც
აკლდა, დავნერგე და შესავლისა და მოთხოვნების თავის წერა დავიწყე. დღეს ძირითადად თქვენი აზრი მაინტერესებს.)

---

## 2. მიდგომა

**2.1** *Is this the kind of motivation you had in mind? Researchers need data for their models, preparing the data
takes many manual steps, and my system makes these steps easier.*

**2.2** *Are two modelling papers and one dataset paper enough? Or should I add more studies to show that the steps
are typical?*

**2.3** *Is a table "step in the paper → requirement" a good way to derive the requirements? And what should I do with
the older requirements that do not come from the literature, like the chat, the map or the PDF report? Should I
justify them as usability requirements, or remove them?*

---

## 3. Case studies

**3.1** *For case study 1, I want to build the same simplified dataset two times: once by hand with Python, and once
with the system. Then I compare time, number of steps and the results. Is this a good evaluation? Is it okay if I am
the only tester, or do I need a second person?*

**3.2** *May I use the Zenodo data of Suttirat et al. for the comparison?*

**3.3** (Haddawy-ს) *Do you know roughly how long the data preparation took in the Suttirat study? May I cite this as
a personal communication?*

**3.4** *Which studies would you recommend for case study 2 and 3? My ideas are: Brazil, because Lowe et al. share
their data; malaria or cholera, but the WHO data is only yearly; or a researcher's own CSV file with automatic climate
matching.*

---

## 4. სისტემის ფარგლები

**4.1** *Both papers average the climate over the whole region. My system uses one point per country. Which extensions
are necessary for a bachelor thesis, and which can I describe as limitations or future work? For example: area
average instead of one point, the province level, weekly data.*

(Tmin/Tmax და lag სვეტები უკვე გაკეთებულია, აღარ იკითხო.)

**4.2** *I decided not to fill missing data automatically from another source, because the sources use different case
definitions. Instead, the system shows the gaps and lets the user compare two sources. Do you agree with this
decision?*

---

## 5. ფორმალური საკითხები

**5.1** *About how many references do you expect? Which topics must be covered, for example related tools or LLMs in
data processing?*

**5.2** *Which citation style should I use: numbers or author-year? Is there a template?*

**5.3** *Is it okay that my main case study is a paper where Professor Haddawy is a co-author?*

**5.4** *Are there rules for the structure and the length? And when is the deadline?*

(5.2: მონახაზში ახლა author-year არის.)

---

## 6. თუ გკითხეს: „რატომ მხოლოდ დენგე?“

*Dengue is my validation case because OpenDengue has open monthly data. In the papers, the climate effect comes with a
delay of zero to six months. With yearly data, like the WHO data for malaria and cholera, you cannot see this. Malaria
and cholera are already in the system, and users can upload their own monthly data as CSV. To show that it also works
for other diseases, I plan a second case study.*

**თუ მალარიაზე გკითხეს:** *The WHO malaria numbers are modelled estimates, not reported cases. So I would be careful
to use them as input for a new model.*

(WHO-ს შეფასების მეთოდი ჯერ არ წაგიკითხავს: არ თქვა, რომ ისინი კლიმატს იყენებენ.)

---

## 7. დასასრული

*Thank you very much. I will summarise the decisions and send them to you by email. When would be a good time for the
next meeting?*

(დიდი მადლობა. გადაწყვეტილებებს შევაჯამებ და მეილით გამოგიგზავნით. როდის იქნება მოსახერხებელი შემდეგი შეხვედრა?)
