--------------------------------------------------------
--  DDL for Package Body LPM_LIB_VFLD_BENEFICIARY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LPM_LIB_VFLD_BENEFICIARY" 
is
  function getFieldLabel(iFieldName in varchar)
    return varchar
  is
    lvresult varchar2(80);
  begin
    select max(nvl(PDIC.FDILABEL, FLD.FLDDESCR) )
      into lvresult
      from PCS.PC_FLDSC FLD
         , PCS.PC_FDICO PDIC
     where FLD.FLDNAME = iFieldName
       and FLD.PC_FLDSC_ID = PDIC.PC_FLDSC_ID
       and PDIC.PC_LANG_ID = PCS.PC_PUBLIC.GETUSERLANGID;

    return lvresult;
  exception
    when others then
      return iFieldName;
  end GetFieldLabel;

  function getVFieldValue(iVTableName in varchar, iRecID in number, ivVFieldName in varchar, ivVFieldPCField in varchar, iFldType in varchar)
    return varchar
  is
    result varchar2(4000);
  begin
    -- Champs COM_VFIELDS_RECORD
    if ivVFieldPCField is null then
      if iFldType = 'FTBOOLEAN' then
        result  := COM_VFIELDS.GETVFBOOLEAN(iVTableName, ivVFieldName, iRecId);
      elsif iFldType in('FTDATETIME', 'FTDATE', 'FTTIME') then
        result  := to_char(COM_VFIELDS.GETVFDATE(iVTableName, ivVFieldName, iRecId), 'dd/mm/yyyy');
      elsif iFldType = 'FTSTRING' then
        result  := COM_VFIELDS.GETVFCHAR(iVTableName, ivVFieldName, iRecId);
      elsif iFldType = 'FTMEMO' then
        result  := COM_VFIELDS.GETVFMEMO(iVTableName, ivVFieldName, iRecId);
      else
        result  := COM_VFIELDS.GETVFNUMBER(iVTableName, ivVFieldName, iRecId);
      end if;
    -- Champs COM_VFIELDS_VALUE
    else
      result  := COM_VFIELDS.GETVF2VALUE(iVTableName, ivVFieldName, iRecId);
    end if;

    -- Conversion booléen litteral
    if iFldType = 'FTBOOLEAN' then
      result  :=(case
                   when result = '1' then PCS.PC_FUNCTIONS.TranslateWord('Oui')
                   when result is null then null
                   else PCS.PC_FUNCTIONS.TranslateWord('Non')
                 end);
    end if;

    return result;
  end GetVFieldValue;

  function vfields
    return tt_vfields pipelined
  is
    type t_ref_cursor is ref cursor;

    lRc         t_ref_cursor;
    lRecData    t_vfields;
    lStmtSelect varchar2(4000);
  begin
    lStmtSelect  :=
      'select distinct SCH_STUDENT_ID
                , FATHER_ITEM_ID
                , FATHER_ITEM_VALUE
                , ITEM_ID
                , ITEM_VALUE
                , FIELD_VALUE
                , FLDNAME
                , PC_VFIELD_VALUE_ID
                , FLDTYPE';

    if pcs.PC_CONFIG.getconfig('LPM_VFIELDS_VIEW', GetCompanyID, GetConliID) is not null then
      open lRc for lStmtSelect || ' FROM ' || pcs.PC_CONFIG.getconfig('LPM_VFIELDS_VIEW', GetCompanyID, GetConliID);
    else
      open lRc for lStmtSelect ||
                   ' from (select distinct LBE.SCH_STUDENT_ID
                , nvl(VFLD.FLDVIRTUALGROUP, PCS.PC_FUNCTIONS.TranslateWord(''Divers'') ) as FATHER_ITEM_ID
                , nvl(VFLD.FLDVIRTUALGROUP, PCS.PC_FUNCTIONS.TranslateWord(''Divers'') ) as FATHER_ITEM_VALUE
                , VFLD.PC_FLDSC_ID ITEM_ID
                , null ITEM_VALUE
                , null FIELD_VALUE
                , VFLD.FLDVIRTUALSEQ
                , VFLD.FLDVIRTUALGROUP
                , VFLD.FLDNAME
                , VFLD.PC_VFIELD_VALUE_ID
                , VFLD.FLDTYPE
                 FROM LPM_BENEFICIARY LBE
                , PCS.PC_FLDSC VFLD
                , PCS.PC_TABLE TBL
                where TBL.TABNAME = ''SCH_STUDENT''
              and VFLD.PC_TABLE_ID = TBL.PC_TABLE_ID
              and VFLD.FLDVIRTUALFIELD = 1
              and VFLD.FLDVISIBLE = 1
              and (   PC_OBJECT_ID is not null
                   or     VFLD.PC_OBJECT_ID is null
                      and not exists(
                            select 1
                              from PCS.PC_FLDSC VFLD2
                                 , PCS.PC_TABLE TBL2
                             where TBL2.TABNAME = ''SCH_STUDENT''
                               and VFLD2.PC_TABLE_ID = TBL2.PC_TABLE_ID
                               and VFLD2.FLDVIRTUALFIELD = 1
                               and VFLD2.FLDVISIBLE = 1
                               and VFLD2.PC_OBJECT_ID is not null
                               and VFLD2.FLDNAME = VFLD.FLDNAME)
                  )
         order by SCH_STUDENT_ID
                , FLDVIRTUALGROUP asc nulls last
                , FLDVIRTUALSEQ asc nulls last)';
    end if;

    loop
      fetch lRc
       into lRecData.SCH_STUDENT_ID
          , lRecData.FATHER_ITEM_ID
          , lRecData.FATHER_ITEM_VALUE
          , lRecData.ITEM_ID
          , lRecData.ITEM_VALUE
          , lRecData.FIELD_VALUE
          , lRecData.FLDNAME
          , lRecData.PC_VFIELD_VALUE_ID
          , lRecData.FLDTYPE;

      exit when lRc%notfound;
      pipe row(lRecData);
    end loop;

    close lRc;

    return;
  exception
    when NO_DATA_NEEDED then
      return;
  end vfields;

    /**
  * function GetCompanyID
  * Description
  *    Fonction permettant de chercher l'id de la compagnie du schémas courant.
  * @author JFR
  * @return  L'ID de la compagnie courante.
  */
  function GetCompanyID
    return integer
  is
    CompanyID number;
  begin
    select max(pc_comp_id)
      into CompanyID
      from pcs.pc_comp
         , pcs.PC_SCRIP
     where PCS.PC_COMP.PC_SCRIP_ID = PCS.PC_SCRIP.PC_SCRIP_ID
       and PC_SCRIP.SCRDBOWNER = sys_context('USERENV', 'CURRENT_SCHEMA');

    return CompanyID;
  end GetCompanyID;

  /**
  * procedure GetConliID
  * Description
  *    Retourn l'id du groupe de config "Default"
  * @author JFR
  * @lastUpdate
  * @return  L'ID du groupe de config "Default"
  */
  function GetConliID
    return integer
  is
    ConliID number;
  begin
    select PC_CONLI_ID
      into ConliID
      from pcs.PC_CONLI
     where CONNAME = 'DEFAULT';

    return ConliID;
  end GetConliID;
end LPM_LIB_VFLD_BENEFICIARY;
