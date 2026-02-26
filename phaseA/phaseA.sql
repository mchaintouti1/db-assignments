---------------------------------------2.1---------------------------------------
CREATE OR REPLACE FUNCTION insert_person()
RETURNS character varying AS
$$
DECLARE
	new_amka character varying;
	same boolean := false;
	email character varying(30);
	greekToEng character varying;
	tuc character varying := '@tuc.gr';
	new_email character varying(30);
	lastAMKAints character varying;
BEGIN
	LOOP
		--Create new amka
		SELECT INTO new_amka string_agg(FLOOR(RANDOM()*10) :: text, '') FROM generate_series(1, 11); 
		SELECT INTO same EXISTS(SELECT 1 FROM "Person" 	WHERE amka = new_amka);
		EXIT WHEN NOT same;
	END LOOP;
	
	INSERT INTO "Person"(name, amka, surname, father_name)
	VALUES((SELECT name FROM "Name" ORDER BY RANDOM() LIMIT 1),
		   new_amka, 
		  (SELECT surname FROM "Surname" ORDER BY RANDOM() LIMIT 1),
		  (SELECT name FROM "Name" ORDER BY RANDOM() LIMIT 1));
	
	--Create new email
	SELECT surname INTO greekToEng FROM "Person" WHERE amka = new_amka;
	email := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(greekToEng, 'Α', 'a'), 'Β', 'b'), 'Γ', 'g'), 'Δ', 'd'),'Ε', 'e'),'Ζ', 'z'), 'Η', 'i'),'Θ', 'th'), 'Ι', 'i'), 'Κ', 'k'), 'Λ', 'l'), 'Μ', 'm'), 'Ν', 'n'), 'Ξ', 'ks'), 'Ο', 'o'), 'Π', 'p'), 'Ρ', 'r'), 'Σ', 's'), 'Τ', 't'), 'Υ', 'y'), 'Φ', 'f'), 'Χ','x'), 'Ψ', 'ps'), 'Ω', 'o');
	SELECT amka INTO lastAMKAints FROM "Person" WHERE amka = new_amka;
	new_email := email|| right(lastAMKAints, 4) || tuc;
	UPDATE "Person" SET email = new_email WHERE amka = new_amka;
	RETURN new_amka;
END;
$$
LANGUAGE plpgsql;

------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION insert_professors(num_records INTEGER) RETURNS VOID AS
$$
BEGIN
  FOR i IN 1..num_records LOOP
    --Choosing random rank types
  	WITH rand_type AS(
  		SELECT unnest(enum_range(null :: public.rank_type)) AS rank offset FLOOR(RANDOM()*4) LIMIT 1)
		
    -- Εισαγωγή δεδομένων στον πίνακα "Professor"
    INSERT INTO "Professor" (amka, labjoins, rank)
    VALUES (insert_person(),
			(SELECT lab_code FROM "Lab" ORDER BY RANDOM() LIMIT 1),
			(SELECT rank FROM rand_type));
  END LOOP;
END;
$$
LANGUAGE plpgsql;

------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION insert_lab_staff(num_staff integer)
RETURNS VOID AS $$
BEGIN
    FOR i IN 1..num_staff LOOP
    --Choosing random rank types
  	WITH  lab_staff_type AS(
  		SELECT unnest(enum_range(null :: public.level_type)) AS level offset FLOOR(RANDOM()*4) LIMIT 1)
		
    -- Εισαγωγή δεδομένων στον πίνακα "Professor"
    INSERT INTO "LabTeacher" (amka, labworks, level)
    VALUES (insert_person(),
			(SELECT lab_code FROM "Lab" ORDER BY RANDOM() LIMIT 1),
			(SELECT level FROM lab_staff_type));
  END LOOP;
END;
$$
LANGUAGE plpgsql;
  
