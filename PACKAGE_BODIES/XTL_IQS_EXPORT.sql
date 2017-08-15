--------------------------------------------------------
--  DDL for Package Body XTL_IQS_EXPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "XTL_IQS_EXPORT" 
is
  procedure ExportCustomers(pIQS_Session_id number)
/************************************************************************
 * Description : Export all customers for which a least one record exists
 *           in GCO_COMPL_DATA_SALE table.
 *
 *         Export condition :   cust has an address of type 'Fac'
 *                      cust may have an e-mail address
 *
 * @author Pierre-Yves Voirol
 * @version Date 16.03.2002
 * @public
 * @param pIQS_Session_id : Session's ID
 *
 ***********************************************************************/
  is
  begin
    insert into xtl_iqs_pac_partner
                (xtl_iqs_pac_partner_id
               , c_iqs_partner_type
               , pac_person_id
               , per_short_name
               , per_name
               , per_forename
               , per_key1
               , add_address1
               , pc_cntry_id
               , cntid
               , add_zipcode
               , add_city
               , com_ext_number
               , a_datecre
               , a_idcre
               , iqs_export_session_id
                )
      select init_id_seq.nextval
           , '1'
           , per.pac_person_id
           , per.per_short_name
           , per.per_name
           , per.per_forename
           , per.per_key1
           , addr.add_address1
           , cnt.pc_cntry_id
           , cnt.cntid
           , addr.add_zipcode
           , addr.add_city
           , com.com_ext_number
           , sysdate
           , pcs.PC_I_LIB_SESSION.getuserini
           , piqs_session_id
        from pac_person per
           , pac_address addr
           , pac_custom_partner cus
           , pcs.pc_cntry cnt
           , pac_communication com
       where per.pac_person_id = addr.pac_person_id
         and addr.pc_cntry_id = cnt.pc_cntry_id
         and addr.dic_address_type_id = 'Fac'
         and per.pac_person_id = com.pac_person_id(+)
         and com.dic_communication_type_id(+) = 'E-mail'
         and per.pac_person_id = cus.pac_custom_partner_id
         and per.pac_person_id in(select csa.pac_custom_partner_id
                                    from gco_compl_data_sale csa
                                   where csa.pac_custom_partner_id is not null);
  end ExportCustomers;

  procedure ExportSuppliers(pIQS_Session_id number)
/************************************************************************
 * Description : Export all suppliers for which a least one record exists
 *           in GCO_COMPL_DATA_PURCHASE table.
 *
 *         Export condition :   suppl has an address of type 'Fac'
 *                      suppl may have an e-mail address
 *
 * @author Pierre-Yves Voirol
 * @version Date 16.03.2002
 * @public
 * @param pIQS_Session_id : Session's ID
 *
 ***********************************************************************/
  is
  begin
    insert into XTL_IQS_PAC_PARTNER
                (XTL_IQS_PAC_PARTNER_ID
               , C_IQS_PARTNER_TYPE
               , PAC_PERSON_ID
               , PER_SHORT_NAME
               , PER_NAME
               , PER_FORENAME
               , PER_KEY1
               , ADD_ADDRESS1
               , PC_CNTRY_ID
               , CNTID
               , ADD_ZIPCODE
               , ADD_CITY
               , COM_EXT_NUMBER
               , a_datecre
               , a_idcre
               , IQS_EXPORT_SESSION_ID
                )
      select Init_id_Seq.nextval
           , '2'
           , PER.PAC_PERSON_ID
           , PER.PER_SHORT_NAME
           , PER.PER_NAME
           , PER.PER_FORENAME
           , PER.PER_KEY1
           , ADDR.ADD_ADDRESS1
           , CNT.PC_CNTRY_ID
           , CNT.CNTID
           , ADDR.ADD_ZIPCODE
           , ADDR.ADD_CITY
           , COM.COM_EXT_NUMBER
           , sysdate
           , pcs.PC_I_LIB_SESSION.getuserini
           , pIQS_Session_id
        from PAC_PERSON PER
           , PAC_ADDRESS ADDR
           , PAC_SUPPLIER_PARTNER SUP
           , PCS.PC_CNTRY CNT
           , PAC_COMMUNICATION COM
       where PER.PAC_PERSON_ID = ADDR.PAC_PERSON_ID
         and ADDR.PC_CNTRY_ID = CNT.PC_CNTRY_ID
         and ADDR.DIC_ADDRESS_TYPE_ID = 'Fac'
         and PER.PAC_PERSON_ID = COM.PAC_PERSON_ID(+)
         and COM.DIC_COMMUNICATION_TYPE_ID(+) = 'E-Mail'
         and PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and PER.PAC_PERSON_ID in(select CDA.PAC_SUPPLIER_PARTNER_ID
                                    from GCO_COMPL_DATA_PURCHASE CDA
                                   where CDA.PAC_SUPPLIER_PARTNER_ID is not null);
  end ExportSuppliers;

  procedure ExportProducts(pIQS_Session_id number)
