-- Kullanicý Adý Ad Soyad
-- Banka Onay Kodu Semt Fatura Tarihi Ýlce Kargo Fiþ No Açýk Adres Sipariþ ID Tarih Toplam Tutar Ödeme Tarihi

--ilk tablo hazýrlamasý excelde sütun adlarý ve tablo adlarý belirlenir.

--sipariþ kim verdi, hangia adrese, sipraiþ tarihi ve kargo gönderim tarihleri neler, toplam tutarlar neler?

select u.USERNAME_ as kullanýcýadý,
		u.NAMESURNAME as adsoyad,
		ct.CITY as il,
		t.TOWN as ilçe,
		d.DISTRICT as semt,
		a.ADDRESSTEXT as acýkadres,
		o.ID as sipraisId,
		o.DATE_ as tarih,
		o.TOTALPRICE as toplamtutar,
		p.DATE_ as ordemetarýhý,
		p.APPROVECODE as bankaonaykod,
		ý.DATE_ as faturatarihi,
		ý.CARGOFICHENO as kargofisno
from orders o 

		inner join users u on u.ID = o.USERID
		inner join ADDRESS a on a.ID = o.ADDRESSID
		inner join CITIES ct on ct.ID = a.CITYID
		inner join TOWNS t on t.ID = a.TOWNID 
		inner join DISTRICTS d on d.ID = a.DISTRICTID
		inner join PAYMENTS p on p.ORDERID = o.ID
		inner join INVOICES ý on ý.ORDERID = o.ID



--sipariþ detaylarý


select u.USERNAME_ as kullanýcýadý,
		u.NAMESURNAME as adsoyad,
		ct.CITY as il,
		t.TOWN as ilçe,
		d.DISTRICT as semt,
		a.ADDRESSTEXT as acýkadres,
		o.ID as sipraisId,
		o.DATE_ as tarih,
		o.TOTALPRICE as toplamtutar,
		p.DATE_ as ordemetarýhý,
		p.APPROVECODE as bankaonaykod,
		ý.DATE_ as faturatarihi,
		ý.CARGOFICHENO as kargofisno,
		od.*,
		ýtm.ITEMCODE as itemkodu,
		ýtm.ITEMNAME as itemismi,
		od.AMOUNT as miktar,
		od.LINETOTAL as satýrtoplami

from orders o 

		inner join users u on u.ID = o.USERID
		inner join ADDRESS a on a.ID = o.ADDRESSID
		inner join CITIES ct on ct.ID = a.CITYID
		inner join TOWNS t on t.ID = a.TOWNID 
		inner join DISTRICTS d on d.ID = a.DISTRICTID
		inner join PAYMENTS p on p.ORDERID = o.ID
		inner join INVOICES ý on ý.ORDERID = o.ID
		inner join ORDERDETAILS od on od.ORDERID = o.ID
		inner join ITEMS ýtm on ýtm.ID = od.ITEMID
where u.NAMESURNAME = 'Ceyda GEZGÝNCÝ'




--þehirlere göre verilen sipariþleri toplam olarak listeleme
--þehirlere göre verilen sipariþ miktarlarý

--þehir adý, toplam verilen sipraiþ turarý, toplam sipariþ adedi, toplam sipraiþ sayýsý
 


select 
--u.USERNAME_ as kullanýcýadý, u.NAMESURNAME as adsoyad,
ct.CITY as þehir,
sum(od.LINETOTAL) as toplamsipariþtoplamý,
sum(od.AMOUNT) as toplamsipariþadedi,
count(od.ID) as toplamsipraiþsayýsý

from orders o 

		inner join users u on u.ID = o.USERID
		inner join ADDRESS a on a.ID = o.ADDRESSID
		inner join CITIES ct on ct.ID = a.CITYID
		inner join TOWNS t on t.ID = a.TOWNID 
		inner join DISTRICTS d on d.ID = a.DISTRICTID
		inner join PAYMENTS p on p.ORDERID = o.ID
		inner join INVOICES ý on ý.ORDERID = o.ID
		inner join ORDERDETAILS od on od.ORDERID = o.ID
		inner join ITEMS ýtm on ýtm.ID = od.ITEMID
--where 
--od.ORDERID= 26121 
--u.NAMESURNAME = 'Ceyda GEZGÝNCÝ'
group by ct.CITY --, u.USERNAME_ , u.NAMESURNAME
order by  toplamsipariþtoplamý desc--ct.CITY 


