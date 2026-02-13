/*Hedef: CEO ve Pazarlama ekibi her bir müþterinin 
"Toplam Harcamasýný", 
"Toplam Sipariþ Adedini" ve 
"Son Görülme Tarihini" tek bir satýrda görmek istiyor*/

--Adý, þehri,toplam harcamasý ve son sipariþ tarihi tek satýrda olmalý.
/*
users namesurname-telnr1, CITIES CITYID, towns TOWN-cýtyýd, address addresstext,userýd, 
orders DATE_,totalprýce userýd-addressýd, ýnvoýces cargofýcheno,totalprýce, orderýd -addressýd, ýnvoýcedetaýls, 
*/
CREATE VIEW SP_CUSTOMER_360 as
select u.NAMESURNAME, sum(p.PAYMENTTOTAL) as toplam_harcama, 
u.TELNR1, a.ADDRESSTEXT, 
MAX(o.DATE_) as son_tarih
from USERS u 
join ADDRESS a on a.USERID = u.ID
join ORDERS o on o.USERID = u.ID
join PAYMENTS p on p.ORDERID = o.ID
group by u.NAMESURNAME, u.TELNR1, a.ADDRESSTEXT

select top 10 * from SP_CUSTOMER_360

--Hedef: Hangi ürünlerin "Yýldýz", hangilerinin "Yük" olduðunu tek bakýþta görmek istiyoruz.
---ORDERDETAILS ITEMID-AMOUNT-LINETOTAL
--ýtems ITEMNAME-BRAND-CATEGORY1,
SELECT I.ITEMNAME, I.BRAND, I.CATEGORY1,
SUM(O.LINETOTAL) AS TOPLAM_CIRO,
SUM(AMOUNT) AS TOPLAM_ADET,
COUNT(O.ORDERID) AS SIPARIS_SIKLIGI,
SUM(O.LINETOTAL) / SUM(O.AMOUNT) AS Ortalama_Satis_Fiyati

FROM ITEMS I 
JOIN ORDERDETAILS O ON O.ITEMID = I.ID
GROUP BY
    I.ITEMNAME, I.BRAND, I.CATEGORY1

/*Senaryo:
Kargo firmasýyla pazarlýk yapacaðýz.
Patron soruyor: "En çok kargoyu nereye gönderiyoruz? Ýstanbul mu, Ankara mý? Ve hangi þehir daha çok para harcýyor?"*/
cýtýes cýty, address addresstext, users ýd-address, orders userýd

create view VW_Sehir_Performans as
SELECT 
    C.CITY AS Sehir_Adi, -- CITIES tablosundaki þehir adý kolonu
    
    COUNT(DISTINCT O.ID) AS Toplam_Siparis, -- Tekil sipariþ sayýsý
    
    COUNT(DISTINCT U.ID) AS Tekil_Musteri_Sayisi, -- Kaç farklý kiþi sipariþ vermiþ?
    
    SUM(O.TOTALPRICE) AS Toplam_Ciro -- ORDERS tablosundaki toplam tutar (LINETOTAL toplamý veya TOTALPRICE)
from CITIES c
join ADDRESS a on a.CITYID  = c.ID
join USERS u on a.USERID = u.ID
join ORDERS o on o.USERID = u.ID
GROUP BY 
    C.CITY

/*Yönetici Hedefi:
Sadece "Hangi kategori ne kadar sattý?" deðil,
"Marka Gücü"nü de görmek istiyoruz. Yani "Elektronik kategorisinde Samsung mu taþýyor, Apple mý?" 
sorusunun cevabýný veren bir View yazacaðýz.*/

CREATE VIEW VW_CategoryBrandAnalysis AS
SELECT
    I.CATEGORY1 AS Kategori, -- Ana Kategori (Örn: Giyim)
    
    I.BRAND AS Marka, -- Marka (Örn: Nike)
    
    COUNT(DISTINCT OD.ID) AS Satis_Islem_Sayisi, -- Kaç kez kasadan geçti?
    
    SUM(OD.AMOUNT) AS Toplam_Urun_Adedi, -- Toplam kaç adet satýldý?
    
    SUM(OD.LINETOTAL) AS Toplam_Ciro, -- Kasaya giren para
    
    -- YÖNETÝCÝ BONUSU: Ortalama Ürün Fiyatý (Pahalý mý satýyoruz, sürümden mi kazanýyoruz?)
    SUM(OD.LINETOTAL) / NULLIF(SUM(OD.AMOUNT), 0) AS Ortalama_Fiyat

FROM
    dbo.ITEMS I
INNER JOIN
    dbo.ORDERDETAILS OD ON OD.ITEMID = I.ID -- Ürünleri Satýþlara Baðla
GROUP BY
    I.CATEGORY1, -- Önce Kategoriye göre grupla
    I.BRAND      -- Sonra Markaya göre kýrýlým yap
select * from VW_CategoryBrandAnalysis order by 4 desc