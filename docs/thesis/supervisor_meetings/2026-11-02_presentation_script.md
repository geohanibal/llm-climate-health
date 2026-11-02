# პრეზენტაციის სცენარი, 2026-11-02 (B1 ინგლისური)

> ეს ტექსტი ზუსტად ემთხვევა `2026-11-02_presentation.pptx`-ის სლაიდებსა და შენიშვნებს.
> ყოველ სლაიდზე ჯერ ინგლისური ტექსტია (ხმამაღლა წასაკითხი), შემდეგ ქართული თარგმანი.
> კითხვა-პასუხისთვის (როცა რამე ვერ გაიგე, case study-ების კითხვები) იხ. `2026-11-02_english_phrases.md`.

---

## სლაიდი 1: From papers to requirements

Hello everyone. Thank you for your time. Today I want to show what I did after your last feedback. I worked on two things: the motivation and the requirements. Both are based on papers. Before the meeting I sent you an email. It has a short summary, the first draft of my thesis in German and in English, and my open questions. So you have everything in writing. Now I will show the main points. I will keep it short, so we have time for your questions. If something is not clear, please stop me and ask.

(გამარჯობა ყველას. მადლობა დროისთვის. დღეს მინდა გაჩვენოთ, რა გავაკეთე თქვენი ბოლო შენიშვნის შემდეგ. ორ რამეზე ვიმუშავე: მოტივაციასა და მოთხოვნებზე. ორივე სტატიებს ეყრდნობა. შეხვედრამდე მეილი გამოგიგზავნეთ. მასშია მოკლე შეჯამება, ჩემი ნაშრომის პირველი მონახაზი გერმანულად და ინგლისურად და ჩემი ღია კითხვები. ასე რომ, ყველაფერი წერილობით გაქვთ. ახლა მთავარ პუნქტებს გაჩვენებთ. მოკლედ ვიტყვი, რომ თქვენი კითხვებისთვის დრო დარჩეს. თუ რამე გაუგებარია, გთხოვთ, შემაჩერეთ და მკითხეთ.)

---

## სლაიდი 2: Your feedback became my plan

In October you said: the system works, but the motivation is missing. You gave me an idea: look at papers where people build models with data. Use these papers in three ways. First, for the motivation. Second, to find the requirements for the system. Third, as case studies, to show the system. This is what I did. Today I talk mostly about the first two points.

(ოქტომბერში თქვით: სისტემა მუშაობს, მაგრამ მოტივაცია აკლია. იდეა მომეცით: მენახა სტატიები, სადაც მკვლევრები მონაცემებით მოდელებს აგებენ, და ეს სტატიები სამი გზით გამომეყენებინა. პირველი, მოტივაციისთვის. მეორე, სისტემის მოთხოვნების მოსაძებნად. მესამე, case study-ებად, სისტემის საჩვენებლად. ეს გავაკეთე. დღეს ძირითადად პირველ ორ პუნქტზე ვისაუბრებ.)

---

## სლაიდი 3: Three papers as the basis

I read three papers in detail. The first one is Suttirat et al. It is about dengue in Thailand, with monthly data. It describes the data preparation very well. So it is my main case study. Peter, you are a co-author of this paper. I was happy to see your name. I only use what is written in the methods part. Is it okay for you that I use this paper as the main example? The second paper is Lowe et al. They do a similar study in Brazil. It shows that the steps are typical. The third paper is Clarke et al. It describes the OpenDengue dataset. From this paper I take ideas about the source of the data, versions, and comparing sources.