--ürün kategorilerine göre sipariþ daðýlýmý

select 
ýtm.CATEGORY1 ,  ýtm.CATEGORY2, ýtm.CATEGORY3, ýtm.CATEGORY4,
sum(od.LINETOTAL) as toplamsipariþtoplamý,
sum(od.AMOUNT) as toplamsipariþadedi,
count(od.ID) as toplamsipraiþsayýsý

from orders o 

		inner join users u on u.ID = o.USERID
		inner join ADDRESS a on a.ID = o.ADDRESSID
		inner join CITIES ct on ct.ID = a.CITYID
		inner join TOWNS t on t.ID = a.TOWNID 
		inner join DISTRICTS d on d.ID = a.DISTRICTID
		inner join PAYMENTS p on p.ORDERID = o.ID
		inner join INVOICES ý on ý.ORDERID = o.ID
		inner join ORDERDETAILS od on od.ORDERID = o.ID
		inner join ITEMS ýtm on ýtm.ID = od.ITEMID

	GROUP BY ýtm.CATEGORY1,ýtm.CATEGORY2,ýtm.CATEGORY3,ýtm.CATEGORY4
	ORDER BY ýtm.CATEGORY1, 5 DESC


	--TARÝHE GÖRE SÝPARÝÞ DAÐILIMI
	--CONVERT
	
select CONVERT(DATE, O.DATE_) TARIH,
sum(od.LINETOTAL) as toplamsipariþtoplamý,
sum(od.AMOUNT) as toplamsipariþadedi,
count(od.ID) as toplamsipariþsayýsý

from orders o 

		inner join users u on u.ID = o.USERID
		inner join ADDRESS a on a.ID = o.ADDRESSID
		inner join CITIES ct on ct.ID = a.CITYID
		inner join TOWNS t on t.ID = a.TOWNID 
		inner join DISTRICTS d on d.ID = a.DISTRICTID
		inner join PAYMENTS p on p.ORDERID = o.ID
		inner join INVOICES ý on ý.ORDERID = o.ID
		inner join ORDERDETAILS od on od.ORDERID = o.ID
		inner join ITEMS ýtm on ýtm.ID = od.ITEMID

		group by CONVERT(DATE, O.DATE_)
		order by CONVERT(DATE, O.DATE_)



		-- aylara göre 

select DATEPART(YEAR, O.DATE_) YIL,DATEPART(MONTH, O.DATE_) AY,
	   CASE 
			WHEN  DATEPART(MONTH, O.DATE_) = 1 THEN 'OCAK'
			WHEN  DATEPART(MONTH, O.DATE_) = 2 THEN 'ÞUBAT'
			WHEN  DATEPART(MONTH, O.DATE_) = 3 THEN 'MART'
			WHEN  DATEPART(MONTH, O.DATE_) = 4 THEN 'NÝSAN'
			WHEN  DATEPART(MONTH, O.DATE_) = 5 THEN 'MAYIS'
			WHEN  DATEPART(MONTH, O.DATE_) = 6 THEN 'HAZÝRAN'
			WHEN  DATEPART(MONTH, O.DATE_) = 7 THEN 'TEMMUZ'
			WHEN  DATEPART(MONTH, O.DATE_) = 8 THEN 'AÐUSTOS'
			WHEN  DATEPART(MONTH, O.DATE_) = 9 THEN 'EYLÜL'
			WHEN  DATEPART(MONTH, O.DATE_) = 10 THEN 'EKÝM'
			WHEN  DATEPART(MONTH, O.DATE_) = 11 THEN 'KASIM'
			WHEN  DATEPART(MONTH, O.DATE_) = 12 THEN 'ARALIK'
		END AS AYADI,
sum(od.LINETOTAL) as toplamsipariþtoplamý,
sum(od.AMOUNT) as toplamsipariþadedi,
count(od.ID) as toplamsipariþsayýsý

from orders o 

		inner join users u on u.ID = o.USERID
		inner join ADDRESS a on a.ID = o.ADDRESSID
		inner join CITIES ct on ct.ID = a.CITYID
		inner join TOWNS t on t.ID = a.TOWNID 
		inner join DISTRICTS d on d.ID = a.DISTRICTID
		inner join PAYMENTS p on p.ORDERID = o.ID
		inner join INVOICES ý on ý.ORDERID = o.ID
		inner join ORDERDETAILS od on od.ORDERID = o.ID
		inner join ITEMS ýtm on ýtm.ID = od.ITEMID

