-- 1. DDL
CREATE TABLE Users
(
	Id INT PRIMARY KEY IDENTITY,
	Username VARCHAR(30) NOT NULL UNIQUE,
	[Password] VARCHAR(50) NOT NULL,
	[Name] VARCHAR(50),
	Birthdate DATETIME,
	Age INT CHECK(Age BETWEEN 14 AND 110),
	Email VARCHAR(50) NOT NULL
)

CREATE TABLE Departments
(
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL
)

CREATE TABLE Employees
(
	Id INT PRIMARY KEY IDENTITY,
	FirstName VARCHAR(25),
	LastName VARCHAR(25),
	Birthdate DATETIME,
	Age INT CHECK(Age BETWEEN 18 AND 110),
	DepartmentId INT REFERENCES Departments(Id)
)

CREATE TABLE Categories
(
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	DepartmentId INT NOT NULL REFERENCES Departments(Id)
)


CREATE TABLE [Status]
(
	Id INT PRIMARY KEY IDENTITY,
	[Label] VARCHAR(30) NOT NULL
)

CREATE TABLE Reports
(
	Id INT PRIMARY KEY IDENTITY,
	CategoryId INT NOT NULL REFERENCES Categories(Id),
	StatusId INT NOT NULL REFERENCES [Status](Id),
	OpenDate DATETIME NOT NULL,
	CloseDate DATETIME,
	[Description] VARCHAR(200) NOT NULL,
	UserId INT NOT NULL REFERENCES Users(Id),
	EmployeeId INT REFERENCES Employees(Id)
)

-- 2. INSERT
INSERT INTO Employees (FirstName, LastName, Birthdate, DepartmentId) VALUES
('Marlo', 'O''Malley', '1958/9/21', 1),
('Niki', 'Stanaghan', '1969/11/26', 4),
('Ayrton', 'Senna', '1960/03/21', 9),
('Ronnie', 'Paterson', '1944/02/14', 9),
('Giovanna', 'Amati', '1959/07/20', 5)

INSERT INTO Reports (CategoryId, StatusId, OpenDate, CloseDate, [Description], UserId, EmployeeId) VALUES
(1,	1, '2017/04/13', NULL, 'Stuck Road on Str.133', 6, 2),
(6,	3, '2015/09/05', '2015/12/06', 'Charity trail running', 3, 5),
(14, 2, '2015/09/07', NULL, 'Falling bricks on Str.58', 5, 2),
(4, 3, '2017/07/03', '2017/07/06', 'Cut off streetlight on Str.11', 1, 1)


-- 3. UPDATE
UPDATE Reports
SET CloseDate = GETDATE()
	WHERE CloseDate IS NULL

-- 4. DELETE
DELETE FROM Reports
	WHERE StatusId = 4

-- 5. Unassigned Reports
SELECT [Description], FORMAT(OpenDate, 'dd-MM-yyyy') FROM Reports
	WHERE EmployeeId IS NULL
	ORDER BY OpenDate, [Description]

-- 6. Reports & Categories
SELECT [Description], c.[Name] AS CategoryName FROM Reports AS r
	JOIN Categories AS c ON r.CategoryId = c.Id
	WHERE CategoryId IS NOT NULL
	ORDER BY [Description], CategoryName

-- 7. Most Reported Category
SELECT TOP(5) c.[Name], COUNT(CategoryId) FROM Reports AS r
	JOIN Categories AS c ON r.CategoryId = c.Id
	GROUP BY c.[Name]
	ORDER BY COUNT(CategoryId) DESC, c.[Name]

-- 8. Birthday Report
SELECT u.Username, c.[Name] AS CategoryName FROM Users AS u
	JOIN Reports AS r ON r.UserId = u.Id
	JOIN Categories AS c ON r.CategoryId = c.Id
	WHERE MONTH(u.Birthdate) = MONTH(r.OpenDate) AND
		DAY(u.Birthdate) = DAY(r.OpenDate)
	ORDER BY u.Username, CategoryName

-- 9. User per Employee
SELECT e.FirstName + ' ' + e.LastName AS FullName, COUNT(r.UserId) AS UsersCount
	FROM Employees	AS e
		LEFT JOIN Reports AS r ON e.Id = r.EmployeeId
		LEFT JOIN Users AS u ON r.UserId = u.Id
		GROUP BY e.FirstName + ' ' + e.LastName
		ORDER BY UsersCount DESC, FullName

-- 10. Full Info
SELECT 
	(
		CASE
		WHEN e.FirstName IS NULL THEN 'None'
		ELSE
		e.FirstName + ' ' + e.LastName
		END
	) AS Employee,
	(
		CASE
		WHEN d.[Name] IS NULL THEN 'None'
		ELSE
		d.[Name]
		END
	) AS Department, c.[Name] AS Category,
		r.[Description], FORMAT(r.OpenDate, 'dd.MM.yyyy') AS OpenDate,
		s.[Label] AS [Status], u.[Name] AS [User]
	FROM Reports AS r
		LEFT JOIN Employees AS e ON r.EmployeeId = e.Id
		LEFT JOIN Categories AS c ON r.CategoryId = c.Id
		LEFT JOIN Departments AS d ON e.DepartmentId = d.Id
		LEFT JOIN [Status] AS s ON r.StatusId = s.Id
		LEFT JOIN Users AS u ON r.UserId = u.Id
	ORDER BY e.FirstName DESC, e.LastName DESC, Department, Category, r.[Description],
		OpenDate, [Status], [User]


-- 11. Hours to Complete
CREATE FUNCTION udf_HoursToComplete(@StartDate DATETIME, @EndDate DATETIME)
RETURNS INT
AS
BEGIN
	DECLARE @difference INT;

	IF(@StartDate IS NULL OR @EndDate IS NULL)
		RETURN 0
	ELSE
		SET @difference = DATEDIFF(HOUR, @StartDate, @EndDate);
	RETURN @difference;
END

-- 12. Assign Employee
CREATE PROC usp_AssignEmployeeToReport(@EmployeeId INT, @ReportId INT)
AS
BEGIN 
	BEGIN TRY
		DECLARE @EmployeeDepartmentId INT = (SELECT DepartmentId FROM Employees WHERE Id = @EmployeeId);
		DECLARE @ReportDepartmentId INT = 
		(
			SELECT d.Id FROM Reports AS r
				JOIN Categories AS c ON r.CategoryId = c.Id
				JOIN Departments AS d ON c.DepartmentId = d.Id
				WHERE r.Id = @ReportId
		);

		IF(@EmployeeDepartmentId = @ReportDepartmentId)
			BEGIN
				UPDATE Reports
					SET EmployeeId = @EmployeeDepartmentId
					WHERE Id = @ReportDepartmentId
			END
		ELSE
			THROW 50001, 'Employee doesn''t belong to the appropriate department!', 1;
	END TRY
	BEGIN CATCH
		PRINT 'Employee doesn''t belong to the appropriate department!';
		THROW
	END CATCH
END