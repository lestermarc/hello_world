--------------------------------------------------------
--  DDL for Package Body ACT_LIB_PAYMENT_ISO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_LIB_PAYMENT_ISO" 
/**
 * Utilitaire pour paiements ISO 20022..
 *
 * @date 03.2012
 * @author rhermann
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
IS

  gcv_authorized_char CONSTANT VARCHAR2(73) :=
    '''()+,-./0123456789:?ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz ';
  gv_forbidden_char VARCHAR2(1024);


function format(
  in_value IN NUMBER)
  return VARCHAR2
is
begin
  return to_char(in_value,'FM99999999999999990.00');
end;

/**
 * Initialisation des caractères interdits.
 *
 * on pourrait utiliser une chaîne de caractères fixe
 */
procedure p_load_forbidden_chars
is
--   i pls_integer:=1;
begin
  for cpt in 1 .. 127 loop
    if (Instr(gcv_authorized_char, Chr(cpt)) = 0) then
      gv_forbidden_char := gv_forbidden_char || Chr(cpt);
    end if;
  end loop;
--   while i<128 loop
--     i:=i+1;
--     if instr(gcv_authorized_char, Chr(i))=0 then
--       gv_forbidden_char := gv_forbidden_char||chr(i);
--     end if;
--   end loop;
end;

function format(
  iv_value IN VARCHAR2)
  return VARCHAR2
is
begin
  if gv_forbidden_char is null then
    p_load_forbidden_chars;
  end if;
  return Translate(Convert(replace(iv_value,'ß', 'ss'),'US7ASCII'), gv_forbidden_char, '-');
end;


function p_Build(
  iv_command IN VARCHAR2,
  ib_use_param IN BOOLEAN)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  lv_result :=
    Replace(
      Replace(
        Replace(Trim(iv_command),
          '['||'CO]', pcs.PC_I_LIB_SESSION.GetCompanyOwner),
        '['||'COMPANY_OWNER]', pcs.PC_I_LIB_SESSION.GetCompanyOwner),
      co.cPcsOwner, 'PCS');

  if (ib_use_param) then
    lv_result :=
      'fin_acc_payment_id := :1;'||
      ' execution_date := :2;'||
      ' result := null;'||Chr(10)||
      lv_result ||
      Chr(10)||':3 := result;';
  end if;
  return
    'DECLARE'||Chr(10)||
    ' fin_acc_payment_id NUMBER(12);'||
      ' execution_date DATE;'||
      ' result XMLType;'||Chr(10)||
    'BEGIN'||Chr(10)||
    lv_result ||
    Chr(10)||'END;';
end;

procedure ValidateCommand(
  iv_command IN VARCHAR2)
is
  ln_result INTEGER := 0;
  lv_error VARCHAR2(32767);
begin
  begin
    EXECUTE IMMEDIATE
      'BEGIN '||
        ':1 := '||pcs.PC_I_LIB_SESSION.GetCompanyOwner||'.com_sqlutils.IsValidSQL(:2, :3);'||
      'END;'
      USING OUT ln_result, -- :1
            IN p_Build(iv_command, FALSE), -- :2
            OUT lv_error; -- :3

  exception
    when OTHERS then
      lv_error := sqlerrm;
  end;

  if (ln_result != 1) then
    act_mgt_payment_iso_exception.raise_exception(
      act_mgt_payment_iso_exception.EXCEPTION_INVALID_COMMAND_NO,
      lv_error);
  end if;
end;

function BuildCommand(
  iv_command IN VARCHAR2)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  lv_result := p_Build(iv_command, TRUE);
  DBMS_OUTPUT.PUT_LINE(lv_result);
  return lv_result;
  --return p_Build(iv_command, TRUE);
end;

