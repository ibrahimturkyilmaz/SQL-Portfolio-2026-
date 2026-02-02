SELECT * FROM [dbo].[Superstore Dataset]
WHERE Sales <= 0          -- Bedava veya eksi fiyatlı satış var mı?
   OR Quantity <= 0       -- 0 veya eksi adet var mı?
   OR Customer_Name IS NULL; -- İsmi olmayan hayalet müşteri var mı?
  
  --Müşteri Segmentasyonu (Etiketleme)

--Şampiyonlar (Champions): Hem en son gelen (R=5) hem çok sık alan (F=5).
--Riskli Grup (At Risk / Can't Lose): Eskiden çok sık alırdı (F=5) ama uzun süredir yok (R=1 veya 2). (Alarm Çanları!) 🚨
--Yeni Gelenler (New Customers): Yeni gelmiş (R=5) ama henüz siftahı var (F=1).
--Uykudakiler (Hibernating): Hem gelmiyor (R=1) hem de az almış (F=1).

        --Müşteri Karnesi
   ;WITH RFM_Hesap AS (
    -- 1. ADIM: Ham Veri (Recency, Frequency, Monetary)
    SELECT 
        Customer_Name,
        DATEDIFF(day, MAX(Order_Date), '2019-01-01') AS Recency_Degeri, -- 2020 Referans Tarihi
        COUNT(DISTINCT Order_ID) AS Frequency_Degeri, --aynı siparişte 5  ürün alsa bile bunu "1 ziyaret" sayıyoruz
        SUM(Sales) AS Monetary_Degeri
    FROM [dbo].[Superstore Dataset]
    GROUP BY Customer_Name
),
RFM_Puanlama AS (
    -- 2. ADIM: 1-5 Arası Puanlama (NTILE)
    SELECT 
        Customer_Name,
        Recency_Degeri, Frequency_Degeri, Monetary_Degeri,
        NTILE(5) OVER (ORDER BY Recency_Degeri DESC) AS R_Skor, -- Az gün = Yüksek Puan
        NTILE(5) OVER (ORDER BY Frequency_Degeri ASC) AS F_Skor, -- Çok İşlem = Yüksek Puan
        NTILE(5) OVER (ORDER BY Monetary_Degeri ASC) AS M_Skor  -- Çok Para = Yüksek Puan
    FROM RFM_Hesap
)
-- 3. ADIM: SEGMENTASYON (ETİKETLEME)
SELECT 
    Customer_Name,
    R_Skor, F_Skor, M_Skor,
    -- Skorları birleştirip tek bir string yapalım (Örn: "555")
    CONCAT(R_Skor, F_Skor, M_Skor) AS RFM_Skoru,
    
    -- SEGMENT MANTIĞI (CASE WHEN)
    CASE 
        WHEN R_Skor = 5 AND F_Skor = 5 THEN 'Şampiyon (Champions)'
        WHEN R_Skor <= 2 AND F_Skor = 5 THEN 'Riskli / Kayıp (Cant Lose)' -- Eskiden iyiydi, şimdi yok
        WHEN R_Skor = 5 AND F_Skor = 1 THEN 'Yeni Gelen (New Customer)'
        WHEN R_Skor <= 2 AND F_Skor <= 2 THEN 'Uykuda (Hibernating)'
        ELSE 'Sadık / Standart (Loyal)' -- Diğer kombinasyonlar
    END AS Musteri_Segmenti

FROM RFM_Puanlama
ORDER BY R_Skor DESC, F_Skor DESC;

--"Sürekli yeni müşteri getiriyoruz diye seviniyorsunuz ama arka kapıdan kaçanları görmüyoruz!
--Ocak ayında gelen müşterilerin kaçı Şubat'ta tekrar geldi? Kaçını 3 ay sonra kaybettik? 
--Bana Müşteri Sadakatini kanıtlayın."
--Zaman Yolculuğu

SELECT 
        Customer_Name,
        Min(Order_Date) AS Ilk_Tarih,
        max(Order_Date) AS son_Tarih,        datediff (MONTH, Min(Order_Date),max(Order_Date) )
    from [dbo].[Superstore Dataset]
    GROUP BY Customer_Name

    select product_name from [dbo].[Superstore Dataset]

--online-retail-ii veri setine geçilir. seviye 2 görevleri oradan devam eder.