/************************************************************************
 * Description : Export all products having a link with a customer
 *
 *
 * @author Pierre-Yves Voirol
 * @version Date 16.03.2002
 * @public
 * @param pIQS_Session_id : Session's ID
 *
 ***********************************************************************/
  is
  begin
    insert into xtl_iqs_gco_product_cust
                (XTL_IQS_GCO_PRODUCT_CUST_ID
               , GCO_GOOD_ID
               , PAC_PERSON_ID
               , GOO_MAJOR_REFERENCE
               , PER_KEY1
               , A_DATECRE
               , A_IDCRE
               , IQS_EXPORT_SESSION_ID
                )
      select init_id_seq.nextval
           , goo.gco_good_id
           , per.pac_person_id
           , goo.goo_major_reference
           , per.per_key1
           , sysdate
           , pcs.PC_I_LIB_SESSION.getuserini
           , pIQS_SESSION_ID
        from gco_compl_data_sale csa
           , gco_good goo
           , pac_person per
       where csa.gco_good_id = goo.gco_good_id
         and csa.pac_custom_partner_id = per.pac_person_id;
  end ExportProducts;

  procedure ExportProductCusts(pIQS_Session_id number)
/************************************************************************
 * Description : Export all link between a product and a customer
 *
 *
 * @author Pierre-Yves Voirol
 * @version Date 16.03.2002
 * @public
 * @param pIQS_Session_id : Session's ID
 *
 ***********************************************************************/
  is
  begin
    insert into xtl_iqs_gco_product
                (xtl_iqs_gco_product_id
               , gco_good_id
               , c_good_status
               , goo_major_reference
               , des_short_description
               , dic_good_line_id
               , dic_good_family_id
               , dic_good_group_id
               , a_datecre
               , a_idcre
               , iqs_export_session_id
                )
      select init_id_seq.nextval
           , goo.gco_good_id
           , goo.c_good_status
           , goo.goo_major_reference
           , des.des_short_description
           , goo.dic_good_line_id
           , goo.dic_good_family_id
           , goo.dic_good_group_id
           , sysdate
           , pcs.PC_I_LIB_SESSION.getuserini
           , pIQS_Session_id
        from gco_good goo
           , gco_description des
       where goo.gco_good_id = des.gco_good_id
         and des.c_description_type = '01'
         and des.pc_lang_id = 2
         and goo.gco_good_id in(select csa.gco_good_id
                                  from gco_compl_data_sale csa
                                 where csa.pac_custom_partner_id is not null);
  end ExportProductCusts;

  procedure ExportParts(pIQS_Session_id number)
