/* =====================================================================
   PROJE      : NovaStore – E-Ticaret Veri Yönetim Sistemi
   KURUM      : TNC Group / Software Persona SQL Eğitimi – Bitirme Projesi
   HAZIRLAYAN : Talha Semih Pertev
   VERİTABANI : NovaStoreDB
   PLATFORM   : Microsoft SQL Server (T-SQL) – SSMS

   DOSYA AKIŞI
     1. Veritabanı oluşturma
     2. Tabloları oluşturma
     3. Foreign key ilişkileri
     4. Örnek veriler
     5. Altı analiz sorgusu
     6. VIEW oluşturma
     7. BACKUP komutu

   NOT: Script baştan sona tekrar çalıştırılabilir. NovaStoreDB zaten
        varsa önce silinir ve temiz bir şekilde yeniden oluşturulur.
        Bu nedenle mevcut NovaStoreDB içindeki veriler kaybolur.
   ===================================================================== */


/* =====================================================================
   BÖLÜM 1 – VERİTABANI OLUŞTURMA
   ===================================================================== */
USE master;
GO

-- Tekrar çalıştırma durumunda çakışmayı önlemek için mevcut veritabanı silinir.
IF DB_ID(N'NovaStoreDB') IS NOT NULL
BEGIN
    ALTER DATABASE NovaStoreDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE NovaStoreDB;
END
GO

-- Turkish_CI_AS harmanlaması, VARCHAR kolonlarda Türkçe karakterlerin
-- (ç, ğ, ı, İ, ö, ş, ü) doğru saklanmasını sağlar.
CREATE DATABASE NovaStoreDB COLLATE Turkish_CI_AS;
GO

USE NovaStoreDB;
GO


/* =====================================================================
   BÖLÜM 2 – TABLOLARI OLUŞTURMA (DDL)
   Tablolar bağımlılık sırasına göre oluşturulur:
   Categories -> Products -> Customers -> Orders -> OrderDetails
   ===================================================================== */

-- 2.1 Categories: Ürün kategorileri
CREATE TABLE Categories
(
    CategoryID   INT IDENTITY(1,1) NOT NULL,
    CategoryName VARCHAR(50)       NOT NULL,
    CONSTRAINT PK_Categories PRIMARY KEY (CategoryID),
    CONSTRAINT UQ_Categories_CategoryName UNIQUE (CategoryName)
);
GO

-- 2.2 Products: Satıştaki ürünler
CREATE TABLE Products
(
    ProductID   INT IDENTITY(1,1) NOT NULL,
    ProductName VARCHAR(100)      NOT NULL,
    Price       DECIMAL(10,2)     NOT NULL,
    Stock       INT               CONSTRAINT DF_Products_Stock DEFAULT 0,
    CategoryID  INT,
    CONSTRAINT PK_Products PRIMARY KEY (ProductID),
    CONSTRAINT CK_Products_Price CHECK (Price >= 0),
    CONSTRAINT CK_Products_Stock CHECK (Stock >= 0)
);
GO

-- 2.3 Customers: Müşteriler
CREATE TABLE Customers
(
    CustomerID INT IDENTITY(1,1) NOT NULL,
    FullName   VARCHAR(50)       NOT NULL,
    City       VARCHAR(20),
    Email      VARCHAR(100),
    CONSTRAINT PK_Customers PRIMARY KEY (CustomerID),
    CONSTRAINT UQ_Customers_Email UNIQUE (Email)
);
GO

-- 2.4 Orders: Sipariş başlıkları
CREATE TABLE Orders
(
    OrderID     INT IDENTITY(1,1) NOT NULL,
    CustomerID  INT,
    OrderDate   DATETIME          CONSTRAINT DF_Orders_OrderDate DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2),
    CONSTRAINT PK_Orders PRIMARY KEY (OrderID),
    CONSTRAINT CK_Orders_TotalAmount CHECK (TotalAmount >= 0)
);
GO

