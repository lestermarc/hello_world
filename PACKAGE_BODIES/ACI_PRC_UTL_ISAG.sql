--------------------------------------------------------
--  DDL for Package Body ACI_PRC_UTL_ISAG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_PRC_UTL_ISAG" 
/**
 * Package utilitaire pour intégration de documents ISE dans ProConcept ERP.
 *
 * @version 1.0
 * @date 09/2011
 * @author pyvoirol
 * @author spfister
 *
 * Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
 */
AS

  gcd_MIN_DATE CONSTANT DATE := to_date('01.01.1900','dd.mm.yyyy');
  gcd_MAX_DATE CONSTANT DATE := to_date('31.12.2099','dd.mm.yyyy');

--
-- Internal methods
--

function p_ExtractEcsBsp(
  iv_ebp_account IN pac_ebpp_reference.ebp_account%TYPE)
  return VARCHAR2
is
begin
  return
    case Substr(iv_ebp_account, 1, 4)
      when '4101' then '01' -- Paynet
      when '4110' then '00' -- YellowBill
    end;
end;

procedure p_FindLinkedEbppReference(
  in_ebpp_reference_id IN pac_ebpp_reference.pac_ebpp_reference_id%TYPE,
  otpl_ebpp_reference OUT pac_ebpp_reference%ROWTYPE)
is
  ld_today DATE := Trunc(Sysdate);
begin
  select EBP.*
  into otpl_ebpp_reference
  from PAC_EBPP_REFERENCE EBP
  where EBP.PAC_EBPP_REFERENCE_ID = in_ebpp_reference_id and
    EBP.C_EBP_INTEGRATION_MODE in ('01','03') and
    EBP.C_EBPP_STATUS = '1' and
    ld_today between Trunc(Nvl(ebp.ebp_valid_from, gcd_MIN_DATE)) and
                     Trunc(Nvl(ebp.ebp_valid_to, gcd_MAX_DATE));

  otpl_ebpp_reference.c_ebpp_bsp := p_ExtractEcsBsp(otpl_ebpp_reference.ebp_account);

  exception
    when NO_DATA_FOUND or TOO_MANY_ROWS then
      otpl_ebpp_reference := null;
end;


--
-- Public methods
--

function CountActiveEbppReferences(
  in_custom_partner_id IN pac_custom_partner.pac_custom_partner_id%TYPE,
  iv_ebp_external_reference IN pac_ebpp_reference.ebp_external_reference%TYPE,
  iv_count_mode IN VARCHAR2)
  return INTEGER
is
  ln_result INTEGER := 0;
  ld_today DATE := Trunc(Sysdate);
begin
  if (iv_count_mode = 'ALL') then
    select Count(*)
    into ln_result
    from PAC_EBPP_REFERENCE EBP
    where EBP.PAC_CUSTOM_PARTNER_ID = in_custom_partner_id and
      EBP.C_EBP_INTEGRATION_MODE in ('01','03') and
      EBP.C_EBPP_STATUS = '1' and
      ld_today between Trunc(Nvl(EBP.EBP_VALID_FROM, gcd_MIN_DATE)) and
                             Trunc(Nvl(EBP.EBP_VALID_TO, gcd_MAX_DATE));
  elsif (iv_count_mode = 'EXACT') then
    select Count(*)
    into ln_result
    from PAC_EBPP_REFERENCE EBP
    where EBP.PAC_CUSTOM_PARTNER_ID = in_custom_partner_id and
      EBP.C_EBP_INTEGRATION_MODE in ('01','03') and
      EBP.C_EBPP_STATUS = '1' and
      EBP.EBP_EXTERNAL_REFERENCE = iv_ebp_external_reference and
      ld_today between Trunc(Nvl(EBP.EBP_VALID_FROM, gcd_MIN_DATE)) and
                       Trunc(Nvl(EBP.EBP_VALID_TO, gcd_MAX_DATE));
  end if;

  return ln_result;
end;

procedure GenerateComEBanking(
  in_act_document_id IN act_document.act_document_id%TYPE,
  in_aci_document_id IN aci_document.aci_document_id%TYPE,
  in_exchange_system_id IN pcs.pc_exchange_system.pc_exchange_system_id%TYPE,
  in_ebpp_reference_id IN pac_ebpp_reference.pac_ebpp_reference_id%TYPE,
  iv_callerCtx IN VARCHAR2,
  ion_ebanking_id IN OUT com_ebanking.com_ebanking_id%TYPE)
