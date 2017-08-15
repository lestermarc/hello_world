--------------------------------------------------------
--  DDL for Package Body WEB_HOME_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_HOME_FCT" AS
  /**
   *  select * from table(WEB_HOME_FCT.GET_INFO_LIST('ViewHomePagePublish02a',null,1,1))
   */
  FUNCTION GET_INFO_LIST(
    pSEARCH_TYPE      IN VARCHAR2
  , pSEARCH_PARAM     IN VARCHAR2
  , pPC_LANG_ID       IN PCS.PC_LANG.PC_LANG_ID%type
  , pHRM_PERSON_ID    IN HRM_PERSON.HRM_PERSON_ID%type
  , pHAS_SEARCH_PARAM IN NUMBER DEFAULT 0
  )
    RETURN WEB_HOME_INFO_LIST_TABLE PIPELINED
  IS
    out_rec     WEB_HOME_INFO_LIST;
    v_sql_stmt  clob;
    TYPE ref0   IS REF CURSOR;
    cur0        ref0;
  BEGIN

    IF NOT pSEARCH_TYPE IS NULL THEN
      --pPcSqlstId contains the sql_id to load
      v_sql_stmt := pcs.pc_functions.getSQL('HRM_PERSON',
                                            'HrmPortalAppModule dynamicMasterViewObject',
                                            pSEARCH_TYPE, null, 'ANSI SQL', false);
      IF NOT v_sql_stmt IS NULL AND length(v_sql_stmt) > 0 THEN
        IF pHAS_SEARCH_PARAM != 0 THEN
          OPEN cur0 FOR to_char(v_sql_stmt) USING pHRM_PERSON_ID, pSEARCH_PARAM;
        ELSE
          OPEN cur0 FOR to_char(v_sql_stmt) USING pHRM_PERSON_ID;
        END IF;

        LOOP
          FETCH cur0 INTO out_rec;
          EXIT WHEN cur0%NOTFOUND;
          PIPE ROW (out_rec);
        END LOOP;

        CLOSE cur0;
      END IF;
    END IF;
  END GET_INFO_LIST;

  /**
   *
   */
  FUNCTION IS_LIKE(
    ps_VALUE    IN VARCHAR2
  , ps_SEARCH_PARAM IN VARCHAR2 DEFAULT NULL
  )
    RETURN NUMBER
  IS
    vn_result NUMBER := 0;
  BEGIN
    IF (ps_SEARCH_PARAM IS NULL) THEN
     vn_result := 1;
   ELSE
     IF ps_VALUE LIKE ps_SEARCH_PARAM THEN
       vn_result := 1;
     END IF;
   END IF;

   RETURN vn_result;
  END IS_LIKE;

  /**
   *
   */
  FUNCTION TRANSLATE_JOKER(
    ps_TEXT IN VARCHAR2
  , ps_JOKER_ANY_STRING IN VARCHAR2 DEFAULT '%'
  , ps_JOKER_ONE_CHARACTER IN VARCHAR2 DEFAULT '_'
  )
    RETURN VARCHAR2
  IS
  BEGIN
    IF ps_TEXT IS NULL THEN
      RETURN '';
    END IF;

    RETURN Translate(ps_TEXT, ps_JOKER_ANY_STRING||ps_JOKER_ONE_CHARACTER, '%_');
  END TRANSLATE_JOKER;

  /**
   *
   */
  FUNCTION APPEND_JOKER(
    ps_TEXT IN VARCHAR2
  )
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN ps_TEXT;
  END APPEND_JOKER;

END WEB_HOME_FCT;
