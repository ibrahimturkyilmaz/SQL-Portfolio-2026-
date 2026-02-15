--(Siparis Oluþtur, Stok Dus, Fiyat Guncelle)
/*Senaryo:
E-Ticaret sitesinde "Satýn Al" butonuna bastýðýnda arka planda iki iþlem olur:
Sipariþ Fiþi Kesilir (ORDERS tablosuna kayýt): "Ahmet Bey, bugün, toplam 500 TL sipariþ verdi."
Sepet Detayý Eklenir (ORDERDETAILS tablosuna kayýt): "Bu sipariþin içinde 1 Telefon, 2 Kýlýf var."
Kritik Risk (Atomicity Ýlkesi):
Elektrik kesildi veya sunucu hata verdi. Sipariþ fiþi oluþtu (ORDERS) ama detaylarý (ORDERDETAILS) yazýlamadý.
Sonuç: Veritabanýnda "Boþ" bir sipariþ oluþur. Depo ne göndereceðini bilemez, muhasebe karýþýr. Bu bir felakettir.
Çözüm: Transaction (Ýþlem Bütünlüðü).
Ya HEPSÝ gerçekleþir ya da HÝÇBÝRÝ. Hata olursa zamaný geri saracaðýz (ROLLBACK).*/
CREATE PROCEDURE sp_SiparisVer
(
    @MusteriID INT,
    @UrunID INT,
    @Adet INT
)
AS
BEGIN
    -- Hata yakalama bloðu baþlat
    BEGIN TRY
        
        -- 1. Ýþlemi Baþlat (Zamaný durduruyoruz gibi düþün)
        BEGIN TRANSACTION;

        -- Deðiþken Tanýmlarý
        DECLARE @YeniSiparisID INT;
        DECLARE @BirimFiyat DECIMAL(18,2);
        DECLARE @ToplamTutar DECIMAL(18,2);

        -- 2. Ürünün Fiyatýný Bul (ITEMS tablosundan)
        -- (Gerçek hayatta buraya PRICE kolonunu yazmalýsýn, yoksa simüle et)
        SELECT @BirimFiyat = UNITPRICE FROM dbo.ITEMS WHERE ID = @UrunID; 
        -- Not: ITEMS tablosunda Fiyat kolonu varsa '100' yerine o kolonu yaz.

        SET @ToplamTutar = @BirimFiyat * @Adet;

        -- 3. ORDERS Tablosuna Kayýt At (Baþlýk)
        INSERT INTO dbo.ORDERS (USERID, DATE_, TOTALPRICE, STATUS_)
        VALUES (@MusteriID, GETDATE(), @ToplamTutar, 1); -- 1: Onaylandý

        -- 4. Oluþan Sipariþin ID'sini Yakala (Çok Kritik!)
        SET @YeniSiparisID = SCOPE_IDENTITY();

        -- 5. ORDERDETAILS Tablosuna Kayýt At (Detay)
        INSERT INTO dbo.ORDERDETAILS (ORDERID, ITEMID, AMOUNT, UNITPRICE, LINETOTAL)
        VALUES (@YeniSiparisID, @UrunID, @Adet, @BirimFiyat, @ToplamTutar);

        -- 6. Her þey yolunda gittiyse ONAYLA ve kaydet
        COMMIT TRANSACTION;
        
        PRINT 'Sipariþ Baþarýyla Oluþturuldu! Sipariþ No: ' + CAST(@YeniSiparisID AS NVARCHAR(20));

    END TRY
    BEGIN CATCH
        -- Hata olursa BURAYA düþer
        -- 7. Zamaný Geri Sar (Yapýlan tüm INSERT'leri iptal et)
        ROLLBACK TRANSACTION;
        
        PRINT 'HATA OLUÞTU! Ýþlem Ýptal Edildi.';
        PRINT ERROR_MESSAGE();
    END CATCH
END
/*Kodun içinde SCOPE_IDENTITY() diye bir komut kullandýk. 
Bu, "Az önce INSERT ettiðim satýrýn otomatik ID'si kaç oldu?" sorusunun cevabýdýr. 
Sipariþ Detayýný (ORDERDETAILS) eklerken bu ID'ye ihtiyacýmýz olduðu için bu komut hayati önem taþýr.*/
EXEC sp_SiparisVer @MusteriID = 1, @UrunID = 5, @Adet = 2;

/*stok düþme
Senaryo:
Depo sorumlusu baðýrýyor: "Sistemde 10 tane görünüyor ama rafta yok! Kim sattý bunu?"
Bizim görevimiz, sipariþ onaylandýðý an stoktan o adedi düþmek. Ayrýca Stok Yetersizse satýþý engellemek.
Kritik Kontrol:
Eðer müþteri 5 tane istiyor ama stokta 3 tane varsa, iþlem iptal edilmeli ve kullanýcýya "Yetersiz Stok" hatasý fýrlatýlmalý.*/
CREATE PROCEDURE sp_StokDus
(
    @UrunID INT,
    @Adet INT
)
AS
BEGIN
    DECLARE @MevcutStok INT;

    -- 1. Önce ürünün güncel stoðunu öðrenelim
    SELECT @MevcutStok = STOCKAMOUNT FROM dbo.ITEMS WHERE ID = @UrunID;

    -- 2. Kontrol Et: Yeterli stok var mý?
    IF @MevcutStok < @Adet
    BEGIN
        -- HATA FIRLAT! (Ýþlemi durdurur, kýrmýzý mesaj verir)
        RAISERROR('HATA: Yetersiz Stok! Satýþ yapýlamaz.', 16, 1);
        RETURN; -- Kodun geri kalanýný çalýþtýrma, çýk.
    END

    -- 3. Eðer stok yetiyorsa, düþüþ yap (UPDATE)
    UPDATE dbo.ITEMS
    SET STOCKAMOUNT = STOCKAMOUNT - @Adet
    WHERE ID = @UrunID;

    PRINT 'Stok baþarýyla güncellendi. Kalan Stok: ' + CAST((@MevcutStok - @Adet) AS NVARCHAR(20));
END
--stok sutunu ITEMS tablosunda yok
-- 1. Tabloya yeni sütun ekle
ALTER TABLE dbo.ITEMS 
ADD STOCKAMOUNT INT;

-- 2. "NULL" stokla çalýþamayýz, hepsine baþlangýç stoðu (100) verelim
UPDATE dbo.ITEMS 
SET STOCKAMOUNT = 100;

-- Kontrol edelim: Sütun geldi mi?
SELECT TOP 5 ID, ITEMNAME, STOCKAMOUNT FROM dbo.ITEMS;

EXEC sp_StokDus @UrunID = 1, @Adet = 1;
EXEC sp_StokDus @UrunID = 1, @Adet = 1000000;

/*Senaryo:
Belirli bir kategorideki (CATEGORY1) veya markadaki (BRAND) ürünlerin fiyatýný, verilen oranda düþüren bir prosedür yazacaðýz.
Güvenlik Uyarýsý:
UPDATE komutu geri alýnamaz (COMMIT olursa). Yanlýþlýkla tüm ürünleri 1 TL yaparsan þirket batar.
O yüzden prosedürün içine "Kaç ürün etkilendi?" bilgisini veren bir sayaç koyacaðýz.*/

create procedure sp_KategoriIndirim
   (
   @KategoriAdi nvarchar(50),
   @IndirimOrani decimal(4,2)
   )
as begin 
        declare @EtkilenenSayi int
        select @EtkilenenSayi = COUNT(*) from dbo.ITEMS where CATEGORY1 = @KategoriAdi

        if @EtkilenenSayi = 0 
        begin 
            print 'UYARI: ÜRÜN YOK' 
            return
        end

        update dbo.ITEMS 
        set UNITPRICE = UNITPRICE - (UNITPRICE * @IndirimOrani) where CATEGORY1= @KategoriAdi

        print 'islem oldu. ' + @KategoriAdi + ' kategorisindeki' + CAST(@EtkilenenSayi AS NVARCHAR(10)) + ' adet ürüne %' 
          + CAST(@IndirimOrani * 100 AS NVARCHAR(10)) + ' indirim yapýldý.';
END

SELECT TOP 5 ITEMNAME, UNITPRICE FROM dbo.ITEMS WHERE CATEGORY1 = 'OYUNCAK';

EXEC sp_KategoriIndirim @KategoriAdi = 'OYUNCAK', @IndirimOrani = 0.10;
SELECT TOP 5 ITEMNAME, UNITPRICE FROM dbo.ITEMS WHERE CATEGORY1 = 'OYUNCAK';
EXEC sp_KategoriIndirim 'OYUNCAK', 0.15;
/*
Senaryo:
Kargo firmasý API'den bize bilgi gönderdi: "12345 nolu sipariþ müþteriye teslim edildi."
Bizim bu bilgiyi alýp veritabanýna iþlememiz lazým. Ancak sadece statüyü deðiþtirmek yetmez; ne zaman teslim edildiðini de kaydetmeliyiz ki 
Lojistik Performansýný (Seviye 2'deki fonksiyonlarla) ölçebilelim.*/
-- Eðer sütun yoksa ekle
IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = 'DELIVERYDATE' AND Object_ID = Object_ID('dbo.ORDERS'))
BEGIN
    ALTER TABLE dbo.ORDERS ADD DELIVERYDATE DATETIME;