-- 2.5 OrderDetails: Sipariş satırları (hangi siparişte hangi üründen kaç adet)
CREATE TABLE OrderDetails
(
    DetailID  INT IDENTITY(1,1) NOT NULL,
    OrderID   INT,
    ProductID INT,
    Quantity  INT               NOT NULL,
    CONSTRAINT PK_OrderDetails PRIMARY KEY (DetailID),
    CONSTRAINT CK_OrderDetails_Quantity CHECK (Quantity > 0)
);
GO


/* =====================================================================
   BÖLÜM 3 – FOREIGN KEY İLİŞKİLERİ
   Categories   (1) ---- (N) Products
   Customers    (1) ---- (N) Orders
   Orders       (1) ---- (N) OrderDetails
   Products     (1) ---- (N) OrderDetails
   ===================================================================== */
ALTER TABLE Products
    ADD CONSTRAINT FK_Products_Categories
        FOREIGN KEY (CategoryID) REFERENCES Categories (CategoryID);
GO

ALTER TABLE Orders
    ADD CONSTRAINT FK_Orders_Customers
        FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID);
GO

ALTER TABLE OrderDetails
    ADD CONSTRAINT FK_OrderDetails_Orders
        FOREIGN KEY (OrderID) REFERENCES Orders (OrderID);
GO

ALTER TABLE OrderDetails
    ADD CONSTRAINT FK_OrderDetails_Products
        FOREIGN KEY (ProductID) REFERENCES Products (ProductID);
GO


/* =====================================================================
   BÖLÜM 4 – ÖRNEK VERİLER (DML)
   Veritabanı her çalıştırmada yeniden oluşturulduğu için IDENTITY
   değerleri 1'den başlar; aşağıdaki ID referansları buna göre yazılmıştır.
   ===================================================================== */

-- 4.1 Kategoriler (5 zorunlu + ürünü olmayan 1 kategori: GÖREV 4'teki
--     LEFT JOIN davranışını göstermek için)
INSERT INTO Categories (CategoryName) VALUES
    (N'Elektronik'),      -- 1
    (N'Giyim'),           -- 2
    (N'Kitap'),           -- 3
    (N'Kozmetik'),        -- 4
    (N'Ev ve Yaşam'),     -- 5
    (N'Spor ve Outdoor'); -- 6 (henüz ürünü yok)
GO

-- 4.2 Ürünler (12 ürün, ürünü olan her kategoride en az 2 ürün)
INSERT INTO Products (ProductName, Price, Stock, CategoryID) VALUES
    (N'Samsung Galaxy A55 Akıllı Telefon',        18999.00, 15, 1), -- 1
    (N'Lenovo IdeaPad Slim 3 Dizüstü Bilgisayar', 24999.00,  8, 1), -- 2
    (N'JBL Tune 520BT Kablosuz Kulaklık',          1899.00, 45, 1), -- 3
    (N'Erkek Slim Fit Kot Pantolon',               1299.90, 30, 2), -- 4
    (N'Kadın Triko Kazak',                          899.90, 12, 2), -- 5
    (N'Unisex Spor Ayakkabı',                      2199.00, 18, 2), -- 6
    (N'Suç ve Ceza - Dostoyevski',                  145.00, 60, 3), -- 7
    (N'Sapiens - Yuval Noah Harari',                320.00, 25, 3), -- 8
    (N'Nemlendirici Yüz Kremi 50 ml',               449.90, 40, 4), -- 9
    (N'Mat Ruj - Kırmızı',                          279.90,  9, 4), -- 10
    (N'Filtre Kahve Makinesi',                     3499.00, 14, 5), -- 11
    (N'Pamuklu Nevresim Takımı Çift Kişilik',      1299.00, 22, 5); -- 12
GO