------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION insert_students(new_num_records INTEGER, entryDate DATE)
RETURNS VOID AS
$$
DECLARE
  i integer := 1;
  year integer;
  new_am character(10);
  amountOfInserted integer;
  IOstudent integer;
  lastFiveDigits character(5);
BEGIN 
	SELECT EXTRACT(YEAR FROM entryDate) INTO year;
	--FOR i IN 1..new_num_records
	WHILE i<= new_num_records
	LOOP
	IOstudent := CASE WHEN RANDOM()<0.5 THEN 0
				 ELSE 1
				 END;
				 
	SELECT COUNT(*) INTO amountOfInserted FROM "Student" WHERE EXTRACT(YEAR FROM entry_date) = year;
	
	amountOfInserted = amountOfInserted +1;
	lastFiveDigits := LPAD(amountOfInserted::text, 5, '0');
	new_am := year::text || IOstudent::text || lastFiveDigits;
	
	INSERT INTO "Student" (amka, entry_date, am)
	VALUES(insert_person(),
		   entryDate,
		   new_am);
	i := i+1;
	END LOOP;
END;
$$
LANGUAGE plpgsql;

---------------------------------------2.2---------------------------------------
CREATE OR REPLACE FUNCTION insert_grades(semester_code integer)
RETURNS VOID AS $$
DECLARE
    exam_grade integer;
    lab_grade integer;
BEGIN
	UPDATE "Register" r SET exam_grade = FLOOR(RANDOM()*10)+1 
	FROM "CourseRun" cr 
	WHERE r.serial_number = cr.serial_number AND r.course_code = cr.course_code AND cr.semesterrunsin = semester_code 
		AND	r.exam_grade IS NULL;
		
	UPDATE "Register" r SET lab_grade = FLOOR(RANDOM()*10)+1 
	FROM "CourseRun" cr 
	WHERE r.serial_number = cr.serial_number AND r.course_code = cr.course_code AND cr.semesterrunsin = semester_code 
		AND	r.lab_grade IS NULL AND cr.labuses IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

---------------------------------------2.3---------------------------------------
CREATE OR REPLACE FUNCTION insert_program(
	p_program_type integer,
	p_language character varying,
	p_season character varying,
	p_start_year character(4),
	p_duration integer,
	p_obligatory boolean)
RETURNS void AS $$
DECLARE
	max_year character(4);
	program_id integer;
