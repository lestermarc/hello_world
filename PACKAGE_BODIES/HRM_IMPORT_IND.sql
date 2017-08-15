--------------------------------------------------------
--  DDL for Package Body HRM_IMPORT_IND
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IMPORT_IND" 
IS

  -- variable globale
  chk_provisory integer;

PROCEDURE hrm_import_process (docid NUMBER,
      IntImportType             PLS_INTEGER,
      StrSeparator              Char,
      IntEmplCodePos            PLS_INTEGER,
      IntElemCodePos            PLS_INTEGER,
      IntAmountPos              PLS_INTEGER,
      IntDateFromPos            PLS_INTEGER,
      IntDateToPos              PLS_INTEGER,
      StrDateFormat             VARCHAR2,
      IntEmplCodeLen            PLS_INTEGER,
      IntElemCodeLen            PLS_INTEGER,
      IntAmountLen              PLS_INTEGER,
      IntDateFromLen            PLS_INTEGER,
      IntDateToLen              PLS_INTEGER
      )
   IS
      /**
      * Procedure HRM_IMPORT_PROCESS
      * @version 1.0
      * @date 02/2005
      * @author rhermann
      * @since Oracle 9.2
      *
      * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
      *
      * Procédure d'importation d'un fichier CLOB
      *
      * Modifications:
      *
      *
      */

      Type StrLineType is table of varchar2(4000) index by binary_integer;
      Type StrEmployeeCodeType is table of varchar2(2000) index by binary_integer;
      Type StrElementCodeType is table of varchar2(2000) index by binary_integer;
      Type DateFromType is table of date index by binary_integer;
      Type DateToType is table of date index by binary_integer;
      Type NumAmountType is table of NUMBER(16,5) index by binary_integer;

      ClobContent               CLOB;
      StrToimport               StrLineType;
      StrEmployeeCode           StrEmployeeCodeType;
      StrElementCode            StrElementCodeType;
      DateFrom                  DateFromType;
      DateTo                    DateToType;
      NumAmount                 NumAmountType;

      IntCurrentPosCR           PLS_INTEGER;
      IntPrevPosCR              PLS_INTEGER;
      IntLine                   PLS_INTEGER;



   BEGIN
      IntPrevPosCR              := 0;
      IntCurrentPosCR           := 0;
      IntLine                   := 1;

      /*
      Select import type :
             1 = ascii flat file
             2 = ascii character delimited file ( CSV )

      In case of CSV, %Pos variables indicate the position ( relative )
      in case of a fixed length file, %Pos variables indicate first bytes of fields
      */
      /* IntImportType             := 1;

      StrSeparator              := ',';       -- Séparateur en cas de CSV
      IntEmplCodePos            := 1;         -- Position relative en cas de CSV, sinon position du 1er caractère du code employé
      IntElemCodePos            := 11;         -- Position relative en cas de CSV, sinon position du 1er caractère du code élément
      IntDateFromPos            := 31;         -- Position relative en cas de CSV, sinon position du 1er caractère de la date début
      IntDateToPos              := 39;         -- Position relative en cas de CSV, sinon position du 1er caractère de la date fin
      IntAmountPos              := 22;         -- Position relative en cas de CSV, sinon position du 1er caractère du montant
      StrDateFormat             := 'yyyymmdd';-- Format des dates dans le fichier

      --Only for fixed length files

      IntEmplCodeLen            := 10;        -- Longueur du code employé
      IntElemCodeLen            := 11;        -- Longueur du code élément
      IntAmountLen              := 9;         -- Longueur du montant
      IntDateFromLen            := 8;         -- Longueur de la date début
      IntDateToLen              := 8;         -- Longueur de la date fin

      */

      /*
      **************************************
      Exemple de fichier longueur fixe:
      **************************************

      < Employe>< Element ><montant><début >< fin  >
      No_EmployeCodeElement1234567892005020120050228

      IntImportType = 1
      IntEmplCodePos = 1                            IntEmplCodeLen = 10
      IntElemCodePos = 11                           IntElemCodeLen = 11
      IntDateFromPos = 31                           IntDateFromLen = 8
      IntDateToPos = 39                             IntDateToLen = 8
      IntAmountPos = 22                             IntAmountLen = 9



       **************************************
       Exemple de fichier CSV
       **************************************
       <Employe>,<elément>,<date début>,<date fin>,<montant>

       IntImportType = 2

       IntEmplCodePos = 1
       IntElemCodePos = 2
       IntDateFromPos = 3
       IntDateToPos = 4
       IntAmountPos = 5

       */

       /*
       Select file to import
       */
      SELECT imd_content
        INTO ClobContent
        FROM hrm_import_doc
       WHERE hrm_import_doc_id = docid;

      LOOP
             /*
           1. Last position of chr(10) is saved in PrevLineNr
           2. Find the next position of chr(10) after the previous one
           3. The record to import is the content between positions 1 and 2
           */
         IntPrevPosCR             := IntCurrentPosCR;
         IntCurrentPosCR          := DBMS_LOB.INSTR (ClobContent, CHR (10), IntPrevPosCR + 1, 1);

         /*
         Exit when no further chr(10) found
         */
         EXIT WHEN IntCurrentPosCR = 0;


         StrToImport(IntLine)     :=
            TRIM (DBMS_LOB.SUBSTR (ClobContent,
                                   IntCurrentPosCR - IntPrevPosCR - 1,
                                   IntPrevPosCR + 1
                                  )
                 );



         If IntImportType = 1 then

           StrEmployeeCode(IntLine) := substr(StrToImport(IntLine),IntEmplCodePos,IntEmplCodeLen);
           StrElementCode(IntLine)  := substr(StrToImport(IntLine),IntElemCodePos,IntElemCodeLen);
           DateFrom(IntLine)        := TO_DATE(substr(StrToImport(IntLine),IntDateFromPos,IntDateFromLen),StrDateFormat);
           DateTo(IntLine)          := TO_DATE(substr(StrToImport(IntLine),IntDateToPos,IntDateToLen),StrDateFormat);
           NumAmount(IntLine)       := substr(StrToImport(IntLine),IntAmountPos,IntAmountLen);


         else

           /*
           CHARACTER DELIMITED FILE
           */

           StrEmployeeCode(IntLine):= getsubstr(StrToImport(IntLine), StrSeparator, IntEmplCodePos );
           StrElementCode(IntLine):= getsubstr(StrToImport(IntLine), StrSeparator, IntElemCodePos );
           DateFrom(IntLine)      := TO_DATE(getsubstr(StrToImport(IntLine), StrSeparator, IntDateFromPos ),StrDateFormat);
           DateTo(IntLine)        := TO_DATE(getsubstr(StrToImport(IntLine), StrSeparator, IntDateToPos ),StrDateFormat);
           NumAmount(IntLine)     := getsubstr(StrToImport(IntLine), StrSeparator, IntAmountPos );

         end if;


         IntLine                  := IntLine +1 ;


       END LOOP;


       FORALL IntLine IN StrToImport.FIRST..StrToImport.LAST
       insert into hrm_import_log bulk(
       HRM_IMPORT_LOG_ID,
       PC_IMPORT_DATA_ID,                      -- NULL dans le cas d'importation CLOB
       HRM_IMPORT_DOC_ID,
       IML_TRANSFER_CODE,                      -- 1 = remplace, 2 = ajoute, 3 = insère
       IML_EMP_CODE,                           -- Code employé
       HRM_EMPLOYEE_ID,
       IML_ELEM_CODE,                          -- Code élément
       HRM_ELEMENTS_ID,
       IML_VALUE_FROM,
       IML_VALUE_TO,
       IML_VALUE,
       IML_TEXT,                               -- Texte de remplacement
       IML_TIME_RATIO,
       IML_BASE_AMOUNT,
       IML_PER_RATE,
       IML_RATE,
       IML_FOREIGN_VALUE,
       IML_REF_VALUE,
       IML_ZL,
       IML_EX_RATE,
       IML_EX_TYPE,
       IML_UPDATE_MODE,                        -- 0 = non tranféré, 1 = insertion, 2 = mise à jour
       IML_IMPORT_DATE,
       IML_TRANSFERRED,
       IML_TRANSFER_DATE,
       /*
          Codes erreurs
          2,Le code de la personne importée n'a pas de correspondance
          3,Le code de l'élément et de la personne n'ont pas de correspondance
         10,Impossible d'insérer cet élément pour cet employé
         11,Cet élément existe déjà pour cet employé
         12,Erreur à l'insertion de cet élément
         13,Cette constante existe déjà pour cet employé
         14,Erreur à l'insertion de cette constante
          1,Le code de l'élément importé n'a pas de correspondance
       */
       IML_IMP_ERROR_CODE,
       IML_TRA_ERROR_CODE,
       IML_IS_VAR)
        (select init_id_seq.nextval, null, docid,
        1,
        StrEmployeeCode(IntLine),                                         -- Code Employé
        ip.HRM_PERSON_ID,
        StrElementCode(IntLine),                                          -- Code Elément
        ie.HRM_ELEMENTS_ID,
        DateFrom(IntLine),                                                -- Date de
        DateTo(IntLine),                                                  -- Date à
        nvl(NumAmount(IntLine),0),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        0,
        sysdate,
        0,
        null,
        case when ip.hrm_person_id is null then '2'
                  when ie.hrm_elements_id is null then '3'
               end,
        null,
        case when upper(hrm_elements_prefixes_id)='EM' then 1 else 0 end
        FROM
       hrm_elements_family f,
       hrm_elements_import_code ie,
       hrm_person_import_code ip,
       hrm_import_doc d
     WHERE
       f.hrm_elements_id(+) = ie.hrm_elements_id and
       ie.hrm_import_type_id (+) = d.hrm_import_type_id and
       ip.hrm_import_type_id (+) = d.hrm_import_type_id and
       ie.eim_import_code (+)= StrElementCode(IntLine)  and                -- Code élément
       ip.pim_import_code (+)= StrEmployeeCode(IntLine)  and               -- Code employé
       d.hrm_import_doc_id = docid and
       length(StrToImport(IntLine))>0
       );



   END hrm_import_process;


   PROCEDURE hrm_import_process_STD (docid NUMBER)
   IS
      /**
      * Procedure HRM_IMPORT_PROCESS
      * @version 1.0
      * @date 02/2005
      * @author rhermann
      * @since Oracle 9.2
      *
      * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
      *
      * Procédure d'importation d'un fichier CLOB
      *
      * Modifications:
      *
      *
      */

      Type StrLineType is table of varchar2(4000) index by binary_integer;
      Type StrEmployeeCodeType is table of varchar2(2000) index by binary_integer;
      Type StrElementCodeType is table of varchar2(2000) index by binary_integer;
      Type DateFromType is table of date index by binary_integer;
      Type DateToType is table of date index by binary_integer;
      Type NumAmountType is table of NUMBER(16,5) index by binary_integer;

      ClobContent               CLOB;
      StrToimport               StrLineType;
      IntCurrentPosCR           PLS_INTEGER;
      IntPrevPosCR              PLS_INTEGER;
      IntLine                   PLS_INTEGER;
      StrEmployeeCode           StrEmployeeCodeType;
      StrElementCode            StrElementCodeType;
      DateFrom                  DateFromType;
      DateTo                    DateToType;
      NumAmount                 NumAmountType;
      IntImportType             PLS_INTEGER;
      StrSeparator              Char;
      IntEmplCodePos            PLS_INTEGER;
      IntElemCodePos            PLS_INTEGER;
      IntAmountPos              PLS_INTEGER;
      IntDateFromPos            PLS_INTEGER;
      IntDateToPos              PLS_INTEGER;
      StrDateFormat             VARCHAR2(10);
      IntEmplCodeLen            PLS_INTEGER;
      IntElemCodeLen            PLS_INTEGER;
      IntAmountLen              PLS_INTEGER;
      IntDateFromLen            PLS_INTEGER;
      IntDateToLen              PLS_INTEGER;


   BEGIN
      IntPrevPosCR              := 0;
      IntCurrentPosCR           := 0;
      IntLine                   := 1;

      /*
      Select import type :
             1 = ascii flat file
             2 = ascii character delimited file ( CSV )

      In case of CSV, %Pos variables indicate the position ( relative )
      in case of a fixed length file, %Pos variables indicate first bytes of fields
      */
      IntImportType             := 2;

      StrSeparator              := ';';       -- Séparateur en cas de CSV
      IntEmplCodePos            := 1;         -- Position relative en cas de CSV, sinon position du 1er caractère du code employé
      IntElemCodePos            := 2;         -- Position relative en cas de CSV, sinon position du 1er caractère du code élément
      IntDateFromPos            := 4;         -- Position relative en cas de CSV, sinon position du 1er caractère de la date début
      IntDateToPos              := 5;         -- Position relative en cas de CSV, sinon position du 1er caractère de la date fin
      IntAmountPos              := 3;         -- Position relative en cas de CSV, sinon position du 1er caractère du montant
      StrDateFormat             := 'dd.mm.yyyy';-- Format des dates dans le fichier
      /*
      Only for fixed length files

      IntEmplCodeLen            := 10;        -- Longueur du code employé
      IntElemCodeLen            := 11;        -- Longueur du code élément
      IntAmountLen              := 9;         -- Longueur du montant
      IntDateFromLen            := 8;         -- Longueur de la date début
      IntDateToLen              := 8;         -- Longueur de la date fin
	  */


      /*
      **************************************
      Exemple de fichier longueur fixe:
      **************************************

      < Employe>< Element ><montant><début >< fin  >
      No_EmployeCodeElement1234567892005020120050228

      IntImportType = 1
      IntEmplCodePos = 1                            IntEmplCodeLen = 10
      IntElemCodePos = 11                           IntElemCodeLen = 11
      IntDateFromPos = 31                           IntDateFromLen = 8
      IntDateToPos = 39                             IntDateToLen = 8
      IntAmountPos = 22                             IntAmountLen = 9



       **************************************
       Exemple de fichier CSV
       **************************************
       <Employe>,<elément>,<date début>,<date fin>,<montant>

       IntImportType = 2

       IntEmplCodePos = 1
       IntElemCodePos = 2
       IntDateFromPos = 3
       IntDateToPos = 4
       IntAmountPos = 5

       */

       /*
       Select file to import
       */
      SELECT imd_content
        INTO ClobContent
        FROM hrm_import_doc
       WHERE hrm_import_doc_id = docid;

      LOOP
             /*
           1. Last position of chr(10) is saved in PrevLineNr
           2. Find the next position of chr(10) after the previous one
           3. The record to import is the content between positions 1 and 2
           */
         IntPrevPosCR             := IntCurrentPosCR;
         IntCurrentPosCR          := DBMS_LOB.INSTR (ClobContent, CHR (10), IntPrevPosCR + 1, 1);

         /*
         Exit when no further chr(10) found
         */
         EXIT WHEN IntCurrentPosCR = 0;


         StrToImport(IntLine)     :=
            TRIM (DBMS_LOB.SUBSTR (ClobContent,
                                   IntCurrentPosCR - IntPrevPosCR - 1,
                                   IntPrevPosCR + 1
                                  )
                 );



         If IntImportType = 1 then

           StrEmployeeCode(IntLine) := substr(StrToImport(IntLine),IntEmplCodePos,IntEmplCodeLen);
           StrElementCode(IntLine)  := substr(StrToImport(IntLine),IntElemCodePos,IntElemCodeLen);
           DateFrom(IntLine)        := TO_DATE(substr(StrToImport(IntLine),IntDateFromPos,IntDateFromLen),StrDateFormat);
           DateTo(IntLine)          := TO_DATE(substr(StrToImport(IntLine),IntDateToPos,IntDateToLen),StrDateFormat);
           NumAmount(IntLine)       := substr(StrToImport(IntLine),IntAmountPos,IntAmountLen);


         else

           /*
           CHARACTER DELIMITED FILE
           */

           StrEmployeeCode(IntLine):= getsubstr(StrToImport(IntLine), StrSeparator, IntEmplCodePos );
           StrElementCode(IntLine):= getsubstr(StrToImport(IntLine), StrSeparator, IntElemCodePos );
           DateFrom(IntLine)      := TO_DATE(getsubstr(StrToImport(IntLine), StrSeparator, IntDateFromPos ),StrDateFormat);
           DateTo(IntLine)        := TO_DATE(getsubstr(StrToImport(IntLine), StrSeparator, IntDateToPos ),StrDateFormat);
           NumAmount(IntLine)     := getsubstr(StrToImport(IntLine), StrSeparator, IntAmountPos );



         end if;


         IntLine                  := IntLine +1 ;


       END LOOP;


       FORALL IntLine IN StrToImport.FIRST..StrToImport.LAST
       insert into hrm_import_log bulk(
       HRM_IMPORT_LOG_ID,
       PC_IMPORT_DATA_ID,                      -- NULL dans le cas d'importation CLOB
       HRM_IMPORT_DOC_ID,
       IML_TRANSFER_CODE,                      -- 1 = remplace, 2 = ajoute, 3 = insère
       IML_EMP_CODE,                           -- Code employé
       HRM_EMPLOYEE_ID,
       IML_ELEM_CODE,                          -- Code élément
       HRM_ELEMENTS_ID,
       IML_VALUE_FROM,
       IML_VALUE_TO,
       IML_VALUE,
       IML_TEXT,                               -- Texte de remplacement
       IML_TIME_RATIO,
       IML_BASE_AMOUNT,
       IML_PER_RATE,
       IML_RATE,
       IML_FOREIGN_VALUE,
       IML_REF_VALUE,
       IML_ZL,
       IML_EX_RATE,
       IML_EX_TYPE,
       IML_UPDATE_MODE,                        -- 0 = non tranféré, 1 = insertion, 2 = mise à jour
       IML_IMPORT_DATE,
       IML_TRANSFERRED,
       IML_TRANSFER_DATE,
       /*
          Codes erreurs
          2,Le code de la personne importée n'a pas de correspondance
          3,Le code de l'élément et de la personne n'ont pas de correspondance
         10,Impossible d'insérer cet élément pour cet employé
         11,Cet élément existe déjà pour cet employé
         12,Erreur à l'insertion de cet élément
         13,Cette constante existe déjà pour cet employé
         14,Erreur à l'insertion de cette constante
          1,Le code de l'élément importé n'a pas de correspondance
       */
       IML_IMP_ERROR_CODE,
       IML_TRA_ERROR_CODE,
       IML_IS_VAR)
        (select init_id_seq.nextval, null, docid,
        1,
        StrEmployeeCode(IntLine),                                         -- Code Employé
        ip.HRM_PERSON_ID,
        StrElementCode(IntLine),                                          -- Code Elément
        ie.HRM_ELEMENTS_ID,
        DateFrom(IntLine),                                                -- Date de
        DateTo(IntLine),                                                  -- Date à
        NumAmount(IntLine),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        0,
        sysdate,
        0,
        null,
        case when ip.hrm_person_id is null then '2'
                  when ie.hrm_elements_id is null then '3'
               end,
        null,
        case when upper(hrm_elements_prefixes_id)='EM' then 1 else 0 end
        FROM
       hrm_elements_family f,
       hrm_elements_import_code ie,
       hrm_person_import_code ip,
       hrm_import_doc d
     WHERE
       f.hrm_elements_id(+) = ie.hrm_elements_id and
       ie.hrm_import_type_id (+) = d.hrm_import_type_id and
       ip.hrm_import_type_id (+) = d.hrm_import_type_id and
       ie.eim_import_code(+) = StrElementCode(IntLine) and                -- Code élément
       ip.pim_import_code(+) = StrEmployeeCode(IntLine) and               -- Code employé
       d.hrm_import_doc_id = docid and
       length(StrToImport(IntLine))>0
       );



   END hrm_import_process_STD;

   PROCEDURE hrm_import_process_VAR (docid NUMBER)
   IS
      /**
      * Procedure HRM_IMPORT_PROCESS
      * @version 1.0
      * @date 02/2005
      * @author rhermann
      * @since Oracle 9.2
      *
      * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
      *
      * Procédure d'importation d'un fichier CLOB
      *
      * Modifications:
      *
      *
      */

      Type StrLineType is table of varchar2(4000) index by binary_integer;
      Type StrEmployeeCodeType is table of varchar2(2000) index by binary_integer;
      Type StrElementCodeType is table of varchar2(2000) index by binary_integer;
      Type DateFromType is table of date index by binary_integer;
      Type DateToType is table of date index by binary_integer;
      Type NumAmountType is table of NUMBER(16,5) index by binary_integer;

      ClobContent               CLOB;
      StrToimport               StrLineType;
      IntCurrentPosCR           PLS_INTEGER;
      IntPrevPosCR              PLS_INTEGER;
      IntLine                   PLS_INTEGER;
      StrEmployeeCode           StrEmployeeCodeType;
      StrElementCode            StrElementCodeType;
      DateFrom                  DateFromType;
      DateTo                    DateToType;
      NumAmount                 NumAmountType;
      IntImportType             PLS_INTEGER;
      StrSeparator              Char;
      IntEmplCodePos            PLS_INTEGER;
      IntElemCodePos            PLS_INTEGER;
      IntAmountPos              PLS_INTEGER;
      IntDateFromPos            PLS_INTEGER;
      IntDateToPos              PLS_INTEGER;
      StrDateFormat             VARCHAR2(10);
      IntEmplCodeLen            PLS_INTEGER;
      IntElemCodeLen            PLS_INTEGER;
      IntAmountLen              PLS_INTEGER;
      IntDateFromLen            PLS_INTEGER;
      IntDateToLen              PLS_INTEGER;


   BEGIN
      IntPrevPosCR              := 0;
      IntCurrentPosCR           := 0;
      IntLine                   := 1;

      /*
      Select import type :
             1 = ascii flat file
             2 = ascii character delimited file ( CSV )
      */
      IntImportType             := 2;

      StrSeparator              := ';';       -- Séparateur en cas de CSV
      IntEmplCodePos            := 1;         -- Position relative en cas de CSV, sinon position du 1er caractère du code employé
      IntElemCodePos            := 2;         -- Position relative en cas de CSV, sinon position du 1er caractère du code élément
      IntDateFromPos            := 4;         -- Position relative en cas de CSV, sinon position du 1er caractère de la date début
      IntDateToPos              := 5;         -- Position relative en cas de CSV, sinon position du 1er caractère de la date fin
      IntAmountPos              := 3;         -- Position relative en cas de CSV, sinon position du 1er caractère du montant
      StrDateFormat             := 'dd.mm.yyyy';-- Format des dates dans le fichier
      /*
      Only for fixed length files

      IntEmplCodeLen            := 10;        -- Longueur du code employé
      IntElemCodeLen            := 11;        -- Longueur du code élément
      IntAmountLen              := 9;         -- Longueur du montant
      IntDateFromLen            := 8;         -- Longueur de la date début
      IntDateToLen              := 8;         -- Longueur de la date fin
	  */

      SELECT imd_content
        INTO ClobContent
        FROM hrm_import_doc
       WHERE hrm_import_doc_id = docid;

      LOOP
             /*
           1. Last position of chr(10) is saved in PrevLineNr
           2. Find the next position of chr(10) after the previous one
           3. The record to import is the content between positions 1 and 2
           */
         IntPrevPosCR             := IntCurrentPosCR;
         IntCurrentPosCR          := DBMS_LOB.INSTR (ClobContent, CHR (10), IntPrevPosCR + 1, 1);

         /*
         Exit when no further chr(10) found
         */
         EXIT WHEN IntCurrentPosCR = 0;


         StrToImport(IntLine)     :=
            TRIM (DBMS_LOB.SUBSTR (ClobContent,
                                   IntCurrentPosCR - IntPrevPosCR - 1,
                                   IntPrevPosCR + 1
                                  )
                 );



         If IntImportType = 1 then

           StrEmployeeCode(IntLine) := substr(StrToImport(IntLine),IntEmplCodePos,IntEmplCodeLen);
           StrElementCode(IntLine)  := substr(StrToImport(IntLine),IntElemCodePos,IntElemCodeLen);
           DateFrom(IntLine)        := TO_DATE(substr(StrToImport(IntLine),IntDateFromPos,IntDateFromLen),StrDateFormat);
           DateTo(IntLine)          := TO_DATE(substr(StrToImport(IntLine),IntDateToPos,IntDateToLen),StrDateFormat);
           NumAmount(IntLine)       := substr(StrToImport(IntLine),IntAmountPos,IntAmountLen);


         else

           /*
           CHARACTER DELIMITED FILE
           */

           StrEmployeeCode(IntLine):= getsubstr(StrToImport(IntLine), StrSeparator, IntEmplCodePos );
           StrElementCode(IntLine):= getsubstr(StrToImport(IntLine), StrSeparator, IntElemCodePos );
           DateFrom(IntLine)      := TO_DATE(getsubstr(StrToImport(IntLine), StrSeparator, IntDateFromPos ),StrDateFormat);
           DateTo(IntLine)        := TO_DATE(getsubstr(StrToImport(IntLine), StrSeparator, IntDateToPos ),StrDateFormat);
           NumAmount(IntLine)     := getsubstr(StrToImport(IntLine), StrSeparator, IntAmountPos );



         end if;

        -- TEST QU'IL N'EXISTE PAS DE DECOMPTE EN PROVISOIRE POUR LES EMPLOYES CONCERNES
        select count(*) into chk_provisory
        from hrm_history h
        where hit_pay_period=hrm_date.activeperiodenddate
        and hit_definitive=0
        and exists (select 1
                    from hrm_person p
                    where p.hrm_person_id=h.hrm_employee_id
                    and p.emp_number=StrEmployeeCode(IntLine));

           if chk_provisory > 0
           then
                raise_application_error(-20001,
                                        chr(10)||'>>>>>>>>>>>>>>>>>'||chr(10)||chr(10)||
                                        'Le matricule '||StrEmployeeCode(IntLine)||' est en cours de calcul. Importation impossible. Le bulletin doit être supprimé avant l''importation'||
                                        chr(10)||chr(10)||'>>>>>>>>>>>>>>>>>'
                                        );
           end if;

         IntLine                  := IntLine +1 ;


       END LOOP;


       FORALL IntLine IN StrToImport.FIRST..StrToImport.LAST
       insert into hrm_import_log bulk(
       HRM_IMPORT_LOG_ID,
       PC_IMPORT_DATA_ID,                      -- NULL dans le cas d'importation CLOB
       HRM_IMPORT_DOC_ID,
       IML_TRANSFER_CODE,                      -- 1 = remplace, 2 = ajoute, 3 = insère
       IML_EMP_CODE,                           -- Code employé
       HRM_EMPLOYEE_ID,
       IML_ELEM_CODE,                          -- Code élément
       HRM_ELEMENTS_ID,
       IML_VALUE_FROM,
       IML_VALUE_TO,
       IML_VALUE,
       IML_TEXT,                               -- Texte de remplacement
       IML_TIME_RATIO,
       IML_BASE_AMOUNT,
       IML_PER_RATE,
       IML_RATE,
       IML_FOREIGN_VALUE,
       IML_REF_VALUE,
       IML_ZL,
       IML_EX_RATE,
       IML_EX_TYPE,
       IML_UPDATE_MODE,                        -- 0 = non tranféré, 1 = insertion, 2 = mise à jour
       IML_IMPORT_DATE,
       IML_TRANSFERRED,
       IML_TRANSFER_DATE,
       /*
          Codes erreurs
          2,Le code de la personne importée n'a pas de correspondance
          3,Le code de l'élément et de la personne n'ont pas de correspondance
         10,Impossible d'insérer cet élément pour cet employé
         11,Cet élément existe déjà pour cet employé
         12,Erreur à l'insertion de cet élément
         13,Cette constante existe déjà pour cet employé
         14,Erreur à l'insertion de cette constante
          1,Le code de l'élément importé n'a pas de correspondance
       */
       IML_IMP_ERROR_CODE,
       IML_TRA_ERROR_CODE,
       IML_IS_VAR)
        (select init_id_seq.nextval, null, docid,
        1,
        StrEmployeeCode(IntLine),                                         -- Code Employé
        ip.HRM_PERSON_ID,
        StrElementCode(IntLine),                                          -- Code Elément
        ie.HRM_ELEMENTS_ID,
        DateFrom(IntLine),                                                -- Date de
        DateTo(IntLine),                                                  -- Date à
        decode(ele.ELE_MULTI_CURRENCY,1,round(NumAmount(IntLine)*hrm_itx.exchangeRateDate2(cry.currency,4,hrm_date.activeperiod),2),NumAmount(IntLine)),
        null,
        null,
        null,
        null,
        null,
        decode(ele.ELE_MULTI_CURRENCY,1,NumAmount(IntLine),null),
        null,
        null,
        decode(ele.ELE_MULTI_CURRENCY,1,hrm_itx.exchangeRateDate2(cry.currency,4,hrm_date.activeperiod),null),
        null,
        0,
        sysdate,
        0,
        null,
        case when ip.hrm_person_id is null then '2'
                  when ie.hrm_elements_id is null then '3'
               end,
        null,
        case when upper(hrm_elements_prefixes_id)='EM' then 1 else 0 end
        FROM
       hrm_elements_family f,
       (select ele.hrm_elements_id,ele.ele_stat_code
        from hrm_elements ele
        where exists (select 1 from hrm_elements_family fam
                      where ele.hrm_elements_id=fam.hrm_elements_id
                      and fam.HRM_ELEMENTS_PREFIXES_ID='EM')
          union all
        select null, 'not_gs' from dual) ie,
       (select hrm_person_id, emp_number from hrm_person
         union all
        select null, 'not_emp' from dual) ip,
       hrm_import_doc d,
       hrm_elements ele,
       (select acs_financial_currency_id, currency
        from acs_financial_currency fcur, pcs.pc_curr cur
        where fcur.pc_curr_id=cur.pc_curr_id) cry
     WHERE
       f.hrm_elements_id(+) = ie.hrm_elements_id and
       ele.hrm_elements_id(+) = ie.hrm_elements_id and
       ele.acs_financial_currency_id=cry.acs_financial_currency_id(+) and
       ie.ele_stat_code(+) = case
                              when exists (select 1 from hrm_elements ele, hrm_elements_family fam
                                          where ele.hrm_elements_id=fam.hrm_elements_id
                                          and fam.HRM_ELEMENTS_PREFIXES_ID='EM'
                                          and ele.ele_stat_code = StrElementCode(IntLine))
                              then StrElementCode(IntLine)
                              else 'not_gs'
                            end and
       ip.emp_number(+) = case
                           when exists (select 1 from hrm_person where emp_number = StrEmployeeCode(IntLine))
                           then StrEmployeeCode(IntLine)
                           else 'not_emp'
                         end and
       d.hrm_import_doc_id = docid and
       length(StrToImport(IntLine))>0
       );



   END hrm_import_process_VAR;

   PROCEDURE hrm_import_process_CONST (docid NUMBER)
   IS
      /**
      * Procedure HRM_IMPORT_PROCESS
      * @version 1.0
      * @date 02/2005
      * @author rhermann
      * @since Oracle 9.2
      *
      * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
      *
      * Procédure d'importation d'un fichier CLOB
      *
      * Modifications:
      *
      *
      */

      Type StrLineType is table of varchar2(4000) index by binary_integer;
      Type StrEmployeeCodeType is table of varchar2(2000) index by binary_integer;
      Type StrElementCodeType is table of varchar2(2000) index by binary_integer;
      Type DateFromType is table of date index by binary_integer;
      Type DateToType is table of date index by binary_integer;
      Type NumAmountType is table of NUMBER(16,5) index by binary_integer;

      ClobContent               CLOB;
      StrToimport               StrLineType;
      IntCurrentPosCR           PLS_INTEGER;
      IntPrevPosCR              PLS_INTEGER;
      IntLine                   PLS_INTEGER;
      StrEmployeeCode           StrEmployeeCodeType;
      StrElementCode            StrElementCodeType;
      DateFrom                  DateFromType;
      DateTo                    DateToType;
      NumAmount                 NumAmountType;
      IntImportType             PLS_INTEGER;
      StrSeparator              Char;
      IntEmplCodePos            PLS_INTEGER;
      IntElemCodePos            PLS_INTEGER;
      IntAmountPos              PLS_INTEGER;
      IntDateFromPos            PLS_INTEGER;
      IntDateToPos              PLS_INTEGER;
      StrDateFormat             VARCHAR2(10);
      IntEmplCodeLen            PLS_INTEGER;
      IntElemCodeLen            PLS_INTEGER;
      IntAmountLen              PLS_INTEGER;
      IntDateFromLen            PLS_INTEGER;
      IntDateToLen              PLS_INTEGER;


   BEGIN
      IntPrevPosCR              := 0;
      IntCurrentPosCR           := 0;
      IntLine                   := 1;

      /*
      Select import type :
             1 = ascii flat file
             2 = ascii character delimited file ( CSV )
      */
      IntImportType             := 2;

      StrSeparator              := ';';       -- Séparateur en cas de CSV
      IntEmplCodePos            := 1;         -- Position relative en cas de CSV, sinon position du 1er caractère du code employé
      IntElemCodePos            := 2;         -- Position relative en cas de CSV, sinon position du 1er caractère du code élément
      IntDateFromPos            := 4;         -- Position relative en cas de CSV, sinon position du 1er caractère de la date début
      IntDateToPos              := 5;         -- Position relative en cas de CSV, sinon position du 1er caractère de la date fin
      IntAmountPos              := 3;         -- Position relative en cas de CSV, sinon position du 1er caractère du montant
      StrDateFormat             := 'dd.mm.yyyy';-- Format des dates dans le fichier
      /*
      Only for fixed length files

      IntEmplCodeLen            := 10;        -- Longueur du code employé
      IntElemCodeLen            := 11;        -- Longueur du code élément
      IntAmountLen              := 9;         -- Longueur du montant
      IntDateFromLen            := 8;         -- Longueur de la date début
      IntDateToLen              := 8;         -- Longueur de la date fin
	  */

      SELECT imd_content
        INTO ClobContent
        FROM hrm_import_doc
       WHERE hrm_import_doc_id = docid;

      LOOP
             /*
           1. Last position of chr(10) is saved in PrevLineNr
           2. Find the next position of chr(10) after the previous one
           3. The record to import is the content between positions 1 and 2
           */
         IntPrevPosCR             := IntCurrentPosCR;
         IntCurrentPosCR          := DBMS_LOB.INSTR (ClobContent, CHR (10), IntPrevPosCR + 1, 1);

         /*
         Exit when no further chr(10) found
         */
         EXIT WHEN IntCurrentPosCR = 0;


         StrToImport(IntLine)     :=
            TRIM (DBMS_LOB.SUBSTR (ClobContent,
                                   IntCurrentPosCR - IntPrevPosCR - 1,
                                   IntPrevPosCR + 1
                                  )
                 );



         If IntImportType = 1 then

           StrEmployeeCode(IntLine) := substr(StrToImport(IntLine),IntEmplCodePos,IntEmplCodeLen);
           StrElementCode(IntLine)  := substr(StrToImport(IntLine),IntElemCodePos,IntElemCodeLen);
           DateFrom(IntLine)        := TO_DATE(substr(StrToImport(IntLine),IntDateFromPos,IntDateFromLen),StrDateFormat);
           DateTo(IntLine)          := TO_DATE(substr(StrToImport(IntLine),IntDateToPos,IntDateToLen),StrDateFormat);
           NumAmount(IntLine)       := substr(StrToImport(IntLine),IntAmountPos,IntAmountLen);


         else

           /*
           CHARACTER DELIMITED FILE
           */

           StrEmployeeCode(IntLine):= getsubstr(StrToImport(IntLine), StrSeparator, IntEmplCodePos );
           StrElementCode(IntLine):= getsubstr(StrToImport(IntLine), StrSeparator, IntElemCodePos );
           DateFrom(IntLine)      := TO_DATE(getsubstr(StrToImport(IntLine), StrSeparator, IntDateFromPos ),StrDateFormat);
           DateTo(IntLine)        := TO_DATE(getsubstr(StrToImport(IntLine), StrSeparator, IntDateToPos ),StrDateFormat);
           NumAmount(IntLine)     := getsubstr(StrToImport(IntLine), StrSeparator, IntAmountPos );



         end if;

        -- TEST QU'IL N'EXISTE PAS DE DECOMPTE EN PROVISOIRE POUR LES EMPLOYES CONCERNES
        select count(*) into chk_provisory
        from hrm_history h
        where hit_pay_period=hrm_date.activeperiodenddate
        and hit_definitive=0
        and exists (select 1
                    from hrm_person p
                    where p.hrm_person_id=h.hrm_employee_id
                    and p.emp_number=StrEmployeeCode(IntLine));

           if chk_provisory > 0
           then
                raise_application_error(-20001,
                                        chr(10)||'>>>>>>>>>>>>>>>>>'||chr(10)||chr(10)||
                                        'Le matricule '||StrEmployeeCode(IntLine)||' est en cours de calcul. Importation impossible. Le bulletin doit être supprimé avant l''importation'||
                                        chr(10)||chr(10)||'>>>>>>>>>>>>>>>>>'
                                        );
           end if;

         IntLine                  := IntLine +1 ;


       END LOOP;


       FORALL IntLine IN StrToImport.FIRST..StrToImport.LAST
       insert into hrm_import_log bulk(
       HRM_IMPORT_LOG_ID,
       PC_IMPORT_DATA_ID,                      -- NULL dans le cas d'importation CLOB
       HRM_IMPORT_DOC_ID,
       IML_TRANSFER_CODE,                      -- 1 = remplace, 2 = ajoute, 3 = insère
       IML_EMP_CODE,                           -- Code employé
       HRM_EMPLOYEE_ID,
       IML_ELEM_CODE,                          -- Code élément
       HRM_ELEMENTS_ID,
       IML_VALUE_FROM,
       IML_VALUE_TO,
       IML_VALUE,
       IML_TEXT,                               -- Texte de remplacement
       IML_TIME_RATIO,
       IML_BASE_AMOUNT,
       IML_PER_RATE,
       IML_RATE,
       IML_FOREIGN_VALUE,
       IML_REF_VALUE,
       IML_ZL,
       IML_EX_RATE,
       IML_EX_TYPE,
       IML_UPDATE_MODE,                        -- 0 = non tranféré, 1 = insertion, 2 = mise à jour
       IML_IMPORT_DATE,
       IML_TRANSFERRED,
       IML_TRANSFER_DATE,
       /*
          Codes erreurs
          2,Le code de la personne importée n'a pas de correspondance
          3,Le code de l'élément et de la personne n'ont pas de correspondance
         10,Impossible d'insérer cet élément pour cet employé
         11,Cet élément existe déjà pour cet employé
         12,Erreur à l'insertion de cet élément
         13,Cette constante existe déjà pour cet employé
         14,Erreur à l'insertion de cette constante
          1,Le code de l'élément importé n'a pas de correspondance
       */
       IML_IMP_ERROR_CODE,
       IML_TRA_ERROR_CODE,
       IML_IS_VAR)
        (select init_id_seq.nextval, null, docid,
        1,
        StrEmployeeCode(IntLine),                                         -- Code Employé
        ip.HRM_PERSON_ID,
        StrElementCode(IntLine),                                          -- Code Elément
        ie.HRM_ELEMENTS_ID,
        DateFrom(IntLine),                                                -- Date de
        DateTo(IntLine),                                                  -- Date à
        decode(ele.CON_MULTI_CURRENCY,1,round(NumAmount(IntLine)*hrm_itx.exchangeRateDate2(cry.currency,4,hrm_date.activeperiod),2),NumAmount(IntLine)),
        null,
        null,
        null,
        null,
        null,
        decode(ele.CON_MULTI_CURRENCY,1,NumAmount(IntLine),null),
        null,
        null,
        decode(ele.CON_MULTI_CURRENCY,1,hrm_itx.exchangeRateDate2(cry.currency,4,hrm_date.activeperiod),null),
        null,
        0,
        sysdate,
        0,
        null,
        case when ip.hrm_person_id is null then '2'
                  when ie.hrm_elements_id is null then '3'
               end,
        null,
        case when upper(hrm_elements_prefixes_id)='EM' then 1 else 0 end
        FROM
       hrm_elements_family f,
       (select con.hrm_constants_id hrm_elements_id, con.con_stat_code ele_stat_code
        from hrm_constants con
        where C_HRM_SAL_CONST_TYPE='3'
          union all
        select null, 'not_gs' from dual) ie,
       (select hrm_person_id, emp_number from hrm_person
         union all
        select null, 'not_emp' from dual) ip,
       hrm_import_doc d,
       hrm_constants ele,
       (select acs_financial_currency_id, currency
        from acs_financial_currency fcur, pcs.pc_curr cur
        where fcur.pc_curr_id=cur.pc_curr_id) cry
     WHERE
       f.hrm_elements_id(+) = ie.hrm_elements_id and
       ele.hrm_constants_id(+) = ie.hrm_elements_id and
       ele.acs_financial_currency_id=cry.acs_financial_currency_id(+) and
       ie.ele_stat_code(+) = case
                              when exists (select 1 from hrm_constants where C_HRM_SAL_CONST_TYPE='3'
                                           and con_stat_code = StrElementCode(IntLine))
                              then StrElementCode(IntLine)
                              else 'not_gs'
                            end and
       ip.emp_number(+) = case
                           when exists (select 1 from hrm_person where emp_number = StrEmployeeCode(IntLine))
                           then StrEmployeeCode(IntLine)
                           else 'not_emp'
                         end and
       d.hrm_import_doc_id = docid and
       length(StrToImport(IntLine))>0
       );

   END hrm_import_process_CONST;

   function getsubstr(Line varchar2, Sep char, pos pls_integer ) return varchar2
   is
     text varchar2(2000);
   begin
     /*
     Traitement particulier pour la première position
     */
     if pos = 1 then
          text:= substr(Line,1,instr(Line,Sep,1,pos)-1);
     /*
     Traitement particulier pour la dernière position
     */
     elsif instr(Line,Sep,1,pos)=0 then
          text := substr(Line, instr(Line,Sep, 1, pos-1)+1);
     /*
     Formule standard pour les autres
     */
     else
          text := substr(Line,instr(Line,Sep,1,pos-1)+1,instr(Line,Sep,1,pos)-instr(Line,Sep,1,pos-1)-1);
     end if;
     return text;
   end;

