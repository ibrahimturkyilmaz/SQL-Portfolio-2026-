<div align="center">

# 🚀 SQL-Portfolio-2026
### Veri Mühendisliği & İş Zekası Mimarisi
*Endüstri Mühendisliği Vizyonuyla: Ham Veriden Stratejik İçgörüye*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ibrahim-turkyilmaz-68a188253/)
![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active_Development-success?style=for-the-badge)

</div>

---

## 📌 Yönetici Özeti (Executive Summary)

Bu depo, standart sorgu yazımının ötesine geçerek; **gerçek hayat senaryolarına dayalı veri mimarisi kurmayı** ve ham veriyi C-Level yöneticiler için **stratejik karar destek mekanizmalarına** dönüştürmeyi hedefler.

Bir **Endüstri Mühendisi** olarak odak noktam sadece kodun çalışması değil; **süreç optimizasyonu, maliyet analizi, veri bütünlüğü ve darboğaz (bottleneck) tespitidir.**

| 🛠️ Kullanılan Araçlar | 📍 Odak Alanları |
| :--- | :--- |
| **SSMS 19** (Geliştirme) | Veri Modelleme & Normalizasyon |
| **T-SQL** (Advanced) | Performans Optimizasyonu |
| **Git & GitHub** (Versiyon) | İş Zekası (BI) Raporlama |

---

## 📂 Proje Matrisi (Portfolio Matrix)

*Detayları görmek için proje ismine tıklayabilirsiniz.*

| Proje Adı | Sektör | Veri Kaynağı | Temel Çözüm |
| :--- | :--- | :--- | :--- |
| **1. Retail 360** | 🛒 E-Ticaret | `ETRADE4` (SQL DB) | **Müşteri 360 & Lojistik Analizi** <br> *(View, UDF)* |
| **2. PROMASTER** | 🏭 Tedarik Zinciri | `AdventureWorks`, `Superstore` | **Stok Yönetimi & Zarar Önleme** <br> *(ABC Analizi, KPI)* |
| **3. FinTech & InsurTech** | 🏦 Banka & Sigorta | `BankChurn`, `Insurance.csv` | **Risk Skorlama & Fraud Tespiti** <br> *(Aktüerya, CRM)* |

---

## 🏗️ Proje Detayları (Architecture Deep Dive)

<details>
<summary><h3>🛒 1. Retail 360: Advanced E-Commerce Intelligence (Aktif)</h3></summary>

> **Özet:** Perakende sektöründe "Operasyonel Körlüğü" ortadan kaldıran merkezi raporlama sistemi.
> **Veri Seti:** `ETRADE4` (Normalize SQL Veritabanı - Users, Orders, Payments, Items).

* **Müşteri 360 (`VW_Customer360`):** Müşterilerin yaşam boyu değerini (CLV), sipariş sıklığını ve son aktivitesini tek satıra indiren özet yapı.
* **Lojistik Isı Haritası (`VW_CityPerformance`):** `COUNT(DISTINCT)` stratejisi ile adres çoklamasını engelleyerek şehir bazlı ciro ve navlun maliyeti analizi.
* **Ürün Karnesi (`VW_ProductPerformance`):** Ürünleri ciro katkısına göre "Yıldız Ürün" veya "Zayıf Halka" olarak segmentlere ayıran algoritma.
* **Fonksiyonel Zeka:** Teslimat gecikmelerini (`fn_CalculateDelay`) ve iş günlerini hesaplayan matematiksel modüller.

</details>

<details>
<summary><h3>🏭 2. PROMASTER: Supply Chain & Sales Analytics</h3></summary>

> **Özet:** Verimlilik, Stok Yönetimi ve CRM üzerine kurgulanmış kapsamlı veri analizi.
> **Veri Setleri:** `Superstore Sales.csv`, `AdventureWorks2019.bak`.

* **Zarar Önleme (Loss Prevention):** Kârlılığı negatif olan kategorilerin tespiti.
* **Stok Yönetimi (ABC Analizi):** Pareto prensibiyle (80/20) stok sınıflandırması.
* **Tedarikçi Karnesi (Vendor Rating):** Termin süresine uyum (OTIF) puanlaması.
* **Üretim Darboğaz Analizi (Bottleneck):** Planlanan vs Gerçekleşen süre sapmalarının (Standart Sapma) tespiti.

</details>

<details>
<summary><h3>🏦 3. FinTech & InsurTech Master Plan</h3></summary>

> **Özet:** Bankacılık ve Sigortacılık verileriyle Risk, Fraud ve Aktüeryal analizler.
> **Veri Setleri:** `bank.csv`, `german_credit.csv`, `fraud_detection.csv`.

* **Aktüeryal Fiyatlandırma:** Sigara kullanımı ve BMI endeksinin maliyetlere etkisi *(The Smoker Tax)*.
* **Kredi Risk Skorlama:** Amaç bazlı risk analizi ve sanal skorlama kartı *(Scorecard Simulation)*.
* **Sigorta Sahteciliği (Fraud):** "Pazartesi Sendromu" ve kaza tarihi manipülasyonlarının tespiti.
* **Churn Prediction:** Müşteri kaybını önleyici erken uyarı sistemleri.

</details>

---

## 🗺️ Gelişim Yol Haritası (Roadmap)

Bu proje, **Teknik Yetkinlikler** ile **Yönetsel Bakış Açısını** birleştiren 5 fazlı bir yapıdadır.

- [x] **Faz 1: Stratejik Raporlama Katmanı** (Advanced Views) 🟢
    * *Teknik:* Complex JOINS, CTEs, Window Functions.
    * *Yönetsel:* KPI Belirleme, Departman Bazlı Raporlama.
- [ ] **Faz 2: Fonksiyonel Zeka** (User Defined Functions) 🟡 *Devam Ediyor*
    * *Teknik:* Scalar & Table Valued Functions.
    * *Yönetsel:* İş Mantığı (Business Logic) Standardizasyonu.
- [ ] **Faz 3: Operasyonel Bütünlük** (Stored Procedures) 🔴
    * *Teknik:* ACID Transactions, Error Handling.
    * *Yönetsel:* İş Akışı (Workflow) Tasarımı.
- [ ] **Faz 4: Otomasyon & Denetim** (Triggers) 🔴
    * *Teknik:* Audit Logs, Security Triggers.
    * *Yönetsel:* İç Denetim ve Güvenlik Politikaları.
- [ ] **Faz 5: Performans Optimizasyonu** (Tuning) 🔴
    * *Teknik:* Indexing, Execution Plan Analysis.
    * *Yönetsel:* Sistem Ölçeklenebilirliği ve Maliyet Yönetimi.

---

<div align="center">
  <img src="https://media.giphy.com/media/dummy/giphy.gif" width="0" height="0" /> <i>👨‍💻 <b>İbrahim Türkyılmaz</b> tarafından geliştirilmektedir.</i>
</div>