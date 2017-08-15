--------------------------------------------------------
--  DDL for Package Body DOC_ALLOY_ADVANCE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_ALLOY_ADVANCE_FUNCTIONS" 
is
  procedure UpdateDeductedParent(aDocumentID in number, aPositionID in number, aDetailID in number, aQuantity in number)
  is
  begin
    /* Màj des détails,positions et documents parents des avances
         de l'avance créée qui est passé en param */
    update DOC_POSITION_DETAIL
       set PDE_BALANCE_QUANTITY =
             decode(sign(PDE_FINAL_QUANTITY)
                  , -1, greatest(least( (PDE_BALANCE_QUANTITY - aQuantity), 0), PDE_FINAL_QUANTITY)
                  , least(greatest( (PDE_BALANCE_QUANTITY - aQuantity), 0), PDE_FINAL_QUANTITY)
                   )
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_DETAIL_ID = aDetailID;

    /* Màj de Qté solde et du statut de la position */
    DOC_FUNCTIONS.UpdateBalancePosition(aPositionID
                                      , aQuantity
                                      , aQuantity
                                      , 0   /* On n'a ni de dépassement de qté ni décharge et solder parent avec/sans extourne */
                                       );
    /* Màj du statut du document */
    DOC_PRC_DOCUMENT.UpdateDocumentStatus(aDocumentID);
  end UpdateDeductedParent;

  /**
  * procedure GenerateAlloyAdvance
  * Description
  *   Création des décompte avance selon données de l'utilisateur figurant
  *   dans la table DOC_GENER_ALLOY_ADVANCE
  */
  procedure GenerateAlloyAdvance(aFootAlloyID in number, aMaxQty in number)
  is
    /* Liste des détails dispo dans la table temp pour la gén. des avances */
    cursor crAdvToGen
    is
      select   *
          from DOC_GENER_ALLOY_ADVANCE
         where DGA_WEIGHT_DEDUCT > 0
      order by DOC_GENER_ALLOY_ADVANCE_ID;

    tplAdvToGen      crAdvToGen%rowtype;
    TotalAdvancedQty number;
    AdvQty           number;
    nContinue        number;
  begin
    /* Rechercher la qté dèjà avancée */
    select nvl(sum(DAA_WEIGHT_DISCHARGE), 0)
      into TotalAdvancedQty
      from DOC_ALLOY_ADVANCE
     where DOC_FOOT_ALLOY_ID = aFootAlloyID;

    /* Vérifie que la qté à décompter ne soit pas encore atteinte par la */
    /* qté totale des avances déjà effectuées */
    if TotalAdvancedQty < aMaxQty then
      open crAdvToGen;

      fetch crAdvToGen
       into tplAdvToGen;

      /* Effectuer les avances tant que l'on a du disponnible et que l'on
         a pas dépassé la qté max à avancer */
      while(crAdvToGen%found)
       and (TotalAdvancedQty < aMaxQty) loop
        /* Vérifie si le document d'avance source est protégé. nContinue peut avoir les valeurs suivantes :
            0 = Au moins un document lié à une avance est protègé, génération interdite.
            1 = Au moins une avance existe et aucun document lié n'est protègé.
           -1 = Aucune avance n'existe sur le document courant. */
        select decode(max(DMT_PROTECTED), null, -1, 0, 1, 1, 0)
          into nContinue
          from DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = tplAdvToGen.DOC_DOCUMENT_ID;

        if    (nContinue = 1)
           or (nContinue = -1) then
          /* Protection du document source dans une transaction autonome
             et met l'ID du document dans une liste pour faire la déprotection */
