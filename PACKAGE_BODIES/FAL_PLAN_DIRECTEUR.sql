--------------------------------------------------------
--  DDL for Package Body FAL_PLAN_DIRECTEUR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PLAN_DIRECTEUR" 
is
  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.PartnerIsAGroup instead.
  */
  function PartnerIsAGroup(Partner FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type)
    return number
  is
  begin
    return FAL_I_PRC_MASTER_PLAN.PartnerIsAGroup(Partner);
  end PartnerIsAGroup;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.DuplicatePicLine instead.
  */
  procedure Duplicate_PIC_Line(Old_Pic_ID number, New_Pic_ID number, Copie_Prev number)
  is
  begin
    FAL_PRC_MASTER_PLAN.DuplicatePicLine(Old_Pic_ID, New_Pic_ID, Copie_Prev);
  end Duplicate_PIC_Line;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.Generation_Lignes_PIC_1 instead.
  */
  procedure Generation_Lignes_PIC_1(
    Pic_ID                   number
  , Revision                 number
  , structure                FAL_PIC.C_PIC_STRUCTURE%type
  , PicByProduct             FAL_PIC.PIC_BY_PRODUCT%type
  , PicValueCostprice        FAL_PIC.PIC_VALUE_COSTPRICE%type
  , DicTariffId              FAL_PIC.DIC_TARIFF_ID%type
  , DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type
  , Init_Prev                integer
  , Begin_Date               date
  , End_Date                 date
  , StoredProc_ID            number
  , PIC_Status               FAL_PIC.C_PIC_STATUS%type
  )
  is
  begin
    FAL_PRC_MASTER_PLAN.Generation_Lignes_PIC_1(Pic_ID
                                              , Revision
                                              , structure
                                              , PicByProduct
                                              , PicValueCostprice
                                              , DicTariffId
                                              , DicFixedCostpriceDescrId
                                              , Init_Prev
                                              , Begin_Date
                                              , End_Date
                                              , StoredProc_ID
                                              , PIC_Status
                                               );
  end Generation_Lignes_PIC_1;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.MiseAJourRealise instead.
  */
  procedure MiseAJourRealise
  is
  begin
    FAL_PRC_MASTER_PLAN.MiseAJourRealise;
  end MiseAJourRealise;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.ProcessusMajQteCmdPicLine instead.
  */
  procedure ProcessusMajQteCmdPicLine(
    PrmGCO_GOOD_ID           GCO_GOOD.GCO_GOOD_ID%type
  , PrmFAN_END_PLAN          date
  , PrmPAC_THIRD_ID          PAC_THIRD.PAC_THIRD_ID%type
  , PrmPAC_REPRESENTATIVE_ID PAC_REPRESENTATIVE.PAC_REPRESENTATIVE_ID%type
  , PrmPDE_BALANCE_QUANTITY  DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type
  , prmDIC_PIC_GROUP_ID      DIC_PIC_GROUP.DIC_PIC_GROUP_ID%type
  )
  is
  begin
    FAL_PRC_MASTER_PLAN.ProcessusMajQteCmdPicLine(PrmGCO_GOOD_ID
                                                , PrmFAN_END_PLAN
                                                , PrmPAC_THIRD_ID
                                                , PrmPAC_REPRESENTATIVE_ID
                                                , PrmPDE_BALANCE_QUANTITY
                                                , prmDIC_PIC_GROUP_ID
                                                 );
  end ProcessusMajQteCmdPicLine;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.CheckTableFormuleEtInitQty instead.
  */
  procedure CheckTableFormuleEtInitQty(aDisplayComponent varchar2 default 'VCI')
  is
  begin
    FAL_PRC_MASTER_PLAN.CheckTableFormuleEtInitQty(aDisplayComponent);
  end CheckTableFormuleEtInitQty;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.deletePicLines instead.
  */
  procedure Suppr_Pic_Line(FalPicId number, DateFin date)
  is
  begin
    FAL_PRC_MASTER_PLAN.deletePicLines(FalPicId, DateFin);
  end Suppr_Pic_Line;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.Calcul_Appro instead.
  */
  function Calcul_Appro(GoodId number, DateDebut date, PivotDate FAL_PIC.PIC_PIVOT_DATE%type)
    return number
  is
  begin
    return FAL_PRC_MASTER_PLAN.Calcul_Appro(GoodId, DateDebut, PivotDate);
  end Calcul_Appro;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.MajValorisation instead.
  */
  procedure MajValorisation(
    FalPicId                 number
  , PicValueCostprice        FAL_PIC.PIC_VALUE_COSTPRICE%type
  , DicTariffId              FAL_PIC.DIC_TARIFF_ID%type
  , DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type
  )
  is
  begin
    FAL_PRC_MASTER_PLAN.MajValorisation(FalPicId, PicValueCostprice, DicTariffId, DicFixedCostpriceDescrId);
  end MajValorisation;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.UpdateOrdersActiveMasterPlan instead.
  */
  procedure UpdateOrdersActiveMasterPlan
  is
  begin
    FAL_PRC_MASTER_PLAN.UpdateOrdersActiveMasterPlan;
  end UpdateOrdersActiveMasterPlan;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.Valid_Revision instead.
  */
  procedure Valid_Revision(FalPicId number)
  is
  begin
    FAL_PRC_MASTER_PLAN.Valid_Revision(FalPicId);
  end Valid_Revision;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.PrepareFalPicLineToDisplay instead.
  */
  procedure PrepareFalPicLineToDisplay(UserCode number)
  is
  begin
    FAL_PRC_MASTER_PLAN.PrepareFalPicLineToDisplay(UserCode);
  end PrepareFalPicLineToDisplay;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.DispatchFalPicLineTemp instead.
  */
  procedure DispatchFalPicLineTemp(UserCode number, ModifPDP number, InRevision number)
  is
  begin
    FAL_PRC_MASTER_PLAN.DispatchFalPicLineTemp(UserCode, ModifPDP, InRevision);
  end DispatchFalPicLineTemp;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use FAL_PRC_MASTER_PLAN.DispatchFalPicLineTemp instead.
  */
  procedure DeleteFalPicLineTemp(aPIT_SESSION varchar2)
  is
  begin
    FAL_PRC_MASTER_PLAN.DeleteFalPicLineTemp(aPIT_SESSION);
  end DeleteFalPicLineTemp;
end;
