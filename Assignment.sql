--2.1
SELECT * FROM Employee;
SELECT * FROM Employee WHERE lastname='King';
SELECT * FROM Employee WHERE firstname='Andrew' AND reportsto=null;

--2.2
SELECT * FROM Album ORDER BY TITLE DESC;
SELECT * FROM Customer ORDER BY city ASC;

--2.3
INSERT INTO Genre (GenreID, Name) VALUES (26, 'Elevator');
INSERT INTO Genre (GenreID, Name) VALUES (27, 'Punk Metal');

INSERT INTO Employee (EmployeeID, LastName, FirstName) VALUES((SELECT COUNT(*) FROM Employee) + 1, 'Fenstermacher', 'Jonathan');
INSERT INTO Employee (EmployeeID, LastName, FirstName) VALUES((SELECT COUNT(*) FROM Employee) + 1, 'McNugget', 'Master');

INSERT INTO Customer (CustomerID, FirstName, LastName, Company, Address, City, State, Country, PostalCode, Phone, Fax, Email) VALUES((SELECT COUNT(*) FROM Customer) + 1, 'Jonathan', 'Fenstermacher', 'Revature', 'Plaza Dr.', 'Reston', 'VA', 'US', '900', '9169999999', '9169999999', 'nope@gmail.com');
INSERT INTO Customer (CustomerID, FirstName, LastName, Email) VALUES((SELECT COUNT(*) FROM Customer) + 1, 'Master', 'McNugget', 'nope@gmail.com');

--2.4
UPDATE customer SET firstname='Robert', lastname='Walter' WHERE firstname='Aaron' AND lastname='Mitchell';
UPDATE artist SET name='CCR' WHERE name='Creedence Clearwater Revival';

--2.5
SELECT * FROM invoice WHERE billingaddress LIKE 'T%';

--2.6
SELECT * FROM invoice WHERE total BETWEEN 15 AND 50;
SELECT * FROM employee WHERE hiredate BETWEEN '01-June-2003' AND '01-Mar-2004';

--2.7
ALTER TABLE invoice DROP CONSTRAINT fk_invoicecustomerid;
ALTER TABLE invoice ADD CONSTRAINT fk_invoicecustomerid FOREIGN KEY (customerid) REFERENCES  customer(customerid) ON DELETE CASCADE;
ALTER TABLE invoiceline DROP CONSTRAINT fk_invoicelineinvoiceid;
ALTER TABLE invoiceline ADD CONSTRAINT fk_invoicelineinvoiceid FOREIGN KEY (invoiceid) REFERENCES invoice(invoiceid) ON DELETE CASCADE;
DELETE customer WHERE lastname='Walter' AND firstname='Robert';

--3.1
CREATE OR REPLACE FUNCTION ReturnTime
RETURN TIMESTAMP AS
DECLARE
    T TIMESTAMP;
BEGIN
    SELECT localtimestamp INTO T FROM dual;
    DBMS_OUTPUT.PUTLINE(T);
    RETURN T;
END;
/

--3.2
CREATE OR REPLACE FUNCTION RETURN_AVG_TOTAL
RETURN NUMBER AS Z NUMBER;
BEGIN
    SELECT AVG(total) INTO Z FROM invoice;
    RETURN Z;
END;
/

DECLARE
    I NUMBER;
BEGIN
    I := RETURN_AVG_TOTAL;
    DBMS_OUTPUT.PUT_LINE('RETURN TOTAL = ' || I);
END;
/

CREATE OR REPLACE FUNCTION Return_Expensive
RETURN NUMBER AS Z NUMBER;
BEGIN
    SELECT MAX(unitprice) INTO Z FROM track;
    RETURN Z;
END;
/

DECLARE
    maxUnit NUMBER;
BEGIN
    maxUnit := Return_Expensive;
    DBMS_OUTPUT.PUT_LINE('MAX UNIT PRICE = ' || maxUnit);
END;
/
--3.3
CREATE OR REPLACE FUNCTION AVG_PRICE_INVOICELINE
RETURN NUMBER AS MONEYS NUMBER;
BEGIN
    SELECT AVG(unitprice) INTO MONEYS FROM invoiceline;
    RETURN moneys;
END;
/

DECLARE
    AVG_UNITPRICE NUMBER;
BEGIN
    AVG_UNITPRICE := AVG_PRICE_INVOICELINE;
    DBMS_OUTPUT.PUT_LINE('AVG UNITPRICE = ' || AVG_UNITPRICE);
END;
/

--3.4
CREATE OR REPLACE FUNCTION EMPLOYEES_BORN_AFTER(birthYear NUMBER)
RETURN SYS_REFCURSOR IS mycursor SYS_REFCURSOR;
BEGIN
    OPEN mycursor FOR SELECT firstname, lastname FROM employee WHERE EXTRACT(YEAR FROM birthdate) > birthYear;
    RETURN mycursor;
END;
/

DECLARE
    dummy SYS_REFCURSOR;
    efirstname employee.firstname%TYPE;
    elastname employee.lastname%TYPE;
BEGIN
    dummy := EMPLOYEES_BORN_AFTER(1968);
    LOOP
        FETCH dummy INTO eFirstname, eLastname;
        EXIT WHEN dummy%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(eFirstname || ' '|| eLastname);
    END LOOP;
    CLOSE dummy;
END;
/

