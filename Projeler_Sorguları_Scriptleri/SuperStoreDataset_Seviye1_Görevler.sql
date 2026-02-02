
--Þirket genel olarak kârlý görünse de, bazý eyaletlerde ve alt kategorilerde (masalar, dolaplar vb.) ciddi paralar kaybediyoruz.
-- CFO senden "Bize en çok zarar ettiren operasyonlarý listeleyen bir rapor" istiyor.

--gerekli sütunlar , city, state, category, sub catg, sales, profit, 


select 
 state eyalet, category kategori, sub_category alt_kategori, 
sum(sales) toplam_satis, sum(profit) toplam_kar_zarar,
sum(profit)  / sum(sales) as kar_Zarar_yüzde
from [dbo].[Superstore Dataset]

group by state,category, sub_category
-- sadece zarar edenler toplam kar zararý 0 ýn altýnda olanlar
-- aggr fonksiyonlarýnda where olmaz having
HAVING SUM(Profit) < 0  -- Sadece ZARAR edenleri (Negatif olanlarý) getir
order by toplam_kar_zarar asc


--"Bize her kategorinin (Mobilya, Teknoloji, Ofis) en çok ciro yapan ilk 3 ürününü ver.
-- Hepsini tek listede görmek istiyoruz."

--sütunla: Category, Product_Name, Sales.

--window fonksiyonu hazýr alýndý.// order by asc en az desc en çok
;WITH SiralamaTablosu AS (
    SELECT 
        Category, 
        Product_Name, 
        Sales,
        ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Sales asc) as Sira_No
    FROM [dbo].[Superstore Dataset]
)
SELECT * FROM SiralamaTablosu
WHERE Sira_No <= 3;

--Müþterileri çok kazandýrandan aza doðru sýralamak ve cironun ilk %80'ini oluþturanlarý tespit etmek.
--MusteriCiro: Önce her müþteri toplam ne kadar harcamýþ onu buluyoruz.
--ParetoHesap: Burada o "sihirli" pencere fonksiyonunu devreye sokuyoruz.
--SUM(...) OVER (ORDER BY ...) yapýsý, satýrlarý yukarýdan aþaðýya toplayarak iner (Running Total).

--Bütün müþterileri cirolarýna göre sýraya dizip, kümülatif (birikimli) olarak toplamak
;WITH MusteriCiro AS (
    -- 1. ADIM: Müþteri bazýnda toplam ciroyu bul
    SELECT 
        Customer_Name, 
        SUM(Sales) as Toplam_Satis
    FROM [dbo].[Superstore Dataset]
    GROUP BY Customer_Name
),
ParetoHesap AS (
    -- 2. ADIM: Kümülatif Toplam ve Genel Toplamý bul
    SELECT 
        Customer_Name,
        Toplam_Satis,
        
        -- KÜMÜLATÝF TOPLAM (Running Total): En çok satýþtan en aza doðru toplayarak git
        SUM(Toplam_Satis) OVER (ORDER BY Toplam_Satis DESC) as Kumulatif_Ciro,
        
        -- GENEL TOPLAM (Grand Total): Tüm þirketin cirosu (Oranlamak için lazým)
        SUM(Toplam_Satis) OVER () as Genel_Toplam
        
    FROM MusteriCiro
),
-- 3. ADIM: Sonucu Görelim
-- 3. ADIM: Yüzdeyi hesapla ve ETÝKETLE (A/B)
pareto_analizi as (SELECT 
    Customer_Name,
    Toplam_Satis,
    Kumulatif_Ciro,
    -- Virgülden sonra çok hane çýkmasýn diye yuvarlayalým (Opsiyonel)
    ROUND((Kumulatif_Ciro / Genel_Toplam) * 100, 2) as Kumulatif_Yuzde

FROM ParetoHesap
)
-- SEGMENTASYON KODU BURADA BAÞLIYOR
select Customer_Name,
    CASE 
        WHEN Kumulatif_Yuzde <= 80 THEN 'A' -- %80 ve altýysa A Grubu (VIP)
        ELSE 'B' -- %80'i geçtiyse B Grubu (Standart)
    END AS Segment_Grubu
