--------------------------------------------------------
--  DDL for Function WEB_SHOP_SEARCH_STD
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "WEB_SHOP_SEARCH_STD" (
   searchtype    VARCHAR2,
   searchparam   VARCHAR2
)
   RETURN web_shop_functions_std.web_shop_search_ids_table PIPELINED
IS
/**
*
*  Author RRI ProConcept 2008 03 10
*
* Use : multi search type : recherche standard par référence ou description
* utilisée depuis ViewObject  : ViewShopSearch2Params

SELECT * FROM TABLE(web_shop_search_std('SN, '1001'))

SELECT * FROM TABLE(web_shop_search_std('DESCR', 'NIPPEL'))

SELECT * FROM TABLE(web_shop_search_std('REF', '154-016019'))
*/
   TYPE ref0 IS REF CURSOR;

   cur0      ref0;
   out_rec   web_shop_functions_std.web_shop_search_ids; -- := web_shop_functions_std.web_shop_search_ids (NULL, NULL);
   sqlstmt   VARCHAR2 (4000);

BEGIN
   IF    (searchparam IS NULL)
      OR (searchparam = '')
      OR (searchparam = '%')
      OR (searchparam = '*')
   THEN
      BEGIN
         sqlstmt := 'SELECT null, null from dual where rownum=0';

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSIF (searchtype = 'SN') --recherche par numéro de série
   THEN
      BEGIN
         sqlstmt :=
               'SELECT '
            ||'   ENU.GCO_GOOD_ID,ENU.SEM_VALUE '
            ||' FROM '
            ||'   STM_ELEMENT_NUMBER ENU'
            ||'   ,GCO_GOOD G '
            ||'   ,WEB_GOOD W '
            || 'WHERE '
            || '  G.GCO_GOOD_ID=ENU.GCO_GOOD_ID AND '
            || '  G.GCO_GOOD_ID=W.GCO_GOOD_ID AND WGO_IS_ACTIVE=1 AND '
            || '  ENU.SEM_VALUE LIKE LIKE_PARAM (:SEM_VALUE) ORDER BY ENU.A_DATECRE DESC';

         OPEN cur0 FOR sqlstmt USING searchparam;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSIF (searchtype = 'REF') --recherche par référence
   THEN
      BEGIN
         sqlstmt :=
               'SELECT '
            || ' distinct G.GCO_GOOD_ID,null SEM_VALUE '
            || 'FROM '
            || ' GCO_GOOD G, '
            || ' WEB_GOOD W  '
            || 'WHERE '
            || ' G.gco_good_id=w.gco_good_id and wgo_is_active=1 and'
            || ' G.GOO_MAJOR_REFERENCE LIKE LIKE_PARAM(:GOO_MAJOR_REFERENCE)';

         OPEN cur0 FOR sqlstmt USING searchparam;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSIF (searchtype = 'DESCR')
   THEN
      BEGIN
         sqlstmt :=
               ' SELECT distinct GCO_GOOD_ID, SEM_VALUE from ('
            || ' SELECT distinct GCO_GOOD_ID, SEM_VALUE,goo_major_reference from ('
            || 'SELECT '
            || ' G.GCO_GOOD_ID,null SEM_VALUE, goo_major_reference '
            || ' FROM '
            || ' GCO_GOOD G  '
            || ' ,GCO_DESCRIPTION D   '
            || ' ,WEB_GOOD W   '
            || 'WHERE '
            || '  G.GCO_GOOD_ID = D.GCO_GOOD_ID '
            || '  AND G.GCO_GOOD_ID=W.GCO_GOOD_ID AND WGO_IS_ACTIVE=1'
            || '  AND D.C_DESCRIPTION_TYPE = ''01'''
            || '  AND (UPPER(D.DES_SHORT_DESCRIPTION) LIKE ''%''||UPPER(LIKE_PARAM (:DES_SHORT_DESCRIPTION))||''%''      '
            || '       OR  UPPER(D.DES_FREE_DESCRIPTION) LIKE ''%''||UPPER(LIKE_PARAM (:DES_SHORT_DESCRIPTION))||''%'')) '
            || ' ORDER BY GOO_MAJOR_REFERENCE )';

         OPEN cur0 FOR sqlstmt USING searchparam, searchparam;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSIF ((searchtype = 'INIT') OR (searchtype IS NULL))
   THEN
      BEGIN
         sqlstmt := 'SELECT 1 GCO_GOOD_ID, ''1'' SEM_VALUE FROM DUAL';

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   END IF;
END;