-- 4.3 Müşteriler (6 müşteri, farklı şehirler, benzersiz e-postalar)
INSERT INTO Customers (FullName, City, Email) VALUES
    (N'Ahmet Yılmaz', N'İstanbul',  'ahmet.yilmaz@example.com'), -- 1
    (N'Ayşe Demir',   N'Ankara',    'ayse.demir@example.com'),   -- 2
    (N'Mehmet Kaya',  N'İzmir',     'mehmet.kaya@example.com'),  -- 3
    (N'Zeynep Çelik', N'Bursa',     'zeynep.celik@example.com'), -- 4
    (N'Emre Şahin',   N'Antalya',   'emre.sahin@example.com'),   -- 5
    (N'Elif Arslan',  N'Eskişehir', 'elif.arslan@example.com');  -- 6
GO

-- 4.4 Siparişler (10 sipariş, farklı tarihler)
-- Tarihler 'YYYYMMDD SS:DD:ss' biçimindedir; bu biçim SQL Server'ın dil ve
-- DATEFORMAT ayarından bağımsız olarak her zaman doğru yorumlanır.
-- TotalAmount, detaylar girildikten sonra 4.6 adımında hesaplanır.
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount) VALUES
    (1, '20260112 10:15:00', 0), -- 1  Ahmet Yılmaz
    (2, '20260203 14:30:00', 0), -- 2  Ayşe Demir
    (3, '20260318 09:45:00', 0), -- 3  Mehmet Kaya
    (1, '20260425 19:20:00', 0), -- 4  Ahmet Yılmaz
    (4, '20260514 11:05:00', 0), -- 5  Zeynep Çelik
    (5, '20260622 16:40:00', 0), -- 6  Emre Şahin
    (2, '20260709 13:10:00', 0), -- 7  Ayşe Demir
    (6, '20260817 20:25:00', 0), -- 8  Elif Arslan
    (3, '20260930 08:50:00', 0), -- 9  Mehmet Kaya
    (1, '20261028 17:35:00', 0); -- 10 Ahmet Yılmaz
GO

-- 4.5 Sipariş detayları (18 satır)
INSERT INTO OrderDetails (OrderID, ProductID, Quantity) VALUES
    (1,  1, 1), (1,  3, 1),   -- Telefon + Kulaklık
    (2,  5, 2), (2,  9, 1),   -- 2 Kazak + Yüz Kremi
    (3,  2, 1),               -- Dizüstü Bilgisayar
    (4,  7, 2), (4,  8, 1),   -- 2 Suç ve Ceza + Sapiens
    (5, 10, 3), (5,  9, 2),   -- 3 Ruj + 2 Yüz Kremi
    (6,  6, 1), (6,  4, 1),   -- Spor Ayakkabı + Kot Pantolon
    (7, 11, 1), (7, 12, 1),   -- Kahve Makinesi + Nevresim
    (8,  8, 2), (8,  7, 1),   -- 2 Sapiens + Suç ve Ceza
    (9,  3, 2),               -- 2 Kulaklık
    (10, 12, 1), (10, 4, 2);  -- Nevresim + 2 Kot Pantolon
GO

-- 4.6 TotalAmount değerlerinin sipariş detaylarından hesaplanması
-- (Toplam Tutar = Σ Quantity × Price). Böylece başlık ve detay tutarlı olur.
UPDATE o
SET    o.TotalAmount = d.Toplam
FROM   Orders AS o
INNER JOIN (
            SELECT od.OrderID, SUM(od.Quantity * p.Price) AS Toplam
            FROM   OrderDetails AS od
            INNER JOIN Products AS p ON p.ProductID = od.ProductID
            GROUP BY od.OrderID
           ) AS d ON d.OrderID = o.OrderID;
GO

