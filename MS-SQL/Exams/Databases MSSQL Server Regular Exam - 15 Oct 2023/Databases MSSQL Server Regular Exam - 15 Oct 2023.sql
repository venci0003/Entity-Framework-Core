CREATE DATABASE TouristAgency

USE TouristAgency

CREATE TABLE Countries(
Id INT PRIMARY KEY IDENTITY,
[Name] NVARCHAR(50) NOT NULL
)

CREATE TABLE Destinations(
Id INT PRIMARY KEY IDENTITY,
[Name] NVARCHAR(50) NOT NULL,
CountryId INT FOREIGN KEY REFERENCES Countries(Id) NOT NULL
)

CREATE TABLE Rooms(
Id INT PRIMARY KEY IDENTITY,
[Type] NVARCHAR(40) NOT NULL,
Price DECIMAL(18,2) NOT NULL,
BedCount INT CHECK(BedCount > 0 AND BedCount <= 10) NOT NULL
)

CREATE TABLE Hotels(
Id INT PRIMARY KEY IDENTITY,
[Name] NVARCHAR(50) NOT NULL,
DestinationId INT FOREIGN KEY REFERENCES Destinations(Id) NOT NULL
)

CREATE TABLE Tourists(
Id INT PRIMARY KEY IDENTITY,
[Name] NVARCHAR(80) NOT NULL,
PhoneNumber NVARCHAR(20) NOT NULL,
Email NVARCHAR(80),
CountryId INT FOREIGN KEY REFERENCES Countries(Id) NOT NULL
)

CREATE TABLE Bookings(
Id INT PRIMARY KEY IDENTITY,
ArrivalDate DATETIME2 NOT NULL,
DepartureDate DATETIME2 NOT NULL,
AdultsCount INT CHECK(AdultsCount >= 1 AND AdultsCount <= 10) NOT NULL,
ChildrenCount INT CHECK(ChildrenCount >= 0 AND ChildrenCount <= 9) NOT NULL,
TouristId INT FOREIGN KEY REFERENCES Tourists(Id) NOT NULL,
HotelId INT FOREIGN KEY REFERENCES Hotels(Id) NOT NULL,
RoomId INT FOREIGN KEY REFERENCES Rooms(Id) NOT NULL
)

CREATE TABLE HotelsRooms(
HotelId INT NOT NULL,
RoomId INT NOT NULL,
PRIMARY KEY(HotelId,RoomId),
FOREIGN KEY(HotelId) REFERENCES Hotels(Id),
FOREIGN KEY(RoomId) REFERENCES Rooms(Id)
)

INSERT INTO Tourists([Name], PhoneNumber, Email, CountryId)
VALUES ('John Rivers', '653-551-1555', 'john.rivers@example.com', 6),
       ('Adeline Aglaé', '122-654-8726', 'adeline.aglae@example.com', 2),
       ('Sergio Ramirez', '233-465-2876', 's.ramirez@example.com', 3),
       ('Johan Müller', '322-876-9826 ', 'j.muller@example.com', 7),
       ('Eden Smith', '551-874-2234', 'eden.smith@example.com', 6)

INSERT INTO Bookings(ArrivalDate, DepartureDate, AdultsCount, ChildrenCount, TouristId, HotelId, RoomId)
VALUES ('2024-03-01', '2024-03-11', 1, 0, 21, 3, 5),
       ('2023-12-28', '2024-01-06', 2, 1, 22, 13, 3),
       ('2023-11-15', '2023-11-20', 1, 2, 23, 19, 7),
       ('2023-12-05', '2023-12-09', 4, 0, 24, 6, 4),
       ('2024-05-01', '2024-05-07', 6, 0, 25, 14, 6)

UPDATE Bookings
SET DepartureDate = DATEADD(DAY, 1, DepartureDate)
WHERE MONTH(DepartureDate) = 12 AND YEAR(DepartureDate) = 2023

UPDATE Tourists
SET Email = NULL
WHERE [Name] LIKE '%MA%'

SELECT TouristId FROM Bookings AS b
JOIN Tourists AS t ON t.Id = b.TouristId
WHERE SUBSTRING(t.[Name], CHARINDEX(' ', t.[Name]) + 1, LEN(t.[Name])) LIKE 'Smith'

DELETE Bookings
WHERE TouristId IN (6,25)

DELETE Tourists 
WHERE SUBSTRING([Name], CHARINDEX(' ', [Name]) + 1, LEN([Name])) LIKE 'Smith'

SELECT FORMAT(ArrivalDate, 'yyyy-MM-dd') AS ArrivalDate,b.AdultsCount,b.ChildrenCount FROM Bookings AS b
JOIN Rooms AS r ON r.Id = b.RoomId
ORDER BY r.Price DESC, b.ArrivalDate

SELECT h.Id,h.[Name] FROM Hotels AS h
JOIN HotelsRooms AS hr ON hr.HotelId = h.Id
JOIN Rooms AS r ON r.Id = hr.RoomId
JOIN Bookings AS b ON b.HotelId = h.Id
WHERE r.[Type] = 'VIP Apartment'
GROUP BY h.[Name],h.Id
ORDER BY COUNT(b.Id) DESC

SELECT t.Id, t.[Name], t.PhoneNumber FROM Tourists AS t
LEFT JOIN Bookings AS b ON b.TouristId = t.Id
WHERE b.ArrivalDate IS NULL
ORDER BY t.[Name] ASC

SELECT TOP(10) h.[Name] AS [HotelName], d.[Name] AS [DestinationName], c.[Name] AS [CountryName] FROM Bookings AS b
JOIN Hotels AS h ON h.Id = b.HotelId
JOIN Destinations AS d ON d.Id = h.DestinationId
JOIN Countries AS c ON d.CountryId = c.Id
WHERE b.HotelId % 2 != 0
ORDER BY c.[Name], b.ArrivalDate

SELECT 
   H.[Name],
   R.Price
FROM Tourists AS T
INNER JOIN Bookings AS B ON B.TouristId = T.Id
INNER JOIN Hotels AS H ON B.HotelId = H.Id
INNER JOIN Rooms AS R ON B.RoomId = R.Id
WHERE T.[Name] NOT LIKE '%EZ'
ORDER BY R.Price DESC;

SELECT
    H.[Name] AS HotelName,
    SUM((DATEDIFF(DAY, B.ArrivalDate, B.DepartureDate) * R.Price)) AS TotalRevenue
FROM Hotels H
JOIN Bookings B ON H.Id = B.HotelId
JOIN Rooms R ON B.RoomId = R.Id
GROUP BY H.[Name]
ORDER BY TotalRevenue DESC;

CREATE FUNCTION udf_RoomsWithTourists(@name NVARCHAR(50))
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT SUM(b.AdultsCount + b.ChildrenCount)
        FROM Bookings b
            JOIN Tourists t ON b.TouristId = t.Id
            JOIN Rooms r ON r.Id = b.RoomId
        WHERE r.Type = @name
    )
END

CREATE PROCEDURE usp_SearchByCountry(@country NVARCHAR(100))
AS
BEGIN

SELECT t.[Name], t.PhoneNumber, t.Email, COUNT(b.Id) AS [CountOfBookings] FROM Tourists AS t
JOIN Bookings AS b ON t.Id = b.TouristId
JOIN Countries AS c ON t.CountryId = c.Id
WHERE c.[Name] = @country
GROUP BY t.[Name], t.PhoneNumber,t.Email
ORDER BY t.[Name], [CountOfBookings] DESC
END

  
