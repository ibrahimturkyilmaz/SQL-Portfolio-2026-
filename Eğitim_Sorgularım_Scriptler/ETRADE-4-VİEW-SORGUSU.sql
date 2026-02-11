create view VW_Orders
as
select 
o.ID orderýd, o.DATE_,
datename(month, o.DATE_) as month,
u.ID userýd, u.GENDER ,u.USERNAME_, u.NAMESURNAME, u.TELNR1, 
a.ADDRESSTEXT, a.POSTALCODE, c.CITY, t.TOWN,
ý.ITEMCODE, ý.ITEMNAME, ý.BRAND, ý.CATEGORY1, ý.CATEGORY2,
od.AMOUNT, od.UNITPRICE, od.LINETOTAL, od.ITEMID
from ORDERS o

join ORDERDETAILS od on od.ID = o.ID
join ITEMS ý on ý.ID = od.ITEMID
join USERS u on u.ID = o.USERID
join ADDRESS a on a.ID = o.ADDRESSID
join CITIES c on c.ID = a.CITYID
join TOWNS t on t.ID = a.TOWNID



ALTER VIEW VW_Orders
as
select 
o.ID orderýd, o.DATE_,
year(o.DATE_) year ,
datename(month, o.DATE_) as month,
DATENAME(DW, o.DATE_) date_name,
u.ID userýd, u.GENDER ,u.USERNAME_, u.NAMESURNAME, u.TELNR1, 
a.ADDRESSTEXT, a.POSTALCODE, c.CITY, t.TOWN,
ý.ITEMCODE, ý.ITEMNAME, ý.BRAND, ý.CATEGORY1, ý.CATEGORY2,
od.AMOUNT, od.UNITPRICE, od.LINETOTAL, od.ITEMID
from ORDERS o

join ORDERDETAILS od on od.ID = o.ID
join ITEMS ý on ý.ID = od.ITEMID
join USERS u on u.ID = o.USERID
join ADDRESS a on a.ID = o.ADDRESSID
join CITIES c on c.ID = a.CITYID
join TOWNS t on t.ID = a.TOWNID


select * from VW_Orders 
where CITY = 'ANKARA'



create view VM_Sales_Month as 
select datepart(month, DATE_) monthnumber, datename(month,DATE_) as month, sum(TOTALPRICE) as totalsale
from ORDERS
 group by datename(month,DATE_) , datepart(month, DATE_)
 -- ORDER BY VÝEW DE KULLANILMAZ order by datepart(month, DATE_) 
 SET LANGUAGE Turkish
 select month, totalsale
 from VM_Sales_Month 
 order by  monthnumber
 --TÜRKÇE ÝÇÝN VEYA 
 alter view VM_Sales_Month as 
 select 
		case 
			when month(DATE_) =1 THEN '01.Ocak'
			when month(DATE_) =2 THEN '02.Þubat'
			when month(DATE_) =3 THEN '03.Mart'
			when month(DATE_) =4 THEN '04.Nisan'
			when month(DATE_) =5 THEN '05.Mayýs'
			when month(DATE_) =6 THEN '06.Haziran'
			when month(DATE_) =7 THEN '07.Temmuz'
			when month(DATE_) =8 THEN '08.Aðustos'
			when month(DATE_) =9 THEN '09.Eylül'
			when month(DATE_) =10 THEN '10.Ekim'
			when month(DATE_) =11 THEN '11.Kasým'
			when month(DATE_) =12 THEN '12.Aralýk'
			END Month_Name,
sum(TOTALPRICE) as totalsale
from ORDERS
 group by datename(month,DATE_) , datepart(month, DATE_)



 create view VW_Ort_Hazirlik_Sure as 
 select 
-- C.CITY, 
 ýt.BRAND, ýt.CATEGORY1, ýt.CATEGORY2,avg(datediff(hour, o.DATE_, I.DATE_)) ortalama_hazirlik_suresi
 
 from orders o
  join INVOICES ý on ý.ORDERID = o.ID
  join ADDRESS a on a.ID = ý.ADDRESSID
  join CITIES c on c.ID = a.CITYID
  join ITEMS ýt on ýt.ID = o.ID

  group by ýt.BRAND, ýt.CATEGORY1, ýt.CATEGORY2  --C.CITY, 


  --ÞUAN DOÐAN MÜÞTERÝLERE TOPLU MESAJ GÖNDERME


  select 
  NAMESURNAME, GENDER, DATEDIFF(year, BIRTHDATE, GETDATE()) AGE, BIRTHDATE,
  CASE 
    WHEN GENDER = 'K' THEN 'SN '+ NAMESURNAME + ' BEY ' + CONVERT(VARCHAR,DATEDIFF(year, BIRTHDATE, GETDATE()))+'. YAÞINIZI KUTLARIM.'
	
    WHEN GENDER = 'E' THEN 'SN '+ NAMESURNAME + ' HANIM '  + CONVERT(VARCHAR,DATEDIFF(year, BIRTHDATE, GETDATE()))+'. YAÞINIZI KUTLARIM.'
	END MESSAGE
  from users
  WHERE 
  DATEPART(MONTH,BIRTHDATE) = DATEPART(MONTH,GETDATE()) AND
  DATEPART(DAY,BIRTHDATE) = DATEPART(DAY,GETDATE())
  --DAHA KISA VE VÝEW OLUÞTURARAK

  CREATE VIEW VW_DOGUM_GUNU_MESAJ
  AS
  SELECT
  'SN '+ NAMESURNAME + GENDEREXP + CONVERT(VARCHAR, AGE)+'. YAÞINIZI KUTLARIM.' as mesaj
  FROM
  (
	  select 
	  NAMESURNAME, GENDER, DATEDIFF(year, BIRTHDATE, GETDATE()) AGE, BIRTHDATE,
	  IIF(GENDER='K', 'HANIM', 'BEY') GENDEREXP
	  from users
	  WHERE 
	  DATEPART(MONTH,BIRTHDATE) = DATEPART(MONTH,GETDATE()) AND
	  DATEPART(DAY,BIRTHDATE) = DATEPART(DAY,GETDATE())
  ) T





