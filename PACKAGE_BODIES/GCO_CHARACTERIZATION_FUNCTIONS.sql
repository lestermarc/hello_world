--------------------------------------------------------
--  DDL for Package Body GCO_CHARACTERIZATION_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_CHARACTERIZATION_FUNCTIONS" 
is
  function gCharManagementMode
    return number
  is
  begin
    return GCO_PRC_CHARACTERIZATION.gCharManagementMode;
  end gCharManagementMode;

  /**
  * Description : M�thode qui retourne les caract�risations associ�es � un bien donn�
  */
  procedure GetCharacterizationsID(
    aGoodId         in     GCO_GOOD.GCO_GOOD_ID%type
  , aMovementKindID in     STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , aGaugeID        in     DOC_POSITION.DOC_POSITION_ID%type
  , aGabChar        in     number
  , aAdminDomain    in     varchar2
  , aCharactID_1    in out DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type
  , aCharactID_2    in out DOC_POSITION_DETAIL.GCO_GCO_CHARACTERIZATION_ID%type
  , aCharactID_3    in out DOC_POSITION_DETAIL.GCO2_GCO_CHARACTERIZATION_ID%type
  , aCharactID_4    in out DOC_POSITION_DETAIL.GCO3_GCO_CHARACTERIZATION_ID%type
  , aCharactID_5    in out DOC_POSITION_DETAIL.GCO4_GCO_CHARACTERIZATION_ID%type
  )
  is
  begin
    GCO_LIB_CHARACTERIZATION.GetCharacterizationsID(aGoodId
                                                  , aMovementKindID
                                                  , aGaugeID
                                                  , aGabChar
                                                  , aAdminDomain
                                                  , aCharactID_1
                                                  , aCharactID_2
                                                  , aCharactID_3
                                                  , aCharactID_4
                                                  , aCharactID_5
                                                   );
  end GetCharacterizationsID;

  /**
  * Description
  *      Recherche des id de caract�rization d'un bien
  */
  procedure GetListOfCharacterization(
    aGoodId          in     number
  , aCharManagement  in     number
  , aMovementSort    in     varchar2
  , aAdminDomain     in     varchar2
  , aCharac1Id       out    number
  , aCharac2Id       out    number
  , aCharac3Id       out    number
  , aCharac4Id       out    number
  , aCharac5Id       out    number
  , aCharacType1     out    varchar2
  , aCharacType2     out    varchar2
  , aCharacType3     out    varchar2
  , aCharacType4     out    varchar2
  , aCharacType5     out    varchar2
  , aCharacStk1      out    number
  , aCharacStk2      out    number
  , aCharacStk3      out    number
  , aCharacStk4      out    number
  , aCharacStk5      out    number
  , aPieceManagement out    number
  )
  is
  begin
    GCO_LIB_CHARACTERIZATION.GetListOfCharacterization(aGoodId
                                                     , aCharManagement
                                                     , aMovementSort
                                                     , aAdminDomain
                                                     , aCharac1Id
                                                     , aCharac2Id
                                                     , aCharac3Id
                                                     , aCharac4Id
                                                     , aCharac5Id
                                                     , aCharacType1
                                                     , aCharacType2
                                                     , aCharacType3
                                                     , aCharacType4
                                                     , aCharacType5
                                                     , aCharacStk1
                                                     , aCharacStk2
                                                     , aCharacStk3
                                                     , aCharacStk4
                                                     , aCharacStk5
                                                     , aPieceManagement
                                                      );
  end GetListOfCharacterization;

  /**
  * Description
  *   Mise � jour du dernier incr�ment utilis�
  */
  procedure UpdateCharLastUsedNumber(aCharacterizationId in number, aNewValue in varchar2)
  is
  begin
    GCO_PRC_CHARACTERIZATION.UpdateCharLastUsedNumber(aCharacterizationId, aNewValue);
  end UpdateCharLastUsedNumber;

  /**
  * Description
  *   Supprime le prefixe et le suffixe � la valeur de caracterisation retourn�e
  */
  function getValueWithoutPrefix(aValue in varchar2, aPrefix in GCO_CHARACTERIZATION.CHA_PREFIXE%type, aSuffix in GCO_CHARACTERIZATION.CHA_SUFFIXE%type)
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.getValueWithoutPrefix(aValue, aPrefix, aSuffix);
  end getValueWithoutPrefix;

  /**
  * Description
  *   retourne la valeur effective d'un pr�fixe ou suffixe de caract�risation
  *   en interpr�tant les marcro qu'il contient
  */
  function prefixApplyMacro(aText in GCO_CHARACTERIZATION.CHA_PREFIXE%type)
    return GCO_CHARACTERIZATION.CHA_PREFIXE%type
  is
  begin
    return GCO_LIB_CHARACTERIZATION.prefixApplyMacro(aText);
  end prefixApplyMacro;

  /**
  * Description
  *   retourne l'�valuation d'une expression macro
  */
  function prefixInterpretMacro(aMacro in varchar2)
    return varchar2
  is
  begin
    return GCO_LIB_CHARACTERIZATION.prefixInterpretMacro(aMacro);
  end prefixInterpretMacro;

  /**
  * Description
  *      converti les id de caract�risation en ElementNumberId
  */
  procedure convertCharIdToElementNumber(
    aGoodID     in     number
  , aCharact1Id in     number
  , aCharact2Id in     number
  , aCharact3Id in     number
  , aCharact4Id in     number
  , aCharact5Id in     number
  , aCharacVal1 in     varchar2
  , aCharacVal2 in     varchar2
  , aCharacVal3 in     varchar2
  , aCharacVal4 in     varchar2
  , aCharacVal5 in     varchar2
  , aEleNum1Id  out    number
  , aEleNum2Id  out    number
  , aEleNum3Id  out    number
  )
  is
  begin
    GCO_LIB_CHARACTERIZATION.convertCharIdToElementNumber(aGoodID
                                                        , aCharact1Id
                                                        , aCharact2Id
                                                        , aCharact3Id
                                                        , aCharact4Id
                                                        , aCharact5Id
                                                        , aCharacVal1
                                                        , aCharacVal2
                                                        , aCharacVal3
                                                        , aCharacVal4
                                                        , aCharacVal5
                                                        , aEleNum1Id
                                                        , aEleNum2Id
                                                        , aEleNum3Id
                                                         );
  end convertCharIdToElementNumber;

  /**
  * Description
  *   Dans le cadre d'un ajout de
  *   procedure mettant � jour les diff�rentes tables utilisant les caract�risation
  */
  procedure addCharToExisting(aCharacterizationId in number, aDefValue in varchar2, aQualityValue in number, aRetestValue in date, aError out number)
  is
  begin
    GCO_PRC_CHARACTERIZATION.addCharToExisting(aCharacterizationId, aDefValue, aQualityValue, aRetestValue, aError);
  end addCharToExisting;

  /**
  * Description
  *   Dans le cadre d'un retrait de caract�risation
  *   procedure mettant � jour les diff�rentes tables utilisant les caract�risations
  *   !!!!!processus irr�versible!!!!!
  */
  procedure removeCharToExisting(aCharacterizationId in number, aSilent in boolean default false, aError out number)
  is
  begin
    GCO_PRC_CHARACTERIZATION.removeCharToExisting(aCharacterizationId, aSilent, aError);
  end removeCharToExisting;

  /**
  * Description
  *    Lors de l'ajout d'une caract�risation "Piece" �clater les details pour tous les encours
  */
  procedure splitDocDetailsForPiece(
    aGoodID             in GCO_GOOD.GCO_GOOD_ID%type
  , aCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aStkMgnt            in GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type
  )
  is
  begin
    GCO_PRC_CHARACTERIZATION.splitDocDetailsForPiece(aGoodID, aCharacterizationId, aStkMgnt);
  end splitDocDetailsForPiece;

  /**
  * Description
  *    Lors de l'ajout d'une caract�risation "Piece" �clater les details pour tous les encours
  */
  procedure splitFalLotDetailsForPiece(aGoodID in GCO_GOOD.GCO_GOOD_ID%type, aCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
  is
  begin
    GCO_PRC_CHARACTERIZATION.splitFalLotDetailsForPiece(aGoodID, aCharacterizationId);
  end splitFalLotDetailsForPiece;

  /**
  * Description
  *    Lors de l'ajout d'une caract�risation "Piece" �clater les details pour tous les encours
  */
  procedure splitAsaRecordForPiece(aGoodID in GCO_GOOD.GCO_GOOD_ID%type, aCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
  is
  begin
    GCO_PRC_CHARACTERIZATION.splitAsaRecordForPiece(aGoodID, aCharacterizationId);
  end splitAsaRecordForPiece;

  /**
  * Description
  *    insertion du detail des positions dans une table temporaire
  *    pour saisie manuelle des valeurs du stock
  */
  procedure fillStkPosToTemp(
    aGoodID       in GCO_GOOD.GCO_GOOD_ID%type
  , aCharactType  in GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , iQualityValue in number
  , iRetestValue  in date
  )
  is
  begin
    GCO_PRC_CHARACTERIZATION.fillStkPosToTemp(aGoodID, aCharactType, iQualityValue, iRetestValue);
  end fillStkPosToTemp;

  /**
  * Description
  *    indique si le lot poss�de des caract�risations morphologiques
  */
  function isCharMorph(aCharacterizationId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.isCharMorph(aCharacterizationId);
  end;

  /**
  * Description
  *   Est-ce que le produit est g�r� avec une date de p�remption
  */
  function IsTimeLimitManagement(aGoodID in number)
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.IsTimeLimitManagement(aGoodID);
  end IsTimeLimitManagement;

  /**
  * function IsChronoChar
  * Description
  *   Est-ce que le bien poss�de une caract�ristique chronologique
  * @created fp 15.04.2008
  * @lastUpdate
  * @public
  * @param aGoodID : id du bien � tester
  * @return 1 si OK sinon 0
  */
  function IsChronoChar(aGoodID in number)
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.IsChronoChar(aGoodID);
  end IsChronoChar;

  /**
  * Description
  *   recherche du d�lai de p�remption (si pas trouv�, retourne null)
  */
  function getLapsingMarge(aGoodID in number, aThirdId in number default null)
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.getLapsingMarge(aGoodID, aThirdId);
  end getLapsingMarge;

  -- Assignation du mode de gestion des caract�risations
  procedure SetCharManagementMode(aValue in number)
  is
  begin
    GCO_PRC_CHARACTERIZATION.SetCharManagementMode(aValue);
  end SetCharManagementMode;

  /**
  * function VerifyWizardTmpPosValues
  */
  function VerifyWizardTmpPosValues
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.VerifyWizardTmpPosValues;
  end VerifyWizardTmpPosValues;

  /**
  * function VerifyWizardTmpPosValuesGood
  */
  function VerifyWizardTmpPosValueGood(aGoodID GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.VerifyWizardTmpPosValueGood(aGoodID);
  end VerifyWizardTmpPosValueGood;

  function getWizardBalanceQty(
    aGoodID     in STM_TMP_STOCK_POSITION.GCO_GOOD_ID%type
  , aStockID    in STM_TMP_STOCK_POSITION.STM_STOCK_ID%type
  , aLocationID in STM_TMP_STOCK_POSITION.STM_LOCATION_ID%type
  , aChar1Value in STM_TMP_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , aChar2Value in STM_TMP_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , aChar3Value in STM_TMP_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , aChar4Value in STM_TMP_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  )
    return STM_TMP_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  is
  begin
    return GCO_LIB_CHARACTERIZATION.getWizardBalanceQty(aGoodID, aStockID, aLocationID, aChar1Value, aChar2Value, aChar3Value, aChar4Value);
  end getWizardBalanceQty;

  /**
  * Description
  *   G�n�ration des mouvements de transformation de l'assistant de maintenance des caract�risations
  */
  procedure GenerateWizardMovements
  is
  begin
    GCO_PRC_CHARACTERIZATION.GenerateWizardMovements;
  end GenerateWizardMovements;

  procedure setGenerateWizardMovementSp
  is
  begin
    GCO_PRC_CHARACTERIZATION.setGenerateWizardMovementSp;
  end setGenerateWizardMovementSp;

  /**
  * Description
  *   G�n�ration des mouvements de transformation de l'assistant de maintenance des caract�risations
  */
  procedure GenerateWizardMovement(aTmpStockPositionId in number, aGenerationOk out number)
  is
  begin
    GCO_PRC_CHARACTERIZATION.GenerateWizardMovement(aTmpStockPositionId, aGenerationOk);
  end GenerateWizardMovement;
end GCO_CHARACTERIZATION_FUNCTIONS;
