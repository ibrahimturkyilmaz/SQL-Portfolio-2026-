-- Yeni bir Master Tablo oluþturuyoruz
SELECT *
INTO [dbo].[Online_Retail_All] -- Yeni tablonun adý bu olacak
FROM (
    -- 1. Tabloyu Al
    SELECT * FROM [dbo].[online_retail_II] -- BURAYA KENDÝ 1. TABLO ADINI YAZ
    
    UNION ALL -- "Altýna Yapýþtýr" komutu
    
    -- 2. Tabloyu Al
    SELECT * FROM [dbo].[online_retail_II_2009_2010_2] -- BURAYA KENDÝ 2. TABLO ADINI YAZ
) AS Birlestirme;

------ ## ÝKÝ TABLO CSV TÝPÝNE ÇEVRÝLDÝ TEKLÝ AKTARILDI VE BURADA BÝRLEÞTÝRÝLDÝ.

SELECT 
    COUNT(*) AS Toplam_Satir,
    COUNT([Customer_ID]) AS ID_Olanlar, -- Gerçek müþteriler
    COUNT(*) - COUNT([Customer_ID]) AS ID_Olmayanlar, -- Misafirler (Boþ)
    
    -- Oraný Görelim: Eðer %20-25 civarý boþsa NORMALDÝR.
    -- Eðer %80-90'ý boþsa TERSLÝK VARDIR.
    100 * (COUNT(*) - COUNT([Customer_ID])) / COUNT(*) AS Bos_Orani_Yuzde
FROM [dbo].[Online_Retail_All];


-- Ýptal Verilerini Kaydet ve temiz verileri kaydet
SELECT 
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    Customer_ID,
    Country,
    -- YENÝ SÜTUN: Ciro Hesabý (Adet x Fiyat)
    (Quantity * Price) AS Total_Price 
