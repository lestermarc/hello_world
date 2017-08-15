--------------------------------------------------------
--  DDL for Package Body IMP_PUBLIC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_PUBLIC" 
is
  function TONUMBER(pString varchar)
    return number
  is
    tmp number;
  begin
    begin
      --Si la valeur est null, on retourne 0
      if (pString is null) then
        return 0;
      end if;

      --Conversion de la string en nombre
      tmp  := to_number(pString);
    --Si il y a un problème, on renvoie -1
    exception
      when others then
        tmp  := -1;
    end;

    return tmp;
  end TONUMBER;

  function imp_CheckCCP(pRefNumber varchar2)
    return number
  is
    type TtblCCP is table of varchar2(20)
      index by binary_integer;

    vtblCCP TtblCCP;
    vCont   varchar2(20);
    vKey    varchar2(2);
  begin
    select column_value
    bulk collect into vtblCCP
      from table(charListToTable(pRefNumber, '-') );

    if vtblCCP.count = 3 then
      vCont  := lpad(vtblCCP(1), 2, '0') || lpad(vtblCCP(2), 6, '0');
      vKey   := vtblCCP(3);
    elsif vtblCCP.count = 1 then
      vCont  := lpad(substr(vtblCCP(1), 1, length(vtblCCP(1) ) - 1), 8, '0');
      vKey   := substr(vtblCCP(1), length(vtblCCP(1) ), 1);
    else
      return 0;
    end if;

    if pcs.pcstonumber(replace(pRefNumber, '-') ) is null then
      return 0;
    else
      if ACS_FUNCTION.Modulo10(vCont) = vKey then
        return 1;
      else
        return 0;
      end if;
    end if;
  end imp_CheckCCP;

  -- Vérifie si la valeur existe pour le descode en question
  function CheckDescodeValue(iDescodeName in varchar2, iDescodeValue in varchar2)
    return number
  is
    lnResult integer;
  begin
    if iDescodeValue is null then
      lnResult  := 1;
    else
      select sign(count(*) )
        into lnResult
        from V_COM_CPY_PCS_CODES
       where GCGNAME = upper(iDescodeName)
         and gclcode = iDescodeValue;
    end if;

    return lnResult;
  end CheckDescodeValue;

  -- Renvoi la valeur numérique max autorisée pour un champ
  function GetNumberFieldMaxValue(iTableName in varchar2, iFieldName in varchar2)
    return number
  is
    lnLength    number;
    lnPrecision number;
  begin
    begin
      -- Rechercher le format du champ en question
      select nvl(DATA_PRECISION, 0)
           , nvl(DATA_SCALE, 0)
        into lnLength
           , lnPrecision
        from all_tab_columns
       where OWNER = PCS.PC_I_LIB_SESSION.GETCOMPANYOWNER
         and TABLE_NAME = upper(iTableName)
         and COLUMN_NAME = upper(iFieldName);
    exception
      when others then
        lnLength     := 0;
        lnPrecision  := 0;
    end;

    return(power(10, lnLength - lnPrecision) - power(10, -1 * lnPrecision) );
  end GetNumberFieldMaxValue;

  -- Renvoi la description d'un champ
  function GetFieldDescr(iFieldName in varchar2)
    return varchar2
  as
  begin
    return IMP_LIB_TOOLS.GetFieldDescr(iFieldName);
  end GetFieldDescr;
end IMP_PUBLIC;
