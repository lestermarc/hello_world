--------------------------------------------------------
--  DDL for Package Body MGM_DISTRIBUTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MGM_DISTRIBUTIONS" 
is

  /**
  * Description: Procedure g�n�rale de  cr�ations des donn�es de base de la r�partition
  **/
  procedure GetDistributionDatas(pDistributionId MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                                 pStartPeriodId  MGM_DISTRIBUTION.ACS_PERIOD_START_ID%type,
                                 pEndPeriodId     MGM_DISTRIBUTION.ACS_PERIOD_END_ID%type,
                                 pBudgetVersionId MGM_DISTRIBUTION.ACB_BUDGET_VERSION_ID%type)
  is
    vBudgetVersionId MGM_DISTRIBUTION.ACB_BUDGET_VERSION_ID%type;
  begin
    if (pBudgetVersionId = 0) or (pBudgetVersionId is null) then
      vBudgetVersionId := null;
    else
      vBudgetVersionId := pBudgetVersionId;
    end if;
    /*Cr�ation des soldes avant r�partition des axes analytiques*/
    GetDistributionBalance(pDistributionId, pStartPeriodId, pEndPeriodId,vBudgetVersionId);
    /*Cr�ation des d�tails de r�partition avec les sources et cibles*/
    GetDistributionDetail(pDistributionId, vBudgetVersionId);
    /*Cr�ation des taux unit�s d'oeuvre*/
    GetDistributionRates(pDistributionId, vBudgetVersionId);
  end GetDistributionDatas;

  /**
  * Description: Constitution des soldes crois�es des axes analytiques pour les p�riode donn�es
  **/
  procedure GetDistributionBalance(pDistributionId  MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                                   pStartPeriodId   MGM_DISTRIBUTION.ACS_PERIOD_START_ID%type,
                                   pEndPeriodId     MGM_DISTRIBUTION.ACS_PERIOD_END_ID%type,
                                   pBudgetVersionId MGM_DISTRIBUTION.ACB_BUDGET_VERSION_ID%type)
  is
    /**
    * Curseur de recherche des montants par axes analytiques des positions des totaux par p�riode
    * comprises dans les p�riodes donn�es en monnaie locale
    **/
    cursor cTotalByPeriod
    is
      select MGM.ACS_CPN_ACCOUNT_ID,
             MGM.ACS_CDA_ACCOUNT_ID,
             MGM.ACS_PF_ACCOUNT_ID,
             MGM.ACS_PJ_ACCOUNT_ID,
             MGM.DOC_RECORD_ID,
             MGM.ACS_QTY_UNIT_ID,
             nvl(sum(nvl(MGM.MTO_DEBIT_LC,0)),0)   MTO_DEBIT_LC,
             nvl(sum(nvl(MGM.MTO_CREDIT_LC,0)),0)  MTO_CREDIT_LC,
             nvl(sum(nvl(MGM.MTO_QUANTITY_D,0)),0) MTO_QUANTITY_D,
             nvl(sum(nvl(MGM.MTO_QUANTITY_C,0)),0) MTO_QUANTITY_C
      from ACS_PERIOD PER_START,
           ACS_PERIOD PER_END,
           ACS_PERIOD PER,
           ACT_MGM_TOT_BY_PERIOD MGM,
           MGM_DISTRIBUTION DIS
      where DIS.MGM_DISTRIBUTION_ID = pDistributionId
        and PER_START.ACS_PERIOD_ID = DIS.ACS_PERIOD_START_ID
        and PER_END.ACS_PERIOD_ID   = DIS.ACS_PERIOD_END_ID
        and PER.PER_START_DATE     >= PER_START.PER_START_DATE
        and PER.PER_END_DATE       <= PER_END.PER_END_DATE
        and PER.C_TYPE_PERIOD      <> 1
        and MGM.ACS_PERIOD_ID       = PER.ACS_PERIOD_ID
        and MGM.ACS_ACS_FINANCIAL_CURRENCY_ID = LocalCurrencyId
        and exists(select 1
                   from MGM_CUMUL TOT
                   where TOT.MGM_DISTRIBUTION_MODEL_ID = DIS.MGM_DISTRIBUTION_MODEL_ID
                     and MGM.C_TYPE_CUMUL = TOT.C_TYPE_CUMUL
                   )
      group by MGM.ACS_CPN_ACCOUNT_ID,
               MGM.ACS_CDA_ACCOUNT_ID,
               MGM.ACS_PF_ACCOUNT_ID,
               MGM.ACS_PJ_ACCOUNT_ID,
               MGM.DOC_RECORD_ID,
               MGM.ACS_QTY_UNIT_ID;

    /**
    * Curseur de recherche des montants par axes analytiques de la version par d�faut
    * de l'exercice de la p�riode donn�e
    **/
    cursor cDefaultBudget
    is
      select GLO.ACS_CPN_ACCOUNT_ID
            ,GLO.ACS_CDA_ACCOUNT_ID
            ,GLO.ACS_PF_ACCOUNT_ID
            ,GLO.ACS_PJ_ACCOUNT_ID
            ,GLO.DOC_RECORD_ID
            ,GLO.ACS_QTY_UNIT_ID
            ,nvl(sum(nvl(APA.PER_AMOUNT_D,0)),0) PER_AMOUNT_D
            ,nvl(sum(nvl(APA.PER_AMOUNT_C,0)),0) PER_AMOUNT_C
            ,nvl(sum(nvl(APA.PER_QTY_D,0)),0)    PER_QTY_D
            ,nvl(sum(nvl(APA.PER_QTY_C,0)),0)    PER_QTY_C
      from ACB_PERIOD_AMOUNT APA
          ,ACB_GLOBAL_BUDGET GLO
          ,ACB_BUDGET_VERSION VER
          ,ACB_BUDGET BUD
          ,ACS_PERIOD PER_START
          ,ACS_PERIOD PER_END
          ,ACS_PERIOD PER
      where PER_START.ACS_PERIOD_ID   = pStartPeriodId
        and PER_END.ACS_PERIOD_ID     = pEndPeriodId
        and PER.PER_START_DATE       >= PER_START.PER_START_DATE
        and PER.PER_END_DATE         <= PER_END.PER_END_DATE
        and PER.C_TYPE_PERIOD        <> 1
        and BUD.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
        and VER.ACB_BUDGET_ID         = BUD.ACB_BUDGET_ID
        and VER.VER_DEFAULT           = 1
        and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID
        and APA.ACB_GLOBAL_BUDGET_ID  = GLO.ACB_GLOBAL_BUDGET_ID
        and APA.ACS_PERIOD_ID         = PER.ACS_PERIOD_ID
      group by GLO.ACS_CPN_ACCOUNT_ID,
               GLO.ACS_CDA_ACCOUNT_ID,
               GLO.ACS_PF_ACCOUNT_ID,
               GLO.ACS_PJ_ACCOUNT_ID,
               GLO.DOC_RECORD_ID,
               GLO.ACS_QTY_UNIT_ID;

    /**
    * Curseur de recherche des montants par axes analytiques de la version budget
    * donn�e
    **/
    cursor cBudgetVersion
    is
      select GLO.ACS_CPN_ACCOUNT_ID
            ,GLO.ACS_CDA_ACCOUNT_ID
            ,GLO.ACS_PF_ACCOUNT_ID
            ,GLO.ACS_PJ_ACCOUNT_ID
            ,GLO.DOC_RECORD_ID
            ,GLO.ACS_QTY_UNIT_ID
            ,nvl(sum(nvl(APA.PER_AMOUNT_D,0)),0) PER_AMOUNT_D
            ,nvl(sum(nvl(APA.PER_AMOUNT_C,0)),0) PER_AMOUNT_C
            ,nvl(sum(nvl(APA.PER_QTY_D,0)),0)    PER_QTY_D
            ,nvl(sum(nvl(APA.PER_QTY_C,0)),0)    PER_QTY_C
      from ACB_PERIOD_AMOUNT APA
          ,ACB_GLOBAL_BUDGET GLO
          ,ACS_PERIOD PER_START
          ,ACS_PERIOD PER_END
          ,ACS_PERIOD PER
      where PER_START.ACS_PERIOD_ID   = pStartPeriodId
        and PER_END.ACS_PERIOD_ID     = pEndPeriodId
        and PER.PER_START_DATE       >= PER_START.PER_START_DATE
        and PER.PER_END_DATE         <= PER_END.PER_END_DATE
        and PER.C_TYPE_PERIOD        <> 1
        and GLO.ACB_BUDGET_VERSION_ID = pBudgetVersionId
        and APA.ACB_GLOBAL_BUDGET_ID  = GLO.ACB_GLOBAL_BUDGET_ID
        and APA.ACS_PERIOD_ID         = PER.ACS_PERIOD_ID
      group by GLO.ACS_CPN_ACCOUNT_ID,
               GLO.ACS_CDA_ACCOUNT_ID,
               GLO.ACS_PF_ACCOUNT_ID,
               GLO.ACS_PJ_ACCOUNT_ID,
               GLO.DOC_RECORD_ID,
               GLO.ACS_QTY_UNIT_ID;

    vTotalByPeriod    cTotalByPeriod%rowtype;--R�ceptionne les enregistrement du curseur
    vDefaultBudget    cDefaultBudget%rowtype;--R�ceptionne les enregistrement du curseur
    vBudgetVersion    cBudgetVersion%rowtype;--R�ceptionne les enregistrement du curseur
    vBalancePosition  MGM_DISTRIBUTION_BALANCE.MGM_DISTRIBUTION_BALANCE_ID%type;--R�ceptionne id position solde cr��e
  begin
    /*Suppression des �ventuelles positions d�j� existantes*/
    delete from MGM_DISTRIBUTION_BALANCE where MGM_DISTRIBUTION_ID = pDistributionId;

    /**
    * Si version budget est saisie les montants de solde sont les montants de la version et les montant budget
    *   ne sont pas initialis�s
    * sinon les montants de soldes respectivemetnt budget sont r�cup�r�s de leurs tables respectives
    **/
    if (pBudgetVersionId is null) or (pBudgetVersionId = 0)then
      /**
      * Parcours du curseur et cr�ation / modification des position de solde avant r�partition
      **/
      open cTotalByPeriod;
      fetch cTotalByPeriod into  vTotalByPeriod;
      while cTotalByPeriod%found
      loop
        vBalancePosition := CreateBalancePosition(pDistributionId,                   --R�partition parente
                                                  vTotalByPeriod.ACS_CPN_ACCOUNT_ID, --Compte CPN
                                                  vTotalByPeriod.ACS_CDA_ACCOUNT_ID, --Compte CDA
                                                  vTotalByPeriod.ACS_PF_ACCOUNT_ID,  --Compte PF
                                                  vTotalByPeriod.ACS_PJ_ACCOUNT_ID,  --Compte PJ
                                                  vTotalByPeriod.DOC_RECORD_ID,      --Dossier
                                                  vTotalByPeriod.ACS_QTY_UNIT_ID,    --Quantit�s
                                                  vTotalByPeriod.MTO_DEBIT_LC,       --Montant d�bit
                                                  vTotalByPeriod.MTO_CREDIT_LC,      --Montan cr�dit
                                                  vTotalByPeriod.MTO_QUANTITY_D,     --Quantit� d�bit
                                                  vTotalByPeriod.MTO_QUANTITY_C,     --Quantit� cr�dit
                                                  0);                                --Indique un montant budgetis�
      fetch cTotalByPeriod into  vTotalByPeriod;
      end loop;
      close cTotalByPeriod;

      /**
      * Parcours du curseur et cr�ation / modification des position de solde avant r�partition
      **/
      open cDefaultBudget;
      fetch cDefaultBudget into  vDefaultBudget;
      while cDefaultBudget%found
      loop
        vBalancePosition := CreateBalancePosition(pDistributionId,                   --R�partition parente
                                                  vDefaultBudget.ACS_CPN_ACCOUNT_ID, --Compte CPN
                                                  vDefaultBudget.ACS_CDA_ACCOUNT_ID, --Compte CDA
                                                  vDefaultBudget.ACS_PF_ACCOUNT_ID,  --Compte PF
                                                  vDefaultBudget.ACS_PJ_ACCOUNT_ID,  --Compte PJ
                                                  vDefaultBudget.DOC_RECORD_ID,      --Dossier
                                                  vDefaultBudget.ACS_QTY_UNIT_ID,    --Quantit�s
                                                  vDefaultBudget.PER_AMOUNT_D,       --Montant d�bit
                                                  vDefaultBudget.PER_AMOUNT_C,       --Montan cr�dit
                                                  vDefaultBudget.PER_QTY_D,          --Quantit� d�bit
                                                  vDefaultBudget.PER_QTY_C,          --Quantit� cr�dit
                                                  1);                                --Indique un montant budgetis�
      fetch cDefaultBudget into  vDefaultBudget;
      end loop;
      close cDefaultBudget;
    else
      /**
      * Parcours du curseur et cr�ation / modification des position de solde avant r�partition
      **/
      open cBudgetVersion;
      fetch cBudgetVersion into  vBudgetVersion;
      while cBudgetVersion%found
      loop
        vBalancePosition := CreateBalancePosition(pDistributionId,                   --R�partition parente
                                                  vBudgetVersion.ACS_CPN_ACCOUNT_ID, --Compte CPN
                                                  vBudgetVersion.ACS_CDA_ACCOUNT_ID, --Compte CDA
                                                  vBudgetVersion.ACS_PF_ACCOUNT_ID,  --Compte PF
                                                  vBudgetVersion.ACS_PJ_ACCOUNT_ID,  --Compte PJ
                                                  vBudgetVersion.DOC_RECORD_ID,      --Dossier
                                                  vBudgetVersion.ACS_QTY_UNIT_ID,    --Quantit�s
                                                  vBudgetVersion.PER_AMOUNT_D,       --Montant d�bit
                                                  vBudgetVersion.PER_AMOUNT_C,       --Montan cr�dit
                                                  vBudgetVersion.PER_QTY_D,          --Quantit� d�bit
                                                  vBudgetVersion.PER_QTY_C,          --Quantit� cr�dit
                                                  0);                                --Indique un montant budgetis�
      fetch cBudgetVersion into  vBudgetVersion;
      end loop;
      close cBudgetVersion;
    end if;
  end GetDistributionBalance;

  /**
  * Description: Cr�ation des d�tails de r�partition avec les sources et cibles
  **/
  procedure GetDistributionDetail(pDistributionId MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                                  pBudgetVersionId MGM_DISTRIBUTION.ACB_BUDGET_VERSION_ID%type
                                 )
  is
    /**
    * Curseur de recherche des champs utilis�es pour cr�ation des d�tails r�partition.
    * Les d�tails seront cr��s par ordre de s�quence de mod�le et s�quence d'�l�ment
    **/
    cursor cDetails
    is
      select MDE.MGM_DISTRIBUTION_ELEMENT_ID,
             MUT.MGM_TRANSFER_UNIT_ID,
             MMS.MMS_SEQUENCE,
             MSE.MSE_SEQUENCE
      from MGM_DISTRIBUTION DIS,
           MGM_MODEL_SEQUENCE MMS,
           MGM_STRUCTURE_ELEMENT MSE,
           MGM_DISTRIBUTION_ELEMENT MDE,
           MGM_USAGE_TYPE MUT
      where DIS.MGM_DISTRIBUTION_ID = pDistributionId
        and MMS.MGM_DISTRIBUTION_MODEL_ID = DIS.MGM_DISTRIBUTION_MODEL_ID
        and not MMS.MGM_DISTRIBUTION_STRUCTURE_ID is null
        and MSE.MGM_DISTRIBUTION_STRUCTURE_ID = MMS.MGM_DISTRIBUTION_STRUCTURE_ID
        and MDE.MGM_DISTRIBUTION_ELEMENT_ID = MSE.MGM_DISTRIBUTION_ELEMENT_ID
        and MUT.MGM_USAGE_TYPE_ID = MDE.MGM_USAGE_TYPE_ID
      order by MMS_SEQUENCE,MSE_SEQUENCE;

    vDetail          cDetails%rowtype;                                         --R�ceptionne les enregistrement du curseur
    vDetailId        MGM_DISTRIBUTION_DETAIL.MGM_DISTRIBUTION_DETAIL_ID%type;  --R�ceptionne id de d�tail cr��
  begin
    /**
    *Suppression des �ventuelles positions d�j� existantes
    **/
    delete from MGM_DISTRIBUTION_DETAIL where MGM_DISTRIBUTION_ID = pDistributionId;
    /**
    * Parcours du curseur et cr�ation des position de d�tail
    **/
    open cDetails;
    fetch cDetails into  vDetail;
    while cDetails%found
    loop
      vDetailId := CreateDetailPosition(pDistributionId,                     --R�partition parente
                                        vDetail.MGM_DISTRIBUTION_ELEMENT_ID, --El�ment de r�partition
                                        vDetail.MGM_TRANSFER_UNIT_ID,        --Unit� de mesure
                                        vDetail.MMS_SEQUENCE,                --S�quence mod�le
                                        vDetail.MSE_SEQUENCE);               --S�quence �l�ment de structure
      /**
      * La cr�ation d�tail a r�ussie....Cr�ation des sources et cibles de r�partition du d�tail
      **/
      if not vDetailId is null then
        GetDetailOriginTarget(vDetailId,pBudgetVersionId);
      end if;
    fetch cDetails into  vDetail;
    end loop;
    close cDetails;
  end GetDistributionDetail;

  /**
  * Description: Constitution des taux sources / cibles des d�tails de r�partition
  */
  procedure GetDistributionRates(pDistributionId MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                                 pBudgetVersionId MGM_DISTRIBUTION.ACB_BUDGET_VERSION_ID%type)
  is
    /*Curseur de recherche des s�quences , �l�ments de r�partition */
    cursor cDetails
    is
      select DET.MGM_TRANSFER_UNIT_ID,
             MTU.C_MGM_UNIT_ORIGIN,
             MUT.MGM_USAGE_TYPE_ID,
             DIS.ACS_PERIOD_START_ID,
             DIS.ACS_PERIOD_END_ID,
             DIS.ACS_FINANCIAL_YEAR_ID,
             DET.MGM_DISTRIBUTION_DETAIL_ID,
             ELM.MGM_RATE_USAGE_TYPE_ID
      from MGM_DISTRIBUTION_DETAIL DET,
           MGM_TRANSFER_UNIT MTU,
           MGM_USAGE_TYPE MUT,
           MGM_DISTRIBUTION DIS,
           MGM_DISTRIBUTION_ELEMENT ELM
      where DIS.MGM_DISTRIBUTION_ID  = pDistributionId
        and DET.MGM_DISTRIBUTION_ID  = DIS.MGM_DISTRIBUTION_ID
        and DET.MGM_DISTRIBUTION_ELEMENT_ID = ELM.MGM_DISTRIBUTION_ELEMENT_ID
        and ELM.MGM_RATE_USAGE_TYPE_ID  = MUT.MGM_USAGE_TYPE_ID
        and MUT.MGM_TRANSFER_UNIT_ID = MTU.MGM_TRANSFER_UNIT_ID
      order by DET.MGM_DISTRIBUTION_DETAIL_ID;

    vDetail           cDetails%rowtype;                     --R�ceptionne les enregistrement du curseur
    vRateId           MGM_UNIT_RATE.MGM_UNIT_RATE_ID%type;  --R�ceptionne id  taux cr��
    vRateNumber       number;                               --R�ceptionne la somme des nombres d'une unit� de mesure
    vRateCounter      number;                               --Compteur de rows de la table des taux
    vRateAmount       MGM_UNIT_RATE.MUR_AMOUNT%type;        --R�ceptionn le montant du taux
    vCpnAmount        MGM_UNIT_RATE.MUR_AMOUNT%type;
    vRateOriginAmount MGM_UNIT_RATE.MUR_AMOUNT%type;           --R�ceptionne le montant du taux
    vUsageTypeId      MGM_UNIT_RATE.MGM_USAGE_TYPE_ID%type;    --R�ceptionne l'unit� trait�
    vCurrentUnitId    MGM_UNIT_RATE.MGM_USAGE_TYPE_ID%type;    --R�ceptionne l'unit� trait�
    vCPNGroup         MGM_UNIT_RATE.MUR_CPN_GROUP%type;
    vUpdate           Boolean;

    vCPNCursorText   MGM_DISTRIBUTION_ELEMENT.MDE_CPN_ORIGIN_CONDITION%type; --R�ceptionne les commandes SQL de s�lection des comptes...
    vCPNAccount      TAccountLimit;                                          --R�ceptionne les comptes CPN prises en compte
    vCPNCounter      number;                                                 --Compteur de rows des tables temporaires
    /**
    * Fonction de retour du num�ro de compte
    **/
    function GetCPNAccNumber(pAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type) return ACS_ACCOUNT.ACC_NUMBER%type
    is
      vResult ACS_ACCOUNT.ACC_NUMBER%type;
    begin
      vResult := '';
      begin
        select ACC_NUMBER
        into vResult
        from ACS_ACCOUNT
        where ACS_ACCOUNT_ID = pAccountId;
      exception
        when others then
          vResult := '';
      end;
      return vResult;
    end GetCPNAccNumber;
  begin
    vRateNumber    := 0.0;
    vRateCounter   := 0.0;
    vUsageTypeId   := 0.0;
    vCurrentUnitId := 0.0;

    /**
    *Suppression des �ventuelles positions d�j� existantes
    **/
    delete from MGM_UNIT_RATE where MGM_DISTRIBUTION_ID = pDistributionId;
    /*Parcours des enregistrements du curseur et cr�ation des position*/
    open cDetails;
    fetch cDetails into  vDetail;
    while cDetails%found
    loop
      if vDetail.MGM_USAGE_TYPE_ID <> vUsageTypeId then
        vUsageTypeId := vDetail.MGM_TRANSFER_UNIT_ID;
        /**
        * Initialisation de la structure temporaire de r�ception des �l�ments cibles et leurs nombres
        * avec les types "Unit� d'oeuvre"
        **/
        GetElementsRates(pDistributionId,
                         vDetail.MGM_USAGE_TYPE_ID,
                         vDetail.C_MGM_UNIT_ORIGIN,
                         '2',
                         vDetail.ACS_PERIOD_START_ID,
                         vDetail.ACS_PERIOD_END_ID,
                         vDetail.ACS_FINANCIAL_YEAR_ID,
                         pBudgetVersionId,
                         vRateNumber);
        /**
        * Des �lments d'unit� d'oeuvre existent
        **/
        if vTargetElement.Count > 0 then
          vCurrentUnitId := 0.0;
          vRateId        := 0.0;
          for vRateCounter in vTargetElement.First ..vTargetElement.last
          loop
            vUpdate := True;
            /**
            * La recherche des montants faisant appel � une fonction globale selon comptes
            * ...elle n'est appel�e qu'une fois  pour chaue position d'unit� d'oeuvre
            * ...le curseur retournant le produit cart�sien des tables , p�riodes....
            **/
            if vCurrentUnitId <> vTargetElement(vRateCounter).TARGET_ID then
              /**
              * La ligne de l'unit� appliqu�e poss�de un filtre sur les CPN
              * le montant = somme des montants des CPN g�r�s
              */
              if not ((vTargetElement(vRateCounter).ACS_CPN_ACCOUNT_ID is null) and
                      (vTargetElement(vRateCounter).ACS_ACS_CPN_ACCOUNT_ID is null) and
                      (vTargetElement(vRateCounter).MAU_CPN_CONDITION is null) )then
                /*R�cup�ration de la commande SQL */
                vCPNCursorText := GetAccountCursor(vTargetElement(vRateCounter).MAU_CPN_CONDITION,
                                                   vTargetElement(vRateCounter).ACS_CPN_ACCOUNT_ID,
                                                   vTargetElement(vRateCounter).ACS_ACS_CPN_ACCOUNT_ID,
                                                   'CPN');
                begin
                  execute immediate vCPNCursorText bulk collect into vCPNAccount; --Ouverture des curseurs des comptes CPN
                exception
                  when others then
                    raise_application_error(-20001, chr(13) ||PCS.PC_FUNCTIONS.TRANSLATEWORD('NO_VALID_CTYP_TARGET') ||  chr(13) || vCPNCursorText ||  chr(13));
                end;
                if vCPNAccount.count <> 0 then                                  --...Traitement uniquement si CPN renseign�
                  vCpnAmount := 0.0;
                  for vCPNCounter in vCPNAccount.First..vCPNAccount.Last
                  loop

                    GetRateTupleAmount(pDistributionId,
                                       vDetail.MGM_DISTRIBUTION_DETAIL_ID,
                                       vDetail.MGM_TRANSFER_UNIT_ID,
                                       vCPNAccount(vCPNCounter),
                                       vTargetElement(vRateCounter).ACS_CDA_ACCOUNT_ID,
                                       vTargetElement(vRateCounter).ACS_PF_ACCOUNT_ID,
                                       vTargetElement(vRateCounter).ACS_PJ_ACCOUNT_ID,
                                       vRateOriginAmount
                                       );
                    vCpnAmount := vCpnAmount  + vRateOriginAmount;
                  end loop;
                  vRateOriginAmount := vCpnAmount;
                end if;
              else
                GetRateTupleAmount(pDistributionId,
                                   vDetail.MGM_DISTRIBUTION_DETAIL_ID,
                                   vDetail.MGM_TRANSFER_UNIT_ID,
                                   vTargetElement(vRateCounter).ACS_CPN_ACCOUNT_ID,
                                   vTargetElement(vRateCounter).ACS_CDA_ACCOUNT_ID,
                                   vTargetElement(vRateCounter).ACS_PF_ACCOUNT_ID,
                                   vTargetElement(vRateCounter).ACS_PJ_ACCOUNT_ID,
                                   vRateOriginAmount
                                   );
              end if;

              /**
              *  R�cup�ration des condition et bornes de la position
              **/
              vCPNGroup := '';
              if vTargetElement(vRateCounter).MAU_CPN_CONDITION <> '' then
                vCPNGroup := vTargetElement(vRateCounter).MAU_CPN_CONDITION;
              elsif (vTargetElement(vRateCounter).ACS_CPN_ACCOUNT_ID + vTargetElement(vRateCounter).ACS_ACS_CPN_ACCOUNT_ID) <> 0.0 then
                vCPNGroup := GetCPNAccNumber(vTargetElement(vRateCounter).ACS_CPN_ACCOUNT_ID) || '  ---  ' ||
                             GetCPNAccNumber(vTargetElement(vRateCounter).ACS_ACS_CPN_ACCOUNT_ID);
              end if;
              vCurrentUnitId := vTargetElement(vRateCounter).TARGET_ID;
              vUpdate  := False;
            end if;

            /**
            * Cr�ation / mise � jour de la position
            **/
            vRateId := CreateRatePosition(pDistributionId,
                                          vDetail.MGM_TRANSFER_UNIT_ID,
                                          vDetail.MGM_USAGE_TYPE_ID,
                                          vTargetElement(vRateCounter).ACS_CDA_ACCOUNT_ID,
                                          vTargetElement(vRateCounter).ACS_PF_ACCOUNT_ID,
                                          vTargetElement(vRateCounter).ACS_PJ_ACCOUNT_ID,
                                          vRateOriginAmount,
                                          vTargetElement(vRateCounter).MUV_NUMBER,
                                          vCPNGroup,
                                          vUpdate,
                                          vRateId
                                           );
          end loop;
        end if;
      end if;
      fetch cDetails into  vDetail;
    end loop;
    close cDetails;
    /**
    * Calcul du taux pour chaque position
    **/
    update MGM_UNIT_RATE
    set MUR_RATE = MUR_AMOUNT / MUR_QUANTITY
    where MGM_DISTRIBUTION_ID  = pDistributionId;

  end GetDistributionRates;

  /**
  * Description: Constitution des sources / cibles des d�tails de r�partition
  **/
  procedure GetDetailOriginTarget(pDistributionDetId MGM_DISTRIBUTION_DETAIL.MGM_DISTRIBUTION_DETAIL_ID%type,
                                  pBudgetVersionId MGM_DISTRIBUTION.ACB_BUDGET_VERSION_ID%type
                                  )
  is
    /**
    * Curseur de recherche des �l�ments de r�partition li�s au d�tail
    **/
    cursor cOriginElements
    is
      select DIS.ACS_PERIOD_START_ID,
             DIS.ACS_PERIOD_END_ID,
             DIS.ACS_FINANCIAL_YEAR_ID,
             MTU.C_MGM_UNIT_EXPLOITATION,
             MTU.C_MGM_UNIT_ORIGIN,
             MTU.MGM_TRANSFER_UNIT_ID,
             MUT.MGM_USAGE_TYPE_ID,
             MDE.MGM_DISTRIBUTION_ELEMENT_ID,
             MDE.ACS_CPN_ORIGIN_FROM_ID,
             MDE.ACS_CPN_ORIGIN_TO_ID,
             MDE.ACS_CPN_IMP_ORIGIN_ID,
             MDE.ACS_CPN_IMP_TARGET_ID,
             MDE.ACS_CDA_ORIGIN_FROM_ID,
             MDE.ACS_CDA_ORIGIN_TO_ID,
             MDE.ACS_PF_ORIGIN_FROM_ID,
             MDE.ACS_PF_ORIGIN_TO_ID,
             MDE.ACS_PJ_ORIGIN_FROM_ID,
             MDE.ACS_PJ_ORIGIN_TO_ID,
             MDE.DOC_RECORD_FROM_ID,
             MDE.DOC_RECORD_TO_ID,
             MDE.MDE_CPN_ORIGIN_CONDITION,
             MDE.MDE_CDA_ORIGIN_CONDITION,
             MDE.MDE_PF_ORIGIN_CONDITION,
             MDE.MDE_PJ_ORIGIN_CONDITION,
             MDE.MDE_REC_ORIGIN_CONDITION,
             DET.MGM_DISTRIBUTION_ID
      from MGM_DISTRIBUTION_ELEMENT MDE,
           MGM_DISTRIBUTION_DETAIL DET,
           MGM_TRANSFER_UNIT MTU,
           MGM_DISTRIBUTION DIS,
           MGM_USAGE_TYPE MUT
      where DET.MGM_DISTRIBUTION_DETAIL_ID  = pDistributionDetId
        and MDE.MGM_DISTRIBUTION_ELEMENT_ID = DET.MGM_DISTRIBUTION_ELEMENT_ID
        and DIS.MGM_DISTRIBUTION_ID         = DET.MGM_DISTRIBUTION_ID
        and MUT.MGM_USAGE_TYPE_ID           = MDE.MGM_USAGE_TYPE_ID
        and MDE.MGM_RATE_USAGE_TYPE_ID is null
        and MTU.MGM_TRANSFER_UNIT_ID        = MUT.MGM_TRANSFER_UNIT_ID;


    vOriginElement   cOriginElements%rowtype;                                   --R�ceptionne les enregistrement du curseur
    vCPNCursorText   MGM_DISTRIBUTION_ELEMENT.MDE_CPN_ORIGIN_CONDITION%type;    --R�ceptionnent les commandes SQL de s�lection des comptes...
    vCDACursorText   MGM_DISTRIBUTION_ELEMENT.MDE_CDA_ORIGIN_CONDITION%type;    --...prises en compte.
    vPFCursorText    MGM_DISTRIBUTION_ELEMENT.MDE_PF_ORIGIN_CONDITION%type;
    vPJCursorText    MGM_DISTRIBUTION_ELEMENT.MDE_PJ_ORIGIN_CONDITION%type;
    vRecCursorText   MGM_DISTRIBUTION_ELEMENT.MDE_REC_ORIGIN_CONDITION%type;
    vCPNAccount      TAccountLimit;                                             --R�ceptionne les comptes CPN prises en compte
    vCDAAccount      TAccountLimit;                                             --R�ceptionne les comptes CDA prises en compte
    vPFAccount       TAccountLimit;                                             --R�ceptionne les comptes PF  prises en compte
    vPJAccount       TAccountLimit;                                             --R�ceptionne les comptes PJ  prises en compte
    vRecLimits       TAccountLimit;                                             --R�ceptionne les dossier pris en compte
    vCPNCounter      number;                                                    --Compteur de rows des tables temporaires
    vCDACounter      number;                                                    --Compteur de rows des tables temporaires
    vPFCounter       number;                                                    --Compteur de rows des tables temporaires
    vPJCounter       number;                                                    --Compteur de rows des tables temporaires
    vRecCounter      number;                                                    --Compteur de rows des tables temporaires
    vNumberTotal     number;                                                    --R�ceptionne la somme des nombres d'une unit� de mesure
    vSignCPN          number;                                                   --Indique la prise en compte de tous les cpn sans filtres
    vSignCDA          number;                                                   --Indique la prise en compte de tous les cda sans filtres
    vSignPF           number;                                                   --Indique la prise en compte de tous les pf sans filtres
    vSignPJ           number;                                                   --Indique la prise en compte de tous les pj sans filtres
    vSignRec          number;                                                   --Indique la prise en compte de tous les dossiers sans filtres
    vRateUsageTypeId MGM_DISTRIBUTION_ORIGIN.MGM_DISTRIBUTION_ORIGIN_ID%type;--R�ceptionne Id de la position source cr��e
  begin
    vCPNCounter    := 0;
    vCDACounter    := 0;
    vPFCounter     := 0;
    vPJCounter     := 0;
    vSignCPN       := 1;
    vSignCDA       := 1;
    vSignPF        := 1;
    vSignPJ        := 1;
    vSignRec       := 1;

    /**
    * Suppression des �ventuelles positions d�j� existantes
    **/
    delete from MGM_DISTRIBUTION_ORIGIN where MGM_DISTRIBUTION_DETAIL_ID = pDistributionDetId;
    /**
    * Parcours du curseur des �l�ments de r�partition du d�tail
    **/
    select  nvl(ELM.MGM_RATE_USAGE_TYPE_ID,0)
    into vRateUsageTypeId
     from  MGM_DISTRIBUTION_DETAIL DET
        , MGM_DISTRIBUTION_ELEMENT ELM
   where DET.MGM_DISTRIBUTION_DETAIL_ID = pDistributionDetId
   and DET.MGM_DISTRIBUTION_ELEMENT_ID = ELM.MGM_DISTRIBUTION_ELEMENT_ID;

   open cOriginElements;
    fetch cOriginElements into  vOriginElement;

    if cOriginElements%found then
      /**
      * Constitution de la commande SQL de recherche des comptes selon condition et/ ou bornes du domaine concern�
      **/
      vCPNCursorText := GetAccountCursor(vOriginElement.MDE_CPN_ORIGIN_CONDITION, vOriginElement.ACS_CPN_ORIGIN_FROM_ID,vOriginElement.ACS_CPN_ORIGIN_TO_ID,'CPN');
      vCDACursorText := GetAccountCursor(vOriginElement.MDE_CDA_ORIGIN_CONDITION, vOriginElement.ACS_CDA_ORIGIN_FROM_ID,vOriginElement.ACS_CDA_ORIGIN_TO_ID,'CDA');
      vPFCursorText  := GetAccountCursor(vOriginElement.MDE_PF_ORIGIN_CONDITION,  vOriginElement.ACS_PF_ORIGIN_FROM_ID ,vOriginElement.ACS_PF_ORIGIN_TO_ID ,'PF');
      vPJCursorText  := GetAccountCursor(vOriginElement.MDE_PJ_ORIGIN_CONDITION,  vOriginElement.ACS_PJ_ORIGIN_FROM_ID ,vOriginElement.ACS_PJ_ORIGIN_TO_ID ,'PJ');
      vRecCursorText := GetRecordCursor (vOriginElement.MDE_REC_ORIGIN_CONDITION, vOriginElement.DOC_RECORD_FROM_ID    ,vOriginElement.DOC_RECORD_TO_ID);

      /**
      *  Ouverture du curseur des comptes CPN
      *  Permet de contr�ler la validit� des param�tres et de ne faire le traitement que si des comptes CPN valides existent
      **/
      begin
        execute immediate vCPNCursorText bulk collect into vCPNAccount;--Contr�le validit�
        if (vOriginElement.MDE_CPN_ORIGIN_CONDITION is null ) and
           (vOriginElement.ACS_CPN_ORIGIN_FROM_ID   is null ) and
           (vOriginElement.ACS_CPN_ORIGIN_TO_ID     is null ) then
            vSignCPN := -1;
        end if;
      exception
        when others then
          raise_application_error(-20001, chr(13) ||PCS.PC_FUNCTIONS.TRANSLATEWORD('NO_VALID_CTYP_ORIGIN') ||  chr(13) || vCPNCursorText ||  chr(13) );
      end;

      if vCPNAccount.count <> 0 then                                            --Comptes CPN existent
        /**
        * Initialisation de la structure temporaire de r�ception des �l�ments cibles et leurs nombres
        * avec les types "R�partition"
        **/
        GetElementsRates(vOriginElement.MGM_DISTRIBUTION_ID,
                         vOriginElement.MGM_USAGE_TYPE_ID,
                         vOriginElement.C_MGM_UNIT_ORIGIN,
                         '1',
                         vOriginElement.ACS_PERIOD_START_ID,
                         vOriginElement.ACS_PERIOD_END_ID,
                         vOriginElement.ACS_FINANCIAL_YEAR_ID,
                         pBudgetVersionId,
                         vNumberTotal);

        /**
        *  Ouverture du curseur des comptes CDA
        **/
        if not vCDACursorText is null then
          begin
            if (vOriginElement.MDE_CDA_ORIGIN_CONDITION is null ) and
               (vOriginElement.ACS_CDA_ORIGIN_FROM_ID   is null ) and
               (vOriginElement.ACS_CDA_ORIGIN_TO_ID     is null ) then
              vSignCDA := -1;
            end if;
            execute immediate vCDACursorText bulk collect into vCDAAccount;
            if (vCDAAccount.Count = 0 ) then
              vCDAAccount(1) := 0;
            end if;
          exception
            when others then
              raise_application_error(-20001, chr(13) ||PCS.PC_FUNCTIONS.TRANSLATEWORD('NO_VALID_CCEN_ORIGIN') ||  chr(13) || vCDACursorText ||  chr(13));
          end;
        end if;
        /**
        *  Ouverture du curseur des comptes PF
        **/
        if not vPFCursorText is null then
          begin
            if (vOriginElement.MDE_PF_ORIGIN_CONDITION is null ) and
               (vOriginElement.ACS_PF_ORIGIN_FROM_ID   is null ) and
               (vOriginElement.ACS_PF_ORIGIN_TO_ID     is null ) then
              vSignPF := -1;
            end if;
            execute immediate vPFCursorText  bulk collect into vPFAccount;
            if (vPFAccount.Count = 0 ) then
              vPFAccount(1) := 0;
            end if;
          exception
            when others then
              raise_application_error(-20001, chr(13) ||PCS.PC_FUNCTIONS.TRANSLATEWORD('NO_VALID_COBJ_ORIGIN') ||  chr(13) || vPFCursorText ||  chr(13));
          end;
        end if;
        /**
        *  Ouverture du curseur des comptes PJ
        **/
        if not vPJCursorText is null then
          begin
            if (vOriginElement.MDE_PJ_ORIGIN_CONDITION is null ) and
               (vOriginElement.ACS_PJ_ORIGIN_FROM_ID   is null ) and
               (vOriginElement.ACS_PJ_ORIGIN_TO_ID     is null ) then
              vSignPJ := -1;
            end if;
            execute immediate vPJCursorText  bulk collect into vPJAccount;
            if (vPJAccount.Count = 0 ) then
              vPJAccount(1) := 0;
            end if;
          exception
            when others then
              raise_application_error(-20001, chr(13) ||PCS.PC_FUNCTIONS.TRANSLATEWORD('NO_VALID_PROJ_ORIGIN') ||  chr(13) || vPJCursorText ||  chr(13));
          end;
        end if;
        /**
        *  Ouverture du curseur des dossiers
        **/
        if not vRECCursorText is null then
          begin
            if (vOriginElement.MDE_REC_ORIGIN_CONDITION is null) and
               (vOriginElement.DOC_RECORD_FROM_ID       is null) and
               (vOriginElement.DOC_RECORD_TO_ID         is null) then
              vSignREC := -1;
            end if;
            execute immediate vRECCursorText  bulk collect into vRecLimits;
            if (vRecLimits.Count = 0 ) then
              vRecLimits(1) := 0;
            end if;
          exception
            when others then
              raise_application_error(-20001, chr(13) ||PCS.PC_FUNCTIONS.TRANSLATEWORD('NO_VALID_REC_ORIGIN') ||  chr(13) || vRECCursorText ||  chr(13));
          end;
        end if;

        /**
        * Parcours s�quentiel de chaque curseur de compte pour former les tuples de r�partition
        * sources. Toutes les combinaisons sont list�es sans tenir compte des restrictions "m�tier".
        * Et pour chaque tuple source r�partition du montant et cr�ation des enregistrements cibles
        *
        *
        * sign() = 1  commande SQL / bornes existent
        * sign() = -1 commande SQL / bornes non existantes => select *
        * sign() = 0  commande SQL / bornes retournent null
        */
        for vCPNCounter in vCPNAccount.first .. vCPNAccount.last
        loop
          if (vSignCDA = 1) then
            for vCDACounter in vCDAAccount.first .. vCDAAccount.last
            loop
              if (vSignPF = 1) then
                for vPFCounter in vPFAccount.first .. vPFAccount.last
                loop
                  if (vSignPJ = 1) then
                    for vPJCounter in vPJAccount.first .. vPJAccount.last
                    loop
                      if (vSignREC = 1)  then
                        for vRECCounter in vRECLimits.first .. vRECLimits.last
                        loop
                          /**
                          * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, PJ,REC)
                          **/
                          DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                           pDistributionDetId,                        --D�tail parent
                                           vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                           vSignCDA * vCDAAccount(vCDACounter),       --Compte CDA
                                           vSignPF  * vPFAccount(vPFCounter),         --Comte PF
                                           vSignPJ  * vPJAccount(vPJCounter),         --Comte PJ
                                           vSignREC * vRECLimits(vRECCounter),        --Dossier
                                           null,                                      --Quantit�
                                           vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                           nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                           vNumberTotal                               --Nombre unit� de mesure
                                           );
                        end loop;
                      else
                        /**
                        * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, PJ)
                        **/
                        DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                         pDistributionDetId,                        --D�tail parent
                                         vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                         vSignCDA * vCDAAccount(vCDACounter),       --Compte CDA
                                         vSignPF  * vPFAccount(vPFCounter),         --Comte PF
                                         vSignPJ  * vPJAccount(vPJCounter),         --Comte PJ
                                         null,                                      --Dossier
                                         null,                                      --Quantit�
                                         vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                         nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                         vNumberTotal                               --Nombre unit� de mesure
                                         );
                      end if;
                    end loop;
                  else
                    if (vSignREC = 1)  then
                      for vRECCounter in vRECLimits.first .. vRECLimits.last
                      loop
                        /**
                        * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, REC)
                        **/
                        DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                         pDistributionDetId,                        --D�tail parent
                                         vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                         vSignCDA * vCDAAccount(vCDACounter),       --Compte CDA
                                         vSignPF  * vPFAccount(vPFCounter),         --Comte PF
                                         null,                                      --Comte PJ
                                         vSignREC * vRECLimits(vRECCounter),        --Dossier
                                         null,                                      --Quantit�
                                         vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                         nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                         vNumberTotal                               --Nombre unit� de mesure
                                         );
                      end loop;
                    else
                      /**
                      * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF)
                      **/
                      DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                       pDistributionDetId,                        --D�tail parent
                                       vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                       vSignCDA * vCDAAccount(vCDACounter),       --Compte CDA
                                       vSignPF  * vPFAccount(vPFCounter),         --Comte PF
                                       null,                                      --Comte PJ
                                       null,                                      --Dossier
                                       null,                                      --Quantit�
                                       vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                       nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                       vNumberTotal                               --Nombre unit� de mesure
                                       );
                    end if;
                  end if;
                end loop;
              else
               if (vSignPJ = 1) then
                  for vPJCounter in vPJAccount.first .. vPJAccount.last
                  loop
                    if (vSignREC = 1)  then
                      for vRECCounter in vRECLimits.first .. vRECLimits.last
                      loop
                        /**
                        * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, PJ,REC)
                        **/
                        DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                         pDistributionDetId,                        --D�tail parent
                                         vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                         vSignCDA * vCDAAccount(vCDACounter),       --Compte CDA
                                         null,                                      --Comte PF
                                         vSignPJ  * vPJAccount(vPJCounter),         --Comte PJ
                                         vSignREC * vRECLimits(vRECCounter),        --Dossier
                                         null,                                      --Quantit�
                                         vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                         nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                         vNumberTotal                               --Nombre unit� de mesure
                                         );
                      end loop;
                    else
                      /**
                      * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, PJ)
                      **/
                      DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                       pDistributionDetId,                        --D�tail parent
                                       vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                       vSignCDA * vCDAAccount(vCDACounter),       --Compte CDA
                                       null,                                      --Comte PF
                                       vSignPJ  * vPJAccount(vPJCounter),         --Comte PJ
                                       null,                                      --Dossier
                                       null,                                      --Quantit�
                                       vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                       nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                       vNumberTotal                               --Nombre unit� de mesure
                                       );
                    end if;
                  end loop;
                else
                  if (vSignREC = 1)  then
                    for vRECCounter in vRECLimits.first .. vRECLimits.last
                    loop
                      /**
                      * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, REC)
                      **/
                      DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                       pDistributionDetId,                        --D�tail parent
                                       vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                       vSignCDA * vCDAAccount(vCDACounter),       --Compte CDA
                                       null,                                      --Comte PF
                                       null,                                      --Comte PJ
                                       vSignREC * vRECLimits(vRECCounter),        --Dossier
                                       null,                                      --Quantit�
                                       vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                       nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                       vNumberTotal                               --Nombre unit� de mesure
                                       );
                    end loop;
                  else
                    /**
                    * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF)
                    **/
                    DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                     pDistributionDetId,                        --D�tail parent
                                     vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                     vSignCDA * vCDAAccount(vCDACounter),       --Compte CDA
                                     null,                                     --Comte PF
                                     null,                                      --Comte PJ
                                     null,                                      --Dossier
                                     null,                                      --Quantit�
                                     vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                     nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                     vNumberTotal                               --Nombre unit� de mesure
                                     );
                  end if;
                end if;
              end if;
            end loop;
          else
            if (vSignPF = 1) then
              for vPFCounter in vPFAccount.first .. vPFAccount.last
              loop
                if (vSignPJ = 1) then
                  for vPJCounter in vPJAccount.first .. vPJAccount.last
                  loop
                    if (vSignREC = 1)  then
                      for vRECCounter in vRECLimits.first .. vRECLimits.last
                      loop
                        /**
                        * R�ception des montant de r�partition pour les diff�rents tuples (CPN, PF, PJ,REC)
                        **/
                        DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                         pDistributionDetId,                        --D�tail parent
                                         vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                         null,                                       --Compte CDA
                                         vSignPF  * vPFAccount(vPFCounter),         --Comte PF
                                         vSignPJ  * vPJAccount(vPJCounter),         --Comte PJ
                                         vSignREC * vRECLimits(vRECCounter),        --Dossier
                                         null,                                      --Quantit�
                                         vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                         nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                         vNumberTotal                               --Nombre unit� de mesure
                                         );
                      end loop;
                    else
                      /**
                      * R�ception des montant de r�partition pour les diff�rents tuples (CPN,  PF, PJ)
                      **/
                      DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                       pDistributionDetId,                        --D�tail parent
                                       vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                       null,       --Compte CDA
                                       vSignPF  * vPFAccount(vPFCounter),         --Comte PF
                                       vSignPJ  * vPJAccount(vPJCounter),         --Comte PJ
                                       null,                                      --Dossier
                                       null,                                      --Quantit�
                                       vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                       nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                       vNumberTotal                               --Nombre unit� de mesure
                                       );
                    end if;
                  end loop;
                else
                  if (vSignREC = 1)  then
                    for vRECCounter in vRECLimits.first .. vRECLimits.last
                    loop
                      /**
                      * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, REC)
                      **/
                      DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                       pDistributionDetId,                        --D�tail parent
                                       vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                       null,                                      --Compte CDA
                                       vSignPF  * vPFAccount(vPFCounter),         --Comte PF
                                       null,                                      --Comte PJ
                                       vSignREC * vRECLimits(vRECCounter),        --Dossier
                                       null,                                      --Quantit�
                                       vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                       nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                       vNumberTotal                               --Nombre unit� de mesure
                                       );
                    end loop;
                  else
                    /**
                    * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF)
                    **/
                    DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                     pDistributionDetId,                        --D�tail parent
                                     vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                     null,                                      --Compte CDA
                                     vSignPF  * vPFAccount(vPFCounter),         --Comte PF
                                     null,                                      --Comte PJ
                                     null,                                      --Dossier
                                     null,                                      --Quantit�
                                     vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                     nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                     vNumberTotal                               --Nombre unit� de mesure
                                     );
                  end if;
                end if;
              end loop;
            else
             if (vSignPJ = 1) then
                for vPJCounter in vPJAccount.first .. vPJAccount.last
                loop
                  if (vSignREC = 1)  then
                    for vRECCounter in vRECLimits.first .. vRECLimits.last
                    loop
                      /**
                      * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, PJ,REC)
                      **/
                      DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                       pDistributionDetId,                        --D�tail parent
                                       vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                       null,                                      --Compte CDA
                                       null,                                      --Comte PF
                                       vSignPJ  * vPJAccount(vPJCounter),         --Comte PJ
                                       vSignREC * vRECLimits(vRECCounter),        --Dossier
                                       null,                                      --Quantit�
                                       vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                       nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                       vNumberTotal                               --Nombre unit� de mesure
                                       );
                    end loop;
                  else
                    /**
                    * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, PJ)
                    **/
                    DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                     pDistributionDetId,                        --D�tail parent
                                     vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                     null,                                      --Compte CDA
                                     null,                                      --Comte PF
                                     vSignPJ  * vPJAccount(vPJCounter),         --Comte PJ
                                     null,                                      --Dossier
                                     null,                                      --Quantit�
                                     vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                     nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                     vNumberTotal                               --Nombre unit� de mesure
                                     );
                  end if;
                end loop;
              else
                if (vSignREC = 1)  then
                  for vRECCounter in vRECLimits.first .. vRECLimits.last
                  loop
                    /**
                    * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF, REC)
                    **/
                    DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                     pDistributionDetId,                        --D�tail parent
                                     vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                     null,                                      --Compte CDA
                                     null,                                      --Comte PF
                                     null,                                      --Comte PJ
                                     vSignREC * vRECLimits(vRECCounter),        --Dossier
                                     null,                                      --Quantit�
                                     vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                     nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                     vNumberTotal                               --Nombre unit� de mesure
                                     );
                  end loop;
                else
                  /**
                  * R�ception des montant de r�partition pour les diff�rents tuples (CPN, CDA, PF)
                  **/
                  DivideOutAccount(vOriginElement.MGM_DISTRIBUTION_ID,        --Distribution parente
                                   pDistributionDetId,                        --D�tail parent
                                   vSignCPN * vCPNAccount(vCPNCounter),       --Compte CPN
                                   null,                                      --Compte CDA
                                   null,                                     --Comte PF
                                   null,                                      --Comte PJ
                                   null,                                      --Dossier
                                   null,                                      --Quantit�
                                   vOriginElement.ACS_CPN_IMP_ORIGIN_ID,      --Cpn source Imputation
                                   nvl(vOriginElement.ACS_CPN_IMP_TARGET_ID, vCPNAccount(vCPNCounter)), --Cpn cible imputation
                                   vNumberTotal                               --Nombre unit� de mesure
                                   );
                end if;
              end if;
            end if;
          end if;
        end loop;
      end if;
    end if;
    close cOriginElements;
  end GetDetailOriginTarget;


  /**
  * Description: Cr�ation des positions source et cible des d�tails de r�partition
  **/
  procedure DivideOutAccount(pDistributionId    MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                             pDistributionDetId MGM_DISTRIBUTION_DETAIL.MGM_DISTRIBUTION_DETAIL_ID%type,
                             pSourceCPNAccId    MGM_DISTRIBUTION_BALANCE.ACS_CPN_ACCOUNT_ID%type,
                             pSourceCDAAccId    MGM_DISTRIBUTION_BALANCE.ACS_CDA_ACCOUNT_ID%type,
                             pSourcePFAccId     MGM_DISTRIBUTION_BALANCE.ACS_PF_ACCOUNT_ID%type,
                             pSourcePJAccId     MGM_DISTRIBUTION_BALANCE.ACS_PJ_ACCOUNT_ID%type,
                             pSourceRecordId    MGM_DISTRIBUTION_ELEMENT.DOC_RECORD_FROM_ID%type,
                             pSourceQTYAccId    MGM_DISTRIBUTION_BALANCE.ACS_QTY_UNIT_ID%type,
                             pImpSourceCpnId    MGM_DISTRIBUTION_ELEMENT.ACS_CPN_IMP_ORIGIN_ID%type,
                             pImpTargetCpnId    MGM_DISTRIBUTION_ELEMENT.ACS_CPN_IMP_TARGET_ID%type,
                             pNumberTotal       number
                             )
  is
    cursor DistributionAmountCursor
    is
      select nvl(BAL.MDB_AMOUNT_D,0) AMOUNT_D, nvl(BAL.MDB_AMOUNT_C,0) AMOUNT_C,
             BAL.ACS_CPN_ACCOUNT_ID , BAL.ACS_CDA_ACCOUNT_ID , BAL.ACS_PF_ACCOUNT_ID , BAL.ACS_PJ_ACCOUNT_ID,
             BAL.DOC_RECORD_ID
      from  MGM_DISTRIBUTION_BALANCE BAL, MGM_DISTRIBUTION DIS
      where DIS.MGM_DISTRIBUTION_ID = pDistributionId
        and BAL.MGM_DISTRIBUTION_ID = DIS.MGM_DISTRIBUTION_ID
        and ((pSourceCPNAccId is null) or
             ((sign(pSourceCPNAccId) = -1) and (BAL.ACS_CPN_ACCOUNT_ID = abs(pSourceCPNAccId))) or
             ((sign(pSourceCPNAccId) = 1)  and (BAL.ACS_CPN_ACCOUNT_ID = pSourceCPNAccId )) or
             ((sign(pSourceCPNAccId) = 0)  and (BAL.ACS_CPN_ACCOUNT_ID is null ))
            )
        and ((pSourceCDAAccId is null) or
             ((sign(pSourceCDAAccId) = -1) and (BAL.ACS_CDA_ACCOUNT_ID = abs(pSourceCDAAccId) )) or
             ((sign(pSourceCDAAccId) = 1)  and (BAL.ACS_CDA_ACCOUNT_ID = pSourceCDAAccId )) or
             ((sign(pSourceCDAAccId) = 0)  and (BAL.ACS_CDA_ACCOUNT_ID is null ))
            )
        and ((pSourcePFAccId is null) or
             ((sign(pSourcePFAccId) = -1) and (BAL.ACS_PF_ACCOUNT_ID = abs(pSourcePFAccId))) or
             ((sign(pSourcePFAccId) = 1)  and (BAL.ACS_PF_ACCOUNT_ID = pSourcePFAccId )) or
             ((sign(pSourcePFAccId) = 0)  and (BAL.ACS_PF_ACCOUNT_ID is null ))
            )
        and ((pSourcePJAccId is null) or
             ((sign(pSourcePJAccId) = -1) and (BAL.ACS_PJ_ACCOUNT_ID = abs(pSourcePJAccId))) or
             ((sign(pSourcePJAccId) = 1)  and (BAL.ACS_PJ_ACCOUNT_ID = pSourcePJAccId )) or
             ((sign(pSourcePJAccId) = 0)  and (BAL.ACS_PJ_ACCOUNT_ID is null ))
            )
        and ((pSourceRecordId is null) or
             ((sign(pSourceRecordId) = -1) and (BAL.DOC_RECORD_ID = abs(pSourceRecordId) )) or
             ((sign(pSourceRecordId) = 1)  and (BAL.DOC_RECORD_ID = pSourceRecordId )) or
             ((sign(pSourceRecordId) = 0)  and (BAL.DOC_RECORD_ID is null ))
            )
      union all
      select nvl(MDO.MDO_AMOUNT_D,0) , nvl(MDO.MDO_AMOUNT_C,0) ,
             MDO.ACS_CPN_ACCOUNT_ID, MDO.ACS_CDA_ACCOUNT_ID, MDO.ACS_PF_ACCOUNT_ID,
             NULL, NULL
      from  MGM_DISTRIBUTION_ORIGIN MDO,
            MGM_DISTRIBUTION_DETAIL MDD,
            MGM_DISTRIBUTION_ELEMENT ELM,
            MGM_DISTRIBUTION DIS
      where DIS.MGM_DISTRIBUTION_ID = pDistributionId
        and MDD.MGM_DISTRIBUTION_ID = DIS.MGM_DISTRIBUTION_ID
        and MDO.MGM_DISTRIBUTION_DETAIL_ID = MDD.MGM_DISTRIBUTION_DETAIL_ID
        and MDD.MGM_DISTRIBUTION_ELEMENT_ID = ELM.MGM_DISTRIBUTION_ELEMENT_ID
        and ELM.MGM_RATE_USAGE_TYPE_ID IS NULL
        and ((pSourceCPNAccId is null) or
             ((sign(pSourceCPNAccId) = -1) and (MDO.ACS_CPN_ACCOUNT_ID = abs(pSourceCPNAccId))) or
             ((sign(pSourceCPNAccId) = 1)  and (MDO.ACS_CPN_ACCOUNT_ID = pSourceCPNAccId )) or
             ((sign(pSourceCPNAccId) = 0)  and (MDO.ACS_CPN_ACCOUNT_ID is null ))
            )
        and ((pSourceCDAAccId is null) or
             ((sign(pSourceCDAAccId) = -1) and (MDO.ACS_CDA_ACCOUNT_ID = abs(pSourceCDAAccId) )) or
             ((sign(pSourceCDAAccId) = 1)  and (MDO.ACS_CDA_ACCOUNT_ID = pSourceCDAAccId )) or
             ((sign(pSourceCDAAccId) = 0)  and (MDO.ACS_CDA_ACCOUNT_ID is null ))
            )
        and ((pSourcePFAccId is null) or
             ((sign(pSourcePFAccId) = -1) and (MDO.ACS_PF_ACCOUNT_ID = abs(pSourcePFAccId))) or
             ((sign(pSourcePFAccId) = 1)  and (MDO.ACS_PF_ACCOUNT_ID = pSourcePFAccId )) or
             ((sign(pSourcePFAccId) = 0)  and (MDO.ACS_PF_ACCOUNT_ID is null ))
            )
      union all
      select nvl(MDT.MDT_AMOUNT_D,0) , nvl(MDT.MDT_AMOUNT_C,0) ,
             MDT.ACS_CPN_ACCOUNT_ID , MDT.ACS_CDA_ACCOUNT_ID , MDT.ACS_PF_ACCOUNT_ID ,
             MDT.ACS_PJ_ACCOUNT_ID  , NULL
      from  MGM_DISTRIBUTION_TARGET MDT,
            MGM_DISTRIBUTION_ORIGIN MDO,
            MGM_DISTRIBUTION_DETAIL MDD,
            MGM_DISTRIBUTION_ELEMENT ELM,
            MGM_DISTRIBUTION DIS
      where DIS.MGM_DISTRIBUTION_ID = pDistributionId
        and MDD.MGM_DISTRIBUTION_ID = DIS.MGM_DISTRIBUTION_ID
        and MDO.MGM_DISTRIBUTION_DETAIL_ID = MDD.MGM_DISTRIBUTION_DETAIL_ID
        and MDT.MGM_DISTRIBUTION_ORIGIN_ID = MDO.MGM_DISTRIBUTION_ORIGIN_ID
        and MDD.MGM_DISTRIBUTION_ELEMENT_ID = ELM.MGM_DISTRIBUTION_ELEMENT_ID
        and ELM.MGM_RATE_USAGE_TYPE_ID IS NULL
        and ((pSourceCPNAccId is null) or
             ((sign(pSourceCPNAccId) = -1) and (MDT.ACS_CPN_ACCOUNT_ID = abs(pSourceCPNAccId))) or
             ((sign(pSourceCPNAccId) = 1)  and (MDT.ACS_CPN_ACCOUNT_ID = pSourceCPNAccId )) or
             ((sign(pSourceCPNAccId) = 0)  and (MDT.ACS_CPN_ACCOUNT_ID is null ))
            )
        and ((pSourceCDAAccId is null) or
             ((sign(pSourceCDAAccId) = -1) and (MDT.ACS_CDA_ACCOUNT_ID = abs(pSourceCDAAccId))) or
             ((sign(pSourceCDAAccId) = 1)  and (MDT.ACS_CDA_ACCOUNT_ID = pSourceCDAAccId )) or
             ((sign(pSourceCDAAccId) = 0)  and (MDT.ACS_CDA_ACCOUNT_ID is null ))
            )
        and ((pSourcePFAccId is null) or
             ((sign(pSourcePFAccId) = -1) and (MDT.ACS_PF_ACCOUNT_ID = abs(pSourcePFAccId))) or
             ((sign(pSourcePFAccId) = 1)  and (MDT.ACS_PF_ACCOUNT_ID = pSourcePFAccId )) or
             ((sign(pSourcePFAccId) = 0)  and (MDT.ACS_PF_ACCOUNT_ID is null ))
            )
        and ((pSourcePJAccId is null) or
             ((sign(pSourcePJAccId) = -1) and (MDT.ACS_PJ_ACCOUNT_ID = abs(pSourcePJAccId))) or
             ((sign(pSourcePJAccId) = 1)  and (MDT.ACS_PJ_ACCOUNT_ID = pSourcePJAccId )) or
             ((sign(pSourcePJAccId) = 0)  and (MDT.ACS_PJ_ACCOUNT_ID is null ))
            );
    vTargetCounter   number;                                                 --Compteur de rows de la table cible
    vTargetAmountD   MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type;             --R�ceptionne le montant source d�bit
    vTargetAmountC   MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_C%type;             --R�ceptionne le montant source cr�dit
    vSumDistAmountD  MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type;             --R�ceptionne la somme des montants d�bit r�partis
    vSumDistAmountC  MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_C%type;             --R�ceptionne la somme des montants cr�dit r�partis
    vDetSourceId     MGM_DISTRIBUTION_ORIGIN.MGM_DISTRIBUTION_ORIGIN_ID%type;--R�ceptionne Id de la position source cr��e
    vRateUsageTypeId MGM_DISTRIBUTION_ORIGIN.MGM_DISTRIBUTION_ORIGIN_ID%type;--R�ceptionne Id de la position source cr��e
    vDetTargetId     MGM_DISTRIBUTION_TARGET.MGM_DISTRIBUTION_TARGET_ID%type;--R�ceptionne Id de la position cible cr��e
    vDistributionElement DistributionAmountCursor%rowtype;
  begin
    vTargetCounter := 0;

    select  nvl(ELM.MGM_RATE_USAGE_TYPE_ID,0)
    into vRateUsageTypeId
  from  MGM_DISTRIBUTION_DETAIL DET
        , MGM_DISTRIBUTION_ELEMENT ELM
 where DET.MGM_DISTRIBUTION_DETAIL_ID = pDistributionDetId
   and DET.MGM_DISTRIBUTION_ELEMENT_ID = ELM.MGM_DISTRIBUTION_ELEMENT_ID;


    open DistributionAmountCursor;
    fetch DistributionAmountCursor into vDistributionElement;
    while DistributionAmountCursor%found
    loop
       /**
        * Cr�ation de la position source pour CPN, CDA, PF
        **/



        if vRateUsageTypeId = 0 then
        vDetSourceId := CreateSourcePosition(pDistributionDetId,          --D�tail parent
                                             vDistributionElement.ACS_CPN_ACCOUNT_ID,    --Compte CPN
                                             vDistributionElement.ACS_CDA_ACCOUNT_ID,    --Compte CDA
                                             vDistributionElement.ACS_PF_ACCOUNT_ID,     --Compte PF
                                             nvl(pImpSourceCpnId, vDistributionElement.ACS_CPN_ACCOUNT_ID),--Compte CPN Imputation
                                             vDistributionElement.AMOUNT_C,              --Montant d�bit / Cr�dit
                                             vDistributionElement.AMOUNT_D);             -- !!! Inversion !!!
        else /* taux type 2, ce n'est pas une r�partition les sources sont calcul�es et cr��es pour le calcul des taux*/
        vDetSourceId := CreateSourcePosition(pDistributionDetId,          --D�tail parent
                                             vDistributionElement.ACS_CPN_ACCOUNT_ID,    --Compte CPN
                                             vDistributionElement.ACS_CDA_ACCOUNT_ID,    --Compte CDA
                                             vDistributionElement.ACS_PF_ACCOUNT_ID,     --Compte PF
                                             nvl(pImpSourceCpnId, vDistributionElement.ACS_CPN_ACCOUNT_ID),--Compte CPN Imputation
                                             vDistributionElement.AMOUNT_D,
                                             vDistributionElement.AMOUNT_C);
                                             end if;


         /**
         * Uniquement pour les �l�ments de r�partition...les taux (type 2) ne sont pas pris en compte
         **/
        if vRateUsageTypeId = 0 then
        /**
        * Pour chaque source cr�ation des positions cibles selon la structure de r�ception des cibles
        **/
        if (not vDetSourceId is null) and  (vTargetElement.Count <> 0) then
          vSumDistAmountD := 0.0;
          vSumDistAmountC := 0.0;

          for vTargetCounter in vTargetElement.First ..vTargetElement.last
          loop
            if pNumberTotal <> 0 then
              vTargetAmountD  := vDistributionElement.AMOUNT_D  * vTargetElement(vTargetCounter).MUV_NUMBER / pNumberTotal;
              vTargetAmountC  := vDistributionElement.AMOUNT_C  * vTargetElement(vTargetCounter).MUV_NUMBER / pNumberTotal;
            end if;

            vSumDistAmountD := vSumDistAmountD + vTargetAmountD;
            vSumDistAmountC := vSumDistAmountC + vTargetAmountC;

            if vTargetCounter = vTargetElement.last then
              vTargetAmountD  := vTargetAmountD + vDistributionElement.AMOUNT_D - vSumDistAmountD;
              vTargetAmountC  := vTargetAmountC + vDistributionElement.AMOUNT_C - vSumDistAmountC;
            end if;

            vDetTargetId := CreateTargetPosition(vDetSourceId,                                      --Id source parente
                                                 pImpTargetCpnId,                                   --Compte CPN
                                                 vTargetElement(vTargetCounter).ACS_CDA_ACCOUNT_ID, --Compte CDA
                                                 vTargetElement(vTargetCounter).ACS_PF_ACCOUNT_ID,  --Compte PF
                                                 vTargetElement(vTargetCounter).ACS_PJ_ACCOUNT_ID,  --Compte PJ
                                                 vTargetAmountD,                                    --Montant D�bit
                                                 vTargetAmountC);                                   --Montant cr�dit




          end loop;
        end if;
        end if;
      fetch DistributionAmountCursor into vDistributionElement;
    end loop;
    close DistributionAmountCursor;
  end DivideOutAccount;

  /**
  * Description: Constitution de la commande SQL de recherche des comptes
  *              selon la condition et/ ou les bornes de... � .... pass� en param�tre
  **/
  function GetAccountCursor(pCondition  MGM_DISTRIBUTION_ELEMENT.MDE_CPN_ORIGIN_CONDITION%type,
                            pLowerLimit MGM_DISTRIBUTION_ELEMENT.ACS_CPN_ORIGIN_FROM_ID%type,
                            pUpperLimit MGM_DISTRIBUTION_ELEMENT.ACS_CPN_ORIGIN_FROM_ID%type,
                            pSubSet     varchar2)
    return MGM_DISTRIBUTION_ELEMENT.MDE_CPN_ORIGIN_CONDITION%type

  is
    vResult           MGM_DISTRIBUTION_ELEMENT.MDE_CPN_ORIGIN_CONDITION%type;
    vReferenceFld     PCS.PC_FLDSC.FLDNAME%type;
    vLowerAccountId   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vUpperAccountId   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;

    procedure GetLimitAccountId(pReferenceFld   PCS.PC_FLDSC.FLDNAME%type,
                                pLowerAccountId in out  ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                                pUpperAccountId in out  ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
    is
      vSQLText       MGM_DISTRIBUTION_ELEMENT.MDE_CPN_ORIGIN_CONDITION%type; --R�ceptionne la commande SQL construite dynamiquement
      vSQLTextLower  MGM_DISTRIBUTION_ELEMENT.MDE_CPN_ORIGIN_CONDITION%type; --R�ceptionne la commande SQL de la borne inf�rieure
      vSQLTextUpper  MGM_DISTRIBUTION_ELEMENT.MDE_CPN_ORIGIN_CONDITION%type; --R�ceptionne la commande SQL de la borne sup�rieure
      vAccountLimit  TAccountLimit;                                          --Variable de type de r�ception de compte
      vCounter       number(1);
    begin
      /**
      *Construction de la commande SQL selon param�tre
      **/
      vSQLText := 'select REF.[REFERENCEFLD]_ID  ' || chr(13) ||
                  'from [REFERENCEFLD] REF,  ' || chr(13) ||
                  '     ACS_ACCOUNT    ACC   ' || chr(13) ||
                  'where REF.[REFERENCEFLD]_ID= ACC.ACS_ACCOUNT_ID'     || chr(13) ||
                  'order by ACC.ACC_NUMBER ';

      /**
      *Remplacement de la macro par le domaine concern�
      **/
      vSQLText := replace(vSQLText, '[REFERENCEFLD]', pReferenceFld );

      /**
      *Le compte de... n'est pas d�fini -> recherche du compte ayant le n� la + petite
      **/
      if pLowerAccountId is null then
        vSQLTextLower := vSQLText || 'asc';
        /**
        *Ex�cution de la commande et r�cpetion dans la structure d�fini
        **/
        execute immediate vSQLTextLower bulk collect into vAccountLimit;
        vCounter := vAccountLimit.First;
        pLowerAccountId := vAccountLimit(vCounter);
      end if;

      /**
      *Le compte �... n'est pas d�fini -> recherche du compte ayant le n� la + grande
      **/
      if pUpperAccountId is null then
        vSQLTextUpper := vSQLText || 'desc';
        /**
        *Ex�cution de la commande et r�cpetion dans la structure d�fini
        **/
        execute immediate vSQLTextUpper bulk collect into vAccountLimit;
        vCounter := vAccountLimit.First;
        pUpperAccountId := vAccountLimit(vCounter);
      end if;
    end GetLimitAccountId;

  begin
    /**
    * D�finition des champs selon le sous-ensemble
    **/
    if upper(pSubSet)    = 'CPN' then   vReferenceFld := 'ACS_CPN_ACCOUNT';
    elsif upper(pSubSet) = 'CDA' then   vReferenceFld := 'ACS_CDA_ACCOUNT';
    elsif upper(pSubSet) = 'PF'  then   vReferenceFld := 'ACS_PF_ACCOUNT';
    elsif upper(pSubSet) = 'PJ'  then   vReferenceFld := 'ACS_PJ_ACCOUNT';
    end if;
    if not pCondition is null then                                              /** La condition SQL prime sur les bornes **/
      vResult := 'select REF.[REFERENCEFLD]_ID     ' || chr(13) ||              /** La condition doit comporter l'id de la table sp�cifi�e **/
                 'from ( ' || pCondition || ' ) REF' || chr(13) ||
                 '    ,ACS_ACCOUNT    ACC          ' || chr(13) ||
                 'where REF.[REFERENCEFLD]_ID= ACC.ACS_ACCOUNT_ID'|| chr(13) ||
                 'order by ACC.ACC_NUMBER';

    elsif (not pLowerLimit is null) or (not pUpperLimit is null)   then         /** Au moins une limite est renseign�e .. Recherche de l'autre borne **/
        vLowerAccountId := pLowerLimit;
        vUpperAccountId := pUpperLimit;
        /**
        * R�ception dans les variables vide des min / max des comptes.
        **/
        GetLimitAccountId(vReferenceFld, vLowerAccountId,vUpperAccountId);
        /**
        *Cr�ation de la commande SQL selon bornes d�finies
        */
        vResult := 'select REF.[REFERENCEFLD]_ID ' || chr(13) ||
                   'from [REFERENCEFLD] REF,     ' || chr(13) ||
                   '     ACS_ACCOUNT    ACC,     ' || chr(13) ||
                   '     ACS_ACCOUNT    ACC_F,   ' || chr(13) ||
                   '     ACS_ACCOUNT    ACC_T    ' || chr(13) ||
                   'where ACC_F.ACS_ACCOUNT_ID = ' || vLowerAccountId  || chr(13) ||
                   '  and ACC_T.ACS_ACCOUNT_ID = ' || vUpperAccountId  || chr(13) ||
                   '  and ACC.ACC_NUMBER      >= ACC_F.ACC_NUMBER'       || chr(13) ||
                   '  and ACC.ACC_NUMBER      <= ACC_T.ACC_NUMBER'       || chr(13) ||
                   '  and REF.[REFERENCEFLD]_ID= ACC.ACS_ACCOUNT_ID'     || chr(13) ||
                   'order by ACC.ACC_NUMBER';

    else                                                                        /** Cr�ation de la commande SQL g�n�rale **/
      vResult := 'select REF.[REFERENCEFLD]_ID ' || chr(13) ||
                 'from [REFERENCEFLD] REF,     ' || chr(13) ||
                 '     ACS_ACCOUNT    ACC      ' || chr(13) ||
                 'where ACC.ACS_ACCOUNT_ID = [REFERENCEFLD]_ID'    || chr(13) ||
                 'order by ACC.ACC_NUMBER';

    end if;

    vResult := replace(vResult, '[REFERENCEFLD]', vReferenceFld );
    return vResult;
  end GetAccountCursor;

  /**
  * Description: Constitution de la commande SQL de recherche des dossiers
  *              selon la condition et/ ou les bornes de... � .... pass� en param�tre
  **/
  function GetRecordCursor(pCondition  MGM_DISTRIBUTION_ELEMENT.MDE_REC_ORIGIN_CONDITION%type,
                           pLowerLimit MGM_DISTRIBUTION_ELEMENT.DOC_RECORD_FROM_ID%type,
                           pUpperLimit MGM_DISTRIBUTION_ELEMENT.DOC_RECORD_TO_ID%type
                           )
    return MGM_DISTRIBUTION_ELEMENT.MDE_CPN_ORIGIN_CONDITION%type

  is
    vResult           MGM_DISTRIBUTION_ELEMENT.MDE_REC_ORIGIN_CONDITION%type;
    vLowerRecordId    DOC_RECORD.DOC_RECORD_ID%type;
    vUpperRecordId    DOC_RECORD.DOC_RECORD_ID%type;

    procedure GetLimitRecordId(pLowerRecordId  in out  DOC_RECORD.DOC_RECORD_ID%type,
                               pUpperRecordId  in out  DOC_RECORD.DOC_RECORD_ID%type)
    is
      vSQLText       MGM_DISTRIBUTION_ELEMENT.MDE_REC_ORIGIN_CONDITION%type; --R�ceptionne la commande SQL construite dynamiquement
      vSQLTextLower  MGM_DISTRIBUTION_ELEMENT.MDE_REC_ORIGIN_CONDITION%type; --R�ceptionne la commande SQL de la borne inf�rieure
      vSQLTextUpper  MGM_DISTRIBUTION_ELEMENT.MDE_REC_ORIGIN_CONDITION%type; --R�ceptionne la commande SQL de la borne sup�rieure
      vRecordLimit   TAccountLimit;                                          --Variable de type de r�ception de dossier
      vCounter       number(1);
    begin
      /**
      *Construction de la commande SQL selon param�tre
      **/
      vSQLText := 'select REC.DOC_RECORD_ID  ' || chr(13) ||
                  'from DOC_RECORD REC       ' || chr(13) ||
                  'order by REC.RCO_TITLE    ';

      /**
      *Dossier de... n'est pas d�fini -> recherche du dossier ayant le titre le + petit
      **/
      if pLowerRecordId is null then
        vSQLTextLower := vSQLText || 'asc';
        /**
        *Ex�cution de la commande et r�cpetion dans la structure d�fini
        **/
        execute immediate vSQLTextLower bulk collect into vRecordLimit;
        vCounter       := vRecordLimit.First;
        pLowerRecordId := vRecordLimit(vCounter);
      end if;

      /**
      *Le compte �... n'est pas d�fini -> recherche du compte ayant le n� la + grande
      **/
      if pUpperRecordId is null then
        vSQLTextUpper := vSQLText || 'desc';
        /**
        *Ex�cution de la commande et r�cpetion dans la structure d�fini
        **/
        execute immediate vSQLTextUpper bulk collect into vRecordLimit;
        vCounter       := vRecordLimit.First;
        pUpperRecordId := vRecordLimit(vCounter);
      end if;
    end GetLimitRecordId;

  begin
    /**
    * La condition SQL prime sur les bornes
    * La condition doit comporter l'id de la table sp�cifi�e
    **/
    if not pCondition is null then
      vResult := 'select REF.DOC_RECORD_ID         ' || chr(13) ||
                 'from ( ' || pCondition || ' ) REF' || chr(13) ||
                 '    ,DOC_RECORD               REC' || chr(13) ||
                 'where REF.DOC_RECORD_ID = REC.DOC_RECORD_ID'|| chr(13) ||
                 'order by REC.RCO_TITLE';
    elsif (not pLowerLimit is null) or (not pUpperLimit is null)   then         /** Au moins une limite est renseign�e .. Recherche de l'autre borne **/
        vLowerRecordId := pLowerLimit;
        vUpperRecordId := pUpperLimit;
        /**
        * R�ception dans les variables vide des min / max des comptes.
        **/
        GetLimitRecordId(vLowerRecordId,vUpperRecordId);
        /**
        *Cr�ation de la commande SQL selon bornes d�finies
        */
        vResult := 'select REC.DOC_RECORD_ID  ' || chr(13) ||
                   'from DOC_RECORD     REC,  ' || chr(13) ||
                   '     DOC_RECORD     REC_F,' || chr(13) ||
                   '     DOC_RECORD     REC_T ' || chr(13) ||
                   'where REC_F.DOC_RECORD_ID = ' || vLowerRecordId      || chr(13) ||
                   '  and REC_T.DOC_RECORD_ID = ' || vUpperRecordId      || chr(13) ||
                   '  and REC.RCO_TITLE     >= REC_F.RCO_TITLE'        || chr(13) ||
                   '  and REC.RCO_TITLE     <= REC_T.RCO_TITLE'        || chr(13) ||
                   'order by REC.RCO_TITLE';
    else                                                                        /** Cr�ation de la commande SQL g�n�rale **/
      vResult := 'select REC.DOC_RECORD_ID   ' || chr(13) ||
                 'from DOC_RECORD     REC    ' || chr(13) ||
                 'order by REC.RCO_TITLE';

    end if;
    return vResult;
  end GetRecordCursor;


  /*
  * Description: Retour d'une structure temporaire de r�ception des �l�ments cibles et leurs nombres
  */
  procedure GetElementsRates(pDistributionId  MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                             pUsageTypeId     MGM_USAGE_TYPE.MGM_USAGE_TYPE_ID%type,
                             pOrigin          MGM_TRANSFER_UNIT.C_MGM_UNIT_ORIGIN%type,
                             pUsageTyp        MGM_USAGE_TYPE.C_USAGE_TYPE%type,
                             pPeriodFromId    MGM_UNIT_VALUES.ACS_PERIOD_ID%type,
                             pPeriodToId      MGM_UNIT_VALUES.ACS_PERIOD_ID%type,
                             pFinYearIdId     MGM_UNIT_VALUES.ACS_FINANCIAL_YEAR_ID%type,
                             pBudgetVersionId MGM_DISTRIBUTION.ACB_BUDGET_VERSION_ID%type,
                             vNumberTotal     in out number)
  is
    /**
    * R�ception des comptes et montants de la table des "soldes avant" pour les tuples d�finis
    * dans les unit�s appliqu�es de l'unit� donn� et dont la source = (01(effective) ,02(budget))
    * MAU.ACS_CPN.... seront toujours null pour usagetyp 1....
    * La proc�dure �tant globale pour les valeurs usagetyp 1 / 2 , ces champs CPN sont quand m�me mis
    * dans la commande
    **/
    cursor cTotalTargetElements
    is
      select MAU.MGM_APPLIED_UNIT_ID TARGET_ID,
             MAU.ACS_CDA_ACCOUNT_ID,
             MAU.ACS_PF_ACCOUNT_ID,
             MAU.ACS_PJ_ACCOUNT_ID,
             MAU.ACS_CPN_ACCOUNT_ID,
             MAU.ACS_ACS_CPN_ACCOUNT_ID,
             MAU.MAU_CPN_CONDITION,
             nvl(sum(nvl(BAL.MDB_AMOUNT_D,0) - nvl(BAL.MDB_AMOUNT_C,0)),0) MDB_AMOUNT_D,
             nvl(sum(nvl(BAL.MDB_BUD_AMOUNT_D,0) - nvl(BAL.MDB_BUD_AMOUNT_C,0)),0) MDB_BUD_AMOUNT_D
      from MGM_APPLIED_UNIT MAU, MGM_DISTRIBUTION_BALANCE BAL, MGM_USAGE_TYPE MUT
      where MUT.MGM_USAGE_TYPE_ID    = pUsageTypeId
        and MUT.C_USAGE_TYPE         = pUsageTyp
        and MAU.MGM_USAGE_TYPE_ID    = MUT.MGM_USAGE_TYPE_ID
        and BAL.MGM_DISTRIBUTION_ID  = pDistributionId
        and ((BAL.ACS_CDA_ACCOUNT_ID = NVL(MAU.ACS_CDA_ACCOUNT_ID, BAL.ACS_CDA_ACCOUNT_ID)) OR
             (BAL.ACS_CDA_ACCOUNT_ID is null and MAU.ACS_CDA_ACCOUNT_ID is null)
            )
        and ((BAL.ACS_PF_ACCOUNT_ID  = NVL(MAU.ACS_PF_ACCOUNT_ID, BAL.ACS_PF_ACCOUNT_ID)) OR
             (BAL.ACS_PF_ACCOUNT_ID is null and MAU.ACS_PF_ACCOUNT_ID is null)
            )
        and ((BAL.ACS_PJ_ACCOUNT_ID  = NVL(MAU.ACS_PJ_ACCOUNT_ID, BAL.ACS_PJ_ACCOUNT_ID)) OR
             (BAL.ACS_PJ_ACCOUNT_ID is null and MAU.ACS_PJ_ACCOUNT_ID is null)
            )
      group by MAU.MGM_APPLIED_UNIT_ID,
               MAU.ACS_CDA_ACCOUNT_ID,
               MAU.ACS_PF_ACCOUNT_ID,
               MAU.ACS_PJ_ACCOUNT_ID,
               MAU.ACS_CPN_ACCOUNT_ID,
               MAU.ACS_ACS_CPN_ACCOUNT_ID,
               MAU.MAU_CPN_CONDITION;

    /**
    * Curseur de recherche des donn�es cibles selon l'unit�
    * pour les unit�s dont la source <> (01(effective) ,02(budget))
    **/
    cursor cUnitTargetElements
    is
      select MAU.MGM_APPLIED_UNIT_ID TARGET_ID,
             MAU.ACS_CDA_ACCOUNT_ID,
             MAU.ACS_PF_ACCOUNT_ID,
             MAU.ACS_PJ_ACCOUNT_ID,
             MAU.ACS_CPN_ACCOUNT_ID,
             MAU.ACS_ACS_CPN_ACCOUNT_ID,
             MAU.MAU_CPN_CONDITION,
             MUV.MUV_NUMBER
      from MGM_APPLIED_UNIT MAU, MGM_UNIT_VALUES MUV, MGM_TRANSFER_UNIT MTU, MGM_USAGE_TYPE MUT
      where MUT.MGM_USAGE_TYPE_ID    = pUsageTypeId
        and MUT.C_USAGE_TYPE         = pUsageTyp
        and MAU.MGM_USAGE_TYPE_ID    = MUT.MGM_USAGE_TYPE_ID
        and MUV.MGM_TRANSFER_UNIT_ID = MUT.MGM_TRANSFER_UNIT_ID
        and MTU.MGM_TRANSFER_UNIT_ID = MUT.MGM_TRANSFER_UNIT_ID
       and ( (MUV.ACS_CDA_ACCOUNT_ID = MAU.ACS_CDA_ACCOUNT_ID)
            or ( MUV.ACS_CDA_ACCOUNT_ID is null and MAU.ACS_CDA_ACCOUNT_ID is null)
           )
       and ( (MUV.ACS_PF_ACCOUNT_ID = MAU.ACS_PF_ACCOUNT_ID)
            or ( MUV.ACS_PF_ACCOUNT_ID is null and MAU.ACS_PF_ACCOUNT_ID is null)
           )
       and ( (MUV.ACS_PJ_ACCOUNT_ID = MAU.ACS_PJ_ACCOUNT_ID)
            or ( MUV.ACS_PJ_ACCOUNT_ID is null and MAU.ACS_PJ_ACCOUNT_ID is null)
           )
       and (
             (
               case
                 when(MTU.C_MGM_UNIT_EXPLOITATION ='1') then 1
                 when(pBudgetVersionId is not null) then
                 case
                   when(MUV.ACB_BUDGET_VERSION_ID = pBudgetVersionId) then
                   case
                     when(MTU.C_MGM_UNIT_EXPLOITATION = '2') and
                         (MUV.ACS_FINANCIAL_YEAR_ID is null) and
                         (MUV.ACS_PERIOD_ID = pPeriodToId) then 1
                     when(MTU.C_MGM_UNIT_EXPLOITATION ='3') and
                         (MUV.ACS_FINANCIAL_YEAR_ID is null)and
                         (exists(select 1
                                 from ACS_PERIOD PER_FROM
                                    , ACS_PERIOD PER_TO
                                    , ACS_PERIOD PER
                                  where PER_FROM.ACS_PERIOD_ID = pPeriodFromId
                                    and PER_TO.ACS_PERIOD_ID = pPeriodToId
                                    and PER.PER_NO_PERIOD <= PER_TO.PER_NO_PERIOD
                                    and PER.PER_NO_PERIOD >= PER_FROM.PER_NO_PERIOD
                                    and MUV.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                                    and MUV.ACS_FINANCIAL_YEAR_ID = PER_TO.ACS_FINANCIAL_YEAR_ID)
                         )then 1
                     when(MTU.C_MGM_UNIT_EXPLOITATION ='4') and
                         (MUV.ACS_FINANCIAL_YEAR_ID is null) and
                         (MUV.ACS_PERIOD_ID is null) then 1
                     else 0
                   end
                   else 0
                 end
                 when(pFinYearIdId is not null) then
                 case
                   when(MUV.ACS_FINANCIAL_YEAR_ID = pFinYearIdId) then
                   case
                     when(MTU.C_MGM_UNIT_EXPLOITATION ='2')and
                         (MUV.ACB_BUDGET_VERSION_ID is null)and
                         (MUV.ACS_PERIOD_ID = pPeriodToId) then 1
                     when(MTU.C_MGM_UNIT_EXPLOITATION ='3')and
                         (MUV.ACB_BUDGET_VERSION_ID is null)and
                         (exists(select 1
                                 from ACS_PERIOD PER_FROM
                                    , ACS_PERIOD PER_TO
                                    , ACS_PERIOD PER
                                  where PER_FROM.ACS_PERIOD_ID = pPeriodFromId
                                    and PER_TO.ACS_PERIOD_ID = pPeriodToId
                                    and PER.PER_NO_PERIOD <= PER_TO.PER_NO_PERIOD
                                    and PER.PER_NO_PERIOD >= PER_FROM.PER_NO_PERIOD
                                    and MUV.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                                    and MUV.ACS_FINANCIAL_YEAR_ID = pFinYearIdId)
                         )then 1
                     when(MTU.C_MGM_UNIT_EXPLOITATION ='4')and
                         (MUV.ACB_BUDGET_VERSION_ID is null)and
                         (MUV.ACS_PERIOD_ID is null) then 1
                     else 0
                   end
                   else 0
                 end
               end
             )
            ) = 1;


    vTotalTargetElements  cTotalTargetElements%rowtype;            --R�ceptionne les enregistrements du curseur
    vCPNCursorText        MGM_APPLIED_UNIT.MAU_CPN_CONDITION%type; --R�ceptionne la commande SQL de s�lection des comptes CPN
    vCPNAccount           TAccountLimit;                        --Table temporaire de r�ception des comptes CPN
    vCPNCounter           number;                                  --Compteur de la table des CPN
    vCounter              number;                                  --Compteur des enregistrements cible
    vNumber               number;                                  --Nombre de la cible

    /**
    * Fonction de retour du montant effectif ou budget de la table "solde avant" pour les axes analytiques d�finis
    **/
    function GetCpnNumber(pCpnAccountId MGM_DISTRIBUTION_BALANCE.ACS_CPN_ACCOUNT_ID%type,
                          pCdaAccountId MGM_DISTRIBUTION_BALANCE.ACS_CDA_ACCOUNT_ID%type,
                          pPfAccountId  MGM_DISTRIBUTION_BALANCE.ACS_PF_ACCOUNT_ID%type,
                          pPjAccountId  MGM_DISTRIBUTION_BALANCE.ACS_PJ_ACCOUNT_ID%type,
                          pOrigin       MGM_TRANSFER_UNIT.C_MGM_UNIT_ORIGIN%type)

      return number
    is
      vResult    number;
      vAmount    MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type;
      vBudAmount MGM_DISTRIBUTION_BALANCE.MDB_BUD_AMOUNT_D%type;
    begin
      begin
        select ABS(nvl(sum(nvl(BAL.MDB_AMOUNT_D,0) - nvl(BAL.MDB_AMOUNT_C,0)),0)) MDB_AMOUNT_D,
               ABS(nvl(sum(nvl(BAL.MDB_BUD_AMOUNT_D,0) - nvl(BAL.MDB_BUD_AMOUNT_C,0)),0)) MDB_BUD_AMOUNT_D
        into  vAmount , vBudAmount
        from MGM_DISTRIBUTION_BALANCE BAL
        where BAL.MGM_DISTRIBUTION_ID  = pDistributionId
          and ((BAL.ACS_CDA_ACCOUNT_ID = NVL(pCdaAccountId, BAL.ACS_CDA_ACCOUNT_ID)) OR
               (BAL.ACS_CDA_ACCOUNT_ID is null and pCdaAccountId is null)
              )
          and ((BAL.ACS_PF_ACCOUNT_ID  = NVL(pPfAccountId, BAL.ACS_PF_ACCOUNT_ID)) OR
               (BAL.ACS_PF_ACCOUNT_ID is null and pPfAccountId is null)
              )
          and ((BAL.ACS_PJ_ACCOUNT_ID  = NVL(pPjAccountId, BAL.ACS_PJ_ACCOUNT_ID)) OR
               (BAL.ACS_PJ_ACCOUNT_ID is null and pPjAccountId is null)
              )
          and BAL.ACS_CPN_ACCOUNT_ID = pCpnAccountId;
        if pOrigin = '02' then
          vResult := vBudAmount;
        elsif pOrigin = '01' then
          vResult := vAmount;
        end if;
      exception
        when others then
          vResult := 0.0;
      end;
      return vResult;
    end GetCpnNumber;
  begin
    vTargetElement.Delete;
    vCounter     := 1;
    vNumberTotal := 0;
    /**
    * Unit� dont la source = Effectif ou Budget
    * R�ception des comptes CDA, PF, PJ , nombre par tuble et nombre total
    * r�sultant du croisement de la table des soldes et des unit�s appliquees (cible)
    **/
    if (pOrigin = '01') or (pOrigin = '02') then
      open cTotalTargetElements;
      fetch cTotalTargetElements  into vTotalTargetElements;
      while cTotalTargetElements%found
      loop
        /**
        * R�cup�ration des champs dans la structure temporaire globale d�finie
        **/
        vTargetElement(vCounter).TARGET_ID          := vTotalTargetElements.TARGET_ID;
        vTargetElement(vCounter).ACS_CDA_ACCOUNT_ID := vTotalTargetElements.ACS_CDA_ACCOUNT_ID;
        vTargetElement(vCounter).ACS_PF_ACCOUNT_ID  := vTotalTargetElements.ACS_PF_ACCOUNT_ID;
        vTargetElement(vCounter).ACS_PJ_ACCOUNT_ID  := vTotalTargetElements.ACS_PJ_ACCOUNT_ID;

        /**
        * Si la ligne de l'unit� appliqu�e poss�de un filtre sur les CPN
        * --> R�cup�ration des comptes et calcul du nombre pour les CPN prises en charge
        **/
        if not ((vTotalTargetElements.ACS_CPN_ACCOUNT_ID is null) and
                (vTotalTargetElements.ACS_ACS_CPN_ACCOUNT_ID is null) and
                (vTotalTargetElements.MAU_CPN_CONDITION is null) )then
          /**
          * Constitution de la commande SQL de recherche des comptes selon condition et/ ou bornes du domaine concern�
          **/
          vCPNCursorText := GetAccountCursor(vTotalTargetElements.MAU_CPN_CONDITION,          --Condition
                                             vTotalTargetElements.ACS_CPN_ACCOUNT_ID,         --Compte de..
                                             vTotalTargetElements.ACS_ACS_CPN_ACCOUNT_ID,     --Compte �..
                                             'CPN');                                          --Domaine
          begin
            execute immediate vCPNCursorText bulk collect into vCPNAccount; --Contr�le validit�
          exception
            when others then
              raise_application_error(-20001, chr(13) ||PCS.PC_FUNCTIONS.TRANSLATEWORD('NO_VALID_CTYP_TARGET') ||  chr(13) || vCPNCursorText ||  chr(13));
          end;

          if vCPNAccount.count <> 0 then                                  --Comptes CPN existent
            /**
            * R�cup�ration du nombre pour chaque CPN pris en charge
            **/
            for vCPNCounter in vCPNAccount.First..vCPNAccount.Last
            loop
              /**
              * R�cup�ration du montant effectif ou budget pour les axes analytiques donn�es
              **/
              vNumber := GetCpnNumber(vCPNAccount(vCPNCounter),
                                      vTotalTargetElements.ACS_CDA_ACCOUNT_ID,
                                      vTotalTargetElements.ACS_PF_ACCOUNT_ID,
                                      vTotalTargetElements.ACS_PJ_ACCOUNT_ID,
                                      pOrigin);

              /**
              * R�cup�ration de nombre pour l'enregistrement courant
              **/
              vTargetElement(vCounter).MUV_NUMBER := vNumber;
              /**
              * Calcul du nombre total de la r�partition
              **/
              vNumberTotal := vNumberTotal + vTargetElement(vCounter).MUV_NUMBER;
            end loop;
          end if;

        /**
        * Pas de filtre  sur les CPN
        * --> Le nombre correspond au total des montants ou total des montant budget du "solde avant"
        * selon la source de l'unit�
        **/
        else
          if  pOrigin = '01' then --Effectif
            /**
            * R�cup�ration de nombre pour l'enregistrement courant
            **/
            vTargetElement(vCounter).MUV_NUMBER := vTotalTargetElements.MDB_AMOUNT_D;
            /**
            * Calcul du nombre total de la r�partition
            **/
            vNumberTotal                        := vNumberTotal + vTotalTargetElements.MDB_AMOUNT_D;
          else                    --Budget
            /**
            * R�cup�ration de nombre pour l'enregistrement courant
            **/
            vTargetElement(vCounter).MUV_NUMBER := vTotalTargetElements.MDB_BUD_AMOUNT_D;
            /**
            * Calcul du nombre total de la r�partition
            **/
            vNumberTotal                        := vNumberTotal + vTotalTargetElements.MDB_BUD_AMOUNT_D;
          end if;
        end if;
        vCounter := vCounter + 1;
        fetch cTotalTargetElements  into vTotalTargetElements;
      end loop;
      close cTotalTargetElements;
    /**
    * Unit� dont la source <> ( Effectif et Budget )
    * R�ception des comptes CDA, PF, PJ , nombre par tuble et nombre total
    * r�sultant du croisement des unit�s appliquees (cible) et de nombres d'unit�s
    **/
    else
      open cUnitTargetElements;
      fetch cUnitTargetElements  into vTargetElement(vCounter);
      while cUnitTargetElements%found
      loop
        vNumberTotal := vNumberTotal + vTargetElement(vCounter).MUV_NUMBER;
        vCounter     := vCounter + 1;
        fetch cUnitTargetElements  into vTargetElement(vCounter);
      end loop;
      close cUnitTargetElements;
    end if;
  end GetElementsRates;


 /*
  * Description: R�ception des montants calcul�s
  */
  procedure GetRateTupleAmount(pDistributionId MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                               pDetailId       MGM_DISTRIBUTION_DETAIL.MGM_DISTRIBUTION_DETAIL_ID%type,
                               pTraUnitId      MGM_DISTRIBUTION_DETAIL.MGM_TRANSFER_UNIT_ID%type,
                               pCPNAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CPN_ACCOUNT_ID%type,
                               pCDAAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CDA_ACCOUNT_ID%type,
                               pPFAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PF_ACCOUNT_ID%type,
                               pPJAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PJ_ACCOUNT_ID%type,
                               pAmount         in out  MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type)
  is
    vAmountD MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type;
    vAmountC MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_C%type;
  begin
    pAmount := 0.0;

    GetTupleBalanceAmount(pDistributionId,
                          pCPNAccountId,
                          pCDAAccountId,
                          pPFAccountId,
                          pPJAccountId,
                          null,
                          null,
                          vAmountD,
                          vAmountC);

    pAmount := pAmount + (vAmountD - vAmountC);

    GetRateSourceAmount(pDetailId,
                        pCPNAccountId,
                        pCDAAccountId,
                        pPFAccountId,
                        vAmountD,
                        vAmountC);

    pAmount := pAmount + (vAmountD - vAmountC);

    GetRateDistributedAmount(pDistributionId,
                             pCPNAccountId,
                             pCDAAccountId,
                             pPFAccountId,
                             pPJAccountId,
                             vAmountD,
                             vAmountC);

    pAmount := pAmount + (vAmountD - vAmountC);

  end GetRateTupleAmount;

 /*
  * Description: R�ception des montants et quantit�s selon les tuples de compte donn�s
  *              de la table des soldes
  */
  procedure GetTupleBalanceAmount(pDistributionId MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                                  pCPNAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CPN_ACCOUNT_ID%type,
                                  pCDAAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CDA_ACCOUNT_ID%type,
                                  pPFAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PF_ACCOUNT_ID%type,
                                  pPJAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PJ_ACCOUNT_ID%type,
                                  pRecordId       MGM_DISTRIBUTION_ELEMENT.DOC_RECORD_FROM_ID%type,
                                  pQTYAccountId   MGM_DISTRIBUTION_BALANCE.ACS_QTY_UNIT_ID%type,
                                  pAmountD      in out  MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type,
                                  pAmountC      in out  MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_C%type)

  is
  begin
    pAmountD := 0.0;
    pAmountC := 0.0;
    begin
      select nvl(sum(nvl(MDB_AMOUNT_D,0)),0), nvl(sum(nvl(MDB_AMOUNT_C,0)),0)
      into pAmountD, pAmountC
      from  MGM_DISTRIBUTION_BALANCE BAL,
            MGM_DISTRIBUTION DIS
      where DIS.MGM_DISTRIBUTION_ID = pDistributionId
        and BAL.MGM_DISTRIBUTION_ID = DIS.MGM_DISTRIBUTION_ID
        and ((ACS_CPN_ACCOUNT_ID    = NVL(pCPNAccountId, ACS_CPN_ACCOUNT_ID)) OR
             (ACS_CPN_ACCOUNT_ID is null and pCPNAccountId is null)
            )
        and ((ACS_CDA_ACCOUNT_ID    = NVL(pCDAAccountId, ACS_CDA_ACCOUNT_ID)) OR
             (ACS_CDA_ACCOUNT_ID is null and pCDAAccountId is null)
            )
        and ((ACS_PF_ACCOUNT_ID     = NVL(pPFAccountId, ACS_PF_ACCOUNT_ID)) OR
             (ACS_PF_ACCOUNT_ID is null and pPFAccountId is null)
            )
        and ((ACS_PJ_ACCOUNT_ID     = NVL(pPJAccountId, ACS_PJ_ACCOUNT_ID)) OR
             (ACS_PJ_ACCOUNT_ID is null and pPJAccountId is null)
            )
        and ((DOC_RECORD_ID     = NVL(pRecordId, DOC_RECORD_ID)) OR
             (DOC_RECORD_ID is null and pRecordId is null)
            )
        and ((ACS_QTY_UNIT_ID       = NVL(pQTYAccountId, ACS_QTY_UNIT_ID)) OR
             (ACS_QTY_UNIT_ID is null and pQTYAccountId is null)
            );
    exception
      when OTHERS then
        pAmountD := 0.0;
        pAmountC := 0.0;
    end;
  end GetTupleBalanceAmount;

 /*
  * Description: R�ception des montants et quantit�s selon les tuples de compte donn�s
  *              de la table des soldes
  */
  function GetTupleBalanceAmount(pDistributionId MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                                 pCPNAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CPN_ACCOUNT_ID%type,
                                 pCDAAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CDA_ACCOUNT_ID%type,
                                 pPFAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PF_ACCOUNT_ID%type,
                                 pPJAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PJ_ACCOUNT_ID%type,
                                 pRecordId       MGM_DISTRIBUTION_ELEMENT.DOC_RECORD_FROM_ID%type,
                                 pQTYAccountId   MGM_DISTRIBUTION_BALANCE.ACS_QTY_UNIT_ID%type)
    return MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type
  is
    vResult MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type;
  begin
    vResult := 0.0;
    begin
      select nvl(sum(nvl(MDB_AMOUNT_D,0)),0) -  nvl(sum(nvl(MDB_AMOUNT_C,0)),0)
      into vResult
      from  MGM_DISTRIBUTION_BALANCE BAL,
            MGM_DISTRIBUTION DIS
      where DIS.MGM_DISTRIBUTION_ID = pDistributionId
        and BAL.MGM_DISTRIBUTION_ID = DIS.MGM_DISTRIBUTION_ID
        and ((ACS_CPN_ACCOUNT_ID    = NVL(pCPNAccountId, ACS_CPN_ACCOUNT_ID)) OR
             (ACS_CPN_ACCOUNT_ID is null and pCPNAccountId is null)
            )
        and ((ACS_CDA_ACCOUNT_ID    = NVL(pCDAAccountId, ACS_CDA_ACCOUNT_ID)) OR
             (ACS_CDA_ACCOUNT_ID is null and pCDAAccountId is null)
            )
        and ((ACS_PF_ACCOUNT_ID     = NVL(pPFAccountId, ACS_PF_ACCOUNT_ID)) OR
             (ACS_PF_ACCOUNT_ID is null and pPFAccountId is null)
            )
        and ((ACS_PJ_ACCOUNT_ID     = NVL(pPJAccountId, ACS_PJ_ACCOUNT_ID)) OR
             (ACS_PJ_ACCOUNT_ID is null and pPJAccountId is null)
            )
        and ((DOC_RECORD_ID     = NVL(pRecordId, DOC_RECORD_ID)) OR
             (DOC_RECORD_ID is null and pRecordId is null)
            )
        and ((ACS_QTY_UNIT_ID       = NVL(pQTYAccountId, ACS_QTY_UNIT_ID)) OR
             (ACS_QTY_UNIT_ID is null and pQTYAccountId is null)
            );
    exception
      when OTHERS then
        vResult := 0.0;
    end;
    return vResult;

  end GetTupleBalanceAmount;

 /*
  * Description: R�ception des montants selon les tuples de compte donn�s
  *              des r�partitions sources
  */
  procedure GetRateSourceAmount(pDistributionDetId MGM_DISTRIBUTION_DETAIL.MGM_DISTRIBUTION_DETAIL_ID%type,
                                pCPNAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CPN_ACCOUNT_ID%type,
                                pCDAAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CDA_ACCOUNT_ID%type,
                                pPFAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PF_ACCOUNT_ID%type,
                                pAmountD      in out  MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type,
                                pAmountC      in out  MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_C%type
                                )

  is
  begin
    pAmountD := 0.0;
    pAmountC := 0.0;
    begin
      select nvl(sum(nvl(MDO.MDO_AMOUNT_D,0)),0), nvl(sum(nvl(MDO.MDO_AMOUNT_C,0)),0)
      into pAmountD,pAmountC
      from MGM_DISTRIBUTION_ORIGIN MDO, MGM_DISTRIBUTION_DETAIL MDD
      where MDD.MGM_DISTRIBUTION_DETAIL_ID        = pDistributionDetId
        and MDO.MGM_DISTRIBUTION_DETAIL_ID = MDD.MGM_DISTRIBUTION_DETAIL_ID
        and ((MDO.ACS_CPN_ACCOUNT_ID    = NVL(pCPNAccountId, MDO.ACS_CPN_ACCOUNT_ID)) OR
             (MDO.ACS_CPN_ACCOUNT_ID is null and pCPNAccountId is null)
            )
        and ((MDO.ACS_CDA_ACCOUNT_ID    = NVL(pCDAAccountId, MDO.ACS_CDA_ACCOUNT_ID)) OR
             (MDO.ACS_CDA_ACCOUNT_ID is null and pCDAAccountId is null)
            )
        and ((MDO.ACS_PF_ACCOUNT_ID     = NVL(pPFAccountId, MDO.ACS_PF_ACCOUNT_ID)) OR
             (MDO.ACS_PF_ACCOUNT_ID is null and pPFAccountId is null)
            );
    exception
      when no_data_found then
        pAmountD := 0.0;
        pAmountC := 0.0;
    end;
  end GetRateSourceAmount;

 /*
  * Description: R�ception des montants selon les tuples de compte donn�s
  *              des r�partitions cibles
  */
  procedure GetRateDistributedAmount(pDistributionId MGM_DISTRIBUTION.MGM_DISTRIBUTION_ID%type,
                                     pCPNAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CPN_ACCOUNT_ID%type,
                                     pCDAAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CDA_ACCOUNT_ID%type,
                                     pPFAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PF_ACCOUNT_ID%type,
                                     pPJAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PJ_ACCOUNT_ID%type,
                                     pAmountD      in out  MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type,
                                     pAmountC      in out  MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_C%type
                                     )
  is
  begin
    pAmountD := 0.0;
    pAmountC := 0.0;
    begin
      select nvl(sum(nvl(MDT.MDT_AMOUNT_D,0)),0), nvl(sum(nvl(MDT.MDT_AMOUNT_C,0)),0)
      into pAmountD,pAmountC
      from MGM_DISTRIBUTION_TARGET MDT, MGM_DISTRIBUTION_ORIGIN MDO, MGM_DISTRIBUTION_DETAIL MDD
      where MDD.MGM_DISTRIBUTION_ID        = pDistributionId
        and MDO.MGM_DISTRIBUTION_DETAIL_ID = MDD.MGM_DISTRIBUTION_DETAIL_ID
        and MDT.MGM_DISTRIBUTION_ORIGIN_ID = MDO.MGM_DISTRIBUTION_ORIGIN_ID
        and ((MDT.ACS_CPN_ACCOUNT_ID    = NVL(pCPNAccountId, MDT.ACS_CPN_ACCOUNT_ID)) OR
             (MDT.ACS_CPN_ACCOUNT_ID is null and pCPNAccountId is null)
            )
        and ((MDT.ACS_CDA_ACCOUNT_ID    = NVL(pCDAAccountId, MDT.ACS_CDA_ACCOUNT_ID)) OR
             (MDT.ACS_CDA_ACCOUNT_ID is null and pCDAAccountId is null)
            )
        and ((MDT.ACS_PF_ACCOUNT_ID     = NVL(pPFAccountId, MDT.ACS_PF_ACCOUNT_ID)) OR
             (MDT.ACS_PF_ACCOUNT_ID is null and pPFAccountId is null)
            )
        and ((MDT.ACS_PJ_ACCOUNT_ID     = NVL(pPJAccountId, MDT.ACS_PJ_ACCOUNT_ID)) OR
             (MDT.ACS_PJ_ACCOUNT_ID is null and pPJAccountId is null)
            );
  exception
      when no_data_found then
        pAmountD := 0.0;
        pAmountC := 0.0;
    end;
  end GetRateDistributedAmount;

  /**
  * Description: fonction de cr�ation des position de solde
  */
  function  CreateBalancePosition(pDistributionId MGM_DISTRIBUTION_BALANCE.MGM_DISTRIBUTION_ID%type,
                                  pCPNAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CPN_ACCOUNT_ID%type,
                                  pCDAAccountId   MGM_DISTRIBUTION_BALANCE.ACS_CDA_ACCOUNT_ID%type,
                                  pPFAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PF_ACCOUNT_ID%type,
                                  pPJAccountId    MGM_DISTRIBUTION_BALANCE.ACS_PJ_ACCOUNT_ID%type,
                                  pDocRecordId    MGM_DISTRIBUTION_BALANCE.DOC_RECORD_ID%type,
                                  pQTYAccountId   MGM_DISTRIBUTION_BALANCE.ACS_QTY_UNIT_ID%type,
                                  pAmountD        MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_D%type,
                                  pAmountC        MGM_DISTRIBUTION_BALANCE.MDB_AMOUNT_C%type,
                                  pQtyD           MGM_DISTRIBUTION_BALANCE.MDB_QTY_D%type,
                                  pQtyC           MGM_DISTRIBUTION_BALANCE.MDB_QTY_C%type,
                                  pBudget         number)
    return  MGM_DISTRIBUTION_BALANCE.MGM_DISTRIBUTION_BALANCE_ID%type
  is
    vResultBalanceId MGM_DISTRIBUTION_BALANCE.MGM_DISTRIBUTION_BALANCE_ID%type;
  begin
    vResultBalanceId := 0;
    if pBudget = 1 then
      begin
        select nvl(max(MGM_DISTRIBUTION_BALANCE_ID),0)
        into vResultBalanceId
        from  MGM_DISTRIBUTION_BALANCE
        where MGM_DISTRIBUTION_ID = pDistributionId
          and (ACS_CPN_ACCOUNT_ID = nvl(pCPNAccountId,ACS_CPN_ACCOUNT_ID) or
              (ACS_CPN_ACCOUNT_ID is null and pCPNAccountId is null))
          and (ACS_CDA_ACCOUNT_ID = nvl(pCDAAccountId,ACS_CDA_ACCOUNT_ID) or
              (ACS_CDA_ACCOUNT_ID is null and pCDAAccountId is null))
          and (ACS_PF_ACCOUNT_ID = nvl(pPFAccountId,ACS_PF_ACCOUNT_ID) or
              (ACS_PF_ACCOUNT_ID is null and pPFAccountId is null))
          and (ACS_PJ_ACCOUNT_ID = nvl(pPJAccountId,ACS_PJ_ACCOUNT_ID) or
              (ACS_PJ_ACCOUNT_ID is null and pPJAccountId is null))
          and (DOC_RECORD_ID = nvl(pDocRecordId,DOC_RECORD_ID) or
              (DOC_RECORD_ID is null and pDocRecordId is null))
          and (ACS_QTY_UNIT_ID = nvl(pQTYAccountId,ACS_QTY_UNIT_ID) or
              (ACS_QTY_UNIT_ID is null and pQTYAccountId is null));
      exception
        when others then
          vResultBalanceId := 0;
      end;
    end if;

    if vResultBalanceId = 0 then
      select init_id_seq.nextval into vResultBalanceId from dual;
      if pBudget = 1 then
        begin
          insert into MGM_DISTRIBUTION_BALANCE
           (MGM_DISTRIBUTION_BALANCE_ID,
            MGM_DISTRIBUTION_ID,
            ACS_CPN_ACCOUNT_ID,
            ACS_CDA_ACCOUNT_ID,
            ACS_PF_ACCOUNT_ID,
            ACS_PJ_ACCOUNT_ID,
            DOC_RECORD_ID,
            ACS_QTY_UNIT_ID,
            MDB_BUD_AMOUNT_D,
            MDB_BUD_AMOUNT_C,
            MDB_BUD_QTY_D,
            MDB_BUD_QTY_C,
            A_DATECRE,
            A_IDCRE)
          values(
            vResultBalanceId,
            pDistributionId,
            pCPNAccountId,
            pCDAAccountId,
            pPFAccountId,
            pPJAccountId,
            pDocRecordId,
            pQTYAccountId,
            pAmountD,
            pAmountC,
            pQtyD,
            pQtyC,
            sysdate,
            UserIni);

        exception
          when OTHERS then
            vResultBalanceId := null;
        end;
      else
        begin
          insert into MGM_DISTRIBUTION_BALANCE
           (MGM_DISTRIBUTION_BALANCE_ID,
            MGM_DISTRIBUTION_ID,
            ACS_CPN_ACCOUNT_ID,
            ACS_CDA_ACCOUNT_ID,
            ACS_PF_ACCOUNT_ID,
            ACS_PJ_ACCOUNT_ID,
            DOC_RECORD_ID,
            ACS_QTY_UNIT_ID,
            MDB_AMOUNT_D,
            MDB_AMOUNT_C,
            MDB_QTY_D,
            MDB_QTY_C,
            A_DATECRE,
            A_IDCRE)
          values(
            vResultBalanceId,
            pDistributionId,
            pCPNAccountId,
            pCDAAccountId,
            pPFAccountId,
            pPJAccountId,
            pDocRecordId,
            pQTYAccountId,
            pAmountD,
            pAmountC,
            pQtyD,
            pQtyC,
            sysdate,
            UserIni);
        exception
          when OTHERS then
            vResultBalanceId := null;
        end;
      end if;
    else
      update MGM_DISTRIBUTION_BALANCE
      set MDB_BUD_AMOUNT_D   = NVL(MDB_BUD_AMOUNT_D,0) + pAmountD,
          MDB_BUD_AMOUNT_C   = NVL(MDB_BUD_AMOUNT_C,0) + pAmountC,
          MDB_BUD_QTY_D      = NVL(MDB_BUD_QTY_D,0)    + pQtyD,
          MDB_BUD_QTY_C      = NVL(MDB_BUD_QTY_C,0)    + pQtyC
      where MGM_DISTRIBUTION_BALANCE_ID = vResultBalanceId ;
    end if;
    return vResultBalanceId;
  end CreateBalancePosition;

  /**
  * Description: fonction de cr�ation des position de d�tail r�partition
  */
  function  CreateDetailPosition(pDistributionId MGM_DISTRIBUTION_DETAIL.MGM_DISTRIBUTION_ID%type,
                                 pElementId      MGM_DISTRIBUTION_DETAIL.MGM_DISTRIBUTION_ELEMENT_ID%type,
                                 pTraUnitId      MGM_DISTRIBUTION_DETAIL.MGM_TRANSFER_UNIT_ID%type,
                                 pModelSeq       MGM_DISTRIBUTION_DETAIL.MDD_MODEL_SEQ%type,
                                 pElemSeq        MGM_DISTRIBUTION_DETAIL.MMD_STRUCTURE_ELEM_SEQ%type)
    return  MGM_DISTRIBUTION_DETAIL.MGM_DISTRIBUTION_DETAIL_ID%type
  is
    vResultDetailId MGM_DISTRIBUTION_DETAIL.MGM_DISTRIBUTION_DETAIL_ID%type;
  begin
    select init_id_seq.nextval into vResultDetailId from dual;
    begin
      insert into MGM_DISTRIBUTION_DETAIL
       (MGM_DISTRIBUTION_DETAIL_ID,
        MGM_DISTRIBUTION_ID,
        MGM_DISTRIBUTION_ELEMENT_ID,
        MGM_TRANSFER_UNIT_ID,
        MDD_MODEL_SEQ,
        MMD_STRUCTURE_ELEM_SEQ,
        A_DATECRE,
        A_IDCRE)
      values(
        vResultDetailId,
        pDistributionId,
        pElementId,
        pTraUnitId,
        pModelSeq,
        pElemSeq,
        sysdate,
        UserIni);
    exception
      when OTHERS then
        vResultDetailId := null;
    end;
    return vResultDetailId;
  end CreateDetailPosition;

  /**
  * Description: fonction de cr�ation des position de d�tail source
  */
  function  CreateSourcePosition(pDistributionDetId MGM_DISTRIBUTION_ORIGIN.MGM_DISTRIBUTION_DETAIL_ID%type,
                                 pCPNAccountId      MGM_DISTRIBUTION_ORIGIN.ACS_CPN_ACCOUNT_ID%type,
                                 pCDAAccountId      MGM_DISTRIBUTION_ORIGIN.ACS_CDA_ACCOUNT_ID%type,
                                 pPFAccountId       MGM_DISTRIBUTION_ORIGIN.ACS_PF_ACCOUNT_ID%type,
                                 pCPNImputationId   MGM_DISTRIBUTION_ORIGIN.ACS_ACS_CPN_ACCOUNT_ID%type,
                                 pAmount_D          MGM_DISTRIBUTION_ORIGIN.MDO_AMOUNT_D%type,
                                 pAmount_C          MGM_DISTRIBUTION_ORIGIN.MDO_AMOUNT_C%type
                                 )
    return  MGM_DISTRIBUTION_ORIGIN.MGM_DISTRIBUTION_ORIGIN_ID%type
  is
    vResultSourceId MGM_DISTRIBUTION_ORIGIN.MGM_DISTRIBUTION_ORIGIN_ID%type;
  begin
    vResultSourceId := 0.0;
    begin
     /** La recherche de la position existante doit se faire dans le cadre du m�me d�tail**/
      select nvl(max(MGM_DISTRIBUTION_ORIGIN_ID),0)
      into vResultSourceId
      from  MGM_DISTRIBUTION_ORIGIN
      where MGM_DISTRIBUTION_DETAIL_ID = pDistributionDetId
        and (ACS_CPN_ACCOUNT_ID = nvl(pCPNAccountId,ACS_CPN_ACCOUNT_ID) or
            (ACS_CPN_ACCOUNT_ID is null and pCPNAccountId is null))
        and (ACS_CDA_ACCOUNT_ID = nvl(pCDAAccountId,ACS_CDA_ACCOUNT_ID) or
            (ACS_CDA_ACCOUNT_ID is null and ((pCDAAccountId is null) or(pCDAAccountId = -1))))
        and (ACS_PF_ACCOUNT_ID = nvl(pPFAccountId,ACS_PF_ACCOUNT_ID) or
            (ACS_PF_ACCOUNT_ID is null and ((pPFAccountId is null) or(pPFAccountId = -1))));
    exception
      when others then
        vResultSourceId := 0.0;
    end;

    if vResultSourceId = 0.0 then
      select init_id_seq.nextval into vResultSourceId from dual;
      begin
        insert into MGM_DISTRIBUTION_ORIGIN
         (MGM_DISTRIBUTION_ORIGIN_ID,
          MGM_DISTRIBUTION_DETAIL_ID,
          ACS_CPN_ACCOUNT_ID,
          ACS_CDA_ACCOUNT_ID,
          ACS_PF_ACCOUNT_ID,
          ACS_ACS_CPN_ACCOUNT_ID,
          MDO_AMOUNT_D,
          MDO_AMOUNT_C,
          A_DATECRE,
          A_IDCRE)
        values(
          vResultSourceId,
          pDistributionDetId,
          decode(pCPNAccountId,0,null,pCPNAccountId),
          decode(pCDAAccountId,0,null,pCDAAccountId),
          decode(pPFAccountId,0,null,pPFAccountId),
          NVL(pCPNImputationId,pCPNAccountId),
          pAmount_D,
          pAmount_C,
          sysdate,
          UserIni);
      exception
        when OTHERS then
          vResultSourceId := null;
      end;
    else
      update MGM_DISTRIBUTION_ORIGIN
      set MDO_AMOUNT_D = MDO_AMOUNT_D + pAmount_D,
          MDO_AMOUNT_C = MDO_AMOUNT_C + pAmount_C
      where MGM_DISTRIBUTION_ORIGIN_ID = vResultSourceId;
    end if;
    return vResultSourceId;
  end CreateSourcePosition;

  /**
  * Description: Fonction de cr�ation des position de d�tail cible
  */
  function  CreateTargetPosition(pOriginId      MGM_DISTRIBUTION_TARGET.MGM_DISTRIBUTION_ORIGIN_ID%type,
                                 pCPNAccountId  MGM_DISTRIBUTION_TARGET.ACS_CPN_ACCOUNT_ID%type,
                                 pCDAAccountId  MGM_DISTRIBUTION_TARGET.ACS_CDA_ACCOUNT_ID%type,
                                 pPFAccountId   MGM_DISTRIBUTION_TARGET.ACS_PF_ACCOUNT_ID%type,
                                 pPJAccountId   MGM_DISTRIBUTION_TARGET.ACS_PJ_ACCOUNT_ID%type,
                                 pAmount_D      MGM_DISTRIBUTION_TARGET.MDT_AMOUNT_D%type,
                                 pAmount_C      MGM_DISTRIBUTION_TARGET.MDT_AMOUNT_C%type
                                 )
    return  MGM_DISTRIBUTION_TARGET.MGM_DISTRIBUTION_TARGET_ID%type
  is
    vResultTargetId MGM_DISTRIBUTION_TARGET.MGM_DISTRIBUTION_TARGET_ID%type;
  begin
    vResultTargetId := 0.0;
    begin
      select nvl(max(MGM_DISTRIBUTION_TARGET_ID),0)
      into vResultTargetId
      from  MGM_DISTRIBUTION_TARGET
      where MGM_DISTRIBUTION_ORIGIN_ID = pOriginId
        and (ACS_CPN_ACCOUNT_ID = nvl(pCPNAccountId,ACS_CPN_ACCOUNT_ID) or
            (ACS_CPN_ACCOUNT_ID is null and pCPNAccountId is null))
        and (ACS_CDA_ACCOUNT_ID = nvl(pCDAAccountId,ACS_CDA_ACCOUNT_ID) or
            (ACS_CDA_ACCOUNT_ID is null and ((pCDAAccountId is null) or(pCDAAccountId = -1))))
        and (ACS_PF_ACCOUNT_ID = nvl(pPFAccountId,ACS_PF_ACCOUNT_ID) or
            (ACS_PF_ACCOUNT_ID is null and ((pPFAccountId is null) or(pPFAccountId = -1))))
        and (ACS_PJ_ACCOUNT_ID = nvl(pPJAccountId,ACS_PJ_ACCOUNT_ID) or
            (ACS_PJ_ACCOUNT_ID is null and ((pPJAccountId is null) or(pPJAccountId = -1))));
    exception
      when others then
        vResultTargetId := 0.0;
    end;

    if vResultTargetId = 0.0 then
      select init_id_seq.nextval into vResultTargetId from dual;
      begin
        insert into MGM_DISTRIBUTION_TARGET
         (MGM_DISTRIBUTION_TARGET_ID,
          MGM_DISTRIBUTION_ORIGIN_ID,
          ACS_CPN_ACCOUNT_ID,
          ACS_CDA_ACCOUNT_ID,
          ACS_PF_ACCOUNT_ID,
          ACS_PJ_ACCOUNT_ID,
          MDT_AMOUNT_D,
          MDT_AMOUNT_C,
          A_DATECRE,
          A_IDCRE)
        values(
          vResultTargetId,
          pOriginId,
          pCPNAccountId,
          pCDAAccountId,
          pPFAccountId,
          pPJAccountId,
          pAmount_D,
          pAmount_C,
          sysdate,
          UserIni);
      exception
        when OTHERS then
          vResultTargetId := null;
      end;
    else
      update MGM_DISTRIBUTION_TARGET
      set MDT_AMOUNT_D = MDT_AMOUNT_D + pAmount_D,
          MDT_AMOUNT_C = MDT_AMOUNT_C + pAmount_C
      where MGM_DISTRIBUTION_TARGET_ID = vResultTargetId;
    end if;
    return vResultTargetId;
  end CreateTargetPosition;

  /**
  * Description: fonction de cr�ation des position de taux unit� d'oeuvre
  */
  function  CreateRatePosition(pDistributionId  MGM_UNIT_RATE.MGM_DISTRIBUTION_ID%type,
                               pTransferUnitId  MGM_UNIT_RATE.MGM_TRANSFER_UNIT_ID%type,
                               pUsageTypeId     MGM_UNIT_RATE.MGM_USAGE_TYPE_ID%type,
                               pCDAAccountId    MGM_UNIT_RATE.ACS_CDA_ACCOUNT_ID%type,
                               pPFAccountId     MGM_UNIT_RATE.ACS_PF_ACCOUNT_ID%type,
                               pPJAccountId     MGM_UNIT_RATE.ACS_PJ_ACCOUNT_ID%type,
                               pAmount          MGM_UNIT_RATE.MUR_AMOUNT%type,
                               pQuantity        MGM_UNIT_RATE.MUR_QUANTITY%type,
                               pCpnGroup        MGM_UNIT_RATE.MUR_CPN_GROUP%type,
                               pUpdate          boolean,
                               pRateId          MGM_UNIT_RATE.MGM_UNIT_RATE_ID%type
                                )
    return  MGM_UNIT_RATE.MGM_UNIT_RATE_ID%type
  is
    vResultRateId MGM_UNIT_RATE.MGM_UNIT_RATE_ID%type;
  begin
    if not pUpdate  then
      select init_id_seq.nextval into vResultRateId from dual;
      begin
        insert into MGM_UNIT_RATE
         (MGM_UNIT_RATE_ID,
          MGM_TRANSFER_UNIT_ID,
          MGM_DISTRIBUTION_ID,
          MGM_USAGE_TYPE_ID,
          ACS_CDA_ACCOUNT_ID,
          ACS_PF_ACCOUNT_ID,
          ACS_PJ_ACCOUNT_ID,
          MUR_AMOUNT,
          MUR_QUANTITY,
          MUR_RATE,
          MUR_CPN_GROUP,
          A_DATECRE,
          A_IDCRE)
        values(
          vResultRateId,
          pTransferUnitId,
          pDistributionId,
          pUsageTypeId,
          pCDAAccountId,
          pPFAccountId,
          pPJAccountId,
          pAmount,
          pQuantity,
          0,
          pCpnGroup,
          sysdate,
          UserIni);
      exception
        when OTHERS then
          vResultRateId := null;
      end;
    else
      vResultRateId := pRateId;
      update MGM_UNIT_RATE
      set   MUR_QUANTITY = MUR_QUANTITY + pQuantity
      where MGM_UNIT_RATE_ID = pRateId;
    end if;
    return vResultRateId;
  end CreateRatePosition;

begin
  UserIni         := PCS.PC_I_LIB_SESSION.GetUserIni;
  LocalCurrencyId := ACS_FUNCTION.GetLocalCurrencyId;
end MGM_DISTRIBUTIONS;
