/*Senaryo:
Lojistik Müdürümüz her sabah raporda tarihleri (2026-10-01) görüp zihninden hesap yapmaktan yoruldu.
Sistemin otomatik olarak "3 Gün Gecikti" veya "Zamanýnda" diye etiketlemesini istiyor.

SQL Görevi:
ETRADE4 veritabanýnda ORDERS tablosunu kullanacaðýz. 
Elimizde gerçek bir "Teslim Tarihi" kolonu olmadýðý için simülasyon yapacaðýz 
(Sipariþ tarihinden 3 gün sonrasý ideal teslimat olsun).*/
orders siprais verme tarihi - invoices kargo verilme tarihi - 

create function fn_TeslimatDurum
(@SiparisTarihi datetime, @TeslimTarihi datetime)
returns nvarchar(50)
as begin
		declare @Durum nvarchar(50)
		declare @GunFarki int

		set @GunFarki = DATEDIFF(Day, @SiparisTarihi, @TeslimTarihi)

		if @GunFarki <= 3	
						set @Durum = 'zamanda teslim'
		else if @GunFarki between 4 and 7
						set @Durum = 'gecikme'
		else set @Durum = 'kritik'
		return @Durum
End

select top 400 
o.ID sip_no, o.DATE_ sip_tarih, GETDATE() as simule_bugun,
dbo.fn_TeslimatDurum(Date_, GETDATE()) AS lojistik_analizi
from ORDERS o

/*
"Kargo 5 günde gitti diyorsunuz ama araya Cumartesi-Pazar girdi.
Aslýnda operasyon sadece 3 gün sürdü!"
Þirketlerin SLA (Service Level Agreement - Hizmet Seviyesi Anlaþmasý) süreleri hesaplanýrken 
hafta sonlarý, bayramlar sayýlmaz. SQL'in kendi DATEDIFF fonksiyonu "aptaldýr", sadece takvime bakar. 
Biz ona "akýllý" olmayý öðreteceðiz.
Zorluk:
Ýki tarih arasýndaki günleri tek tek kontrol etmeli ve eðer gün "Cumartesi" veya "Pazar" ise sayaca eklememeliyiz.
Bu yüzden bir Döngü (WHILE Loop) kullanacaðýz.*/

create function fn_IsGunuHesap
(
		@baslangictarih as datetime,
		@bitistarihi as datetime
)
returns int
as begin 
	declare @isgunusayisi int = 0
	declare @suankitarih datetime = @baslangictarih

	while @suankitarih <= @bitistarihi
	begin 
		if DATEPART(DW,@suankitarih) not in(1,7)
		begin set @isgunusayisi = @isgunusayisi + 1
		end
		set @suankitarih = DATEADD(day, 1, @suankitarih)
	end
	return @isgunusayisi
end


SELECT  
    ID,
    DATE_ AS SiparisTarihi,
    DATEADD(DAY, 10, DATE_) AS TeslimTarihi_Simulasyon, -- Sipariþten 10 gün sonrasý
    
    -- Standart Hesap 
    DATEDIFF(DAY, DATE_, DATEADD(DAY, 10, DATE_)) AS Normal_Gun_Farki,
    
    -- Bizim Akýllý Hesap (Sadece Hafta Ýçi)
    dbo.fn_IsGunuHesap(DATE_, DATEADD(DAY, 10, DATE_)) AS Is_Gunu_Farki
FROM 
    dbo.ORDERS

/*Senaryo:
Pazarlama Müdürü geldi ve dedi ki: "Bana 10.000 TL üzeri harcayanlarý getir."
Sen bir sorgu yazdýn.
Ertesi gün geldi: "Vazgeçtim, limit 5.000 TL olsun."
Sonraki gün: "Sadece 50.000 TL üzeri harcayan 'Balinalarý' ver."
Her seferinde sorgunun WHERE þartýný deðiþtirmek ameleliktir. 
Bunun yerine "Parametre Alan Bir Tablo" yapacaðýz. Buna Inline Table Valued Function (iTVF) denir.
Mantýk:
Bu fonksiyon, normal bir tablo gibi davranýr ama parantez içinde ona bir sayý 
(Eþik Deðeri) fýrlatýrsýn, o da sana o filtreye uyan tabloyu geri döner.*/