is
begin
  if (iv_callerCtx = 'ISAG') then
    -- appelé depuis le processus aci_isag.aci_ebpp
    insert into COM_EBANKING
               (COM_EBANKING_ID
              , ACT_DOCUMENT_ID
              , ACI_DOCUMENT_ID
              , PAC_EBPP_REFERENCE_ID
              , PC_EXCHANGE_SYSTEM_ID
              , C_ECS_SENDING_MODE
              , C_ECS_VALIDATION
              , C_CEB_EBANKING_STATUS
              , C_CEB_DOCUMENT_ORIGIN
              , C_ECS_ROLE
              , CEB_TRANSACTION_ID
              , A_DATECRE
              , A_IDCRE)
       values (init_id_seq.nextval
             , in_act_document_id
             , in_aci_document_id
             , in_ebpp_reference_id
             , in_exchange_system_id
             , '00' -- C_ECS_SENDING_MODE
             , '02' -- C_ECS_VALIDATION
             , '000' -- C_CEB_EBANKING_STATUS
             , '03' -- C_CEB_DOCUMENT_ORIGIN
             , '01' -- C_ECS_ROLE
             , com_lib_ebanking.NextEBankingTransactionId
             , Sysdate
             , pcs.PC_I_LIB_SESSION.GetUserIni)
     returning COM_EBANKING_ID
          into ion_ebanking_id;
  elsif (iv_callerCtx = 'CTRL') then
    -- appelé depuis le processus de contrôle
    update COM_EBANKING
    set PAC_EBPP_REFERENCE_ID = in_ebpp_reference_id,
        PC_EXCHANGE_SYSTEM_ID = in_exchange_system_id
    where COM_EBANKING_ID = ion_ebanking_id;
  end if;
end;

procedure FindEbppReference(
  in_custom_partner_id IN pac_custom_partner.pac_custom_partner_id%TYPE,
  iv_search_method IN VARCHAR2,
  iv_ebp_external_reference IN pac_ebpp_reference.ebp_external_reference%TYPE,
  otpl_ebpp_reference OUT pac_ebpp_reference%ROWTYPE)
is
  ltpl_ebpp_reference pac_ebpp_reference%ROWTYPE;
  ld_today DATE := Trunc(Sysdate);
begin
  if (iv_search_method = '01') then
    -- 01 = la référence EBPP de l'abonnement, active et valide
    begin
      select EBP.*
      into ltpl_ebpp_reference
      from PAC_EBPP_REFERENCE EBP
      where EBP.PAC_CUSTOM_PARTNER_ID = in_custom_partner_id and
        EBP.C_EBP_INTEGRATION_MODE in ('01', '03') and
        EBP.C_EBPP_STATUS = '1' and
        EBP.EBP_EXTERNAL_REFERENCE = iv_ebp_external_reference and
        ld_today between Trunc(Nvl(EBP.EBP_VALID_FROM, gcd_MIN_DATE)) and
                         Trunc(Nvl(EBP.EBP_VALID_TO, gcd_MAX_DATE));

      if (ltpl_ebpp_reference.EBP_OWN_REFERENCE = 0) then
        p_FindLinkedEbppReference(
          in_ebpp_reference_id => ltpl_ebpp_reference.PAC_PAC_EBPP_REFERENCE_ID,
          otpl_ebpp_reference => ltpl_ebpp_reference);
        ltpl_ebpp_reference.EBP_OWN_REFERENCE := 0;
      end if;

    exception
      when NO_DATA_FOUND  or TOO_MANY_ROWS then
        ltpl_ebpp_reference := null;
    end;
  elsif (iv_search_method = '02') then
    -- 02 = la référence par défaut sans abonnement, active et valide
    begin
      select EBP.*
      into ltpl_ebpp_reference
      from PAC_EBPP_REFERENCE EBP
      where EBP.PAC_CUSTOM_PARTNER_ID = in_custom_partner_id and
        EBP.C_EBP_INTEGRATION_MODE in ('01', '03') and
        EBP.EBP_EXTERNAL_REFERENCE is null and
        EBP.C_EBPP_STATUS = '1' and
        EBP.EBP_DEFAULT = 1 and
        ld_today between Trunc(Nvl(EBP.EBP_VALID_FROM, gcd_MIN_DATE)) and
                         Trunc(Nvl(EBP.EBP_VALID_TO, gcd_MAX_DATE));

      if (ltpl_ebpp_reference.EBP_OWN_REFERENCE = 0) then
        p_FindLinkedEbppReference(
          in_ebpp_reference_id => ltpl_ebpp_reference.PAC_PAC_EBPP_REFERENCE_ID,
          otpl_ebpp_reference => ltpl_ebpp_reference);
        ltpl_ebpp_reference.EBP_OWN_REFERENCE := 0;
      end if;

      exception
        when NO_DATA_FOUND or TOO_MANY_ROWS then
          ltpl_ebpp_reference := null;
    end;
  elsif (iv_search_method = '03') then
    -- 03 = une référence sans abonnement, active et valide
    for tpl_searchMethod03 in (
      select V.*
      from (
        select EBP.*
        from PAC_EBPP_REFERENCE EBP
        where EBP.PAC_CUSTOM_PARTNER_ID = in_custom_partner_id and
          EBP.C_EBP_INTEGRATION_MODE in ('01','03') and
          EBP.C_EBPP_STATUS = '1' and
          EBP.EBP_EXTERNAL_REFERENCE is null and
          ld_today between Trunc(Nvl(EBP.EBP_VALID_FROM, gcd_MIN_DATE)) and
                           Trunc(Nvl(EBP.EBP_VALID_TO, gcd_MAX_DATE))
        order by EBP.EBP_ACCOUNT
        ) V
      where rownum = 1
    ) loop
      if (tpl_searchMethod03.EBP_OWN_REFERENCE = 0) then
        p_FindLinkedEbppReference(
          in_ebpp_reference_id => tpl_searchMethod03.PAC_PAC_EBPP_REFERENCE_ID,
          otpl_ebpp_reference => ltpl_ebpp_reference);
        ltpl_ebpp_reference.EBP_OWN_REFERENCE := 0;
      else
        ltpl_ebpp_reference := tpl_searchMethod03;
      end if;
    end loop;
  end if;

  ltpl_ebpp_reference.c_ebpp_bsp := p_ExtractEcsBsp(ltpl_ebpp_reference.ebp_account);
  otpl_ebpp_reference := ltpl_ebpp_reference;
