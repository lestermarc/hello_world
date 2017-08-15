--------------------------------------------------------
--  DDL for Package Body COM_LOOKUP_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LOOKUP_FUNCTIONS" 
is
  /**
   * Description
   *   fonction conversion en fonction des données contenue dans la table com_lookup,
   *   retournant d'office la valeur par défaut
   */
  function get_default_value(
    aComLookupType  COM_LOOKUP_VALUES.C_COM_LOOKUP_TYPE%type
  , aValueToConvert COM_LOOKUP_VALUES.CLV_VALUE_TO_CONVERT%type
  )
    return varchar2
  is
    cursor cr_PathUsingDefValue(c_comLookupType COM_LOOKUP_VALUES.C_COM_LOOKUP_TYPE%type, c_valueToConvert varchar2)
    is
      select   CLV.CLV_REC_ID
          from COM_LOOKUP_VALUES CLV
         where CLV.PAC_THIRD_ID is null
           and CLV.CLV_VALUE_TO_CONVERT = C_VALUETOCONVERT
           and CLV.C_COM_LOOKUP_TYPE = C_COMLOOKUPTYPE
      order by CLV.CLV_REC_ID asc;

    tpl_PathUsingDefValue cr_pathUsingDefValue%rowtype;
  begin
    if aComLookupType <> 'LOG-004' then   --Incoterms
      open cr_pathUsingDefValue(aComLookupType, aValueToConvert);

      fetch cr_pathUsingDefValue
       into tpl_pathUsingDefValue;

      close cr_pathUsingDefValue;

      return tpl_pathUsingDefValue.CLV_REC_ID;
    else
      return aValueToConvert;
    end if;
  end get_default_value;

  /**
   * Description
   *   fonction de conversion en fonction des données contenue dans la table com_lookup
   */
  function convert_value(
    aComLookupType  COM_LOOKUP_VALUES.C_COM_LOOKUP_TYPE%type
  , aThirdId        number
  , aValueToConvert COM_LOOKUP_VALUES.CLV_VALUE_TO_CONVERT%type
  , aSearchPath     varchar2 default 'DEF_VALUE'
  )
    return varchar2
  is
    cursor cr_PathUsingThird(
      c_comLookupType  COM_LOOKUP_VALUES.C_COM_LOOKUP_TYPE%type
    , c_pacThird_id    number
    , c_valueToConvert varchar2
    )
    is
      select   CLV.CLV_REC_ID
          from COM_LOOKUP_VALUES CLV
         where CLV.PAC_THIRD_ID = C_PACTHIRD_ID
           and CLV.CLV_VALUE_TO_CONVERT = C_VALUETOCONVERT
           and CLV.C_COM_LOOKUP_TYPE = C_COMLOOKUPTYPE
      order by CLV.CLV_REC_ID asc;

    cursor cr_PathUsingDefValue(c_comLookupType COM_LOOKUP_VALUES.C_COM_LOOKUP_TYPE%type, c_valueToConvert varchar2)
    is
      select   CLV.CLV_REC_ID
          from COM_LOOKUP_VALUES CLV
         where CLV.PAC_THIRD_ID is null
           and CLV.CLV_VALUE_TO_CONVERT = C_VALUETOCONVERT
           and CLV.C_COM_LOOKUP_TYPE = C_COMLOOKUPTYPE
      order by CLV.CLV_REC_ID asc;

    tpl_PathUsingThird    cr_pathUsingThird%rowtype;
    tpl_PathUsingDefValue cr_pathUsingDefValue%rowtype;
    vResult               number(12);
    vCounter              number(2)                      := 1;
    vCurrentPath          varchar2(10);
    vTempResult           number;
    vTryNextPath          boolean                        := true;
  begin
    if aComLookupType <> 'LOG-004' then   --Incoterms
      vCurrentPath  := extractline(aSearchPath, vCounter, ',', 1);

      while vCurrentPath is not null
       and vTryNextPath loop
        if vCurrentPath = 'THIRD' then
          open cr_pathUsingThird(aComLookupType, aThirdId, aValueToConvert);

          fetch cr_pathUsingThird
           into tpl_pathUsingThird;

          if cr_pathUsingThird%found then
            vTryNextPath  := false;
            vResult       := tpl_pathUsingThird.clv_rec_id;
          end if;

          close cr_pathUsingThird;
        elsif vCurrentPath = 'DEF_VALUE' then
          open cr_pathUsingDefValue(aComLookupType, aValueToConvert);

          fetch cr_pathUsingDefValue
           into tpl_pathUsingDefValue;

          if cr_pathUsingDefValue%found then
            vTryNextPath  := false;
            vResult       := tpl_pathUsingDefValue.clv_rec_id;
          end if;

          close cr_pathUsingDefValue;
        end if;

        vCounter      := vCounter + 1;
        vCurrentPath  := extractline(aSearchPath, vCounter, ',', 1);
      end loop;

      return vResult;
    else
      return aValueToConvert;
    end if;
  end convert_value;

  /**
   * Description
   *   fonction de conversion en fonction des données contenue dans la table com_lookup
   */
  function convert_number_value(
    ivComLookupType  in COM_LOOKUP_VALUES.C_COM_LOOKUP_TYPE%type
  , iThirdId         in number
  , iNumberToConvert in number
  , ivSearchPath     in varchar2 default 'DEF_VALUE'
  )
    return varchar2
  is
    cursor cr_PathUsingThird
    is
      select   CLV.CLV_REC_ID
          from COM_LOOKUP_VALUES CLV
         where CLV.PAC_THIRD_ID = iThirdId
           and PcsToNumber(CLV.CLV_VALUE_TO_CONVERT) = iNumberToConvert
           and CLV.C_COM_LOOKUP_TYPE = ivComLookupType
      order by CLV.CLV_REC_ID asc;

    cursor cr_PathUsingDefValue
    is
      select   CLV.CLV_REC_ID
          from COM_LOOKUP_VALUES CLV
         where CLV.PAC_THIRD_ID is null
           and PcsToNumber(CLV.CLV_VALUE_TO_CONVERT) = iNumberToConvert
           and CLV.C_COM_LOOKUP_TYPE = ivComLookupType
      order by CLV.CLV_REC_ID asc;

    tpl_PathUsingThird    cr_pathUsingThird%rowtype;
    tpl_PathUsingDefValue cr_pathUsingDefValue%rowtype;
    vResult               number(12);
    vCounter              number(2)                      := 1;
    vCurrentPath          varchar2(10);
    vTempResult           number;
    vTryNextPath          boolean                        := true;
  begin
    if ivComLookupType <> 'LOG-004' then   --Incoterms
      vCurrentPath  := extractline(ivSearchPath, vCounter, ',', 1);

      while vCurrentPath is not null
       and vTryNextPath loop
        if vCurrentPath = 'THIRD' then
          open cr_pathUsingThird;

          fetch cr_pathUsingThird
           into tpl_pathUsingThird;

          if cr_pathUsingThird%found then
            vTryNextPath  := false;
            vResult       := tpl_pathUsingThird.clv_rec_id;
          end if;

          close cr_pathUsingThird;
        elsif vCurrentPath = 'DEF_VALUE' then
          open cr_pathUsingDefValue;

          fetch cr_pathUsingDefValue
           into tpl_pathUsingDefValue;

          if cr_pathUsingDefValue%found then
            vTryNextPath  := false;
            vResult       := tpl_pathUsingDefValue.clv_rec_id;
          end if;

          close cr_pathUsingDefValue;
        end if;

        vCounter      := vCounter + 1;
        vCurrentPath  := extractline(ivSearchPath, vCounter, ',', 1);
      end loop;

      return vResult;
    else
      return to_char(iNumberToConvert);
    end if;
  end convert_number_value;
end COM_LOOKUP_FUNCTIONS;