from pareto_analizi

--tabloya ekleme
ALTER TABLE [dbo].[Superstore Dataset]
ADD Segment_Grubu nvarchar(1); -- Sadece 'A' veya 'B' yazacaðýmýz için 1 karakter yeter.
-- 1. CTE ile Hesaplamayý Yap (Senin Kodun)
;WITH MusteriCiro AS (
    SELECT 
        Customer_Name, 
        SUM(Sales) as Toplam_Satis
    FROM [dbo].[Superstore Dataset]
    GROUP BY Customer_Name
),
ParetoHesap AS (
    SELECT 
        Customer_Name,
        SUM(Toplam_Satis) OVER (ORDER BY Toplam_Satis DESC) as Kumulatif_Ciro,
        SUM(Toplam_Satis) OVER () as Genel_Toplam
    FROM MusteriCiro
),
MusteriSegmentleri AS (
    SELECT 
        Customer_Name,
        -- Segmenti burada belirliyoruz
        CASE 
            WHEN (Kumulatif_Ciro / Genel_Toplam) * 100 <= 80 THEN 'A'
            ELSE 'B' 
        END AS Yeni_Segment
    FROM ParetoHesap
)

-- 2. Ana Tabloyu Bu Bilgiyle Güncelle (UPDATE)
UPDATE AnaTablo
SET AnaTablo.Segment_Grubu = S.Yeni_Segment
FROM [dbo].[Superstore Dataset] AS AnaTablo
INNER JOIN MusteriSegmentleri AS S 
    ON AnaTablo.Customer_Name = S.Customer_Name;


--Ýade Oranlarý ve Maliyet Analizi 
--Senaryo Lojistik Direktörü endiþeli: "Çok satýyoruz ama çok da iade alýyoruz. Hangi bölge (Region) sürekli ürün iade ediyor?
-- Ýadelerin bize maliyeti ne?"


--"Müþteriye ürünü ne kadar hýzlý ulaþtýrýyoruz? 
--'Same Day' (Ayný Gün) kargo seçeneðiyle 'Standard Class' arasýnda gerçekten gün farký var mý,
--yoksa müþteriyi mi kandýrýyoruz?"
--Gruplama: Ship_Mode (Kargo Tipi) bazýnda grupla.
--Metrik 1: Ortalama kaç günde kargoya verilmiþ? (AVG ve DATEDIFF kullan).
--Metrik 2: O kargo tipinde kaç sipariþ var? (COUNT).
--Sýralama: En hýzlýdan en yavaþa sýrala.

--eðitimde öðrendik DATEDIFF 

select ship_mode,

--MIN(DATEDIFF(HOUR, [Order_Date], [Ship_Date])) AS ENKISA_TESLÝMATSURESÝ_SAAT,
AVG(DATEDIFF(day, [Order_Date],[Ship_Date])) AS Ortalama_Teslim_Suresi_Gun,
--MAX(DATEDIFF(HOUR, [Order_Date],[Ship_Date])) AS ENUZUN_TESLÝMATSURESÝ_SAAT

COUNT(*) AS Siparis_Sayisi
from [dbo].[Superstore Dataset]
group by Ship_Mode
order by  Ortalama_Teslim_Suresi_Gun asc

--"Satýþlar çok dalgalý! Bir gün 10.000$ satýyoruz, ertesi gün 200$. Bu gürültüden (noise) önümü göremiyorum. 
--Bana günlük zýplamalarý deðil, genel gidiþatý (trendi) gösteren 7 günlük bir ortalama çizgi lazým."