--4.1
CREATE OR REPLACE 
PROCEDURE PRINT_EMPLOYEES AS
mycursor SYS_REFCURSOR;
efirstname employee.firstname%TYPE;
elastname employee.lastname%TYPE;
BEGIN
    OPEN mycursor FOR SELECT employee.firstname, employee.lastname FROM employee;
    LOOP
        FETCH mycursor INTO efirstname, elastname;
        EXIT WHEN mycursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(efirstname || ' ' || elastname);
    END LOOP;
    CLOSE mycursor;
END;
/

BEGIN
    PRINT_EMPLOYEES;
END;
/

--4.2A
CREATE OR REPLACE PROCEDURE
UPDATE_EMPLOYEE(eid NUMBER, addre employee.address%TYPE) IS
BEGIN
    UPDATE employee SET address=addre WHERE employee.employeeid = eid;
END;
/

BEGIN
    UPDATE_EMPLOYEE(9,'2001 Drury Lane');
END;
/

--4.2B
CREATE OR REPLACE PROCEDURE
RETURN_MANAGER(eid NUMBER) IS
manager employee%ROWTYPE;
BEGIN
    SELECT * INTO manager FROM employee WHERE employee.employeeid = (SELECT reportsto FROM employee WHERE employee.employeeid = eid);
    DBMS_OUTPUT.PUT_LINE(manager.firstname || ' ' || manager.lastname);
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('This employee doesnt report to a manager');
END;
/

BEGIN
    RETURN_MANAGER(1);
END;
/

--4.3
CREATE OR REPLACE PROCEDURE
RETURN_NAME_AND_COMPANY(    cid IN NUMBER,
                            cfn OUT customer.firstname%TYPE,
                            cln OUT customer.lastname%TYPE,
                            cc OUT customer.company%TYPE)
IS
    currCust customer%ROWTYPE;
BEGIN
    SELECT * INTO currCust FROM customer WHERE customer.customerid = cid;
    cfn := currCust.firstname;
    cln := currCust.lastname;
    cc := currCust.company;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('This employee doesnt report to a manager');
END;
/

DECLARE
    firstname customer.firstname%TYPE;
    lastname customer.lastname%TYPE;
    company customer.company%TYPE;
BEGIN
    RETURN_NAME_AND_COMPANY(0, firstname, lastname, company);
    IF firstname%FOUND THEN
    DBMS_OUTPUT.PUT_LINE(firstname || ' ' || lastname || ' works for ' || company);
    END IF;
END;
/

--5.0A
CREATE OR REPLACE PROCEDURE
DELETE_INVOICE(i_id NUMBER) IS
BEGIN
    SAVEPOINT test;
    DELETE invoice WHERE invoiceid = i_id;   
    COMMIT;
END;
/

BEGIN
    DELETE_INVOICE(95);
END;
/

--5.0B
CREATE OR REPLACE PROCEDURE
INSERT_CUSTOMER(cid IN customer.customerid%TYPE,
                cfn IN customer.firstname%TYPE,
                cln IN customer.lastname%TYPE,
                cemail IN customer.email%TYPE)
IS
BEGIN
    SAVEPOINT beforeCustAdd;
    INSERT INTO customer (customerid, firstname, lastname, email) VALUES (cid, cfn, cln, cemail);
    COMMIT;
END;
/

BEGIN
    INSERT_CUSTOMER(63, 'Jonathan', 'Fenstermacher', 'something@google.com');
END;
/

--6.1A
CREATE OR REPLACE TRIGGER AFTER_EMPLOYEE_INSERT
AFTER INSERT ON customer
BEGIN
    DBMS_OUTPUT.PUT_LINE('New customer has been inserted');
END;
/

--6.2B
CREATE OR REPLACE TRIGGER AFTER_ALBUM_INSERT
AFTER INSERT ON album
BEGIN
    DBMS_OUTPUT.PUT_LINE('New album has been inserted');
END;
/

--6.3C
CREATE OR REPLACE TRIGGER AFTER_CUSTOMER_DELETE
AFTER DELETE ON customer
BEGIN
    DBMS_OUTPUT.PUT_LINE('A customer has been deleted');
END;
/

--7.1
SELECT customer.lastname, customer.firstname, invoice.invoiceID 
FROM customer 
INNER JOIN invoice ON customer.customerID = invoice.customerID;

--7.2
SELECT C.customerID, C.firstname, C.lastname, I.invoiceID, I.total
FROM customer C
FULL OUTER JOIN invoice I ON C.customerID = I.customerID;

--7.3
SELECT artist.name, album.title
FROM artist
RIGHT JOIN album ON artist.artistID = album.artistID;

--7.4
SELECT *
FROM album
CROSS JOIN artist
ORDER BY artist.name;

--7.5
SELECT A.lastname, A.employeeID, B.lastname, B.employeeID
FROM employee A, employee B
WHERE A.reportsto <> B.reportsto;

--7.6
SELECT *
FROM customer C INNER JOIN invoice i ON c.customerID = i.customerID
INNER JOIN invoiceline il ON i.invoiceID = il.invoiceID
INNER JOIN track t ON il.trackid = t.trackid
INNER JOIN employee e ON c.supportrepid = e.employeeID
INNER JOIN album al ON t.albumid = al.albumid
INNER JOIN mediatype mt ON t.mediatypeid = mt.mediatypeid
INNER JOIN genre g ON t.genreid = g.genreid
INNER JOIN playlisttrack plt ON t.trackid = plt.trackid
INNER JOIN playlist pl ON plt.playlistid = pl.playlistid;

--9.0
export.sql is database backup