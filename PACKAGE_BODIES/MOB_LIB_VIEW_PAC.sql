--------------------------------------------------------
--  DDL for Package Body MOB_LIB_VIEW_PAC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MOB_LIB_VIEW_PAC" 
is
  function persons
    return tt_person pipelined
  is
    type t_ref_cursor is ref cursor;

    lcur_ref  t_ref_cursor;
    ltpl_pers t_person;
    lv_Select varchar2(4000);
  begin
    lv_Select  :=
      'SELECT PAC_PERSON_ID, DIC_PERSON_POLITNESS_ID, PER_NAME, PER_FORENAME, PER_ACTIVITY, PER_COMMENT, PER_KEY1, PER_KEY2, DIC_FREE_CODE1_ID, DIC_FREE_CODE2_ID, DIC_FREE_CODE3_ID, DIC_FREE_CODE4_ID, DIC_FREE_CODE5_ID, DIC_FREE_CODE6_ID, DIC_FREE_CODE7_ID, DIC_FREE_CODE8_ID, DIC_FREE_CODE9_ID, DIC_FREE_CODE10_ID, PER_SHORT_NAME, PER_CONTACT, C_PARTNER_STATUS, PCO_DESCR, REP_DESCR, DIC_TARIFF_ID,a_deleted,a_datemod, a_idmod ';

    if pcs.pc_public.getconfig('MOB_PERSON_VIEW') is not null then
      open lcur_ref for lv_Select || ' FROM ' || pcs.pc_public.getconfig('MOB_PERSON_VIEW');
    else
      open lcur_ref for
        select p.PAC_PERSON_ID
             , DIC_PERSON_POLITNESS_ID
             , PER_NAME
             , PER_FORENAME
             , PER_ACTIVITY
             , PER_COMMENT
             , PER_KEY1
             , PER_KEY2
             , DIC_FREE_CODE1_ID
             , DIC_FREE_CODE2_ID
             , DIC_FREE_CODE3_ID
             , DIC_FREE_CODE4_ID
             , DIC_FREE_CODE5_ID
             , DIC_FREE_CODE6_ID
             , DIC_FREE_CODE7_ID
             , DIC_FREE_CODE8_ID
             , DIC_FREE_CODE9_ID
             , DIC_FREE_CODE10_ID
             , PER_SHORT_NAME
             , PER_CONTACT
             , p.C_PARTNER_STATUS
             , pco_descr
             , rep_descr
             , dic_tariff_id
             , 0 A_DELETED
             , nvl(p.a_datemod, p.a_datecre)
             , nvl(p.a_idmod, p.a_idcre)
          from pac_person p
             , pac_custom_partner c
             , pac_payment_condition pc
             , pac_representative r
         where p.pac_person_id = pac_custom_partner_id(+)
           and c.pac_payment_condition_id = pc.pac_payment_condition_id(+)
           and c.pac_representative_id = r.pac_representative_id(+);
    end if;

    loop
      fetch lcur_ref
       into ltpl_pers.PAC_PERSON_ID
          , ltpl_pers.DIC_PERSON_POLITNESS_ID
          , ltpl_pers.PER_NAME
          , ltpl_pers.PER_FORENAME
          , ltpl_pers.PER_ACTIVITY
          , ltpl_pers.PER_COMMENT
          , ltpl_pers.PER_KEY1
          , ltpl_pers.PER_KEY2
          , ltpl_pers.DIC_FREE_CODE1_ID
          , ltpl_pers.DIC_FREE_CODE2_ID
          , ltpl_pers.DIC_FREE_CODE3_ID
          , ltpl_pers.DIC_FREE_CODE4_ID
          , ltpl_pers.DIC_FREE_CODE5_ID
          , ltpl_pers.DIC_FREE_CODE6_ID
          , ltpl_pers.DIC_FREE_CODE7_ID
          , ltpl_pers.DIC_FREE_CODE8_ID
          , ltpl_pers.DIC_FREE_CODE9_ID
          , ltpl_pers.DIC_FREE_CODE10_ID
          , ltpl_pers.PER_SHORT_NAME
          , ltpl_pers.PER_CONTACT
          , ltpl_pers.C_PARTNER_STATUS
          , ltpl_pers.PCO_DESCR
          , ltpl_pers.REP_DESCR
          , ltpl_pers.DIC_TARIFF_ID
          , ltpl_pers.a_deleted
          , ltpl_pers.a_datemod
          , ltpl_pers.a_idmod;

      exit when lcur_ref%notfound;
      pipe row(ltpl_pers);
    end loop;

    close lcur_ref;
  exception
    when NO_DATA_NEEDED then
      return;
  end persons;

  function communications
    return tt_communication pipelined
  is
    type t_ref_cursor is ref cursor;

    lcur_ref  t_ref_cursor;
    ltpl_com  t_communication;
    lv_Select varchar2(4000);
  begin
    lv_Select  := 'SELECT PAC_COMMUNICATION_ID, PAC_PERSON_ID, DIC_COMMUNICATION_TYPE_ID, COM_EXT_NUMBER,A_DELETED,
      a_DATEMOD,
      A_IDMOD';

    if pcs.pc_public.getconfig('MOB_COMMUNICATION_VIEW') is not null then
      open lcur_ref for lv_Select || ' FROM ' || pcs.pc_public.getconfig('MOB_COMMUNICATION_VIEW');
    else
      open lcur_ref for
        select pac_communication_id
             , PAC_PERSON_ID
             , DIC_COMMUNICATION_TYPE_ID
             , COM_EXT_NUMBER
             , 0 A_DELETED
             , nvl(a_datemod, a_datecre)
             , nvl(a_idmod, a_idcre)
          from PAC_COMMUNICATION;
    end if;

    loop
      fetch lcur_ref
       into ltpl_com.pac_communication_id
          , ltpl_com.PAC_PERSON_ID
          , ltpl_com.DIC_COMMUNICATION_TYPE_ID
          , ltpl_com.COM_EXT_NUMBER
          , ltpl_com.a_deleted
          , ltpl_com.a_datemod
          , ltpl_com.a_idmod;

      exit when lcur_ref%notfound;
      pipe row(ltpl_com);
    end loop;

    close lcur_ref;
  exception
    when NO_DATA_NEEDED then
      return;
  end communications;

  function addresses
    return tt_address pipelined
  is
    type t_ref_cursor is ref cursor;

    lcur_ref  t_ref_cursor;
    ltpl_adr  t_address;
    lv_Select varchar2(4000);
  begin
    lv_Select  :=
                 'SELECT PAC_ADDRESS_ID,PAC_PERSON_ID,CNTID,ADD_ADDRESS1,ADD_ZIPCODE,ADD_CITY,ADD_STATE,LANID ,DIC_ADDRESS_TYPE_ID,A_DELETED,a_DATEMOD,A_IDMOD';

    if pcs.pc_public.getconfig('MOB_ADDRESS_VIEW') is not null then
      open lcur_ref for lv_Select || ' FROM ' || pcs.pc_public.getconfig('MOB_ADDRESS_VIEW');
    else
      open lcur_ref for
        select PAC_ADDRESS_ID
             , PAC_PERSON_ID
             , (select CNTID
                  from PCS.PC_CNTRY C
                 where A.PC_CNTRY_ID = C.PC_CNTRY_ID) CNTID
             , ADD_ADDRESS1
             , ADD_ZIPCODE
             , ADD_CITY
             , ADD_STATE
             , (select LANID
                  from PCS.PC_LANG L
                 where A.PC_LANG_ID = L.PC_LANG_ID) LANID
             , DIC_ADDRESS_TYPE_ID
             , 0 A_DELETED
             , nvl(A_DATEMOD, A_DATECRE) A_DATEMOD
             , nvl(A_IDMOD, A_IDCRE) A_IDMOD
          from PAC_ADDRESS A;
    end if;

    loop
      fetch lcur_ref
       into ltpl_adr.PAC_ADDRESS_ID
          , ltpl_adr.PAC_PERSON_ID
          , ltpl_adr.CNTID
          , ltpl_adr.ADD_ADDRESS1
          , ltpl_adr.ADD_ZIPCODE
          , ltpl_adr.ADD_CITY
          , ltpl_adr.ADD_STATE
          , ltpl_adr.LANID
          , ltpl_adr.DIC_ADDRESS_TYPE_ID
          , ltpl_adr.a_deleted
          , ltpl_adr.a_datemod
          , ltpl_adr.a_idmod;

      exit when lcur_ref%notfound;
      pipe row(ltpl_adr);
    end loop;

    close lcur_ref;
  exception
    when NO_DATA_NEEDED then
      return;
  end addresses;

  function country_id(iv_cntid in pcs.pc_cntry.cntid%type)
    return pcs.pc_cntry.pc_cntry_id%type
  is
    ln_result pcs.pc_cntry.pc_cntry_id%type;
  begin
    select pc_cntry_id
      into ln_result
      from pcs.pc_cntry
     where cntid = iv_cntid;

    return ln_result;
  end country_id;

  /**
  * Description
  *   retourne 1 si le user a le droit de visionner le record
  */
  function LeadFilter(iLeadId in PAC_LEAD.PAC_LEAD_ID%type)
    return number
  is
    lConfig varchar2(61) := PCS.PC_CONFIG.GetConfig('MOB_LEAD_FILTER_PROC');
    lResult number(1) := 1;
  begin
    if lConfig is not null then
      execute immediate 'select '||lConfig||'(:LEAD_ID) from dual' into lResult using iLeadId;
    end if;
    return lResult;
  end LeadFilter;

  /**
  * Description
  *   retourne 1 si le user a le droit de visionner le record
  */
  function EventFilter(iEventId in PAC_EVENT.PAC_EVENT_ID%type)
    return number
  is
    lConfig varchar2(61) := PCS.PC_CONFIG.GetConfig('MOB_EVENTS_FILTER_PROC');
    lResult number(1) := 1;
  begin
    if lConfig is not null then
      execute immediate 'select '||lConfig||'(:EVENT_ID) from dual' into lResult using iEventId;
    end if;
    return lResult;
  end EventFilter;

  /**
  * Description
  *   fonctions permettant de filter les record du user courant
  *   Se baser sur ces fonctions afin de créer des proc indiv plus pointues
  *   en clientèle
  */
  function MyLeadFilter(iLeadId in PAC_LEAD.PAC_LEAD_ID%type)
    return number
  is
    lUserId PCS.PC_USER.PC_USER_ID%type := FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'PAC_LEAD', iv_column_name => 'LEA_USER_ID', it_pk_value => iLeadId);
  begin
    if lUserId = PCS.PC_I_LIB_SESSION.GetUserId then
      return 1;
    else
      return 0;
    end if;
  end MyLeadFilter;

  function MyEventsFilter(iEventId in PAC_EVENT.PAC_EVENT_ID%type)
    return number
  is
    lUserId PCS.PC_USER.PC_USER_ID%type := FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'PAC_EVENT', iv_column_name => 'EVE_USER_ID', it_pk_value => iEventId);
  begin
    if lUserId = PCS.PC_I_LIB_SESSION.GetUserId then
      return 1;
    else
      return 0;
    end if;
  end MyEventsFilter;


end MOB_LIB_VIEW_PAC;