end;


function FindDefaultExchSys(
  iv_ecs_bsp IN pcs.pc_exchange_system.c_ecs_bsp%TYPE)
  return pcs.pc_exchange_system.pc_exchange_system_id%TYPE
is
  ln_result pcs.pc_exchange_system.pc_exchange_system_id%TYPE default null;
begin
  for tpl_exchangeSystem in (
    select V.*
    from (
      select ECS.PC_EXCHANGE_SYSTEM_ID
      from PCS.PC_EXCHANGE_SYSTEM ECS
      where ECS.C_ECS_BSP = iv_ecs_bsp and
        ECS.C_ECS_STATUS = '01' and
        ECS.C_ECS_ROLE = '01' and
        ECS.PC_COMP_ID = pcs.PC_I_LIB_SESSION.getCompanyId
      order by ECS.ECS_DEFAULT desc, ECS.ECS_KEY asc
      ) V
    where rownum = 1
  ) loop
    ln_result := tpl_exchangeSystem.pc_exchange_system_id;
  end loop;

  return ln_result;
end;

procedure ValidateExchSys(
  in_ebpp_reference_id IN pac_ebpp_reference.pac_ebpp_reference_id%TYPE,
  in_exchange_system_id IN pcs.pc_exchange_system.pc_exchange_system_id%TYPE,
  iv_ecs_bsp IN pcs.pc_exchange_system.c_ecs_bsp%TYPE,
  in_act_document_id IN act_document.act_document_id%TYPE,
  in_aci_document_id IN aci_document.aci_document_id%TYPE,
  iv_callerCtx IN VARCHAR2)
is
  ln_ebanking_id com_ebanking.com_ebanking_id%TYPE;
  ln_exchange_system_id pcs.pc_exchange_system.pc_exchange_system_id%TYPE;
