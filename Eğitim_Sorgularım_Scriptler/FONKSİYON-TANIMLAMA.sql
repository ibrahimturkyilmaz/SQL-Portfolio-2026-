--fonksiyon tanimlayai ogrenme
create function dbo.topla(@sayi1 as int, @sayi2 as int)
returns int
as begin
return  @sayi1 + @sayi2
end

select dbo.topla(30,15)

alter function dbo.topla(@sayi1 as int, @sayi2 as int)
returns int
as begin
declare @sonuc as int 
set @sonuc =@sayi1 + @sayi2
return  @sonuc
end


--AY ADÝ GETÝRME
create function dbo.getmonthname(@DATE as DATETIME)
returns varchar(20)
as begin
declare @result as varchar(20)
if month(@DATE) = 1 SET @result = '01.Ocak'
if month(@DATE) = 2 SET @result = '02.Þubat'
if month(@DATE) = 3 SET @result = '03.Mart'
if month(@DATE) = 4 SET @result = '04.Nisan'
if month(@DATE) = 5 SET @result = '05.Mayýs'
if month(@DATE) = 6 SET @result = '06.Haziran'
if month(@DATE) = 7 SET @result = '07.Temmuz'
if month(@DATE) = 8 SET @result = '08.Aðustos'
if month(@DATE) = 9 SET @result = '09.Eylül'
if month(@DATE) = 10 SET @result = '10.Ekim'
if month(@DATE) = 11 SET @result = '11.Kasým'
if month(@DATE) = 12 SET @result = '12.Aralýk'
return @result end
--
select dbo.getmonthname('2026-02-08')
--


select ý.ID, ý.ITEMCODE, ý.ITEMNAME, ý.BRAND, ý.CATEGORY1  ,
(
select sum(amount) from ORDERDETAILS where ITEMID = ý.ID
) toplamadet
from ýtems ý




select ý.ID, ý.ITEMCODE, ý.ITEMNAME, ý.BRAND, ý.CATEGORY1  ,
(
select sum(amount) from ORDERDETAILS where ITEMID = ý.ID
) toplamadet,
dbo.gettotalamount(ý.ID) totalaomunt2,
(
select sum(LINETOTAL) from ORDERDETAILS where ITEMID = ý.ID
) toplamsatis
from ýtems ý

--fonksiyonsuz  karmasik
select ý.ID, ý.ITEMCODE, ý.ITEMNAME, ý.BRAND, ý.CATEGORY1  ,
(
select sum(amount) from ORDERDETAILS where ITEMID = ý.ID
) toplamadet,
dbo.gettotalamount(ý.ID) totalaomunt2,
(
select sum(LINETOTAL) from ORDERDETAILS where ITEMID = ý.ID
) toplamsatis,
dbo.gettotasale(ý.ID) as totalsales2
from ýtems ý

--fonksiyonlu ise 2 satir
select ý.ID, ý.ITEMCODE, ý.ITEMNAME, ý.BRAND, ý.CATEGORY1  ,
dbo.gettotalamount(ý.ID) totalaomunt2,
dbo.gettotasale(ý.ID) as totalsales2
from ýtems ý


-- TABLO FONKSIYONU OLUÞTURDUK SAYISAL DEÐERLER FONSKSIYON TABLODAN GELDI
select ý.ID, ý.ITEMCODE, ý.ITEMNAME
, INF.*
from ýtems ý
cross apply dbo.ITEMINFO2(ý.ýd) INF
--FARK YOK FAKAT YAZIM SEKILLERI FARKLI
select ý.ID, ý.ITEMCODE, ý.ITEMNAME
, INF.*
from ýtems ý
cross apply dbo.ITEMINFO3(ý.ýd) INF







