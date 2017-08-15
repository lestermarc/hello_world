--------------------------------------------------------
--  DDL for Package Body DOC_FOOT_ALLOY_PARITY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_FOOT_ALLOY_PARITY" 
is
  /**
  * Description
  *   Retourne le compte poids de la mati�re pied
  */
  function GetFootMatStockID(
    aDocumentID                in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aAlloyID                   in GCO_ALLOY.GCO_ALLOY_ID%type
  , aBasisMaterialID           in DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aPositionAlloyStockID      in DOC_POSITION_ALLOY.STM_STOCK_ID%type
  , aThirdStockID              in STM_STOCK.STM_STOCK_ID%type default null
  , aDefaultStockID            in STM_STOCK.STM_STOCK_ID%type default null
  , aThirdID                   in DOC_DOCUMENT.PAC_THIRD_ID%type default null
  , aThirdMaterialRelationType in PAC_CUSTOM_PARTNER.C_THIRD_MATERIAL_RELATION_TYPE%type default null
  , aAdminDomain               in DOC_GAUGE.C_ADMIN_DOMAIN%type default null
  , aMaterialMgntMode          in PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type default null
  )
    return varchar2
  is
    lvStockID STM_STOCK.STM_STOCK_ID%type;
  begin
    lvStockID  := aPositionAlloyStockID;
    DOC_FOOT_ALLOY_FUNCTIONS.GetStockID(aDocumentID                  => aDocumentID
                                      , aAlloyID                     => aAlloyID
                                      , aBasisMaterialID             => aBasisMaterialID
                                      , aStockID                     => lvStockID
                                      , aThirdStockID                => aThirdStockID
                                      , aDefaultStockID              => aDefaultStockID
                                      , aThirdID                     => aThirdID
                                      , aThirdMaterialRelationType   => aThirdMaterialRelationType
                                      , aAdminDomain                 => aAdminDomain
                                      , aMaterialMgntMode            => aMaterialMgntMode
                                       );
    return lvStockID;
  end GetFootMatStockID;

  /**
  * Description
  *    V�rification de la coh�rence d'un document et correction �ventuelle
  */
  procedure CheckDocument(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iRaiseException in boolean := false)
  is
    lvNumber           DOC_DOCUMENT.DMT_NUMBER%type;
    lnProtected        DOC_DOCUMENT.DMT_PROTECTED%type;
    lnConfirmed        DOC_DOCUMENT.DMT_CONFIRMED%type;
    lnStockMovementID  STM_STOCk_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lbSkip             boolean;
    lnFootAlloyMissing number(1);
    lnWeightDone       number(1);
    lnAmountMatOk      number(1);
    lnAmountAlloyOk    number(1);
    lnAdvanceOk        number(1);
    lnStockOK          number(1);
  begin
    -- Recherche les informations sur le document sp�cifi� n�cessaires � la cr�ation du paiement direct
    lbSkip  := false;

    begin
      select DMT.DMT_NUMBER
           , DMT.DMT_PROTECTED
           , DMT.DMT_CONFIRMED
        into lvNumber
           , lnProtected
           , lnConfirmed
        from DOC_DOCUMENT DMT
           , DOC_GAUGE_STRUCTURED GAS
       where DMT.DOC_DOCUMENT_ID = iDocumentID
         and GAS.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAS.GAS_METAL_ACCOUNT_MGM = 1;   -- Mise � jour comptes poids mati�res pr�cieuses sur gabarit
    exception
      when no_data_found then
        -- Document inexistant ou pas de mise � jour des comptes poids mati�res pr�cieuses
        lbSkip  := true;

        if iRaiseException then
          ra(aMessage => 'PCS - no document or no metal account management', aErrNo => -20001);
        end if;
    end;

    -- Contr�le l'�tat du document
    if     not lbSkip
       and (lnProtected = 1) then
      -- Document prot�g�
      lbSkip  := true;

      if iRaiseException then
        ra(aMessage => 'PCS - protected document, operation aborted', aErrNo => -20002);
      end if;
    end if;

    -- Effectue la cr�ation des mati�res pieds
    if not lbSkip then
      -- V�rifie si le document contient des mati�res positions mais pas de mati�res pieds
      select IsFootAlloyMissing(iDocumentID)
        into lnFootAlloyMissing
        from dual;

      if (lnFootAlloyMissing = 1) then
        -- Indique une demande de cr�ation des mati�res pieds
        update DOC_DOCUMENT
           set DMT_CREATE_FOOT_MAT = 1
         where DOC_DOCUMENT_ID = iDocumentID;

        -- Cr�ation des mati�res pieds
        DOC_FOOT_ALLOY_FUNCTIONS.GenerateFootMat(iDocumentID);
      end if;
    end if;

    -- Effectue les mouvements de stock pour les documents d�j� confirm� s'il ne sont pas encore g�n�r�s
    if     not lbSkip
       and (lnConfirmed = 1) then
      -- Contr�le si les mouvements sont d�j� effectu�s
      select max(SMO.STM_STOCK_MOVEMENT_ID)
        into lnStockMovementID
        from STM_STOCK_MOVEMENT SMO
           , DOC_FOOT_ALLOY DFA
       where DFA.DOC_FOOT_ID = iDocumentID
         and SMO.DOC_FOOT_ALLOY_ID = DFA.DOC_FOOT_ALLOY_ID
         and DFA.STM_STOCK_ID is not null;

      if lnStockMovementID is null then
        DOC_FOOT_ALLOY_FUNCTIONS.TestDocumentFoot(iDocumentID
                                                , lnWeightDone
                                                , lnAmountMatOk
                                                , lnAmountAlloyOk
                                                , lnAdvanceOk
                                                , lnStockOk
                                                 );

        -- saisie de montant � facturer pour les mati�res de base
        if lnAmountMatOk = 0 then
          lbSkip  := true;

          if iRaiseException then
            ra(aMessage => 'PCS - error code 120 for document ' || lvNumber, aErrNo => -20003);
          end if;
        end if;

        -- saisie de montants � facturer pour les alliages
        if lnAmountAlloyOk = 0 then
          lbSkip  := true;

          if iRaiseException then
            ra(aMessage => 'PCS - error code 121 for document ' || lvNumber, aErrNo => -20004);
          end if;
        end if;

        -- avances � d�compter
        if lnAdvanceOk = 0 then
          lbSkip  := true;

          if iRaiseException then
            ra(aMessage => 'PCS - error code 122 for document ' || lvNumber, aErrNo => -20005);
          end if;
        end if;

        -- pes�es manquantes
        if lnWeightDone = 0 then
          lbSkip  := true;

          if iRaiseException then
            ra(aMessage => 'PCS - error code 123 for document ' || lvNumber, aErrNo => -20006);
          end if;
        end if;

        -- rupture de stock mati�res pr�cieuses
        if lnStockOk = 0 then
          lbSkip  := true;

          if iRaiseException then
            ra(aMessage => 'PCS - error code 125 for document ' || lvNumber, aErrNo => -20007);
          end if;
        end if;

        -- Mouvements des mati�res pr�cieuses sur le pied du document
        if not lbSkip then
          DOC_INIT_MOVEMENT.DocFootAlloyMovements(iDocumentID);
        end if;
      end if;
    end if;
  end CheckDocument;

     /**
  * Description
  *    V�rifie si le document contient des mati�res positions mais pas de mati�res pieds
  */
  function IsFootAlloyMissing(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lnMetalAccountID DOC_POSITION_ALLOY.STM_STOCK_ID%type;
  begin
    -- Recherche la pr�sence de mati�re position avec compte poids qui ne poss�de pas de mati�re pieds
    select max(DOA.STM_STOCK_ID)
      into lnMetalAccountID
      from DOC_DOCUMENT DMT
         , DOC_FOOT_ALLOY DFA
         , DOC_POSITION POS
         , DOC_POSITION_ALLOY DOA
     where DMT.DOC_DOCUMENT_ID = iDocumentID
       and DFA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
       and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
       and DOA.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and DOA.STM_STOCK_ID = DFA.STM_STOCK_ID;

    if lnMetalAccountID is null then
      return 1;
    else
      return 0;
    end if;
  end IsFootAlloyMissing;
end DOC_FOOT_ALLOY_PARITY;
