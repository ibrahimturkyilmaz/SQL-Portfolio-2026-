[dbo].[insurance]


--Sigara içen birinin (smoker='yes') şirkete maliyeti, içmeyene göre ortalama kaç dolar daha fazla?
--sigara durumuna göre AVG(charges) hesapla.
SELECT
    CASE 
        WHEN smoker = 1 THEN 'Evet (Sigara Iciyor)' 
        WHEN smoker = 0 THEN 'Hayir (icmiyor)' 
        ELSE 'Bilinmiyor' 
    END AS Sigara_Durumu,
    COUNT(*) AS Kisi_Sayisi,
    AVG(charges) AS Ortalama_Maliyet_Skoru, 
    -- En düşük ve En yüksek faturalar
    MIN(charges) AS En_Dusuk,
    MAX(charges) AS En_Yuksek
FROM
    [dbo].[insurance]
GROUP BY
    smoker;

--"Kilolu müşteriler şirkete ne kadar yük oluyor?" 
--BMI değerlerini standart kategorilere (Zayıf, Normal, Kilolu, Obez) çevirip maliyetleri kiyaslayacağiz.
--Zayıf: < 18.5
--Normal: 18.5 - 24.9
--Kilolu: 25 - 29.9
--Obez: > 30


SELECT
    -- 1. ADIM: Önce veriyi temizleyip BMI Kategorisini belirliyoruz
    CASE 
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) < 18.5 THEN '1. Zayif (<18.5)'
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) BETWEEN 18.5 AND 24.9 THEN '2. Normal'
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) BETWEEN 25 AND 29.9 THEN '3. Kilolu'
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) >= 30 THEN '4. Obez (Riskli)'
        ELSE 'Bilinmiyor'
    END AS BMI_Kategorisi,

-- 2. ADIM: İstatistikler
    COUNT(*) AS Kisi_Sayisi,
   AVG(charges) AS Ortalama_Maliyet,
   MIN(charges) AS En_Dusuk,
   MAX(charges) AS En_Yuksek
   FROM
    [dbo].[insurance]
GROUP BY
    CASE 
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) < 18.5 THEN '1. Zayif (<18.5)'
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) BETWEEN 18.5 AND 24.9 THEN '2. Normal'
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) BETWEEN 25 AND 29.9 THEN '3. Kilolu'
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) >= 30 THEN '4. Obez (Riskli)'
        ELSE 'Bilinmiyor'
    END
ORDER BY
    BMI_Kategorisi;

--Bölgesel Risk Haritası
--Senaryo: Hangi bölgede (region) sağlik harcamalari daha yüksek?
--bölgelere göre ortalama maliyet ve toplam müşteri sayisini dök.

select region , count(*) as kişi_sayisi, 
        avg(charges) as ortalama_maliyet
from [dbo].[insurance]
group by region order by ortalama_maliyet desc


--Sigara + Obezite + Bölge
SELECT 
    region AS Bolge,
    
    -- Sigara Durumu (0/1 verisine göre)
    CASE WHEN smoker = 1 THEN ' İciyor' ELSE 'Temiz' END AS Sigara_Durumu,
    
    -- Obezite Durumu (Akıllı BMI düzeltmesi ile)
    CASE 
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) >= 30 
        THEN ' Obez' 
        ELSE ' Normal/Zayıf' 
    END AS Obezite_Durumu,
    
    COUNT(*) AS Kisi_Sayisi,
    FORMAT(AVG(charges), '#,0') AS Ortalama_Maliyet
FROM 
    [dbo].[insurance]
GROUP BY 
    region,
    smoker,
    CASE 
        WHEN (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) >= 30 
        THEN ' Obez' 
        ELSE ' Normal/Zayıf' 
    END
ORDER BY 
    Bolge, Ortalama_Maliyet DESC;



--Çocuk sayısı (children) arttıkça sağlik harcamasi artiyor mu? Mantiken: "Daha çok çocuk = Daha çok doktor ziyareti" demektir.
--Ama acaba 5 çocuklu bir aile, 1 çocuklu aileden tam 5 kat mi maliyetli? Yoksa bir noktadan sonra sabitleniyor mu?

select children as cocuk_sayisi, 
        count(*) as aile_sayisi,
        avg(charges) as ortalama_maliyet
FROM
    [dbo].[insurance]
GROUP BY
    children
ORDER BY
    children ASC;

    --En Riskli Müşteri Profili (Persona)
    ---Şirket için "Kabus Müşteri" kim? Sigara içen + Obez + Yaşlı mı?
--sigara içen ve BMI>30 olanlarin ortalama maliyetini, sigara içmeyen ve BMI<25 olanlarla karşilaştir.
--Analiz Plani: İki uç profili karşilaştiracağiz:
                --Kabus Müşteri : Sigara İçiyor + Obez (BMI > 30) + Yaşlı (> 50)
                --Melek Müşteri: Sigara İçmiyor + Zayıf/Normal (BMI < 25) + Genç (< 30)
SELECT 
    *, 
    CASE 
        -- KABUS PROFİL: Sigara Var, Obez ve 50 Yaş Üstü
        WHEN smoker = 1 
             AND (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) >= 30 
             AND age > 50 THEN '1.  KABUS MUSTERI'
        -- MELEK PROFİL: Sigara Yok, Zayıf/Normal ve 30 Yaş Altı
        WHEN smoker = 0 
             AND (CASE WHEN bmi > 1000 THEN bmi/100.0 WHEN bmi > 100 THEN bmi/10.0 ELSE bmi END) < 25 
             AND age < 30 THEN '2.  MELEK MUSTERI'
        ELSE '3. Diger/Orta Segment' 
    END AS Musteri_Tipi
INTO  #Risk_Segmentleri
FROM [dbo].[insurance];
--
SELECT 
    Musteri_Tipi,
    COUNT(*) AS Kisi_Sayisi,
    FORMAT(AVG(charges), '#,0') AS Ortalama_Maliyet,
    FORMAT(MAX(charges), '#,0') AS En_Yuksek_Fatura
FROM 
    #Risk_Segmentleri
GROUP BY 
    Musteri_Tipi
ORDER BY 
    Ortalama_Maliyet DESC;