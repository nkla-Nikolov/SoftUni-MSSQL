CREATE TABLE Majors
(
	MajorID INT IDENTITY PRIMARY KEY,
	[Name] NVARCHAR(100) NOT NULL
)

CREATE TABLE Students
(
	StudentID INT IDENTITY PRIMARY KEY,
	StudentNumber NVARCHAR(50) UNIQUE,
	StudentName NVARCHAR(50) NOT NULL,
	MajorID INT REFERENCES Majors(MajorID)
)

CREATE TABLE Payments
(
	PaymentID INT IDENTITY PRIMARY KEY,
	PaymentDate DATE NOT NULL,
	PaymentAmount DECIMAL(10, 2) NOT NULL,
	StudentID INT REFERENCES Students(StudentID)
)

CREATE TABLE Subjects
(
	SubjectID INT IDENTITY PRIMARY KEY,
	SubjectName NVARCHAR(100) NOT NULL
)

CREATE TABLE Agenda
(
	StudentID INT REFERENCES Students(StudentID) NOT NULL,
	SubjectID INT REFERENCES Subjects(SubjectID) NOT NULL,
	PRIMARY KEY(StudentID, SubjectID)
)