(სამი სტატია დეტალურად წავიკითხე. პირველი არის Suttirat et al. ის ტაილანდის დენგეზეა, თვიური მონაცემებით. მონაცემების მომზადებას ძალიან კარგად აღწერს. ამიტომ ეს ჩემი მთავარი case study-ია. პიტერ, ამ სტატიის თანაავტორი ხარ. გამიხარდა შენი სახელის დანახვა. მხოლოდ იმას ვიყენებ, რაც მეთოდების ნაწილში წერია. მისაღებია შენთვის, რომ ეს სტატია მთავარ მაგალითად გამოვიყენო? მეორე სტატიაა Lowe et al. ისინი მსგავს კვლევას ბრაზილიაში აკეთებენ. ის აჩვენებს, რომ ნაბიჯები ტიპურია. მესამე სტატიაა Clarke et al. ის OpenDengue-ს მონაცემთა ნაკრებს აღწერს. ამ სტატიიდან ვიღებ იდეებს მონაცემების წყაროზე, ვერსიებზე და წყაროების შედარებაზე.)

---

## სლაიდი 4: Both studies prepare the data in the same way

This table shows the steps from the methods part of both papers. Both studies do almost the same things. They get monthly case numbers. They add Tmin and Tmax. They take the climate from a map and make one value for each region. They make lag variables. This means: the weather of one, two or three months before. And they calculate the number of cases for every 100,000 people. Lowe et al. even take climate data from one year before the start, because of the lags. So these steps are typical. Clarke et al. also write that this work takes time. And all of this needs programming, in Python or R.

(ეს ცხრილი ორივე სტატიის მეთოდების ნაწილიდან აღებულ ნაბიჯებს აჩვენებს. ორივე კვლევა თითქმის ერთსა და იმავეს აკეთებს. იღებენ თვიურ შემთხვევებს. ამატებენ Tmin-სა და Tmax-ს. კლიმატს რუკიდან იღებენ და თითო რეგიონისთვის ერთ მნიშვნელობას აკეთებენ. ქმნიან lag-ცვლადებს, ანუ ერთი, ორი ან სამი თვით ადრინდელ ამინდს. და ითვლიან შემთხვევებს ყოველ 100 000 ადამიანზე. Lowe et al. კლიმატის მონაცემებს დაწყებამდე ერთი წლით ადრიდანაც კი იღებენ, lag-ების გამო. ესე იგი ეს ნაბიჯები ტიპურია. Clarke et al.-იც წერენ, რომ ამ სამუშაოს დრო სჭირდება. და ეს ყველაფერი პროგრამირებას მოითხოვს, Python-ში ან R-ში.)

---

## სლაიდი 5: Missing steps became new features

I wrote every step in a table: the step, the paper with the page, and the requirement. Some steps were missing in my system. So I built five new features. One: lag columns, from one to six months, with extra data before the start date. Two: Tmin and Tmax. Three: an export with metadata. The metadata says where the data comes from, the licence and the processing steps. Four: the system finds missing months and shows a possible reason. Five: the user can compare two sources for the same time, for example ERA5 and NASA POWER. All five are online now.

(ყველა ნაბიჯი ცხრილში ჩავწერე: ნაბიჯი, სტატია გვერდით და მოთხოვნა. ზოგი ნაბიჯი ჩემს სისტემას აკლდა. ამიტომ ხუთი ახალი ფუნქცია ავაწყვე. ერთი: lag-სვეტები, ერთიდან ექვს თვემდე, დაწყების თარიღამდე დამატებითი მონაცემებით. ორი: Tmin და Tmax. სამი: ექსპორტი მეტამონაცემებით. მეტამონაცემები ამბობს, საიდან მოდის მონაცემები, რა ლიცენზიაა და რა ნაბიჯები გაიარა. ოთხი: სისტემა გამოტოვებულ თვეებს პოულობს და შესაძლო მიზეზს აჩვენებს. ხუთი: მომხმარებელს ერთი და იმავე პერიოდისთვის ორი წყაროს შედარება შეუძლია, მაგალითად ERA5-ისა და NASA POWER-ის. ხუთივე ახლა ონლაინაა.)

---

## სლაიდი 6: What I deliberately do not do

