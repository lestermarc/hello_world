--------------------------------------------------------
--  DDL for Package Body WEB_HRM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_HRM_FUNCTIONS" 
/**
*  18.11.2007 RRI Correction fonction copyNewGoal (la partie createNewGoal est un peu différente que ée std par
*                            la mise àjour du epg_
*  11.11.2007 RRI Ajout sendMailWithEvalPersonLink,getEvalPersonNames,getEmpCommPreference
*                       copyNewGoalInd
*                       correction sur fonction hrmevalgoalcheck
*/
IS
   FUNCTION counthrmevalpersonbystate (p_hrm_eval_program_id IN HRM_EVAL_PERSON.hrm_eval_program_id%TYPE,
   p_c_eval_status IN HRM_EVAL_PERSON.c_eval_status%TYPE, p_hrm_in_charge_id IN HRM_PERSON.hrm_person_id%TYPE
   )
      RETURN INTEGER
   IS
      RESULT NUMBER;
      nbrows INTEGER;
      nb INTEGER;
      employeefiltersql VARCHAR2 (32767);
        testsql VARCHAR2 (32767);
      uppertestsql VARCHAR2 (32767);
      cid INTEGER;
   BEGIN

      nb := -1;
      employeefiltersql :=
              pcs.pc_functions.getsql('HRM_PERSON', 'BC4J_VIEWOBJECT_FILTER', 'Dependant employees', NULL, 'ANSI SQL');

      IF employeefiltersql IS NULL
      THEN
         employeefiltersql := 'SELECT HRM_PERSON_ID FROM HRM_PERSON WHERE EMP_STATUS IN (''ACT'')';
      END IF;

      IF (p_c_eval_status = -1)
      THEN
         BEGIN
            testsql :=
               'SELECT count(*) FROM (' || employeefiltersql || ') where hrm_person_id not in ('
               || 'select HRM_PERSON_ID FROM HRM_EVAL_PERSON ep WHERE ' || ' ep.HRM_EVAL_PROGRAM_ID = '
               || p_hrm_eval_program_id || ')';
         END;
      ELSE
         testsql :=
            'SELECT count(*) FROM HRM_EVAL_PERSON ep WHERE ' || ' ep.C_EVAL_STATUS=''' || p_c_eval_status || ''''
            || ' AND ep.HRM_EVAL_PROGRAM_ID = ' || p_hrm_eval_program_id || ' AND ep.HRM_PERSON_ID IN ('
            || employeefiltersql || ')';
      END IF;

      uppertestsql := UPPER (testsql);
      cid := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE (cid, uppertestsql, DBMS_SQL.v7);



      IF INSTR (uppertestsql, ':HRM_IN_CHARGE_ID') > 0
      THEN
         DBMS_SQL.BIND_VARIABLE (cid, 'HRM_IN_CHARGE_ID', p_hrm_in_charge_id);
      END IF;

      DBMS_SQL.DEFINE_COLUMN (cid, 1, nb);
      nbrows := DBMS_SQL.EXECUTE_AND_FETCH (cid);
      DBMS_SQL.COLUMN_VALUE (cid, 1, nb);
      DBMS_SQL.CLOSE_CURSOR (cid);
      RETURN nb;
   END;

   FUNCTION gethrmevalpersonstate (p_hrm_eval_program_id IN HRM_EVAL_PERSON.hrm_eval_program_id%TYPE,
   p_hrm_person_id IN HRM_PERSON.hrm_person_id%TYPE
   )
      RETURN HRM_EVAL_PERSON.c_eval_status%TYPE
   IS
      n INTEGER;
      ret HRM_EVAL_PERSON.c_eval_status%TYPE;
   BEGIN
      SELECT COUNT (*)
      INTO   n
      FROM   HRM_EVAL_PERSON
      WHERE  hrm_person_id = p_hrm_person_id AND hrm_eval_program_id = p_hrm_eval_program_id;

      IF (n = 0)
      THEN
         RETURN -1;
      ELSE
         BEGIN
            SELECT MIN (c_eval_status)
            INTO   ret
            FROM   HRM_EVAL_PERSON
            WHERE  hrm_person_id = p_hrm_person_id AND hrm_eval_program_id = p_hrm_eval_program_id;

            RETURN ret;
         END;

         RETURN NULL;
      END IF;
   END;

      /******************************************************************************
      NAME:       WEB_HRM_EVAL
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        11.07.2005             1. Created this package body.

     function HrmEvalGoalCheck
      retourne 1 si c'est ok sinon 0 si une erreur a été rencontrée. dans ce cas le param errMsg contient l'erreur
   ******************************************************************************/
   FUNCTION hrmevalgoalcheck (hrmevalgoalid IN HRM_EVAL_GOAL.hrm_eval_goal_id%TYPE, errmsg OUT VARCHAR2)
      RETURN NUMBER
   IS
   /* pour tests unitaire
   declare
    n number(1);
    a varchar2(1000);
    begin
      n:= web_hrm_functions.HRMEVALGOALCHECK(60018372447,a);
      dbms_output.PUT_LINE(a||' '||n);
    end;
   */
      n NUMBER;
      totPond NUMBER;
      goaltype HRM_EVAL_GOAL.dic_goal_type_id%TYPE;
      goaldatefrom HRM_EVAL_GOAL.evg_from%TYPE;
      goaldateto HRM_EVAL_GOAL.evg_to%TYPE;
      hrmPersonId HRM_PERSON_GOAL.HRM_PERSON_ID%type;
   BEGIN

      SELECT dic_goal_type_id, nvl(evg_from,epg_from), nvl(evg_to,epg_to)
      INTO   goaltype, goaldatefrom, goaldateto
      FROM   HRM_EVAL_GOAL eg, HRM_PERSON_GOAL pg
      WHERE
      eg.hrm_eval_goal_id=pg.hrm_eval_goal_id(+) and
      eg.hrm_eval_goal_id = hrmevalgoalid;

      IF (goaltype = 'SOC')
      THEN
         BEGIN
            SELECT COUNT (*)
            INTO   n
            FROM   HRM_EVAL_GOAL
            WHERE  dic_goal_type_id = 'SOC'
                   AND ((goaldatefrom BETWEEN evg_from AND evg_to) OR (goaldateto BETWEEN evg_from AND evg_to))
                   AND hrm_eval_goal_id <> hrmevalgoalid;

            IF (n >= 1)
            THEN
               BEGIN
                  errmsg := 'Ne définir qu''un seul objectif "Société" sur la période.';
                  RETURN 2;
               END;
            END IF;

            RETURN 3;
         END;

      ELSIF (goaltype = 'IND')
      /**
      *
      *  Controle si sum des pondérations <=10 et nb d'obj <=3
      *  sur la même période que l'objectif
      */
       THEN
         BEGIN

         SELECT HRM_PERSON_ID
           INTO   hrmPersonId
         FROM   HRM_PERSON_GOAL
         WHERE  hrm_eval_goal_id = hrmevalgoalid;

         SELECT COUNT (*)
            INTO   n
           FROM
             HRM_PERSON_GOAL pg
           WHERE
             hrm_person_id=hrmPersonId and
             ((epg_from is null) or (epg_from<=goaldatefrom) or (goaldatefrom is null)) and
             ( (epg_to is null) or (epg_to>=goaldateto ) or (goaldateto is null) ) and
             hrm_eval_goal_id <> hrmevalgoalid;

         SELECT sum(pg.EPG_WEIGHT)
            INTO totPond
           FROM
             HRM_PERSON_GOAL pg
           WHERE
             hrm_person_id=hrmPersonId and
             ((epg_from is null) or (epg_from<=goaldatefrom) or (goaldatefrom is null) ) and
             ( (epg_to is null) or (epg_to>=goaldateto) or (goaldateto is null) );


            IF (totPond>10)
            THEN
              BEGIN
                  errmsg := 'Le total des pondérations ne doit pas dépasser 10.Total de '||totPond;
                  RETURN 2;
              END;
            END IF;

            IF (n >= 3)
            THEN
               BEGIN
                  errmsg := 'Ne définir que 3 objectifs "Individuels" sur la période.';
                  RETURN 2;
               END;
            END IF;

            RETURN 3;
         END;
      END IF;

      RETURN 3;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            errmsg := 'Objectif (' || hrmevalgoalid || ') non trouvé.';
            RETURN 0;
         END;
   END;


   FUNCTION createanswersforprogramperson (p_hrmpersonid HRM_PERSON.hrm_person_id%TYPE,
                                           p_hrminchargeid HRM_PERSON.hrm_person_id%TYPE,
                                           p_evalprogramid HRM_EVAL_PROGRAM.hrm_eval_program_id%TYPE,
                                           p_evpPrepDate HRM_EVAL_PERSON.EVP_PREP_DATE%TYPE,
                                           p_evpDate HRM_EVAL_PERSON.EVP_DATE%TYPE,
                                           p_evpFrom HRM_EVAL_PERSON.EVP_FROM%TYPE,
                                           p_evpTo HRM_EVAL_PERSON.EVP_TO%TYPE,
                                           p_initials HRM_EVAL_ANSWER.A_IDCRE%TYPE
   )
      RETURN HRM_EVAL_PERSON.hrm_eval_person_id%TYPE
   IS
      v_hrmevalpersonid HRM_EVAL_PERSON.hrm_eval_person_id%TYPE;
      v_exists NUMBER;
      amount NUMBER;
      ExitDate DATE;
   BEGIN
      --Check if exists
      SELECT COUNT (*)
      INTO   v_exists
      FROM   HRM_EVAL_PERSON
      WHERE  hrm_person_id = p_hrmpersonid AND hrm_eval_program_id = p_evalprogramid AND c_eval_status <> '3';

      IF (v_exists = 0)
      THEN
         BEGIN
            SELECT init_id_seq.NEXTVAL
            INTO   v_hrmevalpersonid
            FROM   DUAL;

            INSERT INTO HRM_EVAL_PERSON
                        (hrm_eval_person_id,
                        hrm_person_id,
                        hrm_eval_program_id,
                        evp_description,
                        evp_from,
                        evp_to,
                        c_eval_status,
                        hrm_evaluator_id,
                        a_datecre,
                        a_idcre,
                        evp_prep_date,
                        evp_date)
               SELECT v_hrmevalpersonid,
                      p_hrmpersonid,
                      hrm_eval_program_id,
                      evp_descr,
                      NVL(p_evpFrom,TO_DATE('01.01.'||(TO_CHAR(SYSDATE,'YYYY')-1),'DD.MM.YYYY')),
                      NVL(p_evpTo,TO_DATE ('31.12.' || (TO_CHAR (SYSDATE, 'YYYY') - 1), 'DD.MM.YYYY')),
                      '1',
                      p_hrminchargeid,
                      SYSDATE,
                      p_initials,
                      p_evpPrepDate,
                      p_evpDate
               FROM   HRM_EVAL_PROGRAM
               WHERE  hrm_eval_program_id = p_evalprogramid;
         END;
      ELSE
         BEGIN
            SELECT hrm_eval_person_id
            INTO   v_hrmevalpersonid
            FROM   HRM_EVAL_PERSON p1
            WHERE  hrm_person_id = p_hrmpersonid
                   AND hrm_eval_program_id = p_evalprogramid
                   AND evp_from =
                               (SELECT MAX (evp_from)
                                FROM   HRM_EVAL_PERSON p2
                                WHERE  p1.hrm_person_id = p2.hrm_person_id AND p2.hrm_eval_program_id = p_evalprogramid);
         END;
      END IF;                                                                                --if hrm_eval_person exists

      --v_HrmEvalPersonId is ready
      SELECT COUNT (*) INTO   v_exists
      FROM   HRM_EVAL_ANSWER
      WHERE  hrm_eval_person_id = v_hrmevalpersonid;

      IF (v_exists = 0)
      THEN
         BEGIN
            INSERT INTO HRM_EVAL_ANSWER
                        (hrm_eval_answer_id, hrm_eval_person_id, hrm_eval_question_id, hrm_eval_goal_id, a_datecre,
                         a_idcre)
               SELECT init_id_seq.NEXTVAL, v_hrmevalpersonid, hrm_eval_question_id, NULL, SYSDATE, p_initials
               FROM   HRM_EVAL_QUESTION q, HRM_EVAL_CHAPTER c, HRM_EVAL_PROG_CHAP cp, HRM_EVAL_PERSON ep
               WHERE  q.hrm_eval_chapter_id = c.hrm_eval_chapter_id
                      AND c.hrm_eval_chapter_id = cp.hrm_eval_chapter_id
                      AND cp.hrm_eval_program_id = ep.hrm_eval_program_id
                      AND ep.hrm_eval_person_id = v_hrmevalpersonid;

              /*
            Insertion des réponses aux objectifs définis pour la période et le programme
            */
            /* RRI 2006 12 06
            UPDATE HRM_PERSON_GOAL pg
            SET hrm_eval_chapter_id = (SELECT hrm_eval_chapter_id
                                       FROM   HRM_EVAL_GOAL g
                                       WHERE  g.hrm_eval_goal_id = pg.hrm_eval_goal_id
                                       AND g.hrm_eval_goal_id IS NOT NULL)
            WHERE  hrm_person_id = p_hrmpersonid AND hrm_eval_chapter_id IS NULL;
            */

            INSERT INTO HRM_EVAL_ANSWER
                        (hrm_eval_answer_id, hrm_eval_person_id, hrm_eval_question_id, hrm_eval_goal_id, a_datecre,
                         a_idcre, hrm_eval_notation_detail_id)
                         SELECT init_id_seq.NEXTVAL, v_hrmevalpersonid, NULL, pg.hrm_eval_goal_id, SYSDATE, p_initials, NULL hrm_eval_notation_detail_id
                         FROM   HRM_PERSON_GOAL pg,
                        HRM_EVAL_PERSON ep,
                        HRM_EVAL_GOAL g
                         WHERE  ep.hrm_eval_person_id = v_hrmevalpersonid
                        AND  ep.hrm_person_id = pg.hrm_person_id
                        AND  pg.hrm_eval_goal_id = g.hrm_eval_goal_id
                           AND  g.dic_goal_type_id = 'IND'
                        AND  HRM_EVAL_PERSON_EVAL_ID IS NULL
                        AND  (epg_from BETWEEN evp_from AND evp_to   OR epg_to BETWEEN evp_from AND evp_to);

            /*RRI 25.09.06
            Mise à jour du lien sur HRM_PERSON_GOAL de l'entretien qui va évaluer
            l'objectif (utile pour consultation futur)
            */
            UPDATE HRM_PERSON_GOAL pg
            SET HRM_EVAL_PERSON_EVAL_ID = v_hrmevalpersonid
            WHERE EXISTS (SELECT 1 FROM HRM_EVAL_ANSWER a WHERE HRM_EVAL_PERSON_ID = v_hrmevalpersonid
                            AND pg.HRM_EVAL_GOAL_ID = a.HRM_EVAL_GOAL_ID);

          --Recherche si l'employé est sortant
           SELECT MAX(ino_out) INTO ExitDate
           FROM   HRM_EVAL_PERSON ep,
                  HRM_IN_OUT io
           WHERE  ep.hrm_eval_person_id = v_hrmevalpersonid
           AND    ep.hrm_person_id = io.hrm_employee_id
           AND    io.ino_out IS NOT NULL
           AND    io.ino_out > ep.evp_from
           AND    io.ino_out < ep.evp_to;

           IF ExitDate IS NOT NULL THEN
              --Mise à jour des dates de fin d'entretien si l'employé est sortant
          UPDATE HRM_EVAL_PERSON ep SET evp_to = ExitDate
          WHERE  ep.hrm_eval_person_id = v_hrmevalpersonid;
          END IF;


         END;
      ELSE --les réponses ont déjà été générées
         BEGIN
            NULL;
         END;
      END IF;

      RETURN v_hrmevalpersonid;
   END;





   FUNCTION checkafterinput (p_hrm_eval_chapter_id IN HRM_EVAL_CHAPTER.hrm_eval_chapter_id%TYPE,
   p_hrm_person_id IN HRM_PERSON.hrm_person_id%TYPE, errmsg OUT VARCHAR2
   )
      RETURN INTEGER
   IS
      n NUMBER;
      notok NUMBER;
   BEGIN
      SELECT COUNT (*)
      INTO   n
      FROM   HRM_EVAL_ANSWER a, HRM_EVAL_PERSON p, HRM_EVAL_QUESTION q
      WHERE  a.hrm_eval_person_id = p.hrm_eval_person_id
             AND q.hrm_eval_question_id = a.hrm_eval_question_id
             AND q.hrm_eval_chapter_id = p_hrm_eval_chapter_id
             AND p.hrm_person_id = p_hrm_person_id;

      SELECT COUNT (*)
      INTO   notok
      FROM   HRM_EVAL_ANSWER a, HRM_EVAL_PERSON p, HRM_EVAL_QUESTION q, HRM_EVAL_NOTATION_DETAIL d
      WHERE  a.hrm_eval_person_id = p.hrm_eval_person_id
             AND q.hrm_eval_question_id = a.hrm_eval_question_id
             AND q.hrm_eval_chapter_id = p_hrm_eval_chapter_id
             AND p.hrm_person_id = p_hrm_person_id
             AND a.hrm_eval_notation_detail_id = d.hrm_eval_notation_detail_id(+)
             AND ((evp_answer IS NULL) AND (a.hrm_eval_notation_detail_id IS NULL OR evd_comment = 'Sans réponse'));

      IF (n = 0)
      THEN
         errmsg := 'Aucune réponse au chapitre précédent.';
         RETURN 2;
      ELSIF (notok = 0)
      THEN
         errmsg := 'sans erreur';
         RETURN 3;
      ELSE
         errmsg :=
            'Vous devez répondre à toutes les questions du chapitres. ' || CHR (10) || notok
            || ' ne sont pas renseignées.';
         RETURN 1;
      END IF;
   END;

   FUNCTION getobjpoints (evalid NUMBER)
      RETURN NUMBER
   IS
      RESULT NUMBER;
   BEGIN
      SELECT SUM (NVL (evd_points, 0) * evg_weight)
      INTO   RESULT
      FROM   HRM_EVAL_ANSWER a, HRM_EVAL_NOTATION_DETAIL d, HRM_EVAL_GOAL g
      WHERE  a.hrm_eval_notation_detail_id = d.hrm_eval_notation_detail_id
             AND a.hrm_eval_goal_id = g.hrm_eval_goal_id
             AND a.hrm_eval_person_id = evalid;

      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END;

   FUNCTION getcritpoints (evalid NUMBER)
      RETURN NUMBER
   IS
      RESULT NUMBER;
   BEGIN
      SELECT SUM (NVL (evd_points, 0))
      INTO   RESULT
      FROM   HRM_EVAL_ANSWER a, HRM_EVAL_NOTATION_DETAIL d, HRM_EVAL_PROG_CHAP pc, HRM_EVAL_QUESTION q,
             HRM_EVAL_PERSON p
      WHERE  hrm_eval_goal_id IS NULL
             AND a.hrm_eval_notation_detail_id = d.hrm_eval_notation_detail_id
             AND a.hrm_eval_question_id = q.hrm_eval_question_id
             AND q.hrm_eval_chapter_id = pc.hrm_eval_chapter_id
             AND p.hrm_eval_program_id = pc.hrm_eval_program_id
             AND p.hrm_eval_person_id = evalid
             AND a.hrm_eval_person_id = evalid
             AND pc.evc_sequence = 5;

      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END;

   FUNCTION getbadobjective (evalid NUMBER)
      RETURN NUMBER
   IS
      RESULT NUMBER;
   BEGIN
      SELECT COUNT (d.evd_points)
      INTO   RESULT
      FROM   HRM_EVAL_ANSWER a, HRM_EVAL_NOTATION_DETAIL d, HRM_PERSON_GOAL e, HRM_EVAL_PERSON pe, HRM_EVAL_GOAL g
      WHERE  a.hrm_eval_notation_detail_id = d.hrm_eval_notation_detail_id
             AND a.hrm_eval_goal_id = e.hrm_eval_goal_id
             AND e.hrm_person_id = pe.hrm_person_id
             AND pe.hrm_eval_person_id = evalid
             AND a.hrm_eval_person_id = evalid
             AND e.hrm_eval_goal_id = g.hrm_eval_goal_id
             AND NVL (evd_points, 0) = 0
             AND g.dic_goal_type_id = 'IND';

      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END;

   FUNCTION getbadcriterion (evalid NUMBER)
      RETURN NUMBER
   IS
      RESULT NUMBER;
   BEGIN
      SELECT COUNT (d.evd_points)
      INTO   RESULT
      FROM   HRM_EVAL_ANSWER a, HRM_EVAL_NOTATION_DETAIL d, HRM_EVAL_PROG_CHAP pc, HRM_EVAL_QUESTION q,
             HRM_EVAL_PERSON p
      WHERE  hrm_eval_goal_id IS NULL
             AND a.hrm_eval_notation_detail_id = d.hrm_eval_notation_detail_id
             AND a.hrm_eval_question_id = q.hrm_eval_question_id
             AND q.hrm_eval_chapter_id = pc.hrm_eval_chapter_id
             AND p.hrm_eval_program_id = pc.hrm_eval_program_id
             AND p.hrm_eval_person_id = evalid
             AND a.hrm_eval_person_id = evalid
             AND pc.evc_sequence = 5
             AND evd_points = 0;

      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END;

   FUNCTION getallowedprime (evalid NUMBER)
      RETURN NUMBER
   IS
      RESULT NUMBER;
      obj NUMBER;
      crit NUMBER;
   BEGIN
      crit := getbadcriterion (evalid);
      obj := getbadobjective (evalid);

      IF obj > 0 OR crit > 3
      THEN
         RESULT := 0;
      ELSE
         RESULT := 1;
      END IF;

      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 0;
   END;

   FUNCTION pensiondate (birth VARCHAR, gender VARCHAR)
      RETURN VARCHAR
   IS
      RESULT VARCHAR2 (25);
   BEGIN
      RESULT := TO_CHAR (Hrm_Date.pensiondate (NVL (TO_DATE (birth, 'DD.MM.YYYY'), SYSDATE), gender), 'YYYYMMDD');
      RETURN RESULT;
   END;

   FUNCTION getdivision (empid NUMBER, dateref VARCHAR2)
      RETURN VARCHAR2
   IS
      RESULT VARCHAR2 (255);
      dep VARCHAR2 (50);
      job NUMBER;
   BEGIN
      SELECT MAX (pj.hrm_job_id)
      INTO   job
      FROM   HRM_PERSON_JOB pj, HRM_JOB j
      WHERE  pj.hrm_job_id = j.hrm_job_id
             AND pj.hrm_person_id = empid
             AND TO_DATE (dateref, 'dd.mm.yyyy') BETWEEN pej_from AND NVL (pej_to, TO_DATE ('31.12.2022', 'dd.mm.yyyy'));

      SELECT dic_department_id
      INTO   dep
      FROM   HRM_JOB
      WHERE  hrm_job_id = job;

      RESULT := getdivision (dep, dateref);
      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN ' ';
   END;

   FUNCTION getfonction (empid NUMBER, dateref VARCHAR2)
      RETURN VARCHAR2
   IS
      RESULT VARCHAR2 (255);
      temp NUMBER;
   BEGIN
      SELECT MAX (pj.hrm_job_id)
      INTO   temp
      FROM   HRM_PERSON_JOB pj, HRM_JOB j
      WHERE  pj.hrm_job_id = j.hrm_job_id
             AND pj.hrm_person_id = empid
             AND TO_DATE (dateref, 'dd.mm.yyyy') BETWEEN pej_from AND NVL (pej_to, TO_DATE ('31.12.2022', 'dd.mm.yyyy'));

      SELECT job_title
      INTO   RESULT
      FROM   HRM_JOB
      WHERE  hrm_job_id = temp;

      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN ' ';
   END;

   FUNCTION getfonctiondatefrom (empid NUMBER, dateref VARCHAR2)
      RETURN VARCHAR2
   IS
      RESULT VARCHAR2 (255);
      temp NUMBER;
   BEGIN
      SELECT MAX (pj.hrm_job_id)
      INTO   temp
      FROM   HRM_PERSON_JOB pj, HRM_JOB j
      WHERE  pj.hrm_job_id = j.hrm_job_id
             AND pj.hrm_person_id = empid
             AND TO_DATE (dateref, 'dd.mm.yyyy') BETWEEN pej_from AND NVL (pej_to, TO_DATE ('31.12.2022', 'dd.mm.yyyy'));

      SELECT TO_CHAR (MAX (pej_from), 'dd.mm.yyyy')
      INTO   RESULT
      FROM   HRM_PERSON_JOB
      WHERE  hrm_job_id = temp AND hrm_person_id = empid;

      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN ' ';
   END;

   FUNCTION getactivityrate (empid NUMBER, dateref VARCHAR2)
      RETURN VARCHAR2
   IS
      RESULT VARCHAR2 (255);
      temp NUMBER;
   BEGIN
      SELECT MAX (pj.hrm_job_id)
      INTO   temp
      FROM   HRM_PERSON_JOB pj, HRM_JOB j
      WHERE  pj.hrm_job_id = j.hrm_job_id
             AND pj.hrm_person_id = empid
             AND TO_DATE (dateref, 'dd.mm.yyyy') BETWEEN pej_from AND NVL (pej_to, TO_DATE ('31.12.2022', 'dd.mm.yyyy'));

      SELECT TO_CHAR (MAX (pej_affect_rate))
      INTO   RESULT
      FROM   HRM_PERSON_JOB
      WHERE  hrm_job_id = temp AND hrm_person_id = empid;

      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN ' ';
   END;

   FUNCTION getclasseaig (empid NUMBER, dateref VARCHAR2)
      RETURN VARCHAR2
   IS
      RESULT VARCHAR2 (255);
      temp NUMBER;
   BEGIN
      SELECT MAX (pj.hrm_job_id)
      INTO   temp
      FROM   HRM_PERSON_JOB pj, HRM_JOB j
      WHERE  pj.hrm_job_id = j.hrm_job_id
             AND pj.hrm_person_id = empid
             AND TO_DATE (dateref, 'dd.mm.yyyy') BETWEEN pej_from AND NVL (pej_to, TO_DATE ('31.12.2022', 'dd.mm.yyyy'));

      SELECT MAX (vfi_char_03)
      INTO   RESULT
      FROM   HRM_PERSON_JOB, COM_VFIELDS_RECORD r
      WHERE  hrm_job_id = temp
             AND hrm_person_id = empid
             AND r.vfi_rec_id = hrm_person_job_id
             AND vfi_tabname = 'HRM_PERSON_JOB';

      RETURN RESULT;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN ' ';
   END;

   FUNCTION checkdevcriteres (p_hrm_eval_chapter_id IN HRM_EVAL_CHAPTER.hrm_eval_chapter_id%TYPE,
   p_hrm_person_id IN HRM_PERSON.hrm_person_id%TYPE, p_hrm_eval_person_id NUMBER, errmsg OUT VARCHAR2
   )
      RETURN INTEGER
   IS
      n NUMBER;
      nob NUMBER;
      pointsobj NUMBER;
      pointscrit NUMBER;
   BEGIN
      /*
      Ajouter le contrôle pour l'obligation de renseigner un critère selon responsabilité hiérarchique
      */
      SELECT COUNT (*) - 3, SUM (DECODE (evq_sequence, 10, 1, 11, 1, 0)) nob
      INTO   n, nob
      FROM   HRM_EVAL_ANSWER a, HRM_EVAL_QUESTION q, HRM_EVAL_NOTATION_DETAIL d
      WHERE  q.hrm_eval_question_id = a.hrm_eval_question_id
             AND q.hrm_eval_chapter_id = p_hrm_eval_chapter_id
             AND a.hrm_eval_person_id = p_hrm_eval_person_id
             AND a.hrm_eval_notation_detail_id = d.hrm_eval_notation_detail_id(+)
             AND ((evp_answer IS NULL) AND (a.hrm_eval_notation_detail_id IS NULL OR evd_comment = 'Sans réponse'));

      IF n <> 0
      THEN
         errmsg := 'Vous devez répondre à 8 critères. ' || CHR (10) || 'Il manque ' || TO_CHAR (n) || ' critère(s).';
         RETURN 1;
      ELSE
         IF nob <> 1
         THEN
            errmsg := 'Vous devez répondre à la question 10 ou à la 11';
            RETURN 1;
         END IF;

         IF getbadcriterion (p_hrm_eval_person_id) >= 3 OR getbadobjective (p_hrm_eval_person_id) > 0
         THEN
            errmsg :=
               'Pas de P3 : ' || getbadcriterion (p_hrm_eval_person_id)
               || ' critères "n''a pas répondu aux attentes" et ' || getbadobjective (p_hrm_eval_person_id)
               || ' objectifs individuels non atteints.';
            RETURN 2;
         ELSE
            SELECT SUM (epg_weight * evd_points)
            INTO   pointsobj
            FROM   HRM_EVAL_ANSWER a, HRM_EVAL_NOTATION_DETAIL d, HRM_PERSON_GOAL pg, HRM_EVAL_GOAL g
            WHERE  a.hrm_eval_goal_id = pg.hrm_eval_goal_id
                   AND a.hrm_eval_notation_detail_id = d.hrm_eval_notation_detail_id
                   AND a.hrm_eval_person_id = p_hrm_eval_person_id
                   AND pg.hrm_person_id = p_hrm_person_id
                   AND pg.hrm_eval_goal_id = g.hrm_eval_goal_id
                   AND g.dic_goal_type_id = 'IND';

             /*
            Points des critères = sommes des points total - objectifs
            */
            SELECT SUM (evd_points)
            INTO   pointscrit
            FROM   HRM_EVAL_ANSWER a, HRM_EVAL_NOTATION_DETAIL d
            WHERE  hrm_eval_person_id = p_hrm_eval_person_id
                   AND hrm_eval_goal_id IS NULL
                   AND a.hrm_eval_notation_detail_id = d.hrm_eval_notation_detail_id;

            errmsg :=
               'Total des points "Critères" : ' || TO_CHAR (pointscrit) || ', Report des points "Objectifs" : '
               || TO_CHAR (pointsobj) || ', Total général : ' || TO_CHAR (pointscrit + pointsobj);
            RETURN 2;
         END IF;
      END IF;
   END;

   FUNCTION afterindgoal (p_hrm_eval_chapter_id IN HRM_EVAL_CHAPTER.hrm_eval_chapter_id%TYPE,
   p_hrm_person_id IN HRM_PERSON.hrm_person_id%TYPE, p_hrm_eval_person_id NUMBER, errmsg OUT VARCHAR2
   )
      RETURN INTEGER
   IS
      pond NUMBER;
      nbreobj INTEGER;
      evaldateto DATE;
      chapid NUMBER;
   BEGIN

      SELECT hrm_eval_chapter_id
      INTO   chapid
      FROM   HRM_EVAL_CHAPTER
      WHERE  c_hrm_chapter_type = '02';

      SELECT NVL (MAX (evp_to), SYSDATE)
      INTO   evaldateto
      FROM   HRM_EVAL_PERSON
      WHERE  hrm_eval_person_id = p_hrm_eval_person_id;

      /*
      Contrôle qu'il n'y ait pas plus de 3 objectifs individuels
      */
      SELECT   MAX (COUNT (pg.hrm_person_id))
      INTO     nbreobj
      FROM     HRM_PERSON_GOAL pg, HRM_EVAL_GOAL g
      WHERE    hrm_person_id = p_hrm_person_id
               AND pg.hrm_eval_goal_id = g.hrm_eval_goal_id
               AND g.dic_goal_type_id = 'IND'
               AND TO_CHAR (evg_from, 'yyyy') = TO_CHAR (evaldateto, 'yyyy') + 1
      GROUP BY TO_CHAR (evg_from, 'yyyy');

      /*
      Contrôle que la pondération n'excède pas 10
      */
      SELECT SUM (NVL (epg_weight, 0))
      INTO   pond
      FROM   HRM_PERSON_GOAL pg, HRM_EVAL_GOAL g
      WHERE  hrm_person_id = p_hrm_person_id
             AND pg.hrm_eval_goal_id = g.hrm_eval_goal_id
             AND g.dic_goal_type_id = 'IND'
             AND TO_CHAR (evg_from, 'yyyy') = TO_CHAR (evaldateto, 'yyyy') + 1;

      IF NVL (pond, 0) <> 10 OR nbreobj > 3
      THEN
         IF nbreobj > 3
         THEN
            errmsg := 'Maximum 3 objectifs individuels ';
         ELSE
            errmsg := 'Pondération totale ne peut dépasser 10';
         END IF;

         RETURN 1;
      ELSE
         RETURN 3;
      END IF;
   END;

   FUNCTION afterbilan (p_hrm_eval_chapter_id IN HRM_EVAL_CHAPTER.hrm_eval_chapter_id%TYPE,
   p_hrm_person_id IN HRM_PERSON.hrm_person_id%TYPE, p_hrm_eval_person_id NUMBER, errmsg OUT VARCHAR2
   )
      RETURN INTEGER
   IS
      tmp INTEGER;
   BEGIN
      tmp := NVL (getbadobjective (p_hrm_eval_person_id), 0);

      IF tmp > 0
      THEN
         errmsg := '1 objectif individuel non "atteint" ne permet pas l''obtention de la P3';
         RETURN 2;
      ELSE
         SELECT SUM (epg_weight * evd_points)
         INTO   tmp
         FROM   HRM_EVAL_ANSWER a, HRM_EVAL_NOTATION_DETAIL d, HRM_PERSON_GOAL pg, HRM_EVAL_GOAL g
         WHERE  a.hrm_eval_goal_id = pg.hrm_eval_goal_id
                AND a.hrm_eval_notation_detail_id = d.hrm_eval_notation_detail_id
                AND a.hrm_eval_person_id = p_hrm_eval_person_id
                AND pg.hrm_person_id = p_hrm_person_id
                AND pg.hrm_eval_goal_id = g.hrm_eval_goal_id
                AND g.dic_goal_type_id = 'IND';

         errmsg := tmp || ' points acquis';
         RETURN 2;
      END IF;
   END;

   FUNCTION setgoalchapter (p_hrm_eval_chapter_id IN HRM_EVAL_CHAPTER.hrm_eval_chapter_id%TYPE,
   p_hrm_person_id IN HRM_PERSON.hrm_person_id%TYPE, errmsg OUT VARCHAR2
   )
      RETURN INTEGER
   IS
      temp VARCHAR (10);
   BEGIN
      SELECT MAX (c_hrm_chapter_type)
      INTO   temp
      FROM   HRM_EVAL_CHAPTER c, HRM_EVAL_PROG_CHAP cp, HRM_EVAL_PROG_CHAP pc2
      WHERE  cp.hrm_eval_chapter_id = p_hrm_eval_chapter_id
             AND cp.hrm_eval_program_id = pc2.hrm_eval_program_id
             AND cp.evc_sequence + 1 = pc2.evc_sequence
             AND c.hrm_eval_chapter_id = pc2.hrm_eval_chapter_id;

      IF temp = '03'
      THEN
         UPDATE HRM_EVAL_GOAL
         SET hrm_eval_chapter_id = NULL                                                                     --4295161201
         WHERE HRM_EVAL_GOAL_ID IN (SELECT HRM_EVAL_GOAL_ID FROM
                                    HRM_PERSON_GOAL WHERE hrm_person_id = p_hrm_person_id);
      ELSE
         IF temp = '02'
         THEN
            UPDATE HRM_EVAL_GOAL
            SET hrm_eval_chapter_id = NULL                                                                  --4295161223
         WHERE HRM_EVAL_GOAL_ID IN (SELECT HRM_EVAL_GOAL_ID FROM
                                    HRM_PERSON_GOAL WHERE hrm_person_id = p_hrm_person_id);
         END IF;
      END IF;

      RETURN 3;
   END;


  FUNCTION getLimitDateForGoalList( p_HrmEvalPersonId HRM_EVAL_PERSON.HRM_EVAL_PERSON_ID%TYPE, LIMITDATE OUT VARCHAR2 ) RETURN NUMBER IS
  BEGIN
    SELECT NVL(TO_CHAR(TO_CHAR(evp_to,'yyyy')+1)||TO_CHAR(evp_to,'mmdd'),'21001231') INTO LIMITDATE
    FROM
      HRM_EVAL_PERSON
    WHERE
      HRM_EVAL_PERSON_ID = p_HrmEvalPersonId;

    RETURN 3; --ok
  END;



   FUNCTION count_hrmPersonGoalForGoal (p_hrm_eval_goal_id IN HRM_EVAL_GOAL.hrm_eval_goal_id%TYPE
   )
      RETURN INTEGER IS
      n INTEGER;
      BEGIN
        SELECT COUNT(*) INTO n FROM HRM_PERSON_GOAL WHERE hrm_eval_goal_id=p_hrm_eval_goal_id;
        RETURN n;
      END;

  FUNCTION createNewGoal(p_EvgComment HRM_EVAL_GOAL.EVG_COMMENT%TYPE,
                          p_DicGoalType HRM_EVAL_GOAL.DIC_GOAL_TYPE_ID%TYPE,
                          p_aidcre HRM_EVAL_GOAL.A_IDCRE%TYPE,
                          p_HrmEvalChapter HRM_EVAL_GOAL.HRM_EVAL_CHAPTER_ID%TYPE,
                          p_HrmPersonId HRM_EVAL_PERSON.HRM_PERSON_ID%TYPE,
                          p_HrmEvalPersonId HRM_EVAL_PERSON.HRM_EVAL_PERSON_ID%TYPE,
                          p_initials HRM_EVAL_ANSWER.A_IDCRE%TYPE        ) RETURN NUMBER IS

  v_HrmEvalGoalId HRM_EVAL_GOAL.HRM_EVAL_GOAL_ID%TYPE;
  v_HrmPersonId HRM_EVAL_PERSON.HRM_PERSON_ID%TYPE;
  v_DateTo DATE;
  v_EvgFrom DATE;

  BEGIN

  SELECT init_id_seq.NEXTVAL INTO v_HrmEvalGoalId
  FROM dual;

  IF (p_HrmEvalPersonId IS NOT NULL) THEN
    BEGIN

      SELECT HRM_EVAL_PERSON.EVP_TO,HRM_EVAL_PERSON.HRM_PERSON_ID INTO v_DateTo,v_HrmPersonId
      FROM HRM_EVAL_PERSON
      WHERE hrm_Eval_person_id = p_HrmEvalPersonId;

      IF (v_DateTo IS NOT NULL) THEN
        v_EvgFrom := v_DateTo +1;
      ELSE
        v_EvgFrom := NULL;

      END IF;
  END;
  ELSE --p_HrmEvalPersonId is null dans le cas de saisie d'objectif individuel manuel
  BEGIN
    v_HrmPersonId := p_HrmPersonId;
  END;
  END IF;

  v_HrmEvalGoalId := createNewGoalP(  p_EvgComment
                                    ,p_DicGoalType
                                    ,v_EvgFrom
                                    ,null
                                    ,0
                                    ,p_aidcre
                                    ,p_HrmEvalChapter
                                    ,p_HrmPersonId
                                    ,p_HrmEvalPersonId);
RETURN v_HrmEvalGoalId;
  END;

  /**
  *
  */

  FUNCTION getHrmEvalGoalIndState(p_hrm_eval_goal_id IN HRM_EVAL_GOAL.hrm_eval_goal_id%TYPE)
    RETURN VARCHAR IS
    goalType HRM_EVAL_GOAL.DIC_GOAL_TYPE_ID%type;
    entretien HRM_EVAL_PERSON.EVP_DESCRIPTION%TYPE;
    resultat HRM_EVAL_NOTATION_DETAIL.EVD_DESCR%TYPE;
    result VARCHAR2(200);
    n number(3);

   cursor evpDescr is
    SELECT
      evp_description ENTRETIEN,
      nd.EVD_DESCR resultat
    FROM
      HRM_PERSON_GOAL pg,
      HRM_EVAL_PERSON ep,
      HRM_EVAL_GOAL eg,
      HRM_EVAL_ANSWER a,
      HRM_EVAL_NOTATION_DETAIL nd
    WHERE
      a.hrm_eval_person_id=ep.hrm_eval_person_id and
      a.HRM_EVAL_NOTATION_DETAIL_ID=nd.HRM_EVAL_NOTATION_DETAIL_ID(+) and
      eg.hrm_eval_goal_id=pg.HRM_EVAL_GOAL_ID AND
      pg.hrm_Eval_person_eval_id=ep.HRM_EVAL_PERSON_ID(+)
      AND eg.dic_goal_type_id='IND'
      AND pg.hrm_eval_goal_id = p_hrm_eval_goal_id and
        a.hrm_eval_goal_id=eg.hrm_eval_goal_id;
    ROWevpDescr evpDescr%ROWTYPE;
  BEGIN
    select dic_goal_type_id into goalType
    from hrm_eval_goal where hrm_eval_goal_id = p_hrm_eval_goal_id;
    if (goalType<>'IND') then return ''; end if;

    result := NULL;
    open evpDescr;
    fetch evpDescr into ROWevpDescr;
      while not(evpDescr%notfound) loop

        --recherche de la valeur de la notation
        IF (ROWevpDescr.entretien IS NOT NULL) THEN
        BEGIN
          result := ROWevpDescr.entretien||' '||NVL(ROWevpDescr.resultat,'');
        END;
        ELSE
          result := ROWevpDescr.entretien;
        END IF;

        fetch evpDescr into ROWevpDescr;
      end loop;

      close evpDescr;

    RETURN result;

  END getHrmEvalGoalIndState;

  FUNCTION createNewGoalP(p_EvgComment  HRM_EVAL_GOAL.EVG_COMMENT%type
                        ,p_DicGoalType HRM_EVAL_GOAL.DIC_GOAL_TYPE_ID%type
                        ,p_EvgFrom     HRM_EVAL_GOAL.EVG_FROM%type
                        ,p_EvgTo       HRM_EVAL_GOAL.EVG_TO%type
                        ,p_EpgWeight   HRM_PERSON_GOAL.EPG_WEIGHT%type
                        ,p_aidcre      HRM_EVAL_GOAL.A_IDCRE%type
                        ,p_HrmEvalChapter   HRM_EVAL_GOAL.HRM_EVAL_CHAPTER_ID%type
                        ,p_HrmPersonId  HRM_PERSON_GOAL.HRM_PERSON_ID%type
                        ,p_HrmEvalPersonId  HRM_PERSON_GOAL.HRM_EVAL_PERSON_INPUT_ID%type ) return HRM_EVAL_GOAL.HRM_EVAL_GOAL_ID%type is
    v_HrmEvalGoalId HRM_EVAL_GOAL.HRM_EVAL_GOAL_ID%type;
    p_EvgFrom2 HRM_EVAL_GOAL.EVG_FROM%type;
    p_EvgTo2   HRM_EVAL_GOAL.EVG_TO%type;
  begin

  p_EvgFrom2 := null;
  p_EvgTo2   := null;
  if (p_DicGoalType<>'IND') then
  begin
    p_EvgFrom2 := p_EvgFrom;
    p_EvgTo2 := p_EvgTo;
  end;
  end if;

  if (p_EvgFrom2 is null) then
    p_EvgFrom2:=p_EvgFrom;
  end if;

  SELECT
    init_id_seq.NEXTVAL INTO v_HrmEvalGoalId
  FROM
    dual;

  INSERT INTO HRM_EVAL_GOAL
      (HRM_EVAL_GOAL_ID, EVG_COMMENT, DIC_GOAL_TYPE_ID, EVG_FROM, EVG_TO, A_DATECRE, A_IDCRE,HRM_EVAL_CHAPTER_ID, EVG_WEIGHT) VALUES
      (v_HrmEvalGoalId,p_EvgComment,p_DicGoalType, p_EvgFrom2, p_EvgTo2, SYSDATE, p_aidcre,p_HrmEvalChapter,p_EpgWeight );

  INSERT INTO HRM_PERSON_GOAL
      (HRM_EVAL_GOAL_ID, HRM_PERSON_ID, A_DATECRE, A_IDCRE, EPG_POINTS, EPG_WEIGHT,EPG_FROM, EPG_TO, HRM_EVAL_PERSON_INPUT_ID) VALUES
       (v_HrmEvalGoalId,p_HrmPersonId,SYSDATE, p_aidcre, NULL, p_EpgWeight,p_EvgFrom, p_EvgTo, p_HrmEvalPersonId);


RETURN v_HrmEvalGoalId;

  end;


  FUNCTION copyNewGoalInd( p_hrmPersonId   HRM_PERSON_GOAL.HRM_PERSON_ID%type,
                           p_hrmEvalGoalId HRM_EVAL_GOAL.HRM_EVAL_GOAL_ID%type,
                           p_weight        HRM_PERSON_GOAL.EPG_WEIGHT%type,
                           errmsg out      varchar2) return number is

  ret number(1);
  v_EvgComment  HRM_EVAL_GOAL.EVG_COMMENT%type;
  v_DicGoalType HRM_EVAL_GOAL.DIC_GOAL_TYPE_ID%type;
  v_EvgFrom     HRM_EVAL_GOAL.EVG_FROM%type;
  v_EvgTo       HRM_EVAL_GOAL.EVG_TO%type;
  v_aidcre      HRM_EVAL_GOAL.A_IDCRE%type;
  v_HrmEvalChapter HRM_EVAL_GOAL.HRM_EVAL_CHAPTER_ID%type;
  v_HrmEvalGoalId  HRM_EVAL_GOAL.HRM_EVAL_GOAL_ID%type;


  BEGIN
    ret := 3;

    select
      g.HRM_EVAL_CHAPTER_ID,
      EVG_COMMENT,
      EPG_FROM,
      EPG_TO,
      DIC_GOAL_TYPE_ID,
      g.A_IDCRE
    into
      v_HrmEvalChapter,
      v_EvgComment,
      v_EvgFrom,
      v_EvgTo,
      v_DicGoalType,
      v_aidcre
    from
      HRM_EVAL_GOAL g,
      HRM_PERSON_GOAL pg
    where
       g.HRM_EVAL_GOAL_ID=pg.HRM_EVAL_GOAL_ID
       and g.hrm_eval_goal_id=p_hrmEvalGoalId;

  v_HrmEvalGoalId := createNewGoalP(  v_EvgComment
                                    ,'IND'
                                    ,v_EvgFrom
                                    ,v_EvgTo
                                    ,p_weight
                                    ,v_aidcre
                                    ,v_HrmEvalChapter
                                    ,p_hrmPersonId
                                    ,null);


    return ret;
  END;

  FUNCTION getEmpCommPreference( p_HrmPersonId HRM_PERSON.HRM_PERSON_ID%type) return varchar2 is
  /**
  * retourne la préférence de communication de la personne
  *  retourne PAPER en cas d'erreur
  *  valeurs possibles : PAPER, MAIL
  */
    pref varchar2(6);
  begin
    select
     decode(count(*),0,KEY_COMM_PREF_PAPER,KEY_COMM_PREF_MAIL) into pref
    from
      hrm_person p
    where
      hrm_person_id=p_HrmPersonId and
      per_Email is not null;

    return pref;

  exception when no_data_found then
    return KEY_COMM_PREF_PAPER;

  end;


  PROCEDURE getEvalPersonNames(ids varchar2, returnValue out varchar2)  is

  ret varchar2(4000);
  TYPE         ref0 IS REF CURSOR;
  cur0         ref0;
  n varchar2(122);
  sqlstmt varchar2(4000);
  begin
    sqlstmt := 'select per_first_name||'' ''||per_last_name names from '||
               'hrm_eval_person ev,hrm_person p where p.hrm_person_id=ev.hrm_person_id '||
               'and hrm_eval_person_id in ('||ids||')';
    ret:='';

    OPEN cur0 FOR sqlStmt;

    LOOP
    FETCH cur0 INTO n;
    EXIT WHEN cur0%NOTFOUND;
      ret := ret||','||n;
  END LOOP;

    close cur0;
    returnValue :=  substr(ret,2);

  end;

/**
*
*public static int ERROR       = 0; //when technical error is encountred
  public static int FATAL_ERROR = 1; //return by plsql
  public static int WARNING     = 2; //return by plsql
  public static int OK          = 3; //return by plsql
*
*/


  function sendMailWithEvalPersonLink(p_senderPersonId HRM_PERSON.HRM_PERSON_iD%type, p_evalPersonId HRM_EVAL_PERSON.HRM_PERSON_ID%type, msg out varchar2) return number is
    email_sender hrm_person.PER_EMAIL%type;
    email_dest hrm_person.PER_EMAIL%type;
    email_body varchar2(4000);
    email_subject varchar2(200);
    vErrorMessages varchar2(4000);
    vErrorCodes    varchar2(4000);
    vTempRaw       raw(4000)     := 'E72848574873FE293482AB4930C934567891374454DE6456465AB837D7839E00290F939A929BC03CB035132AB4';
    vTempBLOB      blob          := vTempRaw;
    vMailID        number;
    vMail          EML_SENDER.TMAIL;
    vMessageRetour varchar2(1000);
    email_destExist number(1);
    testEmail number(1);
begin
    getEvalPersonNames(p_evalPersonId,vMessageRetour);

     select
      count(*) into testEmail
    from
      HRM_PERSON
    WHERE
      HRM_PERSON_ID=p_senderPersonId and per_email is not null;

    if (testEmail>0) then

    begin
      select
        per_first_name||' '||per_last_name||' <'||per_email||'>' into email_sender
      from
        HRM_PERSON
      WHERE
        HRM_PERSON_ID=p_senderPersonId;
     end;
    else
      begin
        msg:='You have no email set.';
        return 1;
      end;
    end if;

    select
      count(*) into email_destExist
    from
      hrm_Person p,
      hrm_Eval_person ep
    where
      ep.hrm_person_id=p.HRM_PERSON_ID and
      per_email is not null and
      ep.HRM_EVAL_PERSON_ID=p_evalPersonId;

    if (email_destExist=0) then
      begin
        msg:=vMessageRetour||' has no email set.';
        return 1;
      end;
    end if;

    select
      per_email into email_dest
    from
      hrm_Person p,
      hrm_Eval_person ep
    where
      ep.hrm_person_id=p.HRM_PERSON_ID and
      ep.HRM_EVAL_PERSON_ID=p_evalPersonId;

    email_body :='<html><body>Bonjour,'||
    '<br>Vous accéderez à votre entretien en cliquant sur le lien suivant : <a href=http://127.0.0.1:8870/crystalReport/JRCReportExport.jsp?prompt0='|| p_evalPersonId||'>Votre entretien</a>'||
    '<br><br>'||
    'Le service salaire des ressources humaines se tient à votre disposition.</body></html>';



    dbms_java.set_output(5000);
    -- Fills e-mail's fields
    vMail.mSender         := email_sender;
    vMail.mReplyTo        := email_sender;
    vMail.mRecipients     := email_dest;
    vMail.mCcRecipients   := null;--'CcRecipient <rrimbert@proconcept.ch>';
    vMail.mBccRecipients  := '';
    vMail.mNotification   := 0;
    vMail.mPriority       := EML_SENDER.cPRIOTITY_NORMAL_LEVEL;
    vMail.mCustomHeaders  := 'X-Mailer: PCS mailer';
    vMail.mSubject        := 'Votre entretien '||vMessageRetour ;
    vMail.mBodyPlain      := null;--'Hello world !';
    vMail.mBodyHTML       := email_body;-- 'Hello <B>World</B><BR>How are you ?';
    vMail.mSendMode       := EML_SENDER.cSENDMODE_IMMEDIATE_FORCED;
    vMail.mDateToSend     := sysdate;
    vMail.mBackupMode     := EML_SENDER.cBACKUP_NONE;
    vMail.mBackupOptions  := '';

    vErrorCodes           :=
    EML_SENDER.Send(aErrorMessages => vErrorMessages, aMailID => vMailID, aMail => vMail);
    msg := vMessageRetour;
  return 3;
  exception when others then
    begin
      msg :='error sending email to '||vMessageRetour;
      return 1;
    end;

   end sendMailWithEvalPersonLink;

  function evalPersonControlBeforeCreate(p_HrmPersonId HRM_EVAL_PERSON.HRM_PERSON_ID%TYPE
                           ,p_HrmEvalProgramId HRM_EVAL_PROGRAM.HRM_EVAL_PROGRAM_ID%TYPE
                           ,p_EvgFrom     HRM_EVAL_GOAL.EVG_FROM%type
                           ,p_EvgTo       HRM_EVAL_GOAL.EVG_TO%type
                           ,errmsg out      varchar2) return number is
    evalExist number(1);
  begin
    evalExist:=0;
    select
      count(*) into evalExist
    from
      hrm_eval_person
    where
      hrm_person_id=p_HrmPersonId
      and hrm_eval_program_id=p_HrmEvalProgramId
      AND ( (p_EvgFrom >= evp_from) or (p_EvgTo <=evp_to) );

    if (evalExist=0) then
    return WEB_FUNCTIONS.RETURN_OK;
    else
      errmsg := 'Un entretien existe déjà pour cette période ('||p_EvgFrom||','||p_EvgTo||')';
      return WEB_FUNCTIONS.RETURN_ERROR;
    end if;
  end evalPersonControlBeforeCreate;

END Web_Hrm_Functions;