create function fn_VipMusteri
(
	@limit Decimal(18,2) --disaridan girilecek veri
)
returns table
as 
return
	( 
	select 
		u.NAMESURNAME,
		count(o.ID)as toplam_siparis, 
		sum(p.PAYMENTTOTAL) as toplam_harcama
	from USERS u 
	join ORDERS o on o.USERID = u.ID
	join PAYMENTS p on p.ORDERID = o.ID
	group by u.NAMESURNAME
	having sum(p.PAYMENTTOTAL) > @limit
	)

	select * from dbo.fn_VipMusteri(3000) order by toplam_harcama desc

/*Senaryo:
Lojistik Müdürümüz diyor ki: "Her ürün için sabit kargo parasý ödemeyelim.
Pahalý sipariþlerde kargoyu biz ödeyelim (Promosyon), ucuz sipariþlerde müþteri ödesin."
Normalde bu iþ için ürünün "Aðýrlýðýna" (Desi) bakýlýr. 
Ancak ETRADE4 veritabanýnda ITEMS tablosunda aðýrlýk (Weight) sütunu olmayabilir.
Bu yüzden biz daha stratejik bir yöntem kullanacaðýz: Sepet Tutarýna Göre Kargo.

Kural Setimiz:
Düþük Tutar (< 500 TL): Kargo ücreti 29.90 TL (Müþteri öder).
Orta Tutar (500 TL - 2000 TL): Kargo ücreti 14.90 TL (Ýndirimli).
Yüksek Tutar (> 2000 TL): ÜCRETSÝZ KARGO (Þirket öder).*/

create function fn_KargoHesap
	(@siparis_tutar decimal(18,2)) 
returns decimal(18,2)
as begin 
	declare @kargoucret decimal(18,2)
-- Mantýk Kurallarý (Business Logic)
    IF @siparis_tutar < 500
        SET @kargoucret = 29.90; -- Düþük tutarlý sipariþ
    ELSE IF @siparis_tutar BETWEEN 500 AND 2000
        SET @kargoucret = 14.90; -- Ýndirimli
    ELSE
        SET @kargoucret = 0.00;  -- Ücretsiz Kargo (Free Shipping)

    RETURN @kargoucret;
END

select 
o.ID as sip_no,
o.TOTALPRICE as sip_tutari,
dbo.fn_KargoHesap(o.TOTALPRICE) as alinacak_kargo_tutari
from orders o 
ORDER BY 
    O.TOTALPRICE --DESC -- Pahalý sipariþlerde kargonun 0 olduðunu gör

/*
Senaryo:
Veritabanýna veriler farklý kaynaklardan (Web sitesi, Mobil Uygulama, Çaðrý Merkezi) akýyor.
Kimisi ismini "AHMET" yazmýþ, kimisi "ahmet", kimisi "aHmET".
Raporu CEO'ya sunduðunda bu görüntü "amatör" durur.
Bizden istenen: Her kelimenin Baþ harfi Büyük, gerisi küçük olsun (Örn: "Ahmet").

Teknik Zorluk:
Excel'de PROPER() veya YAZIM.DÜZENÝ() fonksiyonu bunu tek týkla yapar.
Ama SQL Server'da (T-SQL) böyle hazýr bir komut YOKTUR. Bunu biz icat edeceðiz!*/


CREATE FUNCTION fn_MetinDuzelt
(
    @Metin NVARCHAR(MAX) -- Düzelecek kirli metin
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    -- Eðer metin boþsa (NULL), direkt NULL döndür, iþlem yapma
    IF @Metin IS NULL RETURN NULL;

    DECLARE @Sonuc NVARCHAR(MAX);

    -- Formül: Ýlk Harf (Büyük) + Geri Kalan (Küçük)
    SET @Sonuc = UPPER(LEFT(@Metin, 1)) + LOWER(SUBSTRING(@Metin, 2, LEN(@Metin)));

    RETURN @Sonuc;
END
select top 500 * from USERS

SELECT TOP 20
    NAMESURNAME AS Kirli_Veri,
    
    -- Fonksiyonu çaðýrýyoruz
    dbo.fn_MetinDuzelt(NAMESURNAME) AS Temiz_Veri,
    
    -- Þehir isimlerini de deneyelim (varsa)
    EMAIL AS Orjinal_Email,
    dbo.fn_MetinDuzelt(EMAIL) AS Hatali_Format_Ornegi -- Email'de baþ harf büyük olmaz ama deneme amaçlý :)
FROM 
    dbo.USERS

