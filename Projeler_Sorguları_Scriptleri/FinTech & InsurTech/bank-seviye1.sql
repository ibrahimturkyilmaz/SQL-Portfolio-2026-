

[dbo].[bank]
--Pazarlama & Kampanya Yönetimi.
--Banka bu kampanyada genel olarak ne kadar başarılı oldu? %10 barajını geçebildik mi?

SELECT 
    COUNT(*) AS Toplam_Arama,
    SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS Basarili_Satis,
    CAST(SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Basari_Orani_Yuzde
FROM 
   [dbo].[bank]; 

--Satış yapmak için müşteriyi telefonda ortalama kaç dakika tutmak gerekiyor? Bu analiz, çağrı merkezi KPI'ları için hayati önem taşır.

select 
deposit as sonuc,
count(*) as kisi_sayisi,
avg(duration) as saniye,
cast(avg(duration) / 60.0 as DECIMAL(5,2)) as ortalama_tutma_dk_süresi
from [dbo].[bank]
group by deposit

--Hangi meslek grubu parayi daha çok seviyor? Pazarlama bütçesini öğrenciye mi harcayalim, emekliye mi, yoksa yöneticiye mi?

select 
       job as meslek,
       count(*) as toplam_aranan,
       SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS Satis_Adedi,
       CAST(SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Basari_Orani
--Mantik: SQL satir satir aşaği iner.
--Baktiği satirda müşteri yes dediyse → Haneye 1 puan yazar.
--Müşteri no dediyse → Haneye 0 puan yazar.


       FROM
    [dbo].[bank]
GROUP BY
    job
HAVING
    COUNT(*) > 50 -- İstatistiksel sapmayı önlemek için en az 50 kere aranmış meslekleri alalım
ORDER BY
    Basari_Orani DESC;
    
    
    --Pazarlama ekibinin bir teorisi var: "Evlilerin masrafi çok, parayı yatirima bağlamazlar. Bekarlar daha rahat para biriktirir."
    SELECT 
    marital AS Medeni_Hal,
    COUNT(*) AS Kisi_Sayisi,
    AVG(balance) AS Ortalama_Bakiye, -- Kimin cebinde daha çok para var?
    CAST(SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Basari_Orani
FROM 
    [dbo].[bank]
GROUP BY 
    marital
ORDER BY 
    Basari_Orani DESC;

--yilin hangi ayinda (month) insanlar para biriktirmeye (mevduat açmaya) daha meyilli?
--aylara göre 'yes' sayilarini çıkar.


select month, count(*) as toplam_islem,        SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS _basarili_Satis_Adedi,
        CAST(SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Basari_Orani
from [dbo].[bank] 
group by month 
ORDER BY 
    Basari_Orani DESC; -- En başarılı ayı en tepeye getirir

--Eğitim seviyesi (education) arttıkça müşterinin bankadaki bakiyesi (balance) artiyor mu?
    SELECT
    education AS Egitim_Durumu,
    COUNT(*) AS Kisi_Sayisi,    -- İstatistiksel olarak anlamiş mi? (Az kişi olmasin)
    AVG(balance) AS Ortalama_Bakiye -- Kimin parasi daha çok?
FROM 
    [dbo].[bank]
GROUP BY 
    education
ORDER BY 
    Ortalama_Bakiye DESC;


    --çagri merkezi çalişanlari bazen bir müşteriyi 10-15 kere ariyor. 
    --Yönetim soruyor: "Bir müşteriyi en fazla kaç kere ararsak satış ihtimali devam eder? Nereden sonra müşteriyi taciz etmeye (ve kaybetmeye) başliyoruz?" 
    --arama sayisi (campaign) bazinda başari oranlarini çıkar.
--Tam olarak toplam 3 kere arananlarin başarı orani nedir?" "Tam olarak sadece 1 kere arananlarin başari orani nedir?"
SELECT 
    campaign AS Arama_Sayisi,
    COUNT(*) AS Kisi_Sayisi,
    SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS Satis_Adedi,
    CAST(SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Basari_Orani
FROM 
    [dbo].[bank]
--WHERE campaign <= 10 -- 50 kere aranan istisnaları çıkarıp genele odaklanalım
GROUP BY 
    campaign
ORDER BY 
    Arama_Sayisi ASC;

--Hem Ev Kredisi (housing) hem de İhtiyaç Kredisi (loan) borcu olan birinin, bankaya yeni para yatırması (deposit) ne kadar mümkün?
--müşterileri borç durumuna göre 4 gruba ayırıp analiz et.
--Borcu Yok
--Sadece Ev Kredisi Var
--Sadece İhtiyaç Kredisi Var
--Borçta (İkisi de Var)

SELECT 
    housing AS Ev_Kredisi,
    loan AS Bireysel_Kredi,
    COUNT(*) AS Kisi_Sayisi,
    AVG(balance) AS Ortalama_Bakiye, -- Borçluların parası var mı?
    CAST(SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Basari_Orani
FROM 
    [dbo].[bank]
GROUP BY 
    housing, loan
ORDER BY 
    Basari_Orani DESC;

--poutcome (Previous Outcome) diye  bir sütun var. Bu, müşterinin önceki kampanyaya verdiği tepkiyi gösterir.
--success: Daha önce bizden ürün almiş.
--failure: Reddetmiş.
--unknown: İlk defa ariyoruz. Hipotez: Daha önce ürün sattığımız kişi (Sadık Müşteri), soğuk müşteriden 10 kat daha değerlidir. 
--geçmiş performansin bugüne etkisini ölç.

select count(*) as kişi_sayisi, poutcome as Onceki_Kampanya_Sonucu,
       SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS Yeni_Satis,
       CAST(SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Basari_Orani
from [dbo].[bank]

group by poutcome