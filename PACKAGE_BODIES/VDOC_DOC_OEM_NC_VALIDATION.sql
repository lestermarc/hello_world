--------------------------------------------------------
--  DDL for Package Body VDOC_DOC_OEM_NC_VALIDATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "VDOC_DOC_OEM_NC_VALIDATION" 
IS
/**
* Package contenant les fonctions VDOC pour la pré-saisie
*
*     VERSION 10.02
*
* @Author VDOC Team on 20.05.2010
*
*
*/

   /****************************************************************
   **  Liste des tâches à prendre en charge dans vdoc
   **  renvoi une table structurée avec type rt_documents_to_start
   * select * from table(vdoc_acc_pre_entry_validation.wfl_activities_to_start)
   *****************************************************************/
   FUNCTION wfl_activities_to_start
      RETURN tt_documents_to_start PIPELINED
   IS
      v_sql_stmt   CLOB;

      TYPE ref0 IS REF CURSOR;

      cur0         ref0;
      out_rec      rt_documents_to_start;
   BEGIN
      v_sql_stmt :=
         pcs.pc_functions.getsql ('ACT_DOCUMENT',
                                  'vDoc',
                                  'ListProcessACT_PRE_ENTRY_VALIDATION',
                                  NULL,
                                  'ANSI SQL',
                                  FALSE
                                 );

      IF NOT v_sql_stmt IS NULL AND LENGTH (v_sql_stmt) > 0
      THEN
         OPEN cur0 FOR TO_CHAR (v_sql_stmt);

         LOOP
            FETCH cur0
             INTO out_rec;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;
      END IF;
   END wfl_activities_to_start;

   /**
    *  a : PRE_DOC_NUMBER ex. DM-0910022 20100909
    *  b : sys_title ex. RRI sysdate
    */
   PROCEDURE wfl_complete_activity (p_rec_id VARCHAR2, p_state VARCHAR2)
   IS
      l_rec_id   wfl_process_instances.pri_rec_id%TYPE;
   BEGIN
      l_rec_id := TO_NUMBER (p_rec_id);
      com_vdoc.wfl_attribute_by_name ('ACT_DOCUMENT',
                                      p_rec_id,
                                      'ACCEPTED',
                                      p_state
                                     );
      com_vdoc.wfl_complete_activity ('ACT_DOCUMENT', p_rec_id);
   END;

   /**
    * retourne la commande sql pour l'initialisation de champs en fonction du user passé en paramètre
    * ex. retour :
    * select 1 INIT_VALUE1, 'Commande fournisseur' INIT_GAU_DESCRIBE from dual
    *
    *
    * test it :  select vdoc_act_pre_entry_validation.get_sql_for_initialization('toto') from dual;
    *
    *
    */
   FUNCTION get_sql_for_initialization (pusername VARCHAR2)
      RETURN CLOB
   IS
      v_sql_stmt   CLOB;
   BEGIN
      v_sql_stmt := EMPTY_CLOB;
      v_sql_stmt :=
         pcs.pc_functions.getsql ('ACT_DOCUMENT',
                                  'VDOC',
                                  'InitFieldACT_PRE_ENTRY_VALIDATION',
                                  NULL,
                                  'ANSI SQL',
                                  FALSE
                                 );
      RETURN v_sql_stmt;
   END;
END VDOC_DOC_OEM_NC_VALIDATION;