INTO [dbo].[Online_Retail_Ýptaller]
FROM [dbo].[Online_Retail_All]
WHERE 
    -- 1. Hayalet Müþterileri Temizle (Senin örnekteki NULL'lar)
    Customer_ID IS NOT NULL
    -- 2. Ýptalleri al ('C' ile baþlayan faturalar)
    AND Invoice LIKE 'C%'


    -- 3. Hatalý/Bedelsiz Ýþlemleri Temizle
   -- AND Price > 0
   -- AND Quantity > 0; -- Negatif adetleri de (iade) eledik
   select * from 
[dbo].[Online_Retail_Clean]
order by InvoiceDate 


--Recency (Yenilik): Referans tarihi olarak verisetinin en son tarihini baz alacaðýz.
--Frequency (Sýklýk): Kaç farklý fatura (Invoice) kesilmiþ?
--Monetary (Parasal): Toplam Total_Price ne kadar?
-- Temizlik: Varsa eski tabloyu sil

-- Hesapla ve #RFM_Metrikler tablosuna kaydet
SELECT 
    Customer_ID,
    -- En son ne zaman geldi?
    MAX(InvoiceDate) AS Son_Alisveris_Tarihi,
    
    -- Recency: 2012 Yýlbaþýndan geriye kaç gün geçmiþ?
    DATEDIFF(day, MAX(InvoiceDate), '2012-01-01') AS Recency_Degeri,
    
    -- Frequency: Kaç farklý fatura kesilmiþ?
    COUNT(DISTINCT Invoice) AS Frequency_Degeri,
    
    -- Monetary: Toplam ne kadar ciro býrakmýþ?
    SUM(Total_Price) AS Monetary_Degeri
    
INTO #RFM_Metrikler -- SONUCU BURAYA YAZIYORUZ
FROM [dbo].[Online_Retail_Clean]
GROUP BY Customer_ID;

-- Kontrol: Ýlk 5 satýra bakalým, tablo dolmuþ mu?
SELECT TOP 5 * FROM #RFM_Metrikler ORDER BY Monetary_Degeri DESC;

SELECT 
    Customer_ID,
    Recency_Degeri, Frequency_Degeri, Monetary_Degeri,
    
    -- Recency: Az gün = Yüksek Puan (5) -> DESC
    NTILE(5) OVER (ORDER BY Recency_Degeri DESC) AS R_Skor,
    
    -- Frequency: Çok iþlem = Yüksek Puan (5) -> ASC
    NTILE(5) OVER (ORDER BY Frequency_Degeri ASC) AS F_Skor,
    
    -- Monetary: Çok para = Yüksek Puan (5) -> ASC
    NTILE(5) OVER (ORDER BY Monetary_Degeri ASC) AS M_Skor

INTO #RFM_Skorlama
FROM #RFM_Metrikler; 
-- Kontrol: Puanlar gelmiþ mi?
SELECT TOP 5 * FROM #RFM_Skorlama ORDER BY M_Skor DESC;


SELECT 
    Customer_ID,
    R_Skor, F_Skor, M_Skor,
    
    -- Skorlarý görsel olarak birleþtir (Örn: "555")
    CAST(R_Skor AS varchar) + CAST(F_Skor AS varchar) + CAST(M_Skor AS varchar) AS RFM_Skoru,
    
    -- SEGMENTASYON MANTIÐI
    CASE 
        WHEN R_Skor = 5 AND F_Skor = 5 THEN 'Þampiyon (Champions)'
        WHEN R_Skor <= 2 AND F_Skor = 5 THEN 'Riskli / Kayýp (Cant Lose)' -- Eskiden çok alýrdý, þimdi yok
        WHEN R_Skor = 5 AND F_Skor = 1 THEN 'Yeni Gelen (New Customer)'
        WHEN R_Skor <= 2 AND F_Skor <= 2 THEN 'Uykuda (Hibernating)'
        WHEN R_Skor >= 3 AND F_Skor >= 3 THEN 'Sadýk (Loyal)'
        ELSE 'Potansiyel / Diðer'
    END AS Musteri_Segmenti,
    
    Recency_Degeri, Frequency_Degeri, Monetary_Degeri

FROM #RFM_Skorlama
ORDER BY M_Skor DESC, F_Skor DESC;



SELECT 
    Customer_ID,
    R_Skor, F_Skor, M_Skor,
    
    -- Skorlarý görsel olarak birleþtir (Örn: "555")
    CAST(R_Skor AS varchar) + CAST(F_Skor AS varchar) + CAST(M_Skor AS varchar) AS RFM_Skoru,
    
    -- SEGMENTASYON MANTIÐI
    CASE 
        WHEN R_Skor = 5 AND F_Skor = 5 THEN 'Þampiyon (Champions)'
        WHEN R_Skor <= 2 AND F_Skor = 5 THEN 'Riskli / Kayýp (Cant Lose)' -- Eskiden çok alýrdý, þimdi yok
        WHEN R_Skor = 5 AND F_Skor = 1 THEN 'Yeni Gelen (New Customer)'
        WHEN R_Skor <= 2 AND F_Skor <= 2 THEN 'Uykuda (Hibernating)'
        WHEN R_Skor >= 3 AND F_Skor >= 3 THEN 'Sadýk (Loyal)'
        ELSE 'Potansiyel / Diðer'
    END AS Musteri_Segmenti,
    
    Recency_Degeri, Frequency_Degeri, Monetary_Degeri

FROM #RFM_Skorlama
ORDER BY M_Skor DESC, F_Skor DESC;

--"Ocak ayýnda ilk kez gelen müþterilerin kaçý Þubat ayýnda bizi terk etti? Sadakat oranýmýz (Retention Rate) ne?"
--Doðum Günü (Cohort Ayý): Müþterinin bizimle tanýþtýðý ilk ay.


--Yaþam Süresi (Cohort Index): Müþterinin ilk aydan sonraki her alýþveriþinin kaç ay sonra gerçekleþtiði. 
--(0 = Ýlk ay, 1 = Sonraki ay).

SELECT 
    Customer_ID,
    MIN(InvoiceDate) AS Ilk_Tarih
INTO #Ilk_Tarihler
FROM [dbo].[Online_Retail_Clean]
GROUP BY Customer_ID;

-- Kontrol: Bakalým tablo dolmuþ mu?
SELECT TOP 5 * FROM #Ilk_Tarihler;

--Ay_Index = 0 iken sayý kaç? (Bu, o ay gelen toplam yeni müþteri sayýsýdýr).
--Ay_Index = 1 (Ocak 2011) olduðunda sayý kaça düþmüþ?

SELECT 
    S.Customer_ID,
    -- Müþterinin Grubu (Örn: 2010-12 Grubu)
    FORMAT(I.Ilk_Tarih, 'yyyy-MM') AS Cohort_Ay,
    
    -- Alýþveriþ Tarihi ile Ýlk Tarih arasýndaki Ay Farký
    (DATEDIFF(year, I.Ilk_Tarih, S.InvoiceDate) * 12) + 
    (DATEDIFF(month, I.Ilk_Tarih, S.InvoiceDate)) AS Ay_Index
    
INTO #Cohort_Analiz
FROM [dbo].[Online_Retail_Clean] S
JOIN #Ilk_Tarihler I ON S.Customer_ID = I.Customer_ID;

-- Kontrol: Veri düzgün akmýþ mý?
SELECT TOP 5 * FROM #Cohort_Analiz;

SELECT 
    Cohort_Ay,
    Ay_Index, 
    COUNT(DISTINCT Customer_ID) AS Kalan_Musteri_Sayisi
FROM #Cohort_Analiz
WHERE Ay_Index <= 12 -- Ýlk 1 yýl bizim için yeterli
GROUP BY Cohort_Ay, Ay_Index
ORDER BY Cohort_Ay, Ay_Index;

--Ay_Index 0: Bu sayý, o ay gelen "Yeni Müþteri" sayýsýdýr (Örn: 885 kiþi).
--Ay_Index 1: Bu sayý, o 885 kiþinin kaçýnýn Ocak ayýnda geri geldiðidir. 
--Giriþ: 383 Yeni Müþteri.
--1. Ay (Þubat): Sadece 79'u geri gelmiþ.

--Hangi ürünler "ayrýlmaz ikilidir"? 
--(Örn: Çay alan Þeker de alýyor mu?) Bunu bilirsek web sitesinde "Bunu alan bunlarý da aldý" önerisi yaparýz.

[dbo].[Online_Retail_Clean]

-- customer id, descp, invoice, quantity
SELECT 
    Customer_ID, 
    Total_Price,
    Invoice, 
    StockCode, 
    Description
INTO #Sepet_Verisi
FROM [dbo].[Online_Retail_Clean]
WHERE Description IS NOT NULL; -- Ýsimsiz ürünleri eledik


--Fatura ayný olsun (Invoice = Invoice) AMA Ürün farklý olsun (StockCode < StockCode).

SELECT 
    sv.StockCode as urun_a, 
    spv.StockCode as urun_b, 
    COUNT(*) AS Birlikte_Alinma_Sayisi
INTO #Sepet_sonuc 
FROM #Sepet_Verisi sv 
join #Sepet_Verisi spv on sv.StockCode = spv.StockCode -- Ayný Sepet
where sv.StockCode < spv.StockCode -- Kendisiyle eþleþmesin ve çift kayýt olmasýn

GROUP BY sv.StockCode, spv.StockCode
ORDER BY Birlikte_Alinma_Sayisi DESC;
--------------------------------------------------------------------------------------------------------------------------
SELECT TOP 1000 -- Þimdilik en popüler 1000 ikiliyi bulalým
    T1.Description AS Urun_A,
    T2.Description AS Urun_B,
    COUNT(*) AS Birlikte_Alinma_Sayisi
    
INTO #Sepet_Sonuc2
FROM #Sepet_Verisi T1
JOIN #Sepet_Verisi T2 ON T1.Invoice = T2.Invoice -- Ayný Sepet
WHERE T1.StockCode < T2.StockCode -- Kendisiyle eþleþmesin ve çift kayýt olmasýn

GROUP BY T1.Description, T2.Description
ORDER BY Birlikte_Alinma_Sayisi DESC;

SELECT * FROM #Sepet_Sonuc2 ORDER BY Birlikte_Alinma_Sayisi DESC;

--Tamam, ciro yapýyoruz ama bizim için gerçekten deðerli müþteri kim?
-- Sadece çok harcayan mý, yoksa sýk sýk gelip az harcayan mý? Bana pazarlama bütçesini kime harcayacaðýmý söyle."

--Historical CLV (Gerçekleþen Deðer) hesaplayacaðýz.
--Ortalama Sepet Tutarý (AOV) =Toplam Ciro \Ýþlem Sayýsý

-- customerid, total_price, invoice, date,

select Customer_ID, 
sum(Total_Price) as toplam_ciro,
count(distinct Invoice)as iþlem_sayýsý,

sum(Total_Price) / count(distinct Invoice) as ortalama_sepet_tutarý,

datediff(day, min(InvoiceDate), Max(InvoiceDate)) as Musteri_Gün -- ilk geliþinden kaç gün geçti

into #CLV_hesap
from [dbo].[Online_Retail_Clean]

group by Customer_ID
having sum(Total_Price) > 0 --iadeler

#CLV_hesap


--#CLV_Segment) Þimdi müþterileri 4 sýnýfa ayýracaðýz

--A Sýnýfý (Elmas): Yüksek Ciro + Yüksek AOV (Þirketi ayakta tutanlar).
--B Sýnýfý (Altýn): Ortalamanýn üstü.
--C Sýnýfý (Gümüþ): Ýdare eder.
--D Sýnýfý (Bronz): Düþük getiri.

select 
    Customer_ID,
    toplam_ciro,
    iþlem_sayýsý,
    ortalama_sepet_tutarý,
    -- Toplam Ciroya göre 4 gruba böl (1: En kötü, 4: En iyi)
    NTILE(4) OVER (ORDER BY Toplam_Ciro ASC) AS Ciro_Skoru
INTO #CLV_Segment
FROM #CLV_hesap;

--segmentlere ayýrma

select  
Customer_ID, --müþteri gubuna ait customer_idleri bulma
    case    
        when Ciro_Skoru = 4 THEN  'A segment'
        when Ciro_Skoru = 3 THEN  'b segment'
        when Ciro_Skoru = 2 THEN  'c segment'
        when Ciro_Skoru = 1 THEN  'd segment'
    end as müþteri_grubu,
    count(*) as kiþi_sayýsý,
    CAST(AVG(Toplam_Ciro) AS decimal(10,2)) AS Ort_Ciro,
    CAST(AVG(ortalama_sepet_tutarý) AS decimal(10,2)) AS Ort_Sepet_Tutari

    FROM #CLV_Segment
GROUP BY Customer_ID,Ciro_Skoru
ORDER BY Ciro_Skoru DESC;

--Yýlbaþý yoðunluðu ne zaman baþlýyor? Ekstra personel almalý mýyým? Ayrýca gün içinde kargolarý hazýrlamak için en yoðun saat hangisi?"
--Önce satýþlarýn aylara göre nasýl dalgalandýðýna bakalým. Hangi aylar "ölü sezon", hangi aylar "patlama" dönemi?


select 
    year(InvoiceDate) as yýl,
    month(InvoiceDate) as ay,
    datename(month, InvoiceDate) as ayismi,
    count(distinct Invoice) as sipariþ_sayýsý,
    sum(Total_Price) as toplam_ciro

    into #aylýk_trend
    from [dbo].[Online_Retail_Clean]
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate), DATENAME(month, InvoiceDate)
    ORDER BY yýl, ay;

 #aylýk_trend;

 --Haftanýn hangi günü ve günün hangi saati en yoðun? Bu, vardiya planlamasý için kritiktir.
 SELECT 
    Invoice,
    -- Haftanýn Günü (Örn: Monday)
    DATENAME(dw, InvoiceDate) AS Gun,
    -- Günün Saati (0-23)
    DATEPART(hh, InvoiceDate) AS Saat,
    Total_Price
INTO #Zaman_Analizi
FROM [dbo].[Online_Retail_Clean];
-- 1. RAPOR: Hangi Gün En Yoðun?
SELECT 
    Gun,
    COUNT(DISTINCT Invoice) AS Siparis_Sayisi,
    SUM(Total_Price) AS Ciro
FROM #Zaman_Analizi
GROUP BY Gun
ORDER BY Siparis_Sayisi DESC;
-- 2. RAPOR: Hangi Saat En Yoðun? (Heatmap Verisi)
SELECT 
    Saat,
    COUNT(DISTINCT Invoice) AS Siparis_Sayisi
FROM #Zaman_Analizi
GROUP BY Saat
ORDER BY Saat;

--seviye 3 için adventureworks dosyasýna geçiþ