procedure GroupedTransfer(docId IN hrm_import_doc.hrm_import_doc_id%TYPE)
is
  -- cursor cs is based on a view wich return all import records that have no
  -- import errors and are'nt yet transferred (ie 0)
  cursor cs(idDoc hrm_import_doc.hrm_import_doc_id%TYPE) is
    SELECT
      1 isVar,
      min(b.hrm_import_log_id) importId,
      min(d.hrm_employee_elements_id) empelemId,
      b.hrm_employee_id empId,
      b.hrm_elements_id originId,
      to_char(sum(b.iml_value)) elemValue,
      sum(b.iml_value) elemNumValue,
      sum(b.IML_FOREIGN_VALUE) IML_FOREIGN_VALUE,
      max(IML_EX_RATE) IML_EX_RATE,
      decode(c.ele_format, 1, to_char(min(d.emp_num_value)), min(d.emp_value)) oldValue,
      min(c.ele_valid_from) beginDate,
      max(c.ele_valid_to) endDate,
      min(b.iml_value_from) valueFrom,
      min(d.emp_value_from) oldValueFrom,
      max(b.iml_value_to) valueTo,
      max(d.emp_value_to) oldValueTo,
      min(b.iml_transfer_code) transferMode,
      min(b.pc_import_data_id) structId,
      count(*) nbRows
    FROM
      hrm_import_log b,
      hrm_elements c,
      hrm_employee_elements d
    WHERE
      b.hrm_import_doc_id= idDoc and
      b.iml_transferred=0 and
      b.iml_imp_error_code is null and
      b.hrm_elements_id=c.hrm_elements_id and
      (d.hrm_employee_id(+) = b.hrm_employee_id and d.hrm_elements_id(+) = b.hrm_elements_id) and
      (b.iml_value_from <= d.emp_value_to(+) and b.iml_value_to >=d.emp_value_from(+))
    GROUP BY
      b.hrm_employee_id, b.hrm_elements_id, c.ele_format
    UNION ALL
    SELECT
      0,
      min(b.hrm_import_log_id) importId,
      min(d.hrm_employee_const_id) empelemId,
      b.hrm_employee_id empId,
      b.hrm_elements_id originId,
      decode(c.c_hrm_sal_const_type, 3, null, to_char(sum(b.iml_value))) elemValue,
      decode(c.c_hrm_sal_const_type, 3, sum(b.iml_value), null) elemNumValue,
      decode(c.c_hrm_sal_const_type, 3, sum(b.IML_FOREIGN_VALUE), null) IML_FOREIGN_VALUE,
      decode(c.c_hrm_sal_const_type, 3, max(b.IML_EX_RATE), null) IML_EX_RATE,
      decode(c.c_hrm_sal_const_type, 3, to_char(min(d.emc_num_value)), min(d.emc_value)) oldValue,
      min(c.con_from) beginDate,
      max(c.con_to) endDate,
      min(b.iml_value_from) valueFrom,
      min(d.emc_value_from) oldValueFrom,
      max(b.iml_value_to) valueTo,
      max(d.emc_value_to) oldValueTo,
      min(b.iml_transfer_code) transferMode,
      min(b.pc_import_data_id) structId,
      count(*) nbRows
    FROM
      hrm_import_log b,
      hrm_constants c,
      hrm_employee_const d
    WHERE
      b.hrm_import_doc_id= idDoc and
      b.iml_transferred=0 and
      b.iml_imp_error_code is null and
      b.hrm_elements_id=c.hrm_constants_id and
      (d.hrm_employee_id(+) = b.hrm_employee_id and d.hrm_constants_id(+) = b.hrm_elements_id) and
      (b.iml_value_from <= d.emc_value_to(+) and b.iml_value_to >=d.emc_value_from(+))
    GROUP BY
      b.hrm_employee_id, b.hrm_elements_id, c.c_hrm_sal_const_type;
  impRec cs%Rowtype;
  empElemId NUMBER;
  errorStatus VARCHAR2(255);
  errorNb INTEGER;
  errorCode INTEGER;
  updateMode INTEGER;

  procedure insertEmployeeElement
  is
  begin
    insert into hrm_employee_elements
    (hrm_employee_elements_id, hrm_employee_id, hrm_elements_id, emp_value, emp_num_value,EMP_FOREIGN_VALUE,EMP_EX_RATE,
     emp_from, emp_to, emp_value_from, emp_value_to, emp_active,
     a_datecre, a_idCre)
    (select init_id_seq.nextval, impRec.EmpId, impRec.OriginId,
     impRec.ElemValue, impRec.ElemNumValue, impRec.IML_FOREIGN_VALUE, impRec.IML_EX_RATE, impRec.beginDate, impRec.endDate,impRec.ValueFrom,
     impRec.ValueTo,1, sysdate, 'IMP'
     from dual);
     -- we store actual record id for further update
    select init_id_seq.currval into EmpElemId from dual;
    -- we store the fact that we inserted the record for further rollback
    updateMode := 1;
    exception
      when no_data_found then
        errorCode := 10; -- No init_id_seq.curval
  end;

  procedure insertEmployeeConstant
  is
  begin
    insert into hrm_employee_const
    (hrm_employee_const_id, hrm_employee_id, hrm_constants_id, emc_value, emc_num_value,EMC_FOREIGN_VALUE,EMC_EX_RATE,
     emc_from, emc_to, emc_value_from, emc_value_to, emc_active,
     a_datecre, a_idCre)
    (select init_id_seq.nextval, impRec.EmpId, impRec.OriginId, impRec.ElemValue,
     impRec.ElemNumValue,impRec.IML_FOREIGN_VALUE, impRec.IML_EX_RATE, impRec.beginDate, impRec.endDate,impRec.ValueFrom,
     impRec.ValueTo, 1, sysdate, 'IMP'
     from dual);
    -- we store actual record id for further update
    select init_id_seq.currval into EmpElemId from dual;
    -- we store the fact that we inserted the record for further rollback
    updateMode := 1;
    exception
      when no_data_found then
        errorCode := 10; -- No init_id_seq.curval
  end;

  -- updates employee elements testing if we have to override
  -- (ie transferMode =1) or sum (ie transferMode =2)
  -- the values. If transferMode is alarm (ie 3) we will generate an
  -- error code. Error sescriptions can be found in table
  -- Dic_imp_Transfer_errors
  procedure updateEmployeeElement(id IN hrm_employee_elements.hrm_employee_elements_id%TYPE)
  is
  begin
    if (impRec.transferMode = 1) then
      update hrm_employee_elements
        set emp_value      = impRec.ElemValue,
            emp_num_value  = impRec.ElemNumValue,
            EMP_FOREIGN_VALUE = impRec.IML_FOREIGN_VALUE,
            EMP_EX_RATE       = impRec.IML_EX_RATE,
            a_datemod      = sysdate,
            a_idMod        = 'IMP'
      where hrm_employee_elements_id = id;
      -- we store the fact that we updated the record for further rollback
      updateMode := 2;
    elsif (impRec.transferMode = 2) then
      update hrm_employee_elements
        set emp_value = to_char(emp_num_value + impRec.ElemNumValue),
            emp_num_value = emp_num_value + impRec.ElemNumValue,
            a_datemod = sysdate,
            a_idMod   = 'IMP'
      where hrm_employee_elements_id = id;
      -- we store the fact that we updated the record for further rollback
      updateMode := 2;
    else
      errorCode := 11; -- Variable already exist for this employee
      errorNb   := errorNb +1;
    end if;
    -- we store actual record id for further update
    EmpElemId := id;
    exception
      when no_data_found then
        errorCode := 12; -- error updating hrm_employee_elements record
  end;

  -- updates employee constants testing if we have to override
  -- (ie transferMode =1) or sum (ie transferMode =2)
  -- the values. If transferMode is alarm (ie 3) we will generate an
  -- error code. Error sescriptions can be found in table
  -- Dic_imp_Transfer_errors
  procedure updateEmployeeConstant(id IN hrm_employee_const.hrm_employee_const_id%TYPE)
  is
  begin
    if (impRec.transferMode = 1) then
      update hrm_employee_const
        set emc_value = impRec.ElemValue,
            emc_num_value = impRec.ElemNumValue,
            EMC_FOREIGN_VALUE = impRec.IML_FOREIGN_VALUE,
            EMC_EX_RATE       = impRec.IML_EX_RATE,
            a_datemod = sysdate,
            a_idMod   ='IMP'
      where hrm_employee_const_id = id;
      -- we store the fact that we updated the record for further rollback
      updateMode := 2;
    elsif (impRec.transferMode = 2) then
      update hrm_employee_const
        set emc_value = emc_value + impRec.ElemValue,
            emc_num_value = emc_num_value + impRec.ElemNumValue,
            a_datemod = sysdate,
            a_idMod   ='IMP'
      where hrm_employee_const_id = id;
      -- we store the fact that we updated the record for further rollback
      updateMode := 2;
    else
      errorCode := 13; -- Constant already exist for this employee
      errorNb   := errorNb +1;
    end if;
   -- we store actual record id for further update
    EmpElemId := id;
    exception
      when no_data_found then
        errorCode := 14; -- error updating hrm_employee_const record
  end;

  -- updates hrm_import_log with error_code if any, element or constant id
  -- that was either inserted or updated, document id and status tranferred
  procedure updateImportLog
  is
  begin
    update hrm_import_log
      set iml_tra_error_code    = case when errorCode <> 0 then errorCode else null end,
          hrm_empl_elements_id  = case when EmpElemId <> 0.0 then EmpElemId else null end,
          iml_transferred       = 1,
          hrm_import_doc_id     = docId,
          iml_Old_value         = impRec.oldValue,
          iml_Old_value_from    = impRec.oldValueFrom,
          iml_Old_value_to      = impRec.oldValueTo,
          iml_transfer_date     = Sysdate,
          iml_update_mode       = updateMode
    where hrm_import_log_id = imprec.importId;
    if impRec.nbRows>1 Then
      update hrm_import_log
      set iml_tra_error_code    = case when errorCode <> 0 then errorCode else null end,
          hrm_empl_elements_id  = case when EmpElemId <> 0.0 then EmpElemId else null end,
          iml_transferred       = 1,
          hrm_import_doc_id     = docId,
          iml_Old_value         = impRec.oldValue,
          iml_Old_value_from    = impRec.oldValueFrom,
          iml_Old_value_to      = impRec.oldValueTo,
          iml_transfer_date     = Sysdate,
          iml_update_mode       = 0
      where
        hrm_import_doc_id = docId and
        hrm_employee_id = impRec.empId and
        hrm_elements_id = impRec.originId and
        hrm_import_log_id <> imprec.importId;
    end if;
  end;

