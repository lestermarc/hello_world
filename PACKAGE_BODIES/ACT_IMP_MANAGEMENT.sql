--------------------------------------------------------
--  DDL for Package Body ACT_IMP_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_IMP_MANAGEMENT" 
is
  function InfoImputationType return InfoImputationTypeRecType
  is
  begin
    return InfoImputationTypeRec;
  end InfoImputationType;

  -------------------------

  procedure ConvertManagedValuesToInt(aInfoImputationBool    in     InfoImputationRecType,
                                      aInfoImputationInt     in out IInfoImputationRecType)
  is
    /*********************************/
    procedure ConvertItem(info_imp_bool in InfoImputationManagedRecType, info_imp_int in out IInfoImputationManagedRecType)
    is
    begin
      if info_imp_bool.Managed then
        info_imp_int.Managed := 1;
      else
        info_imp_int.Managed := 0;
      end if;
      if info_imp_bool.Required then
        info_imp_int.Required := 1;
      else
        info_imp_int.Required := 0;
      end if;
    end;
    /*********************************/
    /*********************************/
    procedure ConvertRec(info_imp_rec_bool in InfoImputationBaseRecType, info_imp_rec_int in out IInfoImputationBaseRecType)
    is
    begin
      ConvertItem(info_imp_rec_bool.NUMBER1, info_imp_rec_int.NUMBER1);
      ConvertItem(info_imp_rec_bool.NUMBER2, info_imp_rec_int.NUMBER2);
      ConvertItem(info_imp_rec_bool.NUMBER3, info_imp_rec_int.NUMBER3);
      ConvertItem(info_imp_rec_bool.NUMBER4, info_imp_rec_int.NUMBER4);
      ConvertItem(info_imp_rec_bool.NUMBER5, info_imp_rec_int.NUMBER5);

      ConvertItem(info_imp_rec_bool.TEXT1, info_imp_rec_int.TEXT1);
      ConvertItem(info_imp_rec_bool.TEXT2, info_imp_rec_int.TEXT2);
      ConvertItem(info_imp_rec_bool.TEXT3, info_imp_rec_int.TEXT3);
      ConvertItem(info_imp_rec_bool.TEXT4, info_imp_rec_int.TEXT4);
      ConvertItem(info_imp_rec_bool.TEXT5, info_imp_rec_int.TEXT5);

      ConvertItem(info_imp_rec_bool.DATE1, info_imp_rec_int.DATE1);
      ConvertItem(info_imp_rec_bool.DATE2, info_imp_rec_int.DATE2);
      ConvertItem(info_imp_rec_bool.DATE3, info_imp_rec_int.DATE3);
      ConvertItem(info_imp_rec_bool.DATE4, info_imp_rec_int.DATE4);
      ConvertItem(info_imp_rec_bool.DATE5, info_imp_rec_int.DATE5);

      ConvertItem(info_imp_rec_bool.DICO1, info_imp_rec_int.DICO1);
      ConvertItem(info_imp_rec_bool.DICO2, info_imp_rec_int.DICO2);
      ConvertItem(info_imp_rec_bool.DICO3, info_imp_rec_int.DICO3);
      ConvertItem(info_imp_rec_bool.DICO4, info_imp_rec_int.DICO4);
      ConvertItem(info_imp_rec_bool.DICO5, info_imp_rec_int.DICO5);

      ConvertItem(info_imp_rec_bool.GCO_GOOD_ID, info_imp_rec_int.GCO_GOOD_ID);
      ConvertItem(info_imp_rec_bool.HRM_PERSON_ID, info_imp_rec_int.HRM_PERSON_ID);
      ConvertItem(info_imp_rec_bool.DOC_RECORD_ID, info_imp_rec_int.DOC_RECORD_ID);
      ConvertItem(info_imp_rec_bool.PAC_PERSON_ID, info_imp_rec_int.PAC_PERSON_ID);
      ConvertItem(info_imp_rec_bool.FAM_FIXED_ASSETS_ID, info_imp_rec_int.FAM_FIXED_ASSETS_ID);
      ConvertItem(info_imp_rec_bool.C_FAM_TRANSACTION_TYP, info_imp_rec_int.C_FAM_TRANSACTION_TYP);

    end;
    /*********************************/

  begin
    aInfoImputationInt.ACJ_CATALOGUE_DOCUMENT_ID := aInfoImputationBool.ACJ_CATALOGUE_DOCUMENT_ID;
    if aInfoImputationBool.Managed then
      aInfoImputationInt.Managed := 1;
    else
      aInfoImputationInt.Managed := 0;
    end if;

    ConvertRec(aInfoImputationBool.Primary, aInfoImputationInt.Primary);
    ConvertRec(aInfoImputationBool.Secondary, aInfoImputationInt.Secondary);

  end ConvertManagedValuesToInt;

  -------------------------

  procedure UpdateManagedValues(aInfoImputationValues     in out InfoImputationValuesRecType,
                                aInfoImputation           in     InfoImputationBaseRecType)
  is
  begin
    if not aInfoImputation.NUMBER1.Managed then
      aInfoImputationValues.NUMBER1 := null;
    end if;
    if not aInfoImputation.NUMBER2.Managed then
      aInfoImputationValues.NUMBER2 := null;
    end if;
    if not aInfoImputation.NUMBER3.Managed then
      aInfoImputationValues.NUMBER3 := null;
    end if;
    if not aInfoImputation.NUMBER4.Managed then
      aInfoImputationValues.NUMBER4 := null;
    end if;
    if not aInfoImputation.NUMBER5.Managed then
      aInfoImputationValues.NUMBER5 := null;
    end if;
    if not aInfoImputation.TEXT1.Managed then
      aInfoImputationValues.TEXT1 := null;
    end if;
    if not aInfoImputation.TEXT2.Managed then
      aInfoImputationValues.TEXT2 := null;
    end if;
    if not aInfoImputation.TEXT3.Managed then
      aInfoImputationValues.TEXT3 := null;
    end if;
    if not aInfoImputation.TEXT4.Managed then
      aInfoImputationValues.TEXT4 := null;
    end if;
    if not aInfoImputation.TEXT5.Managed then
      aInfoImputationValues.TEXT5 := null;
    end if;
    if not aInfoImputation.DATE1.Managed then
      aInfoImputationValues.DATE1 := null;
    end if;
    if not aInfoImputation.DATE2.Managed then
      aInfoImputationValues.DATE2 := null;
    end if;
    if not aInfoImputation.DATE3.Managed then
      aInfoImputationValues.DATE3 := null;
    end if;
    if not aInfoImputation.DATE4.Managed then
      aInfoImputationValues.DATE4 := null;
    end if;
    if not aInfoImputation.DATE5.Managed then
      aInfoImputationValues.DATE5 := null;
    end if;
    if not aInfoImputation.DICO1.Managed then
      aInfoImputationValues.DICO1 := null;
    end if;
    if not aInfoImputation.DICO2.Managed then
      aInfoImputationValues.DICO2 := null;
    end if;
    if not aInfoImputation.DICO3.Managed then
      aInfoImputationValues.DICO3 := null;
    end if;
    if not aInfoImputation.DICO4.Managed then
      aInfoImputationValues.DICO4 := null;
    end if;
    if not aInfoImputation.DICO5.Managed then
      aInfoImputationValues.DICO5 := null;
    end if;
    if not aInfoImputation.GCO_GOOD_ID.Managed then
      aInfoImputationValues.GCO_GOOD_ID := null;
    end if;
    if not aInfoImputation.HRM_PERSON_ID.Managed then
      aInfoImputationValues.HRM_PERSON_ID := null;
    end if;
    if not aInfoImputation.DOC_RECORD_ID.Managed then
      aInfoImputationValues.DOC_RECORD_ID := null;
    end if;
    if not aInfoImputation.PAC_PERSON_ID.Managed then
      aInfoImputationValues.PAC_PERSON_ID := null;
    end if;
    if not aInfoImputation.FAM_FIXED_ASSETS_ID.Managed then
      aInfoImputationValues.FAM_FIXED_ASSETS_ID := null;
    end if;
    if not aInfoImputation.C_FAM_TRANSACTION_TYP.Managed then
      aInfoImputationValues.C_FAM_TRANSACTION_TYP := null;
    end if;
  end UpdateManagedValues;

  -------------------------

  procedure MergeManagedValues(aSourceInfoImputationValues  in out InfoImputationValuesRecType,
                               aInfoImputationValues        in     InfoImputationValuesRecType)
  is
  begin
    if aSourceInfoImputationValues.NUMBER1 is null then
      aSourceInfoImputationValues.NUMBER1 := aInfoImputationValues.NUMBER1;
    end if;
    if aSourceInfoImputationValues.NUMBER2 is null then
      aSourceInfoImputationValues.NUMBER2 := aInfoImputationValues.NUMBER2;
    end if;
    if aSourceInfoImputationValues.NUMBER3 is null then
      aSourceInfoImputationValues.NUMBER3 := aInfoImputationValues.NUMBER3;
    end if;
    if aSourceInfoImputationValues.NUMBER4 is null then
      aSourceInfoImputationValues.NUMBER4 := aInfoImputationValues.NUMBER4;
    end if;
    if aSourceInfoImputationValues.NUMBER5 is null then
      aSourceInfoImputationValues.NUMBER5 := aInfoImputationValues.NUMBER5;
    end if;
    if aSourceInfoImputationValues.TEXT1 is null then
      aSourceInfoImputationValues.TEXT1 := aInfoImputationValues.TEXT1;
    end if;
    if aSourceInfoImputationValues.TEXT2 is null then
      aSourceInfoImputationValues.TEXT2 := aInfoImputationValues.TEXT2;
    end if;
    if aSourceInfoImputationValues.TEXT3 is null then
      aSourceInfoImputationValues.TEXT3 := aInfoImputationValues.TEXT3;
    end if;
    if aSourceInfoImputationValues.TEXT4 is null then
      aSourceInfoImputationValues.TEXT4 := aInfoImputationValues.TEXT4;
    end if;
    if aSourceInfoImputationValues.TEXT5 is null then
      aSourceInfoImputationValues.TEXT5 := aInfoImputationValues.TEXT5;
    end if;
    if aSourceInfoImputationValues.DATE1 is null then
      aSourceInfoImputationValues.DATE1 := aInfoImputationValues.DATE1;
    end if;
    if aSourceInfoImputationValues.DATE2 is null then
      aSourceInfoImputationValues.DATE2 := aInfoImputationValues.DATE2;
    end if;
    if aSourceInfoImputationValues.DATE3 is null then
      aSourceInfoImputationValues.DATE3 := aInfoImputationValues.DATE3;
    end if;
    if aSourceInfoImputationValues.DATE4 is null then
      aSourceInfoImputationValues.DATE4 := aInfoImputationValues.DATE4;
    end if;
    if aSourceInfoImputationValues.DATE5 is null then
      aSourceInfoImputationValues.DATE5 := aInfoImputationValues.DATE5;
    end if;
    if aSourceInfoImputationValues.DICO1 is null then
      aSourceInfoImputationValues.DICO1 := aInfoImputationValues.DICO1;
    end if;
    if aSourceInfoImputationValues.DICO2 is null then
      aSourceInfoImputationValues.DICO2 := aInfoImputationValues.DICO2;
    end if;
    if aSourceInfoImputationValues.DICO3 is null then
      aSourceInfoImputationValues.DICO3 := aInfoImputationValues.DICO3;
    end if;
    if aSourceInfoImputationValues.DICO4 is null then
      aSourceInfoImputationValues.DICO4 := aInfoImputationValues.DICO4;
    end if;
    if aSourceInfoImputationValues.DICO5 is null then
      aSourceInfoImputationValues.DICO5 := aInfoImputationValues.DICO5;
    end if;
    if aSourceInfoImputationValues.GCO_GOOD_ID is null then
      aSourceInfoImputationValues.GCO_GOOD_ID := aInfoImputationValues.GCO_GOOD_ID;
    end if;
    if aSourceInfoImputationValues.HRM_PERSON_ID is null then
      aSourceInfoImputationValues.HRM_PERSON_ID := aInfoImputationValues.HRM_PERSON_ID;
    end if;
    if aSourceInfoImputationValues.DOC_RECORD_ID is null then
      aSourceInfoImputationValues.DOC_RECORD_ID := aInfoImputationValues.DOC_RECORD_ID;
    end if;
    if aSourceInfoImputationValues.PAC_PERSON_ID is null then
      aSourceInfoImputationValues.PAC_PERSON_ID := aInfoImputationValues.PAC_PERSON_ID;
    end if;
    if aSourceInfoImputationValues.FAM_FIXED_ASSETS_ID is null then
      aSourceInfoImputationValues.FAM_FIXED_ASSETS_ID := aInfoImputationValues.FAM_FIXED_ASSETS_ID;
    end if;
    if aSourceInfoImputationValues.C_FAM_TRANSACTION_TYP is null then
      aSourceInfoImputationValues.C_FAM_TRANSACTION_TYP := aInfoImputationValues.C_FAM_TRANSACTION_TYP;
    end if;
  end MergeManagedValues;

  -------------------------

  function CheckManagedValues(aInfoImputationValues     in  InfoImputationValuesRecType,
                              aInfoImputation           in  InfoImputationBaseRecType) return number
  is
    result number := 0;
    /*********************************/
    procedure CheckItem(aRequired boolean, aManagedValues number, aCodeValue number, aIsNull boolean)
    is
    begin
      if aRequired and aIsNull and (PCS.PC_BITMAN.bit_and(aManagedValues, aCodeValue) != 0) then
        result := result + aCodeValue;
      end if;
    end;
    /*********************************/
  begin
    CheckItem(aInfoImputation.NUMBER1.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.NUMBER1, aInfoImputationValues.NUMBER1 is null);
    CheckItem(aInfoImputation.NUMBER2.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.NUMBER2, aInfoImputationValues.NUMBER2 is null);
    CheckItem(aInfoImputation.NUMBER3.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.NUMBER3, aInfoImputationValues.NUMBER3 is null);
    CheckItem(aInfoImputation.NUMBER4.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.NUMBER4, aInfoImputationValues.NUMBER4 is null);
    CheckItem(aInfoImputation.NUMBER5.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.NUMBER5, aInfoImputationValues.NUMBER5 is null);

    CheckItem(aInfoImputation.TEXT1.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.TEXT1, aInfoImputationValues.TEXT1 is null);
    CheckItem(aInfoImputation.TEXT2.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.TEXT2, aInfoImputationValues.TEXT2 is null);
    CheckItem(aInfoImputation.TEXT3.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.TEXT3, aInfoImputationValues.TEXT3 is null);
    CheckItem(aInfoImputation.TEXT4.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.TEXT4, aInfoImputationValues.TEXT4 is null);
    CheckItem(aInfoImputation.TEXT5.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.TEXT5, aInfoImputationValues.TEXT5 is null);

    CheckItem(aInfoImputation.DATE1.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DATE1, aInfoImputationValues.DATE1 is null);
    CheckItem(aInfoImputation.DATE2.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DATE2, aInfoImputationValues.DATE2 is null);
    CheckItem(aInfoImputation.DATE3.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DATE3, aInfoImputationValues.DATE3 is null);
    CheckItem(aInfoImputation.DATE4.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DATE4, aInfoImputationValues.DATE4 is null);
    CheckItem(aInfoImputation.DATE5.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DATE5, aInfoImputationValues.DATE5 is null);

    CheckItem(aInfoImputation.DICO1.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DICO1, aInfoImputationValues.DICO1 is null);
    CheckItem(aInfoImputation.DICO2.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DICO2, aInfoImputationValues.DICO2 is null);
    CheckItem(aInfoImputation.DICO3.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DICO3, aInfoImputationValues.DICO3 is null);
    CheckItem(aInfoImputation.DICO4.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DICO4, aInfoImputationValues.DICO4 is null);
    CheckItem(aInfoImputation.DICO5.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DICO5, aInfoImputationValues.DICO5 is null);

    CheckItem(aInfoImputation.GCO_GOOD_ID.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.GCO_GOOD_ID, aInfoImputationValues.GCO_GOOD_ID is null);
    CheckItem(aInfoImputation.HRM_PERSON_ID.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.HRM_PERSON_ID, aInfoImputationValues.HRM_PERSON_ID is null);
    CheckItem(aInfoImputation.DOC_RECORD_ID.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.DOC_RECORD_ID, aInfoImputationValues.DOC_RECORD_ID is null);
    CheckItem(aInfoImputation.PAC_PERSON_ID.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.PAC_PERSON_ID, aInfoImputationValues.PAC_PERSON_ID is null);
    CheckItem(aInfoImputation.FAM_FIXED_ASSETS_ID.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.FAM_FIXED_ASSETS_ID, aInfoImputationValues.FAM_FIXED_ASSETS_ID is null);
    CheckItem(aInfoImputation.C_FAM_TRANSACTION_TYP.Required, aInfoImputationValues.GroupType, InfoImputationTypeRec.C_FAM_TRANSACTION_TYP, aInfoImputationValues.C_FAM_TRANSACTION_TYP is null);

    return result;
  end CheckManagedValues;

  -------------------------

  function GetManagedData(aACJ_CATALOGUE_DOCUMENT_ID   ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type) return InfoImputationRecType
  is
    cursor managed_data(aACJ_CATALOGUE_DOCUMENT_ID  ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type) is
      select C_DATA_TYP, MDA_MANDATORY_PRIMARY, MDA_MANDATORY
        from ACJ_IMP_MANAGED_DATA
      where ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID;

    Managed number;
    InfoImputation InfoImputationRecType;

    ----
    procedure UpdateInfos(managed_data_tuple in managed_data%rowtype,
                          InfoImputationManagedRec_Prim in out InfoImputationManagedRecType,
                          InfoImputationManagedRec_Sec  in out InfoImputationManagedRecType)
    is
    begin
      InfoImputationManagedRec_Prim.Managed   := True;
      InfoImputationManagedRec_Sec.Managed    := True;
      InfoImputationManagedRec_Prim.Required  := managed_data_tuple.MDA_MANDATORY_PRIMARY = 1;
      InfoImputationManagedRec_Sec.Required   := managed_data_tuple.MDA_MANDATORY = 1;
    end UpdateInfos;
    ----
  begin
    SELECT nvl(CAT_IMP_INFORMATION, 0)
    INTO Managed
    FROM ACJ_CATALOGUE_DOCUMENT
    WHERE ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID;

    InfoImputation.ACJ_CATALOGUE_DOCUMENT_ID := aACJ_CATALOGUE_DOCUMENT_ID;

    if Managed  = 1 then
      InfoImputation.Managed := True;
    else
      return InfoImputation;
    end if;

    for managed_data_tuple in managed_data(aACJ_CATALOGUE_DOCUMENT_ID) loop

      if managed_data_tuple.C_DATA_TYP = 'NUMBER' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.NUMBER1, InfoImputation.Secondary.NUMBER1);
      elsif managed_data_tuple.C_DATA_TYP = 'NUMBER2' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.NUMBER2, InfoImputation.Secondary.NUMBER2);
      elsif managed_data_tuple.C_DATA_TYP = 'NUMBER3' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.NUMBER3, InfoImputation.Secondary.NUMBER3);
      elsif managed_data_tuple.C_DATA_TYP = 'NUMBER4' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.NUMBER4, InfoImputation.Secondary.NUMBER4);
      elsif managed_data_tuple.C_DATA_TYP = 'NUMBER5' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.NUMBER5, InfoImputation.Secondary.NUMBER5);
      elsif managed_data_tuple.C_DATA_TYP = 'TEXT1' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.TEXT1, InfoImputation.Secondary.TEXT1);
      elsif managed_data_tuple.C_DATA_TYP = 'TEXT2' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.TEXT2, InfoImputation.Secondary.TEXT2);
      elsif managed_data_tuple.C_DATA_TYP = 'TEXT3' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.TEXT3, InfoImputation.Secondary.TEXT3);
      elsif managed_data_tuple.C_DATA_TYP = 'TEXT4' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.TEXT4, InfoImputation.Secondary.TEXT4);
      elsif managed_data_tuple.C_DATA_TYP = 'TEXT5' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.TEXT5, InfoImputation.Secondary.TEXT5);
      elsif managed_data_tuple.C_DATA_TYP = 'DATE1' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DATE1, InfoImputation.Secondary.DATE1);
      elsif managed_data_tuple.C_DATA_TYP = 'DATE2' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DATE2, InfoImputation.Secondary.DATE2);
      elsif managed_data_tuple.C_DATA_TYP = 'DATE3' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DATE3, InfoImputation.Secondary.DATE3);
      elsif managed_data_tuple.C_DATA_TYP = 'DATE4' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DATE4, InfoImputation.Secondary.DATE4);
      elsif managed_data_tuple.C_DATA_TYP = 'DATE5' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DATE5, InfoImputation.Secondary.DATE5);
      elsif managed_data_tuple.C_DATA_TYP = 'DICO1' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DICO1, InfoImputation.Secondary.DICO1);
      elsif managed_data_tuple.C_DATA_TYP = 'DICO2' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DICO2, InfoImputation.Secondary.DICO2);
      elsif managed_data_tuple.C_DATA_TYP = 'DICO3' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DICO3, InfoImputation.Secondary.DICO3);
      elsif managed_data_tuple.C_DATA_TYP = 'DICO4' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DICO4, InfoImputation.Secondary.DICO4);
      elsif managed_data_tuple.C_DATA_TYP = 'DICO5' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DICO5, InfoImputation.Secondary.DICO5);
      elsif managed_data_tuple.C_DATA_TYP = 'GCO_GOOD' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.GCO_GOOD_ID, InfoImputation.Secondary.GCO_GOOD_ID);
      elsif managed_data_tuple.C_DATA_TYP = 'PAC_PERSON' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.PAC_PERSON_ID, InfoImputation.Secondary.PAC_PERSON_ID);
      elsif managed_data_tuple.C_DATA_TYP = 'DOC_RECORD' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.DOC_RECORD_ID, InfoImputation.Secondary.DOC_RECORD_ID);
      elsif managed_data_tuple.C_DATA_TYP = 'HRM_PERSON' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.HRM_PERSON_ID, InfoImputation.Secondary.HRM_PERSON_ID);
      elsif managed_data_tuple.C_DATA_TYP = 'FAM_FIXED' then
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.FAM_FIXED_ASSETS_ID, InfoImputation.Secondary.FAM_FIXED_ASSETS_ID);
        UpdateInfos(managed_data_tuple, InfoImputation.Primary.C_FAM_TRANSACTION_TYP, InfoImputation.Secondary.C_FAM_TRANSACTION_TYP);
      end if;

    end loop;

    return InfoImputation;

  end GetManagedData;

  -------------------------

  procedure GetInfoImputationValuesIMF(aACT_FINANCIAL_IMPUTATION_ID     in     ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                                       aInfoImputationValues            in out InfoImputationValuesRecType)
  is
  begin
    begin
      SELECT imf_number,
             imf_number2,
             imf_number3,
             imf_number4,
             imf_number5,
             imf_text1,
             imf_text2,
             imf_text3,
             imf_text4,
             imf_text5,
             imf_date1,
             imf_date2,
             imf_date3,
             imf_date4,
             imf_date5,
             dic_imp_free1_id,
             dic_imp_free2_id,
             dic_imp_free3_id,
             dic_imp_free4_id,
             dic_imp_free5_id,
             gco_good_id,
             hrm_person_id,
             doc_record_id,
             pac_person_id,
             fam_fixed_assets_id,
             c_fam_transaction_typ,
             InfoImputationTypeRec.GroupALL
  	    INTO aInfoImputationValues
        FROM act_financial_imputation
       WHERE act_financial_imputation_id = aACT_FINANCIAL_IMPUTATION_ID;
    exception
      when OTHERS then
        return;
    end;

  end GetInfoImputationValuesIMF;

  -------------------------

  procedure SetInfoImputationValuesIMF(aACT_FINANCIAL_IMPUTATION_ID     in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                                       aInfoImputationValues            in InfoImputationValuesRecType)
  is
  begin
    begin
     UPDATE act_financial_imputation SET
            imf_number        = aInfoImputationValues.NUMBER1,
            imf_number2       = aInfoImputationValues.NUMBER2,
            imf_number3       = aInfoImputationValues.NUMBER3,
            imf_number4       = aInfoImputationValues.NUMBER4,
            imf_number5       = aInfoImputationValues.NUMBER5,
            imf_text1         = aInfoImputationValues.TEXT1,
            imf_text2         = aInfoImputationValues.TEXT2,
            imf_text3         = aInfoImputationValues.TEXT3,
            imf_text4         = aInfoImputationValues.TEXT4,
            imf_text5         = aInfoImputationValues.TEXT5,
            imf_date1         = aInfoImputationValues.DATE1,
            imf_date2         = aInfoImputationValues.DATE2,
            imf_date3         = aInfoImputationValues.DATE3,
            imf_date4         = aInfoImputationValues.DATE4,
            imf_date5         = aInfoImputationValues.DATE5,
            dic_imp_free1_id  = aInfoImputationValues.DICO1,
            dic_imp_free2_id  = aInfoImputationValues.DICO2,
            dic_imp_free3_id  = aInfoImputationValues.DICO3,
            dic_imp_free4_id  = aInfoImputationValues.DICO4,
            dic_imp_free5_id  = aInfoImputationValues.DICO5,
            gco_good_id       = aInfoImputationValues.GCO_GOOD_ID,
            hrm_person_id     = aInfoImputationValues.HRM_PERSON_ID,
            doc_record_id     = aInfoImputationValues.DOC_RECORD_ID,
            pac_person_id     = aInfoImputationValues.PAC_PERSON_ID,
            fam_fixed_assets_id   = aInfoImputationValues.FAM_FIXED_ASSETS_ID,
            c_fam_transaction_typ = aInfoImputationValues.C_FAM_TRANSACTION_TYP
      WHERE act_financial_imputation_id = aACT_FINANCIAL_IMPUTATION_ID;
    exception
      when OTHERS then
        return;
    end;

  end SetInfoImputationValuesIMF;

  -------------------------

  procedure SetInfoImputationValuesIMF(aACT_FINANCIAL_IMPUTATION_ID     in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                                       aInfoImputationValues            in InfoImputationValuesRecType,
                                       aInfoImputation                  in InfoImputationBaseRecType)
  is
    InfoImputationValues  InfoImputationValuesRecType;
  begin
    --Copie des données pour màj
    InfoImputationValues := aInfoImputationValues;

    --Màj (null) des champs non gérés
    UpdateManagedValues(InfoImputationValues, aInfoImputation);

    --Màj de la table avec les valeurs
    SetInfoImputationValuesIMF(aACT_FINANCIAL_IMPUTATION_ID, InfoImputationValues);

  end SetInfoImputationValuesIMF;

  -------------------------

  procedure GetInfoImputationValuesIMM(aACT_MGM_IMPUTATION_ID     in     ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type,
                                       aInfoImputationValues      in out InfoImputationValuesRecType)
  is
  begin
    begin
      SELECT imm_number,
             imm_number2,
             imm_number3,
             imm_number4,
             imm_number5,
             imm_text1,
             imm_text2,
             imm_text3,
             imm_text4,
             imm_text5,
             imm_date1,
             imm_date2,
             imm_date3,
             imm_date4,
             imm_date5,
             dic_imp_free1_id,
             dic_imp_free2_id,
             dic_imp_free3_id,
             dic_imp_free4_id,
             dic_imp_free5_id,
             gco_good_id,
             hrm_person_id,
             doc_record_id,
             pac_person_id,
             fam_fixed_assets_id,
             c_fam_transaction_typ,
             InfoImputationTypeRec.GroupALL
  	    INTO aInfoImputationValues
        FROM act_mgm_imputation
       WHERE act_mgm_imputation_id = aACT_MGM_IMPUTATION_ID;
    exception
      when OTHERS then
        return;
    end;

  end GetInfoImputationValuesIMM;

  -------------------------

  procedure SetInfoImputationValuesIMM(aACT_MGM_IMPUTATION_ID     in ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type,
                                       aInfoImputationValues      in InfoImputationValuesRecType)
  is
  begin
    begin
     UPDATE act_mgm_imputation SET
            imm_number        = aInfoImputationValues.NUMBER1,
            imm_number2       = aInfoImputationValues.NUMBER2,
            imm_number3       = aInfoImputationValues.NUMBER3,
            imm_number4       = aInfoImputationValues.NUMBER4,
            imm_number5       = aInfoImputationValues.NUMBER5,
            imm_text1         = aInfoImputationValues.TEXT1,
            imm_text2         = aInfoImputationValues.TEXT2,
            imm_text3         = aInfoImputationValues.TEXT3,
            imm_text4         = aInfoImputationValues.TEXT4,
            imm_text5         = aInfoImputationValues.TEXT5,
            imm_date1         = aInfoImputationValues.DATE1,
            imm_date2         = aInfoImputationValues.DATE2,
            imm_date3         = aInfoImputationValues.DATE3,
            imm_date4         = aInfoImputationValues.DATE4,
            imm_date5         = aInfoImputationValues.DATE5,
            dic_imp_free1_id  = aInfoImputationValues.DICO1,
            dic_imp_free2_id  = aInfoImputationValues.DICO2,
            dic_imp_free3_id  = aInfoImputationValues.DICO3,
            dic_imp_free4_id  = aInfoImputationValues.DICO4,
            dic_imp_free5_id  = aInfoImputationValues.DICO5,
            gco_good_id       = aInfoImputationValues.GCO_GOOD_ID,
            hrm_person_id     = aInfoImputationValues.HRM_PERSON_ID,
            doc_record_id     = aInfoImputationValues.DOC_RECORD_ID,
            pac_person_id     = aInfoImputationValues.PAC_PERSON_ID,
            fam_fixed_assets_id   = aInfoImputationValues.FAM_FIXED_ASSETS_ID,
            c_fam_transaction_typ = aInfoImputationValues.C_FAM_TRANSACTION_TYP
      WHERE act_mgm_imputation_id = aACT_MGM_IMPUTATION_ID;
    exception
      when OTHERS then
        return;
    end;

  end SetInfoImputationValuesIMM;

  -------------------------

  procedure SetInfoImputationValuesIMM(aACT_MGM_IMPUTATION_ID     in ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type,
                                       aInfoImputationValues      in InfoImputationValuesRecType,
                                       aInfoImputation            in InfoImputationBaseRecType)
  is
    InfoImputationValues  InfoImputationValuesRecType;
  begin
    --Copie des données pour màj
    InfoImputationValues := aInfoImputationValues;

    --Màj (null) des champs non gérés
    UpdateManagedValues(InfoImputationValues, aInfoImputation);

    --Màj de la table avec les valeurs
    SetInfoImputationValuesIMM(aACT_MGM_IMPUTATION_ID, InfoImputationValues);

  end SetInfoImputationValuesIMM;

  -------------------------

  procedure GetInfoImputationValuesMGM(aACT_MGM_DISTRIBUTION_ID     in     ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type,
                                       aInfoImputationValues        in out InfoImputationValuesRecType)
  is
  begin
    begin
      SELECT mgm_number,
             mgm_number2,
             mgm_number3,
             mgm_number4,
             mgm_number5,
             mgm_text1,
             mgm_text2,
             mgm_text3,
             mgm_text4,
             mgm_text5,
             mgm_date1,
             mgm_date2,
             mgm_date3,
             mgm_date4,
             mgm_date5,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             null,
             InfoImputationTypeRec.GroupNUMBER + InfoImputationTypeRec.GroupTEXT + InfoImputationTypeRec.GroupDATE
  	    INTO aInfoImputationValues
        FROM act_mgm_distribution
       WHERE act_mgm_distribution_id = aACT_MGM_DISTRIBUTION_ID;
    exception
      when OTHERS then
        return;
    end;

  end GetInfoImputationValuesMGM;

  -------------------------

  procedure SetInfoImputationValuesMGM(aACT_MGM_DISTRIBUTION_ID   in ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type,
                                       aInfoImputationValues      in InfoImputationValuesRecType)
  is
  begin
    begin
     UPDATE act_mgm_distribution SET
            mgm_number        = aInfoImputationValues.NUMBER1,
            mgm_number2       = aInfoImputationValues.NUMBER2,
            mgm_number3       = aInfoImputationValues.NUMBER3,
            mgm_number4       = aInfoImputationValues.NUMBER4,
            mgm_number5       = aInfoImputationValues.NUMBER5,
            mgm_text1         = aInfoImputationValues.TEXT1,
            mgm_text2         = aInfoImputationValues.TEXT2,
            mgm_text3         = aInfoImputationValues.TEXT3,
            mgm_text4         = aInfoImputationValues.TEXT4,
            mgm_text5         = aInfoImputationValues.TEXT5,
            mgm_date1         = aInfoImputationValues.DATE1,
            mgm_date2         = aInfoImputationValues.DATE2,
            mgm_date3         = aInfoImputationValues.DATE3,
            mgm_date4         = aInfoImputationValues.DATE4,
            mgm_date5         = aInfoImputationValues.DATE5
      WHERE act_mgm_distribution_id = aACT_MGM_DISTRIBUTION_ID;
    exception
      when OTHERS then
        return;
    end;

  end SetInfoImputationValuesMGM;

  -------------------------

  procedure SetInfoImputationValuesMGM(aACT_MGM_DISTRIBUTION_ID   in ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type,
                                       aInfoImputationValues      in InfoImputationValuesRecType,
                                       aInfoImputation            in InfoImputationBaseRecType)
  is
    InfoImputationValues  InfoImputationValuesRecType;
  begin
    --Copie des données pour màj
    InfoImputationValues := aInfoImputationValues;

    --Màj (null) des champs non gérés
    UpdateManagedValues(InfoImputationValues, aInfoImputation);

    --Màj de la table avec les valeurs
    SetInfoImputationValuesMGM(aACT_MGM_DISTRIBUTION_ID, InfoImputationValues);

  end SetInfoImputationValuesMGM;

  -------------------------

  procedure GetInfoImputationValuesDET_ACI(aACI_DET_PAYMENT_ID        in     ACI_DET_PAYMENT.ACI_DET_PAYMENT_ID%type,
                                           aInfoImputationValues      in out InfoImputationValuesRecType)
  is
  begin
    begin
      SELECT imf_number,
             imf_number2,
             imf_number3,
             imf_number4,
             imf_number5,
             imf_text1,
             imf_text2,
             imf_text3,
             imf_text4,
             imf_text5,
             imf_date1,
             imf_date2,
             imf_date3,
             imf_date4,
             imf_date5,
             dic_imp_free1_id,
             dic_imp_free2_id,
             dic_imp_free3_id,
             dic_imp_free4_id,
             dic_imp_free5_id,
             gco_good_id,
             hrm_person_id,
             doc_record_id,
             pac_person_id,
             fam_fixed_assets_id,
             c_fam_transaction_typ,
             InfoImputationTypeRec.GroupALL
  	    INTO aInfoImputationValues
        FROM aci_det_payment
       WHERE aci_det_payment_id = aACI_DET_PAYMENT_ID;
    exception
      when OTHERS then
        return;
    end;

  end GetInfoImputationValuesDET_ACI;

  -------------------------

  procedure SetInfoImputationValuesDET_ACI(aACI_DET_PAYMENT_ID        in ACI_DET_PAYMENT.ACI_DET_PAYMENT_ID%type,
                                           aInfoImputationValues      in InfoImputationValuesRecType)
  is
  begin
    begin
     UPDATE aci_det_payment SET
            imf_number        = aInfoImputationValues.NUMBER1,
            imf_number2       = aInfoImputationValues.NUMBER2,
            imf_number3       = aInfoImputationValues.NUMBER3,
            imf_number4       = aInfoImputationValues.NUMBER4,
            imf_number5       = aInfoImputationValues.NUMBER5,
            imf_text1         = aInfoImputationValues.TEXT1,
            imf_text2         = aInfoImputationValues.TEXT2,
            imf_text3         = aInfoImputationValues.TEXT3,
            imf_text4         = aInfoImputationValues.TEXT4,
            imf_text5         = aInfoImputationValues.TEXT5,
            imf_date1         = aInfoImputationValues.DATE1,
            imf_date2         = aInfoImputationValues.DATE2,
            imf_date3         = aInfoImputationValues.DATE3,
            imf_date4         = aInfoImputationValues.DATE4,
            imf_date5         = aInfoImputationValues.DATE5,
            dic_imp_free1_id  = aInfoImputationValues.DICO1,
            dic_imp_free2_id  = aInfoImputationValues.DICO2,
            dic_imp_free3_id  = aInfoImputationValues.DICO3,
            dic_imp_free4_id  = aInfoImputationValues.DICO4,
            dic_imp_free5_id  = aInfoImputationValues.DICO5,
            gco_good_id       = aInfoImputationValues.GCO_GOOD_ID,
            hrm_person_id     = aInfoImputationValues.HRM_PERSON_ID,
            doc_record_id     = aInfoImputationValues.DOC_RECORD_ID,
            pac_person_id     = aInfoImputationValues.PAC_PERSON_ID,
            fam_fixed_assets_id   = aInfoImputationValues.FAM_FIXED_ASSETS_ID,
            c_fam_transaction_typ = aInfoImputationValues.C_FAM_TRANSACTION_TYP
      WHERE aci_det_payment_id = aACI_DET_PAYMENT_ID;
    exception
      when OTHERS then
        return;
    end;

  end SetInfoImputationValuesDET_ACI;

  -------------------------

  procedure SetInfoImputationValuesDET_ACI(aACI_DET_PAYMENT_ID              in ACI_DET_PAYMENT.ACI_DET_PAYMENT_ID%type,
                                           aInfoImputationValues            in InfoImputationValuesRecType,
                                           aInfoImputation                  in InfoImputationBaseRecType)
  is
    InfoImputationValues  InfoImputationValuesRecType;
  begin
    --Copie des données pour màj
    InfoImputationValues := aInfoImputationValues;

    --Màj (null) des champs non gérés
    UpdateManagedValues(InfoImputationValues, aInfoImputation);

    --Màj de la table avec les valeurs
    SetInfoImputationValuesDET_ACI(aACI_DET_PAYMENT_ID, InfoImputationValues);

  end SetInfoImputationValuesDET_ACI;

  -------------------------

  procedure GetInfoImputationValuesIMF_ACI(aACI_FINANCIAL_IMPUTATION_ID     in     ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type,
                                           aInfoImputationValues            in out InfoImputationValuesRecType)
  is
  begin
    begin
      SELECT imf_number,
             imf_number2,
             imf_number3,
             imf_number4,
             imf_number5,
             imf_text1,
             imf_text2,
             imf_text3,
             imf_text4,
             imf_text5,
             imf_date1,
             imf_date2,
             imf_date3,
             imf_date4,
             imf_date5,
             dic_imp_free1_id,
             dic_imp_free2_id,
             dic_imp_free3_id,
             dic_imp_free4_id,
             dic_imp_free5_id,
             gco_good_id,
             hrm_person_id,
             doc_record_id,
             pac_person_id,
             fam_fixed_assets_id,
             c_fam_transaction_typ,
             InfoImputationTypeRec.GroupALL
  	    INTO aInfoImputationValues
        FROM aci_financial_imputation
       WHERE aci_financial_imputation_id = aACI_FINANCIAL_IMPUTATION_ID;
    exception
      when OTHERS then
        return;
    end;

  end GetInfoImputationValuesIMF_ACI;

  -------------------------

  procedure SetInfoImputationValuesIMF_ACI(aACI_FINANCIAL_IMPUTATION_ID     in ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type,
                                           aInfoImputationValues            in InfoImputationValuesRecType)
  is
  begin
    begin
     UPDATE aci_financial_imputation SET
            imf_number        = aInfoImputationValues.NUMBER1,
            imf_number2       = aInfoImputationValues.NUMBER2,
            imf_number3       = aInfoImputationValues.NUMBER3,
            imf_number4       = aInfoImputationValues.NUMBER4,
            imf_number5       = aInfoImputationValues.NUMBER5,
            imf_text1         = aInfoImputationValues.TEXT1,
            imf_text2         = aInfoImputationValues.TEXT2,
            imf_text3         = aInfoImputationValues.TEXT3,
            imf_text4         = aInfoImputationValues.TEXT4,
            imf_text5         = aInfoImputationValues.TEXT5,
            imf_date1         = aInfoImputationValues.DATE1,
            imf_date2         = aInfoImputationValues.DATE2,
            imf_date3         = aInfoImputationValues.DATE3,
            imf_date4         = aInfoImputationValues.DATE4,
            imf_date5         = aInfoImputationValues.DATE5,
            dic_imp_free1_id  = aInfoImputationValues.DICO1,
            dic_imp_free2_id  = aInfoImputationValues.DICO2,
            dic_imp_free3_id  = aInfoImputationValues.DICO3,
            dic_imp_free4_id  = aInfoImputationValues.DICO4,
            dic_imp_free5_id  = aInfoImputationValues.DICO5,
            gco_good_id       = aInfoImputationValues.GCO_GOOD_ID,
            hrm_person_id     = aInfoImputationValues.HRM_PERSON_ID,
            doc_record_id     = aInfoImputationValues.DOC_RECORD_ID,
            pac_person_id     = aInfoImputationValues.PAC_PERSON_ID,
            fam_fixed_assets_id   = aInfoImputationValues.FAM_FIXED_ASSETS_ID,
            c_fam_transaction_typ = aInfoImputationValues.C_FAM_TRANSACTION_TYP
      WHERE aci_financial_imputation_id = aACI_FINANCIAL_IMPUTATION_ID;
    exception
      when OTHERS then
        return;
    end;

  end SetInfoImputationValuesIMF_ACI;

  -------------------------

  procedure SetInfoImputationValuesIMF_ACI(aACI_FINANCIAL_IMPUTATION_ID     in ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type,
                                           aInfoImputationValues            in InfoImputationValuesRecType,
                                           aInfoImputation                  in InfoImputationBaseRecType)
  is
    InfoImputationValues  InfoImputationValuesRecType;
  begin
    --Copie des données pour màj
    InfoImputationValues := aInfoImputationValues;

    --Màj (null) des champs non gérés
    UpdateManagedValues(InfoImputationValues, aInfoImputation);

    --Màj de la table avec les valeurs
    SetInfoImputationValuesIMF_ACI(aACI_FINANCIAL_IMPUTATION_ID, InfoImputationValues);

  end SetInfoImputationValuesIMF_ACI;

  -------------------------

  procedure GetInfoImputationValuesIMM_ACI(aACI_MGM_IMPUTATION_ID     in     ACI_MGM_IMPUTATION.ACI_MGM_IMPUTATION_ID%type,
                                           aInfoImputationValues      in out InfoImputationValuesRecType)
  is
  begin
    begin
      SELECT imm_number,
             imm_number2,
             imm_number3,
             imm_number4,
             imm_number5,
             imm_text1,
             imm_text2,
             imm_text3,
             imm_text4,
             imm_text5,
             imm_date1,
             imm_date2,
             imm_date3,
             imm_date4,
             imm_date5,
             dic_imp_free1_id,
             dic_imp_free2_id,
             dic_imp_free3_id,
             dic_imp_free4_id,
             dic_imp_free5_id,
             gco_good_id,
             hrm_person_id,
             doc_record_id,
             pac_person_id,
             fam_fixed_assets_id,
             c_fam_transaction_typ,
             InfoImputationTypeRec.GroupALL
  	    INTO aInfoImputationValues
        FROM aci_mgm_imputation
       WHERE aci_mgm_imputation_id = aACI_MGM_IMPUTATION_ID;
    exception
      when OTHERS then
        return;
    end;

  end GetInfoImputationValuesIMM_ACI;

  -------------------------

  procedure SetInfoImputationValuesIMM_ACI(aACI_MGM_IMPUTATION_ID     in ACI_MGM_IMPUTATION.ACI_MGM_IMPUTATION_ID%type,
                                           aInfoImputationValues      in InfoImputationValuesRecType)
  is
  begin
    begin
     UPDATE aci_mgm_imputation SET
            imm_number        = aInfoImputationValues.NUMBER1,
            imm_number2       = aInfoImputationValues.NUMBER2,
            imm_number3       = aInfoImputationValues.NUMBER3,
            imm_number4       = aInfoImputationValues.NUMBER4,
            imm_number5       = aInfoImputationValues.NUMBER5,
            imm_text1         = aInfoImputationValues.TEXT1,
            imm_text2         = aInfoImputationValues.TEXT2,
            imm_text3         = aInfoImputationValues.TEXT3,
            imm_text4         = aInfoImputationValues.TEXT4,
            imm_text5         = aInfoImputationValues.TEXT5,
            imm_date1         = aInfoImputationValues.DATE1,
            imm_date2         = aInfoImputationValues.DATE2,
            imm_date3         = aInfoImputationValues.DATE3,
            imm_date4         = aInfoImputationValues.DATE4,
            imm_date5         = aInfoImputationValues.DATE5,
            dic_imp_free1_id  = aInfoImputationValues.DICO1,
            dic_imp_free2_id  = aInfoImputationValues.DICO2,
            dic_imp_free3_id  = aInfoImputationValues.DICO3,
            dic_imp_free4_id  = aInfoImputationValues.DICO4,
            dic_imp_free5_id  = aInfoImputationValues.DICO5,
            gco_good_id       = aInfoImputationValues.GCO_GOOD_ID,
            hrm_person_id     = aInfoImputationValues.HRM_PERSON_ID,
            doc_record_id     = aInfoImputationValues.DOC_RECORD_ID,
            pac_person_id     = aInfoImputationValues.PAC_PERSON_ID,
            fam_fixed_assets_id   = aInfoImputationValues.FAM_FIXED_ASSETS_ID,
            c_fam_transaction_typ = aInfoImputationValues.C_FAM_TRANSACTION_TYP
      WHERE aci_mgm_imputation_id = aACI_MGM_IMPUTATION_ID;
    exception
      when OTHERS then
        return;
    end;

  end SetInfoImputationValuesIMM_ACI;

  -------------------------

  procedure SetInfoImputationValuesIMM_ACI(aACI_MGM_IMPUTATION_ID     in ACI_MGM_IMPUTATION.ACI_MGM_IMPUTATION_ID%type,
                                           aInfoImputationValues      in InfoImputationValuesRecType,
                                           aInfoImputation            in InfoImputationBaseRecType)
  is
    InfoImputationValues  InfoImputationValuesRecType;
  begin
    --Copie des données pour màj
    InfoImputationValues := aInfoImputationValues;

    --Màj (null) des champs non gérés
    UpdateManagedValues(InfoImputationValues, aInfoImputation);

    --Màj de la table avec les valeurs
    SetInfoImputationValuesIMM_ACI(aACI_MGM_IMPUTATION_ID, InfoImputationValues);

  end SetInfoImputationValuesIMM_ACI;

  -------------------------



end ACT_IMP_MANAGEMENT;