-- 4.7 Kontrol: tablo bazında kayıt sayıları
SELECT 'Categories'   AS Tablo, COUNT(*) AS KayitSayisi FROM Categories   UNION ALL
SELECT 'Products',               COUNT(*)               FROM Products     UNION ALL
SELECT 'Customers',              COUNT(*)               FROM Customers    UNION ALL
SELECT 'Orders',                 COUNT(*)               FROM Orders       UNION ALL
SELECT 'OrderDetails',           COUNT(*)               FROM OrderDetails;
GO


/* =====================================================================
   BÖLÜM 5 – SORGULAMA VE ANALİZ (DQL)
   ===================================================================== */

-- GÖREV 1: STOK MİKTARI 20'DEN AZ OLAN ÜRÜNLER
-- Kritik stok seviyesindeki ürünler, stok miktarına göre artan sırada listelenir.
SELECT  ProductName,
        Stock
FROM    Products
WHERE   Stock < 20
ORDER BY Stock ASC;
GO

-- GÖREV 2: HANGİ MÜŞTERİ HANGİ TARİHTE SİPARİŞ VERDİ (INNER JOIN)
-- Customers ve Orders tabloları CustomerID üzerinden birleştirilir.
SELECT  c.FullName    AS [Müşteri Adı],
        c.City        AS [Şehir],
        o.OrderDate   AS [Sipariş Tarihi],
        o.TotalAmount AS [Toplam Tutar]
FROM    Customers AS c
INNER JOIN Orders AS o ON o.CustomerID = c.CustomerID
ORDER BY o.OrderDate;
GO

-- GÖREV 3: AHMET YILMAZ'IN SATIN ALDIĞI ÜRÜNLER (ÇOKLU JOIN)
-- Beş tablo birbirine bağlanarak müşterinin aldığı ürünler, fiyatları ve
-- kategorileri listelenir.
SELECT  p.ProductName  AS [Ürün Adı],
        p.Price        AS [Fiyat],
        cat.CategoryName AS [Kategori]
FROM    Customers    AS c
INNER JOIN Orders       AS o   ON o.CustomerID  = c.CustomerID
INNER JOIN OrderDetails AS od  ON od.OrderID    = o.OrderID
INNER JOIN Products     AS p   ON p.ProductID   = od.ProductID
INNER JOIN Categories   AS cat ON cat.CategoryID = p.CategoryID
WHERE   c.FullName = N'Ahmet Yılmaz'
ORDER BY o.OrderDate, p.ProductName;
GO

-- GÖREV 4: KATEGORİ BAZINDA ÜRÜN SAYISI (GROUP BY + COUNT + LEFT JOIN)
-- LEFT JOIN sayesinde ürünü olmayan kategoriler de 0 ürün ile listelenir.
-- COUNT(p.ProductID) NULL değerleri saymadığı için boş kategori 0 döner.
SELECT  cat.CategoryName   AS [Kategori],
        COUNT(p.ProductID) AS [Ürün Sayısı]
FROM    Categories AS cat
LEFT JOIN Products AS p ON p.CategoryID = cat.CategoryID
GROUP BY cat.CategoryName
ORDER BY [Ürün Sayısı] DESC, cat.CategoryName;
GO

-- GÖREV 5: MÜŞTERİ BAZINDA TOPLAM CİRO (GROUP BY + SUM + ORDER BY)
-- Her müşterinin tüm siparişlerinin toplam tutarı hesaplanır ve en çok
-- harcama yapan müşteriden en aza doğru sıralanır.
SELECT  c.FullName         AS [Müşteri Adı],
        COUNT(o.OrderID)   AS [Sipariş Sayısı],
        SUM(o.TotalAmount) AS [Toplam Ciro]
FROM    Customers AS c
INNER JOIN Orders AS o ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FullName
ORDER BY [Toplam Ciro] DESC;
GO

