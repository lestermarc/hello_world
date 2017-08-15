--------------------------------------------------------
--  DDL for Package Body ASA_PRC_GUARANTY_CARDS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_GUARANTY_CARDS" 
is
  /**
  * procedure InitFromRecord
  * Description
  *   Création d'une carte de garantie à partir d'un dossier de réparation
  * @author AGA
  * @created 09.2011
  * @lastUpdate
  * @public
  * @param iotGuarantyCard : enregistrement actif
  * @param iASA_RECORD_ID : dossier de réparation;
  */
  procedure InitFromRecord(iotGuarantyCard in out nocopy fwk_i_typ_definition.t_crud_def, aASA_RECORD_ID in ASA_RECORD.ASA_RECORD_ID%type)
  is
    cursor crRec
    is
      select *
        from ASA_RECORD
       where ASA_RECORD_ID = aASA_RECORD_ID;

    tplRec crRec%rowtype;
  begin
    /*
    si la carte de garantie est créée à partir d'un dossier de réparation
    on initialise les données à partir du dossier de réparation
    */
    open crRec;

    fetch crRec
     into tplRec;

    if crRec%found then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_GOOD_ID', tplRec.GCO_ASA_TO_REPAIR_ID, tplRec.GCO_ASA_TO_REPAIR_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'DOC_POSITION_ID', tplRec.DOC_ORIGIN_POSITION_ID, tplRec.DOC_ORIGIN_POSITION_ID is not null);
      -- initialisation des caractérisations
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR1_ID', tplRec.GCO_CHAR1_ID, tplRec.GCO_CHAR1_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR2_ID', tplRec.GCO_CHAR2_ID, tplRec.GCO_CHAR2_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR3_ID', tplRec.GCO_CHAR3_ID, tplRec.GCO_CHAR3_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR4_ID', tplRec.GCO_CHAR4_ID, tplRec.GCO_CHAR4_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR5_ID', tplRec.GCO_CHAR5_ID, tplRec.GCO_CHAR5_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CHAR1_VALUE', tplRec.ARE_CHAR1_VALUE, tplRec.ARE_CHAR1_VALUE is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CHAR2_VALUE', tplRec.ARE_CHAR2_VALUE, tplRec.ARE_CHAR2_VALUE is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CHAR3_VALUE', tplRec.ARE_CHAR3_VALUE, tplRec.ARE_CHAR3_VALUE is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CHAR4_VALUE', tplRec.ARE_CHAR4_VALUE, tplRec.ARE_CHAR4_VALUE is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CHAR5_VALUE', tplRec.ARE_CHAR5_VALUE, tplRec.ARE_CHAR5_VALUE is not null);
      -- distributeur adresse
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PAC_ASA_DISTRIB_ID', tplRec.PAC_CUSTOM_PARTNER_ID, tplRec.PAC_CUSTOM_PARTNER_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_DISTRIB_LANG_ID', tplRec.PC_ASA_CUST_LANG_ID, tplRec.PC_ASA_CUST_LANG_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PAC_ASA_DISTRIB_ADDR_ID', tplRec.PAC_ASA_ADDR1_ID, tplRec.PAC_ASA_ADDR1_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_ADDRESS_DISTRIB', tplRec.ARE_ADDRESS1, tplRec.ARE_ADDRESS1 is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_POSTCODE_DISTRIB', tplRec.ARE_POSTCODE1, tplRec.ARE_POSTCODE1 is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_TOWN_DISTRIB', tplRec.ARE_TOWN1, tplRec.ARE_TOWN1 is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_STATE_DISTRIB', tplRec.ARE_STATE1, tplRec.ARE_STATE1 is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_FORMAT_CITY_DISTRIB', tplRec.ARE_FORMAT_CITY1, tplRec.ARE_FORMAT_CITY1 is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_DISTRIB_CNTRY_ID', tplRec.PC_ASA_CNTRY1_ID, tplRec.PC_ASA_CNTRY1_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CARE_OF_DET', tplRec.ARE_CARE_OF_DET, tplRec.ARE_CARE_OF_DET is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_DET', tplRec.ARE_PO_BOX_DET, tplRec.ARE_PO_BOX_DET is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_NBR_DET', tplRec.ARE_PO_BOX_NBR_DET, tplRec.ARE_PO_BOX_NBR_DET is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_COUNTY_DET', tplRec.ARE_COUNTY_DET, tplRec.ARE_COUNTY_DET is not null);
      -- distributeur / détaillant dates de garantie
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_SALEDATE_DET', tplRec.ARE_DET_SALE_DATE, tplRec.ARE_DET_SALE_DATE is not null);
      -- client final adresse
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PAC_ASA_FIN_CUST_ID', tplRec.PAC_ASA_FIN_CUST_ID, tplRec.PAC_ASA_FIN_CUST_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_FIN_CUST_LANG_ID', tplRec.PC_ASA_CUST_LANG_ID, tplRec.PC_ASA_CUST_LANG_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PAC_ASA_FIN_CUST_ADDR_ID', tplRec.PAC_ASA_FIN_CUST_ADDR_ID
                                    , tplRec.PAC_ASA_FIN_CUST_ADDR_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_ADDRESS_FIN_CUST', tplRec.ARE_ADDRESS_FIN_CUST, tplRec.ARE_ADDRESS_FIN_CUST is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_POSTCODE_FIN_CUST', tplRec.ARE_POSTCODE_FIN_CUST, tplRec.ARE_POSTCODE_FIN_CUST is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_TOWN_FIN_CUST', tplRec.ARE_TOWN_FIN_CUST, tplRec.ARE_TOWN_FIN_CUST is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_STATE_FIN_CUST', tplRec.ARE_STATE_FIN_CUST, tplRec.ARE_STATE_FIN_CUST is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_FORMAT_CITY_FIN_CUST', tplRec.ARE_FORMAT_CITY_FIN_CUST
                                    , tplRec.ARE_FORMAT_CITY_FIN_CUST is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_FIN_CUST_CNTRY_ID', tplRec.PC_ASA_FIN_CUST_CNTRY_ID
                                    , tplRec.PC_ASA_FIN_CUST_CNTRY_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CARE_OF_CUST', tplRec.ARE_CARE_OF_CUST, tplRec.ARE_CARE_OF_CUST is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_CUST', tplRec.ARE_PO_BOX_CUST, tplRec.ARE_PO_BOX_CUST is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_NBR_CUST', tplRec.ARE_PO_BOX_NBR_CUST, tplRec.ARE_PO_BOX_NBR_CUST is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_COUNTY_CUST', tplRec.ARE_COUNTY_CUST, tplRec.ARE_COUNTY_CUST is not null);
      -- Clent final dates garantie
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_SALEDATE', tplRec.ARE_FIN_SALE_DATE, tplRec.ARE_FIN_SALE_DATE is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_BEGIN', tplRec.ARE_BEGIN_GUARANTY_DATE, tplRec.ARE_BEGIN_GUARANTY_DATE is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_DAYS', tplRec.ARE_GUARANTY, tplRec.ARE_GUARANTY is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_END', tplRec.ARE_END_GUARANTY_DATE, tplRec.ARE_END_GUARANTY_DATE is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'C_ASA_GUARANTY_UNIT', tplRec.C_ASA_GUARANTY_UNIT, tplRec.C_ASA_GUARANTY_UNIT is not null);
      --Agent
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PAC_ASA_AGENT_ID', tplRec.PAC_ASA_AGENT_ID, tplRec.PAC_ASA_AGENT_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_AGENT_LANG_ID', tplRec.PC_ASA_CUST_LANG_ID, tplRec.PC_ASA_CUST_LANG_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PAC_ASA_AGENT_ADDR_ID', tplRec.PAC_ASA_AGENT_ADDR_ID, tplRec.PAC_ASA_AGENT_ADDR_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_ADDRESS_AGENT', tplRec.ARE_ADDRESS_AGENT, tplRec.ARE_ADDRESS_AGENT is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_POSTCODE_AGENT', tplRec.ARE_POSTCODE_AGENT, tplRec.ARE_POSTCODE_AGENT is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_TOWN_AGENT', tplRec.ARE_TOWN_AGENT, tplRec.ARE_TOWN_AGENT is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_STATE_AGENT', tplRec.ARE_STATE_AGENT, tplRec.ARE_STATE_AGENT is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_FORMAT_CITY_AGENT', tplRec.ARE_FORMAT_CITY_AGENT, tplRec.ARE_FORMAT_CITY_AGENT is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_AGENT_CNTRY_ID', tplRec.PC_ASA_AGENT_CNTRY_ID, tplRec.PC_ASA_AGENT_CNTRY_ID is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CARE_OF_AGENT', tplRec.ARE_CARE_OF_AGENT, tplRec.ARE_CARE_OF_AGENT is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_AGENT', tplRec.ARE_PO_BOX_AGENT, tplRec.ARE_PO_BOX_AGENT is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_NBR_AGENT', tplRec.ARE_PO_BOX_NBR_AGENT is not null);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_COUNTY_AGENT', tplRec.ARE_COUNTY_AGENT, tplRec.ARE_COUNTY_AGENT is not null);
      -- agent dates de garantie
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_SALEDATE_AGENT', tplRec.ARE_SALE_DATE, tplRec.ARE_SALE_DATE is not null);
    end if;

    close crRec;
  end InitFromRecord;

  /**
  * procedure CheckGoodData
  * Description
  *   Initialisation des données liées au bien de la garantie
  * @author AGA
  * @created 09.2011
  * @lastUpdate
  * @public
  * @param iGoodId : Bien de la carte de garantie
  * @param iotGuarantyCard : enregistrement actif
  */
  procedure CheckGoodData(iGoodId GCO_GOOD.GCO_GOOD_ID%type, iotGuarantyCard in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    cursor crCodes
    is
      select   CAS_GUARANTEE_DELAY
             , C_ASA_GUARANTY_UNIT
             , CAS_SER_PERIODICITY
             , C_ASA_SERVICE_UNIT
          from GCO_COMPL_DATA_ASS
         where GCO_GOOD_ID = iGoodId
      order by nvl(CAS_DEFAULT_REPAIR, 0) desc;

    tplCodes crCodes%rowtype;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'GCO_GOOD_ID') then
      open crCodes;

      fetch crCodes
       into tplCodes;

      if crCodes%found then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard
                                      , 'AGC_DAYS'
                                      , tplCodes.CAS_GUARANTEE_DELAY
                                      ,     not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_DAYS')
                                        and tplCodes.CAS_GUARANTEE_DELAY is not null
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard
                                      , 'C_ASA_GUARANTY_UNIT'
                                      , tplCodes.C_ASA_GUARANTY_UNIT
                                      ,     not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'C_ASA_GUARANTY_UNIT')
                                        and tplCodes.C_ASA_GUARANTY_UNIT is not null
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard
                                      , 'AGC_SER_PERIODICITY'
                                      , tplCodes.CAS_SER_PERIODICITY
                                      ,     not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_SER_PERIODICITY')
                                        and tplCodes.CAS_SER_PERIODICITY is not null
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard
                                      , 'C_ASA_SERVICE_UNIT'
                                      , tplCodes.C_ASA_SERVICE_UNIT
                                      ,     not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'C_ASA_SERVICE_UNIT')
                                        and tplCodes.C_ASA_SERVICE_UNIT is not null
                                       );
      end if;

      close crCodes;
    end if;
  end CheckGoodData;

  /**
  * procedure CheckThirdsData
  * Description
  *   Initialisation des données liées au tiers (Code langue et adresse)
  * @author AGA
  * @created 09.2011
  * @lastUpdate
  * @public
  * @param iotGuarantyCard : enregistrement actif
  */
  procedure CheckThirdsData(iotGuarantyCard in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    type TAdress is record(
      address1 PAC_ADDRESS.ADD_ADDRESS1%type
    , zipcode  PAC_ADDRESS.ADD_ZIPCODE%type
    , city     PAC_ADDRESS.ADD_CITY%type
    , state    PAC_ADDRESS.ADD_STATE%type
    , careof   PAC_ADDRESS.ADD_CARE_OF%type
    , pobox    PAC_ADDRESS.ADD_PO_BOX%type
    , poboxnbr PAC_ADDRESS.ADD_PO_BOX_NBR%type
    , county   PAC_ADDRESS.ADD_COUNTY%type
    , addrId   PAC_ADDRESS.PAC_ADDRESS_ID%type
    , cntryId  PAC_ADDRESS.PC_CNTRY_ID%type
    , langId   PAC_ADDRESS.PC_LANG_ID%type
    , adrmode  integer
    );

    lAddressSql varchar2(1000)
      := 'SELECT ' ||
         '       ADD_ADDRESS1, ' ||
         '       ADD_ZIPCODE, ' ||
         '       ADD_CITY, ' ||
         '       ADD_STATE, ' ||
         '       ADD_CARE_OF, ' ||
         '       ADD_PO_BOX, ' ||
         '       ADD_PO_BOX_NBR, ' ||
         '       ADD_COUNTY, ' ||
         '       PAC_ADDRESS_ID, ' ||
         '       PC_CNTRY_ID, ' ||
         '       PC_LANG_ID, ' ||
         '       1 ADRMODE ' ||
         '  FROM PAC_ADDRESS ' ||
         ' WHERE PAC_ADDRESS.DIC_ADDRESS_TYPE_ID = PAC_I_LIB_LOOKUP.getDIC_ADDRESS_TYPE_DEFAULT ' ||
         '       AND PAC_ADDRESS.ADD_PRINCIPAL   = 1 ' ||
         '       AND PAC_ADDRESS.PAC_PERSON_ID   = :PAC_PERSON_ID ';
    lAdd        TAdress;
  begin
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'PAC_ASA_DISTRIB_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotGuarantyCard, 'PAC_ASA_DISTRIB_ID') then
      begin
        execute immediate lAddressSql
                     into lAdd
                    using FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'PAC_ASA_DISTRIB_ID');

        if lAdd.LangId is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_DISTRIB_LANG_ID', lAdd.langid);
        else
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_DISTRIB_LANG_ID', PCS.PC_I_LIB_SESSION.GetUserLangId);
        end if;

        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PAC_ASA_DISTRIB_ADDR_ID', lAdd.addrid);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_ADDRESS_DISTRIB', lAdd.address1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_POSTCODE_DISTRIB', lAdd.zipcode);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_TOWN_DISTRIB', lAdd.city);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_STATE_DISTRIB', lAdd.state);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_DISTRIB_CNTRY_ID', lAdd.cntryid);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CARE_OF_DET', lAdd.careof);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_DET', lAdd.pobox);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_NBR_DET', lAdd.poboxnbr);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_COUNTY_DET', lAdd.county);
      exception
        when no_data_found then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'PAC_ASA_DISTRIB_ID');
      end;
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'PAC_ASA_AGENT_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotGuarantyCard, 'PAC_ASA_AGENT_ID') then
      begin
        execute immediate lAddressSql
                     into lAdd
                    using FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'PAC_ASA_AGENT_ID');

        if lAdd.LangId is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_AGENT_LANG_ID', lAdd.langid);
        else
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_AGENT_LANG_ID', PCS.PC_I_LIB_SESSION.GetUserLangId);
        end if;

        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PAC_ASA_AGENT_ADDR_ID', lAdd.addrid);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_ADDRESS_AGENT', lAdd.address1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_POSTCODE_AGENT', lAdd.zipcode);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_TOWN_AGENT', lAdd.city);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_STATE_AGENT', lAdd.state);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_AGENT_CNTRY_ID', lAdd.cntryid);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CARE_OF_AGENT', lAdd.careof);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_AGENT', lAdd.pobox);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_NBR_AGENT', lAdd.poboxnbr);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_COUNTY_AGENT', lAdd.county);
      exception
        when no_data_found then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'PAC_ASA_AGENT_ID');
      end;
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'PAC_ASA_FIN_CUST_ID')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotGuarantyCard, 'PAC_ASA_FIN_CUST_ID') then
      begin
        execute immediate lAddressSql
                     into lAdd
                    using FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'PAC_ASA_FIN_CUST_ID');

        if lAdd.LangId is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_FIN_CUST_LANG_ID', lAdd.langid);
        else
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_FIN_CUST_LANG_ID', PCS.PC_I_LIB_SESSION.GetUserLangId);
        end if;

        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PAC_ASA_FIN_CUST_ADDR_ID', lAdd.addrid);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_ADDRESS_FIN_CUST', lAdd.address1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_POSTCODE_FIN_CUST', lAdd.zipcode);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_TOWN_FIN_CUST', lAdd.city);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_STATE_FIN_CUST', lAdd.state);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'PC_ASA_FIN_CUST_CNTRY_ID', lAdd.cntryid);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_CARE_OF_CUST', lAdd.careof);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_CUST', lAdd.pobox);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_PO_BOX_NBR_CUST', lAdd.poboxnbr);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_COUNTY_CUST', lAdd.county);
      exception
        when no_data_found then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'PAC_ASA_FIN_CUST_ID');
      end;
    end if;
  end CheckThirdsData;

  /**
  * procedure CheckCharact
  * Description
  *   Initialisation des données liées aux caractérisations du bien
  * @author AGA
  * @created 09.2011
  * @lastUpdate
  * @public
  * @param iotGuarantyCard : enregistrement actif
  */
  procedure CheckCharact(iotGuarantyCard in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lnCharactID_1 DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type;
    lnCharactID_2 DOC_POSITION_DETAIL.GCO_GCO_CHARACTERIZATION_ID%type;
    lnCharactID_3 DOC_POSITION_DETAIL.GCO2_GCO_CHARACTERIZATION_ID%type;
    lnCharactID_4 DOC_POSITION_DETAIL.GCO3_GCO_CHARACTERIZATION_ID%type;
    lnCharactID_5 DOC_POSITION_DETAIL.GCO4_GCO_CHARACTERIZATION_ID%type;
    lId           GCO_GOOD.GCO_GOOD_ID%type;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'GCO_GOOD_ID') then
      -- initialisation des caractérisations
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR1_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR2_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR3_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR4_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR5_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'AGC_CHAR1_VALUE', not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_CHAR1_VALUE') );
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'AGC_CHAR2_VALUE', not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_CHAR2_VALUE') );
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'AGC_CHAR3_VALUE', not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_CHAR3_VALUE') );
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'AGC_CHAR4_VALUE', not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_CHAR4_VALUE') );
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'AGC_CHAR5_VALUE', not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_CHAR5_VALUE') );
    end if;

    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotGuarantyCard, 'GCO_GOOD_ID') then
      lid  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'GCO_GOOD_ID');
      GCO_I_LIB_CHARACTERIZATION.GetCharacterizationsID(lId
                                                      , null
                                                      , null
                                                      , 1
                                                      , '2'   -- domaine des ventes
                                                      , lnCharactID_1
                                                      , lnCharactID_2
                                                      , lnCharactID_3
                                                      , lnCharactID_4
                                                      , lnCharactID_5
                                                       );

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotGuarantyCard, 'AGC_CHAR1_VALUE') then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR1_ID');
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR1_ID', lnCharactID_1);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotGuarantyCard, 'AGC_CHAR2_VALUE') then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR2_ID');
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR2_ID', lnCharactID_2);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotGuarantyCard, 'AGC_CHAR3_VALUE') then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR3_ID');
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR3_ID', lnCharactID_3);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotGuarantyCard, 'AGC_CHAR4_VALUE') then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR4_ID');
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR4_ID', lnCharactID_4);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotGuarantyCard, 'AGC_CHAR5_VALUE') then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotGuarantyCard, 'GCO_CHAR5_ID');
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'GCO_CHAR5_ID', lnCharactID_5);
      end if;
    end if;
  end CheckCharact;

  /**
  * procedure CheckDates
  * Description
  *   Initialisation des données liées aux dates et durée de garantie et services
  * @author AGA
  * @created 09.2011
  * @lastUpdate
  * @public
  * @param iotGuarantyCard : enregistrement actif
  */
  procedure CheckDates(iotGuarantyCard in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ldEnd ASA_GUARANTY_CARDS.AGC_END%type;
    lRec  FWK_TYP_ASA_ENTITY.tGuarantyCards := FWK_TYP_ASA_ENTITY.gttGuarantyCards(iotGuarantyCard.entity_id);
  begin
    if     lRec.AGC_SALEDATE is not null
       and lRec.AGC_BEGIN is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_BEGIN', lRec.AGC_SALEDATE);
      lRec  := FWK_TYP_ASA_ENTITY.gttGuarantyCards(iotGuarantyCard.entity_id);
    end if;

    if    (    FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_DAYS')
           and lRec.AGC_DAYS is not null)
       or (    FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_BEGIN')
           and lRec.AGC_BEGIN is not null)
       or (    FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'C_ASA_GUARANTY_UNIT')
           and lRec.C_ASA_GUARANTY_UNIT is not null) then
      if lRec.C_ASA_GUARANTY_UNIT = 'D' then   -- unité de garantie en jour
        ldEnd  := lRec.AGC_BEGIN + lRec.AGC_DAYS;
      elsif lRec.C_ASA_GUARANTY_UNIT = 'M' then   -- unité de garantie en mois
        ldEnd  := add_months(lRec.AGC_BEGIN, lRec.AGC_DAYS);
      elsif lRec.C_ASA_GUARANTY_UNIT = 'Y' then   -- unité de garantie en années
        ldEnd  := add_months(lRec.AGC_BEGIN,(lRec.AGC_DAYS * 12) );
      elsif lRec.C_ASA_GUARANTY_UNIT = 'W' then   -- unité de garantie en semaine
        ldEnd  := lRec.AGC_BEGIN +(lRec.AGC_DAYS * 7);
      end if;

      if ldEnd is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_END', ldEnd);
      end if;
    end if;

    if    (    FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_LAST_SERVICE_DATE')
           and lRec.AGC_LAST_SERVICE_DATE is not null)
       or (    FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_SER_PERIODICITY')
           and lRec.AGC_SER_PERIODICITY is not null)
       or (    FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'C_ASA_SERVICE_UNIT')
           and lRec.C_ASA_SERVICE_UNIT is not null) then
      if lRec.C_ASA_SERVICE_UNIT = 'D' then   -- unité de garantie en jour
        ldEnd  := lRec.AGC_LAST_SERVICE_DATE + lRec.AGC_SER_PERIODICITY;
      elsif lRec.C_ASA_SERVICE_UNIT = 'M' then   -- unité de garantie en mois
        ldEnd  := add_months(lRec.AGC_LAST_SERVICE_DATE, lRec.AGC_SER_PERIODICITY);
      elsif lRec.C_ASA_SERVICE_UNIT = 'Y' then   -- unité de garantie en années
        ldEnd  := add_months(lRec.AGC_LAST_SERVICE_DATE,(lRec.AGC_SER_PERIODICITY * 12) );
      elsif lRec.C_ASA_SERVICE_UNIT = 'W' then   -- unité de garantie en semaine
        ldEnd  := lRec.AGC_LAST_SERVICE_DATE +(lRec.AGC_SER_PERIODICITY * 7);
      end if;

      if ldEnd is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_NEXT_SERVICE_DATE', ldEnd);
      end if;
    end if;
  end CheckDates;

  /**
  * Description
  *   Initialisation de la localité formaté pour les différentes adresses
  *   si le code postal, la ville ou le pays a été changé
  *
  */
  procedure InitFormatCity(iotGuarantyCard in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lFormatCity PAC_ADDRESS.ADD_FORMAT%type;
  begin
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_POSTCODE_AGENT')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_TOWN_AGENT')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'PC_ASA_AGENT_CNTRY_ID') then
      -- Initialisation de la localité formaté pour l'agent
      lFormatCity  :=
        PAC_PARTNER_MANAGEMENT.FormatingAddress(pAddZipCode     => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_POSTCODE_AGENT')
                                              , pAddCity        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_TOWN_AGENT')
                                              , pAddState       => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_STATE_AGENT')
                                              , pAddCounty      => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_COUNTY_AGENT')
                                              , pAddCountryId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'PC_ASA_AGENT_CNTRY_ID')
                                               );
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_FORMAT_CITY_AGENT', lFormatCity);
    end if;

    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_POSTCODE_DISTRIB')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_TOWN_DISTRIB')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'PC_ASA_DISTRIB_CNTRY_ID') then
      -- Initialisation de la localité formaté pour le détaillant
      lFormatCity  :=
        PAC_PARTNER_MANAGEMENT.FormatingAddress(pAddZipCode     => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_POSTCODE_DISTRIB')
                                              , pAddCity        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_TOWN_DISTRIB')
                                              , pAddState       => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_STATE_DISTRIB')
                                              , pAddCounty      => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_COUNTY_DET')
                                              , pAddCountryId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'PC_ASA_DISTRIB_CNTRY_ID')
                                               );
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_FORMAT_CITY_DISTRIB', lFormatCity);
    end if;

    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_POSTCODE_FIN_CUST')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_TOWN_FIN_CUST')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'PC_ASA_FIN_CUST_CNTRY_ID') then
      -- Initialisation de la localité formaté pour le client final
      lFormatCity  :=
        PAC_PARTNER_MANAGEMENT.FormatingAddress(pAddZipCode     => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_POSTCODE_FIN_CUST')
                                              , pAddCity        => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_TOWN_FIN_CUST')
                                              , pAddState       => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_STATE_FIN_CUST')
                                              , pAddCounty      => FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGuarantyCard, 'AGC_COUNTY_CUST')
                                              , pAddCountryId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'PC_ASA_FIN_CUST_CNTRY_ID')
                                               );
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_FORMAT_CITY_FIN_CUST', lFormatCity);
    end if;
  end InitFormatCity;

  /**
  * Description
  *   Initialisation de la ville et de l'état en fonction du code postal
  *
  */
  procedure InitTownState(iotGuarantyCard in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lnCount   number;
    lZipZip   PCS.PC_ZIPCI.ZIPZIP%type;
    lCntryId  PCS.PC_CNTRY.PC_CNTRY_ID%type;
    lZipCity  PCS.PC_ZIPCI.ZIPCITY%type;
    lZipState PCS.PC_ZIPCI.ZIPSTATE%type;
  begin
    -- Traitement pour l'agent
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_POSTCODE_AGENT')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_TOWN_AGENT')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_STATE_AGENT') then
      -- Ajouter la ville et l'état pour autant qu'il n'y qu'une seule correspondance avec le code postal
      lZipZip   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'AGC_POSTCODE_AGENT');
      lCntryId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'PC_ASA_AGENT_CNTRY_ID');

      select   count(*)
             , min(ZIP.ZIPCITY)
             , min(ZIP.ZIPSTATE)
          into lnCount
             , lZipCity
             , lZipState
          from PCS.PC_ZIPCI ZIP
             , PCS.PC_CNTRY CNT
         where ZIP.PC_CNTRY_ID = CNT.PC_CNTRY_ID
           and ZIP.ZIPZIP = lZipZip
           and CNT.PC_CNTRY_ID = lCntryId
           and nvl(ZIP.ZIPCITY, ' ') = decode(0, 1, lZipCity, nvl(ZIP.ZIPCITY, ' ') )
      group by ZIP.ZIPZIP;

      if lnCount = 1 then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_TOWN_AGENT', lZipCity);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_STATE_AGENT', lZipState);
      end if;
    end if;

    -- Traitement pour le détaillant
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_POSTCODE_DISTRIB')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_TOWN_DISTRIB')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_STATE_DISTRIB') then
      -- Ajouter la ville et l'état pour autant qu'il n'y qu'une seule correspondance avec le code postal
      lZipZip   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'AGC_POSTCODE_DISTRIB');
      lCntryId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'PC_ASA_DISTRIB_CNTRY_ID');

      select   count(*)
             , min(ZIP.ZIPCITY)
             , min(ZIP.ZIPSTATE)
          into lnCount
             , lZipCity
             , lZipState
          from PCS.PC_ZIPCI ZIP
             , PCS.PC_CNTRY CNT
         where ZIP.PC_CNTRY_ID = CNT.PC_CNTRY_ID
           and ZIP.ZIPZIP = lZipZip
           and CNT.PC_CNTRY_ID = lCntryId
           and nvl(ZIP.ZIPCITY, ' ') = decode(0, 1, lZipCity, nvl(ZIP.ZIPCITY, ' ') )
      group by ZIP.ZIPZIP;

      if lnCount = 1 then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_TOWN_DISTRIB', lZipCity);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_STATE_DISTRIB', lZipState);
      end if;
    end if;

    -- Traitement pour le client final
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_POSTCODE_FIN_CUST')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_TOWN_FIN_CUST')
       and not FWK_I_MGT_ENTITY_DATA.IsModified(iotGuarantyCard, 'AGC_STATE_FIN_CUST') then
      -- Ajouter la ville et l'état pour autant qu'il n'y qu'une seule correspondance avec le code postal
      lZipZip   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'AGC_POSTCODE_FIN_CUST');
      lCntryId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGuarantyCard, 'PC_ASA_FIN_CUST_CNTRY_ID');

      select   count(*)
             , min(ZIP.ZIPCITY)
             , min(ZIP.ZIPSTATE)
          into lnCount
             , lZipCity
             , lZipState
          from PCS.PC_ZIPCI ZIP
             , PCS.PC_CNTRY CNT
         where ZIP.PC_CNTRY_ID = CNT.PC_CNTRY_ID
           and ZIP.ZIPZIP = lZipZip
           and CNT.PC_CNTRY_ID = lCntryId
           and nvl(ZIP.ZIPCITY, ' ') = decode(0, 1, lZipCity, nvl(ZIP.ZIPCITY, ' ') )
      group by ZIP.ZIPZIP;

      if lnCount = 1 then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_TOWN_FIN_CUST', lZipCity);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGuarantyCard, 'AGC_STATE_FIN_CUST', lZipState);
      end if;
    end if;
  end InitTownState;
end ASA_PRC_GUARANTY_CARDS;
