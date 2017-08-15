--------------------------------------------------------
--  DDL for Package Body WEB_SHOPV2_ORDER_MGM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_SHOPV2_ORDER_MGM" 
is
/**
*
*  Purpose : main primitive to manage order :
*
*
    declare
     ret number(1);
     msg varchar2(2000);
     ID varchar2(100);
    begin
    dbms_output.PUT_LINE('go !');
    ret := web_shopv2_order_mgm.ORDERNEW(1348,5162,'refclient 4','a','b','c','d',1,'e','f','g','h',1,id);
    dbms_output.PUT_LINE(ret||' '||msg);
    ret := web_shopv2_order_mgm.orderpositionnew(to_number(id),'SST-000001',1,'prod','prod',null,msg);
    ret := web_shopv2_order_mgm.orderpositionnew(to_number(id),'SST-000001',100,'prod','prod',null,msg);
    dbms_output.PUT_LINE(ret||' '||msg);
    commit;
    end;
*/
  function ordernew(
    apaccustompartnerid    in     pac_custom_partner.pac_custom_partner_id%type
  , apacsendingconditionid in     doc_interface.pac_sending_condition_id%type
  , adoipartnerreference   in     doc_interface.doi_partner_reference%type
  , aadddeladd             in     doc_interface.doi_address1%type
  , aadddelzip             in     doc_interface.doi_zipcode1%type
  , aadddelstate           in     doc_interface.doi_state1%type
  , aadddelcity            in     doc_interface.doi_town1%type
  , aadddelcntryid         in     doc_interface.pc_cntry_id%type
  , aaddbiladd             in     doc_interface.doi_address2%type
  , aaddbilzip             in     doc_interface.doi_zipcode2%type
  , aaddbilstate           in     doc_interface.doi_state2%type
  , aaddbilcity            in     doc_interface.doi_town1%type
  , aaddbilcntryid         in     doc_interface.pc__pc_cntry_id%type
  , adoidocumenttext       in     doc_interface.doi_document_text%type
  , msg                    out    varchar2
  )
    return number
  is
    vdocinterfaceid            doc_interface.doc_interface_id%type;
    vdoinumber                 doc_interface.dmt_number%type;
    vtargetgaugeid             doc_gauge.doc_gauge_id%type;
    vinterfacegaugeid          doc_gauge.doc_gauge_id%type;
    vaddressid1                pac_address.pac_address_id%type;
    vdoiaddress1               pac_address.add_address1%type;
    vdoizipcode1               pac_address.add_zipcode%type;
    vdoitown1                  pac_address.add_city%type;
    vdoistate1                 pac_address.add_state%type;
    vcntryid1                  pac_address.pc_cntry_id%type;
    vlangid1                   pac_address.pc_lang_id%type;
    vaddressid2                pac_address.pac_address_id%type;
    vdoiaddress2               pac_address.add_address1%type;
    vdoizipcode2               pac_address.add_zipcode%type;
    vdoitown2                  pac_address.add_city%type;
    vdoistate2                 pac_address.add_state%type;
    vcntryid2                  pac_address.pc_cntry_id%type;
    vaddressid3                pac_address.pac_address_id%type;
    vdoiaddress3               pac_address.add_address1%type;
    vdoizipcode3               pac_address.add_zipcode%type;
    vdoitown3                  pac_address.add_city%type;
    vdoistate3                 pac_address.add_state%type;
    vcntryid3                  pac_address.pc_cntry_id%type;
    vc_doc_interface_origin    doc_interface.c_doc_interface_origin%type;
    vuserid                    pcs.pc_user.pc_user_id%type;
    vuseini                    pcs.pc_user.use_ini%type;
    vacs_financial_currency_id acs_financial_currency.acs_financial_currency_id%type;
    vpername                   doc_interface.doi_per_name%type;
    vpershortname              doc_interface.doi_per_short_name%type;
    vperkey1                   doc_interface.doi_per_key1%type;
    vperkey2                   doc_interface.doi_per_key2%type;
    vdictariffid               doc_interface.dic_tariff_id%type;
    vpacpaymentconditionid     doc_interface.pac_payment_condition_id%type;
    vpacsendingconditionid     doc_interface.pac_sending_condition_id%type;
    vdictypesubmissionid       doc_interface.dic_type_submission_id%type;
    vacsvatdetaccountid        doc_interface.acs_vat_det_account_id%type;
    vacsfinaccspaymentid       doc_interface.acs_fin_acc_s_payment_id%type;
    vpacadressid               doc_interface.pac_address_id%type;
    vpacrepresentativeid       doc_interface.pac_representative_id%type;
    vctarificationmode         pac_custom_partner.c_tariffication_mode%type;
    vdiccomplementarydataid    pac_custom_partner.dic_complementary_data_id%type;
    vcdeliverytyp              pac_custom_partner.c_delivery_typ%type;
    vcompid                    pcs.pc_comp.pc_comp_id%type;
  begin
    select pc_comp_id
      into vcompid
      from pcs.pc_comp c
         , pcs.pc_scrip s
     where c.pc_scrip_id = s.pc_scrip_id
       and s.scrdbowner = user;

    select init_id_seq.nextval
      into vdocinterfaceid
      from dual;

    select doc_gauge_id
      into vinterfacegaugeid
      from doc_gauge
     where gau_describe = pcs.pc_config.getconfig('BC4J_SHOP_GABARIT_INTERFACE', vcompid, 1);

    select doc_gauge_id
      into vtargetgaugeid
      from doc_gauge
     where gau_describe = pcs.pc_config.getconfig('BC4J_SHOP_GABARIT_TARGET', vcompid, 1);

    select pc_user_id
         , use_ini
      into vuserid
         , vuseini
      from pcs.pc_user
     where use_name like pcs.pc_config.getconfig('BC4J_SHOP_DEFAULT_PCS_USER', vcompid, 1);

    doc_interface_fct.setnewinterfacenumber(vinterfacegaugeid);
    vdoinumber               := doc_interface_fct.getnewinterfacenumber(vinterfacegaugeid);
    vc_doc_interface_origin  := pcs.pc_config.getconfig('BC4J_SHOP_C_DOC_ORIGIN', vcompid, 1);

    select pac_functions.getcustomercurrencyid(apaccustompartnerid)
      into vacs_financial_currency_id
      from dual;

    doc_interface_fct.getcustominfo(apaccustompartnerid
                                  , vpername
                                  , vpershortname
                                  , vperkey1
                                  , vperkey2
                                  , vdictariffid
                                  , vpacpaymentconditionid
                                  , vpacsendingconditionid
                                  , vdictypesubmissionid
                                  , vacsvatdetaccountid
                                  , vacsfinaccspaymentid
                                  , vpacadressid
                                  , vpacrepresentativeid
                                  , vctarificationmode
                                  , vdiccomplementarydataid
                                  , vcdeliverytyp
                                   );
    doc_interface_fct.getthirdaddress(apaccustompartnerid
                                    , vtargetgaugeid
                                    , vaddressid1
                                    , vdoiaddress1
                                    , vdoizipcode1
                                    , vdoitown1
                                    , vdoistate1
                                    , vcntryid1
                                    , vlangid1
                                    , vaddressid2
                                    , vdoiaddress2
                                    , vdoizipcode2
                                    , vdoitown2
                                    , vdoistate2
                                    , vcntryid2
                                    , vaddressid3
                                    , vdoiaddress3
                                    , vdoizipcode3
                                    , vdoitown3
                                    , vdoistate3
                                    , vcntryid3
                                     );

    insert into doc_interface
                (doc_interface_id
               , doi_number
               , c_doc_interface_origin
               , c_doi_interface_status
               , c_doi_interface_fail_reason
               , doi_protected
               , pc_user_id
               , pac_third_id
               , doi_per_name
               , doi_per_short_name
               , doi_per_key1
               , doi_per_key2
               , doc_record_id
               , doi_rco_title
               , doi_rco_number
               , pac_representative_id
               , doi_rep_descr
               , pac_sending_condition_id
               , doi_sen_key
               , pc_lang_id
               , doi_lanid
               , doi_reference
               , doi_partner_reference
               , doi_partner_number
               , doi_partner_date
               , acs_financial_currency_id
               , doi_currency
               , doi_document_date
               , doi_value_date
               , doi_delivery_date
               , dic_type_submission_id
               , pac_payment_condition_id
               , doi_pco_descr
               , dic_tariff_id
               , acs_vat_det_account_id
               , doi_vat_det_account_descr
               , acs_fin_acc_s_payment_id
               , doi_fin_payment_descr
               , pac_address_id
               , doi_add1_per_name
               , doi_add1_per_key1
               , doi_add1_per_key2
               , doi_address1
               , pc_cntry_id
               , doi_cntid1
               , doi_zipcode1
               , doi_town1
               , doi_state1
               , pac_pac_address_id
               , doi_add2_per_name
               , doi_add2_per_key1
               , doi_add2_per_key2
               , doi_address2
               , pc__pc_cntry_id
               , doi_cntid2
               , doi_zipcode2
               , doi_town2
               , doi_state2
               , pac2_pac_address_id
               , doi_add3_per_name
               , doi_add3_per_key1
               , doi_add3_per_key2
               , doi_address3
               , pc_2_pc_cntry_id
               , doi_cntid3
               , doi_zipcode3
               , doi_town3
               , doi_state3
               , dic_pos_free_table_1_id
               , doi_text_1
               , doi_decimal_1
               , dic_pos_free_table_2_id
               , doi_text_2
               , doi_decimal_2
               , dic_pos_free_table_3_id
               , doi_text_3
               , doi_decimal_3
               , a_datecre
               , a_datemod
               , a_idcre
               , a_idmod
               , a_reclevel
               , a_recstatus
               , a_confirm
               , doc_gauge_id
               , doi_subtype
               , doi_date_1
               , doi_date_2
               , doi_date_3
               , doi_error
               , doi_error_message
               , doi_document_text
               , doi_heading_text
               , doi_title_text
               , dmt_number
               , c_interface_gen_mode
               , doc_document_id
               , doi_foot_charge_copy
               , doi_gau_describe
               , pac_distribution_channel_id
               , pac_sale_territory_id
               , pac_third_aci_id
               , pac_third_delivery_id
               , pac_third_tariff_id
               , pac_repr_aci_id
               , pac_repr_delivery_id
               , pc_lang_aci_id
               , pc_lang_delivery_id
               , doi_name1
               , doi_name2
               , doi_name3
               , doi_forename1
               , doi_forename2
               , doi_forename3
               , doi_activity1
               , doi_activity2
               , doi_activity3
               , doi_care_of1
               , doi_care_of2
               , doi_care_of3
               , doi_po_box1
               , doi_po_box2
               , doi_po_box3
               , doi_po_box_nbr1
               , doi_po_box_nbr2
               , doi_po_box_nbr3
               , doi_county1
               , doi_county2
               , doi_county3
               , doi_contact1
               , doi_contact2
               , doi_contact3
                )
         values (vdocinterfaceid
               , vdoinumber
               , vc_doc_interface_origin
               , '02'
               , null
               , 0
               , vuserid
               , apaccustompartnerid
               , vpername
               , vpershortname
               , vperkey1
               , vperkey2
               , null
               , null
               , null
               , vpacrepresentativeid
               , null
               , apacsendingconditionid
               , null
               , vlangid1
               , null
               , null
               , adoipartnerreference
               , null
               , null
               , vacs_financial_currency_id
               , null
               , sysdate
               , sysdate
               , null
               , vdictypesubmissionid
               , vpacpaymentconditionid
               , null
               , vdictariffid
               , vacsvatdetaccountid
               , null
               , null
               , null
               , vaddressid1
               , null
               , null
               , null
               ,
                 --nvl(aadddeladd,vdoiaddress1),nvl(aadddelcntryid,vcntryid1), NULL, nvl(aadddelzip,vdoizipcode1), nvl(aadddelcity,vdoitown1),nvl(aadddelstate,vdoistate1),
                 vdoiaddress1
               , aadddelcntryid
               , null
               , aadddelzip
               , aadddelcity
               , aadddelstate
               , vaddressid2
               , null
               , null
               , null
               , nvl(aadddeladd, vdoiaddress1)
               , nvl(aadddelcntryid, vcntryid1)
               , null
               , nvl(aadddelzip, vdoizipcode1)
               , nvl(aadddelcity, vdoitown1)
               , nvl(aadddelstate, vdoistate1)
               ,
                 --nvl(aaddbiladd,vdoiaddress2),nvl(aaddbilcntryid,vcntryid2), NULL, nvl(aaddbilzip,vdoizipcode2), nvl(aaddbilcity,vdoitown2),nvl(aaddbilstate,vdoistate2),
                 vaddressid3
               , null
               , null
               , null
               , vdoiaddress3
               , vcntryid3
               , null
               , vdoizipcode3
               , vdoitown3
               , vdoistate3
               , null
               , null
               ,
                 --nvl(aaddbiladd,vdoiaddress2),nvl(aaddbilcntryid,vcntryid2), NULL, nvl(aaddbilzip,vdoizipcode2), nvl(aaddbilcity,vdoitown2),nvl(aaddbilstate,vdoistate2),
                 null
               , null
               , null
               , null
               , null
               , null
               , null
               , sysdate
               , null
               , vuseini
               , null
               , null
               , null
               , null
               , vtargetgaugeid
               , null
               , null
               , null
               , null
               , 0
               , null
               , adoidocumenttext
               , null
               , null
               , null
               , null
               , null
               , 0
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
                );