begin
  errorNb    := 0;
  open cs(docId);
  loop
    fetch cs into impRec;
    -- we test if we have some more records, if we d'ont we exit from the loop
    exit when cs%notFound;
    errorCode  := 0;
    updateMode := 0;
    EmpElemId  := 0;
    -- if an empElemid does not erxist it means that we have not found
    -- any variable or constant for that employee having the same validty date
    -- so we test for variable or constante and insert one
    if impRec.EmpElemId is null then
      if (impRec.IsVar = 1) then InsertEmployeeElement;
      else InsertEmployeeConstant;
      end if;
    -- if we found an empElemid we have a variable or a constant for an employee
    -- and we've got to update either variables or contants
    else
      if (impRec.IsVar = 1) then updateEmployeeElement(impRec.empElemId);
      else updateEmployeeConstant(impRec.empElemId);
      end if;
    end if;
    -- we udate hrm_import_log with variable or constant id or an error_code
    -- if one and by the way we update the transfer date, the transfer doc and
    -- the boolean transfer flag even if we have an errror
    UpdateImportLog;
    update hrm_import_doc
      set imd_tra_error_num = errorNb,
          imd_transfer_date = Sysdate,
          imd_transferred = 1
    where hrm_import_doc_id = docId;
  end loop;
  close cs;

  commit;

  exception
    when others then
      -- if an error is raised we rollback
      rollback;
end GroupedTransfer;


end;