-- GÖREV 6: SİPARİŞLERİN ÜZERİNDEN GEÇEN GÜN SAYISI (DATEDIFF + GETDATE + DATEADD)
-- DATEDIFF ile sipariş tarihinden bugüne geçen gün sayısı hesaplanır.
-- DATEADD ile her siparişin 14 günlük iade süresinin bitiş tarihi bulunur.
SELECT  OrderID                              AS [Sipariş ID],
        OrderDate                            AS [Sipariş Tarihi],
        DATEDIFF(DAY, OrderDate, GETDATE())  AS [Geçen Gün Sayısı],
        DATEADD(DAY, 14, OrderDate)          AS [İade Son Tarihi]
FROM    Orders
ORDER BY OrderDate;
GO


/* =====================================================================
   BÖLÜM 6 – VIEW OLUŞTURMA
   vw_SiparisOzet: Müşteri adı, sipariş tarihi, ürün adı ve adet bilgisini
   tek bir sanal tabloda birleştirir.
   ===================================================================== */
IF OBJECT_ID(N'dbo.vw_SiparisOzet', N'V') IS NOT NULL
    DROP VIEW dbo.vw_SiparisOzet;
GO

CREATE VIEW dbo.vw_SiparisOzet
AS
SELECT  c.FullName    AS MusteriAdi,
        o.OrderDate   AS SiparisTarihi,
        p.ProductName AS UrunAdi,
        od.Quantity   AS Adet
FROM    Customers    AS c
INNER JOIN Orders       AS o  ON o.CustomerID = c.CustomerID
INNER JOIN OrderDetails AS od ON od.OrderID   = o.OrderID
INNER JOIN Products     AS p  ON p.ProductID  = od.ProductID;
GO

-- VIEW testi
SELECT  MusteriAdi, SiparisTarihi, UrunAdi, Adet
FROM    dbo.vw_SiparisOzet
ORDER BY SiparisTarihi, UrunAdi;
GO


/* =====================================================================
   BÖLÜM 7 – BACKUP (YEDEKLEME)
   Hedef: C:\Yedek\NovaStoreDB_Backup.bak

   ÖN KOŞULLAR (yedeklemeden önce manuel kontrol edilmelidir):
     1. C:\Yedek klasörü SQL Server'ın çalıştığı makinede mevcut olmalıdır.
        BACKUP komutu klasör oluşturmaz; klasör yoksa işlem hata verir.
     2. SQL Server servis hesabının (ör. NT Service\MSSQLSERVER) bu klasöre
        yazma (Modify) yetkisi olmalıdır. Klasör > Özellikler > Güvenlik
        sekmesinden kontrol edilir. LocalDB kullanılıyorsa işlem, oturum
        açan Windows kullanıcısının yetkisiyle yapılır.
     3. Komutu çalıştıran oturumun BACKUP DATABASE yetkisi (sysadmin,
        db_owner veya db_backupoperator) olmalıdır.

   Aşağıdaki blok klasörün varlığını sys.dm_os_file_exists ile kontrol eder;
   klasör yoksa yedek almaz ve uyarı mesajı verir.
   ===================================================================== */
USE master;
GO

IF EXISTS (SELECT 1
           FROM   sys.dm_os_file_exists(N'C:\Yedek')
           WHERE  file_is_a_directory = 1)
BEGIN
    BACKUP DATABASE NovaStoreDB
    TO DISK = N'C:\Yedek\NovaStoreDB_Backup.bak'
    WITH FORMAT,
         INIT,
         NAME  = N'NovaStoreDB - Tam Yedek',
         STATS = 10;

    -- Yedek dosyasının okunabilir ve geçerli olduğunu doğrular.
    RESTORE VERIFYONLY FROM DISK = N'C:\Yedek\NovaStoreDB_Backup.bak';
END
ELSE
BEGIN
    PRINT N'UYARI: C:\Yedek klasörü bulunamadı. Yedek ALINMADI.';
    PRINT N'Klasörü oluşturup SQL Server servis hesabına yazma yetkisi verdikten sonra bu bölümü tekrar çalıştırın.';
END
GO

/* ============================= SCRIPT SONU ============================= */