/*
                   doi_address1,pc_cntry_id, doi_cntid1, doi_zipcode1, doi_town1,doi_state1,
                   pac_pac_address_id, doi_add2_per_name,doi_add2_per_key1, doi_add2_per_key2,
                   doi_address2,pc__pc_cntry_id, doi_cntid2, doi_zipcode2, doi_town2,doi_state2,
                   pac2_pac_address_id, doi_add3_per_name,doi_add3_per_key1, doi_add3_per_key2,
                   doi_address3,pc_2_pc_cntry_id, doi_cntid3, doi_zipcode3, doi_town3,doi_state3,
*/
    msg                      := vdocinterfaceid;
    return 2;
  end;

  /**
   * Retourne le no de l'interface (permet d'être individulisée à l'appel par nom de config)
   */
  function ordergetnumber(adocinterfaceid doc_interface.doc_interface_id%type)
    return varchar2
  is
    vdocname varchar2(200);
  begin
    select nvl(d.dmt_number, i.doi_number)
      into vdocname
      from doc_interface i
         , doc_document d
     where i.doc_interface_id = adocinterfaceid
       and d.dmt_doi_number(+) = i.doi_number;

    return vdocname;
  end;

  /**
   * creation d'une position de type bien
   */
  function orderpositionnew(
    adocinterfaceid      in     doc_interface.doc_interface_id%type
  , agoomajorreference   in     gco_good.goo_major_reference%type
  , adopqty              in     doc_interface_position.dop_qty%type
  , adopshortdescription in     doc_interface_position.dop_short_description%type
  , adoplongdescription  in     doc_interface_position.dop_long_description%type
  , adopgrossunitvalue   in     doc_interface_position.dop_gross_unit_value%type
  , msg                  out    varchar2
  )
    return number
  is
    vdocinterfacepositionid  doc_interface_position.doc_interface_position_id%type;
    vgcogoodid               gco_good.gco_good_id%type;
    vposnumber               doc_interface_position.dop_pos_number%type;
    vtargetgaugeid           doc_gauge.doc_gauge_id%type;
    vunitprice               doc_interface_position.dop_gross_unit_value%type;
    vtotalprice              doc_interface_position.dop_gross_value%type;
    vpacid                   pac_custom_partner.pac_custom_partner_id%type;
    vdop_short_description   doc_interface_position.dop_short_description%type;
    vdop_long_description    doc_interface_position.dop_long_description%type;
    vdop_free_description    doc_interface_position.dop_free_description%type;
    vpclangid                doc_interface.pc_lang_id%type;
    vgco_characterization_id gco_characterization.gco_characterization_id%type;
    vche_value               gco_characteristic_element.che_value%type;
    vexistschar              number(2);
    vacs_tax_code_id         acs_tax_code.acs_tax_code_id%type;
    vc_admin_domain          pcs.pc_gcodes.gclcode%type;
    vacs_vat_det_account_id  pac_custom_partner.acs_vat_det_account_id%type;
    vdic_type_submission_id  pac_custom_partner.dic_type_submission_id%type;
    vdic_type_movement_id    doc_gauge_structured.dic_type_movement_id%type;
    vuseprice                number(1);
    vacsfinancialcurrencyid  number(12);
    vcurrency                varchar2(5);
    vuseini                  pcs.pc_user.use_ini%type;
  begin
    select acs_financial_currency_id
         , a_idcre
      into vacsfinancialcurrencyid
         , vuseini
      from doc_interface
     where doc_interface_id = adocinterfaceid;

    if (    (adopgrossunitvalue is null)
        or (adopgrossunitvalue = 0) ) then
      vuseprice  := 0;
    else
      vuseprice  := 1;
    end if;

    select init_id_seq.nextval
      into vdocinterfacepositionid
      from dual;

    select pac_third_id
         , doc_gauge_id
         , pc_lang_id
         , acs_vat_det_account_id
      into vpacid
         , vtargetgaugeid
         , vpclangid
         , vacs_vat_det_account_id
      from doc_interface
     where doc_interface_id = adocinterfaceid;

    select gco_good_id
      into vgcogoodid
      from gco_good
     where goo_major_reference = agoomajorreference;

    select count(*)
      into vexistschar
      from gco_characterization
     where gco_good_id = vgcogoodid
       and c_charact_type <> 3;

    if (vexistschar > 0) then
      begin
        select gco_characterization_id
          into vgco_characterization_id
          from gco_characterization
         where gco_good_id = vgcogoodid
           and rownum = 1;

        select che_value
          into vche_value
          from gco_characteristic_element
         where gco_characterization_id = vgco_characterization_id
           and rownum = 1;
      end;
    end if;

    select c_admin_domain
         , dic_type_movement_id
      into vc_admin_domain
         , vdic_type_movement_id
      from doc_gauge g
         , doc_gauge_structured s
     where g.doc_gauge_id = s.doc_gauge_id
       and g.doc_gauge_id = vtargetgaugeid;

    select dic_type_submission_id
      into vdic_type_submission_id
      from pac_custom_partner
     where pac_custom_partner_id = vpacid;

    vacs_tax_code_id  :=
      ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(1
                                            , vpacid
                                            , vgcogoodid
                                            , null
                                            , null
                                            , vc_admin_domain
                                            , vdic_type_submission_id
                                            , vdic_type_movement_id
                                            , vacs_vat_det_account_id
                                             );
    vtotalprice       :=
              web_shop_functions_std.getgcogoodprice(vgcogoodid, vpacid, vacsfinancialcurrencyid, adopqty, 'orderPrice');

    if     (adopgrossunitvalue is not null)
       and (adopgrossunitvalue <> 0) then
      vunitprice  := adopgrossunitvalue;
    else
      vunitprice  :=
                   web_shop_functions_std.getgcogoodprice(vgcogoodid, vpacid, vacsfinancialcurrencyid, 1, 'orderPrice');
    end if;

    select 10 *(count(*) + 1)
      into vposnumber
      from doc_interface_position
     where doc_interface_id = adocinterfaceid;

    select des_short_description
         , des_long_description
         , des_free_description
      into vdop_short_description
         , vdop_long_description
         , vdop_free_description
      from gco_description
     where gco_good_id = vgcogoodid
       and c_description_type = '01'
       and pc_lang_id = vpclangid;

    if (adopshortdescription is not null) then
      vdop_short_description  := adopshortdescription;
    end if;

    if (adoplongdescription is not null) then
      vdop_long_description  := adoplongdescription;
    end if;

    insert into doc_interface_position
                (doc_interface_position_id
               , doc_interface_id
               , c_dop_interface_status
               , c_dop_interface_fail_reason
               , c_gauge_type_pos
               , gap_designation
               , doc_gauge_id
               , gau_describe
               , dop_pos_number
               , gco_good_id
               , dop_major_reference
               , gco_characterization_id
               , gco_gco_characterization_id
               , gco2_gco_characterization_id
               , gco3_gco_characterization_id
               , gco4_gco_characterization_id
               , dop_characterization_value_1
               , dop_characterization_value_2
               , dop_characterization_value_3
               , dop_characterization_value_4
               , dop_characterization_value_5
               , c_product_delivery_typ
               , acs_tax_code_id
               , dop_tax_code_descr
               , dop_qty
               , dop_qty_value
               , dop_gross_unit_value
               , dop_gross_value
               , dop_net_value_excl
               , dop_net_value_incl
               , dop_include_tax_tariff
               , dop_net_tariff
               , dop_discount_rate
               , stm_stock_id
               , dop_sto_description1
               , stm_location_id
               , dop_loc_description1
               , stm_stm_stock_id
               , dop_sto_description2
               , stm_stm_location_id
               , dop_loc_description2
               , doc_record_id
               , dop_rco_title
               , dop_rco_number
               , pac_representative_id
               , dop_rep_descr
               , dop_basis_delay
               , dop_intermediate_delay
               , dop_final_delay
               , dic_pos_free_table_1_id
               , dop_pos_text_1
               , dop_pos_decimal_1
               , dic_pos_free_table_2_id
               , dop_pos_text_2
               , dop_pos_decimal_2
               , dic_pos_free_table_3_id
               , dop_pos_text_3
               , dop_pos_decimal_3
               , dic_pde_free_table_1_id
               , dop_pde_text_1
               , dop_pde_decimal_1
               , dic_pde_free_table_2_id
               , dop_pde_text_2
               , dop_pde_decimal_2
               , dic_pde_free_table_3_id
               , dop_pde_text_3
               , dop_pde_decimal_3
               , dop_short_description
               , dop_long_description
               , dop_free_description
               , pc_appltxt_id
               , dop_body_text
               , doc_document_id
               , dop_father_dmt_number
               , doc_position_id
               , dop_father_pos_number
               , doc_position_detail_id
               , dop_father_delay
               , a_datecre
               , a_datemod
               , a_idcre
               , a_idmod
               , a_reclevel
               , a_recstatus
               , a_confirm
               , dop_special_tariff
               , dop_flat_rate
               , dop_pos_date_1
               , dop_pos_date_2
               , dop_pos_date_3
               , dop_pde_date_1
               , dop_pde_date_2
               , dop_pde_date_3
               , c_interface_gen_mode
               , dop_error
               , dop_error_message
               , dop_use_good_price
               , doc_gauge_position_id
               , dop_secondary_reference
               , pps_nomenclature_id
               , dop_pos_charge_copy
               , doc_interface_origin_pos_id
               , pac_repr_aci_id
               , pac_repr_delivery_id
                )
         values (vdocinterfacepositionid
               , adocinterfaceid
               , '02'
               , null
               , '1'
               , null
               , vtargetgaugeid
               , null
               , vposnumber
               , vgcogoodid
               , agoomajorreference
               , vgco_characterization_id
               , 0
               , 0
               , 0
               , 0
               , vche_value
               , null
               , null
               , null
               , null
               , null
               , vacs_tax_code_id
               , null
               , adopqty
               , adopqty
               , vunitprice
               , vtotalprice
               , null
               , null
               , 0
               , 0
               , 0
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , 0
               , null
               , null
               , 0
               , null
               , null
               , 0
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , vdop_short_description
               , vdop_long_description
               , vdop_free_description
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , sysdate
               , null
               , 'ECON'
               , null
               , null
               , null
               , null
               , 0
               , 0
               , null
               , null
               , null
               , null
               , null
               , null
               , 'INSERT'
               , 0
               , null
               , vuseprice
               , null
               , null
               , null
               , 0
               , null
               , null
               , null
                );

    msg               := vdocinterfacepositionid;
    return web_functions.return_ok;
  end;

  /**
   * creation d'une position de type text
   */
  function orderpositiontextnew(
    adocinterfaceid in     doc_interface.doc_interface_id%type
  , adopbodytext    in     doc_interface_position.dop_body_text%type
  , msg             out    varchar2
  )
    return number
  is
    vuseini                 pcs.pc_user.use_ini%type;
    vdocinterfacepositionid doc_interface_position.doc_interface_position_id%type;
    vposnumber              doc_interface_position.dop_pos_number%type;
    vtargetgaugeid          doc_gauge.doc_gauge_id%type;
  begin
    select a_idcre
      into vuseini
      from doc_interface
     where doc_interface_id = adocinterfaceid;

    select 10 *(count(*) + 1)
      into vposnumber
      from doc_interface_position
     where doc_interface_id = adocinterfaceid;

    select doc_gauge_id
      into vtargetgaugeid
      from doc_interface
     where doc_interface_id = adocinterfaceid;

    select init_id_seq.nextval
      into vdocinterfacepositionid
      from dual;

    insert into doc_interface_position
                (doc_interface_position_id
               , doc_interface_id
               , c_dop_interface_status
               , c_dop_interface_fail_reason
               , c_gauge_type_pos
               , gap_designation
               , doc_gauge_id
               , gau_describe
               , dop_pos_number
               , gco_good_id
               , dop_major_reference
               , gco_characterization_id
               , gco_gco_characterization_id
               , gco2_gco_characterization_id
               , gco3_gco_characterization_id
               , gco4_gco_characterization_id
               , dop_characterization_value_1
               , dop_characterization_value_2
               , dop_characterization_value_3
               , dop_characterization_value_4
               , dop_characterization_value_5
               , c_product_delivery_typ
               , acs_tax_code_id
               , dop_tax_code_descr
               , dop_qty
               , dop_qty_value
               , dop_gross_unit_value
               , dop_gross_value
               , dop_net_value_excl
               , dop_net_value_incl
               , dop_include_tax_tariff
               , dop_net_tariff
               , dop_discount_rate
               , stm_stock_id
               , dop_sto_description1
               , stm_location_id
               , dop_loc_description1
               , stm_stm_stock_id
               , dop_sto_description2
               , stm_stm_location_id
               , dop_loc_description2
               , doc_record_id
               , dop_rco_title
               , dop_rco_number
               , pac_representative_id
               , dop_rep_descr
               , dop_basis_delay
               , dop_intermediate_delay
               , dop_final_delay
               , dic_pos_free_table_1_id
               , dop_pos_text_1
               , dop_pos_decimal_1
               , dic_pos_free_table_2_id
               , dop_pos_text_2
               , dop_pos_decimal_2
               , dic_pos_free_table_3_id
               , dop_pos_text_3
               , dop_pos_decimal_3
               , dic_pde_free_table_1_id
               , dop_pde_text_1
               , dop_pde_decimal_1
               , dic_pde_free_table_2_id
               , dop_pde_text_2
               , dop_pde_decimal_2
               , dic_pde_free_table_3_id
               , dop_pde_text_3
               , dop_pde_decimal_3
               , dop_short_description
               , dop_long_description
               , dop_free_description
               , pc_appltxt_id
               , dop_body_text
               , doc_document_id
               , dop_father_dmt_number
               , doc_position_id
               , dop_father_pos_number
               , doc_position_detail_id
               , dop_father_delay
               , a_datecre
               , a_datemod
               , a_idcre
               , a_idmod
               , a_reclevel
               , a_recstatus
               , a_confirm
               , dop_special_tariff
               , dop_flat_rate
               , dop_pos_date_1
               , dop_pos_date_2
               , dop_pos_date_3
               , dop_pde_date_1
               , dop_pde_date_2
               , dop_pde_date_3
               , c_interface_gen_mode
               , dop_error
               , dop_error_message
               , dop_use_good_price
               , doc_gauge_position_id
               , dop_secondary_reference
               , pps_nomenclature_id
               , dop_pos_charge_copy
               , doc_interface_origin_pos_id
               , pac_repr_aci_id
               , pac_repr_delivery_id
                )
         values (vdocinterfacepositionid
               , adocinterfaceid
               , '02'
               , null
               , '4'
               ,   --c_gauge_type_pos Position de type TEXT
                 null
               , vtargetgaugeid
               , null
               , vposnumber
               , null
               ,   --vgcogoodid,
                 null
               ,   --agoomajorreference,
                 null
               ,   --vgco_characterization_id,
                 0
               , 0
               , 0
               , 0
               , null
               ,   --vche_value,
                 null
               , null
               , null
               , null
               , null
               , null
               ,   --vacs_tax_code_id,
                 null
               , 0
               ,   --adopqty,
                 0
               , 0
               , 0
               ,   --adopqty, vunitprice, vtotalprice,
                 null
               , null
               , 0
               , 0
               , 0
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , 0
               , null
               , null
               , 0
               , null
               , null
               , 0
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               ,   --vdop_short_description,
                 null
               ,   --vdop_long_description,
                 null
               ,   --vdop_free_description,
                 null
               , adopbodytext
               ,   --NULL,
                 null
               , null
               , null
               , null
               , null
               , null
               , sysdate
               , null
               , vuseini
               , null
               , null
               , null
               , null
               , 0
               , 0
               , null
               , null
               , null
               , null
               , null
               , null
               , 'INSERT'
               , 0
               , null
               , 0
               , null
               , null
               , null
               , 0
               , null
               , null
               , null
                );

    return web_functions.return_ok;
  end;

  /**
  * Retourne le no de l'interface (permet d'être individulisée à l'appel par nom de config)
  */
  function ordergetnewdocnumber(adocinterfaceid doc_interface.doc_interface_id%type)
    return doc_document.dmt_number%type
  is
    vdocname varchar2(200);
  begin
    select doi_number
      into vdocname
      from doc_interface
     where doc_interface_id = adocinterfaceid;

    return vdocname;
  end;

  /**
    * Génération du document
    */
  function ordergeneration(
    pdocinterfaceid in     doc_interface.doc_interface_id%type
  , pdmtnumber      in     doc_interface.doi_number%type
  , msg             out    varchar2
  )
    return number
  is
    vdmtnumber       doc_document.dmt_number%type;
    errmsg           varchar2(4000);
    listdocid        varchar2(4000);
    docid            doc_document.doc_document_id%type;
    vdefaultshopuser pcs.pc_user.use_name%type;
    vcompid          pcs.pc_comp.pc_comp_id%type;
  begin
    select pc_comp_id
      into vcompid
      from pcs.pc_comp c
         , pcs.pc_scrip s
     where c.pc_scrip_id = s.pc_scrip_id
       and s.scrdbowner = user;

    vdefaultshopuser                                          :=
                                                       pcs.pc_config.getconfig('BC4J_SHOP_DEFAULT_PCS_USER', vcompid, 1);
    pcs.PC_I_LIB_SESSION.setcompanyid(vcompid);
    pcs.PC_I_LIB_SESSION.setuser(vdefaultshopuser);
    doc_document_generate.resetdocumentinfo(doc_document_initialize.documentinfo);
    doc_document_initialize.documentinfo.clear_document_info  := 0;
    doc_document_initialize.documentinfo.dmt_number           := pdmtnumber;
    doc_document_generator.generatedocument(ainterfaceid          => pdocinterfaceid
                                          , aerrormsg             => errmsg
                                          , anewdocumentsidlist   => listdocid
                                           );

    select dmt_number
      into vdmtnumber
      from doc_document
     where instr(',' || listdocid || ',', ',' || to_char(doc_document_id) || ',') > 0
       and rownum = 1;

    select doc_document_id
      into docid
      from doc_document
     where dmt_number = vdmtnumber;

    msg                                                       := docid;
    return 2;
  end;

  /**
  *  correspond à SetGeneratedOrderUpdatable de la v1
  *  supprime le document et réactive le docInterface
  */
  function orderupdatable(plsqlparamprefix1 in doc_document.dmt_number%type, pecousersid in number, pmsg out varchar2)
    return number
  is
  begin
    return null;
  end;

  /**
  * correspond à SetgeneratedorderCancel de la v1
    supprime le document ainsi que docInterface
  */
  function ordercancel(plsqlparamprefix1 in doc_document.dmt_number%type, pecousersid in number, pmsg out varchar2)
    return number
  is
  begin
    return null;
  end;

  /**
  * correspond à WEB_SHOP_FUNCTIONS_STD.SetGeneratedOrderValidate de la v1
    confirm le DocDocument
  */
  function orderconfirm(plsqlparamprefix1 in doc_document.dmt_number%type, pecousersid in number, pmsg out varchar2)
    return number
  is
  begin
    return null;
  end;

  /**
  *  Supprime de la table DOC_INTERFACE
  */
  function orderdelete(adocinterfaceid in doc_interface.doc_interface_id%type)
    return number
  is
  begin
    delete      doc_interface
          where doc_interface_id = adocinterfaceid;

    return web_functions.return_ok;
  end;
end web_shopv2_order_mgm;