begin
  if (in_exchange_system_id is not null) then
    aci_prc_utl_isag.GenerateComEBanking(in_act_document_id, in_aci_document_id, in_exchange_system_id, in_ebpp_reference_id, iv_callerCtx, ln_ebanking_id);
    if (com_lib_ebanking.IsExchangeSystemActive(in_exchange_system_id)) then
      com_prc_ebanking_det.InsertEBPPDetail(ln_ebanking_id, '000', null, null, null, true);
    else
      com_prc_ebanking_det.InsertEBPPDetail(ln_ebanking_id, '000', '301', null, null, true);
    end if;
  else
    ln_exchange_system_id := aci_prc_utl_isag.FindDefaultExchSys(iv_ecs_bsp);
    if (ln_exchange_system_id is not null) then
      aci_prc_utl_isag.GenerateComEBanking(in_act_document_id, in_aci_document_id, ln_exchange_system_id, in_ebpp_reference_id, iv_callerCtx, ln_ebanking_id);
      com_prc_ebanking_det.InsertEBPPDetail(ln_ebanking_id, '000', null, null, null, true);
    else
      aci_prc_utl_isag.GenerateComEBanking(in_act_document_id, in_aci_document_id, null, in_ebpp_reference_id, iv_callerCtx, ln_ebanking_id);
      if (iv_ecs_bsp = '00') then
        com_prc_ebanking_det.InsertEBPPDetail(ln_ebanking_id, '000', '302', null, null, true);
      else
        com_prc_ebanking_det.InsertEBPPDetail(ln_ebanking_id, '000', '303', null, null, true);
      end if;
    end if;
  end if;
end;

function ListEbppReferences(
  in_custom_partner_id IN pac_custom_partner.pac_custom_partner_id%TYPE,
  iv_ebp_external_reference IN pac_ebpp_reference.ebp_external_reference%TYPE)
  return TT_EBP_PREFERENCE
  PIPELINED
is
  lcur_ebpp_reference pac_ebpp_reference%ROWTYPE;
  lt_ebp_preference T_EBP_PREFERENCE;
begin
  lt_ebp_preference := null;
  lt_ebp_preference.pac_custom_partner_id_1 := in_custom_partner_id;

  -- méthode de recherche : 01
  aci_prc_utl_isag.FindEbppReference(in_custom_partner_id, '01', iv_ebp_external_reference, lcur_ebpp_reference);

  lt_ebp_preference.search_method := '01 = abonnement (référence active et valide)';
  lt_ebp_preference.pac_ebpp_reference_id_2 := lcur_ebpp_reference.PAC_EBPP_REFERENCE_ID;
  lt_ebp_preference.ebp_own_reference_1 := lcur_ebpp_reference.EBP_OWN_REFERENCE;
  lt_ebp_preference.pc_exchange_system_id_2 := lcur_ebpp_reference.PC_EXCHANGE_SYSTEM_ID;
  lt_ebp_preference.c_ecs_bsp_2 := lcur_ebpp_reference.C_EBPP_BSP;

  if (lcur_ebpp_reference.PAC_EBPP_REFERENCE_ID is not null) then
    lt_ebp_preference.pac_custom_partner_id_2 := lcur_ebpp_reference.PAC_CUSTOM_PARTNER_ID;
    lt_ebp_preference.ebp_account_2 := lcur_ebpp_reference.EBP_ACCOUNT;
    PIPE ROW(lt_ebp_preference);
  else
    -- méthode de recherche : 02
    aci_prc_utl_isag.FindEbppReference(in_custom_partner_id, '02', null, lcur_ebpp_reference);

    lt_ebp_preference.search_method := '02 = référence par défaut sans abonnement (active et valide)';
    lt_ebp_preference.pac_ebpp_reference_id_2 := lcur_ebpp_reference.PAC_EBPP_REFERENCE_ID;
    lt_ebp_preference.ebp_own_reference_1 := lcur_ebpp_reference.EBP_OWN_REFERENCE;
    lt_ebp_preference.pc_exchange_system_id_2 := lcur_ebpp_reference.PC_EXCHANGE_SYSTEM_ID;
    lt_ebp_preference.c_ecs_bsp_2 := lcur_ebpp_reference.C_EBPP_BSP;

    if (lcur_ebpp_reference.PAC_EBPP_REFERENCE_ID is not null) then
      lt_ebp_preference.pac_custom_partner_id_2 := lcur_ebpp_reference.PAC_CUSTOM_PARTNER_ID;
      lt_ebp_preference.ebp_account_2 := lcur_ebpp_reference.EBP_ACCOUNT;
      PIPE ROW(lt_ebp_preference);
    else
      -- méthode de recherche : 03
      aci_prc_utl_isag.FindEbppReference(in_custom_partner_id, '03', null, lcur_ebpp_reference);

      lt_ebp_preference.search_method := '03 = une référence sans abonnement (active et valide)';
      lt_ebp_preference.pac_ebpp_reference_id_2 := lcur_ebpp_reference.PAC_EBPP_REFERENCE_ID;
      lt_ebp_preference.ebp_own_reference_1 := lcur_ebpp_reference.EBP_OWN_REFERENCE;
      lt_ebp_preference.pc_exchange_system_id_2 := lcur_ebpp_reference.PC_EXCHANGE_SYSTEM_ID;
      lt_ebp_preference.c_ecs_bsp_2 := lcur_ebpp_reference.C_EBPP_BSP;

      lt_ebp_preference.pac_custom_partner_id_2 := lcur_ebpp_reference.PAC_CUSTOM_PARTNER_ID;
      lt_ebp_preference.ebp_account_2 := lcur_ebpp_reference.EBP_ACCOUNT;

      if (lcur_ebpp_reference.PAC_EBPP_REFERENCE_ID is not null) then
        lt_ebp_preference.pac_custom_partner_id_2 := lcur_ebpp_reference.PAC_CUSTOM_PARTNER_ID;
        lt_ebp_preference.ebp_account_2 := lcur_ebpp_reference.EBP_ACCOUNT;
        PIPE ROW(lt_ebp_preference);
      end if;
    end if;
  end if;

  return;

  exception
    when NO_DATA_NEEDED then
      return;
