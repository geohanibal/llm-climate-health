# პრეზენტაციის სცენარი, 2026-11-19 (Thomas, B1 ინგლისური)

> ემთხვევა `2026-11-19_presentation.pptx`-ის სლაიდებსა და შენიშვნებს (PDF-ვერსია: `2026-11-19_presentation.pdf`).

---

## სლაიდი 1: Progress since 2 November

Thank you for meeting me. I want to show what I did since our meeting on 2 November: regional data, related systems and literature. At the end I want to talk about the registration of my thesis.

(მადლობა, რომ შემხვდით. მინდა გაჩვენოთ, რა გავაკეთე 2 ნოემბრის შეხვედრის შემდეგ: რეგიონული მონაცემები, მსგავსი სისტემები და ლიტერატურა. ბოლოს ჩემი ნაშრომის რეგისტრაციაზე მინდა ვისაუბრო.)

---

## სლაიდი 2: Regional data is possible for Thailand

First, regional data. I checked if it is possible. OpenDengue has monthly dengue data for every province in Thailand, from 1993 to 2022. Thirty countries have monthly or weekly regional data. Lin showed me the province borders on HDX: 77 provinces, with an open licence. I also found that a new province, Bueng Kan, started in 2011. So I need the same step as Suttirat: merge Bueng Kan with Nong Khai. The province table is now ready. After merging Bueng Kan into Nong Khai, my table has exactly 18,240 province-months, the same number as in the Suttirat paper.

(პირველი, რეგიონული მონაცემები. შევამოწმე, შესაძლებელია თუ არა. OpenDengue-ს ტაილანდის ყველა პროვინციისთვის თვიური მონაცემები აქვს, 1993-დან 2022-მდე. ოცდაათ ქვეყანას აქვს თვიური ან კვირის რეგიონული მონაცემები. Lin-მა პროვინციების საზღვრები HDX-ზე მაჩვენა: 77 პროვინცია, ღია ლიცენზიით. ასევე აღმოვაჩინე, რომ 2011-ში ახალი პროვინცია, Bueng Kan, გაჩნდა. ამიტომ Suttirat-ის მსგავსი ნაბიჯი მჭირდება: Bueng Kan-ის Nong Khai-სთან გაერთიანება. პროვინციების ცხრილი უკვე მზადაა. Bueng Kan-ის Nong Khai-სთან გაერთიანების შემდეგ ჩემს ცხრილში ზუსტად 18 240 პროვინცია-თვეა, იგივე რიცხვი, რაც Suttirat-ის სტატიაშია.)

---

## სლაიდი 3: Regional climate and population: my plan

For the climate, I see three options. Option A: several points in each province and the mean. This works with my current code. Option B: the ERA5 grid with an area-weighted mean, like Lowe et al. This is better, but more work. Option C: one point per province, which is too simple. I want to start with A and do B later. For population, WorldPop has open data from 2015. Before 2015 is still open.

(კლიმატისთვის სამ ვარიანტს ვხედავ. ვარიანტი A: თითო პროვინციაში რამდენიმე წერტილი და მათი საშუალო. ეს ჩემს არსებულ კოდთან მუშაობს. ვარიანტი B: ERA5-ის ბადე ფართობით შეწონილი საშუალოთი, როგორც Lowe et al.-თან. ეს უკეთესია, მაგრამ მეტ შრომას მოითხოვს. ვარიანტი C: თითო პროვინციაზე ერთი წერტილი, რაც ზედმეტად მარტივია. მინდა A-თი დავიწყო, B კი მოგვიანებით გავაკეთო. მოსახლეობისთვის WorldPop-ს 2015-დან ღია მონაცემები აქვს. 2015-მდე ჯერ ღიაა.)

---

## სლაიდი 4: Related systems (tips from Lin)

Lin told me about two systems. DHIS2 is for ministries of health. It adds climate data to districts and makes forecasts. DART is a forecast system for dengue in Viet Nam. My system is different: it prepares open data for researchers who build their own models, and it shows where every number comes from.

(Lin-მა ორი სისტემა მირჩია. DHIS2 ჯანდაცვის სამინისტროებისთვისაა. ის კლიმატის მონაცემებს რაიონებს უმატებს და პროგნოზებს აკეთებს. DART ვიეტნამში დენგეს პროგნოზის სისტემაა. ჩემი სისტემა განსხვავდება: ის ღია მონაცემებს ამზადებს მკვლევრებისთვის, რომლებიც საკუთარ მოდელებს აგებენ, და აჩვენებს, საიდან მოდის თითოეული რიცხვი.)

