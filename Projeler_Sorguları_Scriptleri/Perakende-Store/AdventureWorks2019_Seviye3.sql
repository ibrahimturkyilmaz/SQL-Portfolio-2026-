-- tüm tablolar incelenecek ve null deðerlere bakýlacak
-- 1. Ürün Maliyet Kontrolü (Görev 3.1 için)
-- StandardCost veya ListPrice'ý 0 veya NULL olan ürün var mý?
SELECT 'Production.Product' AS Tablo, COUNT(*) AS Sorunlu_Kayit_Sayisi
FROM Production.Product
WHERE StandardCost IS NULL OR StandardCost = 0;

-- 2. Ürün Aðacý Kontrolü (Görev 3.3 için)
-- Montaj parçasý olup da (Assembly) alt parçasý olmayan var mý?
SELECT 'Production.BillOfMaterials' AS Tablo, COUNT(*) AS Kayit_Sayisi
FROM Production.BillOfMaterials;

-- 3. Üretim Rotalarý (Görev 3.4 için)
-- Planlanan maliyeti (PlannedCost) olmayan rota var mý?
SELECT 'Production.WorkOrderRouting' AS Tablo, COUNT(*) AS Sorunlu_Kayit_Sayisi
FROM Production.WorkOrderRouting
WHERE PlannedCost IS NULL;

-- 4. Tedarikçi Sipariþleri (Görev 3.2 için)
-- Sipariþ verilmiþ ama tedarikçi ID'si olmayan hayalet kayýt var mý?
SELECT 'Purchasing.PurchaseOrderHeader' AS Tablo, COUNT(*) AS Sorunlu_Kayit_Sayisi
FROM Purchasing.PurchaseOrderHeader
WHERE VendorID IS NULL;


--"Binlerce çeþit bisiklet parçamýz var (vida, pedal, zincir...). 
--Ama kasaya giren paranýn aslan payýný hangileri getiriyor? Bana Cironun %70'ini sýrtlayan 'A Kalite' ürünleri ver, 
--onlarý çelik kasada saklayalým.
--Geri kalan 'C sýnýfý' vidalarý dýþarýda býraksak da olur."

--tablo 1, Sales.SalesOrderDetail Her Ürünün Cirosunu Bul

SELECT 
    P.ProductID,
    P.Name AS Urun_Adi,
    P.ProductNumber,
    SUM(SOD.LineTotal) AS Toplam_Ciro
INTO #Urun_Ciro
FROM Sales.SalesOrderDetail SOD
JOIN Production.Product P ON SOD.ProductID = P.ProductID
GROUP BY P.ProductID, P.Name, P.ProductNumber;

--Kümülatif Hesap ve Etiketleme
--A Sýnýfý: Cironun ilk %70'ini oluþturanlar (Kritik Stok).
--B Sýnýfý: %70 - %90 arasý (Orta Önem).
--C Sýnýfý: Geriye kalan son %10 (Düþük Önem).

SELECT 
    ProductID,
    Urun_Adi,
    Toplam_Ciro,
    -- Birikimli Ciro (En yüksekten en düþüðe toplayarak git)
    SUM(Toplam_Ciro) OVER (ORDER BY Toplam_Ciro DESC) AS Kumulatif_Ciro,

    -- 2. Genel Toplam (Tüm tablonun toplamý)
    -- Dikkat: Ýçi boþ OVER() tüm tabloyu kapsar
    SUM(Toplam_Ciro) OVER () AS Genel_Toplam_Ciro,
    
    -- 3. Yüzde Hesabý (Birikimli / Genel Toplam)
    (SUM(Toplam_Ciro) OVER (ORDER BY Toplam_Ciro DESC) * 1.0 / SUM(Toplam_Ciro) OVER ()) * 100 AS Kumulatif_Yuzde
INTO #ABC_Hesap
FROM #Urun_Ciro;

--OVER, gruplamadan hesap yapmaný saðlar.Her satýrýn yanýna "sanal bir pencere" açar ve oraya sonucu yazar. Satýr sayýsý AYNI KALIR.
--Senaryo: "Her satýþýn yanýna, o kategorinin toplamýný da yaz (ki oranlayabileyim)."
--Sonuç: 1000 satýr aynen kalýr, yanýna yeni bir sütun eklenir.
SELECT 
    ProductID,
    Toplam_Ciro AS Ciro,
    CAST(Kumulatif_Yuzde AS decimal(10,2)) AS Birikimli_Yuzde,
    -- ABC SINIFLANDIRMASI (Yol Haritasý Kuralý)
    CASE 
        WHEN Kumulatif_Yuzde <= 70 THEN 'A Sýnýfý (Kritik)'
        WHEN Kumulatif_Yuzde <= 90 THEN 'B Sýnýfý (Önemli)'
        ELSE 'C Sýnýfý (Standart)'
    END AS ABC_Sinifi
