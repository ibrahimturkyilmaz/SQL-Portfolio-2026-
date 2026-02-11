/*Elimizde rastgele oluþturulan plakalardan oluþan bir araç
veritabaný var. Bu araç veritabanýný kullanarak içine araç
markasý, ve trafiðe çýkýþ tarihi baþlangýç ve bitiþ
parametrelerini alarak sonuç döndüren stored
procedure'ü yazýnýz.*/

 LAB_PLATES
ALTER proc SP_CarInfo
@brand as varchar(20) = 'BRAND',
@begdate as DATE= null,
@enddate as DATE= null
as
BEGIN
    IF @begdate IS NULL
    BEGIN
        SELECT TOP 1 @begdate = LICENCEDATE FROM LAB_PLATES ORDER BY LICENCEDATE ASC
    END
    IF @enddate IS NULL
    BEGIN
        SET @enddate = GETDATE();
    END
select * from LAB_PLATES 
where BRAND = @BRAND and LICENCEDATE between @begdate and @enddate END

SP_CarInfo 'Audi', '20150101','20181212'

-- Sadece Marka ve Baþlangýç tarihini gönderiyoruz
EXEC SP_CarInfo @brand = 'Audi', @begdate = '20150101'

-- Marka Audi, Baþlangýç Tarihi NULL (prosedür en eskiyi bulacak), Bitiþ Tarihi NULL (prosedür bugünü alacak)
EXEC SP_CarInfo 'Audi', NULL, NULL
/*
Elimizde rastgele oluþturulan plakalardan oluþan bir araç
veritabaný var. Bu araç veritabanýný kullanarak içine araç
markasý,trafiðe çýkýþ tarihi baþlangýç-bitiþ parametreleri
ile bölgeleri liste olarak göndereceðimiz ve her bir
þehirde kiþi baþýna düþen araç sayýsýný hem toplam araç
bazýnda hem de marka bazýnda getirecek stored
procedure'ü yazýnýz.*/

select top 5* from lab_plates
select top 5* from lab_cýtýes


alter proc SP_Sehir_Arac_Info
@brand as varchar(100) ='%',
@begdate as date = null,
@enddate as date = null,
@region as varchar(100) = '%'
as
BEGIN
    IF @begdate IS NULL
    BEGIN
        SELECT TOP 1 @begdate = LICENCEDATE FROM LAB_PLATES ORDER BY LICENCEDATE ASC
    END
    IF @enddate IS NULL
    BEGIN
        SET @enddate = GETDATE();
    END
select  
        c.ID, c.CITYNAME as sehir, c.POPULATION as nufus, c.REGION as bolge, 
        count(p.PLATE) as arabasayisi,
        count(p.PLATE) / (c.POPULATION*1.0) as kisibasi_araba
from lab_cýtýes c
        join lab_plates p on p.CITYNR =c.ID
WHERE 
        (p.BRAND LIKE @brand) AND
        (p.LICENCEDATE BETWEEN @begdate AND @enddate) AND
        c.REGION in (select value from string_split(@region,','))

GROUP BY c.ID, c.CITYNAME, c.POPULATION, c.REGION end


SP_Sehir_Arac_Info

EXEC SP_Sehir_Arac_Info @region = 'EGE'

EXEC SP_Sehir_Arac_Info @brand = 'BMW', @region = 'EGE,MARMARA', @begdate = '2010-01-01'


/*
Elimizde satýþlarýn olduðu bir veritabaný var.
Bu veritabanýnda içine baþlangýç ve bitiþ tarihlerini ve
birden fazla seçilen þehir isimlerini alan ve buna göre
satýþlarý çeken bir stored procedure yazýnýz.
Bu procedure iki dataset döndürmelidir. Birincisi girilen
filtrelerin ne olduðunu gösteren dataset, ikincisi ise bu
filtrelere göre gelen sorgu sonucudur.*/

alter PROC SP_SALES
@BEGDATE AS DATE,
@ENDDATE AS DATE,
@CITIES AS VARCHAR(200)
AS
DECLARE @RESULT AS VARCHAR(1000)
SET @RESULT ='BEGDATE:'+CONVERT(varchar,@BEGDATE,104)
SET @RESULT =@RESULT+CHAR(13)
SET @RESULT =@RESULT+'ENDDATE:'+CONVERT(varchar,@ENDDATE,104)
SET @RESULT =@RESULT+CHAR(13)
SET @RESULT =@RESULT+'CITIES:'+@CITIES
select @RESULT as parameters
SELECT
CATEGORY1 CATEGORY,SUM(TOTALPRICE) TOTALSALE
FROM LAB_SALES
WHERE DATE_ BETWEEN @BEGDATE AND @ENDDATE
AND CITY IN (SELECT VALUE FROM string_split(@CITIES,','))
group by CATEGORY1
order by 2  desc

EXEC SP_SALES @BEGDATE='20190501',@ENDDATE='20190601',
@CITIES='ÝSTANBUL,BURSA,ÝZMÝR'