group by DATEPART(YEAR, O.DATE_),  DATEPART(MONTH, O.DATE_)
order by DATEPART(MONTH, O.DATE_), DATEPART(YEAR, O.DATE_)


--ÖDEME TÜRÜNE GÖRE DAÐILIM

--PAYMENTS TABLOSU VE TÜRÜ

SELECT  DISTINCT PAYMENTTYPE FROM PAYMENTS
--1 KREDÝ 2 BANKA HAVALE


SELECT  DATEPART(YEAR, DATE_) YIL,DATEPART(MONTH, DATE_) AY,
		CASE 
		    WHEN PAYMENTTYPE = 1 THEN 'KREDÝ'
			WHEN PAYMENTTYPE = 2 THEN 'bANKA'
		END AS ÖDEMETURU_ACIKLAMA,
SUM(PAYMENTTOTAL) AS TOPLAMTUTAR

FROM PAYMENTS
group by PAYMENTTYPE, DATEPART(YEAR, DATE_),  DATEPART(MONTH, DATE_)
order by DATEPART(MONTH, DATE_), DATEPART(YEAR, DATE_)


--ORTALAMA TESLÝMAT SÜRESÝ 

--SÝPRAÝÞ TARÝHÝ - KARGO TARÝHÝ


select 
--O.ID AS SIPARISID,O.DATE_ AS SIPARISTARIHI,I.DATE_ AS FATURATARIHI,
--DATEDIFF(HOUR, O.DATE_, I.DATE_) AS TESLÝMATSURESÝ_SAAT,
MIN(DATEDIFF(HOUR, O.DATE_, I.DATE_)) AS ENKISA_TESLÝMATSURESÝ_SAAT,
AVG(DATEDIFF(HOUR, O.DATE_, I.DATE_)) AS ORTALAMA_TESLÝMATSURESÝ_SAAT,
MAX(DATEDIFF(HOUR, O.DATE_, I.DATE_)) AS ENUZUN_TESLÝMATSURESÝ_SAAT
from orders o 

		inner join users u on u.ID = o.USERID
		inner join ADDRESS a on a.ID = o.ADDRESSID
		inner join CITIES ct on ct.ID = a.CITYID
		inner join TOWNS t on t.ID = a.TOWNID 
		inner join DISTRICTS d on d.ID = a.DISTRICTID
		inner join PAYMENTS p on p.ORDERID = o.ID
		inner join INVOICES ý on ý.ORDERID = o.ID
		--GROUP BY O.ID , O.DATE_, I.DATE
		
		
		

		-- en kýsa ve en uzun arasýndaki farka göre kampanya vs yapýlabilir
select u.ID, u.NAMESURNAME,
--O.ID AS SIPARISID,O.DATE_ AS SIPARISTARIHI,I.DATE_ AS FATURATARIHI,
--DATEDIFF(HOUR, O.DATE_, I.DATE_) AS TESLÝMATSURESÝ_SAAT,
MIN(DATEDIFF(HOUR, O.DATE_, I.DATE_)) AS ENKISA_TESLÝMATSURESÝ_SAAT,
AVG(DATEDIFF(HOUR, O.DATE_, I.DATE_)) AS ORTALAMA_TESLÝMATSURESÝ_SAAT,
MAX(DATEDIFF(HOUR, O.DATE_, I.DATE_)) AS ENUZUN_TESLÝMATSURESÝ_SAAT,
sum(o.TOTALPRICE) AS TOPLAMSÝPAÝÞTUARI,
COUNT(O.ID) AS SÝPARÝÞAYISI
from orders o 

		inner join users u on u.ID = o.USERID
		inner join ADDRESS a on a.ID = o.ADDRESSID
		inner join CITIES ct on ct.ID = a.CITYID
		inner join TOWNS t on t.ID = a.TOWNID 
		inner join DISTRICTS d on d.ID = a.DISTRICTID
		inner join PAYMENTS p on p.ORDERID = o.ID
		inner join INVOICES ý on ý.ORDERID = o.ID


		GROUP BY u.ID, u.NAMESURNAME --O.ID , O.DATE_, I.DATE__

		order by 3 desc,5 desc