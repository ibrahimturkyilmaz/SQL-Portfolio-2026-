

-- INSERT, UPDATE, DELETE ISLEMLERI KAPSANIR
 
 customer

alter TRIGGER TRGCUSTOMERINSERT
ON customer
AFTER INSERT
AS
BEGIN
DECLARE @ýd AS INT
DECLARE @name AS VARCHAR(100)
DECLARE @birthdate AS DATE

SELECT @ýd=ýd,@name=@name,
@birthdate=@birthdate FROM inserted
SELECT @ýd AS ýd,@name AS name,@birthdate AS birthdate end

truncate table customer
INSERT INTO customer (name, birthdate)
VALUES ('ZEYNEP ÖZKAYA','19850101')