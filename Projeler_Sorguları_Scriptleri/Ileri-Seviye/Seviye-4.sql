/*Trigger çalýþtýðýnda SQL hafýzasýnda iki sanal tablo oluþur:
deleted Tablosu: Silinen veya deðiþtirilmeden önceki ESKÝ veriyi tutar.
inserted Tablosu: Yeni eklenen veya deðiþtirilen YENÝ veriyi tutar.*/

CREATE TABLE PRICE_LOGS
(
    LOG_ID INT IDENTITY(1,1) PRIMARY KEY, -- Kayýt numarasý
    URUN_ID INT,
    ESKI_FIYAT DECIMAL(18,2),
    YENI_FIYAT DECIMAL(18,2),
    DEGISTIREN_KISI NVARCHAR(50), -- Kim yaptý?
    DEGISIM_TARIHI DATETIME DEFAULT GETDATE()
)

CREATE TRIGGER trg_FiyatTakip
ON dbo.ITEMS
AFTER UPDATE
AS
BEGIN
    -- Sadece Fiyat (PRICE) deðiþtiyse çalýþ, diðer güncellemeleri (stok vs) görmezden gel
    IF UPDATE(UNITPRICE)
    BEGIN
        INSERT INTO dbo.PRICE_LOGS (URUN_ID, ESKI_FIYAT, YENI_FIYAT, DEGISTIREN_KISI, DEGISIM_TARIHI)
        SELECT 
            i.ID, 
            d.UNITPRICE,  -- deleted tablosundaki ESKÝ fiyat
            i.UNITPRICE,  -- inserted tablosundaki YENÝ fiyat
            SYSTEM_USER, -- SQL'e o an baðlý olan kullanýcý (Senin Bilgisayar Adýn)
            GETDATE()
        FROM 
            inserted i
        INNER JOIN 
            deleted d ON i.ID = d.ID
    END
END

UPDATE dbo.ITEMS SET UNITPRICE = 999 WHERE ID = 1;
SELECT * FROM dbo.PRICE_LOGS ORDER BY DEGISIM_TARIHI DESC;


/*Senaryo: Bir ürünün stoðu kritik seviyenin (örneðin 10 adet) altýna düþtüðünde, 
depo sorumlusunun fark etmesini beklemeden sistem otomatik olarak "Satýn Alma Talebi" oluþtursun.
Buna "Reorder Point" (Yeniden Sipariþ Noktasý) otomasyonu denir.*/

CREATE TABLE SATIN_ALMA_TALEPLERI
(
    TALEP_ID INT IDENTITY(1,1) PRIMARY KEY,
    URUN_ID INT,
    TALEP_TARIHI DATETIME DEFAULT GETDATE(),
    DURUM NVARCHAR(20) DEFAULT 'BEKLIYOR', -- Bekliyor, Sipariþ Verildi
    ACIKLAMA NVARCHAR(100)
)
CREATE TRIGGER trg_StokAlarm
ON dbo.ITEMS
AFTER UPDATE
AS
BEGIN
    -- Sadece STOK (STOCKAMOUNT) deðiþtiyse çalýþ
    IF UPDATE(STOCKAMOUNT)
    BEGIN
        DECLARE @YeniStok INT;
        DECLARE @UrunID INT;

        -- Deðiþen veriyi 'inserted' tablosundan al
        SELECT @UrunID = ID, @YeniStok = STOCKAMOUNT FROM inserted;

        -- KRÝTÝK KONTROL: Stok 10'un altýna düþtü mü?
        IF @YeniStok <= 10
        BEGIN
            -- Daha önce bekleyen bir talep yoksa yeni talep aç (Mükerrer kaydý önle)
            IF NOT EXISTS (SELECT * FROM dbo.SATIN_ALMA_TALEPLERI WHERE URUN_ID = @UrunID AND DURUM = 'BEKLIYOR')
            BEGIN
                INSERT INTO dbo.SATIN_ALMA_TALEPLERI (URUN_ID, ACIKLAMA)
                VALUES (@UrunID, 'DÝKKAT! Stok Kritik Seviyede (' + CAST(@YeniStok AS NVARCHAR(10)) + ' adet)');
                
                PRINT 'ALARM: Stok azaldý! Otomatik satýn alma talebi oluþturuldu.';
            END
        END
    END
END

UPDATE dbo.ITEMS SET STOCKAMOUNT = 5 WHERE ID = 1;

SELECT * FROM dbo.SATIN_ALMA_TALEPLERI;




CREATE TABLE CEO_ALERTS
(
    ALERT_ID INT IDENTITY(1,1) PRIMARY KEY,
    SIPARIS_ID INT,
    MUSTERI_ID INT,
    TUTAR DECIMAL(18,2),
    MESAJ NVARCHAR(250),
    OLUSTURMA_TARIHI DATETIME DEFAULT GETDATE()
)

alter TRIGGER trg_YuksekTutar
ON dbo.ORDERS
AFTER INSERT
AS
BEGIN
    DECLARE @YeniTutar DECIMAL(18,2);
    DECLARE @SiparisID INT;
    DECLARE @MusteriID INT;

    -- Yeni eklenen kaydý 'inserted' sanal tablosundan al
    SELECT 
        @SiparisID = ID, 
        @MusteriID = USERID, 
        @YeniTutar = TOTALPRICE 
    FROM inserted;

    -- KONTROL: Tutar 5000 TL'den büyük mü?
    IF @YeniTutar > 5000
    BEGIN
        -- CEO_ALERTS tablosuna kayýt at
        INSERT INTO dbo.CEO_ALERTS (SIPARIS_ID, MUSTERI_ID, TUTAR, MESAJ)
        VALUES (@SiparisID, @MusteriID, @YeniTutar, ' TEBRÝKLER! Yüksek cirolu yeni bir satýþ gerçekleþti.');
        
        PRINT 'ALARM: Yüksek tutarlý sipariþ yakalandý! CEO bilgilendirildi.';
    END