procedure SepaNumbering (iov_Number in out varchar2)
is
  ln_MethodId    ACJ_NUMBER_METHOD.ACJ_NUMBER_METHOD_ID%type;
  lv_Prefix      ACJ_NUMBER_METHOD.DNM_PREFIX%type;
  lv_Suffix      ACJ_NUMBER_METHOD.DNM_SUFFIX%type;
  ln_Increment   ACJ_NUMBER_METHOD.DNM_INCREMENT%type;
  lv_NumberType  ACJ_NUMBER_METHOD.C_NUMBER_TYPE%type;
  ln_LastNumber  ACJ_LAST_NUMBER.NAP_LAST_NUMBER%type;
  lv_PicPrefix   ACS_PICTURE.PIC_PICTURE%type;
  lv_PicNumber   ACS_PICTURE.PIC_PICTURE%type;
  lv_PicSuffix   ACS_PICTURE.PIC_PICTURE%type;
  ln_FreeNumber  ACJ_FREE_NUMBER.FNU_NUMBER%type;
  ln_FreeMgt     ACJ_NUMBER_METHOD.DNM_FREE_MANAGEMENT%type;
begin
  begin
    -- Recherche numéroteur pour SEPA
    select NUM.ACJ_NUMBER_METHOD_ID
         , NUM.C_NUMBER_TYPE
         , NUM.DNM_PREFIX
         , NUM.DNM_SUFFIX
         , NUM.DNM_INCREMENT
         , NUM.DNM_FREE_MANAGEMENT
         , PPI.PIC_PICTURE
         , NPI.PIC_PICTURE
         , SPI.PIC_PICTURE
      into ln_MethodId
         , lv_NumberType
         , lv_PREFIX
         , lv_SUFFIX
         , ln_Increment
         , ln_FreeMgt
         , lv_PicPrefix
         , lv_PicNumber
         , lv_PicSuffix
      from ACS_PICTURE PPI
         , ACS_PICTURE NPI
         , ACS_PICTURE SPI
         , ACJ_NUMBER_METHOD NUM
     where NUM.DNM_SEPA = 1
       and NUM.ACS_PIC_PREFIX_ID = PPI.ACS_PICTURE_ID(+)
       and NUM.ACS_PIC_NUMBER_ID = NPI.ACS_PICTURE_ID
       and NUM.ACS_PIC_SUFFIX_ID = SPI.ACS_PICTURE_ID(+);
  exception
    when no_data_found then
      raise_application_error(-20000, 'No SEPA numbering founded');
  end;


  iov_Number  := null;

  if ln_MethodId is not null then
    -- Récupération du dernier numéro
    begin
      select NAP_LAST_NUMBER
      into ln_LastNumber
      from ACJ_LAST_NUMBER
      where ACJ_NUMBER_METHOD_ID = ln_MethodId;
    exception
      when no_data_found then
        ln_LastNumber  := 0;
        insert into ACJ_LAST_NUMBER
                      (ACJ_LAST_NUMBER_ID
                     , ACJ_NUMBER_METHOD_ID
                     , ACS_FINANCIAL_YEAR_ID
                     , NAP_LAST_NUMBER
                        )
               values (INIT_ID_SEQ.nextval
                     , ln_MethodId
                     , null
                     , ln_LastNumber
                      );
    end;
    --Calcul du numéro selon les paramètres
    iov_Number  := ACT_FUNCTIONS.DocNumber(null
                              , ln_LastNumber
                              , lv_NumberType
                              , lv_Prefix
                              , lv_Suffix
                              , ln_Increment
                              , ln_FreeMgt
                              , ln_FreeNumber
                              , lv_PicPrefix
                              , lv_PicNumber
                              , lv_PicSuffix
                               );

      if iov_Number is not null then
        -- Mise à jour dernier numéro utilisé
        update ACJ_LAST_NUMBER
        set NAP_LAST_NUMBER = ln_LastNumber + ln_Increment
        where ACJ_NUMBER_METHOD_ID = ln_MethodId;
      end if;
  end if;

  commit;
end SepaNumbering;

END ACT_LIB_PAYMENT_ISO;