Some steps from the papers I do not do. This is on purpose. I describe them as limitations in the thesis. My system uses one point for each country, not provinces. It does not handle changing borders. It has no bioclimatic indicators and no satellite data. And it does not fill missing data from another source. Here is an example why. OpenDengue counts all reported cases. Suttirat et al. count only the severe form, DHF. Imagine June has 1,000 cases from OpenDengue. July is missing, and we fill it from a DHF source with 50 cases. Then it looks like the cases went down twenty times. But this is not true. Only the way of counting is different. So my system shows the gap, and the user can compare the sources. Do you agree with this decision, or should the system fill the gaps?

(სტატიების ზოგ ნაბიჯს არ ვაკეთებ. ეს განზრახ გადავწყვიტე. ნაშრომში მათ შეზღუდვებად აღვწერ. ჩემი სისტემა თითო ქვეყნისთვის ერთ წერტილს იყენებს და არა პროვინციებს. ცვალებად საზღვრებს არ ამუშავებს. ბიოკლიმატური ინდიკატორები და სატელიტური მონაცემები არ აქვს. და გამოტოვებულ მონაცემებს სხვა წყაროდან არ ავსებს. აი, მაგალითი, რატომ. OpenDengue ყველა შეტყობინებულ შემთხვევას ითვლის. Suttirat et al. მხოლოდ მძიმე ფორმას, DHF-ს. წარმოიდგინეთ, ივნისში OpenDengue-დან 1000 შემთხვევაა. ივლისი აკლია და DHF-ის წყაროდან 50 შემთხვევით ვავსებთ. მაშინ ისე ჩანს, თითქოს შემთხვევები ოცჯერ შემცირდა. მაგრამ ეს სიმართლე არ არის. მხოლოდ დათვლის წესია განსხვავებული. ამიტომ ჩემი სისტემა ხარვეზს აჩვენებს და მომხმარებელს წყაროების შედარება შეუძლია. ეთანხმებით ამ გადაწყვეტილებას, თუ სისტემამ ხარვეზები უნდა შეავსოს?)

---

## სლაიდი 7: The LLM helps, the code decides

This slide is about the role of the LLM. The LLM does only some jobs. It turns a request in normal language into the fields of the form. The user can check and change the fields before the start. The LLM also explains the result in simple words, and it helps in the chat. All the data work is normal program code, not the LLM. So the same request always gives the same table. But the LLM can make mistakes. In my own test, it said that one correlation was the strongest. But this correlation was not significant. It had only nine value pairs. I fixed this. Now the LLM gets the significance and the number of pairs for each correlation. And it is told to report only significant results. But this is an instruction, not a guarantee. So I will test it in the evaluation.

(ეს სლაიდი LLM-ის როლზეა. LLM მხოლოდ ზოგ საქმეს აკეთებს. ჩვეულებრივ ენაზე დაწერილ მოთხოვნას ფორმის ველებად გარდაქმნის. მომხმარებელს ველების შემოწმება და შეცვლა გაშვებამდე შეუძლია. LLM შედეგს მარტივი სიტყვებითაც ხსნის და ჩატში ეხმარება. მონაცემებთან მთელი მუშაობა ჩვეულებრივი პროგრამული კოდია და არა LLM. ამიტომ ერთი და იგივე მოთხოვნა ყოველთვის ერთსა და იმავე ცხრილს იძლევა. მაგრამ LLM-ს შეუძლია შეცდომა დაუშვას. ჩემს ტესტში მან თქვა, რომ ერთი კორელაცია ყველაზე ძლიერი იყო. მაგრამ ეს კორელაცია მნიშვნელოვანი არ იყო. მას მხოლოდ ცხრა წყვილი ჰქონდა. ეს გამოვასწორე. ახლა LLM ყოველ კორელაციასთან ერთად იღებს მნიშვნელოვნებას და წყვილების რაოდენობას. და ეუბნებიან, რომ მხოლოდ მნიშვნელოვანი შედეგები დაასახელოს. მაგრამ ეს ინსტრუქციაა და არა გარანტია. ამიტომ ამას ევალუაციაში შევამოწმებ.)

---

## სლაიდი 8: Proposal for a research question

