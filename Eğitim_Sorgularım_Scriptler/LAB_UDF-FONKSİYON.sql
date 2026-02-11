--Elimizde bir futbolcu listesi var. Bu futbolcu listesinde
--içine futbolcunun dogum tarihini alip, yasini getiren
--fonksiyonu yaziniz.

create function dbo.getdate(@BIRTHDATE AS DATE)
RETURNS INT
AS BEGIN
	DECLARE @RESULT AS INT
	SET @RESULT = DATEDIFF(YEAR,@BIRTHDATE,GETDATE())
	RETURN @RESULT
END

SELECT * FROM LAB_PLAYER
select *, dbo.getdate(BIRTHDATE) as yas
from LAB_PLAYER 
where PLAYER_NAME like 'Lionel Messi'


--YAS GRUPLAMASI FONKSIYONU
CREATE FUNCTION DBO.GETAGEGROUP(@BIRTHDATE AS DATE)
RETURNS VARCHAR(20)
AS
BEGIN
DECLARE @AGE AS INT
SET @AGE=DATEDIFF(YEAR,@BIRTHDATE,GETDATE())

DECLARE @RESULT AS VARCHAR(20)
IF @AGE<20
	SET @RESULT='20 DEN KÜÇÜK'
IF @AGE BETWEEN 20 AND 30
	SET @RESULT='20-30 ARASI'
IF @AGE BETWEEN 31 AND 40
	SET @RESULT='31-40 ARASI'
IF @AGE >40
	SET @RESULT='40 TAN BÜYÜK'

RETURN @RESULT
END


select *, dbo.getdate(BIRTHDATE) as yas, dbo.GETAGEGROUP(BIRTHDATE)  as yas_grubu
from LAB_PLAYER 
where PLAYER_NAME like 'Lionel Messi'

--Elimizde bir futbolcu listesi ve futbolcularin oynadigi maclarin listesi var.
--Her bir futbolcunun
--Mevcut oynadigi takimi
--Kac farkli takimda oynadigi
--Toplam kac mac yaptigini
--Kac yildir futbol oynadigi
--getiren fonksiyonlari yaziniz.

--Mevcut oynadigi takimi
CREATE FUNCTION DBO.GETCURRENTTEAM(@PLAYERID AS INT)
RETURNS VARCHAR(100)
AS
BEGIN
DECLARE @RESULT AS VARCHAR(100)
SELECT TOP 1 @RESULT=TEAM
FROM LAB_MATCH_PLAYER
WHERE PLAYERID=@PLAYERID
ORDER BY DATE_ DESC

return @RESULT
END

SELECT PLAYER_API_ID, PLAYER_NAME, DBO.GETCURRENTTEAM(PLAYER_API_ID) AS CURRENTTEAM
FROM LAB_PLAYER WHERE PLAYER_NAME LIKE 'C%RONALDO%'


--Kac farkli takimda oynadigi
CREATE FUNCTION DBO.GETTEAMCOUNT (@PLAYERID AS INT)
RETURNS INT
AS
BEGIN
DECLARE @RESULT AS INT
SELECT @RESULT=COUNT(DISTINCT TEAM) FROM LAB_MATCH_PLAYER
WHERE PLAYERID=@PLAYERID
RETURN @RESULT
END


SELECT PLAYER_API_ID, PLAYER_NAME, DBO.GETCURRENTTEAM(PLAYER_API_ID) AS CURRENTTEAM, DBO.GETTEAMCOUNT (PLAYER_API_ID) as teamcount
FROM LAB_PLAYER WHERE PLAYER_NAME LIKE 'C%RONALDO%'


--Toplam kac mac yaptigini
CREATE FUNCTION DBO.GETMatchCOUNT (@PLAYERID AS INT)
RETURNS INT
AS
BEGIN
DECLARE @RESULT AS INT
SELECT @RESULT=COUNT(*) FROM LAB_MATCH_PLAYER
WHERE PLAYERID=@PLAYERID
RETURN @RESULT
END

SELECT PLAYER_API_ID, PLAYER_NAME,
DBO.GETCURRENTTEAM(PLAYER_API_ID) AS CURRENTTEAM, 
DBO.GETTEAMCOUNT (PLAYER_API_ID) as teamcount,
DBO.GETMatchCOUNT (PLAYER_API_ID) matchCOUNT
FROM LAB_PLAYER WHERE PLAYER_NAME LIKE 'C%RONALDO%'

