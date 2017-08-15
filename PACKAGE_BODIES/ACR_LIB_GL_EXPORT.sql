--------------------------------------------------------
--  DDL for Package Body ACR_LIB_GL_EXPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_LIB_GL_EXPORT" 
is
  /**
  * Description :
  *   Formatage nom du fichier physique selon données de l'enregistrement courant
  */
  function BuildFileName(iCurrentId in number)
    return varchar2
  is
    lvResult varchar2(255);
    lvSiren  PCS.PC_COMP.COM_SIREN%type;
  begin
    select COM_SIREN
      into lvSiren
      from PCS.PC_COMP
     where PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId;

    select lvSiren ||
           'FEC' ||
           to_char(YEA.FYE_END_DATE, 'YYYYMMDD') ||
           decode(AGE.C_FILE_GRANULARITY
                        , '2', '_'||AGF.AGF_PART_NUM
                        , '3', '_'||AGF.AGF_PART_NUM
                        , '4', '_' || to_char(PER_FROM.PER_START_DATE, 'MM'), '') ||
           '.xml' FILE_EXTENSION
      into lvResult
      from ACR_GL_EXPORT_FILE AGF
        , ACR_GL_EXPORT AGE
         , ACS_FINANCIAL_YEAR YEA
         , ACS_PERIOD PER_FROM
     where AGE.ACR_GL_EXPORT_ID = AGF.ACR_GL_EXPORT_ID
        and YEA.ACS_FINANCIAL_YEAR_ID = AGF.ACS_FINANCIAL_YEAR_ID
        and PER_FROM.ACS_PERIOD_ID = AGF.AGF_PERIOD_FROM_ID
       and AGF.ACR_GL_EXPORT_FILE_ID = iCurrentId;

    return lvResult;
  end BuildFileName;

  procedure PrepareEmailing(iCurrentId in number, oTo out varchar2, ioSubject in out varchar2, ioBody in out varchar2)
  is
    lrExportRow             ACR_GL_EXPORT%rowtype;
    lvDocDate                varchar2(10);
    lnNoExercice            ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type;
    lnPerNoPeriodFrom  ACS_PERIOD.PER_NO_PERIOD%type;
    lnPerNoPeriodTo      ACS_PERIOD.PER_NO_PERIOD%type;
  begin
    begin
      select *
        into lrExportRow
        from ACR_GL_EXPORT
       where ACR_GL_EXPORT_ID = iCurrentId;
    exception
      when no_data_found then
        return;
    end;

    begin
      select to_char(AGE.A_DATECRE, 'DD.MM.YYYY')
           , (select FYE_NO_EXERCICE
                from ACS_FINANCIAL_YEAR
               where ACS_FINANCIAL_YEAR_ID = AGE.ACS_FINANCIAL_YEAR_ID)
           , (select PER_NO_PERIOD
                from ACS_PERIOD
               where ACS_PERIOD_ID = AGE.AGE_PERIOD_FROM_ID)
           , (select PER_NO_PERIOD
                from ACS_PERIOD
               where ACS_PERIOD_ID = AGE.AGE_PERIOD_TO_ID)
        into lvDocDate
           , lnNoExercice
           , lnPerNoPeriodFrom
           , lnPerNoPeriodTo
        from ACR_GL_EXPORT AGE
       where ACR_GL_EXPORT_ID = iCurrentId;
    exception
      when no_data_found then
        return;
    end;

    oTo       := lrExportRow.AGE_RECEIVER_EMAIL;

    if ioSubject is null then
      ioSubject  := 'Export Grand-Livre ' || lvDocDate || ':  ' || lnNoExercice || '  ' || lnPerNoPeriodFrom || ' - ' || lnPerNoPeriodTo;
    end if;

    if ioBody is null then
      ioBody  := lvDocDate || '  ' || lnNoExercice || '  ' || lnPerNoPeriodFrom || ' - ' || lnPerNoPeriodTo;
    end if;
  end PrepareEmailing;

  /**
  * Description :
  *   Vérification si la granularité peut être appliquée à la période définie
  */
  function CheckGranularity(inGLExportId in ACR_GL_EXPORT.ACR_GL_EXPORT_ID%type)
    return boolean
  is
    lnMod    number;
    lvResult boolean;
  begin
    begin
        select decode(C_FILE_GRANULARITY
                    , '1', mod(ACS_PERIOD_FCT.GetNbMonthBetweenPer(AGE_PERIOD_FROM_ID, AGE_PERIOD_TO_ID), 12)
                    , '2', mod(ACS_PERIOD_FCT.GetNbMonthBetweenPer(AGE_PERIOD_FROM_ID, AGE_PERIOD_TO_ID), 6)
                    , '3', mod(ACS_PERIOD_FCT.GetNbMonthBetweenPer(AGE_PERIOD_FROM_ID, AGE_PERIOD_TO_ID), 3)
                    , '4', mod(ACS_PERIOD_FCT.GetNbMonthBetweenPer(AGE_PERIOD_FROM_ID, AGE_PERIOD_TO_ID), 1)
                    , 1
                     )
          into lnMod
          from ACR_GL_EXPORT
         where ACR_GL_EXPORT_ID = inGLExportId;

        if lnMod = 0 then
          lvResult  := true;
        else
          lvResult  := false;
        end if;
      exception
        when no_data_found then
          lvResult  := false;
    end;
      return lvResult;
  end CheckGranularity;

  /**
  * Description :
  *   Vérification si la granularité peut être appliquée à la période définie
  */
  function CheckGranularity2(inFileGranularity in ACR_GL_EXPORT.C_FILE_GRANULARITY%type, inPeriodFromID in ACR_GL_EXPORT.AGE_PERIOD_FROM_ID%type, inPeriodToId in ACR_GL_EXPORT.AGE_PERIOD_TO_ID%type)
    return number
  is
    lnMod    number;
    lvResult number;
  begin
    begin
        select decode(inFileGranularity
                    , '1', mod(ACS_PERIOD_FCT.GetNbMonthBetweenPer(inPeriodFromID, inPeriodToId), 12)
                    , '2', mod(ACS_PERIOD_FCT.GetNbMonthBetweenPer(inPeriodFromID, inPeriodToId), 6)
                    , '3', mod(ACS_PERIOD_FCT.GetNbMonthBetweenPer(inPeriodFromID, inPeriodToId), 3)
                    , '4', mod(ACS_PERIOD_FCT.GetNbMonthBetweenPer(inPeriodFromID, inPeriodToId), 1)
                    , 1
                     )
          into lnMod
          from dual;

        if lnMod = 0 then
          lvResult  := 1;
        else
          lvResult  := 0;
        end if;
      exception
        when no_data_found then
          lvResult  := 0;
    end;
      return lvResult;
  end CheckGranularity2;

  /**
  * Description :
  *   Vérification de l'existance d'un fichier XML pour l'export défini
  */
  function XmlFileExist(inGLExportId in ACR_GL_EXPORT.ACR_GL_EXPORT_ID%type)
    return boolean
  is
    lnNbXml  number;
    lvResult boolean;
  begin
    begin
        select count(*)
          into lnNbXml
          from ACR_GL_EXPORT_FILE
         where ACR_GL_EXPORT_ID = inGLExportId;

        if lnNbXml >= 1 then
          lvResult  := true;
        else
          lvResult  := false;
        end if;
      exception
        when no_data_found then
          lvResult  := false;
    end;
      return lvResult;
  end XmlFileExist;

  /**
  * Description :
  *   Vérification de l'existance d'un fichier XML pour l'export défini
  */
  function XmlFileExistN(inGLExportId in ACR_GL_EXPORT.ACR_GL_EXPORT_ID%type)
    return number
  is
    lnResult number;
  begin
    begin
        if XmlFileExist(inGLExportId) then
          lnResult  := 1;
        else
          lnResult  := 0;
        end if;
      exception
        when no_data_found then
          lnResult  := 0;
    end;
      return lnResult;
  end XmlFileExistN;

   /**
  * Description :
  *   Vérification de la validité de l'adresse email fournie
  */
  function verifyMail(ivEmail in ACR_GL_EXPORT.AGE_RECEIVER_EMAIL%type)
    return number
  is
    lnMailCheck number;
 begin
    begin
      select REGEXP_INSTR(ivEmail, '\w+@\w+(\.\w+)+')
      into lnMailCheck
      from dual;
    exception
      when no_data_found then
          lnMailCheck  := 0;
    end;

   if lnMailCheck > 0 then
    return 1;
   else
    return  0;
    end if;
  end verifyMail;
end ACR_LIB_GL_EXPORT;
