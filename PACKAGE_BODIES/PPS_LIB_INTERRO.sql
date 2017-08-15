--------------------------------------------------------
--  DDL for Package Body PPS_LIB_INTERRO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_LIB_INTERRO" 
is
  /**
  * Description
  *    Retourne une expression SQL donnant la liste des matières précieuses
  *    contenue dans la table PPS_INTERRO_ALLOY
  */
  procedure GetAlloyColumnsListForSql(iBeginDate in date, oSqlExpression in out clob, oAlloyList out varchar2)
  is
    lBatchReceiptWeight   varchar2(2000);
    lMatMvtWeight         varchar2(2000);
    lCptMvtWeight         varchar2(2000);
    lvBeginDateExpression varchar2(100)  := 'TO_DATE(''' || to_char(iBeginDate, 'DD.MM.YYYY') || ''',''DD.MM.YYYY'')';
  begin
    for ltplAlloy in (select distinct IPM.GCO_ALLOY_ID
                                    , GAL.GAL_ALLOY_REF
                                 from PPS_INTERRO_ALLOY IPM
                                    , GCO_ALLOY GAL
                                where GAL.GCO_ALLOY_ID = IPM.GCO_ALLOY_ID) loop
      oSqlExpression  :=
        oSqlExpression ||
        ', [CO].GCO_I_LIB_ALLOY.GetAlloyInitialWeight(' ||
        ltplAlloy.GCO_ALLOY_ID ||
        ' , PPI.GCO_GOOD_ID, nvl(PPI.COM_UTIL_COEFF,1), nvl(PPI.COM_REF_QTY,1)) ' ||
        'IW_' ||
        ltplAlloy.GCO_ALLOY_ID ||
        CO.cLineBreak ||
        ', [CO].GCO_I_LIB_ALLOY.GetAlloyNewWeight(' ||
        ltplAlloy.GCO_ALLOY_ID ||
        ' , PPI.GCO_GOOD_ID, nvl(PPI.COM_UTIL_COEFF,1), nvl(PPI.COM_REF_QTY,1)) ' ||
        'NW_' ||
        ltplAlloy.GCO_ALLOY_ID;

      if oAlloyList is not null then
        oAlloyList  := oAlloyList || ';' || ltplAlloy.GCO_ALLOY_ID;
      else
        oAlloyList  := ltplAlloy.GCO_ALLOY_ID;
      end if;
/*  pas implémenté pour l'instant
      -- pesées lors des réception d'OF
      if lBatchReceiptWeight is not null then
        lBatchReceiptWeight  := lBatchReceiptWeight || ' + ';
      else
        lBatchReceiptWeight  := ', ';
      end if;

      lBatchReceiptWeight  :=
        lBatchReceiptWeight ||
        ' [CO].GCO_I_LIB_ALLOY.GetAlloyBatchReceiptWeight(' ||
        ltplAlloy.GCO_ALLOY_ID ||
        ' , PPI.GCO_GOOD_ID, nvl(PPI.COM_UTIL_COEFF,1), nvl(PPI.COM_REF_QTY,1),' ||
        lvBeginDateExpression ||
        ' ) ';

      -- pesées lors des mouvements matières précieuses
      if lMatMvtWeight is not null then
        lMatMvtWeight  := lMatMvtWeight || ' + ';
      else
        lMatMvtWeight  := ', ';
      end if;

      lMatMvtWeight        :=
        lMatMvtWeight ||
        ' [CO].GCO_I_LIB_ALLOY.GetAlloyMatMvtWeight(' ||
        ltplAlloy.GCO_ALLOY_ID ||
        ' , PPI.GCO_GOOD_ID, nvl(PPI.COM_UTIL_COEFF,1), nvl(PPI.COM_REF_QTY,1),' ||
        lvBeginDateExpression ||
        ' ) ';

      -- pesées lors des mouvements composants
      if lCptMvtWeight is not null then
        lCptMvtWeight  := lCptMvtWeight || ' + ';
      else
        lCptMvtWeight  := ', ';
      end if;

      lCptMvtWeight        :=
        lCptMvtWeight ||
        ' [CO].GCO_I_LIB_ALLOY.GetAlloyCptMvtWeight(' ||
        ltplAlloy.GCO_ALLOY_ID ||
        ' , PPI.GCO_GOOD_ID, nvl(PPI.COM_UTIL_COEFF,1), nvl(PPI.COM_REF_QTY,1),' ||
        lvBeginDateExpression ||
        ' ) ';
*/
    end loop;
/*
    oSqlExpression  := oSqlExpression || nvl(lBatchReceiptWeight, ', CAST(NULL as number(15,4))') || ' GetAlloyBatchReceiptWeight';
    oSqlExpression  := oSqlExpression || nvl(lMatMvtWeight, ', CAST(NULL as number(15,4))') || ' GetAlloyMatMvtWeight';
    oSqlExpression  := oSqlExpression || nvl(lCptMvtWeight, ', CAST(NULL as number(15,4))') || ' GetAlloyCptMvtWeight';
*/
  end GetAlloyColumnsListForSql;

  /**
  * Description
  *   retourne 1 si le bien a des alliages dans PPS_INTERRO_ALLOY
  */
  function IsAlloyGood(iGoodId in PPS_INTERROGATION.GCO_GOOD_ID%type)
    return number
  is
    lResult number(1);
  begin
    if GCO_I_LIB_ALLOY.IsGoodPreciousMat(iGoodId) = 1 then
      select 2 * sign(count(*) )
        into lResult
        from PPS_INTERRO_ALLOY
       where GCO_GOOD_ID = iGoodId
         and C_GPM_UPDATE_TYPE in('1', '2', '3');

      if lResult = 0 then
        select sign(count(*) )
          into lResult
          from PPS_INTERRO_ALLOY
         where GCO_GOOD_ID = iGoodId;
      end if;
    end if;

    return lResult;
  end IsAlloyGood;

  /**
  * Description
  *   Indique si un bien est déjà dans la table d'interrogation (utile pour la
  *   recherche des cas d'emplois afin de ne pas être redondant)
  */
  function IsGoodAlreadyThere(
    iNomenclatureId      in PPS_INTERROGATION.GCO_GOOD_ID%type
  , iChildNomenclatureId in PPS_INTERROGATION.GCO_GOOD_ID%type
  , iChildGoodId         in PPS_INTERROGATION.GCO_GOOD_ID%type
  )
    return number
  is
    lnMode number(1);
  begin
    -- le champ indique si on a déjà traité le bien dans la boucle
    select distinct 1
               into lnMode
               from PPS_INTERROGATION
              where PPS_NOMENCLATURE_ID = iNomenclatureId
                and nvl(PPS_PPS_NOMENCLATURE_ID, 0) = nvl(iChildNomenclatureId, 0)
                and GCO_GOOD_ID = iChildGoodId;

    return lnMode;
  exception
    when no_data_found then
      return 0;
  end IsGoodAlreadyThere;

  /**
  * function IsBondInVariantList
  * Description
  *   Indique si le composant (bien) figure pour la liste des variantes proposées
  */
  function IsBondInVariantList(iNomBondID in PPS_NOM_BOND.PPS_NOM_BOND_ID%type, iVariantListID in varchar2)
    return number
  is
    cursor lcrVariant
    is
      select distinct A.PPS_FIXED_VARIANT_ID
                 from PPS_NOM_BON_S_PPS_VAR_VAL A
                where A.PPS_NOM_BOND_ID = iNomBondID
      minus
      select distinct B.PPS_FIXED_VARIANT_ID
                 from PPS_NOM_BON_S_PPS_VAR_VAL B
                    , table(idListToTable(iVariantListID) ) idlist
                where B.PPS_NOM_BOND_ID = iNomBondID
                  and B.PPS_VARIANT_VALUE_ID = idlist.column_value;

    ltplVariant lcrVariant%rowtype;
    lnResult    number(1);
  begin
    open lcrVariant;

    fetch lcrVariant
     into ltplVariant;

    if lcrVariant%found then
      lnResult  := 0;
    else
      lnResult  := 1;
    end if;

    close lcrVariant;

    return lnResult;
  end IsBondInVariantList;
end PPS_LIB_INTERRO;