end;

procedure aci_ebpp_check_reversal(
  in_actDocumentId IN act_document.act_document_id%TYPE,
  in_ConversionId IN aci_conversion.aci_conversion_id%TYPE)
is
begin
  for tpl_det_pmt1 in (
    select DET.ACT_PART_IMPUTATION_ID
          ,DET.ACT_EXPIRY_ID
      from ACT_DET_PAYMENT DET
          ,ACT_DOCUMENT DOC
          ,ACT_EXPIRY EXP
     where DOC.ACT_DOCUMENT_ID = in_actDocumentId
       and DOC.ACT_DOCUMENT_ID = EXP.ACT_DOCUMENT_ID
       and EXP.ACT_EXPIRY_ID = DET.ACT_EXPIRY_ID
  ) loop
    for tpl_det_pmt2 in (
      select DET.ACT_EXPIRY_ID
        from ACT_DET_PAYMENT DET
       where DET.ACT_PART_IMPUTATION_ID = tpl_det_pmt1.ACT_PART_IMPUTATION_ID
         and DET.ACT_EXPIRY_ID != tpl_det_pmt1.ACT_EXPIRY_ID
    ) loop
      for tpl_act_exp in (
        select CEB.C_CEB_EBANKING_STATUS, ACI.ACI_CONVERSION_ID, CEB.ACT_DOCUMENT_ID, CEB.COM_EBANKING_ID
          from ACT_EXPIRY EXP
              ,COM_EBANKING CEB
              ,ACI_DOCUMENT ACI
         where EXP.ACT_EXPIRY_ID = tpl_det_pmt2.ACT_EXPIRY_ID
           and EXP.ACT_DOCUMENT_ID = CEB.ACT_DOCUMENT_ID
           and CEB.ACI_DOCUMENT_ID = ACI.ACI_DOCUMENT_ID
      ) loop
        if (tpl_act_exp.ACI_CONVERSION_ID = in_ConversionId)  then
          -- document original et extourne sont dans le même job, le document e-banking peut être supprimé
          delete com_ebanking ceb
           where ceb.act_document_id = tpl_act_exp.ACT_DOCUMENT_ID;
        elsif tpl_act_exp.C_CEB_EBANKING_STATUS in ('000', '001', '002') then
          -- document original et extourne ne sont pas dans le même job, le statut de l'e-facture est passé à "annulé"
          com_prc_ebanking_det.InsertEBPPDetail(
            in_ebanking_id => tpl_act_exp.COM_EBANKING_ID,
            iv_ebanking_status => '009',
            iv_ebanking_error => '500',
            iv_comment => 'Facture extournée',
            ib_update => TRUE);
        else
          -- document original et extourne ne sont pas dans le même job, le statut n'autorise plus sa suppression ou son annulation
          com_prc_ebanking_det.InsertEBPPDetail(
            in_ebanking_id => tpl_act_exp.COM_EBANKING_ID,
            iv_ebanking_status => tpl_act_exp.C_CEB_EBANKING_STATUS,
            iv_ebanking_error => '501',
            iv_comment => 'Extourne impossible',
            ib_update => FALSE);
        end if;
      end loop tpl_act_exp;
    end loop tpl_det_pmt2;
  end loop tpl_det_pmt1;
end aci_ebpp_check_reversal;

END ACI_PRC_UTL_ISAG;
