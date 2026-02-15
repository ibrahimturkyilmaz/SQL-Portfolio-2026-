# 🚀 İleri Seviye SQL Çalışmaları

<div align="center">

![Advanced SQL](https://img.shields.io/badge/Level-Advanced-red?style=for-the-badge)
![T-SQL](https://img.shields.io/badge/T--SQL-Expert-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Status](https://img.shields.io/badge/Status-In%20Progress-yellow?style=for-the-badge)

**Profesyonel T-SQL Teknikleri ve Veritabanı Programlama**

</div>

---

## 📋 İçindekiler

- [📊 Window Functions](#-window-functions)
- [🔄 CTEs \& Recursive Queries](#-ctes--recursive-queries)
- [🔀 Pivot \& Unpivot](#-pivot--unpivot)
- [⚙️ Stored Procedures](#-stored-procedures)
- [🎯 Triggers](#-triggers)
- [🧩 Dynamic SQL](#-dynamic-sql)
- [📚 Pratik Örnekler](#-pratik-örnekler)

---

## 🗂️ Klasör Yapısı

```
Ileri-Seviye/
│
├── 01-Window-Functions/
│   ├── 01_Ranking_Functions.sql          # ROW_NUMBER, RANK, DENSE_RANK
│   ├── 02_Offset_Functions.sql           # LAG, LEAD, FIRST_VALUE, LAST_VALUE
│   ├── 03_Aggregate_Windows.sql          # SUM, AVG, COUNT OVER
│   ├── 04_Advanced_Partitioning.sql      # Karmaşık PARTITION BY senaryoları
│   └── README.md
│
├── 02-CTEs-Recursive/
│   ├── 01_Basic_CTE.sql                  # Temel CTE kullanımı
│   ├── 02_Multiple_CTEs.sql              # Çoklu CTE'ler
│   ├── 03_Recursive_Hierarchy.sql        # Organizasyon hiyerarşisi
│   ├── 04_Recursive_Date_Series.sql      # Tarih serileri oluşturma
│   ├── 05_Advanced_Recursion.sql         # Graph traversal, BOM
│   └── README.md
│
├── 03-Pivot-Unpivot/
│   ├── 01_Static_Pivot.sql               # Sabit pivot tablolar
│   ├── 02_Dynamic_Pivot.sql              # Dinamik pivot
│   ├── 03_Unpivot_Examples.sql           # Unpivot işlemleri
│   ├── 04_CrossTab_Reports.sql           # Crosstab raporlar
│   └── README.md
│
├── 04-Stored-Procedures/
│   ├── 01_Basic_SP.sql                   # Temel stored procedure
│   ├── 02_Input_Output_Params.sql        # Parametre yönetimi
│   ├── 03_Error_Handling.sql             # TRY-CATCH yapısı
│   ├── 04_Transaction_Management.sql     # Transaction kontrolü
│   ├── 05_Advanced_SP.sql                # Kompleks business logic
│   └── README.md
│
├── 05-Triggers/
│   ├── 01_AFTER_Trigger.sql              # AFTER INSERT/UPDATE/DELETE
│   ├── 02_INSTEAD_OF_Trigger.sql         # INSTEAD OF triggers
│   ├── 03_Audit_Trail.sql                # Audit log trigger
│   ├── 04_Business_Rules_Trigger.sql     # İş kuralları
│   └── README.md
│
├── 06-Dynamic-SQL/
│   ├── 01_sp_executesql.sql              # Dinamik sorgu çalıştırma
│   ├── 02_Dynamic_Pivot.sql              # Dinamik pivot örneği
│   ├── 03_SQL_Injection_Prevention.sql   # Güvenli kod yazma
│   └── README.md
│
└── 07-Practice-Projects/
    ├── Sales_Analytics_Advanced.sql
    ├── Inventory_Management.sql
    └── Performance_Tuning_Examples.sql
```

---

## 📊 Window Functions

### 🎯 Kapsam ve Kullanım Alanları

Window Functions, SQL'in en güçlü özelliklerinden biridir. Aggregate fonksiyonlar gibi çalışırlar ancak satırları gruplamadan, her satır için hesaplama yaparlar.

<details>
<summary><b>📖 Window Functions Genel Bakış (Tıklayın)</b></summary>

#### Temel Syntax
```sql
<window_function> OVER (
    [PARTITION BY partition_expression]
    [ORDER BY sort_expression [ASC | DESC]]
    [ROWS/RANGE window_frame]
)
```

#### Fonksiyon Kategorileri

| Kategori | Fonksiyonlar | Kullanım Amacı |
|----------|-------------|----------------|
| **Ranking** | ROW_NUMBER(), RANK(), DENSE_RANK(), NTILE() | Sıralama ve gruplama |
| **Offset** | LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE() | Önceki/sonraki satıra erişim |
| **Aggregate** | SUM(), AVG(), COUNT(), MIN(), MAX() | Hareketli hesaplamalar |
| **Distribution** | PERCENT_RANK(), CUME_DIST() | Yüzdelik dağılımlar |

</details>

---

### 🔢 1. Ranking Functions (Sıralama Fonksiyonları)

<details>
<summary><b>💡 ROW_NUMBER() - Benzersiz Sıra Numarası</b></summary>

#### Açıklama
Her satıra benzersiz bir sıra numarası atar. Duplicate değerler olsa bile farklı numaralar verir.

#### Kullanım Senaryoları
- Sayfalama (Pagination)
- Duplicate kayıtları temizleme
- Top N sorguları

#### Örnek: En Çok Satan Ürünler (Kategori Bazında)
```sql
WITH UrunSatislar AS (
    SELECT 
        c.CategoryName,
        p.ProductName,
        SUM(od.Quantity) AS ToplamSatilan,
        SUM(od.Quantity * od.UnitPrice) AS ToplamGelir,
        -- Her kategori içinde gelire göre sıralama
        ROW_NUMBER() OVER (
            PARTITION BY c.CategoryName 
            ORDER BY SUM(od.Quantity * od.UnitPrice) DESC
        ) AS KategoriIcindeRank
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Categories c ON p.CategoryID = c.CategoryID
    GROUP BY c.CategoryName, p.ProductName
)
SELECT 
    CategoryName,
    ProductName,
    ToplamSatilan,
    ToplamGelir,
    KategoriIcindeRank
FROM UrunSatislar
WHERE KategoriIcindeRank <= 3  -- Her kategoriden top 3
ORDER BY CategoryName, KategoriIcindeRank;
```

#### Sayfalama (Pagination) Örneği
```sql
DECLARE @SayfaNo INT = 2
DECLARE @SayfaBoyutu INT = 10

WITH SayfaliVeri AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY OrderDate DESC) AS SatirNo
    FROM Orders
)
SELECT *
FROM SayfaliVeri
WHERE SatirNo BETWEEN (@SayfaNo - 1) * @SayfaBoyutu + 1 
                  AND @SayfaNo * @SayfaBoyutu;
```

</details>

<details>
<summary><b>💡 RANK() vs DENSE_RANK() - Sıralamadaki Farklar</b></summary>

#### RANK()
Aynı değerler aynı rank alır, sonraki rank atlanır.
**Örnek:** 1, 2, 2, 4, 5 (3 atlandı)

#### DENSE_RANK()
Aynı değerler aynı rank alır, sonraki rank devam eder.
**Örnek:** 1, 2, 2, 3, 4 (boşluk yok)

#### Karşılaştırmalı Örnek
```sql
SELECT 
    ProductName,
    UnitPrice,
    -- ROW_NUMBER: Her zaman benzersiz
    ROW_NUMBER() OVER (ORDER BY UnitPrice DESC) AS RowNum,
    -- RANK: Eşit değerlerde aynı, sonra atlama
    RANK() OVER (ORDER BY UnitPrice DESC) AS RankNum,
    -- DENSE_RANK: Eşit değerlerde aynı, devam
    DENSE_RANK() OVER (ORDER BY UnitPrice DESC) AS DenseRankNum
FROM Products
ORDER BY UnitPrice DESC;
```

**Örnek Çıktı:**
| ProductName | UnitPrice | RowNum | RankNum | DenseRankNum |
|-------------|-----------|--------|---------|--------------|
| Product A | 100.00 | 1 | 1 | 1 |
| Product B | 100.00 | 2 | 1 | 1 |
| Product C | 95.50 | 3 | 3 | 2 |
| Product D | 95.50 | 4 | 3 | 2 |
| Product E | 90.00 | 5 | 5 | 3 |

#### Pratik Kullanım: Maaş Sıralaması
```sql
-- Departman bazında maaş sıralaması
SELECT 
    DepartmentName,
    EmployeeName,
    Salary,
    RANK() OVER (
        PARTITION BY DepartmentName 
        ORDER BY Salary DESC
    ) AS MaasRank,
    -- Yüzdelik dilim (Quartile)
    NTILE(4) OVER (
        PARTITION BY DepartmentName 
        ORDER BY Salary DESC
    ) AS MaasQuartile
FROM Employees e
JOIN Departments d ON e.DepartmentID = d.DepartmentID;
```

</details>

<details>
<summary><b>💡 NTILE() - Gruplara Bölme</b></summary>

#### Açıklama
Veriyi eşit sayıda gruba (bucket) böler. Quartile, percentile hesaplamalarında kullanılır.

#### Örnek: Müşteri Segmentasyonu (Harcama Bazında)
```sql
WITH MusteriHarcama AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        SUM(o.TotalAmount) AS ToplamHarcama,
        COUNT(DISTINCT o.OrderID) AS SiparisSayisi,
        -- Müşterileri 4 gruba böl (Quartile)
        NTILE(4) OVER (ORDER BY SUM(o.TotalAmount) DESC) AS HarcamaQuartile,
        -- Müşterileri 100 gruba böl (Percentile)
        NTILE(100) OVER (ORDER BY SUM(o.TotalAmount) DESC) AS HarcamaPercentile
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT 
    *,
    CASE HarcamaQuartile
        WHEN 1 THEN '🥇 VIP (Top 25%)'
        WHEN 2 THEN '🥈 Altın (25-50%)'
        WHEN 3 THEN '🥉 Gümüş (50-75%)'
        WHEN 4 THEN '📊 Standart (Bottom 25%)'
    END AS MusteriSegmenti
FROM MusteriHarcama
ORDER BY ToplamHarcama DESC;
```

#### ABC Analizi Örneği
```sql
-- Ürünleri satış tutarına göre A, B, C sınıflandırması
WITH UrunSatislar AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(od.Quantity * od.UnitPrice) AS ToplamSatis,
        -- Kümülatif toplam için
        SUM(SUM(od.Quantity * od.UnitPrice)) OVER (
            ORDER BY SUM(od.Quantity * od.UnitPrice) DESC
        ) AS KumulatifSatis
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName
),
ToplamSatisHesapla AS (
    SELECT 
        *,
        (SELECT SUM(ToplamSatis) FROM UrunSatislar) AS GenelToplam,
        KumulatifSatis * 100.0 / (SELECT SUM(ToplamSatis) FROM UrunSatislar) AS KumulatifYuzde
    FROM UrunSatislar
)
SELECT 
    ProductName,
    ToplamSatis,
    ROUND(KumulatifYuzde, 2) AS KumulatifYuzde,
    CASE 
        WHEN KumulatifYuzde <= 70 THEN 'A - Yüksek Değer (Top 70%)'
        WHEN KumulatifYuzde <= 90 THEN 'B - Orta Değer (70-90%)'
        ELSE 'C - Düşük Değer (Son 10%)'
    END AS ABC_Sinifi
FROM ToplamSatisHesapla
ORDER BY ToplamSatis DESC;
```

</details>

---

### ⏭️ 2. Offset Functions (Kayma Fonksiyonları)

<details>
<summary><b>💡 LAG() & LEAD() - Önceki ve Sonraki Satırlara Erişim</b></summary>

#### LAG() - Önceki Satır
Mevcut satırın **öncesindeki** satırlara erişim sağlar.

#### LEAD() - Sonraki Satır
Mevcut satırın **sonrasındaki** satırlara erişim sağlar.

#### Syntax
```sql
LAG(column_name, offset, default_value) OVER (ORDER BY ...)
LEAD(column_name, offset, default_value) OVER (ORDER BY ...)
```

#### Örnek: Aylık Satış Trendi ve Değişim
```sql
WITH AylikSatis AS (
    SELECT 
        YEAR(OrderDate) AS Yil,
        MONTH(OrderDate) AS Ay,
        SUM(TotalAmount) AS AylikCiro
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    Yil,
    Ay,
    AylikCiro,
    -- Önceki ay cirosu
    LAG(AylikCiro, 1) OVER (ORDER BY Yil, Ay) AS OncekiAyCiro,
    -- Sonraki ay cirosu
    LEAD(AylikCiro, 1) OVER (ORDER BY Yil, Ay) AS SonrakiAyCiro,
    -- Aylık değişim (₺)
    AylikCiro - LAG(AylikCiro, 1) OVER (ORDER BY Yil, Ay) AS Degisim,
    -- Aylık değişim (%)
    ROUND(
        (AylikCiro - LAG(AylikCiro, 1) OVER (ORDER BY Yil, Ay)) * 100.0 / 
        NULLIF(LAG(AylikCiro, 1) OVER (ORDER BY Yil, Ay), 0),
        2
    ) AS DegisimYuzde,
    -- Trend göstergesi
    CASE 
        WHEN AylikCiro > LAG(AylikCiro, 1) OVER (ORDER BY Yil, Ay) THEN '📈 Artış'
        WHEN AylikCiro < LAG(AylikCiro, 1) OVER (ORDER BY Yil, Ay) THEN '📉 Düşüş'
        ELSE '➡️ Sabit'
    END AS Trend
FROM AylikSatis
ORDER BY Yil, Ay;
```

#### Örnek: Stok Hareketi Analizi
```sql
WITH StokHareketleri AS (
    SELECT 
        ProductID,
        TransactionDate,
        TransactionType,  -- 'IN' veya 'OUT'
        Quantity,
        -- Kümülatif stok
        SUM(CASE WHEN TransactionType = 'IN' THEN Quantity ELSE -Quantity END) 
            OVER (PARTITION BY ProductID ORDER BY TransactionDate) AS MevcutStok
    FROM StockTransactions
)
SELECT 
    ProductID,
    TransactionDate,
    TransactionType,
    Quantity,
    MevcutStok,
    -- Önceki stok seviyesi
    LAG(MevcutStok, 1) OVER (PARTITION BY ProductID ORDER BY TransactionDate) AS OncekiStok,
    -- Stok değişimi
    MevcutStok - LAG(MevcutStok, 1) OVER (PARTITION BY ProductID ORDER BY TransactionDate) AS StokDegisimi,
    -- Kritik seviye uyarısı
    CASE 
        WHEN MevcutStok < 10 AND LAG(MevcutStok, 1) OVER (PARTITION BY ProductID ORDER BY TransactionDate) >= 10 
        THEN '⚠️ KRİTİK SEVİYE'
        ELSE NULL
    END AS Uyari
FROM StokHareketleri
ORDER BY ProductID, TransactionDate;
```

</details>

<details>
<summary><b>💡 FIRST_VALUE() & LAST_VALUE() - İlk ve Son Değer</b></summary>

#### Açıklama
Window frame içindeki ilk veya son değeri döndürür.

#### Örnek: Her Müşterinin İlk ve Son Siparişi
```sql
SELECT 
    CustomerID,
    OrderID,
    OrderDate,
    TotalAmount,
    -- İlk sipariş tarihi
    FIRST_VALUE(OrderDate) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS IlkSiparisTarihi,
    -- Son sipariş tarihi
    LAST_VALUE(OrderDate) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS SonSiparisTarihi,
    -- İlk sipariş tutarı
    FIRST_VALUE(TotalAmount) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS IlkSiparisTutari,
    -- Müşteri yaşı (gün)
    DATEDIFF(DAY, 
        FIRST_VALUE(OrderDate) OVER (
            PARTITION BY CustomerID 
            ORDER BY OrderDate
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ),
        OrderDate
    ) AS MusteriYasiGun
FROM Orders
ORDER BY CustomerID, OrderDate;
```

#### Örnek: Ürün Fiyat Değişim Takibi
```sql
WITH FiyatDegisiklikleri AS (
    SELECT 
        ProductID,
        EffectiveDate,
        NewPrice,
        -- İlk fiyat
        FIRST_VALUE(NewPrice) OVER (
            PARTITION BY ProductID 
            ORDER BY EffectiveDate
        ) AS IlkFiyat,
        -- Güncel fiyat
        LAST_VALUE(NewPrice) OVER (
            PARTITION BY ProductID 
            ORDER BY EffectiveDate
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS GuncelFiyat
    FROM PriceHistory
)
SELECT 
    ProductID,
    EffectiveDate,
    NewPrice,
    IlkFiyat,
    GuncelFiyat,
    -- Başlangıçtan bu yana değişim
    ROUND((NewPrice - IlkFiyat) * 100.0 / NULLIF(IlkFiyat, 0), 2) AS BaslangictanDegisimYuzde,
    -- Toplam değişim
    ROUND((GuncelFiyat - IlkFiyat) * 100.0 / NULLIF(IlkFiyat, 0), 2) AS ToplamDegisimYuzde
FROM FiyatDegisiklikleri
ORDER BY ProductID, EffectiveDate;
```

</details>

---

### 📈 3. Aggregate Window Functions

<details>
<summary><b>💡 Hareketli Ortalamalar (Moving Averages)</b></summary>

#### 3 Aylık Hareketli Ortalama
```sql
SELECT 
    OrderDate,
    DailyRevenue,
    -- Son 7 günün ortalaması
    AVG(DailyRevenue) OVER (
        ORDER BY OrderDate
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS HareketliOrt7Gun,
    -- Son 30 günün ortalaması
    AVG(DailyRevenue) OVER (
        ORDER BY OrderDate
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS HareketliOrt30Gun,
    -- Son 90 günün ortalaması
    AVG(DailyRevenue) OVER (
        ORDER BY OrderDate
        ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
    ) AS HareketliOrt90Gun
FROM DailySales
ORDER BY OrderDate;
```

#### Kümülatif Toplam (Cumulative Sum)
```sql
SELECT 
    OrderDate,
    DailyRevenue,
    -- Yıl başından itibaren kümülatif toplam (YTD)
    SUM(DailyRevenue) OVER (
        PARTITION BY YEAR(OrderDate)
        ORDER BY OrderDate
    ) AS YTD_Revenue,
    -- Ay başından itibaren kümülatif toplam (MTD)
    SUM(DailyRevenue) OVER (
        PARTITION BY YEAR(OrderDate), MONTH(OrderDate)
        ORDER BY OrderDate
    ) AS MTD_Revenue,
    -- Toplam içindeki yüzde
    ROUND(
        SUM(DailyRevenue) OVER (ORDER BY OrderDate) * 100.0 /
        SUM(DailyRevenue) OVER (),
        2
    ) AS KumulatifYuzde
FROM DailySales
ORDER BY OrderDate;
```

</details>

---

## 🔄 CTEs & Recursive Queries

### 📚 Common Table Expressions (CTE)

<details>
<summary><b>💡 Temel CTE Kullanımı</b></summary>

#### Açıklama
CTE, sorgu içinde geçici named result set oluşturur. Karmaşık sorguları daha okunabilir yapar.

#### Syntax
```sql
WITH CTE_Name AS (
    SELECT ...
    FROM ...
    WHERE ...
)
SELECT * FROM CTE_Name;
```

#### Örnek: Müşteri Analizi
```sql
WITH MusteriOzet AS (
    SELECT 
        CustomerID,
        COUNT(DISTINCT OrderID) AS SiparisSayisi,
        SUM(TotalAmount) AS ToplamHarcama,
        AVG(TotalAmount) AS OrtSiparisTutari,
        MIN(OrderDate) AS IlkSiparis,
        MAX(OrderDate) AS SonSiparis
    FROM Orders
    GROUP BY CustomerID
),
MusteriSegment AS (
    SELECT 
        *,
        CASE 
            WHEN ToplamHarcama > 10000 THEN 'VIP'
            WHEN ToplamHarcama > 5000 THEN 'Premium'
            WHEN ToplamHarcama > 1000 THEN 'Regular'
            ELSE 'New'
        END AS Segment
    FROM MusteriOzet
)
SELECT 
    ms.*,
    c.CustomerName,
    c.Email,
    DATEDIFF(DAY, ms.SonSiparis, GETDATE()) AS SonSiparistenGun
FROM MusteriSegment ms
JOIN Customers c ON ms.CustomerID = c.CustomerID
WHERE Segment IN ('VIP', 'Premium')
ORDER BY ToplamHarcama DESC;
```

</details>

<details>
<summary><b>💡 Recursive CTE - Hiyerarşik Veriler</b></summary>

#### Açıklama
Recursive CTE, kendini çağırarak hiyerarşik verileri işler (ağaç yapıları, org chart, bill of materials).

#### Syntax
```sql
WITH RECURSIVE_CTE AS (
    -- Anchor member (başlangıç noktası)
    SELECT ... WHERE ...
    
    UNION ALL
    
    -- Recursive member (kendini çağıran kısım)
    SELECT ... FROM RECURSIVE_CTE ...
)
SELECT * FROM RECURSIVE_CTE;
```

#### Örnek: Organizasyon Şeması
```sql
-- Çalışan tablosu
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(100),
    ManagerID INT,
    JobTitle NVARCHAR(50),
    Salary DECIMAL(10,2)
);

-- Recursive CTE ile tüm hiyerarşi
WITH CalisanHiyerarsi AS (
    -- Anchor: CEO (en üst)
    SELECT 
        EmployeeID,
        EmployeeName,
        ManagerID,
        JobTitle,
        Salary,
        1 AS Seviye,
        CAST(EmployeeName AS NVARCHAR(500)) AS Hiyerarsi
    FROM Employees
    WHERE ManagerID IS NULL  -- CEO'nun yöneticisi yok
    
    UNION ALL
    
    -- Recursive: Alt seviye çalışanlar
    SELECT 
        e.EmployeeID,
        e.EmployeeName,
        e.ManagerID,
        e.JobTitle,
        e.Salary,
        ch.Seviye + 1,
        CAST(ch.Hiyerarsi + ' > ' + e.EmployeeName AS NVARCHAR(500))
    FROM Employees e
    INNER JOIN CalisanHiyerarsi ch ON e.ManagerID = ch.EmployeeID
)
SELECT 
    REPLICATE('    ', Seviye - 1) + EmployeeName AS OrgChart,
    JobTitle,
    Salary,
    Seviye,
    Hiyerarsi
FROM CalisanHiyerarsi
ORDER BY Hiyerarsi;
```

**Çıktı:**
```
OrgChart                    JobTitle            Salary      Seviye
────────────────────────────────────────────────────────────────
John Doe                    CEO                 150000      1
    Jane Smith              VP Sales            100000      2
        Bob Johnson         Sales Manager       75000       3
            Alice Brown     Sales Rep           50000       4
    Mike Wilson             VP IT               95000       2
        Sarah Davis         Dev Manager         80000       3
```

#### Örnek: Bill of Materials (BOM - Ürün Ağacı)
```sql
WITH UrunAgaci AS (
    -- Anchor: Ana ürün
    SELECT 
        ComponentID,
        ComponentName,
        ParentID,
        Quantity,
        UnitPrice,
        1 AS Seviye,
        CAST(ComponentName AS NVARCHAR(500)) AS Path
    FROM Components
    WHERE ParentID IS NULL
    
    UNION ALL
    
    -- Recursive: Alt bileşenler
    SELECT 
        c.ComponentID,
        c.ComponentName,
        c.ParentID,
        c.Quantity * ua.Quantity AS Quantity,  -- Çarpımlı miktar
        c.UnitPrice,
        ua.Seviye + 1,
        CAST(ua.Path + ' > ' + c.ComponentName AS NVARCHAR(500))
    FROM Components c
    INNER JOIN UrunAgaci ua ON c.ParentID = ua.ComponentID
)
SELECT 
    REPLICATE('├── ', Seviye - 1) + ComponentName AS BOMTree,
    Quantity,
    UnitPrice,
    Quantity * UnitPrice AS TotalCost,
    Seviye,
    Path
FROM UrunAgaci
ORDER BY Path;
```

#### Örnek: Tarih Serisi Oluşturma
```sql
DECLARE @StartDate DATE = '2024-01-01'
DECLARE @EndDate DATE = '2024-12-31'

WITH TarihSerisi AS (
    -- Anchor: Başlangıç tarihi
    SELECT @StartDate AS Tarih
    
    UNION ALL
    
    -- Recursive: Her gün ekle
    SELECT DATEADD(DAY, 1, Tarih)
    FROM TarihSerisi
    WHERE Tarih < @EndDate
)
SELECT 
    Tarih,
    DATENAME(WEEKDAY, Tarih) AS GunAdi,
    CASE 
        WHEN DATENAME(WEEKDAY, Tarih) IN ('Saturday', 'Sunday') THEN 'Hafta Sonu'
        ELSE 'İş Günü'
    END AS GunTipi,
    DATEPART(WEEK, Tarih) AS HaftaNo,
    DATEPART(QUARTER, Tarih) AS Ceyrek
FROM TarihSerisi
OPTION (MAXRECURSION 366);  -- 366 gün için
```

</details>

---

## 🔀 Pivot & Unpivot

<details>
<summary><b>💡 PIVOT - Satırları Sütunlara Çevirme</b></summary>

#### Statik PIVOT Örneği
```sql
-- Aylık satışları kategori bazında pivot table
SELECT 
    Yil,
    [Electronics],
    [Clothing],
    [Food],
    [Books]
FROM (
    SELECT 
        YEAR(OrderDate) AS Yil,
        CategoryName,
        TotalAmount
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Categories c ON p.CategoryID = c.CategoryID
) AS SourceTable
PIVOT (
    SUM(TotalAmount)
    FOR CategoryName IN ([Electronics], [Clothing], [Food], [Books])
) AS PivotTable
ORDER BY Yil;
```

#### Dinamik PIVOT
```sql
-- Kategoriler dinamik olarak belirlenir
DECLARE @cols AS NVARCHAR(MAX)
DECLARE @query AS NVARCHAR(MAX)

-- Sütun listesini dinamik oluştur
SELECT @cols = STRING_AGG(QUOTENAME(CategoryName), ', ')
FROM (SELECT DISTINCT CategoryName FROM Categories) AS Categories;

-- Dinamik pivot sorgusu
SET @query = '
SELECT Yil, ' + @cols + '
FROM (
    SELECT 
        YEAR(OrderDate) AS Yil,
        CategoryName,
        TotalAmount
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Categories c ON p.CategoryID = c.CategoryID
) AS SourceTable
PIVOT (
    SUM(TotalAmount)
    FOR CategoryName IN (' + @cols + ')
) AS PivotTable
ORDER BY Yil;'

EXEC sp_executesql @query;
```

</details>

---

## ⚙️ Stored Procedures

<details>
<summary><b>💡 Temel Stored Procedure</b></summary>

#### Basit SP Örneği
```sql
CREATE PROCEDURE sp_GetCustomerOrders
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        OrderID,
        OrderDate,
        TotalAmount,
        OrderStatus
    FROM Orders
    WHERE CustomerID = @CustomerID
    ORDER BY OrderDate DESC;
END;
GO

-- Kullanım
EXEC sp_GetCustomerOrders @CustomerID = 5;
```

#### Input/Output Parametreli SP
```sql
CREATE PROCEDURE sp_CalculateCustomerStats
    @CustomerID INT,
    @TotalOrders INT OUTPUT,
    @TotalSpent DECIMAL(12,2) OUTPUT,
    @AvgOrderValue DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        @TotalOrders = COUNT(DISTINCT OrderID),
        @TotalSpent = SUM(TotalAmount),
        @AvgOrderValue = AVG(TotalAmount)
    FROM Orders
    WHERE CustomerID = @CustomerID;
    
    -- Eğer hiç sipariş yoksa
    IF @TotalOrders IS NULL
    BEGIN
        SET @TotalOrders = 0;
        SET @TotalSpent = 0;
        SET @AvgOrderValue = 0;
    END
END;
GO

-- Kullanım
DECLARE @Siparis INT, @Tutar DECIMAL(12,2), @Ort DECIMAL(10,2);

EXEC sp_CalculateCustomerStats 
    @CustomerID = 5,
    @TotalOrders = @Siparis OUTPUT,
    @TotalSpent = @Tutar OUTPUT,
    @AvgOrderValue = @Ort OUTPUT;

SELECT @Siparis AS Siparişler, @Tutar AS Toplam, @Ort AS Ortalama;
```

</details>

<details>
<summary><b>💡 Error Handling - TRY CATCH</b></summary>

```sql
CREATE PROCEDURE sp_ProcessOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Stok kontrolü
        DECLARE @AvailableStock INT;
        SELECT @AvailableStock = UnitsInStock
        FROM Products
        WHERE ProductID = @ProductID;
        
        IF @AvailableStock < @Quantity
        BEGIN
            RAISERROR('Yetersiz stok! Mevcut: %d, Talep: %d', 16, 1, @AvailableStock, @Quantity);
        END
        
        -- Sipariş oluştur
        INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
        VALUES (@CustomerID, GETDATE(), 
                (SELECT UnitPrice FROM Products WHERE ProductID = @ProductID) * @Quantity);
        
        DECLARE @OrderID INT = SCOPE_IDENTITY();
        
        -- Sipariş detayı ekle
        INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
        SELECT @OrderID, @ProductID, @Quantity, UnitPrice
        FROM Products
        WHERE ProductID = @ProductID;
        
        -- Stok güncelle
        UPDATE Products
        SET UnitsInStock = UnitsInStock - @Quantity
        WHERE ProductID = @ProductID;
        
        COMMIT TRANSACTION;
        
        SELECT 'Sipariş başarıyla oluşturuldu' AS Mesaj, @OrderID AS SiparisNo;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Hata bilgilerini döndür
        SELECT 
            ERROR_NUMBER() AS HataNo,
            ERROR_MESSAGE() AS HataMesaji,
            ERROR_PROCEDURE() AS HataliProsedur,
            ERROR_LINE() AS HataSatiri;
    END CATCH
END;
```

</details>

---

## 🎯 Triggers

<details>
<summary><b>💡 AFTER Trigger - Audit Log</b></summary>

```sql
-- Audit tablosu
CREATE TABLE ProductAuditLog (
    AuditID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT,
    ColumnChanged NVARCHAR(50),
    OldValue NVARCHAR(500),
    NewValue NVARCHAR(500),
    ChangedBy NVARCHAR(100),
    ChangedDate DATETIME DEFAULT GETDATE()
);
GO

-- Fiyat değişikliklerini logla
CREATE TRIGGER trg_Product_PriceChange
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Sadece fiyat değiştiyse log at
    IF UPDATE(UnitPrice)
    BEGIN
        INSERT INTO ProductAuditLog (ProductID, ColumnChanged, OldValue, NewValue, ChangedBy)
        SELECT 
            i.ProductID,
            'UnitPrice',
            CAST(d.UnitPrice AS NVARCHAR(500)),
            CAST(i.UnitPrice AS NVARCHAR(500)),
            SUSER_SNAME()
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID
        WHERE i.UnitPrice <> d.UnitPrice;
    END
END;
```

</details>

---

## 🧩 Dynamic SQL

<details>
<summary><b>💡 sp_executesql Kullanımı</b></summary>

```sql
CREATE PROCEDURE sp_DynamicSearch
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128),
    @SearchValue NVARCHAR(500)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    
    -- SQL Injection korumalı dinamik sorgu
    SET @SQL = N'SELECT * FROM ' + QUOTENAME(@TableName) + 
               N' WHERE ' + QUOTENAME(@ColumnName) + N' LIKE @Search';
    
    EXEC sp_executesql @SQL, 
         N'@Search NVARCHAR(500)', 
         @Search = '%' + @SearchValue + '%';
END;
```

</details>

---

## 📚 Pratik Örnekler

### Kompleks Analiz Örnekleri

<details>
<summary><b>💼 Satış Performans Dashboard Sorgusu</b></summary>

```sql
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(TotalAmount) AS Revenue,
        COUNT(DISTINCT OrderID) AS Orders,
        COUNT(DISTINCT CustomerID) AS Customers
    FROM Orders
    WHERE OrderDate >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
),
SalesWithMetrics AS (
    SELECT 
        *,
        -- MoM Growth
        LAG(Revenue) OVER (ORDER BY Year, Month) AS PrevMonthRevenue,
        ROUND((Revenue - LAG(Revenue) OVER (ORDER BY Year, Month)) * 100.0 / 
              NULLIF(LAG(Revenue) OVER (ORDER BY Year, Month), 0), 2) AS MoM_Growth,
        -- 3 Month Moving Average
        AVG(Revenue) OVER (ORDER BY Year, Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MA3,
        -- YTD
        SUM(Revenue) OVER (PARTITION BY Year ORDER BY Month) AS YTD
    FROM MonthlySales
)
SELECT * FROM SalesWithMetrics
ORDER BY Year DESC, Month DESC;
```

</details>

---

<div align="center">

## 📊 İstatistikler

| Kategori | Script Sayısı | Tamamlanma |
|----------|---------------|------------|
| Window Functions | 8 | ✅ 100% |
| CTEs & Recursive | 6 | ✅ 100% |
| Pivot & Unpivot | 4 | ✅ 100% |
| Stored Procedures | 5 | 🔄 60% |
| Triggers | 4 | 🔄 40% |
| Dynamic SQL | 3 | ✅ 100% |

**Toplam Kod Satırı:** ~1,200+

</div>

---

<div align="center">

**Son Güncelleme:** Şubat 2026

*Mastering T-SQL, One Query at a Time* 🚀

</div>