/************************************************************************
 * Description :
 *
 *
 * @author Pierre-Yves Voirol
 * @version Date 16.03.2002
 * @public
 * @param pIQS_Session_id : Session's ID
 *
 ***********************************************************************/
  is
  begin
    insert into XTL_IQS_GCO_PART
                (XTL_IQS_GCO_PART_ID
               , GCO_GOOD_ID
               , GOO_MAJOR_REFERENCE
               , DES_SHORT_DESCRIPTION
               , C_GOOD_STATUS
               , DIC_GOOD_MODEL_ID
               , A_DATECRE
               , A_IDCRE
               , IQS_EXPORT_SESSION_ID
                )
      select init_id_seq.nextval
           , GOO.GCO_GOOD_ID
           , GOO.GOO_MAJOR_REFERENCE
           , DES.DES_SHORT_DESCRIPTION
           , GOO.C_GOOD_STATUS
           , GOO.DIC_GOOD_MODEL_ID
           , sysdate
           , pcs.PC_I_LIB_SESSION.getuserini
           , pIQS_Session_id
        from GCO_GOOD GOO
           , GCO_DESCRIPTION DES
           , GCO_PRODUCT PDT
       where GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID
         and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
         and DES.C_DESCRIPTION_TYPE = '01'
         and DES.PC_LANG_ID = 2
         and PDT.PDT_STOCK_MANAGEMENT = 1
         and PDT.C_SUPPLY_MODE = '1';
  end ExportParts;

  procedure ExportPartSuppls(pIQS_Session_id number)
/************************************************************************
 * Description :
 *
 *
 * @author Pierre-Yves Voirol
 * @version Date 16.03.2002
 * @public
 * @param pIQS_Session_id : Session's ID
 *
 ***********************************************************************/
  is
  begin
    insert into XTL_IQS_GCO_PART_SUPPL
                (XTL_IQS_GCO_PART_SUPPL_ID
               , GCO_GOOD_ID
               , GOO_MAJOR_REFERENCE
               , PAC_PERSON_ID
               , PER_KEY1
               , A_DATECRE
               , A_IDCRE
               , IQS_EXPORT_SESSION_ID
                )
      select init_id_seq.nextval
           , GOO.GCO_GOOD_ID
           , GOO.GOO_MAJOR_REFERENCE
           , PER.PAC_PERSON_ID
           , PER.PER_KEY1
           , sysdate
           , pcs.PC_I_LIB_SESSION.getuserini
           , pIQS_Session_id
        from GCO_COMPL_DATA_PURCHASE CPU
           , GCO_GOOD GOO
           , PAC_PERSON PER
           , GCO_PRODUCT PDT
       where CPU.GCO_GOOD_ID = PDT.GCO_GOOD_ID
         and CPU.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and CPU.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID;
  end ExportPartSuppls;

  procedure ExportProductParts(pIQS_Session_id number)
