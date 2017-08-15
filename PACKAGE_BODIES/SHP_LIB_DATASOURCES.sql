--------------------------------------------------------
--  DDL for Package Body SHP_LIB_DATASOURCES
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_LIB_DATASOURCES" 
as
  /**
  * function pGetNomenclatureID
  * Description
  *    Retourne dans l'ordre la nomenclature par défaut du SAV puis celle du production si existantes
  * @created AGE 05.07.2012
  * @lastUpdate
  * @public
  * @param iGoodID : ID Bien pour lequel on recherche la nomenclature
  * @return : Voir description
  */
  function pGetNomenclatureID(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  as
    cursor curBom(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select   1 seq
             , PPS_NOMENCLATURE_ID
          from PPS_NOMENCLATURE
         where GCO_GOOD_ID = iGoodID
           and C_TYPE_NOM = '8'   -- Service après-vente
           and NOM_DEFAULT = 1
      union
      select   2 seq
             , PPS_NOMENCLATURE_ID
          from PPS_NOMENCLATURE
         where GCO_GOOD_ID = iGoodID
           and C_TYPE_NOM = '2'   -- Production
           and NOM_DEFAULT = 1
      order by seq;

    ltplBom curBom%rowtype;
  begin
    /* On ne retourne que la première nomenclature trouvée s'il y en a plusieurs. */
    open curBom(iGoodID => iGoodID);

    fetch curBom
     into ltplBom;

    close curBom;

    return ltplBom.PPS_NOMENCLATURE_ID;
  end pGetNomenclatureID;

  /**
  * Description
  *    Source de données pour les descriptions de produit
  */
  function dataSource4Descriptions(inGcoGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return SHP_LIB_TYPES.ttDescriptions pipelined
  is
    ltDescription       SHP_LIB_TYPES.tDescription;
    lvGooMajorReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lvDesShort01        GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    lvDesLong01         GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
    lvDesFree01         GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    lvDesShort09        GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    lvDesLong09         GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
    lvDesFree09         GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    lvDesShort10        GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    lvDesLong10         GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
    lvDesFree10         GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
  begin
    select max(GOO_MAJOR_REFERENCE)
      into lvGooMajorReference
      from GCO_GOOD
     where GCO_GOOD_ID = inGcoGoodID;

    for ltplLang in (select   PC_LANG_ID
                            , LAN_ISO_CODE_SHORT
                         from PCS.PC_LANG
                        where LANUSED = 1
                     order by PC_LANG_ID) loop
      ltDescription.LAN_ISO_CODE_SHORT  := ltplLang.LAN_ISO_CODE_SHORT;

      -- description principale
      select max(des.DES_SHORT_DESCRIPTION)
           , max(des.DES_LONG_DESCRIPTION)
           , max(des.DES_FREE_DESCRIPTION)
        into lvDesShort09
           , lvDesLong09
           , lvDesFree09
        from GCO_DESCRIPTION des
           , GCO_GOOD goo
       where goo.GCO_GOOD_ID = inGcoGoodID
         and goo.GCO_GOOD_ID = des.GCO_GOOD_ID
         and des.PC_LANG_ID = ltplLang.PC_LANG_ID
         and des.C_DESCRIPTION_TYPE = '09';

      select max(des.DES_SHORT_DESCRIPTION)
           , max(des.DES_LONG_DESCRIPTION)
           , max(des.DES_FREE_DESCRIPTION)
        into lvDesShort01
           , lvDesLong01
           , lvDesFree01
        from GCO_DESCRIPTION des
           , GCO_GOOD goo
       where goo.GCO_GOOD_ID = inGcoGoodID
         and goo.GCO_GOOD_ID = des.GCO_GOOD_ID
         and des.PC_LANG_ID = ltplLang.PC_LANG_ID
         and des.C_DESCRIPTION_TYPE = '01';

      ltDescription.MAIN_SHORT_DESCR    := nvl(nvl(lvDesShort09, lvDesShort01), lvGooMajorReference);
      ltDescription.MAIN_LONG_DESCR     := nvl(nvl(lvDesLong09, lvDesLong01), lvGooMajorReference);
      ltDescription.MAIN_FREE_DESCR     := nvl(nvl(lvDesFree09, lvDesFree01), lvGooMajorReference);

      -- description meta
      select max(des10.DES_SHORT_DESCRIPTION)
           , max(des10.DES_LONG_DESCRIPTION)
           , max(des10.DES_FREE_DESCRIPTION)
        into lvDesShort10
           , lvDesLong10
           , lvDesFree10
        from GCO_DESCRIPTION des10
           , GCO_GOOD goo
       where goo.GCO_GOOD_ID = inGcoGoodID
         and goo.GCO_GOOD_ID = des10.GCO_GOOD_ID
         and des10.PC_LANG_ID = ltplLang.PC_LANG_ID
         and des10.C_DESCRIPTION_TYPE = '10';

      ltDescription.META_SHORT_DESCR    := nvl(lvDesShort10, lvGooMajorReference);
      ltDescription.META_LONG_DESCR     := nvl(lvDesLong10, lvGooMajorReference);
      ltDescription.META_FREE_DESCR     := nvl(lvDesFree10, lvGooMajorReference);

      if    ltDescription.MAIN_SHORT_DESCR is not null
         or ltDescription.MAIN_LONG_DESCR is not null
         or ltDescription.MAIN_FREE_DESCR is not null
         or ltDescription.META_SHORT_DESCR is not null
         or ltDescription.META_LONG_DESCR is not null
         or ltDescription.META_FREE_DESCR is not null then
        pipe row(ltDescription);
      end if;
    end loop;
  exception
    when no_data_needed then
      return;
  end dataSource4Descriptions;

  /**
  * function
  * Description
  *    Source de données pour la quantité en stock d'un produit
  */
  function dataSource4Quantity(inGcoGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return SHP_LIB_TYPES.ttQuantities pipelined
  is
    ltQquantity SHP_LIB_TYPES.tQuantity;
  begin
    for ltplQuantity in (select spo.SPO_AVAILABLE_QUANTITY
                              , spo.STM_STOCK_ID
                              , spo.STM_LOCATION_ID
                           from STM_STOCK_POSITION spo
                              , STM_STOCK sto
                              , STM_LOCATION stl
                          where spo.GCO_GOOD_ID = inGcoGoodID
                            and spo.STM_STOCK_ID = sto.STM_STOCK_ID
                            and spo.STM_LOCATION_ID = stl.STM_LOCATION_ID
                            and sto.C_ACCESS_METHOD = 'PUBLIC'
                            and sto.STO_SHOP_USE = 1) loop
      ltQquantity.GCO_PRODUCT_ID          := inGcoGoodId;
      ltQquantity.STM_STOCK_ID            := ltplQuantity.STM_STOCK_ID;
      ltQquantity.STM_LOCATION_ID         := ltplQuantity.STM_LOCATION_ID;
      ltQquantity.SPO_AVAILABLE_QUANTITY  := ltplQuantity.SPO_AVAILABLE_QUANTITY;
      pipe row(ltQquantity);
    end loop;
  exception
    when no_data_needed then
      return;
  end dataSource4Quantity;

  /**
  * Description
  *    Source de données pour la récupération des images d'un élément selon son contexte,
  *    sa clef primaire et son type. Va retourner les images trouvées pour l'éléments
  *    (DIC_IMAGE_TYPE_ID like 'SHP-[ivPictureType]-%')
  */
  function dataSource4Pictures(inRecID in COM_IMAGE_FILES.IMF_REC_ID%type, ivContext in COM_IMAGE_FILES.IMF_TABLE%type, ivPictureType in varchar2)
    return SHP_LIB_TYPES.ttPictures pipelined
  as
    ltPicture SHP_LIB_TYPES.tPicture;
  begin
    for ltplPicture in (select DIC_IMAGE_TYPE_ID
                             , IMF_PATHFILE
                          from COM_IMAGE_FILES
                         where IMF_REC_ID = inRecId
                           and IMF_TABLE = ivContext
                           and instr(DIC_IMAGE_TYPE_ID, decode(ivPictureType, 'M', 'SHP-M', 'A', 'SHP-A', 'T', 'SHP-T', 'P', 'SHP-P', 'B', 'SHP-B') ) > 0) loop
      ltPicture.PICTURE_GROUP  := substr(ltplPicture.DIC_IMAGE_TYPE_ID, 1, 8);
      ltPicture.PICTURE_SIZE   := lower(substr(ltplPicture.DIC_IMAGE_TYPE_ID, -1) );
      ltPicture.URL            := ltplPicture.IMF_PATHFILE;
      pipe row(ltPicture);
    end loop;
  exception
    when no_data_needed then
      return;
  end dataSource4Pictures;

  /**
  * Description
  *    Source de données pour la récupération des documents d'un élément selon son contexte,
  *    son ID et son type. Va retourner les documents trouvées pour l'éléments
  *    (DIC_IMAGE_TYPE_ID like 'SHP-[ivPictureType]-%')
  */
  function dataSource4AdditionalDocs(inRecID in COM_IMAGE_FILES.IMF_REC_ID%type, ivContext in COM_IMAGE_FILES.IMF_TABLE%type, ivDocType in varchar2)
    return SHP_LIB_TYPES.ttAdditionalDocs pipelined
  as
    ltDoc SHP_LIB_TYPES.tAdditionalDoc;
  begin
    for ltplDoc in (select DIC_IMAGE_TYPE_ID
                         , IMF_PATHFILE
                      from COM_IMAGE_FILES
                     where IMF_REC_ID = inRecId
                       and IMF_TABLE = ivContext
                       and instr(DIC_IMAGE_TYPE_ID, decode(ivDocType, 'D', 'SHP-D') ) > 0) loop   /* Decode laissé pour de futurs autres types de documents */
      ltDoc.DOC_GROUP  := substr(ltplDoc.DIC_IMAGE_TYPE_ID, 1, 8);
      ltDoc.URL        := ltplDoc.IMF_PATHFILE;
      pipe row(ltDoc);
    end loop;
  exception
    when no_data_needed then
      return;
  end dataSource4AdditionalDocs;

  /**
  * Description
  *    Source de données pour la récupération données de classification du bien transmis en paramètre.
  */
  function dataSource4Classif(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return SHP_LIB_TYPES.ttClassifValues pipelined
  as
    lClassifValue SHP_LIB_TYPES.tClassifValue;
  begin
    for ltplClassifValue in (select 1 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_1_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_1_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_1'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 2 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_2_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_2_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_2'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 3 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_3_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_3_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_3'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 4 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_4_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_4_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_4'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 5 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_5_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_5_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_5'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 6 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_6_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_6_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_6'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 7 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_7_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_7_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_7'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 8 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_8_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_8_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_8'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 9 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_9_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_9_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_9'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 10 CLASSIF_INDEX
                                  , goo.DIC_GCO_STATISTIC_10_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GCO_STATISTIC_10_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GCO_STATISTIC_10'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 11 CLASSIF_INDEX
                                  , goo.DIC_GOOD_LINE_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GOOD_LINE_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GOOD_LINE'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 12 CLASSIF_INDEX
                                  , goo.DIC_GOOD_FAMILY_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GOOD_FAMILY_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GOOD_FAMILY'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 13 CLASSIF_INDEX
                                  , goo.DIC_GOOD_GROUP_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GOOD_GROUP_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GOOD_GROUP'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 14 CLASSIF_INDEX
                                  , goo.DIC_GOOD_MODEL_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GOOD_MODEL_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GOOD_MODEL'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 15 CLASSIF_INDEX
                                  , goo.DIC_GOO_WEB_CATEG1_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GOO_WEB_CATEG1_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GOO_WEB_CATEG1'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 16 CLASSIF_INDEX
                                  , goo.DIC_GOO_WEB_CATEG2_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GOO_WEB_CATEG2_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GOO_WEB_CATEG2'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 17 CLASSIF_INDEX
                                  , goo.DIC_GOO_WEB_CATEG3_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GOO_WEB_CATEG3_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GOO_WEB_CATEG3'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1
                             union all
                             select 18 CLASSIF_INDEX
                                  , goo.DIC_GOO_WEB_CATEG4_ID CLASSIF_VALUE
                                  , lan.LAN_ISO_CODE_SHORT CLASSIF_LAN_ISO_CODE_SHORT
                                  , dit.DIT_DESCR CLASSIF_DESCRIPTION_01
                                  , dit.DIT_DESCR2 CLASSIF_DESCRIPTION_02
                               from GCO_GOOD goo
                                  , DICO_DESCRIPTION dit
                                  , pcs.PC_LANG lan
                              where goo.GCO_GOOD_ID = iGoodId
                                and goo.DIC_GOO_WEB_CATEG4_ID = dit.DIT_CODE
                                and dit.DIT_TABLE = 'DIC_GOO_WEB_CATEG4'
                                and dit.PC_LANG_ID = lan.PC_LANG_ID
                                and lan.LANUSED = 1) loop
      pipe row(ltplClassifValue);
    end loop;
  exception
    when no_data_needed then
      return;
  end dataSource4Classif;

  /**
  * Description
  *    Source de données pour les composants d'un bien. Les composants sont trié
  *    par numéro de séquence (COM_SEQ) de la nomenclature
  */
  function dataSource4ComponentsComSeq(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return SHP_LIB_TYPES.ttComponents pipelined
  is
    ltComponent     SHP_LIB_TYPES.tComponent;
    lNomenclatureID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    lNomenclatureID  := pGetNomenclatureID(iGoodID => iGoodID);

    if lNomenclatureID is not null then
      for ltplComponent in (select   COM_SEQ BOM_INDEX
                                   , GCO_GOOD_ID
                                from PPS_NOM_BOND
                               where PPS_NOMENCLATURE_ID = lNomenclatureID
                                 and GCO_GOOD_ID is not null
                            order by nvl(COM_SEQ, 0) ) loop
        ltComponent.BOM_INDEX     := ltplComponent.BOM_INDEX;
        ltComponent.BOM_SEQUENCE  := ltplComponent.BOM_INDEX;
        ltComponent.GCO_GOOD_ID   := ltplComponent.GCO_GOOD_ID;
        pipe row(ltComponent);
      end loop;
    end if;
  exception
    when no_data_needed then
      return;
  end dataSource4ComponentsComSeq;

  /**
  * Description
  *    Source de données pour les composants d'un bien. Les composants sont trié
  *    par numéro de position (COM_POS) de la nomenclature
  */
  function dataSource4ComponentsComPos(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return SHP_LIB_TYPES.ttComponents pipelined
  is
    ltComponent     SHP_LIB_TYPES.tComponent;
    lNomenclatureID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    lNomenclatureID  := pGetNomenclatureID(iGoodID => iGoodID);

    if lNomenclatureID is not null then
      for ltplComponent in (select   nvl(COM_POS, '0') BOM_INDEX
                                   , COM_SEQ
                                   , GCO_GOOD_ID
                                from PPS_NOM_BOND
                               where PPS_NOMENCLATURE_ID = lNomenclatureID
                                 and GCO_GOOD_ID is not null
                            order by nvl(COM_SEQ, 0) ) loop
        ltComponent.BOM_INDEX     := ltplComponent.BOM_INDEX;
        ltComponent.BOM_SEQUENCE  := ltplComponent.COM_SEQ;
        ltComponent.GCO_GOOD_ID   := ltplComponent.GCO_GOOD_ID;
        pipe row(ltComponent);
      end loop;
    end if;
  exception
    when no_data_needed then
      return;
  end dataSource4ComponentsComPos;

  /**
  * Description
  *    Source de données pour les composants d'un bien. Les composants sont trié
  *    par la réserve numérique (COM_RES_NUM) de la nomenclature
  */
  function dataSource4ComponentsComResNum(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return SHP_LIB_TYPES.ttComponents pipelined
  is
    ltComponent     SHP_LIB_TYPES.tComponent;
    lNomenclatureID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
  begin
    lNomenclatureID  := pGetNomenclatureID(iGoodID => iGoodID);

    if lNomenclatureID is not null then
      for ltplComponent in (select   nvl(COM_RES_NUM, 0) BOM_INDEX
                                   , COM_SEQ
                                   , GCO_GOOD_ID
                                from PPS_NOM_BOND
                               where PPS_NOMENCLATURE_ID = lNomenclatureID
                                 and GCO_GOOD_ID is not null
                            order by nvl(COM_SEQ, 0) ) loop
        ltComponent.BOM_INDEX     := ltplComponent.BOM_INDEX;
        ltComponent.BOM_SEQUENCE  := ltplComponent.COM_SEQ;
        ltComponent.GCO_GOOD_ID   := ltplComponent.GCO_GOOD_ID;
        pipe row(ltComponent);
      end loop;
    end if;
  exception
    when no_data_needed then
      return;
  end dataSource4ComponentsComResNum;

  /**
  * Description
  *    Source de données pour le status du document
  */
  function dataSource4Document(inDocDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return SHP_LIB_TYPES.ttDocumentStatus pipelined
  as
    ltDocumentStatus SHP_LIB_TYPES.tDocumentStatus;
  begin
    for ltplDocumentStatus in (select DOC_DOCUMENT_ID
                                    , DMT_PARTNER_NUMBER
                                    , C_DOCUMENT_STATUS
                                    , DMT_BALANCED
                                    , A_DATECRE
                                    , A_DATEMOD
                                 from DOC_DOCUMENT
                                where DOC_DOCUMENT_ID = inDocDocumentID) loop
      ltDocumentStatus.SHOP_ORDERID      := ltplDocumentStatus.DMT_PARTNER_NUMBER;
      ltDocumentStatus.EXTERNAL_ORDERID  := ltplDocumentStatus.DOC_DOCUMENT_ID;
      ltDocumentStatus.SHOP_STATUS_CODE  :=
             SHP_LIB_DOCUMENT.getShopFromErpDocStatus(ivErpDocStatus   => ltplDocumentStatus.C_DOCUMENT_STATUS
                                                    , inDmtBalanced    => ltplDocumentStatus.DMT_BALANCED);
      ltDocumentStatus.UPDATE_DATETIME   := SHP_LIB_UTL.toDate1970Based(nvl(ltplDocumentStatus.A_DATEMOD, ltplDocumentStatus.A_DATECRE) );
      pipe row(ltDocumentStatus);
    end loop;
  exception
    when no_data_needed then
      return;
  end dataSource4Document;

  /**
  * Description
  *    Source de données pour les informations de l'utilisateur Web
  */
  function dataSource4UserInfos(
    iWebUserID                 in PCS.PC_USER.PC_USER_ID%type
  , iPhoneDicCommunicationID   in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iFaxDicCommunicationID     in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iWebSiteDicCommunicationID in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  )
    return SHP_LIB_TYPES.ttUserInfos pipelined
  as
    ltUserInfo SHP_LIB_TYPES.tUserInfo;
  begin
    for ltplUserInfos in (select per.DIC_PERSON_POLITNESS_ID TITLE
                               , weu.WEU_FIRST_NAME FIRSTNAME
                               , weu.WEU_LAST_NAME LASTNAME
                               , per.PER_NAME COMPANY
                               , weu.WEU_EMAIL EMAIL
                               , (select com.COM_AREA_CODE || ' ' || com.COM_EXT_NUMBER
                                    from PAC_COMMUNICATION com
                                   where com.PAC_PERSON_ID = weu.PAC_CUSTOM_PARTNER_ID
                                     and com.DIC_COMMUNICATION_TYPE_ID = iPhoneDicCommunicationID) PHONE
                               , (select com.COM_AREA_CODE || ' ' || com.COM_EXT_NUMBER
                                    from PAC_COMMUNICATION com
                                   where com.PAC_PERSON_ID = weu.PAC_CUSTOM_PARTNER_ID
                                     and com.DIC_COMMUNICATION_TYPE_ID = iFaxDicCommunicationID) FAX
                               , (select com.COM_EXT_NUMBER
                                    from PAC_COMMUNICATION com
                                   where com.PAC_PERSON_ID = weu.PAC_CUSTOM_PARTNER_ID
                                     and com.DIC_COMMUNICATION_TYPE_ID = iWebSiteDicCommunicationID) WEBSITE
                               , case pac.DIC_TYPE_SUBMISSION_ID
                                   when '0' then '0'
                                   else '1'
                                 end TAX_EXEMPT
                               , nvl(lan_user.LAN_ISO_CODE_SHORT, lan_addr.LAN_ISO_CODE_SHORT) USER_LANGUAGE
                               , cur.CURRENCY CURRENCY
                               , (select nvl(max(WEG.WEB_GROUP_VISUAL_LEVEL), 0)
                                    from WEB_GROUP weg
                                       , WEB_USER_GROUP_ROLE wug
                                   where WEG.WEB_GROUP_ID = WUG.WEB_GROUP_ID
                                     and WUG.WEB_USER_ID = iWebUserID) DISPLAYABLE_PERMISSION_LEVEL
                               , (select nvl(max(WEG.WEB_GROUP_ORDER_LEVEL), 0)
                                    from WEB_GROUP weg
                                       , WEB_USER_GROUP_ROLE wug
                                   where WEG.WEB_GROUP_ID = WUG.WEB_GROUP_ID
                                     and WUG.WEB_USER_ID = iWebUserID) ORDERABLE_PERMISSION_LEVEL
                            from WEB_USER weu
                               , PAC_PERSON per
                               , PAC_CUSTOM_PARTNER pac
                               , pcs.PC_LANG lan_addr
                               , pcs.PC_LANG lan_user
                               , PAC_ADDRESS addr
                               , pcs.PC_CURR cur
                               , ACS_FINANCIAL_CURRENCY fin
                           where weu.WEB_USER_ID = iWebUserID
                             and per.PAC_PERSON_ID = weu.PAC_CUSTOM_PARTNER_ID
                             and pac.PAC_CUSTOM_PARTNER_ID = per.PAC_PERSON_ID
                             and addr.PAC_PERSON_ID(+) = weu.PAC_CUSTOM_PARTNER_ID
                             and addr.ADD_PRINCIPAL(+) = 1
                             and lan_addr.PC_LANG_ID(+) = addr.PC_LANG_ID
                             and lan_user.PC_LANG_ID(+) = weu.PC_LANG_ID
                             and fin.ACS_FINANCIAL_CURRENCY_ID = PAC_FUNCTIONS.GetCustomerCurrencyId(PPAC_CUSTOM_PARTNER_ID => weu.PAC_CUSTOM_PARTNER_ID)
                             and cur.PC_CURR_ID = fin.PC_CURR_ID
                             and web_user_id in(select wugr.WEB_USER_ID
                                                  from WEB_USER_GROUP_ROLE wugr
                                                     , WEB_GROUP weg
                                                 where wugr.WEB_GROUP_ID = weg.WEB_GROUP_ID
                                                   and upper(weg.WEG_GROUP_NAME) like '%SHOP%') ) loop
      ltUserInfo.TITLE                         := ltplUserInfos.TITLE;
      ltUserInfo.FIRSTNAME                     := ltplUserInfos.FIRSTNAME;
      ltUserInfo.LASTNAME                      := ltplUserInfos.LASTNAME;
      ltUserInfo.COMPANY                       := ltplUserInfos.COMPANY;
      ltUserInfo.EMAIL                         := ltplUserInfos.EMAIL;
      ltUserInfo.PHONE                         := ltplUserInfos.PHONE;
      ltUserInfo.FAX                           := ltplUserInfos.FAX;
      ltUserInfo.WEBSITE                       := ltplUserInfos.WEBSITE;
      ltUserInfo.TAX_EXEMPT                    := ltplUserInfos.TAX_EXEMPT;
      ltUserInfo.USER_LANGUAGE                 := ltplUserInfos.USER_LANGUAGE;
      ltUserInfo.CURRENCY                      := ltplUserInfos.CURRENCY;
      ltUserInfo.DISPLAYABLE_PERMISSION_LEVEL  := ltplUserInfos.DISPLAYABLE_PERMISSION_LEVEL;
      ltUserInfo.ORDERABLE_PERMISSION_LEVEL    := ltplUserInfos.ORDERABLE_PERMISSION_LEVEL;
      pipe row(ltUserInfo);
    end loop;
  exception
    when no_data_needed then
      return;
  end dataSource4UserInfos;

  /**
  * Description
  *    Source de données pour l'adresse de facturation de l'utilisteur Web
  */
  function dataSource4BillingAddress(iWebUserID in PCS.PC_USER.PC_USER_ID%type)
    return SHP_LIB_TYPES.ttUserAddresses pipelined
  as
    ltBillingAddress SHP_LIB_TYPES.tUserAddress;
  begin
    for ltplBillingAddress in (select per.DIC_PERSON_POLITNESS_ID TITLE
                                    , weu.WEU_FIRST_NAME FIRSTNAME
                                    , weu.WEU_LAST_NAME LASTNAME
                                    , substr(ExtractLine(aStrText => addr.ADD_ADDRESS1, aNoLine => 1), 1, 255) ADDRESS
                                    , substr(ExtractLine(aStrText => addr.ADD_ADDRESS1, aNoLine => 2), 1, 255) ADDRESS2
                                    , addr.ADD_ZIPCODE ZIPCODE
                                    , addr.ADD_CITY CITY
                                    , addr.ADD_STATE STATE
                                    , cnt.CNTID COUNTRY
                                    , null PHONE
                                 from WEB_USER weu
                                    , PAC_PERSON per
                                    , PAC_ADDRESS addr
                                    , pcs.PC_CNTRY cnt
                                where weu.WEB_USER_ID = iWebUserID
                                  and per.PAC_PERSON_ID = weu.PAC_CUSTOM_PARTNER_ID
                                  and addr.PAC_PERSON_ID(+) = weu.PAC_CUSTOM_PARTNER_ID
                                  and cnt.PC_CNTRY_ID = addr.PC_CNTRY_ID
                                  and addr.ADD_PRINCIPAL = 1) loop
      ltBillingAddress.TITLE      := ltplBillingAddress.TITLE;
      ltBillingAddress.FIRSTNAME  := ltplBillingAddress.FIRSTNAME;
      ltBillingAddress.LASTNAME   := ltplBillingAddress.LASTNAME;
      ltBillingAddress.ADDRESS    := ltplBillingAddress.ADDRESS;
      ltBillingAddress.ADDRESS2   := ltplBillingAddress.ADDRESS2;
      ltBillingAddress.ZIPCODE    := ltplBillingAddress.ZIPCODE;
      ltBillingAddress.CITY       := ltplBillingAddress.CITY;
      ltBillingAddress.STATE      := ltplBillingAddress.STATE;
      ltBillingAddress.COUNTRY    := ltplBillingAddress.COUNTRY;
      ltBillingAddress.PHONE      := ltplBillingAddress.PHONE;
      pipe row(ltBillingAddress);
    end loop;
  exception
    when no_data_needed then
      return;
  end dataSource4BillingAddress;

  /**
  * Description
  *    Source de données pour l'adresse d'expédition de l'utilisteur Web
  */
  function dataSource4ShippingAddress(iWebUserID in PCS.PC_USER.PC_USER_ID%type, iDicAddressTypeID in PAC_ADDRESS.DIC_ADDRESS_TYPE_ID%type)
    return SHP_LIB_TYPES.ttUserAddresses pipelined
  as
    ltShippingAddress SHP_LIB_TYPES.tUserAddress;
  begin
    for ltplShippingAddress in (select per.DIC_PERSON_POLITNESS_ID TITLE
                                     , weu.WEU_FIRST_NAME FIRSTNAME
                                     , weu.WEU_LAST_NAME LASTNAME
                                     , substr(ExtractLine(aStrText => addr.ADD_ADDRESS1, aNoLine => 1), 1, 255) ADDRESS
                                     , substr(ExtractLine(aStrText => addr.ADD_ADDRESS1, aNoLine => 2), 1, 255) ADDRESS2
                                     , addr.ADD_ZIPCODE ZIPCODE
                                     , addr.ADD_CITY CITY
                                     , addr.ADD_STATE STATE
                                     , cnt.CNTID COUNTRY
                                     , null PHONE
                                  from WEB_USER weu
                                     , PAC_PERSON per
                                     , PAC_ADDRESS addr
                                     , pcs.PC_CNTRY cnt
                                 where weu.WEB_USER_ID = iWebUserID
                                   and per.PAC_PERSON_ID = weu.PAC_CUSTOM_PARTNER_ID
                                   and cnt.PC_CNTRY_ID = addr.PC_CNTRY_ID
                                   and addr.PAC_ADDRESS_ID = (select max(PAC_ADDRESS_ID)
                                                                from PAC_ADDRESS
                                                               where PAC_PERSON_ID = weu.PAC_CUSTOM_PARTNER_ID
                                                                 and DIC_ADDRESS_TYPE_ID = iDicAddressTypeID) ) loop
      ltShippingAddress.TITLE      := ltplShippingAddress.TITLE;
      ltShippingAddress.FIRSTNAME  := ltplShippingAddress.FIRSTNAME;
      ltShippingAddress.LASTNAME   := ltplShippingAddress.LASTNAME;
      ltShippingAddress.ADDRESS    := ltplShippingAddress.ADDRESS;
      ltShippingAddress.ADDRESS2   := ltplShippingAddress.ADDRESS2;
      ltShippingAddress.ZIPCODE    := ltplShippingAddress.ZIPCODE;
      ltShippingAddress.CITY       := ltplShippingAddress.CITY;
      ltShippingAddress.STATE      := ltplShippingAddress.STATE;
      ltShippingAddress.COUNTRY    := ltplShippingAddress.COUNTRY;
      ltShippingAddress.PHONE      := ltplShippingAddress.PHONE;
      pipe row(ltShippingAddress);
    end loop;
  exception
    when no_data_needed then
      return;
  end dataSource4ShippingAddress;
end SHP_LIB_DATASOURCES;