;WITH GunlukOzet AS (
    -- 1. ADIM: Önce veriyi GÜNLÜK olarak gruplayýp topluyoruz
    SELECT 
        [Order_Date],
        SUM(Sales) as Gunluk_Toplam_Ciro
    FROM [dbo].[Superstore Dataset]
    GROUP BY [Order_Date] -- Bunu unutursan hata alýrsýn!
)
SELECT 
    DATEPART(YEAR, [Order_Date]) AS YIL,
    DATEPART(MONTH, [Order_Date]) AS AY,
    [Order_Date],
    
    -- Gün adýný SQL kendisi versin (Daha garanti yöntem)
    DATENAME(WEEKDAY, [Order_Date]) AS Gun_Adi, 
    
    Gunluk_Toplam_Ciro,

    -- 2. ADIM: Hareketli Ortalama Hesabý (SELECT içinde yapýlýr)
    AVG(Gunluk_Toplam_Ciro) OVER (
        ORDER BY [Order_Date] 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as Yedi_Gunluk_Ortalama

FROM GunlukOzet
ORDER BY [Order_Date];

--Haftalýk Karne
SELECT 
    DATEPART(YEAR, [Order_Date]) AS Yil,
    -- Yýlýn kaçýncý haftasý (1-53 arasý)
    DATEPART(WEEK, [Order_Date]) AS Hafta_No,
    -- KPI 1: Toplam Ciro (Kasa ne kadar doldu?)
    SUM(Sales) AS Toplam_Ciro,
    -- KPI 2: Sipariþ Sayýsý (Kaç fatura kestik?)
    COUNT(*) AS Siparis_Adedi,
    -- KPI 3: Ortalama Sepet (Müþteri ortalama kaç paralýk alýþveriþ yaptý?)
    -- (Toplam Ciro / Sipariþ Sayýsý)
    SUM(Sales) / COUNT(*) AS Ortalama_Sepet_Tutari
FROM [dbo].[Superstore Dataset]
GROUP BY 
    DATEPART(YEAR, [Order_Date]), DATEPART(WEEK, [Order_Date])
ORDER BY Yil, Hafta_No;


--"Bana her bölgenin (Region) en iyi 3 müþterisini getir. Onlara özel hediye göndereceðiz. 
--AMA HAK GEÇMESÝN! Eðer iki kiþi ayný ciroyu yapmýþsa, ikisi de 1. olsun. Listede kimsenin hakkýný yeme."
--DENSE_RANK() Kullanýyoruz?
--ROW_NUMBER(): Acýmasýzdýr. Puanlarý ayný olsa bile birine 1, diðerine 2 der.
--DENSE_RANK(): Adaletlidir. Puanlarý aynýysa ikisine de "1" der ve bir sonraki kiþi "2"den devam eder. (Sýralamada boþluk býrakmaz).

--Önce Topla: Müþterileri ve Bölgeleri gruplayýp toplam cirolarýný bul.
--Sonra Sýrala: Her bölgeyi kendi içinde (PARTITION BY Region) puanýna göre derecelendir.
--Filtrele: Sadece ilk 3'e girenleri al.

SELECT  Region,
    SUM(Sales) AS Toplam_Ciro

    FROM [dbo].[Superstore Dataset]
    GROUP BY  Region 
    ORDER BY Toplam_Ciro DESC

;WITH MÜÞTERÝ_ÖZET AS ( -- 1. HATA DÜZELDÝ: WITH eklendi
    SELECT 
        Region, 
        Customer_Name, 
        SUM(Sales) AS Toplam_Ciro
    FROM [dbo].[Superstore Dataset]
    GROUP BY Customer_Name, Region
    -- ORDER BY burda gereksizdir, ONU DIÞTA YAPICAZ
),
SiralamaTablosu AS (
    SELECT 
        Region,
        Customer_Name,
        Toplam_Ciro,
        ---- Bölgeye göre ayýr, Ciroya göre yarýþtýr
        DENSE_RANK() OVER (PARTITION BY Region ORDER BY Toplam_Ciro DESC) as Siralama
    FROM MÜÞTERÝ_ÖZET
)
-- FÝNAL: Sadece Madalya Kazananlar (Ýlk 3)
SELECT * FROM SiralamaTablosu
WHERE Siralama <= 3
ORDER BY Region, Siralama;
--Neden DENSE_RANK kullandýk? Çünkü "En iyi 3 müþteriyi getir" dediðimizde; 
--eðer 1. ve 2. ayný parayý harcadýysa, bir sonraki kiþiye "Sen 3.sün" demek haksýzlýk olur.
--O kiþi teknik olarak 2. en iyi skoru yapmýþtýr. DENSE_RANK bu hakký korur.