BEGIN
	--Check for the most recent start year per type
	SELECT MAX("Year"::int) INTO max_year FROM public."Program";
	IF prog_year::int<max_year THEN
   		Raise Exception 'A program in a more recent year already exists';
	ELSIF prog_year::int= max_year AND EXISTS(SELECT 1 FROM public."Program"
   		WHERE "Program"."DiplomaType"=dig_type) THEN
    	Raise Exception 'A similar program already exists';
	END IF;
	
	--Insert program
	INSERT INTO "Program"("Duration", "MinCourses", "MinCredits", "Obligatory", "CommitteeNum", "DiplomaType", "NumOfParticipants", "Year")
	VALUES (p_duration, NULL, NULL, p_obligatrorym NULL, diploma_type(p_program_type), NULL, p_start_year)
	RETURNING "ProgramID" INTO program_id;
	
	--Get the new program id
	SELECT "ProgramID" INTO program_id
    FROM "Program"
    WHERE "Year" = p_start_year
    AND "DiplomaType" = CASE p_program_type
                            WHEN 1 THEN 'degree'
                            WHEN 2 THEN 'diploma'
                            WHEN 3 THEN 'certificate'
                          END;

	--Typical Program: Insert students and courses that have been registered 
	IF p_program_type = 1 THEN
	--Courses
	INSERT INTO "Course"("course_code", "course_title", "units", "lecture_hours", "tutorial_hours", "lab_hours", "typical_year", "typical_season", "obligatory", "course_description")
	SELECT "course_code", "course_title", "units", "lecture_hours", "tutorial_hours", "lab_hours", "typical_year", "typical_season", "obligatory", "course_description"
	FROM "Course"
	JOIN public."CourseRun" cr ON c.course_code = cr.course_code
    JOIN public."Semester" s ON cr.semesterrunsin = s.semester_id
	WHERE "typical_year" >= p_start_year :: integer;
	--Students
	INSERT INTO "Students"(amka, entry_date, am)
	SELECT "amka, "entry_date", "am"
	FROM public."Student" std
	WHERE EXTRACT(YEAR FROM entry_date) >= p_start_year :: integer
	AND amka NOT IN(
		SELECT th.StudentAMKA
		FROM "Thesis" th
		JOIN "Committee" com ON th.ThesisID = com.ThesisID
		WHERE th.StudentAMKA = std.amka)
	AND amka NOT IN (
		SELECT d.StudentAMKA
		FROM "Diploma" d
		WHERE d.StudentAMKA = std.amka)
	AND amka NOT IN(
		SELECT fl.ProgramID
		FROM "ForeignLanguageProgram" fl
		WHERE fl.ProgramID = program_id);
	ELSIF program_type = 2 THEN
    --Insert students
    INSERT INTO public."Student" ("amka", "am", "entry_date")
    SELECT "amka", "am", "entry_date"
    FROM public."Student" std
    WHERE EXTRACT(YEAR FROM "entry_date") >= start_year::integer
    AND "amka" NOT IN (
        SELECT th.StudentAMKA
        FROM public."Thesis" th
        JOIN public."Committee" com ON th.ThesisID = com.ThesisID
        WHERE th.StudentAMKA = std.amka
    )
    AND "amka" NOT IN (
        SELECT d.StudentAMKA
        FROM public."Diploma" d
        WHERE d.StudentAMKA = std.amka
    )
    AND "amka" NOT IN (
        SELECT fl.ProgramID
		FROM "ForeignLanguageProgram" fl
		WHERE fl.ProgramID = program_id
    );
	ELSIF program_type = 3 THEN
    --Insert students
   INSERT INTO "Students"(amka, entry_date, am)
	SELECT "amka, "entry_date", "am"
	FROM public."Student" std
	WHERE EXTRACT(YEAR FROM entry_date) >= p_start_year :: integer
	AND amka NOT IN(
		SELECT th.StudentAMKA
		FROM "Thesis" th
		JOIN "Committee" com ON th.ThesisID = com.ThesisID
		WHERE th.StudentAMKA = std.amka)
	AND amka NOT IN (
		SELECT d.StudentAMKA
		FROM "Diploma" d
		WHERE d.StudentAMKA = std.amka)
	AND amka NOT IN(
		SELECT fl.ProgramID
		FROM "ForeignLanguageProgram" fl
		WHERE fl.ProgramID = program_id);
END;
$$ LANGUAGE plpgsql;


---------------------------------------3.1---------------------------------------
CREATE OR REPLACE FUNCTION getInfo(stud_am character)
RETURNS TABLE(name character varying, surname character varying, amka character varying, am character, entry_date date) AS $$
BEGIN
RETURN QUERY
	SELECT p.name,p.surname,st.amka,st.am,st.entry_date
	FROM "Person" p
	JOIN "Student" st ON p.amka = st.amka
	WHERE st.am = stud_am
	GROUP BY(p.name,p.surname,st.amka,st.am,st.entry_date);
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION PUBLIC.getInfo(stud_am character) OWNER TO POSTGRES;


---------------------------------------3.2---------------------------------------			
CREATE OR REPLACE FUNCTION GetStudentsByCourseCode(code character)
RETURNS TABLE(name character varying, surname character varying, am character(10)) AS $$
BEGIN
    RETURN QUERY
    SELECT pr.name, pr.surname, st.am
    FROM "Register" r
	JOIN "Student" st ON r.amka = st.amka
	JOIN "Person" pr ON st.amka = pr.amka
    JOIN "CourseRun" cr ON r.course_code = cr.course_code AND r.serial_number = cr.serial_number
    JOIN "Semester" s ON cr.semesterrunsin = s.semester_id
    WHERE s.semester_status = 'present' AND r.course_code = code;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION PUBLIC.GetStudentsByCourseCode(code character) OWNER TO POSTGRES;

