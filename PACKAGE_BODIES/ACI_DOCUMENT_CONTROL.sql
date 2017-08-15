--------------------------------------------------------
--  DDL for Package Body ACI_DOCUMENT_CONTROL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_DOCUMENT_CONTROL" 
is
  GrpKey_InternalCheck boolean := true;

  /**
  * fonction AuthorizedClosedPeriod
  * Description
  *   Test si le modèle de document autorise la comptabilisation sur une période
  *     bouclée.
  * @lastUpdate
  * @private
  * @param aACI_DOCUMENT_ID  : id du document interface(ACI_DOCUMENT_ID) à contrôler
  * @result : 1 -> possible, 0 -> interdit
  */
  function AuthorizedClosedPeriod(aACI_DOCUMENT_ID in ACI_DOCUMENT.ACI_DOCUMENT_ID%type)
    return number
  is
    vResult number(1);
  begin
    select nvl(TYP.TYP_CLO_PER_ACC, 0)
      into vResult
      from ACJ_JOB_TYPE TYP
         , ACJ_JOB_TYPE_S_CATALOGUE TYPCAT
         , ACI_DOCUMENT DOC
     where TYP.ACJ_JOB_TYPE_ID = TYPCAT.ACJ_JOB_TYPE_ID
       and TYPCAT.ACJ_JOB_TYPE_S_CATALOGUE_ID = DOC.ACJ_JOB_TYPE_S_CATALOGUE_ID
       and DOC.ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;

    return vResult;
  end AuthorizedClosedPeriod;

  /**
  * procedure DeleteForeCapture
  * Description
  * @lastUpdate
  * @private
  * @param document_id  : id du document interface(ACI_DOCUMENT_ID) à contrôler
  * @param financial_year_id : id de l'exercice comptable du document
  * @param job_type_s_catalogue_id : id de la transaction du modèle
  * @param customer : 1 = client
  */
  procedure DeleteForeCapture(
    document_id             in number
  , financial_year_id       in number
  , job_type_s_catalogue_id in number
  , customer                in number
  )
  is
    catalogue_document_id ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    cat_flow_id           ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    doc_doc_id            DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    act_doc_id            ACT_DOCUMENT.ACT_DOCUMENT_ID%type;
  begin
    select max(DOC_DOCUMENT_ID)
      into doc_doc_id
      from ACI_DOCUMENT
     where ACI_DOCUMENT_ID = document_id;

    -- Recherche du document présaisi et mise à jour des liens
    if doc_doc_id is not null then
      update act_doc_receipt
         set aci_document_id = document_id
           , a_datemod = sysdate
           , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni2
       where doc_document_id = doc_doc_id;
    else
      select max(ACJ_CATALOGUE_DOCUMENT_ID)
        into catalogue_document_id
        from ACJ_JOB_TYPE_S_CATALOGUE
       where ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_catalogue_id;

      select max(ACJ_CATALOGUE_DOCUMENT_ID)
        into cat_flow_id
        from acj_flow
       where ACJ_CAT_DOCUMENT2_ID = catalogue_document_id;

      -- si le flux du catalogue autorise les pré-saisies
      -- recherche du document de présaisie
      if cat_flow_id is not null then
        if customer = 1 then
          -- recherche si il existe un document de présaisie
          select max(act_document.act_document_id)
            into act_doc_id
            from act_document
               , act_part_imputation
               , acj_flow
               , acj_job_type
               , act_job
               , aci_part_imputation
           where act_document.act_document_id = act_part_imputation.act_document_id
             and act_part_imputation.pac_custom_partner_id = aci_part_imputation.pac_custom_partner_id
             and acj_flow.acj_cat_document2_id = catalogue_document_id
             and acj_flow.acj_catalogue_document_id = act_document.acj_catalogue_document_id
             and act_job.act_job_id = act_document.act_job_id
             and acj_job_type.acj_job_type_id = act_job.acj_job_type_id
             and acj_job_type.typ_supplier_permanent = 1
             and nvl(act_part_imputation.par_document, ' ') = nvl(aci_part_imputation.par_document, ' ')
             and act_document.acs_financial_year_id = financial_year_id
             and aci_part_imputation.aci_document_id = document_id;
        else
          -- recherche si il existe un document de présaisie
          select max(act_document.act_document_id)
            into act_doc_id
            from act_document
               , act_part_imputation
               , acj_flow
               , acj_job_type
               , act_job
               , aci_part_imputation
           where act_document.act_document_id = act_part_imputation.act_document_id
             and act_part_imputation.pac_supplier_partner_id = aci_part_imputation.pac_supplier_partner_id
             and acj_flow.acj_cat_document2_id = catalogue_document_id
             and acj_flow.acj_catalogue_document_id = act_document.acj_catalogue_document_id
             and act_job.act_job_id = act_document.act_job_id
             and acj_job_type.acj_job_type_id = act_job.acj_job_type_id
             and acj_job_type.typ_supplier_permanent = 1
             and nvl(act_part_imputation.par_document, ' ') = nvl(aci_part_imputation.par_document, ' ')
             and act_document.acs_financial_year_id = financial_year_id
             and aci_part_imputation.aci_document_id = document_id;
        end if;

        -- si on a un document de pré-saisie
        if act_doc_id is not null then
          -- mise à jour du lien
          update ACT_DOC_RECEIPT
             set ACI_DOCUMENT_ID = document_id
               , a_datemod = sysdate
               , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni2
           where ACT_DOCUMENT_ID = act_doc_id;

          -- si aucun tuple n'a été mis à jour, on crée un lien
          if sql%notfound then
            insert into act_doc_receipt
                        (act_doc_receipt_id
                       , act_document_id
                       , aci_document_id
                       , a_datecre
                       , a_idcre
                        )
                 values (init_id_seq.nextval
                       , act_doc_id
                       , document_id
                       , sysdate
                       , pcs.PC_I_LIB_SESSION.GetUserIni2
                        );
          end if;
        end if;
      end if;
    end if;
  end DeleteForeCapture;

  /**
  * fonction Mgm_Imputation_Control
  * Description
  *    Controle des imputations analytiques
  * @author FP
  * @lastUpdate fp 27.06.2003
  * @private
  * @param document_id  : id du document interface(ACI_DOCUMENT_ID) à contrôler
  * @param financial_year_id : id de l'exercice comptable du document
  * @param fail_reason out : valeur de descode c_fail_reason en cas d'erreur de contrôle
  * @return 1 si control OK sinon à 0
  */
  function Mgm_Imputation_Control(document_id in number, financial_year_id in number, fail_reason in out number)
    return signtype
  is
    cursor mgm_imputation(document_id number)
    is
      select MGM.*
           , (select FIN.ACS_FINANCIAL_ACCOUNT_ID
                from ACI_FINANCIAL_IMPUTATION FIN
               where FIN.ACI_FINANCIAL_IMPUTATION_ID = MGM.ACI_FINANCIAL_IMPUTATION_ID) ACS_FINANCIAL_ACCOUNT_ID
        from ACI_MGM_IMPUTATION MGM
       where MGM.ACI_DOCUMENT_ID = document_id;

    cursor ctrl_solde(document_id number)
    is
      select   ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID
          from ACI_MGM_IMPUTATION
             , ACI_FINANCIAL_IMPUTATION
         where ACI_MGM_IMPUTATION.ACI_DOCUMENT_ID = document_id
           and ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID = ACI_MGM_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID
      group by ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID
        having sum(IMM_AMOUNT_LC_D - IMM_AMOUNT_LC_C) <>
                 avg( (IMF_AMOUNT_LC_D -
                       case
                         when sign(IMF_AMOUNT_LC_D) = 0 then 0
                         else case
                         when TAX_INCLUDED_EXCLUDED = 'E' then TAX_VAT_AMOUNT_LC
                         else 0
                       end
                       end
                      ) -
                     (IMF_AMOUNT_LC_C -
                      case
                        when sign(IMF_AMOUNT_LC_C) = 0 then 0
                        else case
                        when TAX_INCLUDED_EXCLUDED = 'E' then TAX_VAT_AMOUNT_LC
                        else 0
                      end
                      end
                     )
                    )
            or sum(IMM_AMOUNT_FC_D - IMM_AMOUNT_FC_C) <>
                 avg( (IMF_AMOUNT_FC_D -
                       case
                         when sign(IMF_AMOUNT_FC_D) = 0 then 0
                         else case
                         when TAX_INCLUDED_EXCLUDED = 'E' then TAX_VAT_AMOUNT_FC
                         else 0
                       end
                       end
                      ) -
                     (IMF_AMOUNT_FC_C -
                      case
                        when sign(IMF_AMOUNT_FC_C) = 0 then 0
                        else case
                        when TAX_INCLUDED_EXCLUDED = 'E' then TAX_VAT_AMOUNT_FC
                        else 0
                      end
                      end
                     )
                    );

    cursor crFinImpMandatoryMgm(document_id number)
    is
      select B.ACS_CPN_ACCOUNT_ID
           , A.*
        from ACI_FINANCIAL_IMPUTATION A
           , ACS_FINANCIAL_ACCOUNT B
       where A.ACI_DOCUMENT_ID = document_id
         and A.ACS_FINANCIAL_ACCOUNT_ID = B.ACS_FINANCIAL_ACCOUNT_ID
         and b.ACS_CPN_ACCOUNT_ID is not null
         and not exists(select ACI_MGM_IMPUTATION_ID
                          from ACI_MGM_IMPUTATION
                         where ACI_FINANCIAL_IMPUTATION_ID = A.ACI_FINANCIAL_IMPUTATION_ID);

    solde_imput_id          ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    mgm_imputation_tuple    mgm_imputation%rowtype;
    currency_id             ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    cda_account_id          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    cpn_account_id          ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    cpn_id                  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    pf_account_id           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    pj_account_id           ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    period_id               ACS_PERIOD.ACS_PERIOD_ID%type;
    catalogue_document_id   ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    imp_information         ACJ_CATALOGUE_DOCUMENT.CAT_IMP_INFORMATION%type;
    cda_imputation          ACS_CPN_ACCOUNT.C_CDA_IMPUTATION%type;
    pf_imputation           ACS_CPN_ACCOUNT.C_PF_IMPUTATION%type;
    pj_imputation           ACS_CPN_ACCOUNT.C_PJ_IMPUTATION%type;
    qty_unit_id             ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    type_period             ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type;
    goodId                  gco_good.gco_good_id%type;
    recordId                doc_record.doc_record_id%type;
    vC_RCO_STATUS           DOC_RECORD.C_RCO_STATUS%type;
    hrmpersonId             hrm_person.hrm_person_id%type;
    personId                pac_person.pac_person_id%type;
    fixedassetsId           fam_fixed_assets.fam_fixed_assets_id%type;
    cfamtransactiontyp      aci_mgm_imputation.c_fam_transaction_typ%type;
    dicimpfree1id           dic_imp_free1.dic_imp_free1_id%type;
    dicimpfree2id           dic_imp_free2.dic_imp_free2_id%type;
    dicimpfree3id           dic_imp_free3.dic_imp_free3_id%type;
    dicimpfree4id           dic_imp_free4.dic_imp_free4_id%type;
    dicimpfree5id           dic_imp_free5.dic_imp_free5_id%type;
    nb_interaction          integer;
    doc_date                date;
    blocked                 ACS_ACCOUNT.ACC_BLOCKED%type;
    validSince              date;
    validTo                 date;
    exist_fin_imp           number;
    vAuthorizedClosedPeriod number(1);
    state_period            ACS_PERIOD.C_STATE_PERIOD%type;
    state_fin_year          ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;
    info_imp_values         ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    managed_infos           ACT_IMP_MANAGEMENT.InfoImputationRecType;
    managed_imput           ACT_IMP_MANAGEMENT.InfoImputationBaseRecType;
    error_info_imp          number;
    vCAutorizationType      ACS_QTY_S_CPN_ACOUNT.C_AUTHORIZATION_TYPE%type;
    vStopCtrl               boolean;
  begin
    -- ouverture du curseur
    open mgm_imputation(document_id);

    -- positionnement sur le premier enregistrement
    fetch mgm_imputation
     into mgm_imputation_tuple;

    -- mise à 0 du flag d'erreur sur les imputations financières du document à contrôler
    update aci_mgm_imputation
       set IMM_CONTROL_FLAG = 0
     where ACI_DOCUMENT_ID = mgm_imputation_tuple.aci_document_id;

    -- Controle si on peut avoir de l'analytique dans la transaction
    select max(b.acj_catalogue_document_id)
         , max(d.c_type_period)
         , max(d.cat_imp_information)
      into catalogue_document_id
         , type_period
         , imp_information
      from aci_document a
         , acj_job_type_s_catalogue b
         , acj_sub_set_cat c
         , acj_catalogue_document d
     where a.ACJ_JOB_TYPE_S_CATALOGUE_ID = b.ACJ_JOB_TYPE_S_CATALOGUE_ID
       and c.acj_catalogue_document_id = b.acj_catalogue_document_id
       and aci_document_id = document_id
       and d.acj_catalogue_document_id = b.acj_catalogue_document_id
       and c_sub_set = 'CPN';

    -- controle si le catalogue document autorise les imputations analytiques
    if     mgm_imputation%found
       and catalogue_document_id is null then
      fail_reason  := '580';

      close mgm_imputation;

      return 0;
    end if;

    -- Recherche si il existe des écritures financières
    select sign(count(*) )
      into exist_fin_imp
      from ACI_FINANCIAL_IMPUTATION
     where ACI_DOCUMENT_ID = document_id;

    -- recherche de la date du document pour créer une échéance
    select nvl(B.IMF_TRANSACTION_DATE, A.DOC_DOCUMENT_DATE)
      into doc_date
      from ACI_DOCUMENT A
         , ACI_FINANCIAL_IMPUTATION B
     where A.ACI_DOCUMENT_ID = document_id
       and B.ACI_DOCUMENT_ID(+) = A.ACI_DOCUMENT_ID
       and B.IMF_PRIMARY(+) = 1;

    -- tant que l'on a des imputation analytiques
    vStopCtrl  := false;

    while mgm_imputation%found
     and not vStopCtrl loop
      -- contrôle si imp. anal. sans lien avec imp. fin.
      if     exist_fin_imp = 1
         and mgm_imputation_tuple.ACI_FINANCIAL_IMPUTATION_ID is null then
        fail_reason  := '582';
        vStopCtrl    := true;
      end if;

      -- maj de l'id de la monnaie étrangère
      if     not vStopCtrl
         and mgm_imputation_tuple.acs_financial_currency_id is null then
        if mgm_imputation_tuple.currency1 is not null then
          select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
            into currency_id
            from ACS_FINANCIAL_CURRENCY FIN
               , PCS.PC_CURR CUR
           where FIN.PC_CURR_ID = CUR.PC_CURR_ID
             and CUR.CURRENCY = mgm_imputation_tuple.currency1;

          if currency_id is not null then
            update ACI_MGM_IMPUTATION
               set ACS_FINANCIAL_CURRENCY_ID = currency_id
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          else
            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            fail_reason  := '510';
            vStopCtrl    := true;
          end if;
        else   -- force la MB dans la ME
          update ACI_MGM_IMPUTATION
             set ACS_FINANCIAL_CURRENCY_ID = (select ACS_FINANCIAL_CURRENCY_ID
                                                from ACS_FINANCIAL_CURRENCY
                                               where FIN_LOCAL_CURRENCY = 1)
           where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
        end if;
      end if;

      -- maj de l'id de la monnaie de base
      if not vStopCtrl then
        if     mgm_imputation_tuple.currency2 is not null
           and mgm_imputation_tuple.acs_acs_financial_currency_id is null then
          select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
            into currency_id
            from ACS_FINANCIAL_CURRENCY FIN
               , PCS.PC_CURR CUR
           where FIN.PC_CURR_ID = CUR.PC_CURR_ID
             and FIN.FIN_LOCAL_CURRENCY = 1
             and CUR.CURRENCY = mgm_imputation_tuple.currency2;

          if currency_id is not null then
            update ACI_MGM_IMPUTATION
               set ACS_ACS_FINANCIAL_CURRENCY_ID = currency_id
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          else
            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            fail_reason  := '520';
            vStopCtrl    := true;
          end if;
        else   -- contrôle de l'id. S'assurer 1) qu'il est renseigné (nvl)et que 2) c'est bien la MB (FIN_LOCAL_CURRENCY = 1)
          select max(ACS_FINANCIAL_CURRENCY_ID)
            into currency_id
            from ACS_FINANCIAL_CURRENCY
           where ACS_FINANCIAL_CURRENCY_ID = nvl(mgm_imputation_tuple.acs_acs_financial_currency_id, 0)
             and FIN_LOCAL_CURRENCY = 1;

          if currency_id is null then
            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            fail_reason  := '520';
            vStopCtrl    := true;
          end if;
        end if;
      end if;

      -- Contrôle de la saisie des valeurs étrangères. Si MB est la même que ME, les valeurs contenant de la ME ne doivent pas être renseignées
      if     not vStopCtrl
         and mgm_imputation_tuple.acs_acs_financial_currency_id =
                 nvl(mgm_imputation_tuple.acs_financial_currency_id, mgm_imputation_tuple.acs_acs_financial_currency_id)
         and (   nvl(mgm_imputation_tuple.IMM_AMOUNT_FC_D, 0) <> 0
              or nvl(mgm_imputation_tuple.IMM_AMOUNT_FC_C, 0) <> 0
              or nvl(mgm_imputation_tuple.IMM_EXCHANGE_RATE, 0) <> 0
              or nvl(mgm_imputation_tuple.IMM_BASE_PRICE, 0) <> 0
             ) then
        fail_reason  := '518';
        vStopCtrl    := true;
      end if;

      -- maj de l'id du compte CPN (charge par nature)
      if not vStopCtrl then
        cpn_account_id  := null;

        if mgm_imputation_tuple.ACS_CPN_ACCOUNT_ID is null then
          --Recherche ID selon le numéro CPN
          if mgm_imputation_tuple.CPN_NUMBER is not null then
            select max(CPN.ACS_CPN_ACCOUNT_ID)
                 , nvl(max(ACC.ACC_BLOCKED), 0)
                 , nvl(max(ACC.ACC_VALID_SINCE), to_date('01.01.0001', 'DD.MM.YYYY') )
                 , nvl(max(ACC.ACC_VALID_TO), to_date('31.12.2999', 'DD.MM.YYYY') )
              into cpn_account_id
                 , blocked
                 , validSince
                 , validTo
              from ACS_CPN_ACCOUNT CPN
                 , ACS_ACCOUNT ACC
             where ACC.ACS_ACCOUNT_ID = CPN.ACS_CPN_ACCOUNT_ID
               and ACC.ACC_NUMBER = mgm_imputation_tuple.cpn_number;
          elsif mgm_imputation_tuple.ACS_FINANCIAL_ACCOUNT_ID is not null then
            --Recherche CPN selon compte financier
            select max(CPN.ACS_CPN_ACCOUNT_ID)
                 , nvl(max(ACC.ACC_BLOCKED), 0)
                 , nvl(max(ACC.ACC_VALID_SINCE), to_date('01.01.0001', 'DD.MM.YYYY') )
                 , nvl(max(ACC.ACC_VALID_TO), to_date('31.12.2999', 'DD.MM.YYYY') )
              into cpn_account_id
                 , blocked
                 , validSince
                 , validTo
              from ACS_FINANCIAL_ACCOUNT FIN
                 , ACS_CPN_ACCOUNT CPN
                 , ACS_ACCOUNT ACC
             where FIN.ACS_FINANCIAL_ACCOUNT_ID = mgm_imputation_tuple.ACS_FINANCIAL_ACCOUNT_ID
               and FIN.ACS_CPN_ACCOUNT_ID = CPN.ACS_CPN_ACCOUNT_ID
               and CPN.ACS_CPN_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID;
          end if;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if cpn_account_id is not null then
            if     blocked = 0
               and mgm_imputation_tuple.imm_transaction_date between validSince and validTo then
              update ACI_MGM_IMPUTATION
                 set ACS_CPN_ACCOUNT_ID = cpn_account_id
               where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
            else
              fail_reason  := '541';
              vStopCtrl    := true;
            end if;
          else
            fail_reason  := '540';
            vStopCtrl    := true;
          end if;
        else   --mgm_imputation_tuple.ACS_CPN_ACCOUNT_ID existe
          --Contrôle des dates du CPN
          select max(ACS_ACCOUNT_ID)
               , nvl(max(ACC_BLOCKED), 0)
               , nvl(max(ACC_VALID_SINCE), to_date('01.01.0001', 'DD.MM.YYYY') )
               , nvl(max(ACC_VALID_TO), to_date('31.12.2999', 'DD.MM.YYYY') )
            into cpn_account_id
               , blocked
               , validSince
               , validTo
            from ACS_ACCOUNT
           where ACS_ACCOUNT.ACS_ACCOUNT_ID = mgm_imputation_tuple.ACS_CPN_ACCOUNT_ID;

          -- Si le compte est bloqué ou qu'il n'est plus dans les dates de validité
          if    blocked = 1
             or not(mgm_imputation_tuple.imm_transaction_date between validSince and validTo) then
            fail_reason  := '541';
            vStopCtrl    := true;
          end if;
        end if;
      end if;

      -- Controle si le compte financier permet le CPN, si on a une imputation financière liée
      if     not vStopCtrl
         and cpn_account_id is not null
         and mgm_imputation_tuple.aci_financial_imputation_id is not null then
        -- controle si on doit avoir de l'analytique
        select max(acs_cpn_account_id)
          into cpn_id
          from acs_financial_account
         where acs_financial_account_id = mgm_imputation_tuple.acs_financial_account_id;

        -- le compte financier n'autorise pas l'analytique
        if cpn_id is null then
          fail_reason  := '585';
          vStopCtrl    := true;
        end if;
      end if;

      -- maj de l'id du compte CDA (centre d'analyse)
      if     not vStopCtrl
         and mgm_imputation_tuple.CDA_NUMBER is not null
         and mgm_imputation_tuple.ACS_CDA_ACCOUNT_ID is null then
        select max(ACS_CDA_ACCOUNT_ID)
             , nvl(max(ACC_BLOCKED), 0)
             , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
             , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
          into cda_account_id
             , blocked
             , validSince
             , validTo
          from ACS_CDA_ACCOUNT
             , ACS_ACCOUNT
         where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID
           and ACC_NUMBER = mgm_imputation_tuple.cda_number;

        -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
        if cda_account_id is not null then
          if     blocked = 0
             and mgm_imputation_tuple.imm_transaction_date between validSince and validTo then
            update ACI_MGM_IMPUTATION
               set ACS_CDA_ACCOUNT_ID = cda_account_id
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          else
            fail_reason  := '531';
            vStopCtrl    := true;
          end if;
        else
          fail_reason  := '530';
          vStopCtrl    := true;
        end if;
      elsif mgm_imputation_tuple.ACS_CDA_ACCOUNT_ID is not null then
        select max(ACS_ACCOUNT_ID)
             , nvl(max(ACC_BLOCKED), 0)
             , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
             , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
          into cda_account_id
             , blocked
             , validSince
             , validTo
          from ACS_ACCOUNT
         where ACS_ACCOUNT.ACS_ACCOUNT_ID = mgm_imputation_tuple.ACS_CDA_ACCOUNT_ID;

        -- Si le compte est bloqué ou qu'il n'est plus dans les dates de validité
        if    blocked = 1
           or not(mgm_imputation_tuple.imm_transaction_date between validSince and validTo) then
          fail_reason  := '531';
          vStopCtrl    := true;
        end if;
      end if;

      -- maj de l'id du compte PF (porteur de frais)
      if     not vStopCtrl
         and mgm_imputation_tuple.PF_NUMBER is not null
         and mgm_imputation_tuple.ACS_PF_ACCOUNT_ID is null then
        select max(ACS_PF_ACCOUNT_ID)
             , nvl(max(ACC_BLOCKED), 0)
             , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
             , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
          into pf_account_id
             , blocked
             , validSince
             , validTo
          from ACS_PF_ACCOUNT
             , ACS_ACCOUNT
         where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID
           and ACC_NUMBER = mgm_imputation_tuple.pf_number;

        -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
        if pf_account_id is not null then
          if     blocked = 0
             and mgm_imputation_tuple.imm_transaction_date between validSince and validTo then
            update ACI_MGM_IMPUTATION
               set ACS_PF_ACCOUNT_ID = pf_account_id
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          else
            fail_reason  := '551';
            vStopCtrl    := true;
          end if;
        else
          fail_reason  := '550';
          vStopCtrl    := true;
        end if;
      elsif mgm_imputation_tuple.ACS_PF_ACCOUNT_ID is not null then
        select max(ACS_ACCOUNT_ID)
             , nvl(max(ACC_BLOCKED), 0)
             , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
             , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
          into pf_account_id
             , blocked
             , validSince
             , validTo
          from ACS_ACCOUNT
         where ACS_ACCOUNT.ACS_ACCOUNT_ID = mgm_imputation_tuple.ACS_PF_ACCOUNT_ID;

        -- Si le compte est bloqué ou qu'il n'est plus dans les dates de validité
        if    blocked = 1
           or not(mgm_imputation_tuple.imm_transaction_date between validSince and validTo) then
          fail_reason  := '551';
          vStopCtrl    := true;
        end if;
      end if;

      -- maj de l'id du compte PJ (projet)
      if     not vStopCtrl
         and mgm_imputation_tuple.PJ_NUMBER is not null
         and mgm_imputation_tuple.ACS_PJ_ACCOUNT_ID is null then
        select max(ACS_PJ_ACCOUNT_ID)
             , nvl(max(ACC_BLOCKED), 0)
             , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
             , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
          into pj_account_id
             , blocked
             , validSince
             , validTo
          from ACS_PJ_ACCOUNT
             , ACS_ACCOUNT
         where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID
           and ACC_NUMBER = mgm_imputation_tuple.pj_number;

        -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
        if pj_account_id is not null then
          if     blocked = 0
             and mgm_imputation_tuple.imm_transaction_date between validSince and validTo then
            update ACI_MGM_IMPUTATION
               set ACS_PJ_ACCOUNT_ID = pj_account_id
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          else
            fail_reason  := '561';
            vStopCtrl    := true;
          end if;
        else
          fail_reason  := '560';
          vStopCtrl    := true;
        end if;
      elsif mgm_imputation_tuple.ACS_PJ_ACCOUNT_ID is not null then
        select max(ACS_ACCOUNT_ID)
             , nvl(max(ACC_BLOCKED), 0)
             , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
             , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
          into pj_account_id
             , blocked
             , validSince
             , validTo
          from ACS_ACCOUNT
         where ACS_ACCOUNT.ACS_ACCOUNT_ID = mgm_imputation_tuple.ACS_PJ_ACCOUNT_ID;

        -- Si le compte est bloqué ou qu'il n'est plus dans les dates de validité
        if    blocked = 1
           or not(mgm_imputation_tuple.imm_transaction_date between validSince and validTo) then
          fail_reason  := '561';
          vStopCtrl    := true;
        end if;
      end if;

      -- controle si la cohérence de présence des comptes analytiques
      if     not vStopCtrl
         and cpn_account_id is not null then
        select C_CDA_IMPUTATION
             , C_PF_IMPUTATION
             , C_PJ_IMPUTATION
          into cda_imputation
             , pf_imputation
             , pj_imputation
          from ACS_CPN_ACCOUNT
         where ACS_CPN_ACCOUNT_ID = cpn_account_id;

        -- controle la cohérence du compte CDA
        if    (    cda_account_id is null
               and cda_imputation = '1')
           or (    cda_account_id is not null
               and cda_imputation = '3') then
          fail_reason  := '591';
          vStopCtrl    := true;
        end if;

        -- controle la cohérence du compte PF
        if     not vStopCtrl
           and (    (    pf_account_id is null
                     and pf_imputation = '1')
                or (    pf_account_id is not null
                    and pf_imputation = '3') ) then
          fail_reason  := '592';
          vStopCtrl    := true;
        end if;

        -- controle la cohérence du compte PJ
        if     not vStopCtrl
           and (    (    pj_account_id is null
                     and pj_imputation = '1')
                or (    pj_account_id is not null
                    and pj_imputation = '3') ) then
          fail_reason  := '593';
          vStopCtrl    := true;
        end if;

        -- controle l'existance 2ème axe (CDA-PF)
        if     not vStopCtrl
           and (    cda_account_id is null
                and pf_account_id is null) then
          fail_reason  := '594';
          vStopCtrl    := true;
        end if;

      end if;

      -- Controle des interactions
      -- Controle interaction CPN-CDA
      if     not vStopCtrl
         and cda_account_id is not null then
        select count(*)
          into nb_interaction
          from acs_mgm_interaction
         where acs_cpn_account_id = cpn_account_id
           and acs_cda_account_id is not null;

        if nb_interaction > 0 then
          select count(*)
            into nb_interaction
            from acs_mgm_interaction
           where acs_cpn_account_id = cpn_account_id
             and acs_cda_account_id = cda_account_id
             and doc_date between nvl(MGM_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') )
                              and nvl(MGM_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') );

          if nb_interaction = 0 then
            fail_reason  := '597';
            vStopCtrl    := true;
          end if;
        end if;
      end if;

      -- Controle interaction CPN-PF
      if     not vStopCtrl
         and pf_account_id is not null then
        select count(*)
          into nb_interaction
          from acs_mgm_interaction
         where acs_cpn_account_id = cpn_account_id
           and acs_pf_account_id is not null;

        if nb_interaction > 0 then
          select count(*)
            into nb_interaction
            from acs_mgm_interaction
           where acs_cpn_account_id = cpn_account_id
             and acs_pf_account_id = pf_account_id
             and doc_date between nvl(MGM_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') )
                              and nvl(MGM_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') );

          if nb_interaction = 0 then
            fail_reason  := '598';
            vStopCtrl    := true;
          end if;
        end if;
      end if;

      -- Controle interaction CPN-PJ
      if     not vStopCtrl
         and pj_account_id is not null then
        select count(*)
          into nb_interaction
          from acs_mgm_interaction
         where acs_cpn_account_id = cpn_account_id
           and acs_pj_account_id is not null;

        if nb_interaction > 0 then
          select count(*)
            into nb_interaction
            from acs_mgm_interaction
           where acs_cpn_account_id = cpn_account_id
             and acs_pj_account_id = pj_account_id
             and doc_date between nvl(MGM_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') )
                              and nvl(MGM_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') );

          if nb_interaction = 0 then
            fail_reason  := '599';
            vStopCtrl    := true;
          end if;
        end if;
      end if;

      -- Comptabilisation sur période bouclé ?
      vAuthorizedClosedPeriod  := AuthorizedClosedPeriod(document_id);

      -- maj de l'id de la période
      if     not vStopCtrl
         and mgm_imputation_tuple.per_no_period is not null
         and mgm_imputation_tuple.acs_period_id is null then
        select max(ACS_PERIOD_ID)
          into period_id
          from ACS_PERIOD
         where PER_NO_PERIOD = mgm_imputation_tuple.per_no_period
           and ACS_FINANCIAL_YEAR_ID = financial_year_id
           and (    (C_STATE_PERIOD = 'ACT')
                or (    vAuthorizedClosedPeriod = 1
                    and C_STATE_PERIOD = 'CLO') )
           and C_TYPE_PERIOD = type_period;
      elsif     not vStopCtrl
            and mgm_imputation_tuple.imm_transaction_date is not null
            and mgm_imputation_tuple.acs_period_id is null then
        select max(ACS_PERIOD_ID)
          into period_id
          from ACS_PERIOD
         where mgm_imputation_tuple.imm_transaction_date between PER_START_DATE and PER_END_DATE + 0.99999
           and ACS_FINANCIAL_YEAR_ID = financial_year_id
           and (    (C_STATE_PERIOD = 'ACT')
                or (    vAuthorizedClosedPeriod = 1
                    and C_STATE_PERIOD = 'CLO') )
           and C_TYPE_PERIOD = type_period;
      elsif     not vStopCtrl
            and mgm_imputation_tuple.acs_period_id is not null then
        select max(ACS_PERIOD_ID)
          into period_id
          from ACS_PERIOD
         where mgm_imputation_tuple.imm_transaction_date between PER_START_DATE and PER_END_DATE + 0.99999
           and ACS_PERIOD_ID = mgm_imputation_tuple.acs_period_id
           and (    (C_STATE_PERIOD = 'ACT')
                or (    vAuthorizedClosedPeriod = 1
                    and C_STATE_PERIOD = 'CLO') )
           and C_TYPE_PERIOD = type_period;
      else
        period_id  := null;
      end if;

      -- Contrôle si période fait partie de l'exercice du document
      if not vStopCtrl then
        if period_id is not null then
          select max(ACS_PERIOD_ID)
               , max(C_STATE_PERIOD)
            into period_id
               , state_period
            from ACS_PERIOD
           where ACS_FINANCIAL_YEAR_ID = financial_year_id
             and ACS_PERIOD_ID = period_id;

          if period_id is null then
            fail_reason  := '571';
            vStopCtrl    := true;
          elsif state_period = 'CLO' then
            -- Si la période est bouclée, vérifier que l'exercice soit bien actif
            select max(C_STATE_FINANCIAL_YEAR)
              into state_fin_year
              from ACS_FINANCIAL_YEAR
             where ACS_FINANCIAL_YEAR_ID = financial_year_id;

            if state_fin_year != 'ACT' then
              fail_reason  := '572';
              vStopCtrl    := true;
            end if;
          end if;

          if not vStopCtrl then
            update ACI_MGM_IMPUTATION
               set ACS_PERIOD_ID = period_id
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          end if;
        else
          fail_reason  := '570';
          vStopCtrl    := true;
        end if;
      end if;

      -- maj de l'id des unités quantitatives
      if not vStopCtrl then
        if     mgm_imputation_tuple.QTY_NUMBER is not null
           and mgm_imputation_tuple.ACS_QTY_UNIT_ID is null then
          -- Recherche de l'ID selon le numéro
          select max(ACS_QTY_UNIT_ID)
            into qty_unit_id
            from ACS_QTY_UNIT QTY
               , ACS_ACCOUNT ACC
           where QTY.ACS_QTY_UNIT_ID = ACC.ACS_ACCOUNT_ID
             and ACC.ACC_NUMBER = mgm_imputation_tuple.QTY_NUMBER;
        elsif mgm_imputation_tuple.ACS_QTY_UNIT_ID is not null then
          --ID existant
          qty_unit_id  := mgm_imputation_tuple.ACS_QTY_UNIT_ID;
        end if;

        --Contrôle des interactions obligatoires CPN - QTY
        if     not vStopCtrl
           and cpn_account_id is not null then
          select nvl(max(QTC.C_AUTHORIZATION_TYPE), '0')
            into vCAutorizationType
            from ACS_QTY_S_CPN_ACOUNT QTC
           where QTC.ACS_CPN_ACCOUNT_ID = cpn_account_id
             and trunc(mgm_imputation_tuple.imm_transaction_date)
                   between nvl(trunc(QTA_FROM), trunc(mgm_imputation_tuple.imm_transaction_date) )
                       and nvl(trunc(QTA_TO), trunc(mgm_imputation_tuple.imm_transaction_date) )
             and QTC.C_AUTHORIZATION_TYPE = '1';

          if     vCAutorizationType = '1'
             and nvl(qty_unit_id, 0) = 0 then
            fail_reason  := '574';
            vStopCtrl    := true;
          end if;
        end if;

        --Contrôle des interactions CPN - QTY
        if     not vStopCtrl
           and qty_unit_id is not null then
          --Recherche d'une interaction sur un compte CPN et/ou QTY
          select count(1)
            into nb_interaction
            from ACS_QTY_S_CPN_ACOUNT
           where (   ACS_CPN_ACCOUNT_ID = cpn_account_id
                  or ACS_QTY_UNIT_ID = qty_unit_id)
             and trunc(mgm_imputation_tuple.imm_transaction_date)
                   between nvl(trunc(QTA_FROM), trunc(mgm_imputation_tuple.imm_transaction_date) )
                       and nvl(trunc(QTA_TO), trunc(mgm_imputation_tuple.imm_transaction_date) );

          if nb_interaction > 0 then
            --S'il existe des interactions sur le compte CPN OU la quantité, l'interaction CPN-QTY DOIT exister
            select max(ACS_QTY_UNIT_ID)
              into qty_unit_id
              from ACS_QTY_S_CPN_ACOUNT
             where (    ACS_CPN_ACCOUNT_ID = cpn_account_id
                    and ACS_QTY_UNIT_ID = qty_unit_id)
               and trunc(mgm_imputation_tuple.imm_transaction_date)
                     between nvl(trunc(QTA_FROM), trunc(mgm_imputation_tuple.imm_transaction_date) )
                         and nvl(trunc(QTA_TO), trunc(mgm_imputation_tuple.imm_transaction_date) );

            if qty_unit_id is null then
              fail_reason  := '575';
              vStopCtrl    := true;
            end if;
          end if;
        end if;

        if not vStopCtrl then
          --Mise à jour de la table des imputations
          if     qty_unit_id is not null
             and (nvl(mgm_imputation_tuple.ACS_QTY_UNIT_ID, 0) <> qty_unit_id) then
            update ACI_MGM_IMPUTATION
               set ACS_QTY_UNIT_ID = qty_unit_id
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          end if;

          if     qty_unit_id is null
             and (   nvl(mgm_imputation_tuple.IMM_QUANTITY_D, 0) <> 0
                  or nvl(mgm_imputation_tuple.IMM_QUANTITY_C, 0) <> 0) then
            fail_reason  := '575';
            vStopCtrl    := true;
          end if;
        end if;
      end if;

      -- contrôle de la présence des données complémentaires
      if     not vStopCtrl
         and imp_information = 1 then
        if nvl(managed_infos.ACJ_CATALOGUE_DOCUMENT_ID, 0) != catalogue_document_id then
          managed_infos  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
        end if;

        -- Autorisation des info. compl. sur l'écriture primaire ou secondaire
        if mgm_imputation_tuple.imm_primary = 1 then
          managed_imput  := managed_infos.primary;
        else
          managed_imput  := managed_infos.Secondary;
        end if;

        -- maj de l'id du bien
        if     not vStopCtrl
           and mgm_imputation_tuple.goo_major_reference is not null
           and mgm_imputation_tuple.gco_good_id is null
           and managed_imput.GCO_GOOD_ID.managed then
          select max(GCO_GOOD_ID)
            into goodId
            from GCO_GOOD
           where GOO_MAJOR_REFERENCE = mgm_imputation_tuple.goo_major_reference;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if goodId is not null then
            update ACI_MGM_IMPUTATION
               set gco_good_id = goodId
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          else
            fail_reason  := '511';
            vStopCtrl    := true;
          end if;
        end if;

        -- maj de l'id du dossier
        if     not vStopCtrl
           and managed_imput.DOC_RECORD_ID.managed then
          if mgm_imputation_tuple.doc_record_id is not null then
            select nvl(max(C_RCO_STATUS), '1')
              into vC_RCO_STATUS
              from DOC_RECORD
             where DOC_RECORD_ID = mgm_imputation_tuple.doc_record_id;

            if vC_RCO_STATUS <> '0' then
              fail_reason  := '535';
              vStopCtrl    := true;
            end if;
          elsif mgm_imputation_tuple.rco_title is not null then
            select max(DOC_RECORD_ID)
              into recordId
              from DOC_RECORD
             where RCO_TITLE = mgm_imputation_tuple.rco_title;

            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            if recordId is not null then
              select nvl(max(C_RCO_STATUS), '1')
                into vC_RCO_STATUS
                from DOC_RECORD
               where DOC_RECORD_ID = recordId;

              if vC_RCO_STATUS <> '0' then
                fail_reason  := '535';
                vStopCtrl    := true;
              else
                update ACI_MGM_IMPUTATION
                   set DOC_RECORD_ID = recordId
                 where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
              end if;
            else
              fail_reason  := '512';
              vStopCtrl    := true;
            end if;
          end if;
        end if;

        -- maj de l'id de la personne HRM
        if     not vStopCtrl
           and mgm_imputation_tuple.emp_number is not null
           and mgm_imputation_tuple.hrm_person_id is null
           and managed_imput.HRM_PERSON_ID.managed then
          select max(HRM_PERSON_ID)
            into hrmpersonId
            from HRM_PERSON
           where EMP_NUMBER = mgm_imputation_tuple.emp_number;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if hrmpersonId is not null then
            update ACI_MGM_IMPUTATION
               set HRM_PERSON_ID = hrmpersonId
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          else
            fail_reason  := '513';
            vStopCtrl    := true;
          end if;
        end if;

        -- maj de l'id de la personne pac
        if     not vStopCtrl
           and (    (mgm_imputation_tuple.per_key1 is not null)
                or (mgm_imputation_tuple.per_key2 is not null) )
           and mgm_imputation_tuple.pac_person_id is null
           and managed_imput.PAC_PERSON_ID.managed then
          select max(PAC_PERSON_ID)
            into personId
            from PAC_PERSON
           where PER_KEY1 = mgm_imputation_tuple.per_key1
              or PER_KEY2 = mgm_imputation_tuple.per_key2;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if personId is not null then
            update ACI_MGM_IMPUTATION
               set PAC_PERSON_ID = personId
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          else
            fail_reason  := '514';
            vStopCtrl    := true;
          end if;
        end if;

        -- maj de l'id de l'immobilisation
        if     not vStopCtrl
           and mgm_imputation_tuple.fix_number is not null
           and mgm_imputation_tuple.fam_fixed_assets_id is null
           and managed_imput.FAM_FIXED_ASSETS_ID.managed then
          select max(FAM_FIXED_ASSETS_ID)
            into fixedassetsId
            from FAM_FIXED_ASSETS
           where FIX_NUMBER = mgm_imputation_tuple.fix_number;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if fixedassetsId is not null then
            update ACI_MGM_IMPUTATION
               set FAM_FIXED_ASSETS_ID = fixedassetsId
             where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;
          else
            fail_reason  := '515';
            vStopCtrl    := true;
          end if;
        end if;

        -- maj du DCOD de l'immobilisation
        if     not vStopCtrl
           and mgm_imputation_tuple.c_fam_transaction_typ is not null
           and managed_imput.C_FAM_TRANSACTION_TYP.managed then
          select max(COD.GCLCODE)
            into cfamtransactiontyp
            from PCS.PC_GCODES COD
           where COD.GCLCODE = mgm_imputation_tuple.C_FAM_TRANSACTION_TYP
             and COD.GCGNAME = 'C_FAM_TRANSACTION_TYP'
             and rownum = 1;

          if cfamtransactiontyp is null then
            fail_reason  := '526';
            vStopCtrl    := true;
          end if;
        end if;

        -- si une immob est saisie, le dcod doit l'être également et vice-versa
        if     not vStopCtrl
           and mgm_imputation_tuple.fam_fixed_assets_id is null
           and mgm_imputation_tuple.fix_number is null
           and mgm_imputation_tuple.c_fam_transaction_typ is not null
           and managed_imput.FAM_FIXED_ASSETS_ID.managed then
          fail_reason  := '507';
          vStopCtrl    := true;
        end if;

        if     not vStopCtrl
           and mgm_imputation_tuple.C_FAM_TRANSACTION_TYP is null
           and (   mgm_imputation_tuple.fix_number is not null   --FAM_FIXED_ASSETS_ID a déjà été trouvé => FIX_NUMBER est valide
                or mgm_imputation_tuple.fam_fixed_assets_id is not null
               )
           and managed_imput.FAM_FIXED_ASSETS_ID.managed then
          fail_reason  := '508';
          vStopCtrl    := true;
        end if;

        --Contrôle des DICOs
        if     not vStopCtrl
           and mgm_imputation_tuple.dic_imp_free1_id is not null
           and managed_imput.DICO1.managed then
          select max(DIC_IMP_FREE1_ID)
            into dicimpfree1id
            from DIC_IMP_FREE1
           where DIC_IMP_FREE1_ID = mgm_imputation_tuple.dic_imp_free1_id;

          if dicimpfree1id is null then
            fail_reason  := '521';
            vStopCtrl    := true;
          end if;
        end if;

        if     not vStopCtrl
           and mgm_imputation_tuple.dic_imp_free2_id is not null
           and managed_imput.DICO2.managed then
          select max(DIC_IMP_FREE2_ID)
            into dicimpfree2id
            from DIC_IMP_FREE2
           where DIC_IMP_FREE2_ID = mgm_imputation_tuple.dic_imp_free2_id;

          if dicimpfree2id is null then
            fail_reason  := '522';
            vStopCtrl    := true;
          end if;
        end if;

        if     not vStopCtrl
           and mgm_imputation_tuple.dic_imp_free3_id is not null
           and managed_imput.DICO3.managed then
          select max(DIC_IMP_FREE3_ID)
            into dicimpfree3id
            from DIC_IMP_FREE3
           where DIC_IMP_FREE3_ID = mgm_imputation_tuple.dic_imp_free3_id;

          if dicimpfree3id is null then
            fail_reason  := '523';
            vStopCtrl    := true;
          end if;
        end if;

        if     not vStopCtrl
           and mgm_imputation_tuple.dic_imp_free4_id is not null
           and managed_imput.DICO4.managed then
          select max(DIC_IMP_FREE4_ID)
            into dicimpfree4id
            from DIC_IMP_FREE4
           where DIC_IMP_FREE4_ID = mgm_imputation_tuple.dic_imp_free4_id;

          if dicimpfree4id is null then
            fail_reason  := '524';
            vStopCtrl    := true;
          end if;
        end if;

        if     not vStopCtrl
           and mgm_imputation_tuple.dic_imp_free5_id is not null
           and managed_imput.DICO5.managed then
          select max(DIC_IMP_FREE5_ID)
            into dicimpfree5id
            from DIC_IMP_FREE5
           where DIC_IMP_FREE5_ID = mgm_imputation_tuple.dic_imp_free5_id;

          if dicimpfree5id is null then
            fail_reason  := '525';
            vStopCtrl    := true;
          end if;
        end if;

        ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMM_ACI(mgm_imputation_tuple.aci_mgm_imputation_id, info_imp_values);
        error_info_imp  := ACT_IMP_MANAGEMENT.CheckManagedValues(info_imp_values, managed_imput);

        -- IMM_NUMBER - IMM_NUMBER1
        if     not vStopCtrl
           and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GroupNUMBER) != 0 then
          fail_reason  := '501';
          vStopCtrl    := true;
        end if;

        -- IMM_TEXT1 - IMM_TEXT5
        if     not vStopCtrl
           and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GroupTEXT) != 0 then
          fail_reason  := '502';
          vStopCtrl    := true;
        end if;

        -- DIC_IMP_FREE1_ID - DIC_IMP_FREE5_ID
        if     not vStopCtrl
           and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GroupDICO) != 0 then
          fail_reason  := '503';
          vStopCtrl    := true;
        end if;

        -- GCO_GOOD_ID
        if     not vStopCtrl
           and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GCO_GOOD_ID) != 0 then
          fail_reason  := '504';
          vStopCtrl    := true;
        end if;

        -- DOC_RECORD_ID
        if     not vStopCtrl
           and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().DOC_RECORD_ID) != 0 then
          fail_reason  := '505';
          vStopCtrl    := true;
        end if;

        -- HRM_PERSON_ID
        if     not vStopCtrl
           and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().HRM_PERSON_ID) != 0 then
          fail_reason  := '506';
          vStopCtrl    := true;
        end if;

        -- FAM_FIXED_ASSETS_ID
        if     not vStopCtrl
           and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().FAM_FIXED_ASSETS_ID) != 0 then
          fail_reason  := '507';
          vStopCtrl    := true;
        end if;

        -- C_FAM_TRANSACTION_TYP
        if     not vStopCtrl
           and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().C_FAM_TRANSACTION_TYP) != 0 then
          fail_reason  := '508';
          vStopCtrl    := true;
        end if;

        -- PAC_PERSON_ID
        if     not vStopCtrl
           and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().PAC_PERSON_ID) != 0 then
          fail_reason  := '509';
          vStopCtrl    := true;
        end if;
      end if;

      if not vStopCtrl then
        if nvl(length(mgm_imputation_tuple.IMM_DESCRIPTION), 0) = 0 then
          fail_reason  := '589';
          vStopCtrl    := true;
        end if;
      end if;

      -- Maj de la colonne indiquant l'erreur sur l'imputation concernée
      if vStopCtrl then
        update aci_mgm_imputation
           set IMM_CONTROL_FLAG = 1
         where ACI_MGM_IMPUTATION_ID = mgm_imputation_tuple.aci_mgm_imputation_id;

        close mgm_imputation;

        return 0;
      end if;

      -- imputation suivante
      fetch mgm_imputation
       into mgm_imputation_tuple;

      cda_account_id           := null;
      cpn_account_id           := null;
      pf_account_id            := null;
      pj_account_id            := null;
      qty_unit_id              := null;
    end loop;

    close mgm_imputation;

    -- contrôle de correspondance des solde entre les imputations analytiques et financière
    open ctrl_solde(document_id);

    fetch ctrl_solde
     into solde_imput_id;

    if ctrl_solde%found then
      fail_reason  := '576';

      close ctrl_solde;

      return 0;
    end if;

    close ctrl_solde;

    -- contrôle qu'il existe des imputations Analytique pour les imputations liès à un compte financier ayant un CPN
    if catalogue_document_id is not null then
      for tplFinImpMandatoryMgm in crFinImpMandatoryMgm(document_id) loop
        insert into ACI_MGM_IMPUTATION
                    (ACI_MGM_IMPUTATION_ID
                   , ACI_DOCUMENT_ID
                   , ACI_FINANCIAL_IMPUTATION_ID
                   , IMM_TYPE
                   , IMM_GENRE
                   , IMM_PRIMARY
                   , ACS_CPN_ACCOUNT_ID
                   , IMM_DESCRIPTION
                   , IMM_VALUE_DATE
                   , IMM_TRANSACTION_DATE
                   , ACS_FINANCIAL_CURRENCY_ID
                   , CURRENCY1
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , CURRENCY2
                   , IMM_EXCHANGE_RATE
                   , IMM_BASE_PRICE
                   , IMM_AMOUNT_LC_D
                   , IMM_AMOUNT_LC_C
                   , IMM_AMOUNT_FC_D
                   , IMM_AMOUNT_FC_C
                   , IMM_AMOUNT_EUR_D
                   , IMM_AMOUNT_EUR_C
                   , ACS_PERIOD_ID
                   , PER_NO_PERIOD
                   , DOC_RECORD_ID
                   , RCO_NUMBER
                   , RCO_TITLE
                   , GCO_GOOD_ID
                   , GOO_MAJOR_REFERENCE
                   , PAC_PERSON_ID
                   , PER_KEY1
                   , PER_KEY2
                   , HRM_PERSON_ID
                   , FAM_FIXED_ASSETS_ID
                   , FIX_NUMBER
                   , C_FAM_TRANSACTION_TYP
                   , IMM_NUMBER
                   , IMM_NUMBER2
                   , IMM_NUMBER3
                   , IMM_NUMBER4
                   , IMM_NUMBER5
                   , IMM_TEXT1
                   , IMM_TEXT2
                   , IMM_TEXT3
                   , IMM_TEXT4
                   , IMM_TEXT5
                   , IMM_DATE1
                   , IMM_DATE2
                   , IMM_DATE3
                   , IMM_DATE4
                   , IMM_DATE5
                   , DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID
                   , IMM_CONTROL_FLAG
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (ACI_ID_SEQ.nextval
                   , document_id
                   , tplFinImpMandatoryMgm.ACI_FINANCIAL_IMPUTATION_ID
                   , 'MAN'
                   , 'STD'
                   , tplFinImpMandatoryMgm.IMF_PRIMARY
                   , tplFinImpMandatoryMgm.ACS_CPN_ACCOUNT_ID
                   , tplFinImpMandatoryMgm.IMF_DESCRIPTION
                   , tplFinImpMandatoryMgm.IMF_VALUE_DATE
                   , tplFinImpMandatoryMgm.IMF_TRANSACTION_DATE
                   , tplFinImpMandatoryMgm.ACS_FINANCIAL_CURRENCY_ID
                   , tplFinImpMandatoryMgm.CURRENCY1
                   , tplFinImpMandatoryMgm.ACS_ACS_FINANCIAL_CURRENCY_ID
                   , tplFinImpMandatoryMgm.CURRENCY2
                   , tplFinImpMandatoryMgm.IMF_EXCHANGE_RATE
                   , tplFinImpMandatoryMgm.IMF_BASE_PRICE
                   , tplFinImpMandatoryMgm.IMF_AMOUNT_LC_D -
                     case
                       when tplFinImpMandatoryMgm.TAX_INCLUDED_EXCLUDED in('S', 'I') then 0
                       else case
                       when tplFinImpMandatoryMgm.IMF_AMOUNT_LC_D = 0 then 0
                       else nvl(tplFinImpMandatoryMgm.TAX_VAT_AMOUNT_LC, 0)
                     end
                     end
                   , tplFinImpMandatoryMgm.IMF_AMOUNT_LC_C -
                     case
                       when tplFinImpMandatoryMgm.TAX_INCLUDED_EXCLUDED in('S', 'I') then 0
                       else case
                       when tplFinImpMandatoryMgm.IMF_AMOUNT_LC_C = 0 then 0
                       else nvl(tplFinImpMandatoryMgm.TAX_VAT_AMOUNT_LC, 0)
                     end
                     end
                   , tplFinImpMandatoryMgm.IMF_AMOUNT_FC_D -
                     case
                       when tplFinImpMandatoryMgm.TAX_INCLUDED_EXCLUDED in('S', 'I') then 0
                       else case
                       when tplFinImpMandatoryMgm.IMF_AMOUNT_FC_D = 0 then 0
                       else nvl(tplFinImpMandatoryMgm.TAX_VAT_AMOUNT_FC, 0)
                     end
                     end
                   , tplFinImpMandatoryMgm.IMF_AMOUNT_FC_C -
                     case
                       when tplFinImpMandatoryMgm.TAX_INCLUDED_EXCLUDED in('S', 'I') then 0
                       else case
                       when tplFinImpMandatoryMgm.IMF_AMOUNT_FC_C = 0 then 0
                       else nvl(tplFinImpMandatoryMgm.TAX_VAT_AMOUNT_FC, 0)
                     end
                     end
                   , tplFinImpMandatoryMgm.IMF_AMOUNT_EUR_D -
                     case
                       when tplFinImpMandatoryMgm.TAX_INCLUDED_EXCLUDED in('S', 'I') then 0
                       else case
                       when tplFinImpMandatoryMgm.IMF_AMOUNT_EUR_D = 0 then 0
                       else nvl(tplFinImpMandatoryMgm.TAX_VAT_AMOUNT_EUR, 0)
                     end
                     end
                   , tplFinImpMandatoryMgm.IMF_AMOUNT_EUR_C -
                     case
                       when tplFinImpMandatoryMgm.TAX_INCLUDED_EXCLUDED in('S', 'I') then 0
                       else case
                       when tplFinImpMandatoryMgm.IMF_AMOUNT_EUR_C = 0 then 0
                       else nvl(tplFinImpMandatoryMgm.TAX_VAT_AMOUNT_EUR, 0)
                     end
                     end
                   , tplFinImpMandatoryMgm.ACS_PERIOD_ID
                   , tplFinImpMandatoryMgm.PER_NO_PERIOD
                   , tplFinImpMandatoryMgm.DOC_RECORD_ID
                   , tplFinImpMandatoryMgm.RCO_NUMBER
                   , tplFinImpMandatoryMgm.RCO_TITLE
                   , tplFinImpMandatoryMgm.GCO_GOOD_ID
                   , tplFinImpMandatoryMgm.GOO_MAJOR_REFERENCE
                   , tplFinImpMandatoryMgm.PAC_PERSON_ID
                   , tplFinImpMandatoryMgm.PER_KEY1
                   , tplFinImpMandatoryMgm.PER_KEY2
                   , tplFinImpMandatoryMgm.HRM_PERSON_ID
                   , tplFinImpMandatoryMgm.FAM_FIXED_ASSETS_ID
                   , tplFinImpMandatoryMgm.FIX_NUMBER
                   , tplFinImpMandatoryMgm.C_FAM_TRANSACTION_TYP
                   , tplFinImpMandatoryMgm.IMF_NUMBER
                   , tplFinImpMandatoryMgm.IMF_NUMBER2
                   , tplFinImpMandatoryMgm.IMF_NUMBER3
                   , tplFinImpMandatoryMgm.IMF_NUMBER4
                   , tplFinImpMandatoryMgm.IMF_NUMBER5
                   , tplFinImpMandatoryMgm.IMF_TEXT1
                   , tplFinImpMandatoryMgm.IMF_TEXT2
                   , tplFinImpMandatoryMgm.IMF_TEXT3
                   , tplFinImpMandatoryMgm.IMF_TEXT4
                   , tplFinImpMandatoryMgm.IMF_TEXT5
                   , tplFinImpMandatoryMgm.IMF_DATE1
                   , tplFinImpMandatoryMgm.IMF_DATE2
                   , tplFinImpMandatoryMgm.IMF_DATE3
                   , tplFinImpMandatoryMgm.IMF_DATE4
                   , tplFinImpMandatoryMgm.IMF_DATE5
                   , tplFinImpMandatoryMgm.DIC_IMP_FREE1_ID
                   , tplFinImpMandatoryMgm.DIC_IMP_FREE2_ID
                   , tplFinImpMandatoryMgm.DIC_IMP_FREE3_ID
                   , tplFinImpMandatoryMgm.DIC_IMP_FREE4_ID
                   , tplFinImpMandatoryMgm.DIC_IMP_FREE5_ID
                   , 1   --IMM_CONTROL_FLAG
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        fail_reason  := '581';
        return 0;
      end loop;
    end if;

    return 1;
  end Mgm_Imputation_Control;

  /**
  * fonction Financial_Imputation_Control
  * Description
  *   Controle des imputations financières
  * @author FP
  * @lastUpdate
  * @private
  * @param document_id  : id du document interface(ACI_DOCUMENT_ID) à contrôler
  * @param financial_year_id : id de l'exercice comptable du document
  * @param customer     : flag   1 : client  0 : fournisseur
  * @param person_id    : id du client-fournisseur
  * @param type_catalogue : type de catalogue document
  * @param fail_reason out : valeur de descode c_fail_reason en cas d'erreur de contrôle
  * @return 1 si control OK sinon à 0
  */
  function Financial_Imputation_Control(
    document_id       in     number
  , financial_year_id in     number
  , customer          in     number
  , person_id         in     number
  , type_catalogue    in     varchar2
  , fail_reason       in out number
  )
    return signtype
  is
    cursor fin_imputation(document_id number)
    is
      select *
        from ACI_FINANCIAL_IMPUTATION
       where ACI_DOCUMENT_ID = document_id;

    fin_imputation_tuple    fin_imputation%rowtype;
    auxiliary_id            acs_account.acs_account_id%type;
    financial_id            acs_account.acs_account_id%type;
    division_id             acs_account.acs_account_id%type;
    tax_code_id             acs_account.acs_account_id%type;
    coll_id                 acs_account.acs_account_id%type;
    sub_set_id              acs_sub_set.acs_sub_set_id%type;
    catalogue_document_id   ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    imp_information         ACJ_CATALOGUE_DOCUMENT.CAT_IMP_INFORMATION%type;
    period_id               acs_period.acs_period_id%type;
    currency_id             ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    type_period             ACJ_CATALOGUE_DOCUMENT.C_TYPE_PERIOD%type;
    goodId                  gco_good.gco_good_id%type;
    recordId                doc_record.doc_record_id%type;
    vC_RCO_STATUS           DOC_RECORD.C_RCO_STATUS%type;
    hrmpersonId             hrm_person.hrm_person_id%type;
    personId                pac_person.pac_person_id%type;
    fixedassetsId           fam_fixed_assets.fam_fixed_assets_id%type;
    cfamtransactiontyp      aci_financial_imputation.c_fam_transaction_typ%type;
    dicimpfree1id           dic_imp_free1.dic_imp_free1_id%type;
    dicimpfree2id           dic_imp_free2.dic_imp_free2_id%type;
    dicimpfree3id           dic_imp_free3.dic_imp_free3_id%type;
    dicimpfree4id           dic_imp_free4.dic_imp_free4_id%type;
    dicimpfree5id           dic_imp_free5.dic_imp_free5_id%type;
    doc_date                date;
    no_fc_currency          number(12);
    is_finImp               number(1);
    vVAT_Possible           integer;
    vAuthorizedClosedPeriod number(1);
    state_period            ACS_PERIOD.C_STATE_PERIOD%type;
    state_fin_year          ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;
    blocked                 ACS_ACCOUNT.ACC_BLOCKED%type;
    validSince              date;
    validTo                 date;
    info_imp_values         ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    managed_infos           ACT_IMP_MANAGEMENT.InfoImputationRecType;
    managed_imput           ACT_IMP_MANAGEMENT.InfoImputationBaseRecType;
    error_info_imp          number;
    vStopCtrl               boolean;
  begin
    -- pas d'imputations dans les lettrages et les paiements
    if (type_catalogue not in('3', '8', '9') ) then
      open fin_imputation(document_id);

      fetch fin_imputation
       into fin_imputation_tuple;

      -- mise à 0 du flag d'erreur sur les imputations financières du document à contrôler
      update aci_financial_imputation
         set IMF_CONTROL_FLAG = 0
       where ACI_DOCUMENT_ID = fin_imputation_tuple.aci_document_id;

      -- Controle si on peut avoir des imputation financières dans la transaction
      select max(b.acj_catalogue_document_id)
           , max(C_TYPE_PERIOD)
           , max(d.cat_imp_information)
        into catalogue_document_id
           , type_period
           , imp_information
        from aci_document a
           , acj_job_type_s_catalogue b
           , acj_sub_set_cat c
           , acj_catalogue_document d
       where a.ACJ_JOB_TYPE_S_CATALOGUE_ID = b.ACJ_JOB_TYPE_S_CATALOGUE_ID
         and c.acj_catalogue_document_id = b.acj_catalogue_document_id
         and a.aci_document_id = document_id
         and d.acj_catalogue_document_id = b.acj_catalogue_document_id
         and c.c_sub_set = 'ACC';

      -- controle si le catalogue document autorise les imputations financières
      if     fin_imputation%found
         and catalogue_document_id is null then
        fail_reason  := '480';

        close fin_imputation;

        return 0;
      end if;

      -- controle que le catalogue document oblige les imputations financières
      if     fin_imputation%notfound
         and catalogue_document_id is not null then
        fail_reason  := '490';

        close fin_imputation;

        return 0;
      end if;

      -- recherche de la date du document pour créer une échéance
      select nvl(B.IMF_TRANSACTION_DATE, A.DOC_DOCUMENT_DATE)
        into doc_date
        from ACI_DOCUMENT A
           , ACI_FINANCIAL_IMPUTATION B
       where A.ACI_DOCUMENT_ID = document_id
         and B.ACI_DOCUMENT_ID(+) = A.ACI_DOCUMENT_ID
         and B.IMF_PRIMARY(+) = 1;

      -- on boucle sur les imputations financières tant que le flag de control est OK
      -- et que l'on a pas encore tout passé en revue
      vStopCtrl  := false;

      while not vStopCtrl
       and fin_imputation%found loop
        financial_id             := fin_imputation_tuple.acs_financial_account_id;

        -- maj de l'id du compte financier
        if     fin_imputation_tuple.acc_number is not null
           and fin_imputation_tuple.acs_financial_account_id is null then
          select max(ACS_FINANCIAL_ACCOUNT_ID)
               , nvl(max(ACC_BLOCKED), 0)
               , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
               , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
            into financial_id
               , blocked
               , validSince
               , validTo
            from ACS_FINANCIAL_ACCOUNT
               , ACS_ACCOUNT
           where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
             and ACC_NUMBER = fin_imputation_tuple.acc_number;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if financial_id is not null then
            if     blocked = 0
               and fin_imputation_tuple.IMF_TRANSACTION_DATE between validSince and validTo then
              update ACI_FINANCIAL_IMPUTATION
                 set ACS_FINANCIAL_ACCOUNT_ID = financial_id
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            else
              fail_reason  := '416';
              vStopCtrl    := true;
            end if;
          else
            fail_reason  := '410';
            vStopCtrl    := true;
          end if;
        elsif fin_imputation_tuple.acs_financial_account_id is not null then
          select max(ACS_ACCOUNT_ID)
               , nvl(max(ACC_BLOCKED), 0)
               , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
               , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
            into financial_id
               , blocked
               , validSince
               , validTo
            from ACS_ACCOUNT
           where ACS_ACCOUNT.ACS_ACCOUNT_ID = fin_imputation_tuple.acs_financial_account_id;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if    blocked = 1
             or not(fin_imputation_tuple.IMF_TRANSACTION_DATE between validSince and validTo) then
            fail_reason  := '416';
            vStopCtrl    := true;
          end if;
        end if;

        -- controle que le compte ne soit pas de type portefeuille
        if not vStopCtrl then
          select min(FIN_PORTFOLIO)
            into blocked
            from ACS_FINANCIAL_ACCOUNT
           where ACS_FINANCIAL_ACCOUNT_ID = financial_id;

          if blocked = 1 then
            fail_reason  := '428';
            vStopCtrl    := true;
          end if;
        end if;

        -- maj de l'id du compte auxiliaire
        if     not vStopCtrl
           and fin_imputation_tuple.aux_number is not null
           and fin_imputation_tuple.acs_auxiliary_account_id is null then

          -- si on a pas de compte auxiliaire, on recherche celui se trouvant au niveau des tiers
          if customer = 1 then
            SELECT max(ACS_AUXILIARY_ACCOUNT_ID)
              into auxiliary_id
              FROM PAC_CUSTOM_PARTNER, ACS_ACCOUNT
             WHERE PAC_CUSTOM_PARTNER.ACS_AUXILIARY_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
               AND ACS_ACCOUNT.ACC_NUMBER = fin_imputation_tuple.aux_number;
          else
            SELECT max(ACS_AUXILIARY_ACCOUNT_ID)
              into auxiliary_id
              FROM PAC_SUPPLIER_PARTNER, ACS_ACCOUNT
             WHERE PAC_SUPPLIER_PARTNER.ACS_AUXILIARY_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
               AND ACS_ACCOUNT.ACC_NUMBER = fin_imputation_tuple.aux_number;
          end if;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if auxiliary_id is not null then
            update ACI_FINANCIAL_IMPUTATION
               set ACS_AUXILIARY_ACCOUNT_ID = auxiliary_id
             where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
          else
            fail_reason  := '420';
            vStopCtrl    := true;
          end if;
        end if;

        -- traitement de l'imputation primaire
        if     not vStopCtrl
           and fin_imputation_tuple.imf_primary = 1
           and type_catalogue in('2', '5', '6') then
          select ACS_AUXILIARY_ACCOUNT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
            into auxiliary_id
               , financial_id
            from ACI_FINANCIAL_IMPUTATION
           where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;

          -- recherche du compte auxiliare du partenaire s'il n'est pas renseigné dans le document
          if auxiliary_id is null then
            -- si on a pas de compte auxiliaire, on prend celui se trouvant au niveau des tiers
            if customer = 1 then
              update ACI_FINANCIAL_IMPUTATION
                 set ACS_AUXILIARY_ACCOUNT_ID = (select max(ACS_AUXILIARY_ACCOUNT_ID)
                                                   from PAC_CUSTOM_PARTNER
                                                  where PAC_CUSTOM_PARTNER_ID = person_id)
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            else
              update ACI_FINANCIAL_IMPUTATION
                 set ACS_AUXILIARY_ACCOUNT_ID = (select max(ACS_AUXILIARY_ACCOUNT_ID)
                                                   from PAC_SUPPLIER_PARTNER
                                                  where PAC_SUPPLIER_PARTNER_ID = person_id)
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            end if;
          end if;

          -- recherche du compte financier du catalogue s'il n'est pas renseigné dans le document
          if financial_id is null then
            select max(c.ACS_FINANCIAL_ACCOUNT_ID)
              into financial_id
              from acj_catalogue_document c
                 , acj_job_type_s_catalogue b
                 , aci_document a
             where a.aci_document_id = document_id
               and a.ACJ_JOB_TYPE_S_CATALOGUE_ID = b.ACJ_JOB_TYPE_S_CATALOGUE_ID
               and c.acj_catalogue_document_id = b.acj_catalogue_document_id;
          end if;

          -- recherche du compte financier du partenaire s'il n'est pas renseigné dans le document ou dans le catalogue
          if financial_id is null then
            -- si on a pas de compte financial, on prend celui se trouvant au niveau des tiers
            if customer = 1 then
              if type_catalogue in('2', '6') then
                select max(ACS_INVOICE_COLL_ID)
                  into financial_id
                  from PAC_CUSTOM_PARTNER
                     , ACS_AUXILIARY_ACCOUNT
                 where ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID = PAC_CUSTOM_PARTNER.ACS_AUXILIARY_ACCOUNT_ID
                   and PAC_CUSTOM_PARTNER_ID = person_id;
              elsif type_catalogue = '5' then
                select max(ACS_PREP_COLL_ID)
                  into financial_id
                  from PAC_CUSTOM_PARTNER
                     , ACS_AUXILIARY_ACCOUNT
                 where ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID = PAC_CUSTOM_PARTNER.ACS_AUXILIARY_ACCOUNT_ID
                   and PAC_CUSTOM_PARTNER_ID = person_id;
              end if;
            else
              if type_catalogue in('2', '6') then
                select max(ACS_INVOICE_COLL_ID)
                  into financial_id
                  from PAC_SUPPLIER_PARTNER
                     , ACS_AUXILIARY_ACCOUNT
                 where ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID = PAC_SUPPLIER_PARTNER.ACS_AUXILIARY_ACCOUNT_ID
                   and PAC_SUPPLIER_PARTNER_ID = person_id;
              elsif type_catalogue = '5' then
                select max(ACS_PREP_COLL_ID)
                  into financial_id
                  from PAC_SUPPLIER_PARTNER
                     , ACS_AUXILIARY_ACCOUNT
                 where ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID = PAC_SUPPLIER_PARTNER.ACS_AUXILIARY_ACCOUNT_ID
                   and PAC_SUPPLIER_PARTNER_ID = person_id;
              end if;
            end if;
          end if;

          -- màj de l'id de l'écriture
          if financial_id is not null then
            update ACI_FINANCIAL_IMPUTATION
               set ACS_FINANCIAL_ACCOUNT_ID = financial_id
             where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
          else
            fail_reason  := '410';
            vStopCtrl    := true;
          end if;
        end if;

        -- Ecriture financière, analytique (type 1) vérifier que le compte financier ne soit pas collectif
        if     not vStopCtrl
           and type_catalogue = '1' then
          begin
            select ACS_FINANCIAL_ACCOUNT_ID
              into financial_id
              from ACS_FINANCIAL_ACCOUNT
             where ACS_FINANCIAL_ACCOUNT_ID = financial_id
               and FIN_COLLECTIVE = 0;
          exception
            when no_data_found then
              fail_reason  := '498';
              vStopCtrl    := true;
          end;
        end if;

        -- Contrôle la présence du compte auxiliaire si le compte financier est collectif
        if not vStopCtrl then
          begin
            select IMP.ACS_AUXILIARY_ACCOUNT_ID
              into auxiliary_id
              from ACS_FINANCIAL_ACCOUNT FIN
                 , ACI_FINANCIAL_IMPUTATION IMP
             where IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and IMP.ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id
               and (    (    IMP.ACS_AUXILIARY_ACCOUNT_ID is null
                         and FIN.FIN_COLLECTIVE = 1)
                    or (    IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
                        and nvl(FIN.FIN_COLLECTIVE, 0) = 0)
                   );

            if auxiliary_id is null then
              -- comte aux. manquant
              fail_reason  := '496';
              vStopCtrl    := true;
            else
              -- compte aux. interdit
              fail_reason  := '497';
              vStopCtrl    := true;
            end if;
          exception
            -- pas de données -> OK, pas d'erreur
            when no_data_found then
              null;
          end;
        end if;

        -- contrôle si compte aux. de l'écriture fin. = compte aux. du partenaire
        if not vStopCtrl then
          select ACS_AUXILIARY_ACCOUNT_ID
            into auxiliary_id
            from ACI_FINANCIAL_IMPUTATION
           where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;

          if auxiliary_id is not null then
            if customer = 1 then
              select max(ACS_AUXILIARY_ACCOUNT_ID)
                into auxiliary_id
                from PAC_CUSTOM_PARTNER
               where PAC_CUSTOM_PARTNER_ID = person_id
                 and ACS_AUXILIARY_ACCOUNT_ID = auxiliary_id;
            else
              select max(ACS_AUXILIARY_ACCOUNT_ID)
                into auxiliary_id
                from PAC_SUPPLIER_PARTNER
               where PAC_SUPPLIER_PARTNER_ID = person_id
                 and ACS_AUXILIARY_ACCOUNT_ID = auxiliary_id;
            end if;

            if auxiliary_id is null then
              fail_reason  := '420';
              vStopCtrl    := true;
            end if;
          end if;
        end if;

        -- maj de l'id du compte taxe
        if     not vStopCtrl
           and fin_imputation_tuple.tax_number is not null
           and fin_imputation_tuple.acs_tax_code_id is null then
          select max(ACS_TAX_CODE_ID)
            into tax_code_id
            from ACS_TAX_CODE
               , ACS_ACCOUNT
           where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_TAX_CODE.ACS_TAX_CODE_ID
             and ACC_NUMBER = fin_imputation_tuple.tax_number;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if tax_code_id is not null then
            update ACI_FINANCIAL_IMPUTATION
               set ACS_TAX_CODE_ID = tax_code_id
             where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
          else
            fail_reason  := '430';
            vStopCtrl    := true;
          end if;
        else
          tax_code_id  := fin_imputation_tuple.acs_tax_code_id;
        end if;

        -- contrôle si compte fin. autorise un compte TVA
        if     not vStopCtrl
           and tax_code_id is not null then
          select nvl(min(FIN_VAT_POSSIBLE), 0)
            into vVAT_Possible
            from ACS_FINANCIAL_ACCOUNT
           where ACS_FINANCIAL_ACCOUNT_ID = financial_id;

          if vVAT_Possible = 0 then
            fail_reason  := '432';
            vStopCtrl    := true;
          end if;
        end if;

        -- màj %-tage déductible
        if not vStopCtrl then
          -- initialisation %-tage déductible à 100%
          if fin_imputation_tuple.tax_deductible_rate is null then
            fin_imputation_tuple.tax_deductible_rate  := 100;
          end if;

          -- initialisation totaux TVA avec les montants TVA
          if fin_imputation_tuple.tax_tot_vat_amount_lc is null then
            fin_imputation_tuple.tax_tot_vat_amount_lc  := fin_imputation_tuple.tax_vat_amount_lc;
            fin_imputation_tuple.tax_tot_vat_amount_fc  := fin_imputation_tuple.tax_vat_amount_fc;
            fin_imputation_tuple.tax_tot_vat_amount_vc  := fin_imputation_tuple.tax_vat_amount_vc;
          end if;

          update ACI_FINANCIAL_IMPUTATION
             set TAX_DEDUCTIBLE_RATE = fin_imputation_tuple.tax_deductible_rate
               , TAX_TOT_VAT_AMOUNT_LC = fin_imputation_tuple.tax_tot_vat_amount_lc
               , TAX_TOT_VAT_AMOUNT_FC = fin_imputation_tuple.tax_tot_vat_amount_fc
               , TAX_TOT_VAT_AMOUNT_VC = fin_imputation_tuple.tax_tot_vat_amount_vc
           where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
        end if;

        -- ctrl parité entre les montants débit+crédit et les montants (soumis+TVA)
        if     not vStopCtrl
           and tax_code_id is not null
           and fin_imputation_tuple.tax_included_excluded = 'E' then
          if (abs(fin_imputation_tuple.IMF_AMOUNT_LC_D) + abs(fin_imputation_tuple.IMF_AMOUNT_LC_C) ) <>
                           (abs(fin_imputation_tuple.TAX_LIABLED_AMOUNT) + abs(fin_imputation_tuple.TAX_VAT_AMOUNT_LC)
                           ) then
            fail_reason  := '431';
            vStopCtrl    := true;
          end if;
        end if;

        -- Comptabilisation sur période bouclé ?
        vAuthorizedClosedPeriod  := AuthorizedClosedPeriod(document_id);

        -- maj de l'id de la période
        if     not vStopCtrl
           and fin_imputation_tuple.per_no_period is not null
           and fin_imputation_tuple.acs_period_id is null then
          select max(ACS_PERIOD_ID)
            into period_id
            from ACS_PERIOD
           where PER_NO_PERIOD = fin_imputation_tuple.per_no_period
             and fin_imputation_tuple.imf_transaction_date between PER_START_DATE and trunc(PER_END_DATE) + 0.99999
             and ACS_FINANCIAL_YEAR_ID = financial_year_id
             and (    (C_STATE_PERIOD = 'ACT')
                  or (    vAuthorizedClosedPeriod = 1
                      and C_STATE_PERIOD = 'CLO') )
             and C_TYPE_PERIOD = type_period;
        elsif     not vStopCtrl
              and fin_imputation_tuple.imf_transaction_date is not null
              and fin_imputation_tuple.acs_period_id is null then
          select max(ACS_PERIOD_ID)
            into period_id
            from ACS_PERIOD
           where fin_imputation_tuple.imf_transaction_date between PER_START_DATE and trunc(PER_END_DATE) + 0.99999
             and ACS_FINANCIAL_YEAR_ID = financial_year_id
             and (    (C_STATE_PERIOD = 'ACT')
                  or (    vAuthorizedClosedPeriod = 1
                      and C_STATE_PERIOD = 'CLO') )
             and C_TYPE_PERIOD = type_period;
        elsif     not vStopCtrl
              and fin_imputation_tuple.acs_period_id is not null then
          select max(ACS_PERIOD_ID)
            into period_id
            from ACS_PERIOD
           where fin_imputation_tuple.imf_transaction_date between PER_START_DATE and trunc(PER_END_DATE) + 0.99999
             and ACS_PERIOD_ID = fin_imputation_tuple.acs_period_id
             and (    (C_STATE_PERIOD = 'ACT')
                  or (    vAuthorizedClosedPeriod = 1
                      and C_STATE_PERIOD = 'CLO') )
             and C_TYPE_PERIOD = type_period;
        else
          period_id  := null;
        end if;

        -- Contrôle si période fait partie de l'exercice du document
        if not vStopCtrl then
          if period_id is not null then
            select max(ACS_PERIOD_ID)
                 , max(C_STATE_PERIOD)
              into period_id
                 , state_period
              from ACS_PERIOD
             where ACS_FINANCIAL_YEAR_ID = financial_year_id
               and ACS_PERIOD_ID = period_id;

            if period_id is null then
              fail_reason  := '441';
              vStopCtrl    := true;
            elsif state_period = 'CLO' then
              -- Si la période est bouclée, vérifier que l'exercice soit bien actif
              select max(C_STATE_FINANCIAL_YEAR)
                into state_fin_year
                from ACS_FINANCIAL_YEAR
               where ACS_FINANCIAL_YEAR_ID = financial_year_id;

              if state_fin_year != 'ACT' then
                fail_reason  := '442';
                vStopCtrl    := true;
              end if;
            end if;

            if not vStopCtrl then
              update ACI_FINANCIAL_IMPUTATION
                 set ACS_PERIOD_ID = period_id
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            end if;
          else
            fail_reason  := '440';
            vStopCtrl    := true;
          end if;
        end if;

        -- maj de l'id de la monnaie de base
        if not vStopCtrl then
          if     fin_imputation_tuple.currency2 is not null
             and fin_imputation_tuple.acs_acs_financial_currency_id is null then
            select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
              into currency_id
              from ACS_FINANCIAL_CURRENCY FIN
                 , PCS.PC_CURR CUR
             where FIN.PC_CURR_ID = CUR.PC_CURR_ID
               and FIN.FIN_LOCAL_CURRENCY = 1
               and CUR.CURRENCY = fin_imputation_tuple.currency2;

            if currency_id is not null then
              update ACI_FINANCIAL_IMPUTATION
                 set ACS_ACS_FINANCIAL_CURRENCY_ID = currency_id
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            else
              -- Monnaie inexistante
              fail_reason  := '450';
              vStopCtrl    := true;
            end if;
          else   -- contrôle de l'id. S'assurer 1) qu'il est renseigné (nvl)et que 2) c'est bien la MB (FIN_LOCAL_CURRENCY = 1)
            select max(ACS_FINANCIAL_CURRENCY_ID)
              into currency_id
              from ACS_FINANCIAL_CURRENCY
             where ACS_FINANCIAL_CURRENCY_ID = nvl(fin_imputation_tuple.acs_acs_financial_currency_id, 0)
               and FIN_LOCAL_CURRENCY = 1;

            if currency_id is null then
              -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
              fail_reason  := '450';
              vStopCtrl    := true;
            end if;
          end if;
        end if;

        -- maj de l'id de la monnaie étrangère
        if     not vStopCtrl
           and fin_imputation_tuple.acs_financial_currency_id is null then
          if fin_imputation_tuple.currency1 is not null then
            select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
              into currency_id
              from ACS_FINANCIAL_CURRENCY FIN
                 , PCS.PC_CURR CUR
             where FIN.PC_CURR_ID = CUR.PC_CURR_ID
               and CUR.CURRENCY = fin_imputation_tuple.currency1;

            if currency_id is not null then
              update ACI_FINANCIAL_IMPUTATION
                 set ACS_FINANCIAL_CURRENCY_ID = currency_id
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            else
              -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
              fail_reason  := '460';
              vStopCtrl    := true;
            end if;
          else   -- force la MB dans la ME
            update ACI_FINANCIAL_IMPUTATION
               set ACS_FINANCIAL_CURRENCY_ID = (select ACS_FINANCIAL_CURRENCY_ID
                                                  from ACS_FINANCIAL_CURRENCY
                                                 where FIN_LOCAL_CURRENCY = 1)
             where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
          end if;
        end if;

        -- Contrôle si écriture avec compte fin. nécessitant une monnaie étrangère
        if not vStopCtrl then
          begin
            select   ACCCUR2.ACS_FINANCIAL_ACCOUNT_ID
                into no_fc_currency
                from ACS_FIN_ACCOUNT_S_FIN_CURR ACCCUR2
                   , (select distinct IMP.ACS_FINANCIAL_ACCOUNT_ID
                                 from ACS_FIN_ACCOUNT_S_FIN_CURR ACCCUR
                                    , ACI_FINANCIAL_IMPUTATION IMP
                                where IMP.ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id
                                  and ACCCUR.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                                  and ACCCUR.ACS_FINANCIAL_CURRENCY_ID != IMP.ACS_FINANCIAL_CURRENCY_ID
                                  and ACCCUR.FSC_DEFAULT = 1
                                  and ACCCUR.ACS_FINANCIAL_CURRENCY_ID != ACS_FUNCTION.GetLocalCurrencyID) ACCDEFFC
               where ACCCUR2.ACS_FINANCIAL_ACCOUNT_ID = ACCDEFFC.ACS_FINANCIAL_ACCOUNT_ID
                 and ACCCUR2.ACS_FINANCIAL_CURRENCY_ID != ACS_FUNCTION.GetLocalCurrencyID
            group by ACCCUR2.ACS_FINANCIAL_ACCOUNT_ID
              having count(*) = 1;
          exception
            when no_data_found then
              no_fc_currency  := null;
          end;

          if no_fc_currency is not null then
            fail_reason  := '417';
            vStopCtrl    := true;
          end if;
        end if;

        -- Contrôle de la saisie des valeurs étrangères. Si MB est la même que ME, les valeurs contenant de la ME ne doivent pas être renseignées
        if     not vStopCtrl
           and fin_imputation_tuple.acs_acs_financial_currency_id =
                 nvl(fin_imputation_tuple.acs_financial_currency_id, fin_imputation_tuple.acs_acs_financial_currency_id)
           and (   nvl(fin_imputation_tuple.IMF_AMOUNT_FC_D, 0) <> 0
                or nvl(fin_imputation_tuple.IMF_AMOUNT_FC_C, 0) <> 0
                or nvl(fin_imputation_tuple.IMF_EXCHANGE_RATE, 0) <> 0
                or nvl(fin_imputation_tuple.IMF_BASE_PRICE, 0) <> 0
                or nvl(fin_imputation_tuple.TAX_VAT_AMOUNT_FC, 0) <> 0
                or nvl(fin_imputation_tuple.TAX_TOT_VAT_AMOUNT_FC, 0) <> 0
               ) then
          fail_reason  := '418';
          vStopCtrl    := true;
        end if;

        -- contrôle de la présence des données complémentaires
        if     not vStopCtrl
           and imp_information = 1 then
          if nvl(managed_infos.ACJ_CATALOGUE_DOCUMENT_ID, 0) != catalogue_document_id then
            managed_infos  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
          end if;

          -- Autorisation des info. compl. sur l'écriture primaire ou secondaire
          if fin_imputation_tuple.imf_primary = 1 then
            managed_imput  := managed_infos.primary;
          else
            managed_imput  := managed_infos.Secondary;
          end if;

          -- maj de l'id du bien
          if     not vStopCtrl
             and fin_imputation_tuple.goo_major_reference is not null
             and fin_imputation_tuple.gco_good_id is null
             and managed_imput.GCO_GOOD_ID.managed then
            select max(GCO_GOOD_ID)
              into goodId
              from GCO_GOOD
             where GOO_MAJOR_REFERENCE = fin_imputation_tuple.goo_major_reference;

            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            if goodId is not null then
              update ACI_FINANCIAL_IMPUTATION
                 set gco_good_id = goodId
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            else
              fail_reason  := '411';
              vStopCtrl    := true;
            end if;
          end if;

          -- maj de l'id du dossier
          if     not vStopCtrl
             and managed_imput.DOC_RECORD_ID.managed then
            if fin_imputation_tuple.doc_record_id is not null then
              select nvl(max(C_RCO_STATUS), '1')
                into vC_RCO_STATUS
                from DOC_RECORD
               where DOC_RECORD_ID = fin_imputation_tuple.doc_record_id;

              if vC_RCO_STATUS <> '0' then
                fail_reason  := '435';
                vStopCtrl    := true;
              end if;
            elsif fin_imputation_tuple.rco_title is not null then
              select max(DOC_RECORD_ID)
                into recordId
                from DOC_RECORD
               where RCO_TITLE = fin_imputation_tuple.rco_title;

              -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
              if recordId is not null then
                select nvl(max(C_RCO_STATUS), '1')
                  into vC_RCO_STATUS
                  from DOC_RECORD
                 where DOC_RECORD_ID = recordId;

                if vC_RCO_STATUS <> '0' then
                  fail_reason  := '435';
                  vStopCtrl    := true;
                else
                  update ACI_FINANCIAL_IMPUTATION
                     set DOC_RECORD_ID = recordId
                   where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
                end if;
              else
                fail_reason  := '412';
                vStopCtrl    := true;
              end if;
            end if;
          end if;

          -- maj de l'id de la personne HRM
          if     not vStopCtrl
             and fin_imputation_tuple.emp_number is not null
             and fin_imputation_tuple.hrm_person_id is null
             and managed_imput.HRM_PERSON_ID.managed then
            select max(HRM_PERSON_ID)
              into hrmpersonId
              from HRM_PERSON
             where EMP_NUMBER = fin_imputation_tuple.emp_number;

            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            if hrmpersonId is not null then
              update ACI_FINANCIAL_IMPUTATION
                 set HRM_PERSON_ID = hrmpersonId
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            else
              fail_reason  := '413';
              vStopCtrl    := true;
            end if;
          end if;

          -- maj de l'id de la personne pac
          if     not vStopCtrl
             and (    (fin_imputation_tuple.per_key1 is not null)
                  or (fin_imputation_tuple.per_key2 is not null) )
             and fin_imputation_tuple.pac_person_id is null
             and managed_imput.PAC_PERSON_ID.managed then
            select max(PAC_PERSON_ID)
              into personId
              from PAC_PERSON
             where PER_KEY1 = fin_imputation_tuple.per_key1
                or PER_KEY2 = fin_imputation_tuple.per_key2;

            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            if personId is not null then
              update ACI_FINANCIAL_IMPUTATION
                 set PAC_PERSON_ID = personId
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            else
              fail_reason  := '414';
              vStopCtrl    := true;
            end if;
          end if;

          -- maj de l'id de l'immobilisation
          if     not vStopCtrl
             and fin_imputation_tuple.fix_number is not null
             and fin_imputation_tuple.fam_fixed_assets_id is null
             and managed_imput.FAM_FIXED_ASSETS_ID.managed then
            select max(FAM_FIXED_ASSETS_ID)
              into fixedassetsId
              from FAM_FIXED_ASSETS
             where FIX_NUMBER = fin_imputation_tuple.fix_number;

            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            if fixedassetsId is not null then
              update ACI_FINANCIAL_IMPUTATION
                 set FAM_FIXED_ASSETS_ID = fixedassetsId
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
            else
              fail_reason  := '415';
              vStopCtrl    := true;
            end if;
          end if;

          -- maj du DCOD de l'immobilisation
          if     not vStopCtrl
             and fin_imputation_tuple.c_fam_transaction_typ is not null
             and managed_imput.C_FAM_TRANSACTION_TYP.managed then
            select max(COD.GCLCODE)
              into cfamtransactiontyp
              from PCS.PC_GCODES COD
             where COD.GCLCODE = fin_imputation_tuple.C_FAM_TRANSACTION_TYP
               and COD.GCGNAME = 'C_FAM_TRANSACTION_TYP'
               and rownum = 1;

            if cfamtransactiontyp is null then
              fail_reason  := '426';
              vStopCtrl    := true;
            end if;
          end if;

          -- si une immob est saisie, le dcod doit l'être également et vice-versa
          if     not vStopCtrl
             and fin_imputation_tuple.fam_fixed_assets_id is null
             and fin_imputation_tuple.fix_number is null
             and fin_imputation_tuple.c_fam_transaction_typ is not null
             and managed_imput.FAM_FIXED_ASSETS_ID.managed then
            fail_reason  := '407';
            vStopCtrl    := true;
          end if;

          if     not vStopCtrl
             and fin_imputation_tuple.C_FAM_TRANSACTION_TYP is null
             and (   fin_imputation_tuple.fix_number is not null   --FAM_FIXED_ASSETS_ID a déjà été trouvé => FIX_NUMBER est valide
                  or fin_imputation_tuple.fam_fixed_assets_id is not null
                 )
             and managed_imput.FAM_FIXED_ASSETS_ID.managed then
            fail_reason  := '408';
            vStopCtrl    := true;
          end if;

          --Contrôle des DICOs
          if     not vStopCtrl
             and fin_imputation_tuple.dic_imp_free1_id is not null
             and managed_imput.DICO1.managed then
            select max(DIC_IMP_FREE1_ID)
              into dicimpfree1id
              from DIC_IMP_FREE1
             where DIC_IMP_FREE1_ID = fin_imputation_tuple.dic_imp_free1_id;

            if dicimpfree1id is null then
              fail_reason  := '421';
              vStopCtrl    := true;
            end if;
          end if;

          if     not vStopCtrl
             and fin_imputation_tuple.dic_imp_free2_id is not null
             and managed_imput.DICO2.managed then
            select max(DIC_IMP_FREE2_ID)
              into dicimpfree2id
              from DIC_IMP_FREE2
             where DIC_IMP_FREE2_ID = fin_imputation_tuple.dic_imp_free2_id;

            if dicimpfree2id is null then
              fail_reason  := '422';
              vStopCtrl    := true;
            end if;
          end if;

          if     not vStopCtrl
             and fin_imputation_tuple.dic_imp_free3_id is not null
             and managed_imput.DICO3.managed then
            select max(DIC_IMP_FREE3_ID)
              into dicimpfree3id
              from DIC_IMP_FREE3
             where DIC_IMP_FREE3_ID = fin_imputation_tuple.dic_imp_free3_id;

            if dicimpfree3id is null then
              fail_reason  := '423';
              vStopCtrl    := true;
            end if;
          end if;

          if     not vStopCtrl
             and fin_imputation_tuple.dic_imp_free4_id is not null
             and managed_imput.DICO4.managed then
            select max(DIC_IMP_FREE4_ID)
              into dicimpfree4id
              from DIC_IMP_FREE4
             where DIC_IMP_FREE4_ID = fin_imputation_tuple.dic_imp_free4_id;

            if dicimpfree4id is null then
              fail_reason  := '424';
              vStopCtrl    := true;
            end if;
          end if;

          if     not vStopCtrl
             and fin_imputation_tuple.dic_imp_free5_id is not null
             and managed_imput.DICO5.managed then
            select max(DIC_IMP_FREE5_ID)
              into dicimpfree5id
              from DIC_IMP_FREE5
             where DIC_IMP_FREE5_ID = fin_imputation_tuple.dic_imp_free5_id;

            if dicimpfree5id is null then
              fail_reason  := '425';
              vStopCtrl    := true;
            end if;
          end if;

          ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMF_ACI(fin_imputation_tuple.aci_financial_imputation_id
                                                          , info_imp_values
                                                           );
          error_info_imp  := ACT_IMP_MANAGEMENT.CheckManagedValues(info_imp_values, managed_imput);

          -- IMF_NUMBER - IMF_NUMBER5
          if     not vStopCtrl
             and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GroupNUMBER) != 0 then
            fail_reason  := '401';
            vStopCtrl    := true;
          end if;

          -- IMF_TEXT1 - IMF_TEXT5
          if     not vStopCtrl
             and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GroupTEXT) != 0 then
            fail_reason  := '402';
            vStopCtrl    := true;
          end if;

          -- DIC_IMP_FREE1_ID - DIC_IMP_FREE5_ID
          if     not vStopCtrl
             and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GroupDICO) != 0 then
            fail_reason  := '403';
            vStopCtrl    := true;
          end if;

          -- GCO_GOOD_ID
          if     not vStopCtrl
             and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GCO_GOOD_ID) != 0 then
            fail_reason  := '404';
            vStopCtrl    := true;
          end if;

          -- DOC_RECORD_ID
          if     not vStopCtrl
             and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().DOC_RECORD_ID) != 0 then
            fail_reason  := '405';
            vStopCtrl    := true;
          end if;

          -- HRM_PERSON_ID
          if     not vStopCtrl
             and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().HRM_PERSON_ID) != 0 then
            fail_reason  := '406';
            vStopCtrl    := true;
          end if;

          -- FAM_FIXED_ASSETS_ID
          if     not vStopCtrl
             and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().FAM_FIXED_ASSETS_ID) != 0 then
            fail_reason  := '407';
            vStopCtrl    := true;
          end if;

          -- C_FAM_TRANSACTION_TYP
          if     not vStopCtrl
             and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().C_FAM_TRANSACTION_TYP) !=
                                                                                                                       0 then
            fail_reason  := '408';
            vStopCtrl    := true;
          end if;

          -- PAC_PERSON_ID
          if     not vStopCtrl
             and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().PAC_PERSON_ID) != 0 then
            fail_reason  := '409';
            vStopCtrl    := true;
          end if;
        end if;

        select max(ACS_SUB_SET_ID)
          into sub_set_id
          from ACS_SUB_SET
         where C_TYPE_SUB_SET = 'DIVI';

        -- maj de l'id du compte division
        if     not vStopCtrl
           and sub_set_id is not null then
          -- recherche du compte division à partir de son numéro
          if     fin_imputation_tuple.div_number is not null
             and fin_imputation_tuple.acs_division_account_id is null then
            select max(ACS_DIVISION_ACCOUNT_ID)
                 , nvl(max(ACC_BLOCKED), 0)
                 , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
                 , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
              into division_id
                 , blocked
                 , validSince
                 , validTo
              from ACS_DIVISION_ACCOUNT
                 , ACS_ACCOUNT
             where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID
               and ACC_NUMBER = fin_imputation_tuple.div_number;

            if not vStopCtrl then
              if division_id is not null then
                if     blocked = 0
                   and fin_imputation_tuple.IMF_TRANSACTION_DATE between validSince and validTo then
                  -- recherche du compte financier
                  select max(ACS_FINANCIAL_ACCOUNT_ID)
                    into financial_id
                    from ACI_FINANCIAL_IMPUTATION
                   where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;

                  -- contrôle des interactions
                  if division_id = ACS_FUNCTION.GetDivisionOfAccount(financial_id, division_id, doc_date) then
                    update ACI_FINANCIAL_IMPUTATION
                       set ACS_DIVISION_ACCOUNT_ID = division_id
                     where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
                  else
                    fail_reason  := '471';
                    vStopCtrl    := true;
                  end if;
                else
                  fail_reason  := '472';
                  vStopCtrl    := true;
                end if;
              else
                fail_reason  := '470';
                vStopCtrl    := true;
              end if;
            end if;
          -- si le compte division est donné
          elsif     not vStopCtrl
                and fin_imputation_tuple.acs_division_account_id is not null then
            select max(ACS_ACCOUNT_ID)
                 , nvl(max(ACC_BLOCKED), 0)
                 , max(nvl(ACC_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') ) )
                 , max(nvl(ACC_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') ) )
              into division_id
                 , blocked
                 , validSince
                 , validTo
              from ACS_ACCOUNT
             where ACS_ACCOUNT.ACS_ACCOUNT_ID = fin_imputation_tuple.acs_division_account_id;

            -- Si le compte est bloqué ou qu'il n'est plus dans les dates de validité
            if    blocked = 1
               or not(fin_imputation_tuple.IMF_TRANSACTION_DATE between validSince and validTo) then
              fail_reason  := '472';
              vStopCtrl    := true;
            end if;

            if not vStopCtrl then
              if division_id is not null then
                -- recherche du compte financier
                select max(ACS_FINANCIAL_ACCOUNT_ID)
                  into financial_id
                  from ACI_FINANCIAL_IMPUTATION
                 where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;

                -- contrôle des interactions
                if division_id = ACS_FUNCTION.GetDivisionOfAccount(financial_id, division_id, doc_date) then
                  update ACI_FINANCIAL_IMPUTATION
                     set ACS_DIVISION_ACCOUNT_ID = division_id
                   where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;
                else
                  fail_reason  := '471';
                  vStopCtrl    := true;
                end if;
              else
                fail_reason  := '470';
                vStopCtrl    := true;
              end if;
            end if;
          -- Si aucun enregistrement n'a été trouvé on recherche le compte division du partenaire
          elsif     not vStopCtrl
                and fin_imputation_tuple.acs_division_account_id is null then
            -- recherche du compte auxiliare
            select max(ACS_AUXILIARY_ACCOUNT_ID)
              into auxiliary_id
              from ACI_FINANCIAL_IMPUTATION
             where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;

            if auxiliary_id is not null then
              select max(ACS_DIVISION_ACCOUNT_ID)
                into division_id
                from ACS_AUXILIARY_ACCOUNT
               where ACS_AUXILIARY_ACCOUNT_ID = auxiliary_id;

              -- si on a trouvé un compte division, mise à jour de l'imputation de l'interface }
              if division_id is not null then
                update ACI_FINANCIAL_IMPUTATION
                   set ACS_DIVISION_ACCOUNT_ID = division_id
                 where aci_financial_imputation_id = fin_imputation_tuple.aci_financial_imputation_id;
              else
                -- recherche du compte collectif suivant les interractions
                if type_catalogue in('2', '6') then
                  select acs_invoice_coll_id
                    into coll_id
                    from acs_auxiliary_account
                   where acs_auxiliary_account_id = auxiliary_id;
                elsif type_catalogue in('5') then
                  select acs_prep_coll_id
                    into coll_id
                    from acs_auxiliary_account
                   where acs_auxiliary_account_id = auxiliary_id;
                end if;

                select max(ACS_DIVISION_ACCOUNT_ID)
                  into division_id
                  from ACS_INTERACTION
                 where ACS_FINANCIAL_ACCOUNT_ID = coll_id
                   and INT_PAIR_DEFAULT = 1;

                -- recherche  de la division par défaut du sous-ensemble
                if division_id is null then
                  select max(ACS_DIVISION_ACCOUNT_ID)
                    into division_id
                    from ACS_DIVISION_ACCOUNT
                   where DIV_DEFAULT_ACCOUNT = 1;
                end if;

                if division_id is not null then
                  update ACI_FINANCIAL_IMPUTATION
                     set ACS_DIVISION_ACCOUNT_ID = division_id
                   where aci_financial_imputation_id = fin_imputation_tuple.aci_financial_imputation_id;
                else
                  fail_reason  := '470';
                  vStopCtrl    := true;
                end if;
              end if;
            else
              -- recherche du compte financier
              select max(ACS_FINANCIAL_ACCOUNT_ID)
                into financial_id
                from ACI_FINANCIAL_IMPUTATION
               where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;

              -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
              if financial_id is not null then
                -- recherche de la division par défaut dans l'interaction
                select max(ACS_DIVISION_ACCOUNT_ID)
                  into division_id
                  from ACS_INTERACTION
                 where ACS_FINANCIAL_ACCOUNT_ID = financial_id
                   and INT_PAIR_DEFAULT = 1
                   and doc_date between nvl(INT_VALID_SINCE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                    and nvl(INT_VALID_TO, to_date('31.12.2999', 'DD.MM.YYYY') );

                -- recherche du compte division par défaut
                if division_id is null then
                  select max(ACS_DIVISION_ACCOUNT_ID)
                    into division_id
                    from ACS_DIVISION_ACCOUNT
                   where DIV_DEFAULT_ACCOUNT = 1;
                end if;

                -- si on a trouvé un compte division, mise à jour de l'imputation de l'interface }
                if division_id is not null then
                  update ACI_FINANCIAL_IMPUTATION
                     set ACS_DIVISION_ACCOUNT_ID = division_id
                   where aci_financial_imputation_id = fin_imputation_tuple.aci_financial_imputation_id;
                else
                  fail_reason  := '470';
                  vStopCtrl    := true;
                end if;
              else
                fail_reason  := '470';
                vStopCtrl    := true;
              end if;
            end if;
          end if;
        end if;

        -- si on a pas trouvé de compte financier : erreur
        if     not vStopCtrl
           and financial_id is null
           and fin_imputation_tuple.acs_financial_account_id is null then
          fail_reason  := '410';
          vStopCtrl    := true;
        end if;

        -- vérifier que le compte financier de l'imputation primaire soit un compte collectif ou que le compte financier de la contre-écriture ne soit pas collectif
        if     not vStopCtrl
           and type_catalogue in('2', '5', '6') then
          if fin_imputation_tuple.imf_primary = 1 then
            begin
              select ACS_FINANCIAL_ACCOUNT_ID
                into financial_id
                from ACS_FINANCIAL_ACCOUNT
               where ACS_FINANCIAL_ACCOUNT_ID = financial_id
                 and FIN_COLLECTIVE = 1;
            exception
              when no_data_found then
                fail_reason  := '495';
                vStopCtrl    := true;
            end;
          else   --contre écriture: pas de compte collectif
            begin
              select ACS_FINANCIAL_ACCOUNT_ID
                into financial_id
                from ACS_FINANCIAL_ACCOUNT
               where ACS_FINANCIAL_ACCOUNT_ID = financial_id
                 and FIN_COLLECTIVE = 0;
            exception
              when no_data_found then
                fail_reason  := '498';
                vStopCtrl    := true;
            end;
          end if;
        end if;

        if not vStopCtrl then
          if nvl(length(fin_imputation_tuple.IMF_DESCRIPTION), 0) = 0 then
            fail_reason  := '489';
            vStopCtrl    := true;
          end if;
        end if;

        if vStopCtrl then
          update aci_financial_imputation
             set IMF_CONTROL_FLAG = 1
           where ACI_FINANCIAL_IMPUTATION_ID = fin_imputation_tuple.aci_financial_imputation_id;

          close fin_imputation;

          return 0;
        end if;

        fetch fin_imputation
         into fin_imputation_tuple;
      end loop;

      close fin_imputation;
    elsif type_catalogue in('3', '8', '9') then
      select sign(count(*) )
        into is_finImp
        from ACI_FINANCIAL_IMPUTATION
       where ACI_DOCUMENT_ID = document_id;

      if is_finImp = 1 then
        if type_catalogue = '8' then
          -- document de relance avec imputations financières
          fail_reason  := '699';
        elsif type_catalogue = '9' then
          -- document de lettrage avec imputations financières
          fail_reason  := '499';
        else
          -- document de paiement avec imputations financières
          fail_reason  := '701';
        end if;

        return 0;
      end if;
    end if;

    return 1;
  end Financial_Imputation_Control;

  /**
  * fonction Reminder_Control
  * Description
  *    Contrôle des relances
  * @author DW
  * @created 15.10.2003
  * @lastUpdate
  * @private
  * @param aDocumentId      : id du document dont on veut contrôler les paiements
  * @param aTypeCatalogue   : type de catalogue document
  * @param aPaymentCurrencyID  : id de la monnaie du document
  * @param aThirdId  : id du tiers
  * @param fail_reason out  : valeur de descode c_fail_reason en cas d'erreur de contrôle
  * @return 1 si control OK sinon à 0
  */
  function Reminder_Control(
    aPartImputationId in     number
  , aTypeCatalogue    in     varchar2
  , aThirdId          in     number
  , fail_reason       in out number
  )
    return signtype
  is
    cursor reminder_cursor(cPartImputationID number)
    is
      select *
        from aci_reminder
       where aci_part_imputation_id = cPartImputationID;

    reminder_tuple        reminder_cursor%rowtype;

    cursor remindertext_cursor(cPartImputationID number)
    is
      select *
        from aci_reminder_text
       where aci_part_imputation_id = cPartImputationId;

    remindertext_tuple    remindertext_cursor%rowtype;
    nbReminder            integer;
    financial_currency_id ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    expiryId              ACT_EXPIRY.ACT_EXPIRY_ID%type;
    expiryAmountLc        ACT_EXPIRY.EXP_AMOUNT_LC%type;
    expiryAmountFc        ACT_EXPIRY.EXP_AMOUNT_FC%type;
    test_num              number;
  begin
    -- recherche des infos cumulées
    select count(*)
      into nbReminder
      from ACI_REMINDER
     where ACI_PART_IMPUTATION_ID = aPartImputationId;

    -- contrôle seulement si on a des paiements
    if     nbReminder > 0
       and (aTypeCatalogue != '8') then
      -- pas de relances pour les documents autres que 8
      fail_reason  := '650';
      return 0;
    elsif aTypeCatalogue = '8' then
      if nbReminder > 0 then
        open reminder_cursor(aPartImputationId);

        fetch reminder_cursor
         into reminder_tuple;

        while reminder_cursor%found loop
          -- maj de l'id des monnaies
          if     reminder_tuple.currency1 is not null
             and reminder_tuple.acs_financial_currency_id is null then
            select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
              into financial_currency_id
              from ACS_FINANCIAL_CURRENCY FIN
                 , PCS.PC_CURR CUR
             where CUR.PC_CURR_ID = FIN.PC_CURR_ID
               and CUR.CURRENCY = reminder_tuple.currency1;

            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            if financial_currency_id is not null then
              update ACI_REMINDER
                 set ACS_FINANCIAL_CURRENCY_id = financial_currency_id
               where ACI_REMINDER_ID = reminder_tuple.ACI_REMINDER_ID;

              reminder_tuple.acs_financial_currency_id  := financial_currency_id;
            else
              fail_reason  := '661';

              close reminder_cursor;

              return 0;
            end if;
          elsif     reminder_tuple.currency1 is null
                and reminder_tuple.acs_financial_currency_id is null then
            fail_reason  := '661';

            close reminder_cursor;

            return 0;
          end if;

          if     reminder_tuple.currency2 is not null
             and reminder_tuple.acs_acs_financial_currency_id is null then
            select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
              into financial_currency_id
              from ACS_FINANCIAL_CURRENCY FIN
                 , PCS.PC_CURR CUR
             where CUR.PC_CURR_ID = FIN.PC_CURR_ID
               and CUR.CURRENCY = reminder_tuple.currency2;

            -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
            if financial_currency_id is not null then
              update ACI_REMINDER
                 set ACS_ACS_FINANCIAL_CURRENCY_id = financial_currency_id
               where ACI_REMINDER_ID = reminder_tuple.ACI_REMINDER_ID;
            else
              fail_reason  := '661';

              close reminder_cursor;

              return 0;
            end if;
          elsif     reminder_tuple.currency2 is null
                and reminder_tuple.acs_acs_financial_currency_id is null then
            fail_reason  := '661';

            close reminder_cursor;

            return 0;
          end if;

          begin
            select exp.ACT_EXPIRY_ID
                 , exp.EXP_AMOUNT_LC
                 , exp.EXP_AMOUNT_FC
              into expiryId
                 , expiryAmountLc
                 , expiryAmountFc
              from ACT_PART_IMPUTATION PAR
                 , ACT_EXPIRY exp
             where PAR.PAR_DOCUMENT = reminder_tuple.PAR_DOCUMENT
               and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
               and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
               and EXP_SLICE = nvl(reminder_tuple.REM_SEQ_NUMBER, 1)
               and EXP_CALC_NET = 1;
          exception
            when no_data_found then
              fail_reason  := '670';

              close reminder_cursor;

              return 0;
            when too_many_rows then
              fail_reason  := '670';

              close reminder_cursor;

              return 0;
          end;

          -- contrôle que le montant d'echéance an monnaie locale soit >= au montant relancé
          if (    sign(expiryAmountLc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 1) ) =
                                                                              sign(reminder_tuple.REM_PAYABLE_AMOUNT_LC)
              and abs(expiryAmountLc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 1) ) <
                                                                               abs(reminder_tuple.REM_PAYABLE_AMOUNT_LC)
             ) then
            fail_reason  := '671';

            close reminder_cursor;

            return 0;
          end if;

          -- contrôle si on est en monnaie étrangère que le montant d'echéance an monnaie étrangère
          -- soit >= au montant relancé
          if     reminder_tuple.ACS_FINANCIAL_CURRENCY_id != ACS_FUNCTION.GetLocalCurrencyId
             and (    sign(expiryAmountFc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 0) ) =
                                                                              sign(reminder_tuple.REM_PAYABLE_AMOUNT_FC)
                  and abs(expiryAmountFc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 0) ) <
                                                                               abs(reminder_tuple.REM_PAYABLE_AMOUNT_FC)
                 ) then
            fail_reason  := '672';

            close reminder_cursor;

            return 0;
          end if;

          -- contrôle des textes
          open remindertext_cursor(aPartImputationId);

          fetch remindertext_cursor
           into remindertext_tuple;

          while remindertext_cursor%found loop
            if trim(remindertext_tuple.REM_TEXT) is null then
              fail_reason  := '681';

              close remindertext_cursor;

              close reminder_cursor;

              return 0;
            end if;

            select max(0)
              into test_num
              from PCS.PC_GCODES COD
             where COD.GCGNAME = 'C_TEXT_TYPE'
               and COD.GCLCODE = remindertext_tuple.C_TEXT_TYPE;

            if test_num is null then
              fail_reason  := '680';

              close remindertext_cursor;

              close reminder_cursor;

              return 0;
            end if;

            fetch remindertext_cursor
             into remindertext_tuple;
          end loop;

          close remindertext_cursor;

          fetch reminder_cursor
           into reminder_tuple;
        end loop;

        close reminder_cursor;
      else
        -- au moins 1 ligne doit exister
        fail_reason  := '651';
        return 0;
      end if;
    end if;

    return 1;
  end Reminder_Control;

  /**
  * fonction Det_Payment_Control
  * Description
  *    Contrôle des détails paiement
  * @author FP
  * @created 17.01.2002
  * @lastUpdate
  * @private
  * @param aPartImputationId : id du part_imputation dont on veut contrôler les paiements
  * @param aTypeCatalogue   : type de catalogue document
  * @param aPaymentCurrencyID  : id de la monnaie du document
  * @param aThirdId  : id du tiers
  * @param fail_reason out  : valeur de descode c_fail_reason en cas d'erreur de contrôle
  * @param aDocumentId      : id du document dont on veut contrôler les paiements (pour document écritures (type 1))
  * @return 1 si control OK sinon à 0
  */
  function Det_Payment_Control(
    aPartImputationId        in     number
  , aTypeCatalogue           in     varchar2
  , aJob_type_s_catalogue_id in     number
  , aPaymentCurrencyID       in     varchar2
  , aThirdId                 in     number
  , fail_reason              in out number
  , aDocumentId              in     number default null
  )
    return signtype
  is
    cursor detPayment_cursor(cPartImputationID number, cDocumentID number)
    is
      select *
        from aci_det_payment
       where aci_part_imputation_id = cPartImputationID
          or aci_document_id = cDocumentID;

    detPayment_tuple          detPayment_cursor%rowtype;
    nbPayment                 integer;
    signExp                   number(1);
    signDet                   number(1);
    diffAmountLc              ACI_DET_PAYMENT.DET_PAIED_LC%type;
    diffAmountFc              ACI_DET_PAYMENT.DET_PAIED_FC%type;
    impAmountLc               ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    impAmountFc               ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    partImputationId          ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    expiryId                  ACT_EXPIRY.ACT_EXPIRY_ID%type;
    expiryCurrencyId          ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_Id%type;
    expiryAmountLc            ACT_EXPIRY.EXP_AMOUNT_LC%type;
    expiryAmountFc            ACT_EXPIRY.EXP_AMOUNT_FC%type;
    catalogue_document_id     ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type;
    info_imp_values           ACT_IMP_MANAGEMENT.InfoImputationValuesRecType;
    managed_infos             ACT_IMP_MANAGEMENT.InfoImputationRecType;
    managed_imput             ACT_IMP_MANAGEMENT.InfoImputationBaseRecType;
    error_info_imp            number;
    goodId                    gco_good.gco_good_id%type;
    recordId                  doc_record.doc_record_id%type;
    vC_RCO_STATUS             DOC_RECORD.C_RCO_STATUS%type;
    hrmpersonId               hrm_person.hrm_person_id%type;
    personId                  pac_person.pac_person_id%type;
    fixedassetsId             fam_fixed_assets.fam_fixed_assets_id%type;
    cfamtransactiontyp        aci_financial_imputation.c_fam_transaction_typ%type;
    dicimpfree1id             dic_imp_free1.dic_imp_free1_id%type;
    dicimpfree2id             dic_imp_free2.dic_imp_free2_id%type;
    dicimpfree3id             dic_imp_free3.dic_imp_free3_id%type;
    dicimpfree4id             dic_imp_free4.dic_imp_free4_id%type;
    dicimpfree5id             dic_imp_free5.dic_imp_free5_id%type;
    job_type_s_cat_det_id     ACI_DET_PAYMENT.ACJ_JOB_TYPE_S_CAT_DET_ID%type;
    type_catalogue_pmt        ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
    job_type_pmt_id           ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type;
    job_type_id               ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type;
    pmt_account_id            ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    createAdvance             boolean;
    vCAT_COVER_INFORMATION    ACJ_CATALOGUE_DOCUMENT.CAT_COVER_INFORMATION%type;
    vACS_FIN_ACC_S_PAYMENT_ID ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID%type;
    vPMM_COVER_GENERATION     ACS_FIN_ACC_S_PAYMENT.PMM_COVER_GENERATION%type;
    vFIN_PORTFOLIO            ACS_FINANCIAL_ACCOUNT.FIN_PORTFOLIO%type;
    vC_TYPE_SUPPORT           ACS_PAYMENT_METHOD.C_TYPE_SUPPORT%type;
    vAcsFinCurId              ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vStopCtrl                 boolean;
  begin
    -- recherche des infos cumulées
    select count(*)
         , sum(nvl(DET_PAIED_LC, 0) )
         , sum(nvl(DET_PAIED_FC, 0) )
      into nbPayment
         , diffAmountLc
         , diffAmountFc
      from ACI_DET_PAYMENT
     where ACI_PART_IMPUTATION_ID = aPartImputationId;

    -- contrôle seulement si on a des paiements
    if     nbPayment > 0
       and (aTypeCatalogue not in('3', '9', '2', '5', '6', '1') ) then
      -- pas de details paiement pour les documents autres quen 3 et 9
      fail_reason  := '600';
      return 0;
    elsif     aTypeCatalogue = '9'
          and nbPayment < 2 then   -- au moins deux lignes doivent exister
      -- au moins deux lignes doivent exister
      fail_reason  := '601';
      return 0;
    elsif     aTypeCatalogue = '9'
          and (   diffAmountLc <> 0
               or DiffAmountFc <> 0) then   -- contrôle des montants OK
      if diffAmountLc <> 0 then
        -- somme des lettrages en monnaie de base non égale à 0
        fail_reason  := '602';
        return 0;
      elsif diffAmountFc <> 0 then
        -- somme des lettrages en monnaie de étarngère non égale à 0
        fail_reason  := '603';
        return 0;
      end if;
    elsif     aTypeCatalogue = '3'
          and nbPayment = 0 then
      -- Détail paiement manquant
      fail_reason  := '700';
      return 0;
    else
      if aTypeCatalogue = '1' then
        -- recherche total paiement
        select sum(nvl(DET_PAIED_LC, 0) )
             , sum(nvl(DET_PAIED_FC, 0) )
          into diffAmountLc
             , diffAmountFc
          from ACI_DET_PAYMENT
         where ACI_DOCUMENT_ID = aDocumentId;

        -- recherche montant 'facture'
        select nvl(max(IMF_AMOUNT_LC_D), 0) + nvl(max(IMF_AMOUNT_LC_C), 0)
             , nvl(max(IMF_AMOUNT_FC_D), 0) + nvl(max(IMF_AMOUNT_FC_C), 0)
          into impAmountLc
             , impAmountFc
          from ACI_FINANCIAL_IMPUTATION
         where ACI_DOCUMENT_ID = aDocumentId
           and IMF_PRIMARY = 1;

        -- si montant différent
        if abs(impAmountLc) != abs(diffAmountLc) then
          fail_reason  := '727';
          return 0;
        elsif abs(impAmountFc) != abs(diffAmountFc) then
          fail_reason  := '730';
          return 0;
        end if;
      end if;

      if aTypeCatalogue = '1' then
        -- mise à 0 du flag d'erreur sur les imputations financières du document à contrôler
        update aci_det_payment
           set DET_CONTROL_FLAG = 0
         where ACI_DOCUMENT_ID = aDocumentId;

        open detPayment_cursor(null, aDocumentId);
      else
        -- mise à 0 du flag d'erreur sur les imputations financières du document à contrôler
        update aci_det_payment
           set DET_CONTROL_FLAG = 0
         where ACI_PART_IMPUTATION_ID = aPartImputationId;

        open detPayment_cursor(aPartImputationId, null);
      end if;

      fetch detPayment_cursor
       into detPayment_tuple;

      vStopCtrl  := false;

      while detPayment_cursor%found
       and not vStopCtrl loop
        if aTypeCatalogue = '9' then   -- lettrages
          signDet  :=
            sign(detPayment_tuple.DET_PAIED_LC +
                 detPayment_tuple.DET_DISCOUNT_LC +
                 detPayment_tuple.DET_DEDUCTION_LC +
                 detPayment_tuple.DET_DIFF_EXCHANGE
                );

          begin
            if detPayment_tuple.ACT_EXPIRY_ID is null then
              select sign(max(EXP_AMOUNT_LC) )
                into signExp
                from ACT_EXPIRY exp
                   , ACT_PART_IMPUTATION PAR
               where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                 and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                 and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                 and EXP_CALC_NET = 1;
            else
              select sign(max(exp.EXP_AMOUNT_LC) )
                into signExp
                from ACT_EXPIRY exp
               where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                 and nvl(exp.EXP_PAC_CUSTOM_PARTNER_ID, exp.EXP_PAC_SUPPLIER_PARTNER_ID) = aThirdId
                 and EXP_CALC_NET = 1;
            end if;
          exception
            when no_data_found then
              vStopCtrl    := true;
              fail_reason  := '610';
          end;

          if not vStopCtrl then
            if signExp = signDet then
              if detPayment_tuple.ACT_EXPIRY_ID is null then
                -- recherche du document de référence dans l'ACT
                -- avec une echéance non lettrée pour le même partenaire
                select max(PAR.ACT_PART_IMPUTATION_ID)
                     , max(PAR.ACS_FINANCIAL_CURRENCY_ID)
                  into partImputationId
                     , expiryCurrencyId
                  from ACT_PART_IMPUTATION PAR
                     , ACT_EXPIRY exp
                 where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                   and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                   and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                   and exp.C_STATUS_EXPIRY = 0;
              else
                -- recherche du document de référence dans l'ACT
                -- avec une echéance non lettrée pour le même partenaire
                select max(PAR.ACT_PART_IMPUTATION_ID)
                     , max(PAR.ACS_FINANCIAL_CURRENCY_ID)
                  into partImputationId
                     , expiryCurrencyId
                  from ACT_PART_IMPUTATION PAR
                     , ACT_EXPIRY exp
                 where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                   and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                   and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                   and exp.C_STATUS_EXPIRY = 0;
              end if;
            else
              if detPayment_tuple.ACT_EXPIRY_ID is null then
                -- recherche du document de référence dans l'ACT
                -- avec une echéance non lettrée pour le même partenaire
                select max(PAR.ACT_PART_IMPUTATION_ID)
                     , max(PAR.ACS_FINANCIAL_CURRENCY_ID)
                  into partImputationId
                     , expiryCurrencyId
                  from ACT_DET_PAYMENT DET
                     , ACT_EXPIRY exp
                     , ACT_PART_IMPUTATION PAR
                 where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                   and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                   and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                   and exp.ACT_EXPIRY_ID = DET.ACT_EXPIRY_ID;
              else
                -- recherche du document de référence dans l'ACT
                -- avec une echéance non lettrée pour le même partenaire
                select max(PAR.ACT_PART_IMPUTATION_ID)
                     , max(PAR.ACS_FINANCIAL_CURRENCY_ID)
                  into partImputationId
                     , expiryCurrencyId
                  from ACT_DET_PAYMENT DET
                     , ACT_EXPIRY exp
                     , ACT_PART_IMPUTATION PAR
                 where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                   and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                   and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                   and exp.ACT_EXPIRY_ID = DET.ACT_EXPIRY_ID;
              end if;
            end if;

            -- si pas d'échéances ouvertes (non lettrée)
            if partImputationId is null then
              vStopCtrl    := true;
              fail_reason  := '610';
            end if;
          end if;

          -- si la monnaie du document expiry est différente de la monnaie du paiement
          if     not vStopCtrl
             and expiryCurrencyId <> aPaymentCurrencyId then
            vStopCtrl    := true;
            fail_reason  := '611';
          end if;

          -- si on a pas déjà une erreur
          if not vStopCtrl then
            if signExp = signDet then
              begin
                if detPayment_tuple.ACT_EXPIRY_ID is null then
                  -- recherche du document de référence dans l'ACT
                  -- avec une echéance non lettrée pour le même partenaire
                  select PAR.ACT_PART_IMPUTATION_ID
                       , exp.ACT_EXPIRY_ID
                       , exp.EXP_AMOUNT_LC
                       , exp.EXP_AMOUNT_FC
                    into partImputationId
                       , expiryId
                       , expiryAmountLc
                       , expiryAmountFc
                    from ACT_PART_IMPUTATION PAR
                       , ACT_EXPIRY exp
                   where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                     and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                     and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                     and EXP_SLICE = nvl(detPayment_tuple.DET_SEQ_NUMBER, 1)
                     and EXP_CALC_NET = 1
                     and exp.C_STATUS_EXPIRY = 0;
                else
                  -- recherche du document de référence dans l'ACT
                  -- avec une echéance non lettrée pour le même partenaire
                  select exp.ACT_PART_IMPUTATION_ID
                       , exp.ACT_EXPIRY_ID
                       , exp.EXP_AMOUNT_LC
                       , exp.EXP_AMOUNT_FC
                    into partImputationId
                       , expiryId
                       , expiryAmountLc
                       , expiryAmountFc
                    from ACT_EXPIRY exp
                   where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                     and nvl(exp.EXP_PAC_CUSTOM_PARTNER_ID, exp.EXP_PAC_SUPPLIER_PARTNER_ID) = aThirdId
                     and exp.EXP_CALC_NET = 1
                     and exp.C_STATUS_EXPIRY = 0;
                end if;
              exception
                when no_data_found then
                  vStopCtrl    := true;
                  fail_reason  := '620';
                when too_many_rows then
                  vStopCtrl    := true;
                  fail_reason  := '623';
              end;
            else
              begin
                if detPayment_tuple.ACT_EXPIRY_ID is null then
                  -- recherche du document de référence dans l'ACT
                  -- avec une echéance lettrée pour le même partenaire (extourne lettrage)
                  select distinct PAR.ACT_PART_IMPUTATION_ID
                                , exp.ACT_EXPIRY_ID
                                , exp.EXP_AMOUNT_LC
                                , exp.EXP_AMOUNT_FC
                             into partImputationId
                                , expiryId
                                , expiryAmountLc
                                , expiryAmountFc
                             from ACT_DET_PAYMENT DET
                                , ACT_EXPIRY exp
                                , ACT_PART_IMPUTATION PAR
                            where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                              and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                              and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                              and EXP_SLICE = nvl(detPayment_tuple.DET_SEQ_NUMBER, 1)
                              and EXP_CALC_NET = 1
                              and exp.ACT_EXPIRY_ID = DET.ACT_EXPIRY_ID;
                else
                  -- recherche du document de référence dans l'ACT
                  -- avec une echéance lettrée pour le même partenaire (extourne lettrage)
                  select distinct exp.ACT_PART_IMPUTATION_ID
                                , exp.ACT_EXPIRY_ID
                                , exp.EXP_AMOUNT_LC
                                , exp.EXP_AMOUNT_FC
                             into partImputationId
                                , expiryId
                                , expiryAmountLc
                                , expiryAmountFc
                             from ACT_DET_PAYMENT DET
                                , ACT_EXPIRY exp
                            where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                              and nvl(exp.EXP_PAC_CUSTOM_PARTNER_ID, exp.EXP_PAC_SUPPLIER_PARTNER_ID) = aThirdId
                              and exp.EXP_CALC_NET = 1
                              and exp.ACT_EXPIRY_ID = DET.ACT_EXPIRY_ID;
                end if;
              exception
                when no_data_found then
                  vStopCtrl    := true;
                  fail_reason  := '620';
                when too_many_rows then
                  vStopCtrl    := true;
                  fail_reason  := '623';
              end;
            end if;
          end if;
        elsif aTypeCatalogue in('2', '5', '6', '1') then   -- paiements directs et écritures avec paiements (1)
          if    detPayment_tuple.acj_job_type_s_cat_det_id is not null
             or detPayment_tuple.cat_key_det is not null then
            -- maj de l'id de la transaction du modèle pour le paiement direct
            -- ???? tenir compte du typ_key ????
            -- ???? (tpl_detpay.cat_key_det is not null and document_tuple.typ_key is not null) ????
            if     not vStopCtrl
               and detPayment_tuple.cat_key_det is not null
               and detPayment_tuple.acj_job_type_s_cat_det_id is null then
              select max(ACJ_JOB_TYPE_S_CATALOGUE_ID)
                into job_type_s_cat_det_id
                from ACJ_JOB_TYPE_S_CATALOGUE
                   , ACJ_CATALOGUE_DOCUMENT
               where ACJ_CATALOGUE_DOCUMENT.CAT_KEY = detPayment_tuple.cat_key_det
                 and
                     -- ???? ACJ_JOB_TYPE.TYP_KEY = document_tuple.typ_key and ????
                     -- ???? ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID and ????
                     ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID =
                                                                        ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

              -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
              if job_type_s_cat_det_id is not null then
                update ACI_DET_PAYMENT
                   set ACJ_JOB_TYPE_S_CAT_DET_ID = job_type_s_cat_det_id
                 where ACI_DET_PAYMENT_ID = detPayment_tuple.aci_det_payment_id;
              else
                fail_reason  := '722';
                vStopCtrl    := true;
              end if;
            elsif     not vStopCtrl
                  and detPayment_tuple.ACJ_JOB_TYPE_S_CAT_DET_ID is null then
              fail_reason  := '722';
              vStopCtrl    := true;
            else
              job_type_s_cat_det_id  := detPayment_tuple.ACJ_JOB_TYPE_S_CAT_DET_ID;
            end if;

            -- les deux transactions du modèle doivent être dans le même travail
            if     not vStopCtrl
               and job_type_s_cat_det_id is not null then
              -- pour un document avec paiement, contrôle que des paiements différents de zéro existent
              -- et pour type '1' sans deduction et escompte
              -- DWA 24.08.2007: Suppression du contrôle sur paiement à 0 pour les factures. On autorise des paiements à 0
              --                 pour des paiements direct à 0 (montant testé précédement).
              --                 Le paiement est supprimé (pas intégré) lors de l'intégration.
              if     aTypeCatalogue = '1'
                 and (    (nvl(detPayment_tuple.DET_PAIED_LC, 0) = 0)
                      or (    (nvl(detPayment_tuple.DET_DISCOUNT_LC, 0) != 0)
                          or (nvl(detPayment_tuple.DET_DEDUCTION_LC, 0) != 0)
                         )
                     ) then
                fail_reason  := '727';
                vStopCtrl    := true;
              end if;

              if not vStopCtrl then
                -- recherche du type de catalogue document paiement
                select max(C_TYPE_CATALOGUE)
                  into type_catalogue_pmt
                  from ACJ_JOB_TYPE_S_CATALOGUE A
                     , ACJ_CATALOGUE_DOCUMENT B
                 where B.ACJ_CATALOGUE_DOCUMENT_ID = A.ACJ_CATALOGUE_DOCUMENT_ID
                   and A.ACJ_JOB_TYPE_S_CATALOGUE_id = job_type_s_cat_det_id;

                if     aTypeCatalogue = '1'
                   and type_catalogue_pmt <> '1' then
                  -- le type écriture (1) est obligatoire
                  fail_reason  := '723';
                  vStopCtrl    := true;
                elsif     aTypeCatalogue <> '1'
                      and type_catalogue_pmt <> '3' then
                  -- le type paiement manuel (3) est obligatoire
                  fail_reason  := '723';
                  vStopCtrl    := true;
                end if;
              end if;

              if not vStopCtrl then
                -- recherche du modèle de travail
                select max(ACJ_JOB_TYPE_ID)
                  into job_type_id
                  from ACJ_JOB_TYPE_S_CATALOGUE
                 where ACJ_JOB_TYPE_S_CATALOGUE_ID = aJob_type_s_catalogue_id;

                -- recherche du modèle de travail pour le paiement
                select max(ACJ_JOB_TYPE_ID)
                     , max(ACS_FINANCIAL_ACCOUNT_ID)
                  into job_type_pmt_id
                     , pmt_account_id
                  from ACJ_JOB_TYPE_S_CATALOGUE
                     , ACJ_CATALOGUE_DOCUMENT
                 where ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_cat_det_id
                   and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID =
                                                                        ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

                if job_type_id <> job_type_pmt_id then
                  fail_reason  := '724';
                  vStopCtrl    := true;
                elsif pmt_account_id is null then
                  fail_reason  := '726';
                  vStopCtrl    := true;
                end if;
              end if;

              if     not vStopCtrl
                 and aTypeCatalogue <> '1' then
                select min(FIN_PORTFOLIO)
                  into vFIN_PORTFOLIO
                  from ACS_FINANCIAL_ACCOUNT
                 where ACS_FINANCIAL_ACCOUNT_ID = pmt_account_id;

                if vFIN_PORTFOLIO = 1 then
                  -- Recherche info couverture + méthode de paiement du catalogue
                  select min(ACJ_CATALOGUE_DOCUMENT.CAT_COVER_INFORMATION)
                       , min(ACJ_CATALOGUE_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID)
                    into vCAT_COVER_INFORMATION
                       , vACS_FIN_ACC_S_PAYMENT_ID
                    from ACJ_JOB_TYPE_S_CATALOGUE
                       , ACJ_CATALOGUE_DOCUMENT
                   where ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_cat_det_id
                     and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID =
                                                                        ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

                  -- Recherche méthode de paiement du catalogue, des échéances ou du partenaire (soit à null, soit égaux)
                  select min(coalesce(vACS_FIN_ACC_S_PAYMENT_ID
                                    , ACI_EXPIRY.ACS_FIN_ACC_S_PAYMENT_ID
                                    , ACI_PART_IMPUTATION.ACS_FIN_ACC_S_PAYMENT_ID
                                     )
                            )
                    into vACS_FIN_ACC_S_PAYMENT_ID
                    from ACI_EXPIRY
                       , ACI_PART_IMPUTATION
                   where ACI_EXPIRY.ACI_PART_IMPUTATION_ID(+) = ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID
                     and ACI_PART_IMPUTATION.ACI_DOCUMENT_ID = detPayment_tuple.ACI_DOCUMENT_ID;

                  -- Recherche si génération couverture pour la méthode de paiement
                  select min(PMM_COVER_GENERATION)
                    into vPMM_COVER_GENERATION
                    from ACS_FIN_ACC_S_PAYMENT
                   where ACS_FIN_ACC_S_PAYMENT_ID = vACS_FIN_ACC_S_PAYMENT_ID;

                  -- Recherche du type de paiement
                  select max(C_TYPE_SUPPORT)
                    into vC_TYPE_SUPPORT
                    from ACS_PAYMENT_METHOD
                   where ACS_PAYMENT_METHOD_ID = (select ACS_PAYMENT_METHOD_ID
                                                    from ACS_FIN_ACC_S_PAYMENT
                                                   where ACS_FIN_ACC_S_PAYMENT_ID = vACS_FIN_ACC_S_PAYMENT_ID);

                  if vCAT_COVER_INFORMATION != 1 then
                    fail_reason  := '720';
                    vStopCtrl    := true;
                  elsif vPMM_COVER_GENERATION != 1 then
                    fail_reason  := '721';
                    vStopCtrl    := true;
                  elsif     (vC_TYPE_SUPPORT = '80')
                        and (   detPayment_tuple.COV_TERMINAL is null
                             or detPayment_tuple.COV_TERMINAL_SEQ is null
                             or detPayment_tuple.COV_TRANSACTION_DATE is null
                            ) then   -- paiement par carte bancaire
                    fail_reason  := '729';
                    vStopCtrl    := true;
                  end if;
                end if;
              end if;
            end if;
          end if;
        elsif aTypeCatalogue = '3' then   -- paiements manuels
          -- info paiement pas autorisée
          if    detPayment_tuple.acj_job_type_s_cat_det_id is not null
             or detPayment_tuple.cat_key_det is not null then
            fail_reason  := '725';
            vStopCtrl    := true;
          end if;

          -- test si création d'un non-lettré
          createAdvance  :=
                detPayment_tuple.ACT_EXPIRY_ID is null
            and detPayment_tuple.PAR_DOCUMENT is null
            and detPayment_tuple.DET_SEQ_NUMBER is null;

          if not createAdvance then
            -- Recherche de l'échéance et de son signe
            if not vStopCtrl then
              begin
                if detPayment_tuple.ACT_EXPIRY_ID is null then
                  select sign(max(exp.EXP_AMOUNT_LC) )
                    into signExp
                    from ACT_EXPIRY exp
                       , ACT_PART_IMPUTATION PAR
                   where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                     and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                     and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                     and EXP_CALC_NET = 1;
                else
                  select sign(max(exp.EXP_AMOUNT_LC) )
                    into signExp
                    from ACT_EXPIRY exp
                   where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                     and nvl(exp.EXP_PAC_CUSTOM_PARTNER_ID, exp.EXP_PAC_SUPPLIER_PARTNER_ID) = aThirdId
                     and exp.EXP_CALC_NET = 1;
                end if;
              exception
                when no_data_found then
                  vStopCtrl    := true;
                  fail_reason  := '770';
              end;
            end if;

            if not vStopCtrl then
              signDet  :=
                sign(detPayment_tuple.DET_PAIED_LC +
                     detPayment_tuple.DET_DISCOUNT_LC +
                     detPayment_tuple.DET_DEDUCTION_LC +
                     detPayment_tuple.DET_DIFF_EXCHANGE
                    );

              if signExp = signDet then
                if detPayment_tuple.ACT_EXPIRY_ID is null then
                  -- recherche du document de référence dans l'ACT
                  -- avec une echéance non lettrée pour le même partenaire
                  select max(PAR.ACT_PART_IMPUTATION_ID)
                       , max(PAR.ACS_FINANCIAL_CURRENCY_ID)
                    into partImputationId
                       , expiryCurrencyId
                    from ACT_PART_IMPUTATION PAR
                       , ACT_EXPIRY exp
                   where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                     and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                     and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                     and exp.C_STATUS_EXPIRY = 0;
                else
                  -- recherche du document de référence dans l'ACT
                  -- avec une echéance non lettrée pour le même partenaire
                  select max(PAR.ACT_PART_IMPUTATION_ID)
                       , max(PAR.ACS_FINANCIAL_CURRENCY_ID)
                    into partImputationId
                       , expiryCurrencyId
                    from ACT_PART_IMPUTATION PAR
                       , ACT_EXPIRY exp
                   where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                     and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                     and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                     and exp.C_STATUS_EXPIRY = 0;
                end if;
              else
                if detPayment_tuple.ACT_EXPIRY_ID is null then
                  -- recherche du document de référence dans l'ACT
                  -- avec une echéance non lettrée pour le même partenaire
                  select max(PAR.ACT_PART_IMPUTATION_ID)
                       , max(PAR.ACS_FINANCIAL_CURRENCY_ID)
                    into partImputationId
                       , expiryCurrencyId
                    from ACT_DET_PAYMENT DET
                       , ACT_EXPIRY exp
                       , ACT_PART_IMPUTATION PAR
                   where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                     and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                     and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                     and exp.ACT_EXPIRY_ID = DET.ACT_EXPIRY_ID;
                else
                  -- recherche du document de référence dans l'ACT
                  -- avec une echéance non lettrée pour le même partenaire
                  select max(PAR.ACT_PART_IMPUTATION_ID)
                       , max(PAR.ACS_FINANCIAL_CURRENCY_ID)
                    into partImputationId
                       , expiryCurrencyId
                    from ACT_DET_PAYMENT DET
                       , ACT_EXPIRY exp
                       , ACT_PART_IMPUTATION PAR
                   where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                     and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                     and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                     and exp.ACT_EXPIRY_ID = DET.ACT_EXPIRY_ID;
                end if;
              end if;

              -- si pas d'échéances ouvertes (non lettrée)
              if partImputationId is null then
                vStopCtrl    := true;
                fail_reason  := '770';
              end if;

              -- si la monnaie du document expiry est différente de la monnaie du paiement
              if     not vStopCtrl
                 and expiryCurrencyId <> aPaymentCurrencyId then
                vStopCtrl    := true;
                fail_reason  := '771';
              end if;
            end if;
          end if;

          -- pour un document avec paiement, contrôle que des paiements différents de zéro existent
          -- ???? tenir compte du montant échéance ????
          if     (not vStopCtrl)
             and (nvl(detPayment_tuple.DET_PAIED_LC, 0) = 0) then
            fail_reason  := '727';
            vStopCtrl    := true;
          end if;

          if not createAdvance then
            -- Recherche d'un document en fonction de la tranche. Erreur si tranche absente ou plusieurs document possible.
            if not vStopCtrl then
              if signExp = signDet then
                begin
                  if detPayment_tuple.ACT_EXPIRY_ID is null then
                    -- recherche du document de référence dans l'ACT
                    -- avec une echéance non lettrée pour le même partenaire
                    select PAR.ACT_PART_IMPUTATION_ID
                         , exp.ACT_EXPIRY_ID
                         , exp.EXP_AMOUNT_LC
                         , exp.EXP_AMOUNT_FC
                      into partImputationId
                         , expiryId
                         , expiryAmountLc
                         , expiryAmountFc
                      from ACT_PART_IMPUTATION PAR
                         , ACT_EXPIRY exp
                     where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                       and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                       and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                       and EXP_SLICE = nvl(detPayment_tuple.DET_SEQ_NUMBER, 1)
                       and EXP_CALC_NET = 1
                       and exp.C_STATUS_EXPIRY = 0;
                  else
                    -- recherche du document de référence dans l'ACT
                    -- avec une echéance non lettrée pour le même partenaire
                    select exp.ACT_PART_IMPUTATION_ID
                         , exp.ACT_EXPIRY_ID
                         , exp.EXP_AMOUNT_LC
                         , exp.EXP_AMOUNT_FC
                      into partImputationId
                         , expiryId
                         , expiryAmountLc
                         , expiryAmountFc
                      from ACT_EXPIRY exp
                     where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                       and nvl(exp.EXP_PAC_CUSTOM_PARTNER_ID, exp.EXP_PAC_SUPPLIER_PARTNER_ID) = aThirdId
                       and exp.EXP_CALC_NET = 1
                       and exp.C_STATUS_EXPIRY = 0;
                  end if;
                exception
                  when no_data_found then
                    vStopCtrl    := true;
                    fail_reason  := '772';
                  when too_many_rows then
                    vStopCtrl    := true;
                    fail_reason  := '773';
                end;
              else
                begin
                  if detPayment_tuple.ACT_EXPIRY_ID is null then
                    -- recherche du document de référence dans l'ACT
                    -- avec une echéance lettrée pour le même partenaire (extourne lettrage)
                    select distinct PAR.ACT_PART_IMPUTATION_ID
                                  , exp.ACT_EXPIRY_ID
                                  , exp.EXP_AMOUNT_LC
                                  , exp.EXP_AMOUNT_FC
                                  , PAR.ACS_FINANCIAL_CURRENCY_ID
                               into partImputationId
                                  , expiryId
                                  , expiryAmountLc
                                  , expiryAmountFc
                                  , expiryCurrencyId
                               from ACT_DET_PAYMENT DET
                                  , ACT_EXPIRY exp
                                  , ACT_PART_IMPUTATION PAR
                              where PAR.PAR_DOCUMENT = detPayment_tuple.PAR_DOCUMENT
                                and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                                and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                                and EXP_SLICE = nvl(detPayment_tuple.DET_SEQ_NUMBER, 1)
                                and EXP_CALC_NET = 1
                                and exp.ACT_EXPIRY_ID = DET.ACT_EXPIRY_ID;
                  else
                    -- recherche du document de référence dans l'ACT
                    -- avec une echéance lettrée pour le même partenaire (extourne lettrage)
                    select distinct PAR.ACT_PART_IMPUTATION_ID
                                  , exp.ACT_EXPIRY_ID
                                  , exp.EXP_AMOUNT_LC
                                  , exp.EXP_AMOUNT_FC
                                  , PAR.ACS_FINANCIAL_CURRENCY_ID
                               into partImputationId
                                  , expiryId
                                  , expiryAmountLc
                                  , expiryAmountFc
                                  , expiryCurrencyId
                               from ACT_DET_PAYMENT DET
                                  , ACT_EXPIRY exp
                                  , ACT_PART_IMPUTATION PAR
                              where exp.ACT_EXPIRY_ID = detPayment_tuple.ACT_EXPIRY_ID
                                and nvl(PAR.PAC_CUSTOM_PARTNER_ID, PAR.PAC_SUPPLIER_PARTNER_ID) = aThirdId
                                and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                                and EXP_CALC_NET = 1
                                and exp.ACT_EXPIRY_ID = DET.ACT_EXPIRY_ID;
                  end if;
                exception
                  when no_data_found then
                    vStopCtrl    := true;
                    fail_reason  := '772';
                  when too_many_rows then
                    vStopCtrl    := true;
                    fail_reason  := '773';
                end;
              end if;

              -- contrôle que le montant d'echéance en monnaie locale soit >= au montant à lettrer
              if     not vStopCtrl
                 and (    sign(expiryAmountLc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 1) ) =
                            sign(detPayment_tuple.DET_PAIED_LC +
                                 detPayment_tuple.DET_DISCOUNT_LC +
                                 detPayment_tuple.DET_DEDUCTION_LC +
                                 detPayment_tuple.DET_DIFF_EXCHANGE
                                )
                      and abs(expiryAmountLc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 1) ) <
                            abs(detPayment_tuple.DET_PAIED_LC +
                                detPayment_tuple.DET_DISCOUNT_LC +
                                detPayment_tuple.DET_DEDUCTION_LC +
                                detPayment_tuple.DET_DIFF_EXCHANGE
                               )
                     ) then
                vStopCtrl    := true;
                fail_reason  := '727';
              end if;

              -- contrôle que le montant d'extourne de lettrage ne dépasse pas de montant déjà lettré
              if     not vStopCtrl
                 and (    sign(expiryAmountLc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 1) ) <>
                            sign(detPayment_tuple.DET_PAIED_LC +
                                 detPayment_tuple.DET_DISCOUNT_LC +
                                 detPayment_tuple.DET_DEDUCTION_LC +
                                 detPayment_tuple.DET_DIFF_EXCHANGE
                                )
                      and abs(ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 1) ) <
                            abs(detPayment_tuple.DET_PAIED_LC +
                                detPayment_tuple.DET_DISCOUNT_LC +
                                detPayment_tuple.DET_DEDUCTION_LC +
                                detPayment_tuple.DET_DIFF_EXCHANGE
                               )
                     ) then
                vStopCtrl    := true;
                fail_reason  := '727';
              end if;

              -- contrôle si on est en monnaie étrangère que le montant d'echéance an monnaie étrangère
              -- soit >= au montant à lettrer
              if     not vStopCtrl
                 and aPaymentCurrencyId <> ACS_FUNCTION.GetLocalCurrencyId
                 and (    sign(expiryAmountFc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 0) ) =
                            sign(detPayment_tuple.DET_PAIED_FC +
                                 detPayment_tuple.DET_DISCOUNT_FC +
                                 detPayment_tuple.DET_DEDUCTION_FC
                                )
                      and abs(expiryAmountFc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 0) ) <
                            abs(detPayment_tuple.DET_PAIED_FC +
                                detPayment_tuple.DET_DISCOUNT_FC +
                                detPayment_tuple.DET_DEDUCTION_FC
                               )
                     ) then
                vStopCtrl    := true;
                fail_reason  := '730';
              end if;

              -- contrôle si on est en monnaie étrangère que le montant d'extourne de lettrage
              -- ne dépasse pas de montant déjà lettré
              if     not vStopCtrl
                 and aPaymentCurrencyId <> ACS_FUNCTION.GetLocalCurrencyId
                 and (    sign(expiryAmountFc - ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 0) ) <>
                            sign(detPayment_tuple.DET_PAIED_FC +
                                 detPayment_tuple.DET_DISCOUNT_FC +
                                 detPayment_tuple.DET_DEDUCTION_FC
                                )
                      and abs(ACT_FUNCTIONS.TOTALPAYMENT(expiryId, 0) ) <
                            abs(detPayment_tuple.DET_PAIED_FC +
                                detPayment_tuple.DET_DISCOUNT_FC +
                                detPayment_tuple.DET_DEDUCTION_FC
                               )
                     ) then
                vStopCtrl    := true;
                fail_reason  := '730';
              end if;
            end if;
          end if;
        end if;

        --Contrôle de la monnaie ME
        if not vStopCtrl then
          if     detPayment_tuple.CURRENCY1 is not null
             and detPayment_tuple.ACS_FINANCIAL_CURRENCY_ID is null then
            select max(ACS_FINANCIAL_CURRENCY_ID)
              into vAcsFinCurId
              from ACS_FINANCIAL_CURRENCY
             where PC_CURR_ID = (select PC_CURR_ID
                                   from PCS.PC_CURR
                                  where CURRENCY = detPayment_tuple.CURRENCY1);

            if vAcsFinCurId is not null then
              update ACI_DET_PAYMENT
                 set ACS_FINANCIAL_CURRENCY_ID = vAcsFinCurId
               where ACI_DET_PAYMENT_ID = detPayment_tuple.aci_det_payment_id;
            else
              fail_reason  := '771';
              vStopCtrl    := true;
            end if;
          end if;
        end if;

        if     not vStopCtrl
           and aTypeCatalogue in('2', '5', '6', '3', '1') then
          if nvl(managed_infos.ACJ_CATALOGUE_DOCUMENT_ID, 0) = 0 then
            if aTypeCatalogue in('2', '5', '6', '1') then
              -- recherche du catalogue du paiement
              select ACJ_CATALOGUE_DOCUMENT_ID
                into catalogue_document_id
                from ACJ_JOB_TYPE_S_CATALOGUE
               where ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_cat_det_id;
            else
              -- si 3 -> recherche du catalogue
              select ACJ_CATALOGUE_DOCUMENT_ID
                into catalogue_document_id
                from ACJ_JOB_TYPE_S_CATALOGUE
               where ACJ_JOB_TYPE_S_CATALOGUE_ID = aJob_type_s_catalogue_id;
            end if;

            managed_infos  := ACT_IMP_MANAGEMENT.GetManagedData(catalogue_document_id);
          end if;

          --Suite des contrôle uniquement si les info. compl. sont activé globalement
          if managed_infos.managed then
            --On prend toujours les info secondaire
            managed_imput   := managed_infos.Secondary;

            -- maj de l'id du bien
            if     not vStopCtrl
               and detPayment_tuple.goo_major_reference is not null
               and detPayment_tuple.gco_good_id is null
               and managed_imput.GCO_GOOD_ID.managed then
              select max(GCO_GOOD_ID)
                into goodId
                from GCO_GOOD
               where GOO_MAJOR_REFERENCE = detPayment_tuple.goo_major_reference;

              -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
              if goodId is not null then
                update ACI_DET_PAYMENT
                   set gco_good_id = goodId
                 where ACI_DET_PAYMENT_ID = detPayment_tuple.aci_det_payment_id;
              else
                fail_reason  := '750';
                vStopCtrl    := true;
              end if;
            end if;

            -- maj de l'id du dossier
            if     not vStopCtrl
               and managed_imput.DOC_RECORD_ID.managed then
              if detPayment_tuple.doc_record_id is not null then
                select nvl(max(C_RCO_STATUS), '1')
                  into vC_RCO_STATUS
                  from DOC_RECORD
                 where DOC_RECORD_ID = detPayment_tuple.doc_record_id;

                if vC_RCO_STATUS <> '0' then
                  fail_reason  := '735';
                  vStopCtrl    := true;
                end if;
              elsif detPayment_tuple.rco_title is not null then
                select max(DOC_RECORD_ID)
                  into recordId
                  from DOC_RECORD
                 where RCO_TITLE = detPayment_tuple.rco_title;

                -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
                if recordId is not null then
                  select nvl(max(C_RCO_STATUS), '1')
                    into vC_RCO_STATUS
                    from DOC_RECORD
                   where DOC_RECORD_ID = recordId;

                  if vC_RCO_STATUS <> '0' then
                    fail_reason  := '735';
                    vStopCtrl    := true;
                  else
                    update ACI_DET_PAYMENT
                       set DOC_RECORD_ID = recordId
                     where ACI_DET_PAYMENT_ID = detPayment_tuple.aci_det_payment_id;
                  end if;
                else
                  fail_reason  := '751';
                  vStopCtrl    := true;
                end if;
              end if;
            end if;

            -- maj de l'id de la personne HRM
            if     not vStopCtrl
               and detPayment_tuple.emp_number is not null
               and detPayment_tuple.hrm_person_id is null
               and managed_imput.HRM_PERSON_ID.managed then
              select max(HRM_PERSON_ID)
                into hrmpersonId
                from HRM_PERSON
               where EMP_NUMBER = detPayment_tuple.emp_number;

              -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
              if hrmpersonId is not null then
                update ACI_DET_PAYMENT
                   set HRM_PERSON_ID = hrmpersonId
                 where ACI_DET_PAYMENT_ID = detPayment_tuple.aci_det_payment_id;
              else
                fail_reason  := '752';
                vStopCtrl    := true;
              end if;
            end if;

            -- maj de l'id de la personne pac
            if     not vStopCtrl
               and (    (detPayment_tuple.per_key1 is not null)
                    or (detPayment_tuple.per_key2 is not null) )
               and detPayment_tuple.pac_person_id is null
               and managed_imput.PAC_PERSON_ID.managed then
              select max(PAC_PERSON_ID)
                into personId
                from PAC_PERSON
               where PER_KEY1 = detPayment_tuple.per_key1
                  or PER_KEY2 = detPayment_tuple.per_key2;

              -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
              if personId is not null then
                update ACI_DET_PAYMENT
                   set PAC_PERSON_ID = personId
                 where ACI_DET_PAYMENT_ID = detPayment_tuple.aci_det_payment_id;
              else
                fail_reason  := '753';
                vStopCtrl    := true;
              end if;
            end if;

            -- maj de l'id de l'immobilisation
            if     not vStopCtrl
               and detPayment_tuple.fix_number is not null
               and detPayment_tuple.fam_fixed_assets_id is null
               and managed_imput.FAM_FIXED_ASSETS_ID.managed then
              select max(FAM_FIXED_ASSETS_ID)
                into fixedassetsId
                from FAM_FIXED_ASSETS
               where FIX_NUMBER = detPayment_tuple.fix_number;

              -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
              if fixedassetsId is not null then
                update ACI_DET_PAYMENT
                   set FAM_FIXED_ASSETS_ID = fixedassetsId
                 where ACI_DET_PAYMENT_ID = detPayment_tuple.aci_det_payment_id;
              else
                fail_reason  := '754';
                vStopCtrl    := true;
              end if;
            end if;

            -- maj du DCOD de l'immobilisation
            if     not vStopCtrl
               and detPayment_tuple.c_fam_transaction_typ is not null
               and managed_imput.C_FAM_TRANSACTION_TYP.managed then
              select max(COD.GCLCODE)
                into cfamtransactiontyp
                from PCS.PC_GCODES COD
               where COD.GCLCODE = detPayment_tuple.C_FAM_TRANSACTION_TYP
                 and COD.GCGNAME = 'C_FAM_TRANSACTION_TYP'
                 and rownum = 1;

              if cfamtransactiontyp is null then
                fail_reason  := '747';
                vStopCtrl    := true;
              end if;
            end if;

            -- si une immob est saisie, le dcod doit l'être également et vice-versa
            if     not vStopCtrl
               and detPayment_tuple.fam_fixed_assets_id is null
               and detPayment_tuple.fix_number is null
               and detPayment_tuple.c_fam_transaction_typ is not null
               and managed_imput.FAM_FIXED_ASSETS_ID.managed then
              fail_reason  := '746';
              vStopCtrl    := true;
            end if;

            if     not vStopCtrl
               and detPayment_tuple.C_FAM_TRANSACTION_TYP is null
               and (   detPayment_tuple.fix_number is not null   --FAM_FIXED_ASSETS_ID a déjà été trouvé => FIX_NUMBER est valide
                    or detPayment_tuple.fam_fixed_assets_id is not null
                   )
               and managed_imput.FAM_FIXED_ASSETS_ID.managed then
              fail_reason  := '747';
              vStopCtrl    := true;
            end if;

            --Contrôle des DICOs
            if     not vStopCtrl
               and detPayment_tuple.dic_imp_free1_id is not null
               and managed_imput.DICO1.managed then
              select max(DIC_IMP_FREE1_ID)
                into dicimpfree1id
                from DIC_IMP_FREE1
               where DIC_IMP_FREE1_ID = detPayment_tuple.dic_imp_free1_id;

              if dicimpfree1id is null then
                fail_reason  := '755';
                vStopCtrl    := true;
              end if;
            end if;

            if     not vStopCtrl
               and detPayment_tuple.dic_imp_free2_id is not null
               and managed_imput.DICO2.managed then
              select max(DIC_IMP_FREE2_ID)
                into dicimpfree2id
                from DIC_IMP_FREE2
               where DIC_IMP_FREE2_ID = detPayment_tuple.dic_imp_free2_id;

              if dicimpfree2id is null then
                fail_reason  := '756';
                vStopCtrl    := true;
              end if;
            end if;

            if     not vStopCtrl
               and detPayment_tuple.dic_imp_free3_id is not null
               and managed_imput.DICO3.managed then
              select max(DIC_IMP_FREE3_ID)
                into dicimpfree3id
                from DIC_IMP_FREE3
               where DIC_IMP_FREE3_ID = detPayment_tuple.dic_imp_free3_id;

              if dicimpfree3id is null then
                fail_reason  := '757';
                vStopCtrl    := true;
              end if;
            end if;

            if     not vStopCtrl
               and detPayment_tuple.dic_imp_free4_id is not null
               and managed_imput.DICO4.managed then
              select max(DIC_IMP_FREE4_ID)
                into dicimpfree4id
                from DIC_IMP_FREE4
               where DIC_IMP_FREE4_ID = detPayment_tuple.dic_imp_free4_id;

              if dicimpfree4id is null then
                fail_reason  := '758';
                vStopCtrl    := true;
              end if;
            end if;

            if     not vStopCtrl
               and detPayment_tuple.dic_imp_free5_id is not null
               and managed_imput.DICO5.managed then
              select max(DIC_IMP_FREE5_ID)
                into dicimpfree5id
                from DIC_IMP_FREE5
               where DIC_IMP_FREE5_ID = detPayment_tuple.dic_imp_free5_id;

              if dicimpfree5id is null then
                fail_reason  := '759';
                vStopCtrl    := true;
              end if;
            end if;

            ACT_IMP_MANAGEMENT.GetInfoImputationValuesDET_ACI(detPayment_tuple.aci_det_payment_id, info_imp_values);
            -- toujours info secondaire
            error_info_imp  := ACT_IMP_MANAGEMENT.CheckManagedValues(info_imp_values, managed_imput);

            -- IMF_NUMBER - IMF_NUMBER5
            if     not vStopCtrl
               and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GroupNUMBER) != 0 then
              fail_reason  := '740';
              vStopCtrl    := true;
            end if;

            -- IMF_TEXT1 - IMF_TEXT5
            if     not vStopCtrl
               and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GroupTEXT) != 0 then
              fail_reason  := '741';
              vStopCtrl    := true;
            end if;

            -- DIC_IMP_FREE1_ID - DIC_IMP_FREE5_ID
            if     not vStopCtrl
               and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GroupDICO) != 0 then
              fail_reason  := '742';
              vStopCtrl    := true;
            end if;

            -- GCO_GOOD_ID
            if     not vStopCtrl
               and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().GCO_GOOD_ID) != 0 then
              fail_reason  := '743';
              vStopCtrl    := true;
            end if;

            -- DOC_RECORD_ID
            if     not vStopCtrl
               and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().DOC_RECORD_ID) != 0 then
              fail_reason  := '744';
              vStopCtrl    := true;
            end if;

            -- HRM_PERSON_ID
            if     not vStopCtrl
               and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().HRM_PERSON_ID) != 0 then
              fail_reason  := '745';
              vStopCtrl    := true;
            end if;

            -- FAM_FIXED_ASSETS_ID
            if     not vStopCtrl
               and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().FAM_FIXED_ASSETS_ID) !=
                                                                                                                       0 then
              fail_reason  := '746';
              vStopCtrl    := true;
            end if;

            -- C_FAM_TRANSACTION_TYP
            if     not vStopCtrl
               and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().C_FAM_TRANSACTION_TYP) !=
                                                                                                                       0 then
              fail_reason  := '747';
              vStopCtrl    := true;
            end if;

            -- PAC_PERSON_ID
            if     not vStopCtrl
               and PCS.PC_BITMAN.bit_and(error_info_imp, ACT_IMP_MANAGEMENT.InfoImputationType().PAC_PERSON_ID) != 0 then
              fail_reason  := '748';
              vStopCtrl    := true;
            end if;
          end if;
        end if;

        -- Maj de la colonne indiquant l'erreur sur l'imputation concernée
        if vStopCtrl then
          update aci_det_payment
             set DET_CONTROL_FLAG = 1
           where ACI_DET_PAYMENT_ID = detPayment_tuple.aci_det_payment_id;

          close detPayment_cursor;

          return 0;
        end if;

        fetch detPayment_cursor
         into detPayment_tuple;
      end loop;

      close detPayment_cursor;
    end if;

    return 1;
  end Det_Payment_Control;

  /**
  * fonction Expiry_Bvr_Control
  * Description
  *   Controle des références BVR dans les échéances
  * @author FP
  * @lastUpdate
  * @private
  * @param part_imputation_id  : id de l'imputation partenaire propriétaire des échéances
  * @param person_id    : id du client-fournisseur
  * @param fail_reason out : valeur de descode c_fail_reason en cas d'erreur de contrôle
  * @return 1 si control OK sinon à 0
  */
  function Expiry_Bvr_Control(part_imputation_id in number, person_id in number, fail_reason in out number)
    return signtype
  is
    cursor crExpiry(part_imputation_id number)
    is
      select   exp.ACI_EXPIRY_ID
             , exp.EXP_CALC_NET
             , trim(PAR.PAR_REF_BVR) PAR_REF_BVR
             , trim(exp.EXP_REF_BVR) EXP_REF_BVR
             , exp.EXP_BVR_CODE
             , (select FIN.FRE_ACCOUNT_NUMBER
                  from PAC_FINANCIAL_REFERENCE FIN
                 where FIN.PAC_FINANCIAL_REFERENCE_ID = PAR.PAC_FINANCIAL_REFERENCE_ID) FRE_ACCOUNT_NUMBER
             , (select FIN.C_TYPE_REFERENCE
                  from PAC_FINANCIAL_REFERENCE FIN
                 where FIN.PAC_FINANCIAL_REFERENCE_ID = PAR.PAC_FINANCIAL_REFERENCE_ID) C_TYPE_REFERENCE
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , case
                 when PAC_SUPPLIER_PARTNER_ID is not null then 1
                 else 0
               end IsSupplier
          from ACI_EXPIRY exp
             , ACI_PART_IMPUTATION PAR
         where exp.ACI_PART_IMPUTATION_ID = PAR.ACI_PART_IMPUTATION_ID
           and PAR.ACI_PART_IMPUTATION_ID = part_imputation_id
      order by EXP_CALC_NET desc;

    tplExpiry         crExpiry%rowtype;
    generation_method PAC_CUSTOM_PARTNER.C_BVR_GENERATION_METHOD%type;
  begin
    open crExpiry(part_imputation_id);

    fetch crExpiry
     into tplExpiry;

    -- si l'échéance n'a pas de référence BVR
    --  et que la référence financière est de type BVR (en principe fournisseur)
    if     tplExpiry.exp_calc_net = 1
       and tplExpiry.exp_ref_bvr is null
       and tplExpiry.c_type_reference = '3' then
      if tplExpiry.par_ref_bvr is not null then
        while crExpiry%found loop
          if (pcstoNumber(replace (tplExpiry.PAR_REF_BVR, ' ')) is null) or
             (ACS_FUNCTION.VerifyNoBvr(tplExpiry.PAR_REF_BVR, tplExpiry.FRE_ACCOUNT_NUMBER) <> 1) then
            fail_reason  := '311';

            close crExpiry;

            return 0;
          end if;

          update ACI_EXPIRY
             set EXP_REF_BVR = tplExpiry.PAR_REF_BVR
           where ACI_EXPIRY_ID = tplExpiry.aci_expiry_id;

          fetch crExpiry
           into tplExpiry;
        end loop;
      else
        fail_reason  := '310';

        close crExpiry;

        return 0;
      end if;
    -- en principe documents clients
    elsif     tplExpiry.exp_calc_net = 1
          and tplExpiry.exp_ref_bvr is null then
      if tplExpiry.par_ref_bvr is not null then
        while crExpiry%found loop
          if ACS_FUNCTION.VerifyNoBvr(tplExpiry.PAR_REF_BVR, null) <> 1 then
            fail_reason  := '311';

            close crExpiry;

            return 0;
          end if;

          update ACI_EXPIRY
             set EXP_REF_BVR = tplExpiry.PAR_REF_BVR
           where ACI_EXPIRY_ID = tplExpiry.aci_expiry_id;

          select max(C_BVR_GENERATION_METHOD)
            into generation_method
            from PAC_CUSTOM_PARTNER
           where PAC_CUSTOM_PARTNER_ID = person_id;

          if    generation_method is null
             or generation_method = '03' then
            update ACI_EXPIRY
               set EXP_BVR_CODE =
                     ACS_FUNCTION.Get_BVR_Coding_Line(ACS_FIN_ACC_S_PAYMENT_ID
                                                    , tplExpiry.PAR_REF_BVR
                                                    , EXP_AMOUNT_LC
                                                    , ACS_FUNCTION.GetLocalCurrencyID
                                                    , EXP_AMOUNT_FC
                                                    , tplExpiry.ACS_FINANCIAL_CURRENCY_ID
                                                     )
             where ACI_EXPIRY_ID = tplExpiry.aci_expiry_id;
          elsif generation_method in('01', '02') then
            update ACI_EXPIRY
               set EXP_BVR_CODE =
                     ACS_FUNCTION.Get_BVR_Coding_Line(ACS_FIN_ACC_S_PAYMENT_ID
                                                    , tplExpiry.PAR_REF_BVR
                                                    , 0
                                                    , ACS_FUNCTION.GetLocalCurrencyID
                                                    , 0
                                                    , tplExpiry.ACS_FINANCIAL_CURRENCY_ID
                                                     )
             where ACI_EXPIRY_ID = tplExpiry.aci_expiry_id;
          end if;

          fetch crExpiry
           into tplExpiry;
        end loop;
      end if;
    elsif     tplExpiry.exp_calc_net = 1
          and tplExpiry.exp_ref_bvr is not null
          and (ACS_FUNCTION.VerifyNoBvr(tplExpiry.EXP_REF_BVR
                                      , case
                                          when tplExpiry.IsSupplier = 1 then tplExpiry.FRE_ACCOUNT_NUMBER
                                          else null
                                        end
                                       ) <> 1
              ) then
      fail_reason  := '311';

      close crExpiry;

      return 0;
    end if;

    close crExpiry;

    return 1;
  end Expiry_Bvr_Control;

  /**
  * fonction Expiry_Control
  * Description
  *    Controle des échéances
  * @author FP
  * @lastUpdate
  * @private
  * @param part_imputation_id  : id de l'imputation partenaire propriétaire des échéances
  * @param fail_reason out : valeur de descode c_fail_reason en cas d'erreur de contrôle
  * @return 1 si control OK sinon à 0
  */
  function Expiry_Control(part_imputation_id in number, fail_reason in out number)
    return signtype
  is
    cursor expiry_ctrl(part_imputation_id number)
    is
      select   exp.ACI_EXPIRY_ID
             , exp.EXP_AMOUNT_LC
          from ACI_EXPIRY exp
             , ACI_PART_IMPUTATION PAR
             , PAC_FINANCIAL_REFERENCE ref
         where exp.ACI_PART_IMPUTATION_ID = PAR.ACI_PART_IMPUTATION_ID
           and PAR.ACI_PART_IMPUTATION_ID = part_imputation_id
           and ref.PAC_FINANCIAL_REFERENCE_ID(+) = PAR.PAC_FINANCIAL_REFERENCE_ID
      order by EXP_CALC_NET desc;

    expiry_ctrl_tuple        expiry_ctrl%rowtype;

    cursor expiry_ctrl_amount(part_imputation_id number)
    is
      select sum(exp.EXP_AMOUNT_LC) EXP_AMOUNT_LC
           , sum(exp.EXP_AMOUNT_FC) EXP_AMOUNT_FC
        from ACI_EXPIRY exp
           , ACI_PART_IMPUTATION PAR
       where exp.ACI_PART_IMPUTATION_ID = PAR.ACI_PART_IMPUTATION_ID
         and PAR.ACI_PART_IMPUTATION_ID = part_imputation_id
         and exp.EXP_CALC_NET = 1;

    expiry_ctrl_amount_tuple expiry_ctrl_amount%rowtype;
    is_expiry                number(1);
    val_sign                 number(1);
    amount_lc                ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    amount_fc                ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    amount_eur               ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    type_catalogue           varchar2(10);
  begin
    -- controle s'il existe des échéances
    select sign(count(*) )
      into is_expiry
      from aci_expiry
     where aci_part_imputation_id = part_imputation_id;

    -- si on a pas d'échéances, on les crée d'après les condition de payment
    if is_expiry = 0 then
      -- génération des échéances
      ACT_EXPIRY_MANAGEMENT.GenerateExpiriesACI(part_imputation_id);
    -- expiry déjà existantes
    else
      -- recherche des montants sur l'imputation primaire
      select imf_amount_lc_c + imf_amount_lc_d
           , imf_amount_fc_c + imf_amount_fc_d
           , imf_amount_eur_c + imf_amount_eur_d
        into amount_lc
           , amount_fc
           , amount_eur
        from ACI_FINANCIAL_IMPUTATION
       where ACI_PART_IMPUTATION_ID = part_imputation_id
         and IMF_PRIMARY = 1;

      -- recherche du signe des montants
      -- !!! pas de lien entre les tables ACJ et ACI_FINANCIAL_IMPUTATION, on utilise le produit cartésien.
      select case
               when PAC_CUSTOM_PARTNER_ID is not null
               and c_type_catalogue in('5', '6')
               and IMF_AMOUNT_LC_C > 0 then -1
               when PAC_CUSTOM_PARTNER_ID is not null
               and c_type_catalogue in('2')
               and IMF_AMOUNT_LC_C > 0 then -1
               when PAC_SUPPLIER_PARTNER_ID is not null
               and c_type_catalogue in('5', '6')
               and IMF_AMOUNT_LC_D > 0 then -1
               when PAC_SUPPLIER_PARTNER_ID is not null
               and c_type_catalogue in('2')
               and IMF_AMOUNT_LC_D > 0 then -1
               else 1
             end
           , c_type_catalogue
        into val_sign
           , type_catalogue
        from ACJ_CATALOGUE_DOCUMENT
           , ACJ_JOB_TYPE_S_CATALOGUE
           , ACI_FINANCIAL_IMPUTATION
           , ACI_PART_IMPUTATION
           , ACI_DOCUMENT
       where ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID = ACI_DOCUMENT.ACJ_JOB_TYPE_S_CATALOGUE_ID
         and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID
         and ACI_FINANCIAL_IMPUTATION.ACI_DOCUMENT_ID = ACI_PART_IMPUTATION.ACI_DOCUMENT_ID
         and ACI_DOCUMENT.ACI_DOCUMENT_ID = ACI_PART_IMPUTATION.ACI_DOCUMENT_ID
         and ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID = part_imputation_id
         and ACI_FINANCIAL_IMPUTATION.IMF_PRIMARY = 1;

      open expiry_ctrl(part_imputation_id);

      fetch expiry_ctrl
       into expiry_ctrl_tuple;

      while expiry_ctrl%found loop
        -- controle que les échéances aient le même signe ou sinon à 0
        if    (     (val_sign <> 0)
               and (sign(expiry_ctrl_tuple.EXP_AMOUNT_LC) + val_sign) = 0)
           or (     (val_sign = 0)
               and (sign(expiry_ctrl_tuple.EXP_AMOUNT_LC) + val_sign) <> 0) then
          fail_reason  := '320';

          close expiry_ctrl;

          return 0;
        end if;

        fetch expiry_ctrl
         into expiry_ctrl_tuple;
      end loop;

      close expiry_ctrl;

      open expiry_ctrl_amount(part_imputation_id);

      fetch expiry_ctrl_amount
       into expiry_ctrl_amount_tuple;

      if expiry_ctrl_amount%found then
        -- controle que les échéances aient le même signe ou sinon à 0
        if    (abs(expiry_ctrl_amount_tuple.EXP_AMOUNT_LC) <> abs(amount_lc) )
           or (abs(expiry_ctrl_amount_tuple.EXP_AMOUNT_FC) <> abs(amount_fc) ) then
          fail_reason  := '330';

          close expiry_ctrl_amount;

          return 0;
        end if;
      end if;

      close expiry_ctrl_amount;
    end if;

    return 1;
  end Expiry_Control;

  /**
  * fonction Part_Imputation_Control
  * Description
  *    Controle des imputations partenaire du document
  * @author FP
  * @lastUpdate
  * @private
  * @param document_id  : id du document interface(ACI_DOCUMENT_ID) à contrôler
  * @param financial_year_id : id de l'exercice comptable du document
  * @param job_type_s_catalogue_id : id de la transaction du modèle
  * @param aTypeCatalogue : type de catalogue document
  * @param customer     : flag   1 : client  0 : fournisseur
  * @param person_id    : id du client-fournisseur
  * @param fail_reason out : valeur de descode c_fail_reason en cas d'erreur de contrôle
  * @return 1 si control OK sinon à 0
  */
  function Part_Imputation_Control(
    document_id             in     number
  , financial_year_id       in     number
  , job_type_s_catalogue_id in     number
  , aTypeCatalogue          in     varchar2
  , customer                in out number
  , person_id               in out number
  , fail_reason             in out number
  )
    return signtype
  is
    cursor crPartImputation(document_id number)
    is
      select *
        from ACI_PART_IMPUTATION
       where ACI_DOCUMENT_ID = document_id;

    tplPartImputation      crPartImputation%rowtype;
    custom_id              PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type;
    supplier_id            PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    address_id             PAC_ADDRESS.PAC_ADDRESS_ID%type;
    financial_reference_id PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%type;
    financial_ref_status   PAC_FINANCIAL_REFERENCE.C_PARTNER_STATUS%type;
    base_currency_id       ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    foreign_currency_id    ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    payment_condition_id   PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;
    payment_condition_kind PAC_PAYMENT_CONDITION.C_PAYMENT_CONDITION_KIND%type;
    part_id                ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type;
    doc_ctrl               ACJ_SUB_SET_CAT.sub_doc_number_ctrl%type;
    type_cumul             ACJ_SUB_SET_CAT.c_type_cumul%type;
    fin_acc_s_payment_id   ACI_PART_IMPUTATION.ACS_FIN_ACC_S_PAYMENT_ID%type;
    tot_pay_lc             ACI_DET_PAYMENT.DET_PAIED_LC%type;
    tot_pay_fc             ACI_DET_PAYMENT.DET_PAIED_FC%type;
    tot_exp_lc             ACI_EXPIRY.EXP_AMOUNT_LC%type;
    tot_exp_fc             ACI_EXPIRY.EXP_AMOUNT_FC%type;
    num_det_pay            number;
    vMbrStatus             PAC_SUPPLIER_PARTNER.C_PARTNER_STATUS%type;
    vGrpStatus             PAC_SUPPLIER_PARTNER.C_PARTNER_STATUS%type;
    vPartnerCategory       PAC_SUPPLIER_PARTNER.C_PARTNER_CATEGORY%type;
    vDIC_BLOCKED_REASON_ID DIC_BLOCKED_REASON.DIC_BLOCKED_REASON_ID%type;
    vFreAccountNumber      ACI_PART_IMPUTATION.FRE_ACCOUNT_NUMBER%type;
    vNumRef                ACI_PART_IMPUTATION.PAR_REF_BVR%type;
    vNumAdh                varchar2(2000);
    vAmount                varchar2(2000);
    vClearing              varchar2(2000);
    vNumAcc                varchar2(2000);
    ise_mode               number;
  begin
    customer  := 0;

    -- ouverture du curseur sur les imputations partenaire
    open crPartImputation(document_id);

    fetch crPartImputation
     into tplPartImputation;

    while crPartImputation%found loop
      -- recherche de l'id du client
      -- Recherche d'après la clef 1
      if     tplPartImputation.per_cust_key1 is not null
         and (    tplPartImputation.pac_custom_partner_id is null
              and tplPartImputation.pac_address_id is null) then
        select max(PAC_CUSTOM_PARTNER_ID)
             , max(PAC_ADDRESS_ID)
          into custom_id
             , address_id
          from PAC_CUSTOM_PARTNER
             , PAC_PERSON
         where PAC_PERSON_ID = PAC_CUSTOM_PARTNER_ID
           and (   PER_KEY1 = tplPartImputation.per_cust_key1
                or (    PER_KEY1 is null
                    and tplPartImputation.per_cust_key1 is null)
               );

        if custom_id is not null then
          update ACI_PART_IMPUTATION
             set PAC_CUSTOM_PARTNER_ID = custom_id
               , PAC_ADDRESS_ID = address_id
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        else
          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          fail_reason  := '210';

          close crPartImputation;

          return 0;
        end if;

        customer  := 1;
      -- Recherche d'après la clef 2
      elsif     tplPartImputation.per_cust_key2 is not null
            and (    tplPartImputation.pac_custom_partner_id is null
                 and tplPartImputation.pac_address_id is null) then
        select max(PAC_CUSTOM_PARTNER_ID)
             , max(PAC_ADDRESS_ID)
          into custom_id
             , address_id
          from PAC_CUSTOM_PARTNER
             , PAC_PERSON
         where PAC_PERSON_ID = PAC_CUSTOM_PARTNER_ID
           and (   PER_KEY2 = tplPartImputation.per_cust_key2
                or (    PER_KEY2 is null
                    and tplPartImputation.per_cust_key2 is null)
               );

        if custom_id is not null then
          update ACI_PART_IMPUTATION
             set PAC_CUSTOM_PARTNER_ID = custom_id
               , PAC_ADDRESS_ID = address_id
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        else
          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          fail_reason  := '210';

          close crPartImputation;

          return 0;
        end if;

        customer  := 1;
      -- Recherche de l'adresse
      elsif     tplPartImputation.pac_custom_partner_id is not null
            and tplPartImputation.pac_address_id is null then
        select max(PAC_ADDRESS_ID)
          into address_id
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = tplPartImputation.pac_custom_partner_id;

        -- Dans le cas ou l'on aurait rien trouvé, une recherche de l'adresse se fait plus loin
        if address_id is not null then
          update ACI_PART_IMPUTATION
             set PAC_ADDRESS_ID = address_id
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        end if;

        customer  := 1;
      end if;

      -- maj de l'id du fournisseur
      -- Recherche d'après la clef 1
      if     tplPartImputation.per_supp_key1 is not null
         and (    tplPartImputation.pac_supplier_partner_id is null
              and tplPartImputation.pac_address_id is null) then
        select max(PAC_SUPPLIER_PARTNER_ID)
             , max(PAC_ADDRESS_ID)
          into supplier_id
             , address_id
          from PAC_SUPPLIER_PARTNER
             , PAC_PERSON
         where PAC_PERSON_ID = PAC_SUPPLIER_PARTNER_ID
           and (   PER_KEY1 = tplPartImputation.per_supp_key1
                or (    PER_KEY1 is null
                    and tplPartImputation.per_supp_key1 is null)
               );

        if supplier_id is not null then
          update ACI_PART_IMPUTATION
             set PAC_SUPPLIER_PARTNER_ID = supplier_id
               , PAC_ADDRESS_ID = address_id
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        else
          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          fail_reason  := '220';

          close crPartImputation;

          return 0;
        end if;
      -- Recherche d'après la clef 2
      elsif     tplPartImputation.per_supp_key2 is not null
            and (    tplPartImputation.pac_supplier_partner_id is null
                 and tplPartImputation.pac_address_id is null) then
        select max(PAC_SUPPLIER_PARTNER_ID)
             , max(PAC_ADDRESS_ID)
          into supplier_id
             , address_id
          from PAC_SUPPLIER_PARTNER
             , PAC_PERSON
         where PAC_PERSON_ID = PAC_SUPPLIER_PARTNER_ID
           and (   PER_KEY2 = tplPartImputation.per_supp_key2
                or (    PER_KEY2 is null
                    and tplPartImputation.per_supp_key2 is null)
               );

        if supplier_id is not null then
          update ACI_PART_IMPUTATION
             set PAC_SUPPLIER_PARTNER_ID = supplier_id
               , PAC_ADDRESS_ID = address_id
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        else
          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          fail_reason  := '220';

          close crPartImputation;

          return 0;
        end if;
      -- Recherche de l'adresse
      elsif     tplPartImputation.pac_supplier_partner_id is not null
            and tplPartImputation.pac_address_id is null then
        select max(PAC_ADDRESS_ID)
          into address_id
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = tplPartImputation.pac_supplier_partner_id;

        -- Dans le cas ou l'on aurait rien trouvé, une recherche de l'adresse se fait plus loin
        if address_id is not null then
          update ACI_PART_IMPUTATION
             set PAC_ADDRESS_ID = address_id
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        end if;
      end if;

      -- si aucun tiers n'est défini ou trouvé : erreur
      if     tplPartImputation.pac_supplier_partner_id is null
         and tplPartImputation.pac_custom_partner_id is null
         and custom_id is null
         and supplier_id is null then
        -- Pas de tiers
        fail_reason  := '280';

        close crPartImputation;

        return 0;
      end if;

      -- controle si on a affaire à un client ou un fournisseur
      select sign(nvl(PAC_CUSTOM_PARTNER_ID, 0) )
        into customer
        from ACI_PART_IMPUTATION
       where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;

      -- contrôle le status du partenaire (Catégorie partenaire -> 2 = Groupe , 3 = Membre de groupe)
      if customer = 1 then
        select max(C_PARTNER_STATUS)
             , max(C_PARTNER_CATEGORY)
          into vMbrStatus
             , vPartnerCategory
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = nvl(tplPartImputation.pac_custom_partner_id, custom_id);

        if vPartnerCategory = '3' then   -- membre de groupe => recherche du statut du groupe (tête de groupe)
          select max(C_PARTNER_STATUS)
            into vGrpStatus
            from PAC_CUSTOM_PARTNER
           where ACS_AUXILIARY_ACCOUNT_ID =
                                (select ACS_AUXILIARY_ACCOUNT_ID
                                   from PAC_CUSTOM_PARTNER
                                  where PAC_CUSTOM_PARTNER_ID = nvl(tplPartImputation.pac_custom_partner_id, custom_id) )
             and C_PARTNER_CATEGORY = '2';
        end if;
      else
        select max(C_PARTNER_STATUS)
             , max(C_PARTNER_CATEGORY)
          into vMbrStatus
             , vPartnerCategory
          from PAC_SUPPLIER_PARTNER
         where PAC_SUPPLIER_PARTNER_ID = nvl(tplPartImputation.pac_supplier_partner_id, supplier_id);

        if vPartnerCategory = '3' then   -- membre de groupe => recherche du statut du groupe (tête de groupe)
          select max(C_PARTNER_STATUS)
            into vGrpStatus
            from PAC_SUPPLIER_PARTNER
           where ACS_AUXILIARY_ACCOUNT_ID =
                          (select ACS_AUXILIARY_ACCOUNT_ID
                             from PAC_SUPPLIER_PARTNER
                            where PAC_SUPPLIER_PARTNER_ID = nvl(tplPartImputation.pac_supplier_partner_id, supplier_id) )
             and C_PARTNER_CATEGORY = '2';
        end if;
      end if;

      -- Le statut du tiers doit être différent de inactif (C_PARTNER_STATUS <> '0')
      -- Pour une catégorie de tiers membre de groupe (C_PARTNER_CATEGORY = '3')
      -- le groupe (tête de groupe) doit avoir un statut différent de inactif (C_PARTNER_STATUS <> '0')
      if    (vMbrStatus = '0')
         or (     (vPartnerCategory = '3')
             and (vGrpStatus = '0') ) then
        fail_reason  := '227';

        close crPartImputation;

        return 0;
      end if;

      -- maj de l'id de l'adresse
        -- controle si on a pas déjà l'id de l'adresse
      select PAC_ADDRESS_ID
           , nvl(PAC_SUPPLIER_PARTNER_ID, PAC_CUSTOM_PARTNER_ID)
        into address_id
           , person_id
        from ACI_PART_IMPUTATION
       where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;

      if address_id is null then
        -- recherche si on a une adresse principale dans la table des adresses
        select max(pac_address_id)
          into address_id
          from PAC_ADDRESS
         where PAC_PERSON_ID = person_id
           and ADD_PRINCIPAL = 1;

        -- si on a pas d'adresse principale, on prend l'adresse par défaut d'après le dictionnaire
        if address_id is null then
          select max(pac_address_id)
            into address_id
            from PAC_ADDRESS
               , DIC_ADDRESS_TYPE
           where PAC_PERSON_ID = person_id
             and DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID = PAC_ADDRESS.DIC_ADDRESS_TYPE_ID
             and DIC_ADDRESS_TYPE.DAD_DEFAULT = 1;
        end if;

        update ACI_PART_IMPUTATION
           set PAC_ADDRESS_ID = address_id
         where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
      end if;

      --Intégration depuis ACI_XML_FUNCTIONS, la zone PAR_BVR_CODE est remplie à la lecture du document XML
      vFreAccountNumber  := tplPartImputation.FRE_ACCOUNT_NUMBER;

      if tplPartImputation.PAR_BVR_CODE is not null then
        if ACS_function.DecodeSBVRLine(tplPartImputation.PAR_BVR_CODE, vNumRef, vNumAdh, vAmount, vClearing, vNumAcc) >
                                                                                                                      0 then
          if tplPartImputation.PAR_REF_BVR is null then
            update ACI_PART_IMPUTATION
               set PAR_REF_BVR = vNumRef
             where ACI_PART_IMPUTATION_ID = tplPartImputation.ACI_PART_IMPUTATION_ID;
          end if;

          vFreAccountNumber  := nvl(tplPartImputation.FRE_ACCOUNT_NUMBER, vNumAdh);

          if     tplPartImputation.FRE_ACCOUNT_NUMBER is null
             and vNumAdh is not null then
            update ACI_PART_IMPUTATION
               set FRE_ACCOUNT_NUMBER = vNumAdh
             where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
          end if;
        end if;
      end if;

      -- maj de l'id de la référence financière
      if     vFreAccountNumber is not null
         and tplPartImputation.pac_financial_reference_id is null then
        if customer = 1 then
          select max(PAC_FINANCIAL_REFERENCE_ID)
            into financial_reference_id
            from PAC_FINANCIAL_REFERENCE
           where FRE_ACCOUNT_NUMBER = vFreAccountNumber
             and PAC_CUSTOM_PARTNER_ID = person_id;

          if financial_reference_id is not null then
            update ACI_PART_IMPUTATION
               set PAC_FINANCIAL_REFERENCE_ID = financial_reference_id
             where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
          end if;
        else
          select max(PAC_FINANCIAL_REFERENCE_ID)
            into financial_reference_id
            from PAC_FINANCIAL_REFERENCE
           where FRE_ACCOUNT_NUMBER = vFreAccountNumber
             and PAC_SUPPLIER_PARTNER_ID = person_id;

          if financial_reference_id is not null then
            update ACI_PART_IMPUTATION
               set PAC_FINANCIAL_REFERENCE_ID = financial_reference_id
             where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
          end if;
        end if;

        -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
        if financial_reference_id is null then
          fail_reason  := '230';

          close crPartImputation;

          return 0;
        end if;
      elsif tplPartImputation.pac_financial_reference_id is null then
        -- recherche automatique de la référence financière pour les fournisseurs
        if customer = 0 then
          -- référence par défaut du fournisseur
          select max(PAC_FINANCIAL_REFERENCE_ID)
            into financial_reference_id
            from PAC_FINANCIAL_REFERENCE
           where PAC_SUPPLIER_PARTNER_ID = person_id
             and FRE_DEFAULT = 1
             and not C_TYPE_REFERENCE = '3'
             and not exists(
                         select EXP_REF_BVR
                           from ACI_EXPIRY
                          where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id
                            and EXP_REF_BVR is null);

          if financial_reference_id is not null then
            update ACI_PART_IMPUTATION
               set PAC_FINANCIAL_REFERENCE_ID = financial_reference_id
             where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
          end if;
        end if;
      elsif tplPartImputation.pac_financial_reference_id is not null then
        financial_reference_id  := tplPartImputation.pac_financial_reference_id;
      end if;

      --Vérifier la validité de la référence financière trouvée
      -- et la signaler en cas de non validité
      if financial_reference_id is not null then
        select max(C_PARTNER_STATUS)
          into financial_ref_status
          from PAC_FINANCIAL_REFERENCE
         where PAC_FINANCIAL_REFERENCE_ID = financial_reference_id;

        if financial_ref_status = '0' then
          fail_reason  := '272';

          close crPartImputation;

          return 0;
        end if;
      end if;

      -- maj des dictionnaire "fournisseurs"
      update ACI_PART_IMPUTATION
         set (DIC_PRIORITY_PAYMENT_ID, DIC_CENTER_PAYMENT_ID, DIC_LEVEL_PRIORITY_ID) =
               (select nvl(ACI_PART_IMPUTATION.DIC_PRIORITY_PAYMENT_ID, PAC_SUPPLIER_PARTNER.DIC_PRIORITY_PAYMENT_ID)
                     , nvl(ACI_PART_IMPUTATION.DIC_CENTER_PAYMENT_ID, PAC_SUPPLIER_PARTNER.DIC_CENTER_PAYMENT_ID)
                     , nvl(ACI_PART_IMPUTATION.DIC_LEVEL_PRIORITY_ID, PAC_SUPPLIER_PARTNER.DIC_LEVEL_PRIORITY_ID)
                  from PAC_SUPPLIER_PARTNER
                     , ACI_PART_IMPUTATION
                 where PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID = person_id
                   and ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id)
       where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;

      -- maj de l'id de la monnaie de base
      if     tplPartImputation.currency1 is not null
         and tplPartImputation.acs_financial_currency_id is null then
        select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
          into base_currency_id
          from ACS_FINANCIAL_CURRENCY FIN
             , PCS.PC_CURR CUR
         where FIN.PC_CURR_ID = CUR.PC_CURR_ID
           and CUR.CURRENCY = tplPartImputation.currency1;

        if base_currency_id is not null then
          update ACI_PART_IMPUTATION
             set ACS_FINANCIAL_CURRENCY_ID = base_currency_id
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        else
          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          fail_reason  := '240';

          close crPartImputation;

          return 0;
        end if;
      end if;

      -- maj de l'id de la monnaie étrangère
      if     tplPartImputation.currency2 is not null
         and tplPartImputation.acs_acs_financial_currency_id is null then
        select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
          into foreign_currency_id
          from ACS_FINANCIAL_CURRENCY FIN
             , PCS.PC_CURR CUR
         where FIN.PC_CURR_ID = CUR.PC_CURR_ID
           and CUR.CURRENCY = tplPartImputation.currency2;

        if foreign_currency_id is not null then
          update ACI_PART_IMPUTATION
             set ACS_ACS_FINANCIAL_CURRENCY_ID = foreign_currency_id
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        else
          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          fail_reason  := '250';

          close crPartImputation;

          return 0;
        end if;
      end if;

      --maj du dictionnaire de la raison de blockage
      if tplPartImputation.DIC_BLOCKED_REASON_ID is not null then
        select max(DIC_BLOCKED_REASON_ID)
          into vDIC_BLOCKED_REASON_ID
          from DIC_BLOCKED_REASON
         where DIC_BLOCKED_REASON_ID = tplPartImputation.DIC_BLOCKED_REASON_ID;

        if vDIC_BLOCKED_REASON_ID is null then
          fail_reason  := '255';

          close crPartImputation;

          return 0;
        end if;
      end if;

      -- maj de l'id des conditions de payement
      if tplPartImputation.pac_payment_condition_id is not null then
        select C_PAYMENT_CONDITION_KIND
          into payment_condition_kind
          from PAC_PAYMENT_CONDITION
         where PAC_PAYMENT_CONDITION_ID = tplPartImputation.pac_payment_condition_id;

        if payment_condition_kind <> '01' then
          fail_reason  := '261';

          close crPartImputation;

          return 0;
        end if;
      elsif     tplPartImputation.pco_descr is not null
            and tplPartImputation.pac_payment_condition_id is null then
        select   max(PAC_PAYMENT_CONDITION_ID)
               , max(C_PAYMENT_CONDITION_KIND)
            into payment_condition_id
               , payment_condition_kind
            from PAC_PAYMENT_CONDITION
           where PCO_DESCR = tplPartImputation.pco_descr
        order by C_PAYMENT_CONDITION_KIND asc
               , PAC_PAYMENT_CONDITION_ID desc;

        if payment_condition_id is not null then
          if payment_condition_kind = '01' then
            update ACI_PART_IMPUTATION
               set PAC_PAYMENT_CONDITION_ID = payment_condition_id
             where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
          else
            fail_reason  := '261';

            close crPartImputation;

            return 0;
          end if;
        else
          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          fail_reason  := '260';

          close crPartImputation;

          return 0;
        end if;
      -- recherche au niveau fournisseur-client
      elsif     tplPartImputation.pac_payment_condition_id is null
            and aTypeCatalogue in('2', '5', '6') then
        if customer = 1 then
          update ACI_PART_IMPUTATION
             set PAC_PAYMENT_CONDITION_ID = (select max(PAC_PAYMENT_CONDITION_ID)
                                               from PAC_CUSTOM_PARTNER
                                              where PAC_CUSTOM_PARTNER_ID = person_id)
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        else
          update ACI_PART_IMPUTATION
             set PAC_PAYMENT_CONDITION_ID = (select max(PAC_PAYMENT_CONDITION_ID)
                                               from PAC_SUPPLIER_PARTNER
                                              where PAC_SUPPLIER_PARTNER_ID = person_id)
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        end if;
      end if;

      -- maj de l'id de la méthode de paiement
      if     tplPartImputation.des_description_summary is not null
         and tplPartImputation.acs_fin_acc_s_payment_id is null then
        select min(SPAY.ACS_FIN_ACC_S_PAYMENT_ID)
          into fin_acc_s_payment_id
          from ACS_DESCRIPTION DES
             , ACS_FIN_ACC_S_PAYMENT SPAY
             , ACS_PAYMENT_METHOD MET
         where DES.DES_DESCRIPTION_SUMMARY = tplPartImputation.des_description_summary
           and MET.ACS_PAYMENT_METHOD_ID = DES.ACS_PAYMENT_METHOD_ID
           and DES.ACS_PAYMENT_METHOD_ID = SPAY.ACS_PAYMENT_METHOD_ID;

        if fin_acc_s_payment_id is not null then
          update ACI_PART_IMPUTATION
             set ACS_FIN_ACC_S_PAYMENT_ID = fin_acc_s_payment_id
           where ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;
        end if;
      end if;

      -- Controle du numéro de document partenaire
      if customer = 1 then
        -- Controle si on doit contrôler le numéro de document partenaire
        select max(c.sub_doc_number_ctrl)
             , max(c.c_type_cumul)
             , decode(max(a.aci_conversion_id), null, 0, 1)
          into doc_ctrl
             , type_cumul
             , ise_mode
          from aci_document a
             , acj_job_type_s_catalogue b
             , acj_sub_set_cat c
             , acj_catalogue_document d
         where a.acj_job_type_s_catalogue_id = b.acj_job_type_s_catalogue_id
           and c.acj_catalogue_document_id = b.acj_catalogue_document_id
           and a.aci_document_id = document_id
           and d.acj_catalogue_document_id = b.acj_catalogue_document_id
           and c.c_sub_set = 'REC';

        if doc_ctrl = 1 and tplPartImputation.par_document is not null then
          select max(act_part_imputation_id)
            into part_id
            from acj_sub_set_cat c
               , act_document b
               , act_part_imputation a
           where a.pac_custom_partner_id = person_id
             and b.act_document_id = a.act_document_id
             and b.acs_financial_year_id = financial_year_id
             and c.acj_catalogue_document_id = b.acj_catalogue_document_id
             and c.c_type_cumul = type_cumul
             and c.c_sub_set = 'REC'
             and a.par_document = tplPartImputation.par_document;

          if part_id is null and ise_mode = 1 then
            -- Test si document vient d'ISAG
            select max(doc.aci_document_id)
              into ise_mode
              from aci_document doc
                 , aci_conversion_type typ
                 , aci_conversion cnv
             where typ.aci_conversion_type_id = cnv.aci_conversion_type_id
               and typ.c_source_type = '50'
               and typ.cty_descr = 'ACT_ISAG'
               and doc.aci_conversion_id = cnv.aci_conversion_id
               and doc.aci_document_id = document_id;

            if ise_mode = 1 then
              -- Test si numéro document existe déjà en ACI
              select max(aci_part_imputation_id)
                into part_id
                from acj_job_type_s_catalogue d
                   , acj_sub_set_cat c
                   , aci_document b
                   , aci_part_imputation a
                   , aci_conversion_type typ
                   , aci_conversion cnv
               where a.pac_custom_partner_id = person_id
                 and b.aci_document_id = a.aci_document_id
                 and b.acs_financial_year_id = financial_year_id
                 and c.acj_catalogue_document_id = c.acj_catalogue_document_id
                 and d.acj_job_type_s_catalogue_id = b.acj_job_type_s_catalogue_id
                 and c.c_type_cumul = type_cumul
                 and c.c_sub_set = 'REC'
                 and a.par_document = tplPartImputation.par_document
                 and typ.aci_conversion_type_id = cnv.aci_conversion_type_id
                 and typ.c_source_type = '50'
                 and typ.cty_descr = 'ACT_ISAG'
                 and b.aci_conversion_id = cnv.aci_conversion_id
                 and b.aci_document_id <> document_id;
            end if;
          end if;

          if part_id is not null then
            -- Si un enregistrement a été trouvé, c'est que le numéro de document
            -- qu'on veut insérer existe déjà pour le tiers
            fail_reason  := '290';

            close crPartImputation;

            return 0;
          end if;
        end if;
      elsif customer = 0 then
        -- Controle si on doit contrôler le numéro de document partenaire
        select max(c.sub_doc_number_ctrl)
             , max(c.c_type_cumul)
             , decode(max(a.aci_conversion_id), null, 0, 1)
          into doc_ctrl
             , type_cumul
             , ise_mode
          from aci_document a
             , acj_job_type_s_catalogue b
             , acj_sub_set_cat c
             , acj_catalogue_document d
         where a.acj_job_type_s_catalogue_id = b.acj_job_type_s_catalogue_id
           and c.acj_catalogue_document_id = b.acj_catalogue_document_id
           and a.aci_document_id = document_id
           and d.acj_catalogue_document_id = b.acj_catalogue_document_id
           and c.c_sub_set = 'PAY';

        if doc_ctrl = 1 and tplPartImputation.par_document is not null then
          select max(act_part_imputation_id)
            into part_id
            from acj_sub_set_cat c
               , act_document b
               , act_part_imputation a
           where a.pac_supplier_partner_id = person_id
             and b.act_document_id = a.act_document_id
             and b.acs_financial_year_id = financial_year_id
             and c.acj_catalogue_document_id = b.acj_catalogue_document_id
             and c.c_type_cumul = type_cumul
             and c.c_sub_set = 'PAY'
             and a.par_document = tplPartImputation.par_document;

          if part_id is null and ise_mode = 1 then
            -- Test si document vient d'ISAG
            select max(doc.aci_document_id)
              into ise_mode
              from aci_document doc
                 , aci_conversion_type typ
                 , aci_conversion cnv
             where typ.aci_conversion_type_id = cnv.aci_conversion_type_id
               and typ.c_source_type = '50'
               and typ.cty_descr = 'ACT_ISAG'
               and doc.aci_conversion_id = cnv.aci_conversion_id
               and doc.aci_document_id = document_id;

            if ise_mode = 1 then
              -- Test si numéro document existe déjà en ACI
              select max(aci_part_imputation_id)
                into part_id
                from acj_job_type_s_catalogue d
                   , acj_sub_set_cat c
                   , aci_document b
                   , aci_part_imputation a
                   , aci_conversion_type typ
                   , aci_conversion cnv
               where a.pac_supplier_partner_id = person_id
                 and b.aci_document_id = a.aci_document_id
                 and b.acs_financial_year_id = financial_year_id
                 and c.acj_catalogue_document_id = c.acj_catalogue_document_id
                 and d.acj_job_type_s_catalogue_id = b.acj_job_type_s_catalogue_id
                 and c.c_type_cumul = type_cumul
                 and c.c_sub_set = 'PAY'
                 and a.par_document = tplPartImputation.par_document
                 and typ.aci_conversion_type_id = cnv.aci_conversion_type_id
                 and typ.c_source_type = '50'
                 and typ.cty_descr = 'ACT_ISAG'
                 and b.aci_conversion_id = cnv.aci_conversion_id
                 and b.aci_document_id <> document_id;
            end if;
          end if;

          if part_id is not null then
            -- Si un enregistrement a été trouvé, c'est que le numéro de document
            -- qu'on veut insérer existe déjà pour le tiers
            fail_reason  := '290';

            close crPartImputation;

            return 0;
          end if;
        end if;
      end if;

      -- control des échéances
      if aTypeCatalogue in('2', '5', '6') then
        if Expiry_Control(tplPartImputation.aci_part_imputation_id, fail_reason) <> 1 then
          close crPartImputation;

          return 0;
        end if;

        if aTypeCatalogue not in('5', '6') then
          if Expiry_Bvr_Control(tplPartImputation.aci_part_imputation_id, person_id, fail_reason) <> 1 then
            close crPartImputation;

            return 0;
          end if;
        end if;

        -- contrôle si montant paiement <= montant facture dans les limites de la déduction autorisée
        -- ce contrôle prend en compte la gestion de la monnaie étrangère
        select sum(nvl(DET.DET_PAIED_LC, 0) +
                   nvl(DET.DET_DISCOUNT_LC, 0) +
                   nvl(DET.DET_DEDUCTION_LC, 0) +
                   nvl(DET.DET_DIFF_EXCHANGE, 0)
                  )
             , sum(nvl(DET.DET_PAIED_FC, 0) + nvl(DET.DET_DISCOUNT_FC, 0) + nvl(DET.DET_DEDUCTION_FC, 0) )
             , count(*)
          into tot_pay_lc   -- Montant paiement MB
             , tot_pay_fc   -- Montant paiement ME
             , num_det_pay
          from ACI_DET_PAYMENT DET
         where DET.ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id;

        if num_det_pay > 0 then
          select sum(nvl(exp.EXP_AMOUNT_LC, 0) )
               , sum(nvl(exp.EXP_AMOUNT_FC, 0) )
            into tot_exp_lc   -- Montant échéance MB
               , tot_exp_fc   -- Montant échéance ME
            from ACI_EXPIRY exp
               , ACI_PART_IMPUTATION PART
           where PART.ACI_PART_IMPUTATION_ID = tplPartImputation.aci_part_imputation_id
             and PART.ACI_PART_IMPUTATION_ID = exp.ACI_PART_IMPUTATION_ID
             and exp.EXP_CALC_NET = 1
             and exp.C_STATUS_EXPIRY = '0';

          -- Montant _LC détail paiement > montant _LC_échéance
          if (tot_pay_lc > tot_exp_lc) then
            fail_reason  := '727';

            close crPartImputation;

            return 0;
          elsif     (tplPartImputation.ACS_FINANCIAL_CURRENCY_ID <> tplPartImputation.ACS_ACS_FINANCIAL_CURRENCY_ID)
                and (tot_pay_fc > tot_exp_fc) then
            -- Monnaie ME <> MB : les montants en ME sont incorrects (paiement supérieur aux échéances)
            fail_reason  := '730';

            close crPartImputation;

            return 0;
          end if;
        end if;

        -- contrôle des détails paiements (paiements directs)
        if Det_Payment_Control(tplPartImputation.aci_part_imputation_id
                             , aTypeCatalogue
                             , job_type_s_catalogue_id
                             , tplPartImputation.acs_financial_currency_id
                             , person_id
                             , fail_reason
                              ) <> 1 then
          close crPartImputation;

          return 0;
        end if;
      elsif aTypeCatalogue = '3' then
        -- contrôle des détails paiements
        if Det_Payment_Control(tplPartImputation.aci_part_imputation_id
                             , aTypeCatalogue
                             , job_type_s_catalogue_id
                             , tplPartImputation.acs_financial_currency_id
                             , person_id
                             , fail_reason
                              ) <> 1 then
          close crPartImputation;

          return 0;
        end if;
      elsif aTypeCatalogue = '9' then
        -- contrôle des détails paiements
        if Det_Payment_Control(tplPartImputation.aci_part_imputation_id
                             , aTypeCatalogue
                             , job_type_s_catalogue_id
                             , tplPartImputation.acs_financial_currency_id
                             , person_id
                             , fail_reason
                              ) <> 1 then
          close crPartImputation;

          return 0;
        end if;
      elsif aTypeCatalogue = '8' then
        -- contrôle des relances
        if Reminder_Control(tplPartImputation.aci_part_imputation_id, aTypeCatalogue, person_id, fail_reason) <> 1 then
          close crPartImputation;

          return 0;
        end if;
      end if;

      -- imputation partenaire suivante
      fetch crPartImputation
       into tplPartImputation;
    end loop;

    close crPartImputation;

    return 1;
  end Part_Imputation_Control;

  /**
  * fonction Header_Control
  * Description
  *   Control de l'entête du document
  * @author FP
  * @lastUpdate
  * @private
  * @param document_id  : id du document interface(ACI_DOCUMENT_ID) à contrôler
  * @param financial_year_id : id de l'exercice comptable du document
  * @param job_type_s_catalogue_id : id de la transaction du modèle
  * @param job_typ_s_cat_pmt_id : id de la transaction du modèle pour le paiement direct
  * @param type_catalogue : type de catalogue document
  * @param
  * @param fail_reason out : valeur de descode c_fail_reason en cas d'erreur de contrôle
  * @return 1 si control OK sinon à 0
  */
  function Header_Control(
    document_id             in     number
  , financial_year_id       in out number
  , job_type_s_catalogue_id in out number
  , job_type_s_cat_pmt_id   in out number
  , type_catalogue          in out varchar2
  , fail_reason             in out number
  )
    return signtype
  is
    cursor document(document_id number)
    is
      select ACI_DOCUMENT.*
        from ACI_DOCUMENT
       where ACI_DOCUMENT.ACI_DOCUMENT_ID = document_id;

    document_tuple            document%rowtype;
    job_type_id               ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type;
    job_type_pmt_id           ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type;
    financial_account_id      ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    pmt_account_id            ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    financial_currency_id     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vat_currency_id           ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    transaction_date          date;
    type_catalogue_pmt        ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
    imput_id                  aci_financial_imputation.aci_financial_imputation_id%type;
    nb_imputation             integer;
    amount_imp_prim_lc        aci_financial_imputation.imf_amount_lc_d%type;
    amount_imp_prim_fc        aci_financial_imputation.imf_amount_fc_d%type;
    test_num                  number;
    exist_detpay              boolean;
    vCAT_COVER_INFORMATION    ACJ_CATALOGUE_DOCUMENT.CAT_COVER_INFORMATION%type;
    vACS_FIN_ACC_S_PAYMENT_ID ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID%type;
    vPMM_COVER_GENERATION     ACS_FIN_ACC_S_PAYMENT.PMM_COVER_GENERATION%type;
    vFIN_PORTFOLIO            ACS_FINANCIAL_ACCOUNT.FIN_PORTFOLIO%type;
  begin
    -- ouverture du curseur sur le document
    open document(document_id);

    fetch document
     into document_tuple;

    -- maj de l'id de l'année financière
    if document_tuple.acs_financial_year_id is null then
      -- recherche d'après le numéro d'exercice
      if document_tuple.fye_no_exercice is not null then
        select max(ACS_FINANCIAL_YEAR_ID)
          into financial_year_id
          from ACS_FINANCIAL_YEAR
         where FYE_NO_EXERCICE = document_tuple.fye_no_exercice;
      end if;

      select max(imf_transaction_date)
        into transaction_date
        from aci_financial_imputation
       where aci_document_id = document_id
         and imf_primary = 1;

      -- recherche d'après la date du document
      if     financial_year_id is null
         and (   document_tuple.doc_document_date is not null
              or transaction_date is not null) then
        select max(ACS_FINANCIAL_YEAR_ID)
          into financial_year_id
          from ACS_FINANCIAL_YEAR
         where nvl(transaction_date, document_tuple.doc_document_date) between FYE_START_DATE and FYE_END_DATE + 0.99999;
      end if;

      -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
      if financial_year_id is not null then
        update ACI_DOCUMENT
           set ACS_FINANCIAL_YEAR_ID = financial_year_id
         where ACI_DOCUMENT_ID = document_id;
      else
        fail_reason  := '110';

        close document;

        return 0;
      end if;
    else
      financial_year_id  := document_tuple.acs_financial_year_id;
    end if;

    -- recherche si det_payment
    select count(*)
      into test_num
      from ACI_PART_IMPUTATION PART
         , ACI_DET_PAYMENT DET
     where PART.ACI_DOCUMENT_ID = document_id
       and PART.ACI_PART_IMPUTATION_ID = DET.ACI_PART_IMPUTATION_ID;

    exist_detpay  := test_num > 0;

    -- maj de l'id de la transaction du modèle
    if     (    document_tuple.cat_key is not null
            and document_tuple.typ_key is not null)
       and document_tuple.acj_job_type_s_catalogue_id is null then
      select max(ACJ_JOB_TYPE_S_CATALOGUE_ID)
        into job_type_s_catalogue_id
        from ACJ_JOB_TYPE_S_CATALOGUE
           , ACJ_JOB_TYPE
           , ACJ_CATALOGUE_DOCUMENT
       where ACJ_CATALOGUE_DOCUMENT.CAT_KEY = document_tuple.cat_key
         and ACJ_JOB_TYPE.TYP_KEY = document_tuple.typ_key
         and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID
         and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

      -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
      if job_type_s_catalogue_id is not null then
        update ACI_DOCUMENT
           set ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_catalogue_id
         where ACI_DOCUMENT_ID = document_id;
      else
        fail_reason  := '120';

        close document;

        return 0;
      end if;
    elsif document_tuple.ACJ_JOB_TYPE_S_CATALOGUE_ID is null then
      fail_reason  := '120';

      close document;

      return 0;
    else
      job_type_s_catalogue_id  := document_tuple.ACJ_JOB_TYPE_S_CATALOGUE_ID;
    end if;

    -- recherche du type de catalogue document
    select max(C_TYPE_CATALOGUE)
      into type_catalogue
      from ACJ_JOB_TYPE_S_CATALOGUE A
         , ACJ_CATALOGUE_DOCUMENT B
         , ACI_DOCUMENT C
     where B.ACJ_CATALOGUE_DOCUMENT_ID = A.ACJ_CATALOGUE_DOCUMENT_ID
       and A.ACJ_JOB_TYPE_S_CATALOGUE_id = C.ACJ_JOB_TYPE_S_CATALOGUE_id
       and ACI_DOCUMENT_ID = document_id;

    -- ctrl si det_payment + paiement directe
    if exist_detpay then
      if    nvl(document_tuple.doc_paid_amount_lc, 0) != 0
         or nvl(document_tuple.doc_paid_amount_fc, 0) != 0
         or nvl(document_tuple.doc_paid_amount_eur, 0) != 0
         or document_tuple.cat_key_pmt is not null
         or document_tuple.acj_job_type_s_cat_pmt_id is not null then
        fail_reason  := '121';

        close document;

        return 0;
      end if;
    end if;

    -- contrôle des dico
    if document_tuple.DIC_DOC_SOURCE_ID is not null then
      select max(0)
        into test_num
        from DIC_DOC_SOURCE
       where DIC_DOC_SOURCE_ID = document_tuple.DIC_DOC_SOURCE_ID;

      if test_num is null then
        fail_reason  := '101';

        close document;

        return 0;
      end if;
    end if;

    if document_tuple.DIC_DOC_DESTINATION_ID is not null then
      select max(0)
        into test_num
        from DIC_DOC_DESTINATION
       where DIC_DOC_DESTINATION_ID = document_tuple.DIC_DOC_DESTINATION_ID;

      if test_num is null then
        fail_reason  := '102';

        close document;

        return 0;
      end if;
    end if;

    -- contrôle des dicos libres 1 à 5
    if document_tuple.DIC_ACT_DOC_FREE_CODE1_ID is not null then
      select max(0)
        into test_num
        from DIC_ACT_DOC_FREE_CODE1
       where DIC_ACT_DOC_FREE_CODE1_ID = document_tuple.DIC_ACT_DOC_FREE_CODE1_ID;

      if test_num is null then
        fail_reason  := '103';

        close document;

        return 0;
      end if;
    end if;

    if document_tuple.DIC_ACT_DOC_FREE_CODE2_ID is not null then
      select max(0)
        into test_num
        from DIC_ACT_DOC_FREE_CODE2
       where DIC_ACT_DOC_FREE_CODE2_ID = document_tuple.DIC_ACT_DOC_FREE_CODE2_ID;

      if test_num is null then
        fail_reason  := '103';

        close document;

        return 0;
      end if;
    end if;

    if document_tuple.DIC_ACT_DOC_FREE_CODE3_ID is not null then
      select max(0)
        into test_num
        from DIC_ACT_DOC_FREE_CODE3
       where DIC_ACT_DOC_FREE_CODE3_ID = document_tuple.DIC_ACT_DOC_FREE_CODE3_ID;

      if test_num is null then
        fail_reason  := '103';

        close document;

        return 0;
      end if;
    end if;

    if document_tuple.DIC_ACT_DOC_FREE_CODE4_ID is not null then
      select max(0)
        into test_num
        from DIC_ACT_DOC_FREE_CODE4
       where DIC_ACT_DOC_FREE_CODE4_ID = document_tuple.DIC_ACT_DOC_FREE_CODE4_ID;

      if test_num is null then
        fail_reason  := '103';

        close document;

        return 0;
      end if;
    end if;

    if document_tuple.DIC_ACT_DOC_FREE_CODE5_ID is not null then
      select max(0)
        into test_num
        from DIC_ACT_DOC_FREE_CODE5
       where DIC_ACT_DOC_FREE_CODE5_ID = document_tuple.DIC_ACT_DOC_FREE_CODE5_ID;

      if test_num is null then
        fail_reason  := '103';

        close document;

        return 0;
      end if;
    end if;

    -- vente au comptant sans det_payment (les det_payment sont testés dans det_payment_control)
    if not exist_detpay then
      if    document_tuple.acj_job_type_s_cat_pmt_id is not null
         or document_tuple.cat_key_pmt is not null then
        -- maj de l'id de la transaction du modèle pour le paiement direct
        if     (    document_tuple.cat_key_pmt is not null
                and document_tuple.typ_key is not null)
           and document_tuple.acj_job_type_s_cat_pmt_id is null then
          select max(ACJ_JOB_TYPE_S_CATALOGUE_ID)
            into job_type_s_cat_pmt_id
            from ACJ_JOB_TYPE_S_CATALOGUE
               , ACJ_JOB_TYPE
               , ACJ_CATALOGUE_DOCUMENT
           where ACJ_CATALOGUE_DOCUMENT.CAT_KEY = document_tuple.cat_key_pmt
             and ACJ_JOB_TYPE.TYP_KEY = document_tuple.typ_key
             and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_ID = ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID
             and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

          -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
          if job_type_s_cat_pmt_id is not null then
            update ACI_DOCUMENT
               set ACJ_JOB_TYPE_S_CAT_PMT_ID = job_type_s_cat_pmt_id
             where ACI_DOCUMENT_ID = document_id;
          else
            fail_reason  := '122';

            close document;

            return 0;
          end if;
        elsif document_tuple.ACJ_JOB_TYPE_S_CAT_PMT_ID is null then
          fail_reason  := '122';

          close document;

          return 0;
        else
          job_type_s_cat_pmt_id  := document_tuple.ACJ_JOB_TYPE_S_CAT_PMT_ID;
        end if;

        -- pour un document avec paiement, contrôle que des paiements différents de zéro existent
        if     job_type_s_cat_pmt_id is not null
           and (nvl(document_tuple.DOC_PAID_AMOUNT_LC, 0) = 0)
           and (nvl(document_tuple.DOC_TOTAL_AMOUNT_DC, 0) != 0) then
          fail_reason  := '127';

          close document;

          return 0;
        end if;

        -- les deux transactions du modèle doivent être dans le même travail
        if job_type_s_cat_pmt_id is not null then
          -- si on a des paiements, seuls certains type de catalogues sont autorisés
          if type_catalogue not in('2', '5', '6') then
            fail_reason  := '125';

            close document;

            return 0;
          end if;

          -- recherche du type de catalogue document paiement
          select max(C_TYPE_CATALOGUE)
            into type_catalogue_pmt
            from ACJ_JOB_TYPE_S_CATALOGUE A
               , ACJ_CATALOGUE_DOCUMENT B
               , ACI_DOCUMENT C
           where B.ACJ_CATALOGUE_DOCUMENT_ID = A.ACJ_CATALOGUE_DOCUMENT_ID
             and A.ACJ_JOB_TYPE_S_CATALOGUE_id = C.ACJ_JOB_TYPE_S_CAT_PMT_ID
             and ACI_DOCUMENT_ID = document_id;

          -- le type paiement manuel (3) est obligatoire
          if type_catalogue_pmt <> '3' then
            fail_reason  := '123';

            close document;

            return 0;
          end if;

          -- recherche du modèle de travail
          select max(ACJ_JOB_TYPE_ID)
            into job_type_id
            from ACJ_JOB_TYPE_S_CATALOGUE
           where ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_catalogue_id;

          -- recherche du modèle de travail pour le paiement
          select max(ACJ_JOB_TYPE_ID)
               , max(ACS_FINANCIAL_ACCOUNT_ID)
            into job_type_pmt_id
               , pmt_account_id
            from ACJ_JOB_TYPE_S_CATALOGUE
               , ACJ_CATALOGUE_DOCUMENT
           where ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_cat_pmt_id
             and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

          if job_type_id <> job_type_pmt_id then
            fail_reason  := '124';

            close document;

            return 0;
          elsif pmt_account_id is null then
            fail_reason  := '126';

            close document;

            return 0;
          else
            select min(FIN_PORTFOLIO)
              into vFIN_PORTFOLIO
              from ACS_FINANCIAL_ACCOUNT
             where ACS_FINANCIAL_ACCOUNT_ID = pmt_account_id;

            if vFIN_PORTFOLIO = 1 then
              -- Recherche info couverture + méthode de paiement du catalogue
              select min(ACJ_CATALOGUE_DOCUMENT.CAT_COVER_INFORMATION)
                   , min(ACJ_CATALOGUE_DOCUMENT.ACS_FIN_ACC_S_PAYMENT_ID)
                into vCAT_COVER_INFORMATION
                   , vACS_FIN_ACC_S_PAYMENT_ID
                from ACJ_JOB_TYPE_S_CATALOGUE
                   , ACJ_CATALOGUE_DOCUMENT
               where ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_cat_pmt_id
                 and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID =
                                                                        ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

              -- Recherche méthode de paiement des échéances ou du partenaire (soit à null, soit égaux)
              select min(coalesce(ACI_EXPIRY.ACS_FIN_ACC_S_PAYMENT_ID
                                , ACI_PART_IMPUTATION.ACS_FIN_ACC_S_PAYMENT_ID
                                , vACS_FIN_ACC_S_PAYMENT_ID
                                 )
                        )
                into vACS_FIN_ACC_S_PAYMENT_ID
                from ACI_EXPIRY
                   , ACI_PART_IMPUTATION
               where ACI_EXPIRY.ACI_PART_IMPUTATION_ID(+) = ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID
                 and ACI_PART_IMPUTATION.ACI_DOCUMENT_ID = document_id;

              -- Recherche si génération couverture pour la méthode de paiement
              select min(PMM_COVER_GENERATION)
                into vPMM_COVER_GENERATION
                from ACS_FIN_ACC_S_PAYMENT
               where ACS_FIN_ACC_S_PAYMENT_ID = vACS_FIN_ACC_S_PAYMENT_ID;

              if vCAT_COVER_INFORMATION != 1 then
                fail_reason  := '720';

                close document;

                return 0;
              elsif vPMM_COVER_GENERATION != 1 then
                fail_reason  := '721';

                close document;

                return 0;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;

    -- maj de l'id du compte financier
    if     document_tuple.acc_number is not null
       and document_tuple.acs_financial_account_id is null then
      select max(ACS_FINANCIAL_ACCOUNT_ID)
        into financial_account_id
        from ACS_FINANCIAL_ACCOUNT
           , ACS_ACCOUNT
       where ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT_ID
         and ACC_NUMBER = document_tuple.acc_number;

      -- Si aucun enregistrement n'a trouvé, le flag de control est mis à false
      if financial_account_id is not null then
        update ACI_DOCUMENT
           set ACS_FINANCIAL_ACCOUNT_ID = financial_account_id
         where ACI_DOCUMENT_ID = document_id;
      else
        fail_reason  := '130';

        close document;

        return 0;
      end if;
    end if;

    -- maj de l'id de la monnaie du document
    if     document_tuple.currency is not null
       and document_tuple.acs_financial_currency_id is null then
      select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
        into financial_currency_id
        from ACS_FINANCIAL_CURRENCY FIN
           , PCS.PC_CURR CUR
       where CUR.PC_CURR_ID = FIN.PC_CURR_ID
         and CUR.CURRENCY = document_tuple.currency;

      -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
      if financial_currency_id is not null then
        update ACI_DOCUMENT
           set ACS_FINANCIAL_CURRENCY_id = financial_currency_id
         where ACI_DOCUMENT_ID = document_id;

        document_tuple.acs_financial_currency_id  := financial_currency_id;
      else
        fail_reason  := '140';

        close document;

        return 0;
      end if;
    elsif     document_tuple.currency is null
          and document_tuple.acs_financial_currency_id is null then
      fail_reason  := '140';

      close document;

      return 0;
    end if;

    -- maj de l'id de la monnaie tva
    if     document_tuple.vat_currency is not null
       and document_tuple.acs_acs_financial_currency_id is null then
      select max(FIN.ACS_FINANCIAL_CURRENCY_ID)
        into vat_currency_id
        from ACS_FINANCIAL_CURRENCY FIN
           , PCS.PC_CURR CUR
       where CUR.PC_CURR_ID = FIN.PC_CURR_ID
         and CUR.CURRENCY = document_tuple.vat_currency;

      -- Si aucun enregistrement n'a été mis à jour, le flag de control est mis à false
      if vat_currency_id is not null then
        update ACI_DOCUMENT
           set ACS_ACS_FINANCIAL_CURRENCY_id = vat_currency_id
         where ACI_DOCUMENT_ID = document_id;
      else
        fail_reason  := '150';

        close document;

        return 0;
      end if;
    -- si la monnaie TVA n'est pas renseignée, on l'initialise avec celle du décompte
    elsif     document_tuple.vat_currency is null
          and document_tuple.acs_acs_financial_currency_id is null then
      begin
        select   VATDET.ACS_FINANCIAL_CURRENCY_ID
            into vat_currency_id
            from ACI_FINANCIAL_IMPUTATION IMP
               , ACS_TAX_CODE TAX
               , ACS_VAT_DET_ACCOUNT VATDET
           where IMP.ACI_DOCUMENT_ID = document_id
             and IMP.ACS_TAX_CODE_ID = TAX.ACS_TAX_CODE_ID
             and TAX.ACS_VAT_DET_ACCOUNT_ID = VATDET.ACS_VAT_DET_ACCOUNT_ID
        group by VATDET.ACS_FINANCIAL_CURRENCY_ID;
      exception
        when no_data_found then
          vat_currency_id  := null;
        when too_many_rows then
          -- plusieurs monnaie TVA
          fail_reason  := '151';

          close document;

          return 0;
      end;

      if vat_currency_id is not null then
        update ACI_DOCUMENT
           set ACS_ACS_FINANCIAL_CURRENCY_id = vat_currency_id
         where ACI_DOCUMENT_ID = document_id;
      end if;
    end if;

    close document;

    if     type_catalogue = '3'
       and exist_detpay then
      -- Test compte financier du catalogue
      -- recherche du modèle de travail pour le paiement
      select max(ACS_FINANCIAL_ACCOUNT_ID)
        into pmt_account_id
        from ACJ_JOB_TYPE_S_CATALOGUE
           , ACJ_CATALOGUE_DOCUMENT
       where ACJ_JOB_TYPE_S_CATALOGUE_ID = job_type_s_catalogue_id
         and ACJ_JOB_TYPE_S_CATALOGUE.ACJ_CATALOGUE_DOCUMENT_ID = ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID;

      if pmt_account_id is null then
        fail_reason  := '728';
        return 0;
      end if;

      -- Si type '3' avec det_payment -> pas d'imputation
      -- Regarde si des imputations existent
      select count(*)
        into test_num
        from aci_financial_imputation
       where aci_document_id = document_id;

      if test_num = 0 then
        select count(*)
          into test_num
          from aci_mgm_imputation
         where aci_document_id = document_id;
      end if;

      if test_num > 0 then
        fail_reason  := '701';
        return 0;
      end if;
    elsif type_catalogue in('1', '2', '3', '4', '5', '6', '7') then
      -- controle de la présence d'une imputation primaire pour les type de catalogue
      -- énumérés ci-dessous

      -- Regarde si des imputations existent
      select max(aci_financial_imputation_id)
        into imput_id
        from aci_financial_imputation
       where aci_document_id = document_id;

      -- Si le document a des imputations, on recherche l'imputation primaire
      if imput_id is not null then
        select count(*)
          into nb_imputation
          from aci_financial_imputation
         where aci_document_id = document_id
           and imf_primary = 1;

        -- Erreur : imputation primaire non existante
        if nb_imputation <> 1 then
          fail_reason  := '400';
          return 0;
        else
          select abs(IMF_AMOUNT_LC_D + IMF_AMOUNT_LC_C)
               , abs(IMF_AMOUNT_FC_D + IMF_AMOUNT_FC_C)
            into amount_imp_prim_lc
               , amount_imp_prim_fc
            from aci_financial_imputation
           where aci_document_id = document_id
             and imf_primary = 1;

          -- Erreur : montant imputation primaire <> montant document
          if ACS_FUNCTION.GetLocalCurrencyId = document_tuple.acs_financial_currency_id then
            if amount_imp_prim_lc <> abs(document_tuple.doc_total_amount_dc) then
              fail_reason  := '020';
              return 0;
            end if;
          else
            if amount_imp_prim_fc <> abs(document_tuple.doc_total_amount_dc) then
              fail_reason  := '020';
              return 0;
            end if;
          end if;
        end if;
      end if;
    end if;

    return 1;
  end Header_Control;

  /**
  * Description
  *   contrôle si tout les documents avec la clé de regroupement sont contrôlé OK
  */
  function GrpKey_Check(grp_key in varchar2)
    return number
  is
    doc_check number(1);
  begin
    select case
             when sign(nvl(max(doc.ACI_DOCUMENT_ID), 0) ) = 0 then 1
             else 0
           end
      into doc_check
      from aci_document_status sta
         , aci_document doc
     where doc.ACI_DOCUMENT_ID = sta.ACI_DOCUMENT_ID
       and doc.DOC_GRP_KEY = grp_key
       and doc.DOC_INTEGRATION_DATE is null
       and sta.C_ACI_FINANCIAL_LINK in('4', '5')
       and C_INTERFACE_CONTROL != '1';

    return doc_check;
  end GrpKey_Check;

  /**
  * Description
  *   contrôle des documents selon la clé de regroupement
  */
  procedure GrpKey_Control(grp_key in varchar2, control_flag in out number)
  is
    cursor csr_document(grpkey varchar2)
    is
      select doc.ACI_DOCUMENT_ID
        from ACI_DOCUMENT_STATUS sta
           , ACI_DOCUMENT doc
       where doc.ACI_DOCUMENT_ID = sta.ACI_DOCUMENT_ID
         and doc.DOC_INTEGRATION_DATE is null
         and doc.DOC_GRP_KEY = grpkey
         and sta.C_ACI_FINANCIAL_LINK in('4', '5');

    tpl_document csr_document%rowtype;
  begin
    -- si on la clé n'est pas nul -> contrôle de tout les documents pas encore intégrés
    if grp_key is not null then
      control_flag          := 1;
      -- désactivation du contrôle sur la clé dans Doc_Control
      GrpKey_InternalCheck  := false;

      open csr_document(grp_key);

      fetch csr_document
       into tpl_document;

      while control_flag = 1
       and csr_document%found loop
        Doc_Control(tpl_document.ACI_DOCUMENT_ID, control_flag);

        fetch csr_document
         into tpl_document;
      end loop;

      close csr_document;

      -- résactivation du contrôle sur la clé dans Doc_Control
      GrpKey_InternalCheck  := true;
    else
      -- clé nul -> contrôle faux
      control_flag  := 0;
    end if;
  end GrpKey_Control;

  /**
  * Description
  *   procédure principale de controle du document
  */
  procedure Doc_Control(
    document_id        in     number
  , control_flag       in out number
  , aci_financial_link in     ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK%type default null
  )
  is
    financial_year_id       ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    parity_sum              ACI_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    job_type_s_catalogue_id ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID%type;
    job_type_s_cat_pmt_id   ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID%type;
    fail_reason             ACI_DOCUMENT.C_FAIL_REASON%type;
    customer                number(1);
    person_id               PAC_PERSON.PAC_PERSON_ID%type;
    type_catalogue          ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type;
    grp_key                 ACI_DOCUMENT.DOC_GRP_KEY%type;
    financial_link          ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK%type;
  begin
    -- Contrôle si document type 4 ou 5 avec clé de regroupement
    if aci_financial_link is null then
      select max(doc.DOC_GRP_KEY)
           , max(sta.C_ACI_FINANCIAL_LINK)
        into grp_key
           , financial_link
        from aci_document_status sta
           , aci_document doc
       where doc.ACI_DOCUMENT_ID = document_id
         and doc.ACI_DOCUMENT_ID = sta.ACI_DOCUMENT_ID(+);
    else
      financial_link  := aci_financial_link;

      if financial_link in('4', '5') then
        select max(doc.DOC_GRP_KEY)
          into grp_key
          from aci_document doc
         where doc.ACI_DOCUMENT_ID = document_id;
      end if;
    end if;

    if     aci_financial_link is null
       and GrpKey_InternalCheck then
      if upper(PCS.PC_CONFIG.GetConfig('ACI_DOC_GRP_KEY') ) = 'TRUE' then
        if     financial_link in('4', '5')
           and grp_key is not null then
          GrpKey_Control(grp_key, control_flag);
          return;
        end if;
      end if;
    end if;

    -- initialisation du flag de controle
    control_flag  := 1;

    -- Réinit du descode C_FAIL_REASON
    update ACI_DOCUMENT
       set C_FAIL_REASON = null
     where ACI_DOCUMENT_ID = document_id;

    -- Si intégration par queu XML -> pas de contrôle et on passe directement à OK
    if financial_link = '8' then
      update ACI_DOCUMENT
         set C_INTERFACE_CONTROL = '1'
       where ACI_DOCUMENT_ID = document_id;

      return;
    end if;

    -- si link = 4 ou 5 et pas de clef de regroupement
    if     financial_link in('4', '5')
       and grp_key is null then
      control_flag  := 0;
      fail_reason   := '160';
    end if;

    if control_flag = 1 then
      -- Appel du control de l'entête
      control_flag  :=
        Header_Control(document_id
                     , financial_year_id
                     , job_type_s_catalogue_id
                     , job_type_s_cat_pmt_id
                     , type_catalogue
                     , fail_reason
                      );

      -- si le flag de control est OK
      if control_flag = 1 then
        control_flag  :=
          Part_Imputation_Control(document_id
                                , financial_year_id
                                , job_type_s_catalogue_id
                                , type_catalogue
                                , customer
                                , person_id
                                , fail_reason
                                 );

        -- si le flag de control est OK
        if control_flag = 1 then
          control_flag  :=
            Financial_Imputation_Control(document_id
                                       , financial_year_id
                                       , customer
                                       , person_id
                                       , type_catalogue
                                       , fail_reason
                                        );

          -- si le flag de control est OK
          if control_flag = 1 then
            control_flag  := Mgm_Imputation_Control(document_id, financial_year_id, fail_reason);

            -- pour les documents écritures (type 1), contrôle des det_payment
            -- (dans ce cas pas de part_imputation)
            if     control_flag = 1
               and type_catalogue = '1' then
              control_flag  :=
                Det_Payment_Control(null, type_catalogue, job_type_s_catalogue_id, null, null, fail_reason
                                  , document_id);
            end if;
          end if;
        end if;
      end if;

      -- control de la parité débit-crédit
      if control_flag = 1 then
        select sum(imf_amount_lc_c +
                   case
                     when imf_amount_lc_c = 0 then 0
                     else case
                     when nvl(TAX_DEDUCTIBLE_RATE, 100) = 100 then 0
                     else nvl(TAX_TOT_VAT_AMOUNT_LC, 0) - nvl(TAX_VAT_AMOUNT_LC, 0)
                   end
                   end
                  ) -
               sum(imf_amount_lc_d +
                   case
                     when imf_amount_lc_d = 0 then 0
                     else case
                     when nvl(TAX_DEDUCTIBLE_RATE, 100) = 100 then 0
                     else nvl(TAX_TOT_VAT_AMOUNT_LC, 0) - nvl(TAX_VAT_AMOUNT_LC, 0)
                   end
                   end
                  )
          into parity_sum
          from aci_financial_imputation
         where ACI_DOCUMENT_ID = document_id;

        -- si on a une différence entre le débiut et le crédit, alors il y a erreur
        if parity_sum <> 0 then
          fail_reason   := '010';
          control_flag  := 0;
        end if;
      end if;

      -- Effacement du document pré-saisi
      if control_flag = 1 then
        DeleteForeCapture(document_id, financial_year_id, job_type_s_catalogue_id, customer);
      end if;

      -- mise à jour du descode CCONTROL_LINK de ACI_DOCUMENT
      if control_flag = 1 then
        update ACI_DOCUMENT
           set C_INTERFACE_CONTROL = '1'
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where ACI_DOCUMENT_ID = document_id;
      else
        update ACI_DOCUMENT
           set C_INTERFACE_CONTROL = '2'
             , C_FAIL_REASON = lpad(fail_reason, 3, '0')
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where ACI_DOCUMENT_ID = document_id;

        --Mise à jour à 'Bloqué' du statut du système d'échange de données
        update PCS.PC_EXCHANGE_DATA_IN
           set C_EDI_STATUS_ACT = '2'
         where ACI_DOCUMENT_ID = document_id;
      end if;
    end if;
  end Doc_Control;
end ACI_DOCUMENT_CONTROL;
