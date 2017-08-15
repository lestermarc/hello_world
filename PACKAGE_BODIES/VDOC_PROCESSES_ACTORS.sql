--------------------------------------------------------
--  DDL for Package Body VDOC_PROCESSES_ACTORS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "VDOC_PROCESSES_ACTORS" 
IS
   FUNCTION manager (
      table_in   IN   VARCHAR2,
      group_in   IN   VARCHAR2,
      sqlid_in   IN   VARCHAR2,
      user_in    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      l_sql       pcs.pc_sqlst.sqlstmnt%TYPE;
      tpl_name    VARCHAR2 (100);
      csr_names   t_ref;
      l_retour    VARCHAR2 (4000);
   BEGIN
      l_sql :=
         REPLACE (pcs.pc_lib_sql.getsql (table_in,
                                         group_in,
                                         sqlid_in,
                                         NULL,
                                         'ANSI SQL',
                                         FALSE
                                        ),
                  ':PCS_COMPANY_NAME',
                  '''' || pcs.PC_I_LIB_SESSION.getcompanyowner || ''''
                 );

      OPEN csr_names FOR TO_CHAR (l_sql) USING user_in;

      FETCH csr_names
       INTO tpl_name;

      WHILE csr_names%FOUND
      LOOP
         IF l_retour IS NULL
         THEN
            l_retour := tpl_name;
         ELSE
            l_retour := l_retour || ',' || tpl_name;
         END IF;

         FETCH csr_names
          INTO tpl_name;
      END LOOP;

      RETURN l_retour;
   END;

   FUNCTION actor_id (user_in IN VARCHAR2, table_in IN VARCHAR2)
      RETURN econcept.eco_user_links.eul_rec_id%TYPE
   IS
      l_result   econcept.eco_user_links.eul_rec_id%TYPE;
   BEGIN
      SELECT eul_rec_id
        INTO l_result
        FROM econcept.eco_user_links l
       WHERE EXISTS (
                SELECT 1
                  FROM econcept.eco_users u
                 WHERE ecu_account_name = user_in
                   AND l.eco_users_id = u.eco_users_id)
         AND eul_tab = table_in
         AND EXISTS (
                SELECT 1
                  FROM econcept.eco_company c
                 WHERE ecc_code = com_currentschema
                   AND c.eco_company_id = l.eco_company_id)
         AND ROWNUM = 1;

      RETURN l_result;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (-20000,
                                     user_in
                                  || ' not found in '
                                  || com_currentschema
                                 );
   END;
END;