---------------------------------------3.3---------------------------------------	
CREATE OR REPLACE FUNCTION getCharactersisms()
RETURNS TABLE(name character varying, surname character varying, role character varying) AS $$
BEGIN
SELECT p.name, p.surname, 
       CASE WHEN pr.amka IS NOT NULL THEN 'Professor'
            WHEN s.amka IS NOT NULL THEN 'Student'
            ELSE 'Lab Staff'
       END AS role
FROM public."Person" p
LEFT JOIN public."Professor" pr ON p.amka = pr.amka
LEFT JOIN public."Student" s ON p.amka = s.amka;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION PUBLIC.getCharactersisms() OWNER TO POSTGRES; 

---------------------------------------3.4---------------------------------------	
CREATE OR REPLACE FUNCTION oblig_courses(program_code integer, st_amka character varying)
RETURNS TABLE(course_code character) AS $$
BEGIN
	RETURN QUERY
	
	SELECT c.course_title
	FROM "Course" c	
	JOIN "ProgramOffersCourse" poc ON c.course_code = poc."CourseCode"
	JOIN "Register" r ON c.course_code = r.course_code
	WHERE poc."ProgramID" = program_code AND r.register_status!='pass' AND c.obligatory = true AND r.amka = st_amka;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION PUBLIC.oblig_courses() OWNER TO POSTGRES;

---------------------------------------3.5---------------------------------------	
CREATE OR REPLACE FUNCTION getSectorsEx()
RETURNS TABLE(sector_code integer, dipl_type diploma_type, NumOfThesis integer) AS $$
BEGIN
RETURN QUERY
	SELECT l.sector_code, p."DiplomaType", count(*) as "NumOfThesis"
	FROM "Thesis" t
	JOIN "Program" p ON t."ProgramID" = p."ProgramID"
	JOIN "Lab" l ON l.lab_code = substring(t."StudentAMKA" from 1 for 2)::integer
	JOIN "Committee" com ON com."ThesisID" = t."ThesisID"
	WHERE com."Supervisor" = 'true'
	GROUP BY l.sector_code, p."DiplomaType";
END;
$$
LANGUAGE plpgsql;

ALTER FUNCTION PUBLIC.getSectorsEx() OWNER TO POSTGRES;

---------------------------------------3.6---------------------------------------
CREATE OR REPLACE FUNCTION retrieve_student_amka()
RETURNS TABLE("StudentAMKA" character varying) AS
$$
BEGIN
    RETURN QUERY
    SELECT th."StudentAMKA"
    FROM "Thesis" th
    WHERE th."StudentAMKA" NOT IN (
        SELECT d."StudentAMKA"
        FROM "Diploma" d
    ) AND th."Grade" >= 5.0;
    RETURN;
END;
$$ LANGUAGE plpgsql;


---------------------------------------3.7---------------------------------------
CREATE OR REPLACE FUNCTION getLabHours()
RETURNS TABLE (amka character varying, surname character varying, name character varying, total_lab_hours numeric) AS $$
BEGIN
	RETURN QUERY
	SELECT per.amka, per.surname, per.name, CAST(SUM(c."lab_hours") AS numeric) AS total_lab_hours
	FROM "Person" per
	LEFT JOIN "LabTeacher" l ON per.amka = l.amka
	LEFT JOIN "Supports" t ON t.amka = l.amka
	LEFT JOIN "CourseRun" cr ON cr.course_code = t.course_code AND cr.serial_number = t.serial_number
	LEFT JOIN "Course" c ON c.course_code = cr.course_code
	LEFT JOIN "Semester" s ON s.semester_id = cr.semesterrunsin
	WHERE s.semester_status = 'present'
	GROUP BY per.amka, per.surname, per.name;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION PUBLIC.getLabHours() OWNER TO POSTGRES;