FROM #ABC_Hesap
ORDER BY Toplam_Ciro DESC;

--Tedarikçi Performans Deðerlendirme
--"Hangi tedarikçi bizi yarý yolda býrakýyor? 
--Malý zamanýnda getirmeyen veya sürekli bozuk mal (hurda) gönderen tedarikçileri tespit et. Onlarla sözleþmeyi feshedeceðiz."

--Analiz Kriterleri
--Zamanlama (On-Time): Termin süresine uyuyorlar mý? (DueDate vs ShipDate) .
--Kalite (Quality): Ne kadar bozuk mal geldi? (RejectedQty) .
--Hacim (Volume): Toplam ne kadarlýk iþ yapýyoruz? (Büyük tedarikçi mi, küçük mü?).

-- 1. sipariþ tarihleri hakkýnda

    SELECT 
        H.VendorID,
        V.Name AS Tedarikci_Adi,
        
        -- DÜZELTME BURADA: DueDate'i "D" (Detail) tablosundan çekiyoruz
        -- Mantýk: DueDate (Termin) - ShipDate (Gerçekleþen Kargo)
        -- Sonuç Pozitifse: Erken/Zamanýnda. Negatifse: Geç.
        AVG(DATEDIFF(day, H.ShipDate, D.DueDate)) AS Ortalama_Termin_Sapmasi,
        
        COUNT(DISTINCT H.PurchaseOrderID) AS Siparis_Sayisi,
        SUM(H.TotalDue) AS Toplam_Satin_Alma,
        
        SUM(D.OrderQty) AS Toplam_Urun_Adedi,
        SUM(D.RejectedQty) AS Toplam_Reddedilen_Adet,
        
        -- Hata Oraný
        (CAST(SUM(D.RejectedQty) AS FLOAT) / NULLIF(SUM(D.OrderQty), 0)) * 100 AS Hata_Orani_Yuzde
    into #Tedarikci_Performans
    FROM Purchasing.PurchaseOrderHeader H
    -- DueDate ve RejectedQty için DETAY tablosuna baðlanýyoruz:
    JOIN Purchasing.PurchaseOrderDetail D ON H.PurchaseOrderID = D.PurchaseOrderID
    JOIN Purchasing.Vendor V ON H.VendorID = V.BusinessEntityID
    
    WHERE H.Status = 4 -- Sadece tamamlanmýþ sipariþler
    GROUP BY H.VendorID, V.Name
  
  SELECT  
    Tedarikci_Adi,
    Siparis_Sayisi,
    FORMAT(Toplam_Satin_Alma, 'N2') AS Toplam_Tutar,
    
    -- Zamanlama Yorumu
    CASE 
        WHEN Ortalama_Termin_Sapmasi < 0 THEN 'GEÇ KALIYOR! '
        WHEN Ortalama_Termin_Sapmasi IS NULL THEN 'Veri Yok'
        ELSE CONCAT(Ortalama_Termin_Sapmasi, ' Gün Erken')
    END AS Zamanlama_Durumu,
    
    -- Kalite Yorumu
    CAST(Hata_Orani_Yuzde AS decimal(10,2)) AS Hata_Orani,
    CASE 
        WHEN Hata_Orani_Yuzde > 0 THEN 'BOZUK MAL! ' 
        ELSE 'Temiz '
    END AS Kalite_Durumu
into  #tedarikçi_performans_yorumu
FROM #Tedarikci_Performans
ORDER BY Hata_Orani_Yuzde DESC;


--"Mountain-200" bisikletini gösterdi: "Þef, bu bisikleti üretmek için depodan hangi parçalarý çekmem lazým? 
--Sadece 'Tekerlek' deme; tekerleðin içindeki jantý, teli, lastiði... Hepsini en alt vidaya kadar (Patlatýlmýþ Görünüm) listele."

-- ÜRÜN AÐACI
--burada ara verdim. görev 3.3