--          ProtectSrcDocument(tplAdvToGen.DOC_DOCUMENT_ID);
          /* Qté à avancer :
             prendre la qté minimale entre la qté max que ll'on peut encore avancer
             et la qté disponnible sur le détail */
          AdvQty            := least( (aMaxQty - TotalAdvancedQty), tplAdvToGen.DGA_WEIGHT_DEDUCT);

          /* insertion de l'avance */
          insert into DOC_ALLOY_ADVANCE
                      (DOC_ALLOY_ADVANCE_ID
                     , DOC_FOOT_ALLOY_ID
                     , DOC_DOCUMENT_ID
                     , DOC_DOC_DOCUMENT_ID
                     , DOC_POSITION_ID
                     , DOC_POSITION_DETAIL_ID
                     , DAA_WEIGHT_DISCHARGE
                     , DAA_RATE
                     , DAA_AMOUNT
                     , A_DATECRE
                     , A_IDCRE
                      )
            select INIT_ID_SEQ.nextval
                 , aFootAlloyID
                 , tplAdvToGen.DOC_DOCUMENT_ID
                 , tplAdvToGen.DOC_DOC_DOCUMENT_ID
                 , tplAdvToGen.DOC_POSITION_ID
                 , tplAdvToGen.DOC_POSITION_DETAIL_ID
                 , AdvQty
                 , tplAdvToGen.DGA_RATE
                 , tplAdvToGen.DGA_RATE * AdvQty
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
              from dual;

          /* Màj la variable indiquant la qté avancer */
          TotalAdvancedQty  := TotalAdvancedQty + AdvQty;
          /* Màj des qté solde du détail parent et màj statut position/document */
          UpdateDeductedParent(tplAdvToGen.DOC_DOCUMENT_ID, tplAdvToGen.DOC_POSITION_ID, tplAdvToGen.DOC_POSITION_DETAIL_ID, AdvQty);
        else
          raise_application_error(-20090, 'Génération impossible, le document d''avance est protègé');
        end if;

        fetch crAdvToGen
         into tplAdvToGen;
      end loop;

      close crAdvToGen;

      /* Màj de la matière de pied après la création des décomptes avance */
      UpdateFootPrecMat(aFootAlloyID);
    end if;
  end GenerateAlloyAdvance;

  /**
  * procedure UpdateFootPrecMat
  * Description
  *   Màj de la matière de pied après la création des décomptes avance
  */
  procedure UpdateFootPrecMat(aFootAlloyID in number)
  is
    TotalWeightDischarge DOC_ALLOY_ADVANCE.DAA_WEIGHT_DISCHARGE%type;
    TotalAmount          DOC_ALLOY_ADVANCE.DAA_AMOUNT%type;
    tmpDFA_RATE          DOC_FOOT_ALLOY.DFA_RATE%type;
    bStop                boolean;
    advMaterialMode      PAC_CUSTOM_PARTNER.C_ADV_MATERIAL_MODE%type;
  begin
    bStop  := false;

    -- Recherche le mode de gestion des avances sur le tiers.
    begin
      select decode(GAU.C_ADMIN_DOMAIN
                  , 1, SUP.C_ADV_MATERIAL_MODE
                  , 2, CUS.C_ADV_MATERIAL_MODE
                  , 5, SUP.C_ADV_MATERIAL_MODE
                  , nvl(CUS.C_ADV_MATERIAL_MODE, SUP.C_ADV_MATERIAL_MODE)
                   )
        into advMaterialMode
        from DOC_FOOT_ALLOY DFA
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where DFA.DOC_FOOT_ALLOY_ID = aFootAlloyID
         and DMT.DOC_DOCUMENT_ID = DFA.DOC_FOOT_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID;
    exception
      when no_data_found then
        bStop  := true;
    end;

    if not bStop then
      /* Recherche de :
         Somme des "Poids déchargé" des décomptes avance
         Somme des "Montant déchargé" des décomptes avance */
      select nvl(sum(DAA_WEIGHT_DISCHARGE), 0)
           , nvl(sum(DAA_AMOUNT), 0)
        into TotalWeightDischarge
           , TotalAmount
        from DOC_ALLOY_ADVANCE
       where DOC_FOOT_ALLOY_ID = aFootAlloyID;

      /* Calcul du Cours facturé
         Cours facturé =   Somme des "Montant déchargé" des décomptes avance /
                           Somme des "Poids déchargé" des décomptes avance */
      if TotalWeightDischarge <> 0 then
        tmpDFA_RATE  := TotalAmount / TotalWeightDischarge;
      else
        tmpDFA_RATE  := 0;
      end if;

      /* Màj "Matière pied" */
      update DOC_FOOT_ALLOY
         set DFA_BASE_COST = 1
           , DFA_RATE = tmpDFA_RATE
           , DFA_AMOUNT = TotalAmount
           , C_MUST_ADVANCE =
               decode(advMaterialMode
                    , '01', decode(TotalWeightDischarge, 0, C_MUST_ADVANCE, nvl(DFA_WEIGHT_DELIVERY, 0), '02', '01')
                    , '02', decode(TotalWeightDischarge, 0, C_MUST_ADVANCE, nvl(DFA_WEIGHT_DELIVERY, 0) + nvl(DFA_LOSS, 0), '02', '01')
                    , '03', decode(TotalWeightDischarge, 0, C_MUST_ADVANCE, nvl(DFA_WEIGHT_INVEST, 0), '02', '01')
                     )
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_FOOT_ALLOY_ID = aFootAlloyID;
    end if;
  end UpdateFootPrecMat;
end DOC_ALLOY_ADVANCE_FUNCTIONS;
