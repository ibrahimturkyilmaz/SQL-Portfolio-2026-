--Bankamız şikayetleri çözemiyor mu, şikayet eden herkes hesabını kapatıp gidiyor mu?

SELECT
    COUNT(*) AS Toplam_Musteri,
    SUM(CAST(Exited AS INT)) AS Kacip_Giden_Sayisi,
    -- Yüzde Hesabı (Burada da CAST lazım)
    CAST(SUM(CAST(Exited AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Kayip_Orani_Yuzde
FROM
   [dbo].[Bank Customer Churn Dataset] ;


   --ülkelere göre bunun oranı nedir?  Banka Fransa, Almanya ve İspanya'da hizmet veriyor. Hangi ülkede müşteriler daha sadıksız?
  --geography sütunu
  SELECT
    Geography,
    COUNT(*) AS Toplam_Musteri,
    SUM(CAST(Exited AS INT)) AS Kacip_Giden_Sayisi,
    -- Yüzde Hesabı (Burada da CAST lazım)
    CAST(SUM(CAST(Exited AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Kayip_Orani_Yuzde
FROM
   [dbo].[Bank Customer Churn Dataset] 
   group by  Geography

   --kadın erkek ayrımı
   SELECT
    Geography,
    Gender,
    COUNT(*) AS Toplam_Musteri,
    SUM(CAST(Exited AS INT)) AS Kacip_Giden,
    -- Yüzdelik Oran
    CAST(SUM(CAST(Exited AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Kayip_Orani
FROM
    [dbo].[Bank Customer Churn Dataset]
GROUP BY
    Geography, Gender
ORDER BY
    Geography, Kayip_Orani DESC; -- En yüksek kaybı en üste getir
   --Müşterinin kullandığı ürün sayısı (NumOfProducts) arttıkça sadakati artar mı? Yoksa 3-4 ürünü olanlar kaçıyor mu?


--zor soru
  -- Ürün Sayısı Paradoksu
--Senaryo: Müşterinin kullandığı ürün sayısı (NumOfProducts) arttıkça sadakati artar mı? Yoksa 3-4 ürünü olanlar kaçıyor mu?
-- Ürün adedine göre Churn oranlarını çıkar.


SELECT
    NumOfProducts AS Urun_Sayisi,
    COUNT(*) AS Toplam_Musteri,
    SUM(CAST(Exited AS INT)) AS Kacip_Giden_Sayisi,
    -- Yüzdelik Kayıp Oranı
    CAST(SUM(CAST(Exited AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Kayip_Orani_Yuzde
FROM
    [dbo].[Bank Customer Churn Dataset]
GROUP BY
    NumOfProducts
ORDER BY
    NumOfProducts ASC;

-- Eski müşteri bankayı bırakmaz" hipotezi doğru mu? 1 yıllık müşteri ile 10 yıllık müşterinin terk etme oranlarını kıyasla.
--Tenure sütununa göre gruplama yap.



SELECT
    Tenure AS Kac_Yillik_Musteri,
    COUNT(*) AS Toplam_Musteri,
    SUM(CAST(Exited AS INT)) AS Kacip_Giden_Sayisi,
    -- Yüzdelik Kayıp Oranı
    CAST(SUM(CAST(Exited AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Kayip_Orani_Yuzde
FROM
    [dbo].[Bank Customer Churn Dataset]
GROUP BY
    Tenure
ORDER BY
    Tenure ASC;

--Senaryo: Bakiyesi (Balance) 100.000$ dan fazla olup bankayı terk eden kaç kişi var? Bu banka için büyük bir nakit kaybı demek.
--WHERE Balance > 100000 AND Exited = 1 filtresiyle toplam kaybedilen parayı (SUM(Balance)) bul.


select Exited, Sum(Balance)as kaybedilen_para,
    COUNT(*) AS Toplam_Musteri
from     [dbo].[Bank Customer Churn Dataset]
where Exited = 1 AND Balance > 100000   
group by Exited

--Senaryo: Kredi kartı olanlar (HasCrCard=1) mı daha sadık, olmayanlar mı?


select Gender, HasCrCard, 
    COUNT(*) AS Toplam_Musteri,
    SUM(CAST(Exited AS INT)) AS Kacip_Giden_Sayisi,
    -- Yüzdelik Kayıp Oranı
    CAST(SUM(CAST(Exited AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Kayip_Orani_Yuzde
from     [dbo].[Bank Customer Churn Dataset]

group by Gender, HasCrCard


-- aktiflik önemli mi? 

select Gender, IsActiveMember, HasCrCard, 
    COUNT(*) AS Toplam_Musteri,
    SUM(CAST(Exited AS INT)) AS Kacip_Giden_Sayisi,
    -- Yüzdelik Kayıp Oranı
    CAST(SUM(CAST(Exited AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Kayip_Orani_Yuzde
from     [dbo].[Bank Customer Churn Dataset]

group by Gender, HasCrCard, IsActiveMember
-- kaç ürün riskli ?
SELECT 
    NumOfProducts AS Urun_Sayisi,
    COUNT(*) AS Toplam_Musteri,
    SUM(CAST(Exited AS INT)) AS Kacip_Giden,
    CAST(SUM(CAST(Exited AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Kayip_Orani_Yuzde
FROM [dbo].[Bank Customer Churn Dataset]
GROUP BY NumOfProducts
ORDER BY NumOfProducts;

--yaş grubu ne kadar etkili?
-- Senaryo: Yaş Gruplarına Göre Müşteri Kaybı (Age Buckets)
SELECT 
    CASE 
        WHEN Age < 30 THEN '1. Genc (18-29)'
        WHEN Age BETWEEN 30 AND 40 THEN '2. Genc Yetiskin (30-40)'
        WHEN Age BETWEEN 41 AND 50 THEN '3. Orta Yas (41-50)'
        WHEN Age BETWEEN 51 AND 60 THEN '4. Olgun (51-60)'
        ELSE '5. Emekli (60+)'
    END AS Yas_Grubu,
    COUNT(*) AS Toplam_Musteri,
    SUM(CAST(Exited AS INT)) AS Kacip_Giden_Sayisi,
    CAST(SUM(CAST(Exited AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Kayip_Orani_Yuzde
FROM [dbo].[Bank Customer Churn Dataset]
GROUP BY 
    CASE 
        WHEN Age < 30 THEN '1. Genc (18-29)'
        WHEN Age BETWEEN 30 AND 40 THEN '2. Genc Yetiskin (30-40)'
        WHEN Age BETWEEN 41 AND 50 THEN '3. Orta Yas (41-50)'
        WHEN Age BETWEEN 51 AND 60 THEN '4. Olgun (51-60)'
        ELSE '5. Emekli (60+)'
    END
ORDER BY Yas_Grubu;


--ülkelere göre card tipleri ve balance

select Geography, Card_Type, Sum(Balance) as toplam_para
       FROM [dbo].[Bank Customer Churn Dataset]
group by  Geography, Card_Type order by toplam_para desc