---

## სლაიდი 5: Literature: skills gap and new papers

Last time you said I need a source for the skills gap. I found two studies. They show a lack of data science skills in health. But they do not measure programming alone, so in the draft I write data science skills. I also found two new papers with the same data preparation steps: one about dengue in Viet Nam and one about malaria in Mozambique. I am reading them now.

(გასულ ჯერზე თქვით, რომ უნარების ნაკლებობისთვის წყარო მჭირდება. ორი კვლევა ვიპოვე. ისინი ჯანდაცვაში Data Science-ის უნარების ნაკლებობას აჩვენებს. მაგრამ პროგრამირებას ცალკე არ ზომავს, ამიტომ მონახაზში Data Science-ის უნარებს ვწერ. ასევე ორი ახალი სტატია ვიპოვე მონაცემების მომზადების იგივე ნაბიჯებით: ერთი ვიეტნამის დენგეზე, მეორე მოზამბიკის მალარიაზე. ახლა მათ ვკითხულობ.)

---

## სლაიდი 6: I think I am ready to register

Now the registration. I think I am ready. The system works, the requirements come from papers, and I have a first draft. The regional data, the case studies, the related work and the writing are still to do. I think this is possible in sixteen weeks. So I would like to register in the next two weeks. Then the deadline would be around the end of March. What do you think?

(ახლა რეგისტრაცია. მგონი, მზად ვარ. სისტემა მუშაობს, მოთხოვნები სტატიებიდან მოდის და პირველი მონახაზი მაქვს. ჯერ დარჩენილია რეგიონული მონაცემები, case study-ები, მონათესავე ნაშრომები და წერა. მგონი, ეს თექვსმეტ კვირაში შესაძლებელია. ამიტომ მინდა მომდევნო ორ კვირაში დავრეგისტრირდე. მაშინ ბოლო ვადა დაახლოებით მარტის ბოლო იქნება. რას ფიქრობთ?)

---

## სლაიდი 7: Registration form: examiners and title

For the form I need two things. First, the examiners. The rule says one examiner must be from category a or b. On the list, Peter is in category a and you are in category c. Who should be the first and who the second examiner? Second, the title. I have three proposals. Which one do you like, or should I change it?

(ფორმისთვის ორი რამ მჭირდება. პირველი, შემფასებლები. წესის მიხედვით, ერთი შემფასებელი კატეგორია a-დან ან b-დან უნდა იყოს. სიაში Peter კატეგორია a-შია, თქვენ კი კატეგორია c-ში. ვინ უნდა იყოს პირველი და ვინ მეორე შემფასებელი? მეორე, სათაური. სამი შეთავაზება მაქვს. რომელი მოგწონთ, თუ შევცვალო?)

---

## სლაიდი 8: Thesis format: what I found, what I ask

About the format. I will write the thesis in English. The examination rules allow German or English. I did not find rules for the length, the citation style or a template. Do you have a template or a page number in mind? Also, only the PDF goes to the examiners, not the code. Is it okay if I put a link to GitHub or Zenodo in the thesis?

(ფორმატის შესახებ. ნაშრომს ინგლისურად დავწერ. საგამოცდო წესები გერმანულსაც და ინგლისურსაც უშვებს. მოცულობის, ციტირების სტილისა და შაბლონის წესები ვერ ვიპოვე. გაქვთ შაბლონი ან გვერდების რაოდენობა მხედველობაში? ასევე, შემფასებლებთან მხოლოდ PDF მიდის და არა კოდი. მისაღებია, თუ ნაშრომში GitHub-ის ან Zenodo-ს ბმულს ჩავსვამ?)

---

## სლაიდი 9: Questions for you

Here are all my questions together. If we do not have time for all of them, the first four are the most important for the registration.

(აქ ყველა ჩემი კითხვაა ერთად. თუ ყველასთვის დრო არ გვექნება, პირველი ოთხი რეგისტრაციისთვის ყველაზე მნიშვნელოვანია.)

---

## სლაიდი 10: Thank you

Thank you very much. My next steps are: register the thesis, finish the province table, and read the new papers. I will write down what we decided and send it by email to you, Peter and Lin.

(დიდი მადლობა. ჩემი შემდეგი ნაბიჯებია: ნაშრომის რეგისტრაცია, პროვინციების ცხრილის დასრულება და ახალი სტატიების წაკითხვა. რაც გადავწყვიტეთ, ჩავიწერ და მეილით გამოგიგზავნით თქვენ, Peter-სა და Lin-ს.)
