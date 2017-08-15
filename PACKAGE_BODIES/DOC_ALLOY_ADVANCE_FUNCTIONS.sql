--------------------------------------------------------
--  DDL for Package Body DOC_ALLOY_ADVANCE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_ALLOY_ADVANCE_FUNCTIONS" 
is
  procedure UpdateDeductedParent(aDocumentID in number, aPositionID in number, aDetailID in number, aQuantity in number)
  is
  begin
    /* M�j des d�tails,positions et documents parents des avances
         de l'avance cr��e qui est pass� en param */
    update DOC_POSITION_DETAIL
       set PDE_BALANCE_QUANTITY =
             decode(sign(PDE_FINAL_QUANTITY)
                  , -1, greatest(least( (PDE_BALANCE_QUANTITY - aQuantity), 0), PDE_FINAL_QUANTITY)
                  , least(greatest( (PDE_BALANCE_QUANTITY - aQuantity), 0), PDE_FINAL_QUANTITY)
                   )
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_DETAIL_ID = aDetailID;

    /* M�j de Qt� solde et du statut de la position */
    DOC_FUNCTIONS.UpdateBalancePosition(aPositionID
                                      , aQuantity
                                      , aQuantity
                                      , 0   /* On n'a ni de d�passement de qt� ni d�charge et solder parent avec/sans extourne */
                                       );
    /* M�j du statut du document */
    DOC_PRC_DOCUMENT.UpdateDocumentStatus(aDocumentID);
  end UpdateDeductedParent;

  /**
  * procedure GenerateAlloyAdvance
  * Description
  *   Cr�ation des d�compte avance selon donn�es de l'utilisateur figurant
  *   dans la table DOC_GENER_ALLOY_ADVANCE
  */
  procedure GenerateAlloyAdvance(aFootAlloyID in number, aMaxQty in number)
  is
    /* Liste des d�tails dispo dans la table temp pour la g�n. des avances */
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
    /* Rechercher la qt� d�j� avanc�e */
    select nvl(sum(DAA_WEIGHT_DISCHARGE), 0)
      into TotalAdvancedQty
      from DOC_ALLOY_ADVANCE
     where DOC_FOOT_ALLOY_ID = aFootAlloyID;

    /* V�rifie que la qt� � d�compter ne soit pas encore atteinte par la */
    /* qt� totale des avances d�j� effectu�es */
    if TotalAdvancedQty < aMaxQty then
      open crAdvToGen;

      fetch crAdvToGen
       into tplAdvToGen;

      /* Effectuer les avances tant que l'on a du disponnible et que l'on
         a pas d�pass� la qt� max � avancer */
      while(crAdvToGen%found)
       and (TotalAdvancedQty < aMaxQty) loop
        /* V�rifie si le document d'avance source est prot�g�. nContinue peut avoir les valeurs suivantes :
            0 = Au moins un document li� � une avance est prot�g�, g�n�ration interdite.
            1 = Au moins une avance existe et aucun document li� n'est prot�g�.
           -1 = Aucune avance n'existe sur le document courant. */
        select decode(max(DMT_PROTECTED), null, -1, 0, 1, 1, 0)
          into nContinue
          from DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = tplAdvToGen.DOC_DOCUMENT_ID;

        if    (nContinue = 1)
           or (nContinue = -1) then
          /* Protection du document source dans une transaction autonome
             et met l'ID du document dans une liste pour faire la d�protection */
--          ProtectSrcDocument(tplAdvToGen.DOC_DOCUMENT_ID);
          /* Qt� � avancer :
             prendre la qt� minimale entre la qt� max que ll'on peut encore avancer
             et la qt� disponnible sur le d�tail */
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

          /* M�j la variable indiquant la qt� avancer */
          TotalAdvancedQty  := TotalAdvancedQty + AdvQty;
          /* M�j des qt� solde du d�tail parent et m�j statut position/document */
          UpdateDeductedParent(tplAdvToGen.DOC_DOCUMENT_ID, tplAdvToGen.DOC_POSITION_ID, tplAdvToGen.DOC_POSITION_DETAIL_ID, AdvQty);
        else
          raise_application_error(-20090, 'G�n�ration impossible, le document d''avance est prot�g�');
        end if;

        fetch crAdvToGen
         into tplAdvToGen;
      end loop;

      close crAdvToGen;

      /* M�j de la mati�re de pied apr�s la cr�ation des d�comptes avance */
      UpdateFootPrecMat(aFootAlloyID);
    end if;
  end GenerateAlloyAdvance;

  /**
  * procedure UpdateFootPrecMat
  * Description
  *   M�j de la mati�re de pied apr�s la cr�ation des d�comptes avance
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
         Somme des "Poids d�charg�" des d�comptes avance
         Somme des "Montant d�charg�" des d�comptes avance */
      select nvl(sum(DAA_WEIGHT_DISCHARGE), 0)
           , nvl(sum(DAA_AMOUNT), 0)
        into TotalWeightDischarge
           , TotalAmount
        from DOC_ALLOY_ADVANCE
       where DOC_FOOT_ALLOY_ID = aFootAlloyID;

      /* Calcul du Cours factur�
         Cours factur� =   Somme des "Montant d�charg�" des d�comptes avance /
                           Somme des "Poids d�charg�" des d�comptes avance */
      if TotalWeightDischarge <> 0 then
        tmpDFA_RATE  := TotalAmount / TotalWeightDischarge;
      else
        tmpDFA_RATE  := 0;
      end if;

      /* M�j "Mati�re pied" */
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
