--------------------------------------------------------
--  DDL for Package Body MOB_PRC_VIEW_PAC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MOB_PRC_VIEW_PAC" 
is
  procedure crud_person(it_person in MOB_LIB_VIEW_PAC.t_person, iv_context in varchar2)
  is
    lt_crud_def  fwk_i_typ_definition.T_CRUD_DEF;
    ln_person_id pac_person.pac_person_id%type;
    lv_key1      pac_person.per_key1%type;
  begin
    /*
      Prévoir ici un point d'entrée pour injecter du code, respectivement appeler une procédure individualisée
      de manière à traiter les données d'une manière particulière t.q. champs virtuels ou libres p.ex.
    */
    if nvl(it_person.a_deleted, 0) = 0 then
      if iv_context = 'UPDATE' then
        pac_e_prc_crm.UpdatePERSON(in_PAC_PERSON_ID             => it_person.pac_person_id
                                 , iv_DIC_PERSON_POLITNESS_ID   => it_person.dic_person_politness_id
                                 , iv_PER_NAME                  => it_person.per_name
                                 , iv_PER_FORENAME              => it_person.per_forename
                                 , iv_PER_ACTIVITY              => it_person.per_activity
                                 , iv_PER_COMMENT               => it_person.per_comment
                                 , iv_PER_KEY1                  => it_person.per_key1
                                 , iv_PER_KEY2                  => it_person.per_key2
                                 , iv_DIC_FREE_CODE1_ID         => it_person.DIC_FREE_CODE1_ID
                                 , iv_DIC_FREE_CODE2_ID         => it_person.DIC_FREE_CODE2_ID
                                 , iv_DIC_FREE_CODE3_ID         => it_person.DIC_FREE_CODE3_ID
                                 , iv_DIC_FREE_CODE4_ID         => it_person.DIC_FREE_CODE4_ID
                                 , iv_DIC_FREE_CODE5_ID         => it_person.DIC_FREE_CODE5_ID
                                 , iv_DIC_FREE_CODE6_ID         => it_person.DIC_FREE_CODE6_ID
                                 , iv_DIC_FREE_CODE7_ID         => it_person.DIC_FREE_CODE7_ID
                                 , iv_DIC_FREE_CODE8_ID         => it_person.DIC_FREE_CODE8_ID
                                 , iv_DIC_FREE_CODE9_ID         => it_person.DIC_FREE_CODE9_ID
                                 , iv_DIC_FREE_CODE10_ID        => it_person.DIC_FREE_CODE10_ID
                                 , iv_PER_SHORT_NAME            => it_person.per_short_name
                                 , in_PER_CONTACT               => it_person.per_contact
                                 , iv_C_PARTNER_STATUS          => it_person.C_PARTNER_STATUS
                                  );
      elsif iv_context = 'INSERT' then
        ln_person_id  :=
          pac_e_prc_crm.CreatePERSON(iv_DIC_PERSON_POLITNESS_ID   => it_person.dic_person_politness_id
                                   , iv_PER_NAME                  => it_person.per_name
                                   , iv_PER_FORENAME              => it_person.per_forename
                                   , iv_PER_ACTIVITY              => it_person.per_activity
                                   , iv_PER_COMMENT               => it_person.per_comment
                                   , iv_PER_KEY1                  => it_person.per_key1
                                   , iv_PER_KEY2                  => it_person.per_key2
                                   , iv_DIC_FREE_CODE1_ID         => it_person.DIC_FREE_CODE1_ID
                                   , iv_DIC_FREE_CODE2_ID         => it_person.DIC_FREE_CODE2_ID
                                   , iv_DIC_FREE_CODE3_ID         => it_person.DIC_FREE_CODE3_ID
                                   , iv_DIC_FREE_CODE4_ID         => it_person.DIC_FREE_CODE4_ID
                                   , iv_DIC_FREE_CODE5_ID         => it_person.DIC_FREE_CODE5_ID
                                   , iv_DIC_FREE_CODE6_ID         => it_person.DIC_FREE_CODE6_ID
                                   , iv_DIC_FREE_CODE7_ID         => it_person.DIC_FREE_CODE7_ID
                                   , iv_DIC_FREE_CODE8_ID         => it_person.DIC_FREE_CODE8_ID
                                   , iv_DIC_FREE_CODE9_ID         => it_person.DIC_FREE_CODE9_ID
                                   , iv_DIC_FREE_CODE10_ID        => it_person.DIC_FREE_CODE10_ID
                                   , iv_PER_SHORT_NAME            => it_person.per_short_name
                                   , in_PER_CONTACT               => it_person.per_contact
                                   , iv_C_PARTNER_STATUS          => '1'
                                   , ov_PER_KEY1                  => lv_key1
                                   , in_PAC_PERSON_ID             => it_person.pac_person_id
                                    );
      end if;
    else
      PAC_E_PRC_CRM.DELETEPERSON(it_person.pac_person_id);
    end if;
  end;

  procedure crud_communication(it_comm in MOB_LIB_VIEW_PAC.t_communication, iv_context in varchar2)
  is
    lt_crud_def         fwk_i_typ_definition.T_CRUD_DEF;
    ln_communication_id pac_communication.pac_communication_id%type;
    ltpl_communication  pac_communication%rowtype;
  begin
    /*
      Prévoir ici un point d'entrée pour injecter du code, respectivement appeler une procédure individualisée
      de manière à traiter les données d'une manière particulière t.q. champs virtuels ou libres p.ex.
    */
    if nvl(it_comm.a_deleted, 0) = 0 then
      if iv_context = 'UPDATE' then
        select *
          into ltpl_communication
          from pac_communication
         where pac_communication_id = it_comm.PAC_COMMUNICATION_ID;

        pac_e_prc_crm.UpdateCOMMUNICATION(IN_PAC_COMMUNICATION_ID        => it_comm.PAC_COMMUNICATION_ID
                                        , IN_PAC_PERSON_ID               => it_comm.pac_person_id
                                        , in_PAC_ADDRESS_ID              => ltpl_communication.pac_address_id
                                        , iv_DIC_COMMUNICATION_TYPE_ID   => it_comm.DIC_COMMUNICATION_TYPE_ID
                                        , iv_COM_EXT_NUMBER              => it_comm.COM_EXT_NUMBER
                                        , iv_COM_INT_NUMBER              => ltpl_communication.com_int_number
                                        , iv_COM_AREA_CODE               => ltpl_communication.com_area_code
                                        , iv_COM_COMMENT                 => ltpl_communication.com_comment
                                         );
      elsif iv_context = 'INSERT' then
        ln_communication_id  :=
          pac_e_prc_crm.CreateCOMMUNICATION(in_PAC_PERSON_ID               => it_comm.pac_person_id
                                          , iv_DIC_COMMUNICATION_TYPE_ID   => it_comm.DIC_COMMUNICATION_TYPE_ID
                                          , iv_COM_EXT_NUMBER              => it_comm.COM_EXT_NUMBER
                                          , inPAC_COMMUNICATION_ID         => it_comm.PAC_COMMUNICATION_ID
                                          , in_COM_PREFERRED_CONTACT       => 0
                                           );
      end if;
    else
      PAC_E_PRC_CRM.DeleteCOMMUNICATION(it_comm.PAC_COMMUNICATION_ID);
    end if;
  end;

  procedure crud_ADDRESS(it_ADR in MOB_LIB_VIEW_PAC.t_address, iv_context in varchar2)
  is
    lt_crud_def   fwk_i_typ_definition.T_CRUD_DEF;
    ln_ADDRESS_id PAC_ADDRESS.PAC_ADDRESS_ID%type;
    ltpl_address  PAC_ADDRESS%rowtype;
  begin
    /*
      Prévoir ici un point d'entrée pour injecter du code, respectivement appeler une procédure individualisée
      de manière à traiter les données d'une manière particulière t.q. champs virtuels ou libres p.ex.
    */
    if nvl(it_ADR.a_deleted, 0) = 0 then
      if iv_context = 'UPDATE' then
        select *
          into ltpl_address
          from PAC_ADDRESS
         where PAC_ADDRESS_ID = it_ADR.PAC_ADDRESS_ID;

        pac_e_prc_crm.UpdateADDRESS(in_PAC_ADDRESS_ID        => IT_Adr.pac_address_id
                                  , in_PAC_PERSON_ID         => IT_Adr.PAC_PERSON_ID
                                  , iv_CNTID                 => IT_Adr.CNTID
                                  , iv_ADD_ADDRESS1          => IT_Adr.ADD_ADDRESS1
                                  , iv_ADD_ZIPCODE           => IT_Adr.add_zipcode
                                  , iv_ADD_CITY              => IT_Adr.ADD_CITY
                                  , iv_ADD_STATE             => IT_Adr.ADD_STATE
                                  , iv_LANID                 => IT_Adr.lanid
                                  , iv_ADD_COMMENT           => ltpl_address.add_comment
                                  , iv_DIC_ADDRESS_TYPE_ID   => IT_Adr.dic_address_type_id
                                  , id_ADD_SINCE             => ltpl_address.add_since
                                  , iv_ADD_FORMAT            => PAC_PARTNER_MANAGEMENT.FORMATingADDRESS(it_adr.add_zipcode
                                                                                                      , it_adr.add_city
                                                                                                      , it_ADR.add_state
                                                                                                      , null
                                                                                                      , MOB_LIB_VIEW_PAC.country_id(it_adr.cntid)
                                                                                                       )
                                  , in_ADD_PRINCIPAL         => ltpl_address.add_principal
                                  , iv_C_PARTNER_STATUS      => ltpl_address.c_partner_status
                                  , in_ADD_PRIORITY          => ltpl_address.add_priority
                                  , iv_ADD_CARE_OF           => ltpl_address.add_care_of
                                  , iv_ADD_PO_BOX            => ltpl_address.add_po_box
                                  , in_ADD_PO_BOX_NBR        => ltpl_address.add_po_box_nbr
                                  , iv_ADD_COUNTY            => ltpl_address.add_county
                                   );
      elsif iv_context = 'INSERT' then
        ln_ADDRESS_id  :=
          pac_e_prc_crm.CreateADDRESS(in_PAC_PERSON_ID         => IT_Adr.PAC_PERSON_ID
                                    , iv_CNTID                 => IT_Adr.CNTID
                                    , iv_ADD_ADDRESS1          => IT_Adr.ADD_ADDRESS1
                                    , iv_ADD_ZIPCODE           => IT_Adr.add_zipcode
                                    , iv_ADD_CITY              => IT_Adr.ADD_CITY
                                    , iv_ADD_STATE             => IT_Adr.ADD_STATE
                                    , iv_LANID                 => IT_Adr.lanid
                                    , iv_ADD_COMMENT           => null
                                    , iv_DIC_ADDRESS_TYPE_ID   => IT_Adr.dic_address_type_id
                                    , id_ADD_SINCE             => null
                                    , iv_ADD_FORMAT            => PAC_PARTNER_MANAGEMENT.FORMATingADDRESS(it_adr.add_zipcode
                                                                                                        , it_adr.add_city
                                                                                                        , it_ADR.add_state
                                                                                                        , null
                                                                                                        , MOB_LIB_VIEW_PAC.country_id(it_adr.cntid)
                                                                                                         )
                                    , in_ADD_PRINCIPAL         => 0
                                    , iv_C_PARTNER_STATUS      => '1'
                                    , in_ADD_PRIORITY          => null
                                    , iv_ADD_CARE_OF           => null
                                    , iv_ADD_PO_BOX            => null
                                    , in_ADD_PO_BOX_NBR        => null
                                    , iv_ADD_COUNTY            => null
                                    , in_PAC_ADDRESS_ID        => IT_Adr.pac_address_id
                                     );
      end if;
    else
      PAC_E_PRC_CRM.DeleteADDRESS(it_ADR.PAC_ADDRESS_ID);
    end if;
  end;

  procedure crud_association(it_asso in MOB_LIB_VIEW_PAC.t_association, iv_context in varchar2)
  is
    lt_crud_def       fwk_i_typ_definition.T_CRUD_DEF;
    ln_person_asso_id pac_person.pac_person_id%type;
    ln_person_id      pac_person.pac_person_id%type;
    lv_key1           pac_person.per_key1%type;
    tpl_person        pac_person%rowtype;
    tpl_asso          pac_person_association%rowtype;
  begin
    /*
      Prévoir ici un point d'entrée pour injecter du code, respectivement appeler une procédure individualisée
      de manière à traiter les données d'une manière particulière t.q. champs virtuels ou libres p.ex.
    */
    if nvl(it_asso.a_deleted, 0) = 0 then
      if iv_context = 'UPDATE' then
        select *
          into tpl_asso
          from pac_person_association a
         where a.pac_person_association_id = it_asso.pac_person_association_id;

        select *
          into tpl_person
          from pac_person
         where pac_person_id = it_asso.pac_person_id;

        pac_e_prc_crm.UpdatePERSON(in_PAC_PERSON_ID             => IT_ASSO.pac_person_id
                                 , iv_DIC_PERSON_POLITNESS_ID   => IT_ASSO.dic_person_politness_id
                                 , iv_PER_NAME                  => IT_ASSO.per_name
                                 , iv_PER_FORENAME              => IT_ASSO.per_forename
                                 , iv_PER_ACTIVITY              => tpl_person.per_activity
                                 , iv_PER_COMMENT               => IT_ASSO.per_comment
                                 , iv_PER_KEY1                  => IT_ASSO.per_key1
                                 , iv_PER_KEY2                  => IT_ASSO.per_key2
                                 , iv_DIC_FREE_CODE1_ID         => IT_ASSO.DIC_FREE_CODE1_ID
                                 , iv_DIC_FREE_CODE2_ID         => IT_ASSO.DIC_FREE_CODE2_ID
                                 , iv_DIC_FREE_CODE3_ID         => IT_ASSO.DIC_FREE_CODE3_ID
                                 , iv_DIC_FREE_CODE4_ID         => IT_ASSO.DIC_FREE_CODE4_ID
                                 , iv_DIC_FREE_CODE5_ID         => IT_ASSO.DIC_FREE_CODE5_ID
                                 , iv_DIC_FREE_CODE6_ID         => IT_ASSO.DIC_FREE_CODE6_ID
                                 , iv_DIC_FREE_CODE7_ID         => IT_ASSO.DIC_FREE_CODE7_ID
                                 , iv_DIC_FREE_CODE8_ID         => IT_ASSO.DIC_FREE_CODE8_ID
                                 , iv_DIC_FREE_CODE9_ID         => IT_ASSO.DIC_FREE_CODE9_ID
                                 , iv_DIC_FREE_CODE10_ID        => IT_ASSO.DIC_FREE_CODE10_ID
                                 , iv_PER_SHORT_NAME            => IT_ASSO.per_short_name
                                 , in_PER_CONTACT               => IT_ASSO.per_contact
                                 , iv_C_PARTNER_STATUS          => tpl_person.C_PARTNER_STATUS
                                  );
        PAC_E_PRC_CRM.UPDATEPERSON_ASSOCIATION(in_PAC_PERSON_ASSOCIATION_ID   => IT_ASSO.PAC_PERSON_ASSOCIATION_ID
                                             , in_PAC_PERSON_ID               => it_asso.pac_company_id
                                             , in_PAC_PAC_PERSON_ID           => it_asso.pac_person_id
                                             , iv_DIC_ASSOCIATION_TYPE_ID     => it_asso.dic_association_type_id
                                             , iv_PAS_COMMENT                 => tpl_asso.pas_comment
                                             , iv_PAS_FUNCTION                => it_asso.pas_function
                                             , iv_C_PARTNER_STATUS            => tpl_asso.c_partner_status
                                             , in_PAS_MAIN_CONTACT            => it_asso.pas_main_contact
                                              );
      else
        /* Création du contact :
            1. Création du contact lui-même
            2. Création de l'association
        */
        ln_person_id       :=
          pac_e_prc_crm.CreatePERSON(iv_DIC_PERSON_POLITNESS_ID   => IT_ASSO.dic_person_politness_id
                                   , iv_PER_NAME                  => IT_ASSO.per_name
                                   , iv_PER_FORENAME              => IT_ASSO.per_forename
                                   , iv_PER_ACTIVITY              => null
                                   , iv_PER_COMMENT               => IT_ASSO.per_comment
                                   , iv_PER_KEY1                  => IT_ASSO.per_key1
                                   , iv_PER_KEY2                  => IT_ASSO.per_key2
                                   , iv_DIC_FREE_CODE1_ID         => IT_ASSO.DIC_FREE_CODE1_ID
                                   , iv_DIC_FREE_CODE2_ID         => IT_ASSO.DIC_FREE_CODE2_ID
                                   , iv_DIC_FREE_CODE3_ID         => IT_ASSO.DIC_FREE_CODE3_ID
                                   , iv_DIC_FREE_CODE4_ID         => IT_ASSO.DIC_FREE_CODE4_ID
                                   , iv_DIC_FREE_CODE5_ID         => IT_ASSO.DIC_FREE_CODE5_ID
                                   , iv_DIC_FREE_CODE6_ID         => IT_ASSO.DIC_FREE_CODE6_ID
                                   , iv_DIC_FREE_CODE7_ID         => IT_ASSO.DIC_FREE_CODE7_ID
                                   , iv_DIC_FREE_CODE8_ID         => IT_ASSO.DIC_FREE_CODE8_ID
                                   , iv_DIC_FREE_CODE9_ID         => IT_ASSO.DIC_FREE_CODE9_ID
                                   , iv_DIC_FREE_CODE10_ID        => IT_ASSO.DIC_FREE_CODE10_ID
                                   , iv_PER_SHORT_NAME            => IT_ASSO.per_short_name
                                   , in_PER_CONTACT               => '1'
                                   , iv_C_PARTNER_STATUS          => '1'
                                   , ov_PER_KEY1                  => lv_key1
                                    );
        ln_person_asso_id  :=
          PAC_E_PRC_CRM.CREATEPERSON_ASSOCIATION(in_PAC_PERSON_ID               => it_asso.pac_company_id
                                               , in_PAC_PAC_PERSON_ID           => ln_person_id
                                               , iv_DIC_ASSOCIATION_TYPE_ID     => it_asso.dic_association_type_id
                                               , iv_PAS_COMMENT                 => null
                                               , iv_PAS_FUNCTION                => it_asso.pas_function
                                               , iv_C_PARTNER_STATUS            => '1'
                                               , in_PAS_MAIN_CONTACT            => it_asso.pas_main_contact
                                               , in_PAC_PERSON_ASSOCIATION_ID   => it_asso.pac_person_association_id
                                                );
      end if;
    else
      PAC_E_PRC_CRM.DELETEPERSON_ASSOCIATION(IT_ASSO.PAC_PERSON_ASSOCIATION_ID);
    end if;
  end crud_association;

  procedure crud_event(it_event in MOB_LIB_VIEW_PAC.t_event, iv_context in varchar2)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_event_id pac_event.pac_event_id%type;
  begin
    /*
      Prévoir ici un point d'entrée pour injecter du code, respectivement appeler une procédure individualisée
      de manière à traiter les données d'une manière particulière t.q. champs virtuels ou libres p.ex.
    */
    if nvl(it_event.a_deleted, 0) = 0 then
      if iv_context = 'UPDATE' then
        /* Appel à pac_e_prc_crm */
        PAC_E_PRC_CRM.UpdateEVENT(in_PAC_EVENT_ID        => it_event.PAC_EVENT_ID
                                , id_EVE_ENDDATE         => it_event.EVE_ENDDATE
                                , in_PAC_PERSON_ID       => it_event.PAC_PERSON_ID
                                , id_EVE_DATE            => it_event.EVE_DATE
                                , in_PAC_company_ID      => it_event.PAC_company_ID
                                , in_PAC_LEAD_ID         => it_event.PAC_LEAD_ID
                                , in_PAC_EVENT_TYPE_ID   => it_event.PAC_EVENT_TYPE_ID
                                , iv_EVE_SUBJECT         => it_event.EVE_SUBJECT
                                , iv_EVE_TEXT            => it_event.EVE_TEXT
                                , in_EVE_ENDED           => it_event.EVE_ENDED
                                , id_EVE_DATE_COMPLETED  => it_event.EVE_DATE_COMPLETED
                                , in_EVE_USER_ID         => it_event.EVE_USER_ID
                                 );
      elsif iv_context = 'INSERT' then
        /* Appel à pac_e_prc_crm */
        ln_event_id  :=
          PAC_E_PRC_CRM.CREATEEVENT(id_EVE_ENDDATE         => it_event.EVE_ENDDATE
                                  , in_PAC_PERSON_ID       => it_event.PAC_PERSON_ID
                                  , id_EVE_DATE            => it_event.EVE_DATE
                                  , in_PAC_company_ID      => it_event.PAC_company_ID
                                  , in_PAC_LEAD_ID         => it_event.PAC_LEAD_ID
                                  , in_PAC_EVENT_TYPE_ID   => it_event.PAC_EVENT_TYPE_ID
                                  , iv_EVE_SUBJECT         => it_event.EVE_SUBJECT
                                  , iv_EVE_TEXT            => it_event.EVE_TEXT
                                  , in_EVE_USER_ID         => it_event.EVE_USER_ID
                                  , in_EVE_ENDED           => it_event.EVE_ENDED
                                  , id_EVE_DATE_COMPLETED  => it_event.EVE_DATE_COMPLETED
                                  , in_PAC_EVENT_ID        => it_event.PAC_EVENT_ID
                                  , in_EVE_PRIVATE         => 0
                                   );
      end if;
    else
      /* Appel à pac_e_prc_crm pour faire le delete */
      PAC_E_PRC_CRM.DeleteEVENT(it_event.PAC_EVENT_ID);
    end if;
  end crud_event;

  procedure crud_lead(it_lead in MOB_LIB_VIEW_PAC.t_lead, iv_context in varchar2)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_lead_id  pac_lead.pac_lead_id%type;
  begin
    /*
      Prévoir ici un point d'entrée pour injecter du code, respectivement appeler une procédure individualisée
      de manière à traiter les données d'une manière particulière t.q. champs virtuels ou libres p.ex.
    */
    if nvl(it_lead.a_deleted, 0) = 0 then
      if iv_context = 'UPDATE' then
        /* Appel à pac_e_prc_crm */
        PAC_E_PRC_CRM.UpdateLEAD(in_PAC_LEAD_ID                 => it_lead.PAC_LEAD_ID
                               , in_PAC_PERSON_ID               => it_lead.PAC_PERSON_ID
                               , iv_C_LEAD_STATUS               => it_lead.C_LEAD_STATUS
                               , iv_LEA_LABEL                   => it_lead.LEA_LABEL
                               , iv_LEA_COMMENT                 => it_lead.LEA_COMMENT
                               , iv_DIC_LEA_SOURCE_ID           => it_lead.DIC_LEA_SOURCE_ID
                               , iv_LEA_SOURCE_COMMENT          => it_lead.LEA_SOURCE_COMMENT
                               , iv_LEA_SOURCE_NR               => it_lead.LEA_SOURCE_NR
                               , iv_DIC_LEA_CLASSIFICATION_ID   => it_lead.DIC_LEA_CLASSIFICATION_ID
                               , in_PAC_REPRESENTATIVE_ID       => it_lead.PAC_REPRESENTATIVE_ID
                               , in_LEA_USER_ID                 => it_lead.LEA_USER_ID
                               , iv_C_OPPORTUNITY_STATUS        => it_lead.C_OPPORTUNITY_STATUS
                               , iv_LEA_RESULT_COMMENT          => it_lead.LEA_RESULT_COMMENT
                               , iv_DIC_LEA_NEXT_STEP_ID        => it_lead.DIC_LEA_NEXT_STEP_ID
                               , iv_DIC_LEA_RATING_ID           => it_lead.DIC_LEA_RATING_ID
                               , iv_currency                    => it_lead.currency
                               , in_LEA_BUDGET_AMOUNT           => it_lead.LEA_BUDGET_AMOUNT
                               , id_LEA_OFFER_DEADLINE          => it_lead.LEA_OFFER_DEADLINE
                               , id_LEA_PROJECT_BEGIN_DATE      => it_lead.LEA_PROJECT_BEGIN_DATE
                               , id_LEA_PROJECT_END_DATE        => it_lead.LEA_PROJECT_END_DATE
                               , id_LEA_DATE                    => it_lead.LEA_DATE
                               , in_LEA_CONTACT_PERSON_ID       => it_lead.LEA_CONTACT_PERSON_ID
                               , iv_LEA_NEXT_STEP_DEADLINE      => it_lead.LEA_NEXT_STEP_DEADLINE
                               , iv_LEA_COMPANY_NAME            => it_lead.LEA_COMPANY_NAME
                               , iv_LEA_COMP_ADDRESS            => it_lead.LEA_COMP_ADDRESS
                               , iv_LEA_COMP_ZIPCODE            => it_lead.LEA_COMP_ZIPCODE
                               , iv_LEA_COMP_CITY               => it_lead.LEA_COMP_CITY
                               , iv_cntid                       => it_lead.cntid
                               , iv_lanid                       => it_lead.lanID
                               , iv_DIC_PERSON_POLITNESS_ID     => it_lead.DIC_PERSON_POLITNESS_ID
                               , iv_LEA_CONTACT_NAME            => it_lead.LEA_CONTACT_NAME
                               , iv_LEA_CONTACT_FORENAME        => it_lead.LEA_CONTACT_FORENAME
                               , iv_LEA_CONTACT_LANG_ID         => it_lead.LEA_CONTACT_LANG_ID
                               , iv_LEA_CONTACT_FUNCTION        => it_lead.LEA_CONTACT_FUNCTION
                               , iv_DIC_ASSOCIATION_TYPE_ID     => it_lead.DIC_ASSOCIATION_TYPE_ID
                               , iv_LEA_CONTACT_PHONE           => it_lead.LEA_CONTACT_PHONE
                               , iv_LEA_CONTACT_FAX             => it_lead.LEA_CONTACT_FAX
                               , iv_LEA_CONTACT_MOBILE          => it_lead.LEA_CONTACT_MOBILE
                               , iv_LEA_CONTACT_EMAIL           => it_lead.LEA_CONTACT_EMAIL
                               , iv_LEA_NUMBER                  => it_lead.LEA_NUMBER
                               , iv_DIC_LEA_PROJ_STEP_ID        => it_lead.DIC_LEA_PROJ_STEP_ID
                               , iv_DIC_LEA_REASON_ID           => it_lead.DIC_LEA_REASON_ID
                               , iv_DIC_LEA_REASON_2_ID         => it_lead.DIC_LEA_REASON_2_ID
                               , iv_LEA_REASON_COMMENT          => it_lead.LEA_REASON_COMMENT
                               , iv_DIC_LEA_REASON_CUST_ID      => it_lead.DIC_LEA_REASON_CUST_ID
                               , iv_DIC_LEA_REASON_CUST_2_ID    => it_lead.DIC_LEA_REASON_CUST_2_ID
                               , iv_LEA_REASON_COMMENT_CUST     => it_lead.LEA_REASON_COMMENT_CUST
                               , iv_DIC_LEA_CATEGORY_ID         => it_lead.DIC_LEA_CATEGORY_ID
                               , iv_DIC_LEA_SUBCATEGORY_ID      => it_lead.DIC_LEA_SUBCATEGORY_ID
                                );
      elsif iv_context = 'INSERT' then
        /* Appel à pac_e_prc_crm */
        ln_lead_id  :=
          PAC_E_PRC_CRM.CreateLEAD(in_PAC_PERSON_ID               => it_lead.PAC_PERSON_ID
                                 , iv_C_LEAD_STATUS               => it_lead.C_LEAD_STATUS
                                 , iv_LEA_LABEL                   => it_lead.LEA_LABEL
                                 , iv_LEA_COMMENT                 => it_lead.LEA_COMMENT
                                 , iv_DIC_LEA_SOURCE_ID           => it_lead.DIC_LEA_SOURCE_ID
                                 , iv_LEA_SOURCE_COMMENT          => it_lead.LEA_SOURCE_COMMENT
                                 , iv_LEA_SOURCE_NR               => it_lead.LEA_SOURCE_NR
                                 , iv_DIC_LEA_CLASSIFICATION_ID   => it_lead.DIC_LEA_CLASSIFICATION_ID
                                 , in_PAC_REPRESENTATIVE_ID       => it_lead.PAC_REPRESENTATIVE_ID
                                 , in_LEA_USER_ID                 => it_lead.LEA_USER_ID
                                 , iv_C_OPPORTUNITY_STATUS        => it_lead.C_OPPORTUNITY_STATUS
                                 , iv_LEA_RESULT_COMMENT          => it_lead.LEA_RESULT_COMMENT
                                 , iv_DIC_LEA_NEXT_STEP_ID        => it_lead.DIC_LEA_NEXT_STEP_ID
                                 , iv_DIC_LEA_RATING_ID           => it_lead.DIC_LEA_RATING_ID
                                 , iv_currency                    => it_lead.currency
                                 , in_LEA_BUDGET_AMOUNT           => it_lead.LEA_BUDGET_AMOUNT
                                 , id_LEA_OFFER_DEADLINE          => it_lead.LEA_OFFER_DEADLINE
                                 , id_LEA_PROJECT_BEGIN_DATE      => it_lead.LEA_PROJECT_BEGIN_DATE
                                 , id_LEA_PROJECT_END_DATE        => it_lead.LEA_PROJECT_END_DATE
                                 , id_LEA_DATE                    => it_lead.LEA_DATE
                                 , in_LEA_CONTACT_PERSON_ID       => it_lead.LEA_CONTACT_PERSON_ID
                                 , iv_LEA_NEXT_STEP_DEADLINE      => it_lead.LEA_NEXT_STEP_DEADLINE
                                 , iv_LEA_COMPANY_NAME            => it_lead.LEA_COMPANY_NAME
                                 , iv_LEA_COMP_ADDRESS            => it_lead.LEA_COMP_ADDRESS
                                 , iv_LEA_COMP_ZIPCODE            => it_lead.LEA_COMP_ZIPCODE
                                 , iv_LEA_COMP_CITY               => it_lead.LEA_COMP_CITY
                                 , iv_cntid                       => it_lead.cntid
                                 , iv_lanid                       => it_lead.lanID
                                 , iv_DIC_PERSON_POLITNESS_ID     => it_lead.DIC_PERSON_POLITNESS_ID
                                 , iv_LEA_CONTACT_NAME            => it_lead.LEA_CONTACT_NAME
                                 , iv_LEA_CONTACT_FORENAME        => it_lead.LEA_CONTACT_FORENAME
                                 , iv_LEA_CONTACT_LANG_ID         => it_lead.LEA_CONTACT_LANG_ID
                                 , iv_LEA_CONTACT_FUNCTION        => it_lead.LEA_CONTACT_FUNCTION
                                 , iv_DIC_ASSOCIATION_TYPE_ID     => it_lead.DIC_ASSOCIATION_TYPE_ID
                                 , iv_LEA_CONTACT_PHONE           => it_lead.LEA_CONTACT_PHONE
                                 , iv_LEA_CONTACT_FAX             => it_lead.LEA_CONTACT_FAX
                                 , iv_LEA_CONTACT_MOBILE          => it_lead.LEA_CONTACT_MOBILE
                                 , iv_LEA_CONTACT_EMAIL           => it_lead.LEA_CONTACT_EMAIL
                                 , iv_LEA_NUMBER                  => it_lead.LEA_NUMBER
                                 , iv_DIC_LEA_PROJ_STEP_ID        => it_lead.DIC_LEA_PROJ_STEP_ID
                                 , iv_DIC_LEA_REASON_ID           => it_lead.DIC_LEA_REASON_ID
                                 , iv_DIC_LEA_REASON_2_ID         => it_lead.DIC_LEA_REASON_2_ID
                                 , iv_LEA_REASON_COMMENT          => it_lead.LEA_REASON_COMMENT
                                 , iv_DIC_LEA_REASON_CUST_ID      => it_lead.DIC_LEA_REASON_CUST_ID
                                 , iv_DIC_LEA_REASON_CUST_2_ID    => it_lead.DIC_LEA_REASON_CUST_2_ID
                                 , iv_LEA_REASON_COMMENT_CUST     => it_lead.LEA_REASON_COMMENT_CUST
                                 , iv_DIC_LEA_CATEGORY_ID         => it_lead.DIC_LEA_CATEGORY_ID
                                 , iv_DIC_LEA_SUBCATEGORY_ID      => it_lead.DIC_LEA_SUBCATEGORY_ID
                                 , in_PAC_LEAD_ID                 => it_lead.PAC_LEAD_ID
                                  );
      end if;
    else
      /* Appel à pac_e_prc_crm pour faire le delete */
      PAC_E_PRC_CRM.DELETELEAD(IT_LEAD.PAC_LEAD_ID);
    end if;
  end crud_lead;

  procedure crud_lead_offer(it_lead_offer in MOB_LIB_VIEW_PAC.t_lead_offer, iv_context in varchar2)
  is
    lt_crud_def      fwk_i_typ_definition.T_CRUD_DEF;
    ln_lead_offer_id pac_lead_offer.pac_lead_offer_id%type;
  begin
    /*
      Prévoir ici un point d'entrée pour injecter du code, respectivement appeler une procédure individualisée
      de manière à traiter les données d'une manière particulière t.q. champs virtuels ou libres p.ex.
    */
    if nvl(it_lead_offer.a_deleted, 0) = 0 then
      if iv_context = 'UPDATE' then
        /* Appel à pac_e_prc_crm */
        PAC_E_PRC_CRM.UpdateLEAD_OFFER(in_PAC_LEAD_OFFER_ID             => it_lead_offer.PAC_LEAD_OFFER_ID
                                     , iv_LEO_NUMBER                    => it_lead_offer.LEO_NUMBER
                                     , in_PAC_LEAD_ID                   => it_lead_offer.PAC_LEAD_ID
                                     , id_LEO_DATE                      => it_lead_offer.LEO_DATE
                                     , iv_LEO_COMMENT                   => it_lead_offer.LEO_COMMENT
                                     , in_LEO_PRICE                     => it_lead_offer.LEO_PRICE
                                     , iv_currency                      => it_lead_offer.currency
                                     , in_DOC_DOCUMENT_ID               => it_lead_offer.DOC_DOCUMENT_ID
                                     , iv_C_LEO_STATUS                  => it_lead_offer.C_LEO_STATUS
                                     , iv_DIC_LEO_QUALIF_ID             => it_lead_offer.DIC_LEO_QUALIF_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE01_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE01_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE02_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE02_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE03_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE03_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE04_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE04_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE05_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE05_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE06_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE06_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE07_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE07_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE08_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE08_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE09_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE09_ID
                                     , iv_DIC_PAC_LEA_OFFER_FREE10_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE10_ID
                                     , iv_DIC_QUOTE_TYPE_ID             => it_lead_offer.DIC_QUOTE_TYPE_ID
                                      );
      elsif iv_context = 'INSERT' then
        /* Appel à pac_e_prc_crm */
        ln_lead_offer_id  :=
          PAC_E_PRC_CRM.CreateLEAD_OFFER(in_PAC_LEAD_OFFER_ID             => it_lead_offer.PAC_LEAD_OFFER_ID
                                       , iv_LEO_NUMBER                    => it_lead_offer.LEO_NUMBER
                                       , in_PAC_LEAD_ID                   => it_lead_offer.PAC_LEAD_ID
                                       , id_LEO_DATE                      => it_lead_offer.LEO_DATE
                                       , iv_LEO_COMMENT                   => it_lead_offer.LEO_COMMENT
                                       , in_LEO_PRICE                     => it_lead_offer.LEO_PRICE
                                       , iv_currency                      => it_lead_offer.currency
                                       , in_DOC_DOCUMENT_ID               => it_lead_offer.DOC_DOCUMENT_ID
                                       , iv_C_LEO_STATUS                  => it_lead_offer.C_LEO_STATUS
                                       , iv_DIC_LEO_QUALIF_ID             => it_lead_offer.DIC_LEO_QUALIF_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE01_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE01_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE02_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE02_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE03_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE03_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE04_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE04_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE05_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE05_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE06_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE06_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE07_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE07_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE08_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE08_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE09_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE09_ID
                                       , iv_DIC_PAC_LEA_OFFER_FREE10_ID   => it_lead_offer.DIC_PAC_LEAD_OFFER_FREE10_ID
                                       , iv_DIC_QUOTE_TYPE_ID             => it_lead_offer.DIC_QUOTE_TYPE_ID
                                        );
      end if;
    else
      /* Appel à pac_e_prc_crm pour faire le delete */
      PAC_E_PRC_CRM.DELETELEAD_OFFER(IT_LEAD_OFFER.PAC_LEAD_OFFER_ID);
    end if;
  end crud_lead_offer;

  procedure crud_lead_offer_good(it_lead_offer_good in MOB_LIB_VIEW_PAC.t_lead_offer_good, iv_context in varchar2)
  is
    lt_crud_def           fwk_i_typ_definition.T_CRUD_DEF;
    ln_lead_offer_good_id pac_lead_offer_good.pac_lead_offer_good_id%type;
  begin
    /*
      Prévoir ici un point d'entrée pour injecter du code, respectivement appeler une procédure individualisée
      de manière à traiter les données d'une manière particulière t.q. champs virtuels ou libres p.ex.
    */
    if nvl(it_lead_offer_good.a_deleted, 0) = 0 then
      if iv_context = 'UPDATE' then
        /* Appel à pac_e_prc_crm */
        PAC_E_PRC_CRM.UpdateLEAD_OFFER_GOOD(in_PAC_LEAD_OFFER_GOOD_ID   => it_lead_offer_good.PAC_LEAD_OFFER_GOOD_ID
                                          , in_PAC_LEAD_OFFER_ID        => it_lead_offer_good.PAC_LEAD_OFFER_ID
                                          , in_GCO_GOOD_ID              => it_lead_offer_good.GCO_GOOD_ID
                                          , iv_LEO_GOOD_DESCR           => it_lead_offer_good.LEO_GOOD_DESCR
                                          , iv_LEO_GOOD_COMMENT         => it_lead_offer_good.LEO_GOOD_COMMENT
                                          , in_LEO_GOOD_PRICE           => it_lead_offer_good.LEO_GOOD_PRICE
                                          , in_DOC_POSITION_ID          => it_lead_offer_good.DOC_POSITION_ID
                                          , in_LEO_GOOD_QTY             => it_lead_offer_good.LEO_GOOD_QTY
                                          , in_LEO_GOOD_UNIT_PRICE      => it_lead_offer_good.LEO_GOOD_UNIT_PRICE
                                           );
      elsif iv_context = 'INSERT' then
        /* Appel à pac_e_prc_crm */
        ln_lead_offer_good_id  :=
          PAC_E_PRC_CRM.CreateLEAD_OFFER_GOOD(in_PAC_LEAD_OFFER_GOOD_ID   => it_lead_offer_good.PAC_LEAD_OFFER_GOOD_ID
                                            , in_PAC_LEAD_OFFER_ID        => it_lead_offer_good.PAC_LEAD_OFFER_ID
                                            , in_GCO_GOOD_ID              => it_lead_offer_good.GCO_GOOD_ID
                                            , iv_LEO_GOOD_DESCR           => it_lead_offer_good.LEO_GOOD_DESCR
                                            , iv_LEO_GOOD_COMMENT         => it_lead_offer_good.LEO_GOOD_COMMENT
                                            , in_LEO_GOOD_PRICE           => it_lead_offer_good.LEO_GOOD_PRICE
                                            , in_DOC_POSITION_ID          => it_lead_offer_good.DOC_POSITION_ID
                                            , in_LEO_GOOD_QTY             => it_lead_offer_good.LEO_GOOD_QTY
                                            , in_LEO_GOOD_UNIT_PRICE      => it_lead_offer_good.LEO_GOOD_UNIT_PRICE
                                             );
      end if;
    else
      /* Appel à pac_e_prc_crm pour faire le delete */
      PAC_E_PRC_CRM.DELETELEAD_OFFER_GOOD(IT_LEAD_OFFER_GOOD.PAC_LEAD_OFFER_GOOD_ID);
    end if;
  end crud_lead_offer_good;
end MOB_PRC_VIEW_PAC;