/************************************************************************
 * Description :
 *
 *
 * @author Pierre-Yves Voirol
 * @version Date 16.03.2002
 * @public
 * @param pIQS_Session_id : Session's ID
 *
 ***********************************************************************/
  is
    cursor all_nomenclatures
    is
      select nom.pps_nomenclature_id
           , nom.gco_good_id
           , goo.goo_major_reference
        from pps_nomenclature nom
           , gco_good goo
           , gco_compl_data_sale csa
       where nom.nom_default = 1
         and nom.gco_good_id = goo.gco_good_id
         and nom.gco_good_id = csa.gco_good_id
         and csa.pac_custom_partner_id is not null;

    nom_tuple all_nomenclatures%rowtype;
  begin
    open all_nomenclatures;

    fetch all_nomenclatures
     into nom_tuple;

    while all_nomenclatures%found loop
      pps_init.SETNOMID(nom_tuple.pps_nomenclature_id);

      insert into XTL_IQS_PPS_PRODUCT_PART
                  (XTL_IQS_PPS_PRODUCT_PART_ID
                 , GCO_GOOD_ID
                 , GCO_GCO_GOOD_ID
                 , GOO_MAJOR_REFERENCE
                 , GOO_GOO_MAJOR_REFERENCE
                 , IQS_EXPORT_SESSION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval
             , nom_tuple.gco_good_id
             , vpps.gco_good_id
             , nom_tuple.goo_major_reference
             , goo.goo_major_reference
             , pIQS_session_id
             , sysdate
             , pcs.PC_I_LIB_SESSION.getuserini
          from v_pps_nomenclature_interro vpps
             , gco_good goo
         where vpps.C_TYPE_COM = 1
           and vpps.C_KIND_COM = 1
           and vpps.pps_pps_nomenclature_id is null
           and vpps.gco_good_id = goo.gco_good_id
           and not exists(
                        select 1
                          from XTL_IQS_PPS_PRODUCT_PART IQS
                         where IQS.GCO_GOOD_ID = nom_tuple.gco_good_id
                           and IQS.GCO_GCO_GOOD_ID = vpps.gco_good_id
                           and IQS.IQS_EXPORT_SESSION_ID = pIQS_session_id);

      fetch all_nomenclatures
       into nom_tuple;
    end loop;

    close all_nomenclatures;
  end ExportProductParts;

  procedure ExportData
/************************************************************************
 * Description : Export all datas needed by IQS'Software
 *
 * @author Pierre-Yves Voirol
 * @version Date 16.03.2002
 * @public
 * @param pIQS_Session_id : Session's ID
 *
 ***********************************************************************/
  is
    vIQS_session_id number;
  begin
    select init_id_seq.nextval
      into vIQS_session_id
      from dual;

    insert into XTL_IQS_LOGFILE
                (XTL_IQS_LOGFILE_ID
               , IQS_EXPORT_SESSION_ID
               , C_IQS_EXPORT_STATUS
               , IQS_EXPORT_TEXT
               , A_DATECRE
               , A_IDCRE
                )
      select init_id_seq.nextval
           , vIQS_session_id
           , '1'
           , 'Exported on     ' || to_char(sysdate, 'DD/MM/YYYY           HH24:MI:SS') || '     by      ' || pcs.PC_I_LIB_SESSION.getuserini
           , sysdate
           , pcs.PC_I_LIB_SESSION.getuserini
        from dual;

    ExportCustomers(vIQS_session_id);
    ExportSuppliers(vIQS_session_id);
    ExportProducts(vIQS_session_id);
    ExportProductCusts(vIQS_session_id);
    ExportParts(vIQS_session_id);
    ExportPartSuppls(vIQS_session_id);
    ExportProductParts(vIQS_session_id);
  end ExportData;

  function DeleteData(paSessionId number)
    return integer
  is
  begin
    --
    -- Effacement des enregistrements d'une session
    --
    delete      XTL_IQS_GCO_PART
          where IQS_EXPORT_SESSION_ID = paSessionId;

    --
    delete      XTL_IQS_GCO_PART_SUPPL
          where IQS_EXPORT_SESSION_ID = paSessionId;

    --
    delete      XTL_IQS_GCO_PRODUCT
          where IQS_EXPORT_SESSION_ID = paSessionId;

    --
    delete      XTL_IQS_GCO_PRODUCT_CUST
          where IQS_EXPORT_SESSION_ID = paSessionId;

    --
    delete      XTL_IQS_PAC_PARTNER
          where IQS_EXPORT_SESSION_ID = paSessionId;

    --
    delete      XTL_IQS_PPS_PRODUCT_PART
          where IQS_EXPORT_SESSION_ID = paSessionId;

    --
    -- Mise à jour du status de log
    --
    update XTL_IQS_LOGFILE
       set C_IQS_EXPORT_STATUS = '9'
         , IQS_EXPORT_TEXT =
             IQS_EXPORT_TEXT ||
             '     /     Deleted on     ' ||
             to_char(sysdate, 'DD/MM/YYYY           HH24:MI:SS') ||
             '     by      ' ||
             pcs.PC_I_LIB_SESSION.getuserini
     where IQS_EXPORT_SESSION_ID = paSessionId;

    --
    return 1;
  end DeleteData;
end XTL_IQS_EXPORT;
