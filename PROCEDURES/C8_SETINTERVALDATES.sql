--------------------------------------------------------
--  DDL for Procedure C8_SETINTERVALDATES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C8_SETINTERVALDATES" (aFrom      in varchar2,
                                                aTo        in varchar2,
                                                aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
is
  /**
  * Description  Initialisation des variables "package" ACT_FUNCTIONS.DATE_FROM et ACT_FUNCTIONS.DATE_TO
                 afin de pouvoir les exploiter par le biais de vues d'interrogation
  *
  * @author   Bruno Lachausse
  * @version  21.06.2001
  * @public
  * @param    aFrom       Date de ...
  * @param    aTo         Date à  ...
  * @param    aRefCursor  Variable curseur en entrée/sortie permettant l'exploitation de la procédure par Cystal Report 8
  * .........
  * @return   return value for functions
  */
begin
  ACT_FUNCTIONS.DATE_FROM := to_date(aFrom, 'yyyymmdd');
  ACT_FUNCTIONS.DATE_TO   := to_date(aTo, 'yyyymmdd');
  open aRefCursor for
    select *
      from DUAL;
end;
