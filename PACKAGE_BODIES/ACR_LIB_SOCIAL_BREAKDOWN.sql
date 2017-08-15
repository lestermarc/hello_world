--------------------------------------------------------
--  DDL for Package Body ACR_LIB_SOCIAL_BREAKDOWN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_LIB_SOCIAL_BREAKDOWN" 
is

  /**
  * Description :
  *   Contrôle des données
  */
  procedure CheckDatasIntegrity(iCurrentId in number, oErrorCode out varchar)
  is
    lvError varchar2(10);
  begin
    /*
      -20100 Le dictionnaire libre n'est pas indiqué dans la configuration des décomptes sociaux
      -20200 Email destinataire absent
      -20210 Email destinataire non valide
    */
    select case
             when (select nvl(max(ASC_DIC_IMP_FREE), ' ')  from ACR_SOCIAL_CONFIG)  = ' '   then -20100
             when ASB.ASB_RECEIVER_EMAIL is  null   then -20200
             when ASB.ASB_RECEIVER_EMAIL is not null
             and regexp_instr(ASB.ASB_RECEIVER_EMAIL, '[^@]+@[^\.]+\..+') = 0 then -20210
             else 0
           end
      into lvError
      from ACR_SOCIAL_BREAKDOWN ASB
     where ACR_SOCIAL_BREAKDOWN_ID = iCurrentId;

    if lvError < 0 then
      oErrorCode  := to_char(lvError, '99999') || '_ACR_SOCIAL_BREAKDOWN';
    end if;
  end CheckDatasIntegrity;


  /**
  * Description :
  *   Foramatage nom du fichier physique selon données de l'enregistrement courant
  */
  function BuildFileName(iCurrentId in number) return varchar2
  is
    lvResult  varchar2(255);
  begin
    select 'AOS_' ||
           substr( (select FYE_NO_EXERCICE
                      from ACS_FINANCIAL_YEAR
                     where ACS_FINANCIAL_YEAR_ID = ASB.ACS_FINANCIAL_YEAR_ID), -2)
           || '-' ||
           to_char(to_number(nvl(substr(ASB.ASB_XML_PATH
                                      , instr(ASB.ASB_XML_PATH, '-') +1
                                      , instr(ASB.ASB_XML_PATH, '.XML') - instr(ASB.ASB_XML_PATH, '-') - 1
                                       )
                               , '0'
                                )
                            ) +
                   1
                 , '00'
                  ) ||
           '.XML' FILE_EXTENSION
      into lvResult
      from ACR_SOCIAL_BREAKDOWN ASB
     where ASB.ACR_SOCIAL_BREAKDOWN_ID  = iCurrentId;

     return lvResult;
  end BuildFileName;

  procedure PrepareEmailing(iCurrentId in number ,
                            oXmlData   out clob,
                            oXmlPath   out varchar2,
                            oTo        out varchar2,
                            ioSubject  in out varchar2 ,
                            ioBody     in out varchar2
                            )
  is
    lrBreakDownRow      ACR_SOCIAL_BREAKDOWN%rowtype;
  begin
    begin
      select *
      into lrBreakDownRow
      from ACR_SOCIAL_BREAKDOWN ASB
      where ACR_SOCIAL_BREAKDOWN_ID = iCurrentId;
    exception
      when no_data_found then
        oXmlData := '';
      return;
    end;

    oTo      := lrBreakDownRow.ASB_RECEIVER_EMAIL;
    oXmlPath := lrBreakDownRow.ASB_XML_PATH;
    oXmlData := lrBreakDownRow.ASB_XML;

    if ioSubject is null then
      ioSubject  := 'Dossier DSHR ' || lrBreakDownRow.ASB_MUNICIPALITY_NUMBER;
    end if;

    if ioBody is null then
      ioBody  :=  lrBreakDownRow.ASB_MUNICIPALITY_NUMBER ||'  ' ||
                  lrBreakDownRow.ASB_MUNICIPALITY_AFFILIATED;
    end if;

  end PrepareEmailing;

end ACR_LIB_SOCIAL_BREAKDOWN;