---------------------------------------3.8---------------------------------------
CREATE OR REPLACE FUNCTION getReqSubs(code character)
RETURNS TABLE(course_code character(7), course_title character(100)) AS $$
BEGIN
RETURN QUERY
	SELECT c.course_code, c.course_title
	FROM "Course" c
	JOIN "Course_depends" cd ON cd.dependent = c.course_code
	WHERE cd.main = code AND cd.mode IN ('required', 'recommended')
	UNION
	SELECT c.course_code, c.course_title
	FROM "Course" c
	JOIN "Course_depends" cd1 ON cd1.dependent = c.course_code
	JOIN "Course_depends" cd2 ON cd2.dependent = cd1.main
	WHERE cd2.main = code AND cd2.mode IN ('required', 'recommended');
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION PUBLIC.getReqSubs(code character) OWNER TO POSTGRES;

---------------------------------------3.9---------------------------------------
CREATE OR REPLACE FUNCTION find_teachers()
RETURNS TABLE("professor_name" character varying) AS
$$
BEGIN
	RETURN QUERY
	SELECT prof.amka
	FROM "Professor" prof
	WHERE prof.amka IN (
		SELECT com."ProfessorAMKA"
    	FROM "Committee" com
    	JOIN "Thesis" th ON com."ThesisID" = th."ThesisID"
    	JOIN "Program" pro ON th."ProgramID" = pro."ProgramID"
    	GROUP BY com."ProfessorAMKA"
    	HAVING COUNT(DISTINCT th."ThesisID") = COUNT(DISTINCT pro."DiplomaType")
	);
  RETURN;
END;
$$ LANGUAGE plpgsql;

---------------------------------------4.1.1---------------------------------------
CREATE OR REPLACE FUNCTION check_semester()
RETURNS TRIGGER AS $$
DECLARE
    overlapping_semester_exists boolean;
BEGIN
    --Check if there is an overlap in another semester
    SELECT EXISTS (
        SELECT 1
        FROM public."Semester"
        WHERE semester_status = 'present' AND
              NEW.start_date < end_date AND
              NEW.end_date > start_date
    ) INTO overlapping_semester_exists;

    IF overlapping_semester_exists THEN
        RAISE EXCEPTION 'Invalid semester dates. The new semester overlaps with another registered semester.';
    END IF;

    --Check if it the time applys with the current semester
    IF NEW.semester_status = 'future' AND
       EXISTS (
           SELECT 1
           FROM public."Semester"
           WHERE semester_status = 'present' AND
                 NEW.start_date < start_date
       ) THEN
        RAISE EXCEPTION 'Invalid semester order. The new semester should follow the current semester.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
		
CREATE TRIGGER validate_semester
BEFORE INSERT OR UPDATE ON "Semester"
FOR EACH ROW
EXECUTE FUNCTION check_semester();

---------------------------------------4.1.2---------------------------------------
CREATE OR REPLACE FUNCTION update_current_semester()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.semester_status = 'present' AND OLD.semester_status = 'future' THEN
	UPDATE public."Semester"
	SET smester_status = 'past'
	WHERE semester_status = 'present';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_current_semester
AFTER UPDATE ON public."Semester"
FOR EACH ROW
EXECUTE FUNCTION update_current_semester();

---------------------------------------4.1.3---------------------------------------
CREATE OR REPLACE FUNCTION update_semester()
RETURNS TRIGGER AS $$
DECLARE
	present_semester integer;
