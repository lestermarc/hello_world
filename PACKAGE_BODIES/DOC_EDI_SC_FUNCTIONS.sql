--------------------------------------------------------
--  DDL for Package Body DOC_EDI_SC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_SC_FUNCTIONS" 
is

  /**
  * Description
  *    Modifie le status du job
  */
  procedure setJobStatus(aJobId in DOC_EDI_IMPORT_JOB.DOC_EDI_IMPORT_JOB_ID%type, aState DOC_EDI_IMPORT_JOB.C_EDI_JOB_STATUS%type)
  is
    pragma autonomous_transaction;
  begin
    update DOC_EDI_IMPORT_JOB
       set C_EDI_JOB_STATUS = aState
     where DOC_EDI_IMPORT_JOB_ID = aJobId;

    commit;
  end setJobStatus;

  /**
  * Description
  *   Converti une string en date selon le format Stepcom
  */
  function toDate(aString in varchar2, aFormat in varchar2)
    return date
  is
  begin
    case
--       when aFormat = 'YYMMDD' then
--         return to_date(aString, 'YYMMDD');
--       when aFormat = 'YYMMDDHHMM' then
--         return to_date(aString, 'YYMMDDHH24MI');
    when aFormat = '102' then
        return to_date(aString, 'YYYYMMDD');
      when aFormat = '203' then
        return to_date(aString, 'YYYYMMDDHH24MI');
      when aFormat = '204' then
        return to_date(aString, 'YYYYMMDDHH24MISS');
--       when aFormat = 'CCYYMMDDHHMMSSttt' then
--         return to_date(aString, 'YYYYMMDDHH24MISS');
    else
        ra('PCS - Invalid date format');
    end case;
  end toDate;

  /**
  * Description
  *    Converti une string en number selon le format Stepcom (p.ex :  9(12)v99
  */
  function toNumber(aString in varchar2, aFormat in varchar2)
    return number
  is
    vLength    pls_integer;
    vPrecision varchar2(20);
    vFillChar  varchar2(1);
    vString    varchar2(30);
    vPattern   varchar2(20);
  begin
    if aFormat is null then
      -- si pas de format, conversion simple
      return to_number(aString);
    else
      -- longueur total de la chaine de caractères
      vLength     := to_number(extractLine(extractLine(extractLine(aFormat, 1, 'v'), 2, '('), 1, ')') );
      -- précision de la conversion
      vPrecision  := extractLine(aFormat, 2, 'v');
      -- caractère de remplissage du pattern
      vFillChar   := extractLine(aFormat, 1, '(');
      vString := substr(aString,-vLength, vLength);
      -- ajout du séparateur décimal
      vString     :=
        substr(lpad(vString, vLength, '0'), 1, vLength - length(vPrecision) ) ||
        '.' ||
        substr(lpad(vString, vLength, '0'), vLength - length(vPrecision) + 1);
      -- définition du pattern de conversion
      vPattern    := lpad(vFillChar, vLength - length(vPrecision), '9') || '.' || vPrecision;
      --return to_number(vPattern);
      return to_number(vString, vPattern);
    end if;
  exception
    -- en cas d'erreur on retourne null
    when others then
      return null;
  end toNumber;

end DOC_EDI_SC_FUNCTIONS;