END

CREATE PROCEDURE sp_SiparisTeslimEt
(
    @SiparisID INT
)
AS
BEGIN
    DECLARE @EskiStatu TINYINT;

    -- 1. Önce sipariþ var mý kontrol et
    SELECT @EskiStatu = STATUS_ FROM dbo.ORDERS WHERE ID = @SiparisID;

    IF @EskiStatu IS NULL
    BEGIN
        PRINT 'HATA: Sipariþ bulunamadý!';
        RETURN;
    END

    -- 2. Zaten teslim edildiyse iþlem yapma (Mükerrer Kayýt Önleme)
    IF @EskiStatu = 4 
    BEGIN
        PRINT 'UYARI: Bu sipariþ zaten teslim edilmiþ.';
        RETURN;
    END

    -- 3. Güncelleme (UPDATE)
    UPDATE dbo.ORDERS
    SET STATUS_ = 4,              -- 4: Teslim Edildi Kodu
        DELIVERYDATE = GETDATE() -- O anýn tarihi ve saati
    WHERE ID = @SiparisID;

    PRINT 'Sipariþ baþarýyla teslim edildi. Statü: 4, Tarih: ' + CONVERT(VARCHAR, GETDATE(), 120);
END
EXEC sp_SiparisTeslimEt @SiparisID = 10;
SELECT ID, DATE_, DELIVERYDATE, STATUS_ FROM dbo.ORDERS WHERE ID = 10;