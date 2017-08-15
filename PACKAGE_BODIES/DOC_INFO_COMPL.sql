--------------------------------------------------------
--  DDL for Package Body DOC_INFO_COMPL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INFO_COMPL" 
is
  /**
  * Description
  *    Contrôle si les données obligatoires ont été saisies pour la table DOC_POSITION_CHARGE
  */
  procedure CtrlPCHInfoCompl(
    iPositionId    in     DOC_POSITION.DOC_POSITION_ID%type
  , oChargeOk      in out integer
  , oDiscountOK    in out integer
  , oRequiredField in out varchar2
  , oResult        in out integer
  )
  is
    cursor crPCHInfoCompl(iCrPositionId DOC_POSITION.DOC_POSITION_ID%type)
    is
      select MAN.C_DATA_TYP
           , nvl(GAS.GAS_VISIBLE_COUNT, 0) ACCOUNT_VISIBLE
           , decode(nvl(PCH.PTC_CHARGE_ID, 0), 0, 0, 1) PCH_CHARGE
           , decode(nvl(PCH.PTC_DISCOUNT_ID, 0), 0, 0, 1) PCH_DISCOUNT
           , decode(nvl(PCH.HRM_PERSON_ID, 0), 0, 0, 1) PCH_HRM_PERSON
           , decode(nvl(PCH.FAM_FIXED_ASSETS_ID, 0), 0, 0, 1) PCH_FAM_FIXED_ID
           , decode(nvl(PCH.C_FAM_TRANSACTION_TYP, 0), 0, 0, 1) PCH_FAM_TRA_TYP
           , decode(nvl(PCH.PCH_IMP_TEXT_1, '0'), '0', 0, 1) PCH_TEXT_1
           , decode(nvl(PCH.PCH_IMP_TEXT_2, '0'), '0', 0, 1) PCH_TEXT_2
           , decode(nvl(PCH.PCH_IMP_TEXT_3, '0'), '0', 0, 1) PCH_TEXT_3
           , decode(nvl(PCH.PCH_IMP_TEXT_4, '0'), '0', 0, 1) PCH_TEXT_4
           , decode(nvl(PCH.PCH_IMP_TEXT_5, '0'), '0', 0, 1) PCH_TEXT_5
           , decode(nvl(PCH.PCH_IMP_NUMBER_1, 0), 0, 0, 1) PCH_NUMBER_1
           , decode(nvl(PCH.PCH_IMP_NUMBER_2, 0), 0, 0, 1) PCH_NUMBER_2
           , decode(nvl(PCH.PCH_IMP_NUMBER_3, 0), 0, 0, 1) PCH_NUMBER_3
           , decode(nvl(PCH.PCH_IMP_NUMBER_4, 0), 0, 0, 1) PCH_NUMBER_4
           , decode(nvl(PCH.PCH_IMP_NUMBER_5, 0), 0, 0, 1) PCH_NUMBER_5
           , case
               when PCH.PCH_IMP_DATE_1 is null then 0
               else 1
             end as PCH_DATE_1
           , case
               when PCH.PCH_IMP_DATE_2 is null then 0
               else 1
             end as PCH_DATE_2
           , case
               when PCH.PCH_IMP_DATE_3 is null then 0
               else 1
             end as PCH_DATE_3
           , case
               when PCH.PCH_IMP_DATE_4 is null then 0
               else 1
             end as PCH_DATE_4
           , case
               when PCH.PCH_IMP_DATE_5 is null then 0
               else 1
             end as PCH_DATE_5
           , decode(nvl(PCH.DIC_IMP_FREE1_ID, '0'), '0', 0, 1) PCH_DIC_1
           , decode(nvl(PCH.DIC_IMP_FREE2_ID, '0'), '0', 0, 1) PCH_DIC_2
           , decode(nvl(PCH.DIC_IMP_FREE3_ID, '0'), '0', 0, 1) PCH_DIC_3
           , decode(nvl(PCH.DIC_IMP_FREE4_ID, '0'), '0', 0, 1) PCH_DIC_4
           , decode(nvl(PCH.DIC_IMP_FREE5_ID, '0'), '0', 0, 1) PCH_DIC_5
        from DOC_POSITION POS
           , DOC_DOCUMENT DOC
           , DOC_POSITION_CHARGE PCH
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE_MANAGED_DATA MAN
       where POS.DOC_POSITION_ID = iCrPositionId
         and PCH.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and DOC.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and DOC.DOC_GAUGE_ID = MAN.DOC_GAUGE_ID
         and MAN.GMA_MANDATORY = 1;
  begin
    oChargeOk       := 1;
    oDiscountOK     := 1;
    oRequiredField  := '';

    for ltplInfoCompl in crPCHInfoCompl(iPositionId) loop
      -- Flag sortant indiquant si c'est une remise ou bien une taxe à laquelle il manque des données
      -- Si Remise alors indiquer que s'il y a une erreur c'est la Remise qui n'est pas correcte
      if ltplInfoCompl.PCH_DISCOUNT = 1 then
        oDiscountOK  := 0;
      else
        oDiscountOK  := 1;
      end if;

      -- Si Taxe alors indiquer que s'il y a une erreur c'est la Taxe qui n'est pas correcte
      if ltplInfoCompl.PCH_CHARGE = 1 then
        oChargeOk  := 0;
      else
        oChargeOk  := 1;
      end if;

      if     (ltplInfoCompl.C_DATA_TYP = 'HRM_PERSON')
         and (ltplInfoCompl.PCH_HRM_PERSON = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->HRM_PERSON_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'FAM_FIXED')
            and (ltplInfoCompl.ACCOUNT_VISIBLE = 1) then
        if (ltplInfoCompl.PCH_FAM_FIXED_ID = 0) then
          oRequiredField  := 'DOC_POSITION_CHARGE->FAM_FIXED_ASSETS_ID';
        elsif(ltplInfoCompl.PCH_FAM_TRA_TYP = 0) then
          oRequiredField  := 'DOC_POSITION_CHARGE->C_FAM_TRANSACTION_TYP';
        end if;
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT1')
            and (ltplInfoCompl.PCH_TEXT_1 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_TEXT_1';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT2')
            and (ltplInfoCompl.PCH_TEXT_2 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_TEXT_2';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT3')
            and (ltplInfoCompl.PCH_TEXT_3 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_TEXT_3';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT4')
            and (ltplInfoCompl.PCH_TEXT_4 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_TEXT_4';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT5')
            and (ltplInfoCompl.PCH_TEXT_5 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_TEXT_5';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER')
            and (ltplInfoCompl.PCH_NUMBER_1 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_NUMBER_1';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER2')
            and (ltplInfoCompl.PCH_NUMBER_2 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_NUMBER_2';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER3')
            and (ltplInfoCompl.PCH_NUMBER_3 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_NUMBER_3';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER4')
            and (ltplInfoCompl.PCH_NUMBER_4 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_NUMBER_4';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER5')
            and (ltplInfoCompl.PCH_NUMBER_5 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_NUMBER_5';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE1')
            and (ltplInfoCompl.PCH_DATE_1 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_DATE_1';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE2')
            and (ltplInfoCompl.PCH_DATE_2 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_DATE_2';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE3')
            and (ltplInfoCompl.PCH_DATE_3 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_DATE_3';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE4')
            and (ltplInfoCompl.PCH_DATE_4 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_DATE_4';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE5')
            and (ltplInfoCompl.PCH_DATE_5 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->PCH_IMP_DATE_5';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO1')
            and (ltplInfoCompl.PCH_DIC_1 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->DIC_IMP_FREE1_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO2')
            and (ltplInfoCompl.PCH_DIC_2 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->DIC_IMP_FREE2_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO3')
            and (ltplInfoCompl.PCH_DIC_3 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->DIC_IMP_FREE3_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO4')
            and (ltplInfoCompl.PCH_DIC_4 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->DIC_IMP_FREE4_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO5')
            and (ltplInfoCompl.PCH_DIC_5 = 0) then
        oRequiredField  := 'DOC_POSITION_CHARGE->DIC_IMP_FREE5_ID';
      end if;

      exit when oRequiredField is not null;
    end loop;

    if oRequiredField is null then
      oResult  := 1;
    else
      oResult  := 0;
    end if;
  end CtrlPCHInfoCompl;

  -- Contrôle si les données obligatoires ont été saisies pour la table DOC_FOOT_CHARGE
  procedure CtrlFCHInfoCompl(
    iDocumentId    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , oChargeOk      in out integer
  , oDiscountOK    in out integer
  , oRequiredField in out varchar2
  , oResult        in out integer
  )
  is
    cursor crFCHInfoCompl(iCrDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select MAN.C_DATA_TYP
           , nvl(GAS.GAS_VISIBLE_COUNT, 0) ACCOUNT_VISIBLE
           , decode(nvl(FCH.PTC_CHARGE_ID, 0), 0, 0, 1) FCH_CHARGE
           , decode(nvl(FCH.PTC_DISCOUNT_ID, 0), 0, 0, 1) FCH_DISCOUNT
           , decode(nvl(FCH.HRM_PERSON_ID, 0), 0, 0, 1) FCH_HRM_PERSON
           , decode(nvl(FCH.FAM_FIXED_ASSETS_ID, 0), 0, 0, 1) FCH_FAM_FIXED_ID
           , decode(nvl(FCH.C_FAM_TRANSACTION_TYP, 0), 0, 0, 1) FCH_FAM_TRA_TYP
           , decode(nvl(FCH.FCH_IMP_TEXT_1, '0'), '0', 0, 1) FCH_TEXT_1
           , decode(nvl(FCH.FCH_IMP_TEXT_2, '0'), '0', 0, 1) FCH_TEXT_2
           , decode(nvl(FCH.FCH_IMP_TEXT_3, '0'), '0', 0, 1) FCH_TEXT_3
           , decode(nvl(FCH.FCH_IMP_TEXT_4, '0'), '0', 0, 1) FCH_TEXT_4
           , decode(nvl(FCH.FCH_IMP_TEXT_5, '0'), '0', 0, 1) FCH_TEXT_5
           , decode(nvl(FCH.FCH_IMP_NUMBER_1, 0), 0, 0, 1) FCH_NUMBER_1
           , decode(nvl(FCH.FCH_IMP_NUMBER_2, 0), 0, 0, 1) FCH_NUMBER_2
           , decode(nvl(FCH.FCH_IMP_NUMBER_3, 0), 0, 0, 1) FCH_NUMBER_3
           , decode(nvl(FCH.FCH_IMP_NUMBER_4, 0), 0, 0, 1) FCH_NUMBER_4
           , decode(nvl(FCH.FCH_IMP_NUMBER_5, 0), 0, 0, 1) FCH_NUMBER_5
           , case
               when FCH.FCH_IMP_DATE_1 is null then 0
               else 1
             end as FCH_DATE_1
           , case
               when FCH.FCH_IMP_DATE_2 is null then 0
               else 1
             end as FCH_DATE_2
           , case
               when FCH.FCH_IMP_DATE_3 is null then 0
               else 1
             end as FCH_DATE_3
           , case
               when FCH.FCH_IMP_DATE_4 is null then 0
               else 1
             end as FCH_DATE_4
           , case
               when FCH.FCH_IMP_DATE_5 is null then 0
               else 1
             end as FCH_DATE_5
           , decode(nvl(FCH.DIC_IMP_FREE1_ID, '0'), '0', 0, 1) FCH_DIC_1
           , decode(nvl(FCH.DIC_IMP_FREE2_ID, '0'), '0', 0, 1) FCH_DIC_2
           , decode(nvl(FCH.DIC_IMP_FREE3_ID, '0'), '0', 0, 1) FCH_DIC_3
           , decode(nvl(FCH.DIC_IMP_FREE4_ID, '0'), '0', 0, 1) FCH_DIC_4
           , decode(nvl(FCH.DIC_IMP_FREE5_ID, '0'), '0', 0, 1) FCH_DIC_5
        from DOC_DOCUMENT DOC
           , DOC_FOOT_CHARGE FCH
           , DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE_MANAGED_DATA MAN
       where DOC.DOC_DOCUMENT_ID = iCrDocumentId
         and FCH.DOC_FOOT_ID = DOC.DOC_DOCUMENT_ID
         and DOC.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and DOC.DOC_GAUGE_ID = MAN.DOC_GAUGE_ID
         and MAN.GMA_MANDATORY = 1;
  begin
    oChargeOk    := 1;
    oDiscountOK  := 1;

    for ltplInfoCompl in crFCHInfoCompl(iDocumentId) loop
      -- Flag sortant indiquant si c'est une remise ou bien une taxe à laquelle il manque des données

      -- Si Remise alors indiquer que s'il y a une erreur c'est la Remise qui n'est pas correcte
      if ltplInfoCompl.FCH_DISCOUNT = 1 then
        oDiscountOK  := 0;
      else
        oDiscountOK  := 1;
      end if;

      -- Si Taxe alors indiquer que s'il y a une erreur c'est la Taxe qui n'est pas correcte
      if ltplInfoCompl.FCH_CHARGE = 1 then
        oChargeOk  := 0;
      else
        oChargeOk  := 1;
      end if;

      if     (ltplInfoCompl.C_DATA_TYP = 'HRM_PERSON')
         and (ltplInfoCompl.FCH_HRM_PERSON = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->HRM_PERSON_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'FAM_FIXED')
            and (ltplInfoCompl.ACCOUNT_VISIBLE = 1) then
        if (ltplInfoCompl.FCH_FAM_FIXED_ID = 0) then
          oRequiredField  := 'DOC_FOOT_CHARGE->FAM_FIXED_ASSETS_ID';
        elsif(ltplInfoCompl.FCH_FAM_TRA_TYP = 0) then
          oRequiredField  := 'DOC_FOOT_CHARGE->C_FAM_TRANSACTION_TYP';
        end if;
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT1')
            and (ltplInfoCompl.FCH_TEXT_1 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_TEXT_1';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT2')
            and (ltplInfoCompl.FCH_TEXT_2 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_TEXT_2';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT3')
            and (ltplInfoCompl.FCH_TEXT_3 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_TEXT_3';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT4')
            and (ltplInfoCompl.FCH_TEXT_4 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_TEXT_4';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'TEXT5')
            and (ltplInfoCompl.FCH_TEXT_5 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_TEXT_5';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER')
            and (ltplInfoCompl.FCH_NUMBER_1 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_NUMBER_1';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER2')
            and (ltplInfoCompl.FCH_NUMBER_2 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_NUMBER_2';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER3')
            and (ltplInfoCompl.FCH_NUMBER_3 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_NUMBER_3';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER4')
            and (ltplInfoCompl.FCH_NUMBER_4 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_NUMBER_4';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'NUMBER5')
            and (ltplInfoCompl.FCH_NUMBER_5 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_NUMBER_5';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE1')
            and (ltplInfoCompl.FCH_DATE_1 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_DATE_1';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE2')
            and (ltplInfoCompl.FCH_DATE_2 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_DATE_2';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE3')
            and (ltplInfoCompl.FCH_DATE_3 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_DATE_3';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE4')
            and (ltplInfoCompl.FCH_DATE_4 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_DATE_4';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DATE5')
            and (ltplInfoCompl.FCH_DATE_5 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->PCH_IMP_DATE_5';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO1')
            and (ltplInfoCompl.FCH_DIC_1 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->DIC_IMP_FREE1_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO2')
            and (ltplInfoCompl.FCH_DIC_2 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->DIC_IMP_FREE2_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO3')
            and (ltplInfoCompl.FCH_DIC_3 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->DIC_IMP_FREE3_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO4')
            and (ltplInfoCompl.FCH_DIC_4 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->DIC_IMP_FREE4_ID';
      elsif     (ltplInfoCompl.C_DATA_TYP = 'DICO5')
            and (ltplInfoCompl.FCH_DIC_5 = 0) then
        oRequiredField  := 'DOC_FOOT_CHARGE->DIC_IMP_FREE5_ID';
      end if;

      exit when oRequiredField is not null;
    end loop;

    if oRequiredField is null then
      oResult  := 1;
    else
      oResult  := 0;
    end if;
  end CtrlFCHInfoCompl;

  -- Recherche des données obligatoires ont été saisies pour la table DOC_POSITION
  procedure GetUsedInfoCompl(
    iDocumentId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , oHrmPerson  out    integer
  , oFamFixed   out    integer
  , oText1      out    integer
  , oText2      out    integer
  , oText3      out    integer
  , oText4      out    integer
  , oText5      out    integer
  , oNumber1    out    integer
  , oNumber2    out    integer
  , oNumber3    out    integer
  , oNumber4    out    integer
  , oNumber5    out    integer
  , oDicFree1   out    integer
  , oDicFree2   out    integer
  , oDicFree3   out    integer
  , oDicFree4   out    integer
  , oDicFree5   out    integer
  , oDate1      out    integer
  , oDate2      out    integer
  , oDate3      out    integer
  , oDate4      out    integer
  , oDate5      out    integer
  )
  is
    cursor crInfoCompl(iCrDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select MAN.C_DATA_TYP
           , MAN.GMA_MANDATORY + 1 GMA_MANDATORY
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_MANAGED_DATA MAN
       where DOC.DOC_DOCUMENT_ID = iCrDocumentId
         and DOC.DOC_GAUGE_ID = MAN.DOC_GAUGE_ID;
  begin
    oHrmPerson  := 0;
    oFamFixed   := 0;
    oText1      := 0;
    oText2      := 0;
    oText3      := 0;
    oText4      := 0;
    oText5      := 0;
    oNumber1    := 0;
    oNumber2    := 0;
    oNumber3    := 0;
    oNumber4    := 0;
    oNumber5    := 0;
    oDicFree1   := 0;
    oDicFree2   := 0;
    oDicFree3   := 0;
    oDicFree4   := 0;
    oDicFree5   := 0;
    oDate1      := 0;
    oDate2      := 0;
    oDate3      := 0;
    oDate4      := 0;
    oDate5      := 0;

    for ltplInfoCompl in crInfoCompl(iDocumentId) loop
      if (ltplInfoCompl.C_DATA_TYP = 'HRM_PERSON') then
        oHrmPerson  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'FAM_FIXED') then
        oFamFixed  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'TEXT1') then
        oText1  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'TEXT2') then
        oText2  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'TEXT3') then
        oText3  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'TEXT4') then
        oText4  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'TEXT5') then
        oText5  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'NUMBER') then
        oNumber1  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'NUMBER2') then
        oNumber2  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'NUMBER3') then
        oNumber3  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'NUMBER4') then
        oNumber4  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'NUMBER5') then
        oNumber5  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DICO1') then
        oDicFree1  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DICO2') then
        oDicFree2  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DICO3') then
        oDicFree3  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DICO4') then
        oDicFree4  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DICO5') then
        oDicFree5  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DATE1') then
        oDate1  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DATE2') then
        oDate2  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DATE3') then
        oDate3  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DATE4') then
        oDate4  := ltplInfoCompl.GMA_MANDATORY;
      elsif(ltplInfoCompl.C_DATA_TYP = 'DATE5') then
        oDate5  := ltplInfoCompl.GMA_MANDATORY;
      end if;
    end loop;
  end GetUsedInfoCompl;
end DOC_INFO_COMPL;