BEGIN
	--Check if the semester that changes is 'future' and the new status is 'present'
	IF NEW.semester_status = 'present' AND OLD.semester_status = 'future' THEN
	--Check if already exist semesters with status 'present'
	SELECT COUNT(*) INTO present_semester
	FROM "Semester"
	WHERE semester_status = 'present';
	
	--If there is at least one semester in 'present' status, we reject the update
	IF present_semester > 0 THEN
	RAISE EXCEPTION 'Cannot have more than one semester in "present" status';
	END IF;
	
	--Delete students for the running semester
	DELETE FROM "Register"
	WHERE amka IN (SELECT amka FROM "Student")
	AND course_code IN (SELECT course_code FROM "CourseRun" WHERE semester_id = NEW.semestr_id);
	
	--Create recommended enrollments for students' courses of the running semester
	INSERT INTO "Register"(amka, course_code, register_status)
	SELECT s.amka, cr.course_code, 'proposed'
	FROM "Student" s, "CourseRun" cr
	WHERE cr.semester_id = NEW.semester_id;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_semester_trigger
AFTER UPDATE ON public."Semester"
FOR EACH ROW
EXECUTE FUNCTION update_semester();

---------------------------------------4.1.4---------------------------------------
CREATE OR REPLACE FUNCTION update_register_grades()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the semester status has changed to 'past'
    IF NEW.semester_status = 'past' AND OLD.semester_status = 'present' THEN
        -- Estimate the final grades and the status (pass/fail)
        UPDATE public."Register" r
        SET r.final_grade = (
                CASE
                    WHEN NEW.exam_grade IS NOT NULL AND NEW.lab_grade IS NOT NULL THEN ((NEW.exam_grade + NEW.lab_grade) / 2)
                    WHEN NEW.exam_grade < 5 THEN NEW.exam_grade
                    WHEN NEW.lab_grade < 5 THEN 0
                    ELSE NULL
                END),
            r.register_status = (
                CASE
                    WHEN NEW.exam_grade IS NOT NULL AND NEW.lab_grade IS NOT NULL THEN
                        CASE
                            WHEN NEW.exam_grade >= 5 AND NEW.lab_grade >= 5 THEN 'pass'
                            ELSE 'fail'
                        END
                    ELSE NULL
                END
            )
        WHERE r.course_code = NEW.course_code;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_register_grades_trigger
AFTER UPDATE ON public."Semester"
FOR EACH ROW
EXECUTE FUNCTION public.update_register_grades();		

---------------------------------------4.2---------------------------------------
CREATE OR REPLACE FUNCTION validate_program()
RETURNS TRIGGER AS $$
DECLARE
    max_committee_members integer;
BEGIN
    --Check if the start year is older than the most recent per type 
    IF EXISTS (
        SELECT 1
        FROM public."Program"
        WHERE "DiplomaType" = NEW."DiplomaType" AND
              "Year" < NEW."Year"
    ) THEN
        RAISE EXCEPTION 'Invalid start year!';
    END IF;

    -- Check the number of the committee
    SELECT "CommitteeNum" INTO max_committee_members
    FROM public."Program"
    WHERE "ProgramID" = NEW."ProgramID";

    IF max_committee_members IS NOT NULL AND
       (SELECT COUNT(*) FROM public."CommitteeMembers" WHERE "ProgramID" = NEW."ProgramID") > max_committee_members THEN
        RAISE EXCEPTION 'Excess of the max number of the members committee number';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_program_trigger
BEFORE INSERT OR UPDATE ON public."Program"
FOR EACH ROW
EXECUTE FUNCTION validate_program();


---------------------------------------1.1---------------------------------------
CREATE VIEW current_semester_courses AS
SELECT c.course_code, c.course_title, string_agg(concat_ws(' ', per.name, per.surname), ', ') AS teacher_names
FROM "Course" c
JOIN "CourseRun" cr ON c.course_code = cr.course_code
JOIN "Teaches" t ON t.course_code = cr.course_code AND t.serial_number = cr.serial_number
JOIN "Professor" p ON p.amka = t.amka
JOIN "Person" per ON per.amka = p.amka
JOIN "Semester" s ON s.semester_id = cr.semesterrunsin AND s.semester_status = 'present'
GROUP BY c.course_code, c.course_title;