--Kac yildir futbol oynadigi
CREATE FUNCTION DBO.GETPLAYINGYEAR(@PLAYERID AS INT)
RETURNS INT
AS
BEGIN
DECLARE @RESULT AS INT
SELECT @RESULT=DATEDIFF(YEAR,MIN(DATE_),MAX(DATE_) FROM LAB_MATCH_PLAYER
WHERE PLAYERID=@PLAYERID
RETURN @RESULT
END

/*
Elimizde bir futbolcu listesi ve futbolcularýn oynadýðý
maçlarýn listesi var.
Her bir futbolcunun
--Yaþýný,yaþ grubunu
--Futbolcunun puanýný
--Kaç kez yedek kadroda çýktýðýný
--Kaç kez asýl kadroda çýktýðýný
--Kaç farklý takýmda oynadýðýný
--Toplam kaç maç yaptýðýný
--Kaç yýldýr futbol oynadýðýný
getiren table valued fonksiyonu inline olarak yazýnýz.*/

SELECT * FROM dbo.fnc_FutbolcuDetaylari()
ORDER BY [Toplam_Mac_Sayisi] DESC;
--inline statement yazýmý ve multi statement yazimi vardir.
create FUNCTION dbo.fnc_FutbolcuDetaylari2(@PLAYERID AS INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        P.ID,
        P.PLAYER_NAME AS [Ad Soyad],
   /*     
-- 1. Yaþ
DATEDIFF(YEAR, P.BIRTHDATE, GETDATE()) AS [Yas],
-- 2. Yaþ Grubu
CASE 
    WHEN DATEDIFF(YEAR, P.BIRTHDATE, GETDATE()) < 23 THEN 'Genç'
    WHEN DATEDIFF(YEAR, P.BIRTHDATE, GETDATE()) BETWEEN 23 AND 32 THEN 'Orta'
    ELSE 'Tecrübeli'
END AS [Yas_Grubu],
*/      -- 1. ve 2. Madde Birleþtirildi: [Yaþ Bilgisi]
        -- Örnek Çýktý: "29 (Orta)"
        CAST(DATEDIFF(YEAR, P.BIRTHDATE, GETDATE()) AS VARCHAR(5)) + ' (' +
        CASE 
            WHEN DATEDIFF(YEAR, P.BIRTHDATE, GETDATE()) < 23 THEN 'Genç'
            WHEN DATEDIFF(YEAR, P.BIRTHDATE, GETDATE()) BETWEEN 23 AND 32 THEN 'Orta'
            ELSE 'Tecrübeli'
        END + ')' AS [Yas_Bilgisi],
        -- 3. Puan
        P.RATING AS [Puan],
/*
-- 4. Yedek Kadro 
SUM(CASE WHEN MP.PLAYERTYPE = 'BACKUP' THEN 1 ELSE 0 END) AS [Yedek_Mac_Sayisi],
-- 5. Asýl Kadro
SUM(CASE WHEN MP.PLAYERTYPE = 'REAL' THEN 1 ELSE 0 END) AS [Asil_Mac_Sayisi],
*/
        -- 4. ve 5. Maddeler Birleþtirildi: [Maç Daðýlýmý]
        -- Örnek Çýktý: "10 Asýl - 2 Yedek"
        CAST(SUM(CASE WHEN MP.PLAYERTYPE = 'REAL' THEN 1 ELSE 0 END) AS VARCHAR(10)) + ' Asýl - ' +
        CAST(SUM(CASE WHEN MP.PLAYERTYPE = 'BACKUP' THEN 1 ELSE 0 END) AS VARCHAR(10)) + ' Yedek' 
        AS [Mac_Dagilimi],
        -- 6. Farklý Takým Sayýsý
        COUNT(DISTINCT MP.TEAMID) AS [Farkli_Takim_Sayisi],
        -- 7. Toplam Maç
        COUNT(MP.MATCHID) AS [Toplam_Mac_Sayisi],
        -- 8. Kaç Yýldýr Oynuyor (Ýlk maç ve son maç arasýndaki yýl farký)
        -- Eðer oyuncunun sadece 1 maçý varsa veya süre 1 yýldan azsa 0 döner, +1 eklenebilir tercihe göre.
        ISNULL(DATEDIFF(YEAR, MIN(MP.DATE_), MAX(MP.DATE_)), 0) AS [Kac_Yildir_Oynuyor]
    FROM 
        [LAB_UDF].[dbo].[LAB_PLAYER] P
    INNER JOIN 
        [LAB_UDF].[dbo].[LAB_MATCH_PLAYER] MP ON P.PLAYER_API_ID = MP.PLAYERID
    WHERE 
        P.PLAYER_API_ID = @PLAYERID
    GROUP BY 
        P.ID, 
        P.PLAYER_NAME, 
        P.BIRTHDATE, 
        P.RATING

)
GO

select * from LAB_PLAYER p
cross apply dbo.fnc_FutbolcuDetaylari2(p.PLAYER_API_ID)