I also want to suggest a research question. Here it is. The main idea is simple. The system does the data preparation automatically. But every step can be checked. Does this direction fit for you?

(კვლევითი კითხვის შეთავაზებაც მინდა. აი, ისიც. მთავარი იდეა მარტივია. სისტემა მონაცემების მომზადებას ავტომატურად აკეთებს. მაგრამ ყოველი ნაბიჯის შემოწმება შეიძლება. ეს მიმართულება თქვენთვის მისაღებია?)

---

## სლაიდი 9: Questions for you

Now I have some questions for you. They are also in my email and at the end of the draft. First, the content. One: is this the motivation you wanted? Two: I use two papers with models and one paper about a dataset. Is this enough, or should I add more papers? Three: I added the chat and the map myself, to make the system easier to use. They do not come from the papers. Should I explain them as easy-to-use features, or remove them from the thesis? Four: for case study 1, I want to make the same small dataset two times: by hand with Python, and with my system. Then I compare the time, the steps and the results. Is this a good evaluation? Now the formal questions. Five: which citation style should I use? Six: is it okay to put the related work after the requirements chapter? Seven: I use AI tools, Claude and Gemini, for code, for help with writing and translating, and for grammar. The decisions, the papers and the checking are my own work. What are the rules, and how should I write this in the thesis? Eight: are there rules for the number of pages and references? And when is the deadline?

(ახლა რამდენიმე კითხვა მაქვს თქვენთან. ისინი ჩემს მეილშიც არის და მონახაზის ბოლოშიც. ჯერ შინაარსი. ერთი: ასეთი მოტივაცია გინდოდათ? ორი: ვიყენებ ორ სტატიას მოდელებით და ერთ სტატიას მონაცემთა ნაკრებზე. ეს საკმარისია, თუ მეტი სტატია დავამატო? სამი: ჩატი და რუკა თვითონ დავამატე, რომ სისტემით სარგებლობა მარტივი ყოფილიყო. ისინი სტატიებიდან არ მოდის. მარტივად გამოსაყენებელ ფუნქციებად ავხსნა, თუ ნაშრომიდან ამოვიღო? ოთხი: case study 1-ისთვის ერთი და იგივე პატარა მონაცემთა ნაკრების ორჯერ შექმნა მინდა: ხელით, Python-ით, და ჩემი სისტემით. მერე შევადარებ დროს, ნაბიჯებს და შედეგებს. ეს კარგი შეფასებაა? ახლა ფორმალური კითხვები. ხუთი: ციტირების რომელი სტილი გამოვიყენო? ექვსი: შეიძლება, რომ მონათესავე ნაშრომების თავი მოთხოვნების თავის შემდეგ იყოს? შვიდი: AI ხელსაწყოებს ვიყენებ, Claude-სა და Gemini-ს, კოდისთვის, წერასა და თარგმნაში დასახმარებლად და გრამატიკისთვის. გადაწყვეტილებები, სტატიები და შემოწმება ჩემი სამუშაოა. რა წესებია და როგორ დავწერო ეს ნაშრომში? რვა: არის წესები გვერდებისა და წყაროების რაოდენობაზე? და როდის არის ბოლო ვადა?)

---

## სლაიდი 10: Thank you

Thank you very much. If I forgot something today, you can find it in the email and in the draft. My next steps are: find sources for the open points in red, look at similar tools in their official documentation, and start case study 1. I will write down what we decided and send it to you by email. When can we meet next time?

(დიდი მადლობა. თუ დღეს რამე გამომრჩა, მეილსა და მონახაზში ნახავთ. ჩემი შემდეგი ნაბიჯებია: წითლად მონიშნული ღია პუნქტებისთვის წყაროების მოძიება, მსგავსი ხელსაწყოების ნახვა მათ ოფიციალურ დოკუმენტაციაში და case study 1-ის დაწყება. რაც გადავწყვიტეთ, ჩავიწერ და მეილით გამოგიგზავნით. შემდეგ როდის შეგვიძლია შეხვედრა?)