END

-- 7500 TL'lik sahte bir sipariþ oluþturalým
INSERT INTO dbo.ORDERS (USERID, DATE_, TOTALPRICE, STATUS_)
VALUES (1, GETDATE(), 7500, 1);

SELECT * FROM dbo.CEO_ALERTS ORDER BY OLUSTURMA_TARIHI DESC;

--kskt trjj mxef nxad

-- Önce temizlik yapalým (Eðer eski denemeler varsa siler)
IF EXISTS (SELECT * FROM msdb.dbo.sysmail_account WHERE name = 'GmailHesabi')
BEGIN
    EXEC msdb.dbo.sysmail_delete_account_sp @account_name = 'GmailHesabi';
END

IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = 'SirketBildirimProfili')
BEGIN
    EXEC msdb.dbo.sysmail_delete_profile_sp @profile_name = 'SirketBildirimProfili';
END

-- A. HESAP OLUÞTUR (Gmail SMTP Ayarlarý)
-- DÝKKAT: @password kýsmýna Gmail'den aldýðýn 16 haneli kodu yaz!
EXEC msdb.dbo.sysmail_add_account_sp
    @account_name = 'GmailHesabi',
    @email_address = 'ibrahimtrkylmz632@gmail.com',  -- <--- BURAYI DEÐÝÞTÝR
    @display_name = 'SQL Server Robotu',
    @mailserver_name = 'smtp.gmail.com',
    @port = 587,
    @enable_ssl = 1,
    @username = 'ibrahimtrkylmz632@gmail.com',       -- <--- BURAYI DEÐÝÞTÝR
    @password = 'kskt trjj mxef nxad';          -- <--- GMAIL UYGULAMA ÞÝFRESÝ

-- B. PROFÝL OLUÞTUR (Mail atan kimlik)
EXEC msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'SirketBildirimProfili',
    @description = 'Yöneticilere bildirim atmak için kullanýlýr.';

-- C. HESABI PROFÝLE BAÐLA
EXEC msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'SirketBildirimProfili',
    @account_name = 'GmailHesabi',
    @sequence_number = 1;

-- D. TEST MAÝLÝ AT (Çalýþýyor mu?)
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'SirketBildirimProfili',
    @recipients = 'ibrahimtrkylmz632@gmail.com', -- Kendi mailine gönder
    @subject = 'SQL Test Mesajý',
    @body = 'Merhaba, bu mesaj SQL Server üzerinden baþarýyla gönderildi! ';

    ALTER TRIGGER trg_YuksekTutar
ON dbo.ORDERS
AFTER INSERT
AS
BEGIN
    -- Deðiþkenler
    DECLARE @YeniTutar DECIMAL(18,2);
    DECLARE @SiparisID INT;
    DECLARE @MusteriID INT;
    DECLARE @MailIcerigi NVARCHAR(MAX); -- HTML formatýnda mail metni

    -- Yeni eklenen veriyi al
    SELECT @SiparisID = ID, @MusteriID = USERID, @YeniTutar = TOTALPRICE 
    FROM inserted;

    -- KONTROL: Tutar 5000 TL'den büyük mü?
    IF @YeniTutar > 5000
    BEGIN
        -- 1. Tabloya Log At (Yedekleme)
        INSERT INTO dbo.CEO_ALERTS (SIPARIS_ID, MUSTERI_ID, TUTAR, MESAJ)
        VALUES (@SiparisID, @MusteriID, @YeniTutar, 'Mail Gönderildi.');

        -- 2. Mail Ýçeriðini HTML Olarak Hazýrla
        SET @MailIcerigi = '
            <html>
            <body>
                <h2 style="color:green;"> Yeni Bir Yüksek Satýþ!</h2>
                <p>Sayýn Yönetici, az önce sistemde büyük bir iþlem gerçekleþti.</p>
                <table border="1">
                    <tr><td><b>Sipariþ No</b></td><td>' + CAST(@SiparisID AS NVARCHAR) + '</td></tr>
                    <tr><td><b>Müþteri ID</b></td><td>' + CAST(@MusteriID AS NVARCHAR) + '</td></tr>
                    <tr><td><b>Tutar</b></td><td>' + CAST(@YeniTutar AS NVARCHAR) + ' TL</td></tr>
                </table>
                <p><i>Ýyi çalýþmalar,<br>SQL Server Botu</i></p>
            </body>
            </html>';

        -- 3. MAÝLÝ GÖNDER
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'SirketBildirimProfili',
            @recipients = 'ibrahimtrkylmz632@gmail.com', -- CEO'nun mail adresi (Senin mailin olsun þimdilik)
            @subject = ' Yüksek Ciro Alarmý!',
            @body = @MailIcerigi,
            @body_format = 'HTML';
    END
END


INSERT INTO dbo.ORDERS (USERID, DATE_, TOTALPRICE, STATUS_)
VALUES (1, GETDATE(), 999999999, 1);

SELECT * FROM msdb.dbo.sysmail_event_log ORDER BY log_date DESC;