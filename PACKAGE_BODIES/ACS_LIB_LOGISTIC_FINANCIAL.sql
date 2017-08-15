--------------------------------------------------------
--  DDL for Package Body ACS_LIB_LOGISTIC_FINANCIAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_LIB_LOGISTIC_FINANCIAL" 
is
  /**
  * Description   Recherche du code TVA
  */
  function GetVatCode(
    iCode            in number
  , iThirdId         in number
  , iGoodId          in number
  , iDiscountId      in number
  , iChargeId        in number
  , iAdminDomain     in varchar2
  , iSubmissionType  in varchar2
  , iMovementType    in varchar2
  , iVatDetAccountId in number
  )
    return number
  is
    SubmissionType  DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type;
    TypeVatGood     DIC_TYPE_VAT_GOOD.DIC_TYPE_VAT_GOOD_ID%type;
    VatDetAccountId ACS_VAT_DET_ACCOUNT.ACS_VAT_DET_ACCOUNT_ID%type;
    result          ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
  begin
    /**
    * PREMIERE PARTIE -> Recherche du décompte TVA et du type de soumission
    */

    -- sans liaison partenaire
    if iThirdId is null then
      SubmissionType  := PCS.PC_CONFIG.GetConfig('DOC_DefltTYPE_SUBMISSION');

      select nvl(iVatDetAccountId, max(ACS_VAT_DET_ACCOUNT_ID) )
        into VatDetAccountId
        from ACS_VAT_DET_ACCOUNT
       where VDE_DEFAULT = 1;
    -- avec liaison partenaire
    else
      select nvl(iSubmissionType
               , decode(iAdminDomain
                      , gcAdSales, CUS.DIC_TYPE_SUBMISSION_ID
                      , gcAdPurchases, SUP.DIC_TYPE_SUBMISSION_ID
                      , gcAdSubcontracting, SUP.DIC_TYPE_SUBMISSION_ID
                      , nvl(CUS.DIC_TYPE_SUBMISSION_ID, SUP.DIC_TYPE_SUBMISSION_ID)
                       )
                )
           , nvl(iVatDetAccountId
               , decode(iAdminDomain
                      , gcAdSales, CUS.ACS_VAT_DET_ACCOUNT_ID
                      , gcAdPurchases, SUP.ACS_VAT_DET_ACCOUNT_ID
                      , gcAdSubcontracting, SUP.ACS_VAT_DET_ACCOUNT_ID
                      , nvl(CUS.DIC_TYPE_SUBMISSION_ID, SUP.DIC_TYPE_SUBMISSION_ID)
                       )
                )
        into SubmissionType
           , VatDetAccountId
        from PAC_PERSON PER
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where PER.PAC_PERSON_ID = iThirdId
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = PER.PAC_PERSON_ID
         and CUS.C_PARTNER_STATUS(+) = '1'
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = PER.PAC_PERSON_ID
         and SUP.C_PARTNER_STATUS(+) = '1';
    end if;

    /**
    * DEUXIEME PARTIE -> Recherche du type de mouvement et TVA type bien
    */

    -- position bien
    if iCode = 1 then
      select nvl(max(DIC_TYPE_VAT_GOOD_ID), PCS.PC_CONFIG.GetConfig('GCO_DefltTYPE_VAT_GOOD') )
        into TypeVatGood
        from GCO_VAT_GOOD
       where GCO_GOOD_ID = iGoodId
         and ACS_VAT_DET_ACCOUNT_ID = VatdetAccountId;
    -- position valeur
    elsif iCode = 2 then
      TypeVatGood  := PCS.PC_CONFIG.GetConfig('DOC_DefltVALUE_TYPE_VAT_GOOD');
    -- remise de pied
    elsif iCode = 3 then
      select nvl(max(DIC_TYPE_VAT_GOOD_ID), PCS.PC_CONFIG.GetConfig('PTC_DefltDISCOUNTTYPE_VAT_GOOD') )
        into TypeVatGood
        from PTC_VAT_DISCOUNT
       where PTC_DISCOUNT_ID = iDiscountId
         and ACS_VAT_DET_ACCOUNT_ID = VatdetAccountId;
    -- taxe de pied
    elsif iCode = 4 then
      select nvl(max(DIC_TYPE_VAT_GOOD_ID), PCS.PC_CONFIG.GetConfig('PTC_DefltCHARGETYPE_VAT_GOOD') )
        into TypeVatGood
        from PTC_VAT_CHARGE
       where PTC_CHARGE_ID = iChargeId
         and ACS_VAT_DET_ACCOUNT_ID = VatdetAccountId;
    -- frais de pied
    elsif iCode = 5 then
      TypeVatGood  := PCS.PC_CONFIG.GetConfig('PTC_DefltCOSTTYPE_VAT_GOOD');
    end if;

    /**
    * TROISIEME PARTIE -> Recherche du code TVA en fonction des valeurs
    * initialisées précédemment
    */
    select max(ACS_TAX_CODE_ID)
      into result
      from ACS_TAX_CODE
     where ACS_VAT_DET_ACCOUNT_ID = VatDetAccountId
       and DIC_TYPE_SUBMISSION_ID = SubmissionType
       and DIC_TYPE_MOVEMENT_ID = iMovementType
       and DIC_TYPE_VAT_GOOD_ID = TypeVatGood;

    return result;
  end GetVatCode;

  /**
   * procedure AddAccInformation
   * Description
   *   Ajoute les informations concernant les comptes (par défaut ou déplacement)
   *   à gtAccountInfo.
   * @created JCH 03.03.2008
   * @lastUpdate
   * @private
   * @param iElementId       : ID de l'élément concerné
   * @param iElementType     : Type d'élément
   * @param iActorId         : ID de l'intervenant pour le déplacement des comptes
   * @param iActor           : Type d'intervenant
   * @param iAdminDomain     : Domaine concerné
   * @param iDateRef         : Date de référence
   * @param obFinancial       : Compte
   * @param iDivision        : Division
   * @param iCpn             : Charge par nature
   * @param iCda             : Centre d'analyse
   * @param iPf              : Porteur
   * @param iPj              : Projet
   * @param iQty             : Quantité
   * @param iCumul           : 0 -> déplacement, 1 -> remplacement des comptes
   * @param iotAccountInfo     : Informations complémentaires des comptes
   * @param iInfoDescription : Description du bloc information à ajouter
   * @param iInfoActor       : Nom de l'intervenant pour le bloc information
   */
  procedure AddAccInformation(
    iElementId       in number
  , iElementType     in ACS_DEFAULT_ACCOUNT.C_DEFAULT_ELEMENT_TYPE%type
  , iActorId         in number default null
  , iActor           in ACS_DEF_ACC_MOVEMENT.C_ACTOR%type default null
  , iAdminDomain     in ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type
  , iDateRef         in date
  , obFinancial      in ACS_DEF_ACCOUNT_VALUES.DEF_FIN_ACCOUNT%type
  , iDivision        in ACS_DEF_ACCOUNT_VALUES.DEF_DIV_ACCOUNT%type
  , iCpn             in ACS_DEF_ACCOUNT_VALUES.DEF_CPN_ACCOUNT%type
  , iCda             in ACS_DEF_ACCOUNT_VALUES.DEF_CDA_ACCOUNT%type
  , iPf              in ACS_DEF_ACCOUNT_VALUES.DEF_PF_ACCOUNT%type
  , iPj              in ACS_DEF_ACCOUNT_VALUES.DEF_PJ_ACCOUNT%type
  , iQty             in ACS_DEF_ACCOUNT_VALUES.DEF_QTY_ACCOUNT%type
  , iCumul           in ACS_DEF_ACC_MOVEMENT.MOV_CUMUL%type default null
  , iotAccountInfo   in tAccountInfo
  , iInfoDescription in varchar2 default null
  , iInfoActor       in varchar2 default null
  )
  is
  begin
    /* Ajoute les informations de recherche des comptes */
    if    obFinancial is not null
       or iDivision is not null
       or iCpn is not null
       or iCda is not null
       or iPf is not null
       or iPj is not null
       or iotAccountInfo.DEF_HRM_PERSON is not null
       or iotAccountInfo.DEF_NUMBER1 is not null
       or iotAccountInfo.DEF_NUMBER2 is not null
       or iotAccountInfo.DEF_NUMBER3 is not null
       or iotAccountInfo.DEF_NUMBER4 is not null
       or iotAccountInfo.DEF_NUMBER5 is not null
       or iotAccountInfo.DEF_TEXT1 is not null
       or iotAccountInfo.DEF_TEXT2 is not null
       or iotAccountInfo.DEF_TEXT3 is not null
       or iotAccountInfo.DEF_TEXT4 is not null
       or iotAccountInfo.DEF_TEXT5 is not null
       or iotAccountInfo.DEF_DATE1 is not null
       or iotAccountInfo.DEF_DATE2 is not null
       or iotAccountInfo.DEF_DATE3 is not null
       or iotAccountInfo.DEF_DATE4 is not null
       or iotAccountInfo.DEF_DATE5 is not null
       or iotAccountInfo.DEF_DIC_IMP_FREE1 is not null
       or iotAccountInfo.DEF_DIC_IMP_FREE2 is not null
       or iotAccountInfo.DEF_DIC_IMP_FREE3 is not null
       or iotAccountInfo.DEF_DIC_IMP_FREE4 is not null
       or iotAccountInfo.DEF_DIC_IMP_FREE5 is not null then
      /* Pour le debug
      ra(iErrNo     => -20100 - PcsToNumber(iActor)
       , iUser      => null
       , iMessage   => obFinancial                     || CO.cLineBreak ||
                       iDivision                      || CO.cLineBreak ||
                       iCpn                           || CO.cLineBreak ||
                       iCda                           || CO.cLineBreak ||
                       iPf                            || CO.cLineBreak ||
                       iPj                            || CO.cLineBreak ||
                       iotAccountInfo.DEF_HRM_PERSON    || CO.cLineBreak ||
                       iotAccountInfo.DEF_NUMBER1       || CO.cLineBreak ||
                       iotAccountInfo.DEF_NUMBER2       || CO.cLineBreak ||
                       iotAccountInfo.DEF_NUMBER3       || CO.cLineBreak ||
                       iotAccountInfo.DEF_NUMBER4       || CO.cLineBreak ||
                       iotAccountInfo.DEF_NUMBER5       || CO.cLineBreak ||
                       iotAccountInfo.DEF_TEXT1         || CO.cLineBreak ||
                       iotAccountInfo.DEF_TEXT2         || CO.cLineBreak ||
                       iotAccountInfo.DEF_TEXT3         || CO.cLineBreak ||
                       iotAccountInfo.DEF_TEXT4         || CO.cLineBreak ||
                       iotAccountInfo.DEF_TEXT5         || CO.cLineBreak ||
                       iotAccountInfo.DEF_DIC_IMP_FREE1 || CO.cLineBreak ||
                       iotAccountInfo.DEF_DIC_IMP_FREE2 || CO.cLineBreak ||
                       iotAccountInfo.DEF_DIC_IMP_FREE3 || CO.cLineBreak ||
                       iotAccountInfo.DEF_DIC_IMP_FREE4 || CO.cLineBreak ||
                       iotAccountInfo.DEF_DIC_IMP_FREE5
        );
      /**/
      AddInformation(nvl(iInfoDescription, 'Comptes') ||
                     CO.cLineBreak ||
                     CO.cLineBreak ||
                     case
                       when iActorId is not null then nvl(iInfoActor, 'ID intervenant') || ' : ' || iActorId || CO.cLineBreak
                       else null
                     end ||
                     'Element : ' ||
                     iElementId ||
                     CO.cLineBreak ||
                     'Type : ' ||
                     iElementType ||
                     CO.cLineBreak ||
                     'Domain : ' ||
                     iAdminDomain ||
                     CO.cLineBreak ||
                     'Date  : ' ||
                     iDateRef ||
                     CO.cLineBreak ||
                     '---' ||
                     CO.cLineBreak ||
                     'Financier : ' ||
                     obFinancial ||
                     CO.cLineBreak ||
                     'Division : ' ||
                     iDivision ||
                     CO.cLineBreak ||
                     'CPN : ' ||
                     iCpn ||
                     CO.cLineBreak ||
                     'CDA : ' ||
                     iCda ||
                     CO.cLineBreak ||
                     'PF : ' ||
                     iPf ||
                     CO.cLineBreak ||
                     'PJ : ' ||
                     iPj ||
                     CO.cLineBreak ||
                     'Quantity : ' ||
                     iQty ||
                     CO.cLineBreak ||
                     case
                       when iCumul is not null then 'Replace : ' || iCumul || CO.cLineBreak
                       else null
                     end ||
                     'Person : ' ||
                     iotAccountInfo.DEF_HRM_PERSON ||
                     CO.cLineBreak ||
                     'D1 : ' ||
                     iotAccountInfo.DEF_NUMBER1 ||
                     CO.cLineBreak ||
                     'D2 : ' ||
                     iotAccountInfo.DEF_NUMBER2 ||
                     CO.cLineBreak ||
                     'D3 : ' ||
                     iotAccountInfo.DEF_NUMBER3 ||
                     CO.cLineBreak ||
                     'D4 : ' ||
                     iotAccountInfo.DEF_NUMBER4 ||
                     CO.cLineBreak ||
                     'D5 : ' ||
                     iotAccountInfo.DEF_NUMBER5 ||
                     CO.cLineBreak ||
                     'T1 : ' ||
                     iotAccountInfo.DEF_TEXT1 ||
                     CO.cLineBreak ||
                     'T2 : ' ||
                     iotAccountInfo.DEF_TEXT2 ||
                     CO.cLineBreak ||
                     'T3 : ' ||
                     iotAccountInfo.DEF_TEXT3 ||
                     CO.cLineBreak ||
                     'T4 : ' ||
                     iotAccountInfo.DEF_TEXT4 ||
                     CO.cLineBreak ||
                     'T5 : ' ||
                     iotAccountInfo.DEF_TEXT5 ||
                     CO.cLineBreak ||
                     'N1 : ' ||
                     iotAccountInfo.DEF_DIC_IMP_FREE1 ||
                     CO.cLineBreak ||
                     'N2 : ' ||
                     iotAccountInfo.DEF_DIC_IMP_FREE2 ||
                     CO.cLineBreak ||
                     'N3 : ' ||
                     iotAccountInfo.DEF_DIC_IMP_FREE3 ||
                     CO.cLineBreak ||
                     'N4 : ' ||
                     iotAccountInfo.DEF_DIC_IMP_FREE4 ||
                     CO.cLineBreak ||
                     'N5 : ' ||
                     iotAccountInfo.DEF_DIC_IMP_FREE5 ||
                     'Date1 : ' ||
                     iotAccountInfo.DEF_DATE1 ||
                     CO.cLineBreak ||
                     'Date2 : ' ||
                     iotAccountInfo.DEF_DATE2 ||
                     CO.cLineBreak ||
                     'Date3 : ' ||
                     iotAccountInfo.DEF_DATE3 ||
                     CO.cLineBreak ||
                     'Date4 : ' ||
                     iotAccountInfo.DEF_DATE4 ||
                     CO.cLineBreak ||
                     'Date5 : ' ||
                     iotAccountInfo.DEF_DATE5
                    );
    end if;
  end AddAccInformation;

  /**
   * procedure NvlCopyAccountInfo
   * Description
   *   Recopie les informations complémentaires non nulles des comptes.
   * @created JCH 03.03.2008
   * @lastUpdate
   * @private
   * @param iSrcAccountInfo  : Informations complémentaires des comptes à copier
   * @param iDestAccountInfo : Informations complémentaires des comptes à mettre à jour
   */
  procedure NvlCopyAccountInfo(iSrcAccountInfo in tAccountInfo, iDestAccountInfo in out tAccountInfo)
  is
  begin
    /* Fusionne les nouvelles informations avec les précédentes. Selon le
       principe suivant. Si la nouvelle donnée est null, on conserve la valeur
       précédente, Si la nouvelle donnée n'est pas null, on remplace l'ancienne
       valeur par la nouvelle. */
    iDestAccountInfo.DEF_HRM_PERSON     := nvl(iSrcAccountInfo.DEF_HRM_PERSON, iDestAccountInfo.DEF_HRM_PERSON);
    iDestAccountInfo.DEF_NUMBER1        := nvl(iSrcAccountInfo.DEF_NUMBER1, iDestAccountInfo.DEF_NUMBER1);
    iDestAccountInfo.DEF_NUMBER2        := nvl(iSrcAccountInfo.DEF_NUMBER2, iDestAccountInfo.DEF_NUMBER2);
    iDestAccountInfo.DEF_NUMBER3        := nvl(iSrcAccountInfo.DEF_NUMBER3, iDestAccountInfo.DEF_NUMBER3);
    iDestAccountInfo.DEF_NUMBER4        := nvl(iSrcAccountInfo.DEF_NUMBER4, iDestAccountInfo.DEF_NUMBER4);
    iDestAccountInfo.DEF_NUMBER5        := nvl(iSrcAccountInfo.DEF_NUMBER5, iDestAccountInfo.DEF_NUMBER5);
    iDestAccountInfo.DEF_TEXT1          := nvl(iSrcAccountInfo.DEF_TEXT1, iDestAccountInfo.DEF_TEXT1);
    iDestAccountInfo.DEF_TEXT2          := nvl(iSrcAccountInfo.DEF_TEXT2, iDestAccountInfo.DEF_TEXT2);
    iDestAccountInfo.DEF_TEXT3          := nvl(iSrcAccountInfo.DEF_TEXT3, iDestAccountInfo.DEF_TEXT3);
    iDestAccountInfo.DEF_TEXT4          := nvl(iSrcAccountInfo.DEF_TEXT4, iDestAccountInfo.DEF_TEXT4);
    iDestAccountInfo.DEF_TEXT5          := nvl(iSrcAccountInfo.DEF_TEXT5, iDestAccountInfo.DEF_TEXT5);
    iDestAccountInfo.DEF_DIC_IMP_FREE1  := nvl(iSrcAccountInfo.DEF_DIC_IMP_FREE1, iDestAccountInfo.DEF_DIC_IMP_FREE1);
    iDestAccountInfo.DEF_DIC_IMP_FREE2  := nvl(iSrcAccountInfo.DEF_DIC_IMP_FREE2, iDestAccountInfo.DEF_DIC_IMP_FREE2);
    iDestAccountInfo.DEF_DIC_IMP_FREE3  := nvl(iSrcAccountInfo.DEF_DIC_IMP_FREE3, iDestAccountInfo.DEF_DIC_IMP_FREE3);
    iDestAccountInfo.DEF_DIC_IMP_FREE4  := nvl(iSrcAccountInfo.DEF_DIC_IMP_FREE4, iDestAccountInfo.DEF_DIC_IMP_FREE4);
    iDestAccountInfo.DEF_DIC_IMP_FREE5  := nvl(iSrcAccountInfo.DEF_DIC_IMP_FREE5, iDestAccountInfo.DEF_DIC_IMP_FREE5);
    iDestAccountInfo.DEF_DATE1          := nvl(iSrcAccountInfo.DEF_DATE1, iDestAccountInfo.DEF_DATE1);
    iDestAccountInfo.DEF_DATE2          := nvl(iSrcAccountInfo.DEF_DATE2, iDestAccountInfo.DEF_DATE2);
    iDestAccountInfo.DEF_DATE3          := nvl(iSrcAccountInfo.DEF_DATE3, iDestAccountInfo.DEF_DATE3);
    iDestAccountInfo.DEF_DATE4          := nvl(iSrcAccountInfo.DEF_DATE4, iDestAccountInfo.DEF_DATE4);
    iDestAccountInfo.DEF_DATE5          := nvl(iSrcAccountInfo.DEF_DATE5, iDestAccountInfo.DEF_DATE5);
  end NvlCopyAccountInfo;

  /**
   * procedure DoGetDefaultAccount
   * Description
   *   Recherche les comptes par défaut pour l'élément concerné.
   * @created JCH 03.03.2008
   * @lastUpdate
   * @private
   * @param iElementId       : ID de l'élément concerné
   * @param iElementType     : Type d'élément
   * @param iAdminDomain     : Domaine concerné
   * @param iDateRef         : Date de référence
   * @param obFinancial       : Compte
   * @param iDivision        : Division
   * @param iCpn             : Charge par nature
   * @param iCda             : Centre d'analyse
   * @param iPf              : Porteur
   * @param iPj              : Projet
   * @param iotAccountInfo     : Informations complémentaires des comptes
   * @param obInfoCompl       : Prise en compte des informations complémentaires des comptes (0 ou 1)
   * @param iAddInformation  : Ajout de blocs information dans gtAccountInfo (0 ou 1)
   * @param iInfoDescription : Description du bloc information à ajouter
   */
  procedure DoGetDefaultAccount(
    iElementId       in     number
  , iElementType     in     ACS_DEFAULT_ACCOUNT.C_DEFAULT_ELEMENT_TYPE%type
  , iAdminDomain     in     ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type
  , iDateRef         in     date
  , obFinancial      in out ACS_DEF_ACCOUNT_VALUES.DEF_FIN_ACCOUNT%type
  , iDivision        in out ACS_DEF_ACCOUNT_VALUES.DEF_DIV_ACCOUNT%type
  , iCpn             in out ACS_DEF_ACCOUNT_VALUES.DEF_CPN_ACCOUNT%type
  , iCda             in out ACS_DEF_ACCOUNT_VALUES.DEF_CDA_ACCOUNT%type
  , iPf              in out ACS_DEF_ACCOUNT_VALUES.DEF_PF_ACCOUNT%type
  , iPj              in out ACS_DEF_ACCOUNT_VALUES.DEF_PJ_ACCOUNT%type
  , iQty             in out ACS_DEF_ACCOUNT_VALUES.DEF_QTY_ACCOUNT%type
  , iotAccountInfo   in out tAccountInfo
  , obInfoCompl      in     integer default 1
  , iAddInformation  in     integer default 1
  , iInfoDescription in     varchar2 default null
  )
  is
    lAccountInfoDef tAccountInfo;
  begin
    -- Recherche des comptes par défaut
    ACS_DEF_ACCOUNT.GetDefaultAccount(iElementId
                                    , iElementType
                                    , iAdminDomain
                                    , iDateRef
                                    , obFinancial
                                    , iDivision
                                    , iCpn
                                    , iCda
                                    , iPf
                                    , iPj
                                    , iQty
                                    , lAccountInfoDef.DEF_HRM_PERSON
                                    , lAccountInfoDef.DEF_NUMBER1
                                    , lAccountInfoDef.DEF_NUMBER2
                                    , lAccountInfoDef.DEF_NUMBER3
                                    , lAccountInfoDef.DEF_NUMBER4
                                    , lAccountInfoDef.DEF_NUMBER5
                                    , lAccountInfoDef.DEF_TEXT1
                                    , lAccountInfoDef.DEF_TEXT2
                                    , lAccountInfoDef.DEF_TEXT3
                                    , lAccountInfoDef.DEF_TEXT4
                                    , lAccountInfoDef.DEF_TEXT5
                                    , lAccountInfoDef.DEF_DIC_IMP_FREE1
                                    , lAccountInfoDef.DEF_DIC_IMP_FREE2
                                    , lAccountInfoDef.DEF_DIC_IMP_FREE3
                                    , lAccountInfoDef.DEF_DIC_IMP_FREE4
                                    , lAccountInfoDef.DEF_DIC_IMP_FREE5
                                    , lAccountInfoDef.DEF_DATE1
                                    , lAccountInfoDef.DEF_DATE2
                                    , lAccountInfoDef.DEF_DATE3
                                    , lAccountInfoDef.DEF_DATE4
                                    , lAccountInfoDef.DEF_DATE5
                                     );

    -- Ajout des informations pour le traçage du traitement si demandé
    if iAddInformation = 1 then
      AddAccInformation(iElementId         => iElementId
                      , iElementType       => iElementType
                      , iAdminDomain       => iAdminDomain
                      , iDateRef           => iDateRef
                      , obFinancial        => obFinancial
                      , iDivision          => iDivision
                      , iCpn               => iCpn
                      , iCda               => iCda
                      , iPf                => iPf
                      , iPj                => iPj
                      , iQty               => iQty
                      , iotAccountInfo     => lAccountInfoDef
                      , iInfoDescription   => nvl(iInfoDescription, 'Comptes par défaut')
                       );
    end if;

    -- Copie des informations complémentaires si nécessaire
    if obInfoCompl = 1 then
      NvlCopyAccountInfo(iSrcAccountInfo => lAccountInfoDef, iDestAccountInfo => iotAccountInfo);
    end if;
  end DoGetDefaultAccount;

  /**
   * procedure DoDefAccMovement
   * Description
   *   Recherche les infos de déplacement (ou remplacement) des comptes par
   *   défaut pour l'élément concerné selont l'intervenant spécifié, et
   *   applique ce déplacement (ou remplacement) si trouvé (iAccMovFound)
   * @created JCH 03.03.2008
   * @lastUpdate
   * @private
   * @param iElementId       : ID de l'élément concerné
   * @param iElementType     : Type d'élément
   * @param iActorId         : ID de l'intervenant pour le déplacement des comptes
   * @param iActor           : Type d'intervenant
   * @param iAdminDomain     : Domaine concerné
   * @param iDateRef         : Date de référence
   * @param obFinancial       : Compte
   * @param iDivision        : Division
   * @param iCpn             : Charge par nature
   * @param iCda             : Centre d'analyse
   * @param iPf              : Porteur
   * @param iPj              : Projet
   * @param iotAccountInfo     : Informations complémentaires des comptes
   * @param obInfoCompl       : Prise en compte des informations complémentaires des comptes (0 ou 1)
   * @param iAddInformation  : Ajout de blocs information dans gtAccountInfo (0 ou 1)
   * @param iInfoDescription : Description du bloc information à ajouter
   * @param iInfoActor       : Nom de l'intervenant pour le bloc information
   * @param iAccMovFound     : Déplacement (ou remplacement) des comptes trouvé (0 ou 1)
   */
  procedure DoDefAccMovement(
    iElementId       in     number
  , iElementType     in     ACS_DEF_ACC_MOVEMENT.C_DEFAULT_ELEMENT_TYPE%type
  , iActorId         in     number
  , iActor           in     ACS_DEF_ACC_MOVEMENT.C_ACTOR%type
  , iAdminDomain     in     ACS_DEF_ACC_MOVEMENT.C_ADMIN_DOMAIN%type
  , iDateRef         in     date
  , obFinancial      in out ACS_DEF_ACCOUNT_VALUES.DEF_FIN_ACCOUNT%type
  , iDivision        in out ACS_DEF_ACCOUNT_VALUES.DEF_DIV_ACCOUNT%type
  , iCpn             in out ACS_DEF_ACCOUNT_VALUES.DEF_CPN_ACCOUNT%type
  , iCda             in out ACS_DEF_ACCOUNT_VALUES.DEF_CDA_ACCOUNT%type
  , iPf              in out ACS_DEF_ACCOUNT_VALUES.DEF_PF_ACCOUNT%type
  , iPj              in out ACS_DEF_ACCOUNT_VALUES.DEF_PJ_ACCOUNT%type
  , iQty             in out ACS_DEF_ACCOUNT_VALUES.DEF_QTY_ACCOUNT%type
  , iotAccountInfo   in out tAccountInfo
  , obInfoCompl      in     integer default 1
  , iAddInformation  in     integer default 1
  , iInfoDescription in     varchar2 default null
  , iInfoActor       in     varchar2 default null
  , iAccMovFound     out    integer
  )
  is
    strFinMov       ACS_DEF_ACC_MOV_VALUES.MOV_ACCOUNT_VALUE%type;
    strDivMov       ACS_DEF_ACC_MOV_VALUES.MOV_DIVISION_VALUE%type;
    strCpnMov       ACS_DEF_ACC_MOV_VALUES.MOV_CPN_VALUE%type;
    strCdaMov       ACS_DEF_ACC_MOV_VALUES.MOV_CDA_VALUE%type;
    strPfMov        ACS_DEF_ACC_MOV_VALUES.MOV_PF_VALUE%type;
    strPjMov        ACS_DEF_ACC_MOV_VALUES.MOV_PJ_VALUE%type;
    strQtyMov       ACS_DEF_ACC_MOV_VALUES.MOV_QTY_VALUE%type;
    intCumul        ACS_DEF_ACC_MOVEMENT.MOV_CUMUL%type;
    lAccountInfoMov tAccountInfo;
  begin
    iAccMovFound  := 0;

    -- Recherche des infos de déplacement
    if (iActorId is not null) then
      ACS_DEF_ACCOUNT.GetDefAccMovement(iActorId
                                      , iElementId
                                      , iActor
                                      , iAdminDomain
                                      , iElementType
                                      , iDateRef
                                      , intCumul
                                      , strFinMov
                                      , strDivMov
                                      , strCpnMov
                                      , strCdaMov
                                      , strPfMov
                                      , strPjMov
                                      , strQtyMov
                                      , lAccountInfoMov.DEF_HRM_PERSON
                                      , lAccountInfoMov.DEF_NUMBER1
                                      , lAccountInfoMov.DEF_NUMBER2
                                      , lAccountInfoMov.DEF_NUMBER3
                                      , lAccountInfoMov.DEF_NUMBER4
                                      , lAccountInfoMov.DEF_NUMBER5
                                      , lAccountInfoMov.DEF_TEXT1
                                      , lAccountInfoMov.DEF_TEXT2
                                      , lAccountInfoMov.DEF_TEXT3
                                      , lAccountInfoMov.DEF_TEXT4
                                      , lAccountInfoMov.DEF_TEXT5
                                      , lAccountInfoMov.DEF_DIC_IMP_FREE1
                                      , lAccountInfoMov.DEF_DIC_IMP_FREE2
                                      , lAccountInfoMov.DEF_DIC_IMP_FREE3
                                      , lAccountInfoMov.DEF_DIC_IMP_FREE4
                                      , lAccountInfoMov.DEF_DIC_IMP_FREE5
                                      , lAccountInfoMov.DEF_DATE1
                                      , lAccountInfoMov.DEF_DATE2
                                      , lAccountInfoMov.DEF_DATE3
                                      , lAccountInfoMov.DEF_DATE4
                                      , lAccountInfoMov.DEF_DATE5
                                       );

      if    strFinMov is not null
         or strDivMov is not null
         or strCpnMov is not null
         or strCdaMov is not null
         or strPfMov is not null
         or strPjMov is not null then
-- Faut-il le mettre ? Etant utilisé que pour le déplacement tiers, si je le rajoute
-- cela peut modifier le fonctionnement existant de la recherche de comptes pour la logisitique
--          or strQtyjMov is not null then
        iAccMovFound  := 1;
      end if;

      -- Ajout des informations pour le traçage du traitement si demandé
      if iAddInformation = 1 then
        AddAccInformation(iElementId         => iElementId
                        , iElementType       => iElementType
                        , iActorId           => iActorId
                        , iActor             => iActor
                        , iAdminDomain       => iAdminDomain
                        , iDateRef           => iDateRef
                        , obFinancial        => strFinMov
                        , iDivision          => strDivMov
                        , iCpn               => strCpnMov
                        , iCda               => strCdaMov
                        , iPf                => strPfMov
                        , iPj                => strPjMov
                        , iQty               => strQtyMov
                        , iCumul             => intCumul
                        , iotAccountInfo     => lAccountInfoMov
                        , iInfoDescription   => nvl(iInfoDescription, 'Mouvement de comptes')
                        , iInfoActor         => iInfoActor
                         );
      end if;

      -- Copie des informations complémentaires si nécessaire
      if obInfoCompl = 1 then
        NvlCopyAccountInfo(iSrcAccountInfo => lAccountInfoMov, iDestAccountInfo => iotAccountInfo);
      end if;

      -- Déplacement ou remplacement des comptes si infos trouvées
      if iAccMovFound = 1 then
        if (nvl(intCumul, 0) = 0) then
          obFinancial  := ACS_FUNCTION.MovAccount(obFinancial, strFinMov);
          iDivision    := ACS_FUNCTION.MovAccount(iDivision, strDivMov);
          iCpn         := ACS_FUNCTION.MovAccount(iCpn, strCpnMov);
          iCda         := ACS_FUNCTION.MovAccount(iCda, strCdaMov);
          iPf          := ACS_FUNCTION.MovAccount(iPf, strPfMov);
          iPj          := ACS_FUNCTION.MovAccount(iPj, strPjMov);
          iQty         := ACS_FUNCTION.MovAccount(iQty, strQtyMov);
        else
          obFinancial  := nvl(strFinMov, obFinancial);
          iDivision    := nvl(strDivMov, iDivision);
          iCpn         := nvl(strCpnMov, iCpn);
          iCda         := nvl(strCdaMov, iCda);
          iPf          := nvl(strPfMov, iPf);
          iPj          := nvl(strPjMov, iPj);
          iQty         := nvl(strQtyMov, iQty);
        end if;
      end if;
    end if;
  end DoDefAccMovement;

   /**
   * Recherche des id des comptes en fonction du numéro de compte
   */
  /**
   * procedure
   * Description
   *   Recherche les ID des comptes à partir des numéros de compte.
   *   La règle de recherche est la suivante :
   *     si iOut est nul ou iOverride = 1 alors
   *       si iIn est non nul, iIn
   *       sinon recherche de l'ID à partir du numéro de compte
   * @created JCH 03.03.2008
   * @lastUpdate
   * @private
   * @param iInFinancialId  : Valeur pré-définie : ID Compte
   * @param iInDivisionId   : Valeur pré-définie : ID Division
   * @param iInCpnId        : Valeur pré-définie : ID Charge par nature
   * @param iInCdaId        : Valeur pré-définie : ID Centre d'analyse
   * @param iInPfId         : Valeur pré-définie : ID Porteur
   * @param iInPjId         : Valeur pré-définie : ID Projet
   * @param obFinancial      : Numéro de compte : Compte
   * @param iDivision       : Numéro de compte : Division
   * @param iCpn            : Numéro de compte : Charge par nature
   * @param iCda            : Numéro de compte : Centre d'analyse
   * @param iPf             : Numéro de compte : Porteur
   * @param iPj             : Numéro de compte : Projet
   * @param ioFinancialId : Résultat : ID Compte
   * @param ioDivisionId  : Résultat : ID Division
   * @param ioCpnId       : Résultat : ID Charge par nature
   * @param ioCdaId       : Résultat : ID Centre d'analyse
   * @param ioPfId        : Résultat : ID Porteur
   * @param ioPjId        : Résultat : ID Projet
   * @param iOverride       : 0 -> ne remplace la valeur de iOut que si elle est nulle, 1 -> ignore la valeur de iOut
   */
  procedure GetAccountIdFromAccounts(
    iInFinancialId in     ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type default null
  , iInDivisionId  in     ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type default null
  , iInCpnId       in     ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type default null
  , iInCdaId       in     ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type default null
  , iInPfId        in     ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type default null
  , iInPjId        in     ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type default null
  , iInQtyId       in     ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type default null
  , obFinancial    in     ACS_DEF_ACCOUNT_VALUES.DEF_FIN_ACCOUNT%type
  , iDivision      in     ACS_DEF_ACCOUNT_VALUES.DEF_DIV_ACCOUNT%type
  , iCpn           in     ACS_DEF_ACCOUNT_VALUES.DEF_CPN_ACCOUNT%type
  , iCda           in     ACS_DEF_ACCOUNT_VALUES.DEF_CDA_ACCOUNT%type
  , iPf            in     ACS_DEF_ACCOUNT_VALUES.DEF_PF_ACCOUNT%type
  , iPj            in     ACS_DEF_ACCOUNT_VALUES.DEF_PJ_ACCOUNT%type
  , iQty           in     ACS_DEF_ACCOUNT_VALUES.DEF_QTY_ACCOUNT%type
  , ioFinancialId  in out ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , ioDivisionId   in out ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , ioCpnId        in out ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , ioCdaId        in out ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  , ioPfId         in out ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  , ioPjId         in out ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type
  , ioQtyId        in out ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type
  , iOverride      in     integer default 1
  )
  is
  begin
    if    ioFinancialId is null
       or (iOverride = 1) then
      ioFinancialId  := nvl(iInFinancialId, ACS_FUNCTION.GetFinancialAccountId(obFinancial) );
    end if;

    if    ioDivisionId is null
       or (iOverride = 1) then
      ioDivisionId  := nvl(iInDivisionId, ACS_FUNCTION.GetDivisionAccountId(iDivision) );
    end if;

    if    ioCpnId is null
       or (iOverride = 1) then
      ioCpnId  := nvl(iInCpnId, ACS_FUNCTION.GetCpnAccountId(iCpn) );

      if     (ioCpnId is null)
         and (ioFinancialId is not null) then
        ioCpnId  := ACS_FUNCTION.GetCpnOfFinAcc(ioFinancialId);
      end if;
    end if;

    if    ioCdaId is null
       or (iOverride = 1) then
      ioCdaId  := nvl(iInCdaId, ACS_FUNCTION.GetCdaAccountId(iCda) );
    end if;

    if    ioPfId is null
       or (iOverride = 1) then
      ioPfId  := nvl(iInPfId, ACS_FUNCTION.GetPfAccountId(iPf) );
    end if;

    if    ioPjId is null
       or (iOverride = 1) then
      ioPjId  := nvl(iInPjId, ACS_FUNCTION.GetPjAccountId(iPj) );
    end if;

    if    ioQtyId is null
       or (iOverride = 1) then
      ioQtyId  := nvl(iInQtyId, ACS_FUNCTION.GetQtyAccountId(iQty) );
    end if;
  end GetAccountIdFromAccounts;

  /**
   * procedure SearchAccounts
   * Description
   *   Recherche les comptes pour l'élément concerné puis effectue tous les
   *   déplacements (ou remplacement) nécessaires (pour les ID d'intervenants
   *   non nuls).
   * @created JCH 03.03.2008
   * @lastUpdate
   * @private
   * @param iElementId        : ID de l'élément concerné
   * @param iElementType      : Type d'élément
   * @param iAdminDomain      : Domaine concerné
   * @param iDateRef          : Date de référence
   * @param iStockId          : ID du stock pour déplacement
   * @param iMovementKindId   : ID du genre de mouvement pour déplacement
   * @param iPositionId       : ID de la position pour déplacement
   * @param iDocumentId       : ID du document pour déplacement
   * @param iGaugeId          : ID du gabarit pour déplacement
   * @param iRecordId         : ID du dossier pour déplacement
   * @param iThirdId          : ID du tiers pour déplacement
   * @param iThirdAdminDomain : Domaine pour la cascade de recherche du déplacement lié au tiers
   * @param iInFinancialId    : Valeur pré-définie : ID Compte
   * @param iInDivisionId     : Valeur pré-définie : ID Division
   * @param iInCpnId          : Valeur pré-définie : ID Charge par nature
   * @param iInCdaId          : Valeur pré-définie : ID Centre d'analyse
   * @param iInPfId           : Valeur pré-définie : ID Porteur
   * @param iInPjId           : Valeur pré-définie : ID Projet
   * @param iInQtyId          : Valeur pré-définie : ID Unité quantitative
   * @param ioFinancialId   : Résultat : ID Compte
   * @param ioDivisionId    : Résultat : ID Division
   * @param ioCpnId         : Résultat : ID Charge par nature
   * @param ioCdaId         : Résultat : ID Centre d'analyse
   * @param ioPfId          : Résultat : ID Porteur
   * @param ioPjId          : Résultat : ID Projet
   * @param ioQtyId         : Résultat : ID Unité quantitative
   * @param iotAccountInfo      : Informations complémentaires des comptes
   * @param obInfoCompl        : Prise en compte des informations complémentaires des comptes (0 ou 1)
   * @param iAddInformation   : Ajout de blocs information dans gtAccountInfo (0 ou 1)
   * @param iInfoDescrDetail  : Ajout à la description des blocs information à ajouter
   * @param iOverride         : 0 -> ne remplace la valeur de iOut que si elle est nulle, 1 -> ignore la valeur de iOut
   */
  procedure SearchAccounts(
    iElementId         in     number
  , iElementType       in     ACS_DEFAULT_ACCOUNT.C_DEFAULT_ELEMENT_TYPE%type
  , iAdminDomain       in     ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type
  , iDateRef           in     date
  , iStockId           in     STM_STOCK.STM_STOCK_ID%type default null
  , iMovementKindId    in     STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  , iPositionId        in     DOC_POSITION.DOC_POSITION_ID%type default null
  , iDocumentId        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , iGaugeId           in     DOC_GAUGE.DOC_GAUGE_ID%type default null
  , iRecordId          in     DOC_RECORD.DOC_RECORD_ID%type default null
  , iFalLotId          in     FAL_LOT.FAL_LOT_ID%type default null
  , iGalTaskId         in     GAL_TASK.GAL_TASK_ID%type default null
  , iFalFactoryFloorId in     FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type default null
  , iGalCostCenterId   in     GAL_COST_CENTER.GAL_COST_CENTER_ID%type default null
  , iHrmPersonId       in     HRM_PERSON.HRM_PERSON_ID%type default null
  , iThirdId           in     PAC_THIRD.PAC_THIRD_ID%type default null
  , iThirdAdminDomain  in     ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type default null
  , iInFinancialId     in     ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type default null
  , iInDivisionId      in     ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type default null
  , iInCpnId           in     ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type default null
  , iInCdaId           in     ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type default null
  , iInPfId            in     ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type default null
  , iInPjId            in     ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type default null
  , iInQtyId           in     ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type default null
  , ioFinancialId      in out ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , ioDivisionId       in out ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , ioCpnId            in out ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , ioCdaId            in out ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  , ioPfId             in out ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  , ioPjId             in out ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type
  , ioQtyId            in out ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type
  , iotAccountInfo     in out tAccountInfo
  , obInfoCompl        in     integer default 1
  , iAddInformation    in     integer default 1
  , iInfoDescrDetail   in     varchar2 default null
  , iOverride          in     integer default 1
  )
  is
    strFinancial ACS_DEF_ACCOUNT_VALUES.DEF_FIN_ACCOUNT%type;
    strDivision  ACS_DEF_ACCOUNT_VALUES.DEF_DIV_ACCOUNT%type;
    strCpn       ACS_DEF_ACCOUNT_VALUES.DEF_CPN_ACCOUNT%type;
    strCda       ACS_DEF_ACCOUNT_VALUES.DEF_CDA_ACCOUNT%type;
    strPf        ACS_DEF_ACCOUNT_VALUES.DEF_PF_ACCOUNT%type;
    strPj        ACS_DEF_ACCOUNT_VALUES.DEF_PJ_ACCOUNT%type;
    strQty       ACS_DEF_ACCOUNT_VALUES.DEF_QTY_ACCOUNT%type;
    strActor     ACS_DEF_ACC_MOVEMENT.C_ACTOR%type;
    lAdminDomain ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type;
    lAccMovFound integer;
  begin
    /**
    * Recherche des comptes par défaut.
    */
    DoGetDefaultAccount(iElementId         => iElementId
                      , iElementType       => iElementType
                      , iAdminDomain       => iAdminDomain
                      , iDateRef           => iDateRef
                      , obFinancial        => strFinancial
                      , iDivision          => strDivision
                      , iCpn               => strCpn
                      , iCda               => strCda
                      , iPf                => strPf
                      , iPj                => strPj
                      , iQty               => strQty
                      , iotAccountInfo     => iotAccountInfo
                      , obInfoCompl        => obInfoCompl
                      , iInfoDescription   => 'Comptes par défaut' || ' ' || iInfoDescrDetail
                       );
    /**
    * Déplacements liés au stock
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iStockId
                   , iActor             => cgAtStock
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement stock' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'Stock'
                   , iAccMovFound       => lAccMovFound
                    );
    /**
    * Déplacements liés au genre de mouvement
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iMovementKindId
                   , iActor             => cgAtMovementKind
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement genre de mouvement' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'MovementKind'
                   , iAccMovFound       => lAccMovFound
                    );
    /**
    * Déplacements liés à la position
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iPositionId
                   , iActor             => cgAtDocPosition
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement position' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'Position'
                   , iAccMovFound       => lAccMovFound
                    );
    /**
    * Déplacements liés au document
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iDocumentId
                   , iActor             => cgAtDocDocument
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement document' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'Document'
                   , iAccMovFound       => lAccMovFound
                    );
    /**
    * Déplacements liés au gabarit
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iGaugeId
                   , iActor             => cgAtDocGauge
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement gabarit' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'Gauge'
                   , iAccMovFound       => lAccMovFound
                    );
    /**
    * Déplacements liés au dossier
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iRecordId
                   , iActor             => cgAtRecord
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement dossier' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'Record'
                   , iAccMovFound       => lAccMovFound
                    );
    /**
    * Déplacements liés au lot
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iFalLotId
                   , iActor             => cgAtManufacturingOrder
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement ordre de fabrication' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'Lot'
                   , iAccMovFound       => lAccMovFound
                    );
--     /**
--     * Déplacements liés au dossier de fabrication
--     */
--     DoDefAccMovement(iElementId         => iElementId
--                    , iElementType       => iElementType
--                    , iActorId           => iGalTaskId
--                    , iActor             => cgAtRecord   --Project !!!!!!!!
--                    , iAdminDomain       => iAdminDomain
--                    , iDateRef           => iDateRef
--                    , obFinancial         => strFinancial
--                    , iDivision          => strDivision
--                    , iCpn               => strCpn
--                    , iCda               => strCda
--                    , iPf                => strPf
--                    , iPj                => strPj
--                    , iQty               => strQty
--                    , iotAccountInfo       => iotAccountInfo
--                    , obInfoCompl         => obInfoCompl
--                    , iAddInformation    => iAddInformation
--                    , iInfoDescription   => 'Déplacement dossier de fabrication' || ' ' || iInfoDescrDetail
--                    , iInfoActor         => 'Task'
--                    , iAccMovFound       => lAccMovFound
--                     );
    /**
    * Déplacements liés à la ressource
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iFalFactoryFloorId
                   , iActor             => cgAtResource
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement ressource' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'FactoryFloor'
                   , iAccMovFound       => lAccMovFound
                    );
    /**
    * Déplacements liés à la nature analytique
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iGalCostCenterId
                   , iActor             => cgAtCostCenter
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement nature analytique' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'CostCenter'
                   , iAccMovFound       => lAccMovFound
                    );
    /**
    * Déplacements liés à l'opérateur HRM
    */
    DoDefAccMovement(iElementId         => iElementId
                   , iElementType       => iElementType
                   , iActorId           => iHrmPersonId
                   , iActor             => cgAtOperatorHRM
                   , iAdminDomain       => iAdminDomain
                   , iDateRef           => iDateRef
                   , obFinancial        => strFinancial
                   , iDivision          => strDivision
                   , iCpn               => strCpn
                   , iCda               => strCda
                   , iPf                => strPf
                   , iPj                => strPj
                   , iQty               => strQty
                   , iotAccountInfo     => iotAccountInfo
                   , obInfoCompl        => obInfoCompl
                   , iAddInformation    => iAddInformation
                   , iInfoDescription   => 'Déplacement opérateur (HRM)' || ' ' || iInfoDescrDetail
                   , iInfoActor         => 'Person'
                   , iAccMovFound       => lAccMovFound
                    );

    /**
    * Déplacements liés au tiers
    */
    if (iThirdId is not null) then
      /**
      * Recherche de l'intervenant pour le déplacement tiers.
      *
      * Si le domaine du gabarit est différent d'achat, vente ou sous-traitance
      * la recherche du déplacement lié au partenaire se fait d'abord avec le
      * client, puis si aucune donnée n'est trouvée, avec le fournisseur comme
      * intervenant.
      */
      lAdminDomain  := nvl(iThirdAdminDomain, iAdminDomain);

      select decode(lAdminDomain
                  , gcAdPurchases, cgAtSupplier   -- Si domaine achat -> intervenant fournisseur
                  , gcAdSubcontracting, cgAtSupplier   -- Si domaine sous-traitance -> intervenant fournisseur
                  , gcAdSales, gcAtCustomer   -- Si domaine vente -> intervenant client
                  , gcAtCustomer   -- Sinon intervenant client (pour la première recherche)
                   )
        into strActor
        from dual;

      DoDefAccMovement(iElementId         => iElementId
                     , iElementType       => iElementType
                     , iActorId           => iThirdId
                     , iActor             => strActor
                     , iAdminDomain       => iAdminDomain
                     , iDateRef           => iDateRef
                     , obFinancial        => strFinancial
                     , iDivision          => strDivision
                     , iCpn               => strCpn
                     , iCda               => strCda
                     , iPf                => strPf
                     , iPj                => strPj
                     , iQty               => strQty
                     , iotAccountInfo     => iotAccountInfo
                     , obInfoCompl        => obInfoCompl
                     , iAddInformation    => iAddInformation
                     , iInfoDescription   => case strActor
                         when gcAtCustomer then 'Déplacement client' || ' ' || iInfoDescrDetail
                         else 'Déplacement fournisseur' || ' ' || iInfoDescrDetail
                       end
                     , iInfoActor         => 'Third'
                     , iAccMovFound       => lAccMovFound
                      );

      if     (lAdminDomain <> gcAdPurchases)   -- Pas domaine achat
         and (lAdminDomain <> gcAdSubcontracting)   -- Pas domaine sous-traitance
         and (lAdminDomain <> gcAdSales)   -- Pas domaine vente
         and (lAccMovFound = 0) then   -- Aucun déplacement client touvé
        DoDefAccMovement(iElementId         => iElementId
                       , iElementType       => iElementType
                       , iActorId           => iThirdId
                       , iActor             => cgAtSupplier
                       , iAdminDomain       => iAdminDomain
                       , iDateRef           => iDateRef
                       , obFinancial        => strFinancial
                       , iDivision          => strDivision
                       , iCpn               => strCpn
                       , iCda               => strCda
                       , iPf                => strPf
                       , iPj                => strPj
                       , iQty               => strQty
                       , iotAccountInfo     => iotAccountInfo
                       , obInfoCompl        => obInfoCompl
                       , iAddInformation    => iAddInformation
                       , iInfoDescription   => 'Déplacement fournisseur' || ' ' || iInfoDescrDetail
                       , iInfoActor         => 'Third'
                       , iAccMovFound       => lAccMovFound
                        );
      end if;
    end if;

    /**
    * Recherche des id des comptes en fonction des numéros de compte
    * iOverride => 0 permet de ne pas écraser les paramètres iOut pré-initialisés
    */
    GetAccountIdFromAccounts(iInFinancialId   => iInFinancialId
                           , iInDivisionId    => iInDivisionId
                           , iInCpnId         => iInCpnId
                           , iInCdaId         => iInCdaId
                           , iInPfId          => iInPfId
                           , iInPjId          => iInPjId
                           , iInQtyId         => iInQtyId
                           , obFinancial      => strFinancial
                           , iDivision        => strDivision
                           , iCpn             => strCpn
                           , iCda             => strCda
                           , iPf              => strPf
                           , iPj              => strPj
                           , iQty             => strQty
                           , ioFinancialId    => ioFinancialId
                           , ioDivisionId     => ioDivisionId
                           , ioCpnId          => ioCpnId
                           , ioCdaId          => ioCdaId
                           , ioPfId           => ioPfId
                           , ioPjId           => ioPjId
                           , ioQtyId          => ioQtyId
                           , iOverride        => iOverride
                            );
  end SearchAccounts;

  /**
   * procedure SearchAccounts
   * Description
   *   Alias pour les procédures logistiques ne tenant pas compte de l'unité
   *   quantitative.
   *   Recherche les comptes pour l'élément concerné puis effectue tous les
   *   déplacements (ou remplacement) nécessaires (pour les ID d'intervenants
   *   non nuls).
   */
  procedure SearchAccounts(
    iElementId         in     number
  , iElementType       in     ACS_DEFAULT_ACCOUNT.C_DEFAULT_ELEMENT_TYPE%type
  , iAdminDomain       in     ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type
  , iDateRef           in     date
  , iStockId           in     STM_STOCK.STM_STOCK_ID%type default null
  , iMovementKindId    in     STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  , iPositionId        in     DOC_POSITION.DOC_POSITION_ID%type default null
  , iDocumentId        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , iGaugeId           in     DOC_GAUGE.DOC_GAUGE_ID%type default null
  , iRecordId          in     DOC_RECORD.DOC_RECORD_ID%type default null
  , iFalLotId          in     FAL_LOT.FAL_LOT_ID%type default null
  , iGalTaskId         in     GAL_TASK.GAL_TASK_ID%type default null
  , iFalFactoryFloorId in     FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type default null
  , iGalCostCenterId   in     GAL_COST_CENTER.GAL_COST_CENTER_ID%type default null
  , iHrmPersonId       in     HRM_PERSON.HRM_PERSON_ID%type default null
  , iThirdId           in     PAC_THIRD.PAC_THIRD_ID%type default null
  , iThirdAdminDomain  in     ACS_DEFAULT_ACCOUNT.C_ADMIN_DOMAIN%type default null
  , iInFinancialId     in     ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type default null
  , iInDivisionId      in     ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type default null
  , iInCpnId           in     ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type default null
  , iInCdaId           in     ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type default null
  , iInPfId            in     ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type default null
  , iInPjId            in     ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type default null
  , ioFinancialId      in out ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , ioDivisionId       in out ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , ioCpnId            in out ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type
  , ioCdaId            in out ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type
  , ioPfId             in out ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type
  , ioPjId             in out ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type
  , iotAccountInfo     in out tAccountInfo
  , obInfoCompl        in     integer default 1
  , iAddInformation    in     integer default 1
  , iInfoDescrDetail   in     varchar2 default null
  , iOverride          in     integer default 1
  )
  is
    -- L'unité quantitative n'est pas gérée en logistique
    lInQtyId  ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    lOutQtyId ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
  begin
    SearchAccounts(iElementId           => iElementId
                 , iElementType         => iElementType
                 , iAdminDomain         => iAdminDomain
                 , iDateRef             => iDateRef
                 , iStockId             => iStockId
                 , iMovementKindId      => iMovementKindId
                 , iPositionId          => iPositionId
                 , iDocumentId          => iDocumentId
                 , iGaugeId             => iGaugeId
                 , iRecordId            => iRecordId
                 , iFalLotId            => iFalLotId
                 , iGalTaskId           => iGalTaskId
                 , iFalFactoryFloorId   => iFalFactoryFloorId
                 , iGalCostCenterId     => iGalCostCenterId
                 , iHrmPersonId         => iHrmPersonId
                 , iThirdId             => iThirdId
                 , iThirdAdminDomain    => iThirdAdminDomain
                 , iInFinancialId       => iInFinancialId
                 , iInDivisionId        => iInDivisionId
                 , iInCpnId             => iInCpnId
                 , iInCdaId             => iInCdaId
                 , iInPfId              => iInPfId
                 , iInPjId              => iInPjId
                 , iInQtyId             => lInQtyId
                 , ioFinancialId        => ioFinancialId
                 , ioDivisionId         => ioDivisionId
                 , ioCpnId              => ioCpnId
                 , ioCdaId              => ioCdaId
                 , ioPfId               => ioPfId
                 , ioPjId               => ioPjId
                 , ioQtyId              => lOutQtyId
                 , iotAccountInfo       => iotAccountInfo
                 , obInfoCompl          => obInfoCompl
                 , iAddInformation      => iAddInformation
                 , iInfoDescrDetail     => iInfoDescrDetail
                 , iOverride            => iOverride
                  );
  end SearchAccounts;

/**
* Description Procedure d'initialisation des comptes positions
*/
  procedure GetPosAccounts(
    iCurId         in     number
  , iElementType   in     varchar2
  , iAdminDomain   in     varchar2
  , iDateRef       in     date
  , iGoodId        in     number
  , iGaugeId       in     number
  , iDocumentId    in     number
  , iPositionId    in     number
  , iRecordId      in     number
  , iThirdId       in     number
  , iInFinancialId in     number
  , iInDivisionId  in     number
  , iInCpnId       in     number
  , iInCdaId       in     number
  , iInPfId        in     number
  , iInPjId        in     number
  , ioFinancialId  in out number
  , ioDivisionId   in out number
  , ioCpnId        in out number
  , ioCdaId        in out number
  , ioPfId         in out number
  , ioPjId         in out number
  , iotAccountInfo in out tAccountInfo
  )
  is
    lFinancial  DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    lAnalytical DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    lInfoCompl  DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
  begin
    /**
    * Vérifie la gestion des comptes dans le gabarit
    */
    select decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
         , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
      into lFinancial
         , lAnalytical
         , lInfoCompl
      from DOC_GAUGE_STRUCTURED GAS
         , DOC_GAUGE GAU
     where GAU.DOC_GAUGE_ID = iGaugeId
       and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    /* Si gestion ou initialisation des comptes financiers ou analytiques */
    if    (lFinancial = 1)
       or (lAnalytical = 1) then
      /**
       * Recherche des comptes
       */
      SearchAccounts(iElementId       => iCurId
                   , iElementType     => iElementType
                   , iAdminDomain     => iAdminDomain
                   , iDateRef         => iDateRef
                   , iPositionId      => null   --iPositionId -- Pas géré
                   , iDocumentId      => iDocumentId
                   , iGaugeId         => iGaugeId
                   , iRecordId        => iRecordId
                   , iThirdId         => iThirdId
                   , iInFinancialId   => iInFinancialId
                   , iInDivisionId    => iInDivisionId
                   , iInCpnId         => iInCpnId
                   , iInCdaId         => iInCdaId
                   , iInPfId          => iInPfId
                   , iInPjId          => iInPjId
                   , ioFinancialId    => ioFinancialId
                   , ioDivisionId     => ioDivisionId
                   , ioCpnId          => ioCpnId
                   , ioCdaId          => ioCdaId
                   , ioPfId           => ioPfId
                   , ioPjId           => ioPjId
                   , iotAccountInfo   => iotAccountInfo
                   , obInfoCompl      => lInfoCompl
                    );
    else   /* Pas de gestion ou d'initialisation des comptes */
      ioFinancialId                     := null;
      ioDivisionId                      := null;
      ioCpnId                           := null;
      ioCdaId                           := null;
      ioPfId                            := null;
      ioPjId                            := null;
      iotAccountInfo.DEF_HRM_PERSON     := null;
      iotAccountInfo.DEF_NUMBER1        := null;
      iotAccountInfo.DEF_NUMBER2        := null;
      iotAccountInfo.DEF_NUMBER3        := null;
      iotAccountInfo.DEF_NUMBER4        := null;
      iotAccountInfo.DEF_NUMBER5        := null;
      iotAccountInfo.DEF_TEXT1          := null;
      iotAccountInfo.DEF_TEXT2          := null;
      iotAccountInfo.DEF_TEXT3          := null;
      iotAccountInfo.DEF_TEXT4          := null;
      iotAccountInfo.DEF_TEXT5          := null;
      iotAccountInfo.DEF_DIC_IMP_FREE1  := null;
      iotAccountInfo.DEF_DIC_IMP_FREE2  := null;
      iotAccountInfo.DEF_DIC_IMP_FREE3  := null;
      iotAccountInfo.DEF_DIC_IMP_FREE4  := null;
      iotAccountInfo.DEF_DIC_IMP_FREE5  := null;
      iotAccountInfo.DEF_DATE1          := null;
      iotAccountInfo.DEF_DATE2          := null;
      iotAccountInfo.DEF_DATE3          := null;
      iotAccountInfo.DEF_DATE4          := null;
      iotAccountInfo.DEF_DATE5          := null;
    end if;   -- ( lFinancial = 1 ) or ( lAnalytical = 1 )
  ----
  -- Inscrit éventuellement le résultat de la recherche des comptes dans la
  --   table DOC_UPDATE_HISTORY
  --WriteInformation(iDocumentId, 'Position');
/*
raise_application_error(-20100,
 iDocumentId                       || CO.cLineBreak ||
 ioFinancialId                    || CO.cLineBreak ||
 ioDivisionId                     || CO.cLineBreak ||
 ioCpnId                          || CO.cLineBreak ||
 ioCdaId                          || CO.cLineBreak ||
 ioPfId                           || CO.cLineBreak ||
 ioPfId                           || CO.cLineBreak ||
 iotAccountInfo.DEF_HRM_PERSON        || CO.cLineBreak ||
 iotAccountInfo.FAM_FIXED_ASSETS_ID   || CO.cLineBreak ||
 iotAccountInfo.C_FAM_TRANSACTION_TYP || CO.cLineBreak ||
 iotAccountInfo.DEF_DIC_IMP_FREE1     || CO.cLineBreak ||
 iotAccountInfo.DEF_DIC_IMP_FREE2     || CO.cLineBreak ||
 iotAccountInfo.DEF_DIC_IMP_FREE3     || CO.cLineBreak ||
 iotAccountInfo.DEF_DIC_IMP_FREE4     || CO.cLineBreak ||
 iotAccountInfo.DEF_DIC_IMP_FREE5     || CO.cLineBreak ||
 iotAccountInfo.DEF_TEXT1             || CO.cLineBreak ||
 iotAccountInfo.DEF_TEXT2             || CO.cLineBreak ||
 iotAccountInfo.DEF_TEXT3             || CO.cLineBreak ||
 iotAccountInfo.DEF_TEXT4             || CO.cLineBreak ||
 iotAccountInfo.DEF_TEXT5             || CO.cLineBreak ||
 iotAccountInfo.DEF_NUMBER1           || CO.cLineBreak ||
 iotAccountInfo.DEF_NUMBER2           || CO.cLineBreak ||
 iotAccountInfo.DEF_NUMBER3           || CO.cLineBreak ||
 iotAccountInfo.DEF_NUMBER4           || CO.cLineBreak ||
 iotAccountInfo.DEF_NUMBER5);
*/
  end GetPosAccounts;

  /**
  * Description Procedure d'initialisation des comptes d'entête de documents
  *
  * @created Fabrice Perotto 30.08.2001
  * @public
  */
  procedure GetHeaderAccounts(
    iCurId         in     number
  , iElementType   in     varchar2
  , iAdminDomain   in     varchar2
  , iDateRef       in     date
  , iGaugeId       in     number
  , iDocumentId    in     number
  , iRecordId      in     number
  , iThirdId       in     number
  , iInFinancialId in     number
  , iInDivisionId  in     number
  , iInCpnId       in     number
  , iInCdaId       in     number
  , iInPfId        in     number
  , iInPjId        in     number
  , ioFinancialId  in out number
  , ioDivisionId   in out number
  , ioCpnId        in out number
  , ioCdaId        in out number
  , ioPfId         in out number
  , ioPjId         in out number
  )
  is
    /**
    * Actuellement, les données complémentaires des imputations ne sont pas
    * gérées dans les documents (en-tête). J'initialise néanmois cette variable
    * en vue d'une mise en place éventuelle sur l'en-tête (ajout des champs sur
    * la table DOC_DOCUMENT).
    */
    lAccountInfo ACS_LIB_LOGISTIC_FINANCIAL.tAccountInfo;
    lFinancial   DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    lAnalytical  DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    lInfoCompl   DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    lDebug       integer                                          := 1;
  begin
    /**
    * Vérifie la gestion des comptes dans le gabarit
    */
    select decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
         , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
      into lFinancial
         , lAnalytical
         , lInfoCompl
      from DOC_GAUGE_STRUCTURED GAS
         , DOC_GAUGE GAU
     where GAU.DOC_GAUGE_ID = iGaugeId
       and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    /* Si gestion ou initialisation des comptes financiers ou analytiques */
    if    (lFinancial = 1)
       or (lAnalytical = 1) then
      /**
       * Recherche des comptes
       */
      SearchAccounts(iElementId        => iCurId
                   , iElementType      => iElementType
                   , iAdminDomain      => iAdminDomain
                   , iDateRef          => iDateRef
                   , iDocumentId       => iDocumentId
                   , iGaugeId          => iGaugeId
                   , iRecordId         => iRecordId
                   , iThirdId          => iThirdId
                   , iInFinancialId    => iInFinancialId
                   , iInDivisionId     => iInDivisionId
                   , iInCpnId          => iInCpnId
                   , iInCdaId          => iInCdaId
                   , iInPfId           => iInPfId
                   , iInPjId           => iInPjId
                   , ioFinancialId     => ioFinancialId
                   , ioDivisionId      => ioDivisionId
                   , ioCpnId           => ioCpnId
                   , ioCdaId           => ioCdaId
                   , ioPfId            => ioPfId
                   , ioPjId            => ioPjId
                   , iotAccountInfo    => lAccountInfo
                   , obInfoCompl       => lInfoCompl
                   , iAddInformation   => lDebug
                    );
    -- DefineFinancialImputation et CheckAccountPermission effectués par
    -- l'appelant (DOC_DOCUMENT_FUNCTIONS par ex)
    else   /* Pas de gestion ou d'initialisation des comptes */
      ioFinancialId                   := null;
      ioDivisionId                    := null;
      ioCpnId                         := null;
      ioCdaId                         := null;
      ioPfId                          := null;
      ioPjId                          := null;
      lAccountInfo.DEF_HRM_PERSON     := null;
      lAccountInfo.DEF_NUMBER1        := null;
      lAccountInfo.DEF_NUMBER2        := null;
      lAccountInfo.DEF_NUMBER3        := null;
      lAccountInfo.DEF_NUMBER4        := null;
      lAccountInfo.DEF_NUMBER5        := null;
      lAccountInfo.DEF_TEXT1          := null;
      lAccountInfo.DEF_TEXT2          := null;
      lAccountInfo.DEF_TEXT3          := null;
      lAccountInfo.DEF_TEXT4          := null;
      lAccountInfo.DEF_TEXT5          := null;
      lAccountInfo.DEF_DIC_IMP_FREE1  := null;
      lAccountInfo.DEF_DIC_IMP_FREE2  := null;
      lAccountInfo.DEF_DIC_IMP_FREE3  := null;
      lAccountInfo.DEF_DIC_IMP_FREE4  := null;
      lAccountInfo.DEF_DIC_IMP_FREE5  := null;
      lAccountInfo.DEF_DATE1          := null;
      lAccountInfo.DEF_DATE2          := null;
      lAccountInfo.DEF_DATE3          := null;
      lAccountInfo.DEF_DATE4          := null;
      lAccountInfo.DEF_DATE5          := null;
    end if;   /* ( lFinancial = 1 ) or ( lAnalytical = 1 ) */
  end GetHeaderAccounts;

-----------------------------------------------------------------------------------------------------------------------------
/**
* Description Procedure d'initialisation des comptes des remises et taxes
*/
  procedure GetDCAccounts(
    iCurId         in     number
  , iElementType   in     varchar2
  , iAdminDomain   in     varchar2
  , iDateRef       in     date
  , iGaugeId       in     number
  , iDocumentId    in     number
  , iPositionId    in     number
  , iRecordId      in     number
  , iThirdId       in     number
  , iInFinancialId in     number
  , iInDivisionId  in     number
  , iInCpnId       in     number
  , iInCdaId       in     number
  , iInPfId        in     number
  , iInPjId        in     number
  , ioFinancialId  in out number
  , ioDivisionId   in out number
  , ioCpnId        in out number
  , ioCdaId        in out number
  , ioPfId         in out number
  , ioPjId         in out number
  , iotAccountInfo in out tAccountInfo
  )
  is
    lFinancial              DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    lAnalytical             DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    lInfoCompl              DOC_GAUGE.GAU_USE_MANAGED_DATA%type;
    lUsePositionAccount     boolean;
    lFinancialAccountNumber ACS_ACCOUNT.ACC_NUMBER%type;
    lDivisionAccountNumber  ACS_ACCOUNT.ACC_NUMBER%type;
    lCPNAccountNumber       ACS_ACCOUNT.ACC_NUMBER%type;
    lCDAAccountNumber       ACS_ACCOUNT.ACC_NUMBER%type;
    lPFAccountNumber        ACS_ACCOUNT.ACC_NUMBER%type;
    lPJAccountNumber        ACS_ACCOUNT.ACC_NUMBER%type;
    lDescription            varchar2(20);
  begin
    /**
    * Vérifie la gestion des comptes dans le gabarit
    */
    select decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
         , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
         , nvl(GAU.GAU_USE_MANAGED_DATA, 0)
      into lFinancial
         , lAnalytical
         , lInfoCompl
      from DOC_GAUGE_STRUCTURED GAS
         , DOC_GAUGE GAU
     where GAU.DOC_GAUGE_ID = iGaugeId
       and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

    /* Si gestion ou initialisation des comptes financiers ou analytiques */
    if    (lFinancial = 1)
       or (lAnalytical = 1) then
      /**
      * L'initialisation des comptes se fait avec les données de la position
      * si la configuration l'autorise.
      */
      lUsePositionAccount  := false;

      /**
      * Inscrit les évenuelles comptes entrants (provenant de la remise ou de la taxe.
      */
      if     (PCS.PC_CONFIG.GetConfig('DOC_ACTIVATE_ACCOUNT_TRACE') = '1')
         and (   iElementType = cgEtDiscount
              or iElementType = cgEtSurcharge)
         and (   ioFinancialId is not null
              or ioDivisionId is not null
              or ioCpnId is not null
              or ioCdaId is not null
              or ioPfId is not null
              or ioPjId is not null) then
        /**
        * Recherche le nom des comptes en fonction des IDs.
        */
        lFinancialAccountNumber  := '';
        lDivisionAccountNumber   := '';
        lCPNAccountNumber        := '';
        lCDAAccountNumber        := '';
        lPFAccountNumber         := '';
        lPJAccountNumber         := '';

        if (ioFinancialId is not null) then
          lFinancialAccountNumber  := ACS_FUNCTION.GetAccountNumber(ioFinancialId);
        end if;

        if (ioDivisionId is not null) then
          lDivisionAccountNumber  := ACS_FUNCTION.GetAccountNumber(ioDivisionId);
        end if;

        if (ioCpnId is not null) then
          lCPNAccountNumber  := ACS_FUNCTION.GetAccountNumber(ioCpnId);
        end if;

        if (ioCdaId is not null) then
          lCDAAccountNumber  := ACS_FUNCTION.GetAccountNumber(ioCdaId);
        end if;

        if (ioPfId is not null) then
          lPFAccountNumber  := ACS_FUNCTION.GetAccountNumber(ioPfId);
        end if;

        if (ioPjId is not null) then
          lPJAccountNumber  := ACS_FUNCTION.GetAccountNumber(ioPjId);
        end if;

        if (iElementType = cgEtDiscount) then   /* Remises */
          lDescription  := 'Comptes de la remise';
        elsif(iElementType = cgEtSurcharge) then   /* Taxes */
          lDescription  := 'Comptes de la taxe';
        end if;

        AddInformation(lDescription ||
                       CO.cLineBreak ||
                       CO.cLineBreak ||
                       '---' ||
                       CO.cLineBreak ||
                       'Financier : ' ||
                       lFinancialAccountNumber ||
                       CO.cLineBreak ||
                       'Division : ' ||
                       lDivisionAccountNumber ||
                       CO.cLineBreak ||
                       'CPN : ' ||
                       lCPNAccountNumber ||
                       CO.cLineBreak ||
                       'CDA : ' ||
                       lCDAAccountNumber ||
                       CO.cLineBreak ||
                       'PF : ' ||
                       lPFAccountNumber ||
                       CO.cLineBreak ||
                       'PJ : ' ||
                       lPJAccountNumber
                      );
      end if;

      if (iElementType = cgEtDiscount) then   /* Remises */
        if     (ioFinancialId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD') = '1') then
          ioFinancialId        := iInFinancialId;
          lUsePositionAccount  := true;
        end if;

        if     (ioDivisionId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_DIV') = '1') then
          ioDivisionId         := iInDivisionId;
          lUsePositionAccount  := true;
        end if;

        if     (ioCpnId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_CPN') = '1') then
          ioCpnId              := iInCpnId;
          lUsePositionAccount  := true;
        end if;

        if     (ioCdaId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_CDA') = '1') then
          ioCdaId              := iInCdaId;
          lUsePositionAccount  := true;
        end if;

        if     (ioPfId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_PF') = '1') then
          ioPfId               := iInPfId;
          lUsePositionAccount  := true;
        end if;

        if     (ioPjId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_PJ') = '1') then
          ioPjId               := iInPjId;
          lUsePositionAccount  := true;
        end if;
      elsif(iElementType = cgEtSurcharge) then   /* Taxes */
        if     (ioFinancialId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD') = '1') then
          ioFinancialId        := iInFinancialId;
          lUsePositionAccount  := true;
        end if;

        if     (ioDivisionId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_DIV') = '1') then
          ioDivisionId         := iInDivisionId;
          lUsePositionAccount  := true;
        end if;

        if     (ioCpnId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_CPN') = '1') then
          ioCpnId              := iInCpnId;
          lUsePositionAccount  := true;
        end if;

        if     (ioCdaId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_CDA') = '1') then
          ioCdaId              := iInCdaId;
          lUsePositionAccount  := true;
        end if;

        if     (ioPfId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_PF') = '1') then
          ioPfId               := iInPfId;
          lUsePositionAccount  := true;
        end if;

        if     (ioPjId is null)
           and (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_PJ') = '1') then
          ioPjId               := iInPjId;
          lUsePositionAccount  := true;
        end if;
      end if;

      /**
      * Inscrit les évenuelles comptes provenant de la position.
      */
      if     (lUsePositionAccount)
         and (PCS.PC_CONFIG.GetConfig('DOC_ACTIVATE_ACCOUNT_TRACE') = '1')
         and (   iInFinancialId is not null
              or iInDivisionId is not null
              or iInCpnId is not null
              or iInCdaId is not null
              or iInPfId is not null
              or iInPjId is not null
             ) then
        /**
        * Recherche le nom des comptes en fonction des IDs.
        */
        lFinancialAccountNumber  := '';
        lDivisionAccountNumber   := '';
        lCPNAccountNumber        := '';
        lCDAAccountNumber        := '';
        lPFAccountNumber         := '';
        lPJAccountNumber         := '';

        if (iInFinancialId is not null) then
          lFinancialAccountNumber  := ACS_FUNCTION.GetAccountNumber(iInFinancialId);
        end if;

        if (iInDivisionId is not null) then
          lDivisionAccountNumber  := ACS_FUNCTION.GetAccountNumber(iInDivisionId);
        end if;

        if (iInCpnId is not null) then
          lCPNAccountNumber  := ACS_FUNCTION.GetAccountNumber(iInCpnId);
        end if;

        if (iInCdaId is not null) then
          lCDAAccountNumber  := ACS_FUNCTION.GetAccountNumber(iInCdaId);
        end if;

        if (iInPfId is not null) then
          lPFAccountNumber  := ACS_FUNCTION.GetAccountNumber(iInPfId);
        end if;

        if (iInPjId is not null) then
          lPJAccountNumber  := ACS_FUNCTION.GetAccountNumber(iInPjId);
        end if;

        AddInformation('Comptes de la position' ||
                       CO.cLineBreak ||
                       CO.cLineBreak ||
                       '---' ||
                       CO.cLineBreak ||
                       'Financier : ' ||
                       lFinancialAccountNumber ||
                       CO.cLineBreak ||
                       'Division : ' ||
                       lDivisionAccountNumber ||
                       CO.cLineBreak ||
                       'CPN : ' ||
                       lCPNAccountNumber ||
                       CO.cLineBreak ||
                       'CDA : ' ||
                       lCDAAccountNumber ||
                       CO.cLineBreak ||
                       'PF : ' ||
                       lPFAccountNumber ||
                       CO.cLineBreak ||
                       'PJ : ' ||
                       lPJAccountNumber
                      );
      end if;

      /**
       * Recherche des comptes
       * iOverride => 0 permet de ne pas écraser les paramètres iOut pré-initialisé
       */
      SearchAccounts(iElementId       => iCurId
                   , iElementType     => iElementType
                   , iAdminDomain     => iAdminDomain
                   , iDateRef         => iDateRef
                   , iPositionId      => iPositionId
                   , iDocumentId      => iDocumentId
                   , iGaugeId         => iGaugeId
                   , iRecordId        => iRecordId
                   , iThirdId         => iThirdId
                   , ioFinancialId    => ioFinancialId
                   , ioDivisionId     => ioDivisionId
                   , ioCpnId          => ioCpnId
                   , ioCdaId          => ioCdaId
                   , ioPfId           => ioPfId
                   , ioPjId           => ioPjId
                   , iotAccountInfo   => iotAccountInfo
                   , obInfoCompl      => lInfoCompl
                   , iOverride        => 0
                    );

      if (iElementType = cgEtDiscount) then   -- Remises
        ----
        -- Procédure de détermination du compte financier et du compte division pour
        -- toutes les imputations des remises.
        --
        DefineFinancialImputation(iCode                  => 4   -- Remise
                                , iChargeId              => iCurId   -- Remise ou taxe. Utilisé uniquement avec iCode = 4 ou 5.
                                , iGaugeId               => iGaugeId   -- Gabarit. Utilisé pour contrôler la gestion des comptes.
                                , iAdminDomain           => iAdminDomain   -- Domain. Utilisé uniquement avec iCode = 2 ou 3.
                                , ioFinancialAccountId   => ioFinancialId
                                , ioDivisionAccountId    => ioDivisionId
                                , ioCPNAccountId         => ioCpnId
                                , ioCDAAccountId         => ioCdaId
                                , ioPFAccountId          => ioPfId
                                , ioPJAccountId          => ioPjId
                                 );

        ----
        -- Inscrit éventuellement le résultat de la recherche des comptes dans la
        -- table DOC_UPDATE_HISTORY
        --
        if (nvl(iPositionId, 0) = 0) then
          WriteInformation(iDocumentId, 'Remise de pied ' || iCurId);
        else
          WriteInformation(iDocumentId, 'Remise de position ' || iCurId);
        end if;
      elsif(iElementType = cgEtSurcharge) then   -- Taxes
        ----
        -- Procédure de détermination du compte financier et du compte division pour
        -- toutes les imputations des taxes.
        --
        DefineFinancialImputation(iCode                  => 5   -- Taxe
                                , iChargeId              => iCurId   -- Remise ou taxe. Utilisé uniquement avec iCode = 4 ou 5.
                                , iGaugeId               => iGaugeId   -- Gabarit. Utilisé pour contrôler la gestion des comptes.
                                , iAdminDomain           => iAdminDomain   -- Domain. Utilisé uniquement avec iCode = 2 ou 3.
                                , ioFinancialAccountId   => ioFinancialId
                                , ioDivisionAccountId    => ioDivisionId
                                , ioCPNAccountId         => ioCpnId
                                , ioCDAAccountId         => ioCdaId
                                , ioPFAccountId          => ioPfId
                                , ioPJAccountId          => ioPjId
                                 );

        ----
        -- Inscrit éventuellement le résultat de la recherche des comptes dans la
        -- table DOC_UPDATE_HISTORY
        --
        if (nvl(iPositionId, 0) = 0) then
          WriteInformation(iDocumentId, 'Taxe de pied ' || iCurId);
        else
          WriteInformation(iDocumentId, 'Taxe de position ' || iCurId);
        end if;
      elsif(iElementType = cgEtCosts) then   -- Frais
        ----
        -- Procédure de détermination du compte financier et du compte division pour
        -- toutes les imputations des frais.
        --
        DefineFinancialImputation(iCode                  => 6   -- Frais
                                , iGaugeId               => iGaugeId   -- Gabarit. Utilisé pour contrôler la gestion des comptes.
                                , iAdminDomain           => iAdminDomain   -- Domain. Utilisé uniquement avec iCode = 2 ou 3.
                                , ioFinancialAccountId   => ioFinancialId
                                , ioDivisionAccountId    => ioDivisionId
                                , ioCPNAccountId         => ioCpnId
                                , ioCDAAccountId         => ioCdaId
                                , ioPFAccountId          => ioPfId
                                , ioPJAccountId          => ioPjId
                                 );
        ----
        -- Inscrit éventuellement le résultat de la recherche des comptes dans la
        -- table DOC_UPDATE_HISTORY
        --
        WriteInformation(iDocumentId, 'Frais');
      end if;

      ----
      -- Contrôle si les imputations (centre d'analyse, porteur et projet) avec la
      -- charge par nature sont autorisées.
      --
      CheckAccountPermission(ioFinancialId, ioDivisionId, ioCpnId, ioCdaId, ioPfId, ioPjId, iDateRef);
    else   -- Pas de gestion ou d'initialisation des comptes
      ioFinancialId                     := null;
      ioDivisionId                      := null;
      ioCpnId                           := null;
      ioCdaId                           := null;
      ioPfId                            := null;
      ioPjId                            := null;
      iotAccountInfo.DEF_HRM_PERSON     := null;
      iotAccountInfo.DEF_NUMBER1        := null;
      iotAccountInfo.DEF_NUMBER2        := null;
      iotAccountInfo.DEF_NUMBER3        := null;
      iotAccountInfo.DEF_NUMBER4        := null;
      iotAccountInfo.DEF_NUMBER5        := null;
      iotAccountInfo.DEF_TEXT1          := null;
      iotAccountInfo.DEF_TEXT2          := null;
      iotAccountInfo.DEF_TEXT3          := null;
      iotAccountInfo.DEF_TEXT4          := null;
      iotAccountInfo.DEF_TEXT5          := null;
      iotAccountInfo.DEF_DIC_IMP_FREE1  := null;
      iotAccountInfo.DEF_DIC_IMP_FREE2  := null;
      iotAccountInfo.DEF_DIC_IMP_FREE3  := null;
      iotAccountInfo.DEF_DIC_IMP_FREE4  := null;
      iotAccountInfo.DEF_DIC_IMP_FREE5  := null;
      iotAccountInfo.DEF_DATE1          := null;
      iotAccountInfo.DEF_DATE2          := null;
      iotAccountInfo.DEF_DATE3          := null;
      iotAccountInfo.DEF_DATE4          := null;
      iotAccountInfo.DEF_DATE5          := null;
    end if;   -- ( lFinancial = 1 ) or ( lAnalytical = 1 )
  end GetDCAccounts;

   /**
  * Procedure GetMvtAccounts
  * Description
  *   Procédure de recherche des comptes liés au mouvement de stock
  * @created Fabrice Perotto 12.02.2001
  * @public
  * @param iGoodId         Bien
  * @param iLocationId     Emplacement de stock
  * @param iStockId        Stock
  * @param iMovementKindId Genre de mouvement
  * @param iPositionId     Position
  * @param iDocumentId     Document
  * @param iDateRef        Date du mouvement
  * @param ioFinAccountId   Compte financier bilan
  * @param ioDivAccountId   Compte division bilan
  * @param ioCpnAccountId   Charge par nature bilan
  * @param ioCdaAccountId   Centre d'analyse bilan
  * @param ioPfAccountId    Porteur bilan
  * @param ioPjAccountId    Projet bilan
  * @param ioFinAccountId2  Compte financier résultat
  * @param ioivAccountId2  Compte division résultat
  * @param ioCpnAccountId2  Charge par nature résultat
  * @param ioCdaAccountId2  Centre d'analyse résultat
  * @param ioPfAccountId2   Porteur résultat
  * @param ioPjAccountId2   Projet résultat
  * @param iotAccountInfo    Record contenant les informations complémentaires des imputations bilans
  * @param iotAccountInfo2   Record contenant les informations complémentaires des imputations résultats
  * @param iobFinancial      Gestion de l'imputation financière
  * @param iobAnalytical     Gestion de l'imputation analytique
  * @param iobInfoCompl      Gestion des axes complémentaires
  */
  procedure GetMvtAccounts(
    iGoodId         in     number
  , iLocationId     in     number
  , iStockId        in     number
  , iMovementKindId in     number
  , iPositionId     in     number
  , iDocumentId     in     number
  , iDateRef        in     date
  , ioFinAccountId  in out number
  , ioDivAccountId  in out number
  , ioCpnAccountId  in out number
  , ioCdaAccountId  in out number
  , ioPfAccountId   in out number
  , ioPjAccountId   in out number
  , ioFinAccountId2 in out number
  , ioDivAccountId2 in out number
  , ioCpnAccountId2 in out number
  , ioCdaAccountId2 in out number
  , ioPfAccountId2  in out number
  , ioPjAccountId2  in out number
  , iotAccountInfo  in out TAccountInfo
  , iotAccountInfo2 in out TAccountInfo
  , obFinancial     out    number
  , obAnalytical    out    number
  , obInfoCompl     out    number
  , iThirdId        in     number default null
  )
  is
    vEntityMovement FWK_I_TYP_STM_ENTITY.tStockMovement;
  begin
    vEntityMovement.GCO_GOOD_ID                   := iGoodID;
    vEntityMovement.STM_STOCK_ID                  := iStockId;
    vEntityMovement.STM_LOCATION_ID               := iLocationId;
    vEntityMovement.STM_MOVEMENT_KIND_ID          := iMovementKindId;
    vEntityMovement.DOC_POSITION_ID               := iPositionId;
    vEntityMovement.SMO_MOVEMENT_DATE             := iDateRef;
    vEntityMovement.PAC_THIRD_ID                  := iThirdId;
    vEntityMovement.ACS_FINANCIAL_ACCOUNT_ID      := ioFinAccountId;
    vEntityMovement.ACS_DIVISION_ACCOUNT_ID       := ioDivAccountId;
    vEntityMovement.ACS_CPN_ACCOUNT_ID            := ioCpnAccountId;
    vEntityMovement.ACS_CDA_ACCOUNT_ID            := ioCdaAccountId;
    vEntityMovement.ACS_PF_ACCOUNT_ID             := ioPfAccountId;
    vEntityMovement.ACS_PJ_ACCOUNT_ID             := ioPjAccountId;
    vEntityMovement.ACS_ACS_FINANCIAL_ACCOUNT_ID  := ioFinAccountId2;
    vEntityMovement.ACS_ACS_DIVISION_ACCOUNT_ID   := ioDivAccountId2;
    vEntityMovement.ACS_ACS_CPN_ACCOUNT_ID        := ioCpnAccountId2;
    vEntityMovement.ACS_ACS_CDA_ACCOUNT_ID        := ioCdaAccountId2;
    vEntityMovement.ACS_ACS_PF_ACCOUNT_ID         := ioPfAccountId2;
    vEntityMovement.ACS_ACS_PJ_ACCOUNT_ID         := ioPjAccountId2;
    GetMvtAccounts(vEntityMovement, iDocumentId, iotAccountInfo, iotAccountInfo2, obFinancial, obAnalytical, obInfoCompl);
    ioFinAccountId                                := vEntityMovement.ACS_FINANCIAL_ACCOUNT_ID;
    ioDivAccountId                                := vEntityMovement.ACS_DIVISION_ACCOUNT_ID;
    ioCpnAccountId                                := vEntityMovement.ACS_CPN_ACCOUNT_ID;
    ioCdaAccountId                                := vEntityMovement.ACS_CDA_ACCOUNT_ID;
    ioPfAccountId                                 := vEntityMovement.ACS_PF_ACCOUNT_ID;
    ioPjAccountId                                 := vEntityMovement.ACS_PJ_ACCOUNT_ID;
    ioFinAccountId2                               := vEntityMovement.ACS_ACS_FINANCIAL_ACCOUNT_ID;
    ioDivAccountId2                               := vEntityMovement.ACS_ACS_DIVISION_ACCOUNT_ID;
    ioCpnAccountId2                               := vEntityMovement.ACS_ACS_CPN_ACCOUNT_ID;
    ioCdaAccountId2                               := vEntityMovement.ACS_ACS_CDA_ACCOUNT_ID;
    ioPfAccountId2                                := vEntityMovement.ACS_ACS_PF_ACCOUNT_ID;
    ioPjAccountId2                                := vEntityMovement.ACS_ACS_PJ_ACCOUNT_ID;
  end GetMvtAccounts;

  /**
  * Procedure GetMvtAccounts
  * Description
  *   Procédure de recherche des comptes liés au mouvement de stock
  * @created Fabrice Perotto 12.02.2001
  * @public
  * @param iotMovementRecord tuple du mouvement
  * @param iDocumentId     id du document
  * @param iotAccountInfo    Record contenant les informations complémentaires des imputations bilans
  * @param iotAccountInfo2   Record contenant les informations complémentaires des imputations résultats
  * @param obFinancial      Gestion de l'imputation financière
  * @param obAnalytical     Gestion de l'imputation analytique
  * @param obInfoCompl      Gestion des axes complémentaires
  */
  procedure GetMvtAccounts(
    iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement
  , iDocumentId       in     number
  , iotAccountInfo    in out tAccountInfo
  , iotAccountInfo2   in out tAccountInfo
  , obFinancial       out    number
  , obAnalytical      out    number
  , obInfoCompl       out    number
  )
  is
    lAdminDomain               DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lThirdId                   PAC_THIRD.PAC_THIRD_ID%type;
    lLocationAccountManagement STM_LOCATION.LOC_CONTINUOUS_INVENTAR%type;
  begin
    /**
    * Vérifie la gestion des comptes dans le genre de mouvement
    */
    select nvl(MOK.MOK_FINANCIAL_IMPUTATION, 0)
         , nvl(MOK.MOK_ANAL_IMPUTATION, 0)
         , nvl(MOK.MOK_USE_MANAGED_DATA, 0)
      into obFinancial
         , obAnalytical
         , obInfoCompl
      from STM_MOVEMENT_KIND MOK
     where MOK.STM_MOVEMENT_KIND_ID = iotMovementRecord.STM_MOVEMENT_KIND_ID;

    select nvl(max(LOC.LOC_CONTINUOUS_INVENTAR), 0)
      into lLocationAccountManagement
      from STM_LOCATION LOC
     where LOC.STM_LOCATION_ID = iotMovementRecord.STM_LOCATION_ID;

    /* Si gestion ou initialisation des comptes financiers ou analytiques */
    if     (    (obFinancial = 1)
            or (obAnalytical = 1) )
       and (lLocationAccountManagement = 1) then
      /* Recherche le domaine. Si le document n'est pas spécifié, on considère
         le domaine est 'Stock' (mouvements manuels). */
      if iDocumentId is null then
        lAdminDomain  := '3';   -- Stock
        lThirdId      := iotMovementRecord.PAC_THIRD_ID;
      else
        select GAU.C_ADMIN_DOMAIN
             , DMT.PAC_THIRD_ID
          into lAdminDomain
             , lThirdId
          from DOC_GAUGE GAU
             , DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = iDocumentId
           and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID;
      end if;

      /**
      * Traitement des comptes bilan
      */

      /**
       * Recherche des comptes (bilan)
       * iOverride => 0 permet de ne pas écraser les paramètres iOut pré-initialisé
       */
      SearchAccounts(iElementId          => iotMovementRecord.GCO_GOOD_ID
                   , iElementType        => cgEtGoodsStock
                   , iAdminDomain        => '3'
                   , iDateRef            => iotMovementRecord.SMO_MOVEMENT_DATE
                   , iStockId            => iotMovementRecord.STM_STOCK_ID
                   , iPositionId         => iotMovementRecord.DOC_POSITION_ID
                   , iDocumentId         => iDocumentId
                   , iThirdId            => lThirdId
                   , iThirdAdminDomain   => lAdminDomain
                   , ioFinancialId       => iotMovementRecord.ACS_FINANCIAL_ACCOUNT_ID
                   , ioDivisionId        => iotMovementRecord.ACS_DIVISION_ACCOUNT_ID
                   , ioCpnId             => iotMovementRecord.ACS_CPN_ACCOUNT_ID
                   , ioCdaId             => iotMovementRecord.ACS_CDA_ACCOUNT_ID
                   , ioPfId              => iotMovementRecord.ACS_PF_ACCOUNT_ID
                   , ioPjId              => iotMovementRecord.ACS_PJ_ACCOUNT_ID
                   , iotAccountInfo      => iotAccountInfo
                   , obInfoCompl         => obInfoCompl
                   , iInfoDescrDetail    => '(bilan)'
                   , iOverride           => 0
                    );
      /**
       * Recherche des comptes (résultat)
       * iOverride => 0 permet de ne pas écraser les paramètres iOut pré-initialisé
       */
      SearchAccounts(iElementId          => iotMovementRecord.GCO_GOOD_ID
                   , iElementType        => cgEtGoodsStockMov
                   , iAdminDomain        => '3'
                   , iDateRef            => iotMovementRecord.SMO_MOVEMENT_DATE
                   , iMovementKindId     => iotMovementRecord.STM_MOVEMENT_KIND_ID
                   , iPositionId         => iotMovementRecord.DOC_POSITION_ID
                   , iDocumentId         => iDocumentId
                   , iThirdId            => lThirdId
                   , iThirdAdminDomain   => lAdminDomain
                   , ioFinancialId       => iotMovementRecord.ACS_ACS_FINANCIAL_ACCOUNT_ID
                   , ioDivisionId        => iotMovementRecord.ACS_ACS_DIVISION_ACCOUNT_ID
                   , ioCpnId             => iotMovementRecord.ACS_ACS_CPN_ACCOUNT_ID
                   , ioCdaId             => iotMovementRecord.ACS_ACS_CDA_ACCOUNT_ID
                   , ioPfId              => iotMovementRecord.ACS_ACS_PF_ACCOUNT_ID
                   , ioPjId              => iotMovementRecord.ACS_ACS_PJ_ACCOUNT_ID
                   , iotAccountInfo      => iotAccountInfo2
                   , obInfoCompl         => obInfoCompl
                   , iInfoDescrDetail    => '(résultat)'
                   , iOverride           => 0
                    );
      ----
      -- Procédure de détermination du compte financier et du compte division pour
      -- toutes les imputations des mouvements de stock. Compte bilan
      --
      DefineFinancialImputation(iCode                  => 7   -- Imputations mouvement de stock (compte bilan)
                              , iLocationId            => iotMovementRecord.STM_LOCATION_ID   -- Emplacement de stock logique. Utilisé uniquement avec iCode = 7.
                              , iStockId               => iotMovementRecord.STM_STOCK_ID   -- Stock logique. Utilisé uniquement avec iCode = 7.
                              , iMovementKindId        => iotMovementRecord.STM_MOVEMENT_KIND_ID   -- Genre de mouvement. Utilisé uniquement avec iCode = 8.
                              , ioFinancialAccountId   => iotMovementRecord.ACS_FINANCIAL_ACCOUNT_ID
                              , ioDivisionAccountId    => iotMovementRecord.ACS_DIVISION_ACCOUNT_ID
                              , ioCPNAccountId         => iotMovementRecord.ACS_CPN_ACCOUNT_ID
                              , ioCDAAccountId         => iotMovementRecord.ACS_CDA_ACCOUNT_ID
                              , ioPFAccountId          => iotMovementRecord.ACS_PF_ACCOUNT_ID
                              , ioPJAccountId          => iotMovementRecord.ACS_PJ_ACCOUNT_ID
                               );
      ----
      -- Contrôle si les imputations (centre d'analyse, porteur et projet) avec la
      -- charge par nature sont autorisées.
      --
      CheckAccountPermission(iotMovementRecord.ACS_FINANCIAL_ACCOUNT_ID
                           , iotMovementRecord.ACS_DIVISION_ACCOUNT_ID
                           , iotMovementRecord.ACS_CPN_ACCOUNT_ID
                           , iotMovementRecord.ACS_CDA_ACCOUNT_ID
                           , iotMovementRecord.ACS_PF_ACCOUNT_ID
                           , iotMovementRecord.ACS_PJ_ACCOUNT_ID
                           , iotMovementRecord.SMO_MOVEMENT_DATE
                            );
      ----
      -- Procédure de détermination du compte financier et du compte division pour
      -- toutes les imputations des mouvements de stock. Compte résultat
      --
      DefineFinancialImputation(iCode                  => 8   -- Imputations mouvement de stock (compte résultat)
                              , iMovementKindId        => iotMovementRecord.STM_MOVEMENT_KIND_ID   -- Genre de mouvement. Utilisé uniquement avec iCode = 8.
                              , ioFinancialAccountId   => iotMovementRecord.ACS_ACS_FINANCIAL_ACCOUNT_ID
                              , ioDivisionAccountId    => iotMovementRecord.ACS_ACS_DIVISION_ACCOUNT_ID
                              , ioCPNAccountId         => iotMovementRecord.ACS_ACS_CPN_ACCOUNT_ID
                              , ioCDAAccountId         => iotMovementRecord.ACS_ACS_CDA_ACCOUNT_ID
                              , ioPFAccountId          => iotMovementRecord.ACS_ACS_PF_ACCOUNT_ID
                              , ioPJAccountId          => iotMovementRecord.ACS_ACS_PJ_ACCOUNT_ID
                               );
      ----
      -- Contrôle si les imputations (centre d'analyse, porteur et projet) avec la
      -- charge par nature sont autorisées.
      --
      CheckAccountPermission(iotMovementRecord.ACS_ACS_FINANCIAL_ACCOUNT_ID
                           , iotMovementRecord.ACS_ACS_DIVISION_ACCOUNT_ID
                           , iotMovementRecord.ACS_ACS_CPN_ACCOUNT_ID
                           , iotMovementRecord.ACS_ACS_CDA_ACCOUNT_ID
                           , iotMovementRecord.ACS_ACS_PF_ACCOUNT_ID
                           , iotMovementRecord.ACS_ACS_PJ_ACCOUNT_ID
                           , iotMovementRecord.SMO_MOVEMENT_DATE
                            );
      ----
      -- Inscrit éventuellement le résultat de la recherche des comptes dans la
      -- table DOC_UPDATE_HISTORY
      --
      WriteInformation(iDocumentId, 'Mouvement de stock ' || iotMovementRecord.GCO_GOOD_ID);
    else   -- Pas de gestion ou d'initialisation des comptes
      iotMovementRecord.ACS_FINANCIAL_ACCOUNT_ID      := null;
      iotMovementRecord.ACS_DIVISION_ACCOUNT_ID       := null;
      iotMovementRecord.ACS_CPN_ACCOUNT_ID            := null;
      iotMovementRecord.ACS_CDA_ACCOUNT_ID            := null;
      iotMovementRecord.ACS_PF_ACCOUNT_ID             := null;
      iotMovementRecord.ACS_PJ_ACCOUNT_ID             := null;
      iotMovementRecord.ACS_ACS_FINANCIAL_ACCOUNT_ID  := null;
      iotMovementRecord.ACS_ACS_DIVISION_ACCOUNT_ID   := null;
      iotMovementRecord.ACS_ACS_CPN_ACCOUNT_ID        := null;
      iotMovementRecord.ACS_ACS_CDA_ACCOUNT_ID        := null;
      iotMovementRecord.ACS_ACS_PF_ACCOUNT_ID         := null;
      iotMovementRecord.ACS_ACS_PJ_ACCOUNT_ID         := null;
      iotAccountInfo.DEF_HRM_PERSON                   := null;
      iotAccountInfo.DEF_NUMBER1                      := null;
      iotAccountInfo.DEF_NUMBER2                      := null;
      iotAccountInfo.DEF_NUMBER3                      := null;
      iotAccountInfo.DEF_NUMBER4                      := null;
      iotAccountInfo.DEF_NUMBER5                      := null;
      iotAccountInfo.DEF_TEXT1                        := null;
      iotAccountInfo.DEF_TEXT2                        := null;
      iotAccountInfo.DEF_TEXT3                        := null;
      iotAccountInfo.DEF_TEXT4                        := null;
      iotAccountInfo.DEF_TEXT5                        := null;
      iotAccountInfo.DEF_DIC_IMP_FREE1                := null;
      iotAccountInfo.DEF_DIC_IMP_FREE2                := null;
      iotAccountInfo.DEF_DIC_IMP_FREE3                := null;
      iotAccountInfo.DEF_DIC_IMP_FREE4                := null;
      iotAccountInfo.DEF_DIC_IMP_FREE5                := null;
      iotAccountInfo.DEF_DATE1                        := null;
      iotAccountInfo.DEF_DATE2                        := null;
      iotAccountInfo.DEF_DATE3                        := null;
      iotAccountInfo.DEF_DATE4                        := null;
      iotAccountInfo.DEF_DATE5                        := null;
      iotAccountInfo2.DEF_HRM_PERSON                  := null;
      iotAccountInfo2.DEF_NUMBER1                     := null;
      iotAccountInfo2.DEF_NUMBER2                     := null;
      iotAccountInfo2.DEF_NUMBER3                     := null;
      iotAccountInfo2.DEF_NUMBER4                     := null;
      iotAccountInfo2.DEF_NUMBER5                     := null;
      iotAccountInfo2.DEF_TEXT1                       := null;
      iotAccountInfo2.DEF_TEXT2                       := null;
      iotAccountInfo2.DEF_TEXT3                       := null;
      iotAccountInfo2.DEF_TEXT4                       := null;
      iotAccountInfo2.DEF_TEXT5                       := null;
      iotAccountInfo2.DEF_DIC_IMP_FREE1               := null;
      iotAccountInfo2.DEF_DIC_IMP_FREE2               := null;
      iotAccountInfo2.DEF_DIC_IMP_FREE3               := null;
      iotAccountInfo2.DEF_DIC_IMP_FREE4               := null;
      iotAccountInfo2.DEF_DIC_IMP_FREE5               := null;
      iotAccountInfo2.DEF_DATE1                       := null;
      iotAccountInfo2.DEF_DATE2                       := null;
      iotAccountInfo2.DEF_DATE3                       := null;
      iotAccountInfo2.DEF_DATE4                       := null;
      iotAccountInfo2.DEF_DATE5                       := null;
    end if;   -- ( obFinancial = 1 ) or ( obAnalytical = 1 ) and (lLocationAccountManagement = 1)
  end GetMvtAccounts;

  /**
  * Description
  *   Procédure de recherche des comptes liés au mouvement de stock
  */
  procedure generatePermanentInventory(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lDocumentId                DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lAccountInfo               tAccountInfo;
    lAccountInfo2              tAccountInfo;
    lFinancial                 STM_MOVEMENT_KIND.MOK_FINANCIAL_IMPUTATION%type;
    lAnalytical                STM_MOVEMENT_KIND.MOK_ANAL_IMPUTATION%type;
    lInfoCompl                 STM_MOVEMENT_KIND.MOK_USE_MANAGED_DATA%type;
    lMovementType              STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lMovementCode              STM_MOVEMENT_KIND.C_MOVEMENT_CODE%type;
    lSearchAccounts            number(1);
    lLocationAccountManagement STM_LOCATION.LOC_CONTINUOUS_INVENTAR%type;
    lGapPurchasePrice          DOC_POSITION_DETAIL.PDE_GAP_PURCHASE_PRICE%type;
    lManagementMode            GCO_GOOD.C_MANAGEMENT_MODE%type;
    tplPositionDetail          DOC_POSITION_DETAIL%rowtype;
    lFinancialCharging         STM_MOVEMENT_KIND.MOK_FINANCIAL_IMPUTATION%type;
  begin
    select C_MOVEMENT_TYPE
         , C_MOVEMENT_CODE
         , MOK_FINANCIAL_IMPUTATION
      into lMovementType
         , lMovementCode
         , lFinancialCharging
      from STM_MOVEMENT_KIND
     where STM_MOVEMENT_KIND_ID = iotMovementRecord.STM_MOVEMENT_KIND_ID;

    if PCS.PC_CONFIG.GetBooleanConfig('STM_FINANCIAL_CHARGING') then
      iotMovementRecord.SMO_FINANCIAL_CHARGING  := nvl(iotMovementRecord.SMO_FINANCIAL_CHARGING, lFinancialCharging);
    else
      iotMovementRecord.SMO_FINANCIAL_CHARGING  := 0;
    end if;

    -- Vérifie si l'emplacement de stock autorise l'inventaire permanent.
    lLocationAccountManagement  := 1;

    if iotMovementRecord.STM_LOCATION_ID is not null then
      select nvl(max(LOC.LOC_CONTINUOUS_INVENTAR), 0)
        into lLocationAccountManagement
        from STM_LOCATION LOC
       where LOC.STM_LOCATION_ID = iotMovementRecord.STM_LOCATION_ID;
    end if;

    -- Ecart d'achat
    lGapPurchasePrice           := null;

    if (lLocationAccountManagement = 1) then
      /* Mouvement issu d'une document et pas un mouvement d'extourne.
         ou
         Mouvement d'Inventaire
         ou
         Mouvement de correction du PRF en inventaire permanent
         ou
         Mouvement de fabrication
      */
      lSearchAccounts                      := 1;

      if iotMovementRecord.DOC_POSITION_DETAIL_ID is not null then
        select *
          into tplPositionDetail
          from DOC_POSITION_DETAIL
         where DOC_POSITION_DETAIL_ID = iotMovementRecord.DOC_POSITION_DETAIL_ID;

        lGapPurchasePrice  := tplPositionDetail.PDE_GAP_PURCHASE_PRICE;

        if     (nvl(iotMovementRecord.A_RECSTATUS, 1) = 5)
           and iotMovementRecord.STM_STM_STOCK_MOVEMENT_ID is not null
           and tplPositionDetail.STM_LOCATION_ID <> tplPositionDetail.STM_STM_LOCATION_ID then
          -- Dans le cas de la création du mouvement de transfert, il faut effectuer la recherche des
          -- comptes. En effet, les comptes associés au mouvement de tranfert ne sont pas présent sur le détail
          -- de position (pour l'instant). Par contre, si l'emplacement source est identique à l'emplacement cible,
          -- je considère que les comptes sur le détail sont valable pour le mouvement de transfert.
          lSearchAccounts  := 1;
        elsif(    iotMovementRecord.DOC_POSITION_DETAIL_ID is not null
              and (nvl(iotMovementRecord.SMO_EXTOURNE_MVT, 0) = 1) ) then
          -- Dans le contexte d'un mouvement d'extourne, il ne faut pas rechercher les comptes. En effet, ils
          -- sont repris intégralement du mouvement à extourner.
          lSearchAccounts  := 0;
        elsif    tplPositionDetail.ACS_FINANCIAL_ACCOUNT_BS_ID is not null
              or tplPositionDetail.ACS_DIVISION_ACCOUNT_BS_ID is not null
              or tplPositionDetail.ACS_CPN_ACCOUNT_BS_ID is not null
              or tplPositionDetail.ACS_CDA_ACCOUNT_BS_ID is not null
              or tplPositionDetail.ACS_PF_ACCOUNT_BS_ID is not null
              or tplPositionDetail.ACS_PJ_ACCOUNT_BS_ID is not null
              or tplPositionDetail.ACS_FINANCIAL_ACCOUNT_PL_ID is not null
              or tplPositionDetail.ACS_DIVISION_ACCOUNT_PL_ID is not null
              or tplPositionDetail.ACS_CPN_ACCOUNT_PL_ID is not null
              or tplPositionDetail.ACS_CDA_ACCOUNT_PL_ID is not null
              or tplPositionDetail.ACS_PF_ACCOUNT_PL_ID is not null
              or tplPositionDetail.ACS_PJ_ACCOUNT_PL_ID is not null then
          iotMovementRecord.ACS_FINANCIAL_ACCOUNT_ID      := tplPositionDetail.ACS_FINANCIAL_ACCOUNT_BS_ID;
          iotMovementRecord.ACS_DIVISION_ACCOUNT_ID       := tplPositionDetail.ACS_DIVISION_ACCOUNT_BS_ID;
          iotMovementRecord.ACS_CPN_ACCOUNT_ID            := tplPositionDetail.ACS_CPN_ACCOUNT_BS_ID;
          iotMovementRecord.ACS_CDA_ACCOUNT_ID            := tplPositionDetail.ACS_CDA_ACCOUNT_BS_ID;
          iotMovementRecord.ACS_PF_ACCOUNT_ID             := tplPositionDetail.ACS_PF_ACCOUNT_BS_ID;
          iotMovementRecord.ACS_PJ_ACCOUNT_ID             := tplPositionDetail.ACS_PJ_ACCOUNT_BS_ID;
          iotMovementRecord.ACS_ACS_FINANCIAL_ACCOUNT_ID  := tplPositionDetail.ACS_FINANCIAL_ACCOUNT_PL_ID;
          iotMovementRecord.ACS_ACS_DIVISION_ACCOUNT_ID   := tplPositionDetail.ACS_DIVISION_ACCOUNT_PL_ID;
          iotMovementRecord.ACS_ACS_CPN_ACCOUNT_ID        := tplPositionDetail.ACS_CPN_ACCOUNT_PL_ID;
          iotMovementRecord.ACS_ACS_CDA_ACCOUNT_ID        := tplPositionDetail.ACS_CDA_ACCOUNT_PL_ID;
          iotMovementRecord.ACS_ACS_PF_ACCOUNT_ID         := tplPositionDetail.ACS_PF_ACCOUNT_PL_ID;
          iotMovementRecord.ACS_ACS_PJ_ACCOUNT_ID         := tplPositionDetail.ACS_PJ_ACCOUNT_PL_ID;
          iotMovementRecord.FAM_FIXED_ASSETS_ID           := tplPositionDetail.FAM_FIXED_ASSETS_ID;
          iotMovementRecord.C_FAM_TRANSACTION_TYP         := tplPositionDetail.C_FAM_TRANSACTION_TYP;
          iotMovementRecord.HRM_PERSON_ID                 := tplPositionDetail.HRM_PERSON_ID;
          iotMovementRecord.DIC_IMP_FREE1_ID              := tplPositionDetail.DIC_IMP_FREE1_ID;
          iotMovementRecord.DIC_IMP_FREE2_ID              := tplPositionDetail.DIC_IMP_FREE2_ID;
          iotMovementRecord.DIC_IMP_FREE3_ID              := tplPositionDetail.DIC_IMP_FREE3_ID;
          iotMovementRecord.DIC_IMP_FREE4_ID              := tplPositionDetail.DIC_IMP_FREE4_ID;
          iotMovementRecord.DIC_IMP_FREE5_ID              := tplPositionDetail.DIC_IMP_FREE5_ID;
          iotMovementRecord.SMO_IMP_TEXT_1                := tplPositionDetail.PDE_IMF_TEXT_1;
          iotMovementRecord.SMO_IMP_TEXT_2                := tplPositionDetail.PDE_IMF_TEXT_2;
          iotMovementRecord.SMO_IMP_TEXT_3                := tplPositionDetail.PDE_IMF_TEXT_3;
          iotMovementRecord.SMO_IMP_TEXT_4                := tplPositionDetail.PDE_IMF_TEXT_4;
          iotMovementRecord.SMO_IMP_TEXT_5                := tplPositionDetail.PDE_IMF_TEXT_5;
          iotMovementRecord.SMO_IMP_NUMBER_1              := tplPositionDetail.PDE_IMF_NUMBER_1;
          iotMovementRecord.SMO_IMP_NUMBER_2              := tplPositionDetail.PDE_IMF_NUMBER_2;
          iotMovementRecord.SMO_IMP_NUMBER_3              := tplPositionDetail.PDE_IMF_NUMBER_3;
          iotMovementRecord.SMO_IMP_NUMBER_4              := tplPositionDetail.PDE_IMF_NUMBER_4;
          iotMovementRecord.SMO_IMP_NUMBER_5              := tplPositionDetail.PDE_IMF_NUMBER_5;
          iotMovementRecord.SMO_IMP_DATE_1                := tplPositionDetail.PDE_IMF_DATE_1;
          iotMovementRecord.SMO_IMP_DATE_2                := tplPositionDetail.PDE_IMF_DATE_2;
          iotMovementRecord.SMO_IMP_DATE_3                := tplPositionDetail.PDE_IMF_DATE_3;
          iotMovementRecord.SMO_IMP_DATE_4                := tplPositionDetail.PDE_IMF_DATE_4;
          iotMovementRecord.SMO_IMP_DATE_5                := tplPositionDetail.PDE_IMF_DATE_5;
          -- iotMovementRecord.DOC_RECORD_ID := tplPositionDetail.DOC_RECORD_BS_ID;
          lSearchAccounts                                 := 0;
        end if;
      end if;

      lAccountInfo.DEF_HRM_PERSON          := GetEmpNumber(iotMovementRecord.HRM_PERSON_ID);
      lAccountInfo.FAM_FIXED_ASSETS_ID     := iotMovementRecord.FAM_FIXED_ASSETS_ID;
      lAccountInfo.C_FAM_TRANSACTION_TYP   := iotMovementRecord.C_FAM_TRANSACTION_TYP;
      lAccountInfo.DEF_DIC_IMP_FREE1       := iotMovementRecord.DIC_IMP_FREE1_ID;
      lAccountInfo.DEF_DIC_IMP_FREE2       := iotMovementRecord.DIC_IMP_FREE2_ID;
      lAccountInfo.DEF_DIC_IMP_FREE3       := iotMovementRecord.DIC_IMP_FREE3_ID;
      lAccountInfo.DEF_DIC_IMP_FREE4       := iotMovementRecord.DIC_IMP_FREE4_ID;
      lAccountInfo.DEF_DIC_IMP_FREE5       := iotMovementRecord.DIC_IMP_FREE5_ID;
      lAccountInfo.DEF_TEXT1               := iotMovementRecord.SMO_IMP_TEXT_1;
      lAccountInfo.DEF_TEXT2               := iotMovementRecord.SMO_IMP_TEXT_2;
      lAccountInfo.DEF_TEXT3               := iotMovementRecord.SMO_IMP_TEXT_3;
      lAccountInfo.DEF_TEXT4               := iotMovementRecord.SMO_IMP_TEXT_4;
      lAccountInfo.DEF_TEXT5               := iotMovementRecord.SMO_IMP_TEXT_5;
      lAccountInfo.DEF_NUMBER1             := to_char(iotMovementRecord.SMO_IMP_NUMBER_1);
      lAccountInfo.DEF_NUMBER2             := to_char(iotMovementRecord.SMO_IMP_NUMBER_2);
      lAccountInfo.DEF_NUMBER3             := to_char(iotMovementRecord.SMO_IMP_NUMBER_3);
      lAccountInfo.DEF_NUMBER4             := to_char(iotMovementRecord.SMO_IMP_NUMBER_4);
      lAccountInfo.DEF_NUMBER5             := to_char(iotMovementRecord.SMO_IMP_NUMBER_5);
      lAccountInfo.DEF_DATE1               := iotMovementRecord.SMO_IMP_DATE_1;
      lAccountInfo.DEF_DATE2               := iotMovementRecord.SMO_IMP_DATE_2;
      lAccountInfo.DEF_DATE3               := iotMovementRecord.SMO_IMP_DATE_3;
      lAccountInfo.DEF_DATE4               := iotMovementRecord.SMO_IMP_DATE_4;
      lAccountInfo.DEF_DATE5               := iotMovementRecord.SMO_IMP_DATE_5;
      lAccountInfo2.DEF_HRM_PERSON         := GetEmpNumber(iotMovementRecord.HRM_PERSON_ID);
      lAccountInfo2.FAM_FIXED_ASSETS_ID    := iotMovementRecord.FAM_FIXED_ASSETS_ID;
      lAccountInfo2.C_FAM_TRANSACTION_TYP  := iotMovementRecord.C_FAM_TRANSACTION_TYP;
      lAccountInfo2.DEF_DIC_IMP_FREE1      := iotMovementRecord.DIC_IMP_FREE1_ID;
      lAccountInfo2.DEF_DIC_IMP_FREE2      := iotMovementRecord.DIC_IMP_FREE2_ID;
      lAccountInfo2.DEF_DIC_IMP_FREE3      := iotMovementRecord.DIC_IMP_FREE3_ID;
      lAccountInfo2.DEF_DIC_IMP_FREE4      := iotMovementRecord.DIC_IMP_FREE4_ID;
      lAccountInfo2.DEF_DIC_IMP_FREE5      := iotMovementRecord.DIC_IMP_FREE5_ID;
      lAccountInfo2.DEF_TEXT1              := iotMovementRecord.SMO_IMP_TEXT_1;
      lAccountInfo2.DEF_TEXT2              := iotMovementRecord.SMO_IMP_TEXT_2;
      lAccountInfo2.DEF_TEXT3              := iotMovementRecord.SMO_IMP_TEXT_3;
      lAccountInfo2.DEF_TEXT4              := iotMovementRecord.SMO_IMP_TEXT_4;
      lAccountInfo2.DEF_TEXT5              := iotMovementRecord.SMO_IMP_TEXT_5;
      lAccountInfo2.DEF_NUMBER1            := to_char(iotMovementRecord.SMO_IMP_NUMBER_1);
      lAccountInfo2.DEF_NUMBER2            := to_char(iotMovementRecord.SMO_IMP_NUMBER_2);
      lAccountInfo2.DEF_NUMBER3            := to_char(iotMovementRecord.SMO_IMP_NUMBER_3);
      lAccountInfo2.DEF_NUMBER4            := to_char(iotMovementRecord.SMO_IMP_NUMBER_4);
      lAccountInfo2.DEF_NUMBER5            := to_char(iotMovementRecord.SMO_IMP_NUMBER_5);
      lAccountInfo2.DEF_DATE1              := iotMovementRecord.SMO_IMP_DATE_1;
      lAccountInfo2.DEF_DATE2              := iotMovementRecord.SMO_IMP_DATE_2;
      lAccountInfo2.DEF_DATE3              := iotMovementRecord.SMO_IMP_DATE_3;
      lAccountInfo2.DEF_DATE4              := iotMovementRecord.SMO_IMP_DATE_4;
      lAccountInfo2.DEF_DATE5              := iotMovementRecord.SMO_IMP_DATE_5;

      if        (lSearchAccounts = 1)
            and (    iotMovementRecord.DOC_POSITION_ID is not null
                 and (nvl(iotMovementRecord.SMO_EXTOURNE_MVT, 0) = 0) )
         or (iotMovementRecord.DOC_FOOT_ALLOY_ID is not null)
         or (lMovementType = 'INV')
         or (lMovementCode = '014')
         or (lMovementCode = '017')
         or (lMovementCode = '018')
         or (lMovementCode = '019')
         or (lMovementCode = '020')
         or (lMovementCode = '023')
         or (    iotMovementRecord.ACS_FINANCIAL_ACCOUNT_ID is null
             and iotMovementRecord.ACS_DIVISION_ACCOUNT_ID is null)
         or (    iotMovementRecord.ACS_ACS_FINANCIAL_ACCOUNT_ID is null
             and iotMovementRecord.ACS_ACS_DIVISION_ACCOUNT_ID is null) then
         --or (    iotMovementRecord.ACS_FINANCIAL_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_DIVISION_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_CPN_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_CDA_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_PF_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_PJ_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_ACS_FINANCIAL_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_ACS_DIVISION_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_ACS_CPN_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_ACS_CDA_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_ACS_PF_ACCOUNT_ID is null
         --    and iotMovementRecord.ACS_ACS_PJ_ACCOUNT_ID is null
         --   ) then
        -- Mouvement d'une position de document -> Recherche de l'id du document
        if (iotMovementRecord.doc_position_id is not null) then
          select DOC_DOCUMENT_ID
            into lDocumentId
            from DOC_POSITION
           where DOC_POSITION_ID = iotMovementRecord.doc_position_id;
        else   -- Mouvement de type INV -> ID du document = NULL
          lDocumentId  := null;
        end if;

        /* Pour les mouvements de fabrication, on force l'utilisation des comptes
           obtenu par la procédure GetMvtAccounts. */
        if    (lMovementCode = '017')
           or (lMovementCode = '018')
           or (lMovementCode = '019')
           or (lMovementCode = '020')
           or (lMovementCode = '023') then
          iotMovementRecord.ACS_FINANCIAL_ACCOUNT_ID      := null;
          iotMovementRecord.ACS_DIVISION_ACCOUNT_ID       := null;
          iotMovementRecord.ACS_CPN_ACCOUNT_ID            := null;
          iotMovementRecord.ACS_CDA_ACCOUNT_ID            := null;
          iotMovementRecord.ACS_PF_ACCOUNT_ID             := null;
          iotMovementRecord.ACS_PJ_ACCOUNT_ID             := null;
          iotMovementRecord.ACS_ACS_FINANCIAL_ACCOUNT_ID  := null;
          iotMovementRecord.ACS_ACS_DIVISION_ACCOUNT_ID   := null;
          iotMovementRecord.ACS_ACS_CPN_ACCOUNT_ID        := null;
          iotMovementRecord.ACS_ACS_CDA_ACCOUNT_ID        := null;
          iotMovementRecord.ACS_ACS_PF_ACCOUNT_ID         := null;
          iotMovementRecord.ACS_ACS_PJ_ACCOUNT_ID         := null;
        end if;

        GetMvtAccounts(iotMovementRecord, lDocumentId, lAccountInfo, lAccountInfo2, lFinancial, lAnalytical, lInfoCompl);
        iotMovementRecord.FAM_FIXED_ASSETS_ID    := lAccountInfo.FAM_FIXED_ASSETS_ID;
        iotMovementRecord.C_FAM_TRANSACTION_TYP  := lAccountInfo.C_FAM_TRANSACTION_TYP;
        iotMovementRecord.HRM_PERSON_ID          := GetHrmPerson(lAccountInfo.DEF_HRM_PERSON);
        iotMovementRecord.DIC_IMP_FREE1_ID       := lAccountInfo.DEF_DIC_IMP_FREE1;
        iotMovementRecord.DIC_IMP_FREE2_ID       := lAccountInfo.DEF_DIC_IMP_FREE2;
        iotMovementRecord.DIC_IMP_FREE3_ID       := lAccountInfo.DEF_DIC_IMP_FREE3;
        iotMovementRecord.DIC_IMP_FREE4_ID       := lAccountInfo.DEF_DIC_IMP_FREE4;
        iotMovementRecord.DIC_IMP_FREE5_ID       := lAccountInfo.DEF_DIC_IMP_FREE5;
        iotMovementRecord.SMO_IMP_TEXT_1         := lAccountInfo.DEF_TEXT1;
        iotMovementRecord.SMO_IMP_TEXT_2         := lAccountInfo.DEF_TEXT2;
        iotMovementRecord.SMO_IMP_TEXT_3         := lAccountInfo.DEF_TEXT3;
        iotMovementRecord.SMO_IMP_TEXT_4         := lAccountInfo.DEF_TEXT4;
        iotMovementRecord.SMO_IMP_TEXT_5         := lAccountInfo.DEF_TEXT5;
        iotMovementRecord.SMO_IMP_NUMBER_1       := to_number(lAccountInfo.DEF_NUMBER1);
        iotMovementRecord.SMO_IMP_NUMBER_2       := to_number(lAccountInfo.DEF_NUMBER2);
        iotMovementRecord.SMO_IMP_NUMBER_3       := to_number(lAccountInfo.DEF_NUMBER3);
        iotMovementRecord.SMO_IMP_NUMBER_4       := to_number(lAccountInfo.DEF_NUMBER4);
        iotMovementRecord.SMO_IMP_NUMBER_5       := to_number(lAccountInfo.DEF_NUMBER5);
        iotMovementRecord.SMO_IMP_DATE_1         := lAccountInfo.DEF_DATE1;
        iotMovementRecord.SMO_IMP_DATE_2         := lAccountInfo.DEF_DATE2;
        iotMovementRecord.SMO_IMP_DATE_3         := lAccountInfo.DEF_DATE3;
        iotMovementRecord.SMO_IMP_DATE_4         := lAccountInfo.DEF_DATE4;
        iotMovementRecord.SMO_IMP_DATE_5         := lAccountInfo.DEF_DATE5;
      end if;

      -- vérifie si le mouvement doit générer un document comptable
      -- (un test plus pointu est fait dans la procedure
      if nvl(iotMovementRecord.SMO_FINANCIAL_CHARGING, 1) <> 0 then
        -- Traitement de l'écart d'achat

        -- Pour un mouvement d'extourne, il faut rechercher l'écart d'achat sur le détail de position père et non sur le
        -- détail lié au mouvement d'extourne.
        if nvl(iotMovementRecord.SMO_EXTOURNE_MVT, 0) = 1 then
          begin
            select decode(PDE.PDE_FINAL_QUANTITY_SU
                        , 0, PDE.PDE_GAP_PURCHASE_PRICE
                        , ACS_FUNCTION.RoundAmount(PDE.PDE_GAP_PURCHASE_PRICE / PDE.PDE_FINAL_QUANTITY_SU * iotMovementRecord.SMO_MOVEMENT_QUANTITY
                                                 , ACS_FUNCTION.GetLocalCurrencyId
                                                  )
                         )
              into lGapPurchasePrice
              from DOC_POSITION_DETAIL PDE
             where PDE.DOC_POSITION_DETAIL_ID = tplPositionDetail.DOC_DOC_POSITION_DETAIL_ID;
          exception
            when no_data_found then
              lGapPurchasePrice  := null;
          end;
        end if;

        if lGapPurchasePrice is not null then
          -- Recherche la mode de gestion du bien
          begin
            select GOO.C_MANAGEMENT_MODE
              into lManagementMode
              from GCO_GOOD GOO
             where GOO.GCO_GOOD_ID = iotMovementRecord.GCO_GOOD_ID;
          exception
            when no_data_found then
              lManagementMode  := null;
          end;

          -- Si le bien n'est pas géré au prix de revient fixe, l'écart d'achat n'est pas à traiter.
          if (nvl(lManagementMode, 'NULL') <> '3') then
            lGapPurchasePrice  := null;
          end if;
        end if;

        -- Génération des documents d'interface comptable
        ACI_PRC_STOCK_MOVEMENT.createInterfaceDocument(iotMovementRecord, lAccountInfo, lAccountInfo2, lGapPurchasePrice);
      end if;
    end if;
  end generatePermanentInventory;

  /**
   * Procedure GetProgressAccounts
   * Description
   *   Procédure d'initialisation des comptes des avancements
   */
  procedure GetProgressAccounts(
    iCurId             in     number
  , iElementType       in     varchar2
  , iAdminDomain       in     varchar2
  , iEntryType         in     varchar2
  , iEntrySign         in     varchar2
  , iDateRef           in     date default sysdate
  , iFalLotId          in     number default null
  , iRecordId          in     number default null
  , iFalFactoryFloorId in     number default null
  , iGalCostCenterId   in     number default null
  , iHrmPersonId       in     number default null
  , iInFinancialId     in     number default null
  , iInDivisionId      in     number default null
  , iInCpnId           in     number default null
  , iInCdaId           in     number default null
  , iInPfId            in     number default null
  , iInPjId            in     number default null
  , iInQtyId           in     number default null
  , ioFinancialId      in out number
  , ioDivisionId       in out number
  , ioCpnId            in out number
  , ioCdaId            in out number
  , ioPfId             in out number
  , ioPjId             in out number
  , ioQtyId            in out number
  , iotAccountInfo     in out tAccountInfo
  )
  is
    lDebug     integer := 1;
    lInfoCompl integer := 1;
  begin
    AddInformation(iCurId ||
                   CO.cLineBreak ||
                   iElementType ||
                   CO.cLineBreak ||
                   iAdminDomain ||
                   CO.cLineBreak ||
                   iEntryType ||
                   CO.cLineBreak ||
                   iEntrySign ||
                   CO.cLineBreak ||
                   iDateRef ||
                   CO.cLineBreak ||
                   iFalLotId ||
                   CO.cLineBreak ||
                   iRecordId ||
                   CO.cLineBreak ||
                   iFalFactoryFloorId ||
                   CO.cLineBreak ||
                   iGalCostCenterId ||
                   CO.cLineBreak ||
                   iHrmPersonId ||
                   CO.cLineBreak
                  );
    /**
     * Recherche des comptes
     * iOverride => 0 permet de ne pas écraser les paramètres iOut pré-initialisé
     */
    SearchAccounts(iElementId           => iCurId
                 , iElementType         => iElementType
                 , iAdminDomain         => iAdminDomain
                 , iDateRef             => iDateRef
                 , iFalLotId            => iFalLotId
                 , iRecordId            => iRecordId
                 , iFalFactoryFloorId   => iFalFactoryFloorId
                 , iGalCostCenterId     => iGalCostCenterId
                 , iHrmPersonId         => iHrmPersonId
                 , iInFinancialId       => iInFinancialId
                 , iInDivisionId        => iInDivisionId
                 , iInCpnId             => iInCpnId
                 , iInCdaId             => iInCdaId
                 , iInPfId              => iInPfId
                 , iInPjId              => iInPjId
                 , iInQtyId             => iInQtyId
                 , ioFinancialId        => ioFinancialId
                 , ioDivisionId         => ioDivisionId
                 , ioCpnId              => ioCpnId
                 , ioCdaId              => ioCdaId
                 , ioPfId               => ioPfId
                 , ioPjId               => ioPjId
                 , ioQtyId              => ioQtyId
                 , iotAccountInfo       => iotAccountInfo
                 , obInfoCompl          => lInfoCompl
                 , iAddInformation      => lDebug
                 , iOverride            => 0
                  );
    ----
    -- Procédure de détermination du compte financier et du compte division pour
    -- toutes les imputations.
    --
    DefineFinancialImputation(iCode                  => gcItProgress
                            , iFalFactoryFloorId     => iFalFactoryFloorId
                            , iGalCostCenterId       => iGalCostCenterId
                            , iAdminDomain           => iAdminDomain
                            , iEntryType             => iEntryType
                            , iEntrySign             => iEntrySign
                            , ioFinancialAccountId   => ioFinancialId
                            , ioDivisionAccountId    => ioDivisionId
                            , ioCPNAccountId         => ioCpnId
                            , ioCDAAccountId         => ioCdaId
                            , ioPFAccountId          => ioPfId
                            , ioPJAccountId          => ioPjId
                            , ioQtyAccountId         => ioQtyId
                             );
    ----
    -- Contrôle si les imputations (centre d'analyse, porteur et projet) avec la
    -- charge par nature sont autorisées.
    --
    CheckAccountPermission(iFinancialAccountId   => ioFinancialId
                         , ioDivisionAccountId   => ioDivisionId
                         , ioCPNAccountId        => ioCpnId
                         , ioCDAAccountId        => ioCdaId
                         , ioPFAccountId         => ioPfId
                         , ioPJAccountId         => ioPjId
                         , iRefdate              => iDateRef
                          );

    if lDebug = 1 then
--         ra(iMessage   => 'Recherche des comptes pour l''imputation d''un avancement' ||
--                          CO.cLineBreak ||
--                          CO.cLineBreak ||
--                          GetInformation
--          , iUser      => ''
--          , iErrNo     => -20500
--           );
      SetInformation(null);
    end if;
  end GetProgressAccounts;

  /**
  * Description : Méthode de détermination du compte financier et du compte
  *               division pour toutes les imputations gèrées dans un document.
   *   Alias pour les procédures logistiques ne tenant pas compte de l'unité
   *   quantitative.
  */
  procedure DefineFinancialImputation(
    iCode                in     number
  , iGoodId              in     number default null
  , iChargeId            in     number default null
  , iLocationId          in     number default null
  , iStockId             in     number default null
  , iMovementKindId      in     number default null
  , iGaugeId             in     number default null
  , iAdminDomain         in     varchar2 default null
  , iMovementType        in     varchar2 default null
  , iChargeType          in     varchar2 default null
  , ioFinancialAccountId in out number
  , ioDivisionAccountId  in out number
  , ioCPNAccountId       in out number
  , ioCDAAccountId       in out number
  , ioPFAccountId        in out number
  , ioPJAccountId        in out number
  )
  is
    lQtyAccountId number;
  begin
    DefineFinancialImputation(iCode                  => iCode
                            , iGoodId                => iGoodId
                            , iChargeId              => iChargeId
                            , iLocationId            => iLocationId
                            , iStockId               => iStockId
                            , iMovementKindId        => iMovementKindId
                            , iGaugeId               => iGaugeId
                            , iAdminDomain           => iAdminDomain
                            , iMovementType          => iMovementType
                            , iChargeType            => iChargeType
                            , ioFinancialAccountId   => ioFinancialAccountId
                            , ioDivisionAccountId    => ioDivisionAccountId
                            , ioCPNAccountId         => ioCPNAccountId
                            , ioCDAAccountId         => ioCDAAccountId
                            , ioPFAccountId          => ioPFAccountId
                            , ioPJAccountId          => ioPJAccountId
                            , ioQtyAccountId         => lQtyAccountId
                             );
  end DefineFinancialImputation;

  /**
  * Description : Méthode de détermination du compte financier et du compte
  *               division pour toutes les imputations gèrées dans un document.
  */
  procedure DefineFinancialImputation(
    iCode                in     number
  , iGoodId              in     number default null
  , iChargeId            in     number default null
  , iLocationId          in     number default null
  , iStockId             in     number default null
  , iMovementKindId      in     number default null
  , iGaugeId             in     number default null
  , iFalFactoryFloorId   in     number default null
  , iGalCostCenterId     in     number default null
  , iAdminDomain         in     varchar2 default null
  , iMovementType        in     varchar2 default null
  , iChargeType          in     varchar2 default null
  , iEntryType           in     varchar2 default null
  , iEntrySign           in     varchar2 default null
  , ioFinancialAccountId in out number
  , ioDivisionAccountId  in out number
  , ioCPNAccountId       in out number
  , ioCDAAccountId       in out number
  , ioPFAccountId        in out number
  , ioPJAccountId        in out number
  , ioQtyAccountId       in out number
  )
  is
    FinancialAccountNumber  ACS_ACCOUNT.ACC_NUMBER%type;
    DivisionAccountNumber   ACS_ACCOUNT.ACC_NUMBER%type;
    FinancialAccountId      ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
    DivisionAccountId       ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    CPNAccountId            ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    CDAAccountId            ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID%type;
    PFAccountId             ACS_PF_ACCOUNT.ACS_PF_ACCOUNT_ID%type;
    PJAccountId             ACS_PJ_ACCOUNT.ACS_PJ_ACCOUNT_ID%type;
    QtyAccountId            ACS_QTY_UNIT.ACS_QTY_UNIT_ID%type;
    ChargeType              PTC_CHARGE.C_CHARGE_TYPE%type;
    lFinancial              DOC_GAUGE_STRUCTURED.GAS_FINANCIAL_CHARGE%type;
    lAnalytical             DOC_GAUGE_STRUCTURED.GAS_ANAL_CHARGE%type;
    lFinancialAccountNumber ACS_ACCOUNT.ACC_NUMBER%type;
    lDivisionAccountNumber  ACS_ACCOUNT.ACC_NUMBER%type;
    lCPNAccountNumber       ACS_ACCOUNT.ACC_NUMBER%type;
    lCDAAccountNumber       ACS_ACCOUNT.ACC_NUMBER%type;
    lPFAccountNumber        ACS_ACCOUNT.ACC_NUMBER%type;
    lPJAccountNumber        ACS_ACCOUNT.ACC_NUMBER%type;
    lQtyAccountNumber       ACS_ACCOUNT.ACC_NUMBER%type;
  begin
    if (nvl(iGaugeId, 0) <> 0) then
      /**
      * Vérifie la gestion des comptes dans le gabarit
      */
      select decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_FINANCIAL_CHARGE, 0), 0, 0, 1) GAS_FINANCIAL
           , decode(nvl(GAS.GAS_VISIBLE_COUNT, 0) + nvl(GAS.GAS_ANAL_CHARGE, 0), 0, 0, 1) GAS_ANALYTICAL
        into lFinancial
           , lAnalytical
        from DOC_GAUGE_STRUCTURED GAS
       where GAS.DOC_GAUGE_ID = iGaugeId;
    elsif(nvl(iMovementKindId, 0) <> 0) then
      /**
      * Vérifie la gestion des comptes dans le genre de mouvement
      */
      select nvl(MOK.MOK_FINANCIAL_IMPUTATION, 0)
           , nvl(MOK.MOK_ANAL_IMPUTATION, 0)
        into lFinancial
           , lAnalytical
        from STM_MOVEMENT_KIND MOK
       where MOK.STM_MOVEMENT_KIND_ID = iMovementKindId;
    elsif iCode = gcItProgress then
      lFinancial   := 1;
      lAnalytical  := 1;
    else
      lFinancial   := 0;
      lAnalytical  := 0;
    end if;

    /* Si gestion ou initialisation des comptes financiers ou analytiques */
    if    (lFinancial = 1)
       or (lAnalytical = 1) then
      -- Garantit une valeur nulle si 0 est transmit.
      ioFinancialAccountId  := zvl(ioFinancialAccountId, null);
      ioDivisionAccountId   := zvl(ioDivisionAccountId, null);
      ioCPNAccountId        := zvl(ioCPNAccountId, null);
      ioCDAAccountId        := zvl(ioCDAAccountId, null);
      ioPFAccountId         := zvl(ioPFAccountId, null);
      ioPJAccountId         := zvl(ioPJAccountId, null);
      ioQtyAccountId        := zvl(ioQtyAccountId, null);

      if    ioFinancialAccountId is null
         or ioDivisionAccountId is null
         or ioCPNAccountId is null
         or ioCDAAccountId is null
         or ioPFAccountId is null
         or ioPJAccountId is null
         or ioQtyAccountId is null then
        if (iCode = gcItDocument) then   -- Imputation financière au niveau du document
          /* Pas géré dans cette méthode. Utiliser plutôt la méthode
             GetFinancialInfo du package DOC_DOCUMENT_FUNCTIONS */
          null;
        elsif    (iCode = gcItGoodPosition)
              or   -- Imputation financière au niveau des positions bien
                 (iCode = gcItPositionValue) then   -- Imputation financière au niveau des positions valeurs
          if (iCode = gcItGoodPosition) then
            /* Recherche les imputations du bien spécifié */
            begin
              select IMD.ACS_FINANCIAL_ACCOUNT_ID
                   , IMD.ACS_DIVISION_ACCOUNT_ID
                   , IMD.ACS_CPN_ACCOUNT_ID
                   , IMD.ACS_CDA_ACCOUNT_ID
                   , IMD.ACS_PF_ACCOUNT_ID
                   , IMD.ACS_PJ_ACCOUNT_ID
                   , ACC1.ACC_NUMBER
                   , ACC2.ACC_NUMBER
                   , ACC3.ACC_NUMBER
                   , ACC4.ACC_NUMBER
                   , ACC5.ACC_NUMBER
                   , ACC6.ACC_NUMBER
                into FinancialAccountId
                   , DivisionAccountId
                   , CPNAccountId
                   , CDAAccountId
                   , PFAccountId
                   , PJAccountId
                   , lFinancialAccountNumber
                   , lDivisionAccountNumber
                   , lCPNAccountNumber
                   , lCDAAccountNumber
                   , lPFAccountNumber
                   , lPJAccountNumber
                from GCO_IMPUT_DOC IMD
                   , ACS_ACCOUNT ACC1
                   , ACS_ACCOUNT ACC2
                   , ACS_ACCOUNT ACC3
                   , ACS_ACCOUNT ACC4
                   , ACS_ACCOUNT ACC5
                   , ACS_ACCOUNT ACC6
               where IMD.GCO_GOOD_ID = iGoodId
                 and IMD.C_ADMIN_DOMAIN = iAdminDomain
                 and ACC1.ACS_ACCOUNT_ID(+) = IMD.ACS_FINANCIAL_ACCOUNT_ID
                 and ACC2.ACS_ACCOUNT_ID(+) = IMD.ACS_DIVISION_ACCOUNT_ID
                 and ACC3.ACS_ACCOUNT_ID(+) = IMD.ACS_CPN_ACCOUNT_ID
                 and ACC4.ACS_ACCOUNT_ID(+) = IMD.ACS_CDA_ACCOUNT_ID
                 and ACC5.ACS_ACCOUNT_ID(+) = IMD.ACS_PF_ACCOUNT_ID
                 and ACC6.ACS_ACCOUNT_ID(+) = IMD.ACS_PJ_ACCOUNT_ID;

              /* Ajoute les informations de recherche des comptes */
              AddInformation('Imputations du bien' ||
                             CO.cLineBreak ||
                             CO.cLineBreak ||
                             'Good : ' ||
                             iGoodId ||
                             CO.cLineBreak ||
                             'Domain : ' ||
                             iAdminDomain ||
                             CO.cLineBreak ||
                             '---' ||
                             CO.cLineBreak ||
                             'Financier : ' ||
                             lFinancialAccountNumber ||
                             CO.cLineBreak ||
                             'Division : ' ||
                             lDivisionAccountNumber ||
                             CO.cLineBreak ||
                             'CPN : ' ||
                             lCPNAccountNumber ||
                             CO.cLineBreak ||
                             'CDA : ' ||
                             lCDAAccountNumber ||
                             CO.cLineBreak ||
                             'PF : ' ||
                             lPFAccountNumber ||
                             CO.cLineBreak ||
                             'PJ : ' ||
                             lPJAccountNumber
                            );
            exception
              when no_data_found then
                null;
            end;

            ioFinancialAccountId  := nvl(ioFinancialAccountId, FinancialAccountId);
            ioDivisionAccountId   := nvl(ioDivisionAccountId, DivisionAccountId);
            ioCPNAccountId        := nvl(ioCPNAccountId, CPNAccountId);
            ioCDAAccountId        := nvl(ioCDAAccountId, CDAAccountId);
            ioPFAccountId         := nvl(ioPFAccountId, PFAccountId);
            ioPJAccountId         := nvl(ioPJAccountId, PJAccountId);
          end if;

          if (iAdminDomain = gcAdPurchases) then   -- Domaine achat
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_PURCHASE_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_PURCHASE_DIV_ACCOUNT');
            end if;
          elsif(iAdminDomain = gcAdSales) then   -- Domaine vente
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_SALE_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_SALE_DIV_ACCOUNT');
            end if;
          elsif(iAdminDomain = gcAdStocks) then   -- Domaine stock
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_STOCK_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_STOCK_DIV_ACCOUNT');
            end if;
          elsif(iAdminDomain = gcAdProduction) then   -- Domaine production
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_PRODUCT_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_PRODUCT_DIV_ACCOUNT');
            end if;
          elsif(iAdminDomain = gcAdSubcontracting) then   -- Domaine sous-traitance
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_SUBCONTR_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_SUBCONTR_DIV_ACCOUNT');
            end if;
          elsif(iAdminDomain = gcAdAfterSalesService) then   -- Domaine service après vente
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_ASS_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_ASS_DIV_ACCOUNT');
            end if;
          elsif(iAdminDomain = gcAdInventoryDomain) then   -- Domaine inventaire
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_INVENT_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_POS_INVENT_DIV_ACCOUNT');
            end if;
          end if;

          if FinancialAccountNumber is not null then
            begin
              select ACS_FINANCIAL_ACCOUNT_ID
                into ioFinancialAccountId
                from ACS_FINANCIAL_ACCOUNT FIN
                   , ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                 and ACC.ACC_NUMBER = FinancialAccountNumber;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if DivisionAccountNumber is not null then
            begin
              select ACS_DIVISION_ACCOUNT_ID
                into ioDivisionAccountId
                from ACS_DIVISION_ACCOUNT DIV
                   , ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
                 and ACC.ACC_NUMBER = DivisionAccountNumber;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if    (FinancialAccountNumber is not null)
             or (DivisionAccountNumber is not null) then
            /* Ajoute les informations de recherche des comptes */
            AddInformation('Configuration' ||
                           CO.cLineBreak ||
                           CO.cLineBreak ||
                           'Domain : ' ||
                           iAdminDomain ||
                           CO.cLineBreak ||
                           '---' ||
                           CO.cLineBreak ||
                           'Financier : ' ||
                           FinancialAccountNumber ||
                           CO.cLineBreak ||
                           'Division ' ||
                           DivisionAccountNumber
                          );
          end if;
        elsif(iCode = gcItDiscount) then   -- Imputation financière au niveau des remises (position ou pied)
          if iChargeType is null then
            begin
              select C_DISCOUNT_TYPE
                into ChargeType
                from PTC_DISCOUNT
               where PTC_DISCOUNT_ID = iChargeId;
            exception
              when no_data_found then
                null;
            end;
          else
            ChargeType  := iChargeType;
          end if;

          if (ChargeType = '1') then   -- Remise accordée à un client
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_DSCT_GIVE_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_DSCT_GIVE_DIV_ACCOUNT');
            end if;
          elsif(ChargeType = '2') then   -- Remise reçue de la part d'un fournisseur
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_DSCT_RECEIVE_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_DSCT_RECEIVE_DIV_ACCOUNT');
            end if;
          end if;

          if FinancialAccountNumber is not null then
            begin
              select ACS_FINANCIAL_ACCOUNT_ID
                into ioFinancialAccountId
                from ACS_FINANCIAL_ACCOUNT FIN
                   , ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                 and ACC.ACC_NUMBER = FinancialAccountNumber;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if DivisionAccountNumber is not null then
            begin
              select ACS_DIVISION_ACCOUNT_ID
                into ioDivisionAccountId
                from ACS_DIVISION_ACCOUNT DIV
                   , ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
                 and ACC.ACC_NUMBER = DivisionAccountNumber;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if    (FinancialAccountNumber is not null)
             or (DivisionAccountNumber is not null) then
            /* Ajoute les informations de recherche des comptes */
            AddInformation('Configuration' ||
                           CO.cLineBreak ||
                           CO.cLineBreak ||
                           'Domain : ' ||
                           iAdminDomain ||
                           CO.cLineBreak ||
                           '---' ||
                           CO.cLineBreak ||
                           'Financier : ' ||
                           FinancialAccountNumber ||
                           CO.cLineBreak ||
                           'Division ' ||
                           DivisionAccountNumber
                          );
          end if;
        elsif(iCode = gcItSurcharge) then   -- Imputation financière au niveau des taxes (position ou pied)
          if iChargeType is null then
            begin
              select C_CHARGE_TYPE
                into ChargeType
                from PTC_CHARGE
               where PTC_CHARGE_ID = iChargeId;
            exception
              when no_data_found then
                null;
            end;
          else
            ChargeType  := iChargeType;
          end if;

          if (ChargeType = '1') then   -- Taxe facturée à un client
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_TAXE_CHARGE_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_TAXE_CHARGE_DIV_ACCOUNT');
            end if;
          elsif(ChargeType = '2') then   -- Taxe payée de la part d'un fournisseur
            if ioFinancialAccountId is null then
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_TAXE_PAY_FIN_ACCOUNT');
            end if;

            if ioDivisionAccountId is null then
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_TAXE_PAY_DIV_ACCOUNT');
            end if;
          end if;

          if FinancialAccountNumber is not null then
            begin
              select ACS_FINANCIAL_ACCOUNT_ID
                into ioFinancialAccountId
                from ACS_FINANCIAL_ACCOUNT FIN
                   , ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                 and ACC.ACC_NUMBER = FinancialAccountNumber;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if DivisionAccountNumber is not null then
            begin
              select ACS_DIVISION_ACCOUNT_ID
                into ioDivisionAccountId
                from ACS_DIVISION_ACCOUNT DIV
                   , ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
                 and ACC.ACC_NUMBER = DivisionAccountNumber;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if    (FinancialAccountNumber is not null)
             or (DivisionAccountNumber is not null) then
            /* Ajoute les informations de recherche des comptes */
            AddInformation('Configuration' ||
                           CO.cLineBreak ||
                           CO.cLineBreak ||
                           'Domain : ' ||
                           iAdminDomain ||
                           CO.cLineBreak ||
                           '---' ||
                           CO.cLineBreak ||
                           'Financier : ' ||
                           FinancialAccountNumber ||
                           CO.cLineBreak ||
                           'Division ' ||
                           DivisionAccountNumber
                          );
          end if;
        elsif(iCode = gcItCosts) then   -- Imputation financière au niveau des frais de document
          if ioFinancialAccountId is null then
            FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_COST_FINANCIAL_ACCOUNT');
          end if;

          if ioDivisionAccountId is null then
            DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_COST_DIVISION_ACCOUNT');
          end if;

          if FinancialAccountNumber is not null then
            begin
              select ACS_FINANCIAL_ACCOUNT_ID
                into ioFinancialAccountId
                from ACS_FINANCIAL_ACCOUNT FIN
                   , ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                 and ACC.ACC_NUMBER = FinancialAccountNumber;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if DivisionAccountNumber is not null then
            begin
              select ACS_DIVISION_ACCOUNT_ID
                into ioDivisionAccountId
                from ACS_DIVISION_ACCOUNT DIV
                   , ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
                 and ACC.ACC_NUMBER = DivisionAccountNumber;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if    (FinancialAccountNumber is not null)
             or (DivisionAccountNumber is not null) then
            /* Ajoute les informations de recherche des comptes */
            AddInformation('Configuration' ||
                           CO.cLineBreak ||
                           CO.cLineBreak ||
                           'Domain : ' ||
                           iAdminDomain ||
                           CO.cLineBreak ||
                           '---' ||
                           CO.cLineBreak ||
                           'Financier : ' ||
                           FinancialAccountNumber ||
                           CO.cLineBreak ||
                           'Division ' ||
                           DivisionAccountNumber
                          );
          end if;
        elsif(iCode = gcItGoodsStockMovBalance) then   -- Imputation financière au niveau des mouvements de stock ( comptes de bilan )
          /* Recherche les imputations stock pour l'emplacement de stock spécifié */
          begin
            if nvl(iLocationId, 0) <> 0 then
              select LOC.ACS_FINANCIAL_ACCOUNT_ID
                   , LOC.ACS_DIVISION_ACCOUNT_ID
                   , ACC1.ACC_NUMBER
                   , ACC2.ACC_NUMBER
                into FinancialAccountId
                   , DivisionAccountId
                   , lFinancialAccountNumber
                   , lDivisionAccountNumber
                from STM_LOCATION LOC
                   , ACS_ACCOUNT ACC1
                   , ACS_ACCOUNT ACC2
               where LOC.STM_LOCATION_ID = iLocationId
                 and ACC1.ACS_ACCOUNT_ID(+) = LOC.ACS_FINANCIAL_ACCOUNT_ID
                 and ACC2.ACS_ACCOUNT_ID(+) = LOC.ACS_DIVISION_ACCOUNT_ID;
            end if;

            /* Recherche les imputations stock pour le stock spécifié */
            if    (lFinancialAccountNumber is null)
               or (lDivisionAccountNumber is null) then
              select STO.ACS_FINANCIAL_ACCOUNT_ID
                   , STO.ACS_DIVISION_ACCOUNT_ID
                   , nvl(lFinancialAccountNumber, ACC1.ACC_NUMBER)
                   , nvl(lDivisionAccountNumber, ACC2.ACC_NUMBER)
                into FinancialAccountId
                   , DivisionAccountId
                   , lFinancialAccountNumber
                   , lDivisionAccountNumber
                from STM_STOCK STO
                   , ACS_ACCOUNT ACC1
                   , ACS_ACCOUNT ACC2
               where STO.STM_STOCK_ID = iStockId
                 and ACC1.ACS_ACCOUNT_ID(+) = STO.ACS_FINANCIAL_ACCOUNT_ID
                 and ACC2.ACS_ACCOUNT_ID(+) = STO.ACS_DIVISION_ACCOUNT_ID;
            end if;

            /* Ajoute les informations de recherche des comptes */
            AddInformation('Imputations du stock' ||
                           CO.cLineBreak ||
                           CO.cLineBreak ||
                           'Location : ' ||
                           iLocationId ||
                           CO.cLineBreak ||
                           'Stock : ' ||
                           iStockId ||
                           CO.cLineBreak ||
                           '---' ||
                           CO.cLineBreak ||
                           'Financier : ' ||
                           lFinancialAccountNumber ||
                           CO.cLineBreak ||
                           'Division : ' ||
                           lDivisionAccountNumber
                          );
          exception
            when no_data_found then
              null;
          end;

          if ioFinancialAccountId is null then
            if FinancialAccountId is not null then
              ioFinancialAccountId  := FinancialAccountId;
            else
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_LG_STOCK_FINANCIAL_ACCOUNT');

              if FinancialAccountNumber is not null then
                begin
                  select ACS_FINANCIAL_ACCOUNT_ID
                    into ioFinancialAccountId
                    from ACS_FINANCIAL_ACCOUNT FIN
                       , ACS_ACCOUNT ACC
                   where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                     and ACC.ACC_NUMBER = FinancialAccountNumber;
                exception
                  when no_data_found then
                    null;
                end;
              end if;
            end if;
          end if;

          if ioDivisionAccountId is null then
            if DivisionAccountId is not null then
              ioDivisionAccountId  := DivisionAccountId;
            else
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_LG_STOCK_DIVISION_ACCOUNT');

              if DivisionAccountNumber is not null then
                begin
                  select ACS_DIVISION_ACCOUNT_ID
                    into ioDivisionAccountId
                    from ACS_DIVISION_ACCOUNT DIV
                       , ACS_ACCOUNT ACC
                   where ACC.ACS_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
                     and ACC.ACC_NUMBER = DivisionAccountNumber;
                exception
                  when no_data_found then
                    null;
                end;
              end if;
            end if;
          end if;

          if    (FinancialAccountNumber is not null)
             or (DivisionAccountNumber is not null) then
            /* Ajoute les informations de recherche des comptes */
            AddInformation('Configuration' ||
                           CO.cLineBreak ||
                           CO.cLineBreak ||
                           'Domain : ' ||
                           iAdminDomain ||
                           CO.cLineBreak ||
                           '---' ||
                           CO.cLineBreak ||
                           'Financier : ' ||
                           FinancialAccountNumber ||
                           CO.cLineBreak ||
                           'Division ' ||
                           DivisionAccountNumber
                          );
          end if;
        elsif(iCode = gcItGoodsStockMovResult) then   -- Imputation financière au niveau des mouvements de stock ( comptes de résultat )
          /* Recherche les imputations stock pour le bien et le type de
             mouvement spécifié */
          begin
            select IMS.ACS_FINANCIAL_ACCOUNT_ID
                 , IMS.ACS_DIVISION_ACCOUNT_ID
                 , IMS.ACS_CPN_ACCOUNT_ID
                 , IMS.ACS_CDA_ACCOUNT_ID
                 , IMS.ACS_PF_ACCOUNT_ID
                 , IMS.ACS_PJ_ACCOUNT_ID
                 , ACC1.ACC_NUMBER
                 , ACC2.ACC_NUMBER
                 , ACC3.ACC_NUMBER
                 , ACC4.ACC_NUMBER
                 , ACC5.ACC_NUMBER
                 , ACC6.ACC_NUMBER
              into FinancialAccountId
                 , DivisionAccountId
                 , CPNAccountId
                 , CDAAccountId
                 , PFAccountId
                 , PJAccountId
                 , lFinancialAccountNumber
                 , lDivisionAccountNumber
                 , lCPNAccountNumber
                 , lCDAAccountNumber
                 , lPFAccountNumber
                 , lPJAccountNumber
              from GCO_IMPUT_STOCK IMS
                 , STM_MOVEMENT_KIND MOK
                 , ACS_ACCOUNT ACC1
                 , ACS_ACCOUNT ACC2
                 , ACS_ACCOUNT ACC3
                 , ACS_ACCOUNT ACC4
                 , ACS_ACCOUNT ACC5
                 , ACS_ACCOUNT ACC6
             where IMS.GCO_GOOD_ID = iGoodId
               and IMS.STM_MOVEMENT_KIND_ID = iMovementKindId
               and MOK.STM_MOVEMENT_KIND_ID = IMS.STM_MOVEMENT_KIND_ID
               and ACC1.ACS_ACCOUNT_ID(+) = IMS.ACS_FINANCIAL_ACCOUNT_ID
               and ACC2.ACS_ACCOUNT_ID(+) = IMS.ACS_DIVISION_ACCOUNT_ID
               and ACC3.ACS_ACCOUNT_ID(+) = IMS.ACS_CPN_ACCOUNT_ID
               and ACC4.ACS_ACCOUNT_ID(+) = IMS.ACS_CDA_ACCOUNT_ID
               and ACC5.ACS_ACCOUNT_ID(+) = IMS.ACS_PF_ACCOUNT_ID
               and ACC6.ACS_ACCOUNT_ID(+) = IMS.ACS_PJ_ACCOUNT_ID;

            /* Ajoute les informations de recherche des comptes */
            AddInformation('Imputations du genre de mouvement' ||
                           CO.cLineBreak ||
                           CO.cLineBreak ||
                           'Good : ' ||
                           iGoodId ||
                           CO.cLineBreak ||
                           'MovementKind : ' ||
                           iMovementKindId ||
                           CO.cLineBreak ||
                           '---' ||
                           CO.cLineBreak ||
                           'Financier : ' ||
                           lFinancialAccountNumber ||
                           CO.cLineBreak ||
                           'Division : ' ||
                           lDivisionAccountNumber ||
                           CO.cLineBreak ||
                           'CPN : ' ||
                           lCPNAccountNumber ||
                           CO.cLineBreak ||
                           'CDA : ' ||
                           lCDAAccountNumber ||
                           CO.cLineBreak ||
                           'PF : ' ||
                           lPFAccountNumber ||
                           CO.cLineBreak ||
                           'PJ : ' ||
                           lPJAccountNumber
                          );
          exception
            when no_data_found then
              null;
          end;

          /*
          raise_application_error(-20100,
                                  iGoodId             || CO.cLineBreak ||
                                  iMovementKindId     || CO.cLineBreak ||
                                  FinancialAccountId  || CO.cLineBreak ||
                                  DivisionAccountId   || CO.cLineBreak ||
                                  CPNAccountId        || CO.cLineBreak ||
                                  CDAAccountId        || CO.cLineBreak ||
                                  PFAccountId         || CO.cLineBreak ||
                                  PJAccountId       );
          */
          ioCPNAccountId  := nvl(ioCPNAccountId, CPNAccountId);
          ioCDAAccountId  := nvl(ioCDAAccountId, CDAAccountId);
          ioPFAccountId   := nvl(ioPFAccountId, PFAccountId);
          ioPJAccountId   := nvl(ioPJAccountId, PJAccountId);

          if    (FinancialAccountId is null)
             or (DivisionAccountId is null) then
            /* Si aucune imputation stock, on recherche les imputations du
               genre de mouvement spécifié */
            begin
              select nvl(FinancialAccountId, ACS_FINANCIAL_ACCOUNT_ID)
                   , nvl(DivisionAccountId, ACS_DIVISION_ACCOUNT_ID)
                into FinancialAccountId
                   , DivisionAccountId
                from STM_MOVEMENT_KIND
               where STM_MOVEMENT_KIND_ID = iMovementKindId;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if ioFinancialAccountId is null then
            if FinancialAccountId is not null then
              ioFinancialAccountId  := FinancialAccountId;
            else
              FinancialAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_MVT_FINANCIAL_ACCOUNT');

              if FinancialAccountNumber is not null then
                begin
                  select ACS_FINANCIAL_ACCOUNT_ID
                    into ioFinancialAccountId
                    from ACS_FINANCIAL_ACCOUNT FIN
                       , ACS_ACCOUNT ACC
                   where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                     and ACC.ACC_NUMBER = FinancialAccountNumber;
                exception
                  when no_data_found then
                    null;
                end;
              end if;
            end if;
          end if;

          if ioDivisionAccountId is null then
            if DivisionAccountId is not null then
              ioDivisionAccountId  := DivisionAccountId;
            else
              DivisionAccountNumber  := PCS.PC_CONFIG.GetConfig('FIN_MVT_DIVISION_ACCOUNT');

              if DivisionAccountNumber is not null then
                begin
                  select ACS_DIVISION_ACCOUNT_ID
                    into ioDivisionAccountId
                    from ACS_DIVISION_ACCOUNT DIV
                       , ACS_ACCOUNT ACC
                   where ACC.ACS_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
                     and ACC.ACC_NUMBER = DivisionAccountNumber;
                exception
                  when no_data_found then
                    null;
                end;
              end if;
            end if;
          end if;

          if    (FinancialAccountNumber is not null)
             or (DivisionAccountNumber is not null) then
            /* Ajoute les informations de recherche des comptes */
            AddInformation('Configuration' ||
                           CO.cLineBreak ||
                           CO.cLineBreak ||
                           'Domain : ' ||
                           iAdminDomain ||
                           CO.cLineBreak ||
                           '---' ||
                           CO.cLineBreak ||
                           'Financier : ' ||
                           FinancialAccountNumber ||
                           CO.cLineBreak ||
                           'Division ' ||
                           DivisionAccountNumber
                          );
          end if;
        elsif(iCode = gcItProgress) then   -- Imputation financière au niveau des avancements
          /* Recherche les imputations atelier puis nature analytique */
          if iFalFactoryFloorId is not null then
            begin
              select FFA.ACS_FINANCIAL_ACCOUNT_ID
                   , FFA.ACS_DIVISION_ACCOUNT_ID
                   , FFA.ACS_CPN_ACCOUNT_ID
                   , FFA.ACS_CDA_ACCOUNT_ID
                   , FFA.ACS_PF_ACCOUNT_ID
                   , FFA.ACS_PJ_ACCOUNT_ID
                   , FFA.ACS_QTY_UNIT_ID
                   , ACC1.ACC_NUMBER
                   , ACC2.ACC_NUMBER
                   , ACC3.ACC_NUMBER
                   , ACC4.ACC_NUMBER
                   , ACC5.ACC_NUMBER
                   , ACC6.ACC_NUMBER
                   , ACC7.ACC_NUMBER
                into FinancialAccountId
                   , DivisionAccountId
                   , CPNAccountId
                   , CDAAccountId
                   , PFAccountId
                   , PJAccountId
                   , QtyAccountId
                   , lFinancialAccountNumber
                   , lDivisionAccountNumber
                   , lCPNAccountNumber
                   , lCDAAccountNumber
                   , lPFAccountNumber
                   , lPJAccountNumber
                   , lQtyAccountNumber
                from FAL_FACTORY_ACCOUNT FFA
                   , ACS_ACCOUNT ACC1
                   , ACS_ACCOUNT ACC2
                   , ACS_ACCOUNT ACC3
                   , ACS_ACCOUNT ACC4
                   , ACS_ACCOUNT ACC5
                   , ACS_ACCOUNT ACC6
                   , ACS_ACCOUNT ACC7
               where FFA.C_FAL_ENTRY_TYPE = iEntryType
                 and FFA.C_FAL_ENTRY_SIGN = iEntrySign
                 and FFA.FAL_FACTORY_FLOOR_ID = iFalFactoryFloorId
                 and ACC1.ACS_ACCOUNT_ID(+) = FFA.ACS_FINANCIAL_ACCOUNT_ID
                 and ACC2.ACS_ACCOUNT_ID(+) = FFA.ACS_DIVISION_ACCOUNT_ID
                 and ACC3.ACS_ACCOUNT_ID(+) = FFA.ACS_CPN_ACCOUNT_ID
                 and ACC4.ACS_ACCOUNT_ID(+) = FFA.ACS_CDA_ACCOUNT_ID
                 and ACC5.ACS_ACCOUNT_ID(+) = FFA.ACS_PF_ACCOUNT_ID
                 and ACC6.ACS_ACCOUNT_ID(+) = FFA.ACS_PJ_ACCOUNT_ID
                 and ACC7.ACS_ACCOUNT_ID(+) = FFA.ACS_QTY_UNIT_ID;
            exception
              when no_data_found then
                null;
            end;
          end if;

          if iGalCostCenterId is not null then
            begin
              select nvl(FinancialAccountId, FFA.ACS_FINANCIAL_ACCOUNT_ID)
                   , nvl(DivisionAccountId, FFA.ACS_DIVISION_ACCOUNT_ID)
                   , nvl(CPNAccountId, FFA.ACS_CPN_ACCOUNT_ID)
                   , nvl(CDAAccountId, FFA.ACS_CDA_ACCOUNT_ID)
                   , nvl(PFAccountId, FFA.ACS_PF_ACCOUNT_ID)
                   , nvl(PJAccountId, FFA.ACS_PJ_ACCOUNT_ID)
                   , nvl(QtyAccountId, FFA.ACS_QTY_UNIT_ID)
                   , nvl(lFinancialAccountNumber, ACC1.ACC_NUMBER)
                   , nvl(lDivisionAccountNumber, ACC2.ACC_NUMBER)
                   , nvl(lCPNAccountNumber, ACC3.ACC_NUMBER)
                   , nvl(lCDAAccountNumber, ACC4.ACC_NUMBER)
                   , nvl(lPFAccountNumber, ACC5.ACC_NUMBER)
                   , nvl(lPJAccountNumber, ACC6.ACC_NUMBER)
                   , nvl(lQtyAccountNumber, ACC7.ACC_NUMBER)
                into FinancialAccountId
                   , DivisionAccountId
                   , CPNAccountId
                   , CDAAccountId
                   , PFAccountId
                   , PJAccountId
                   , QtyAccountId
                   , lFinancialAccountNumber
                   , lDivisionAccountNumber
                   , lCPNAccountNumber
                   , lCDAAccountNumber
                   , lPFAccountNumber
                   , lPJAccountNumber
                   , lQtyAccountNumber
                from FAL_FACTORY_ACCOUNT FFA
                   , ACS_ACCOUNT ACC1
                   , ACS_ACCOUNT ACC2
                   , ACS_ACCOUNT ACC3
                   , ACS_ACCOUNT ACC4
                   , ACS_ACCOUNT ACC5
                   , ACS_ACCOUNT ACC6
                   , ACS_ACCOUNT ACC7
               where FFA.C_FAL_ENTRY_TYPE = iEntryType
                 and FFA.C_FAL_ENTRY_SIGN = iEntrySign
                 and FFA.GAL_COST_CENTER_ID = iGalCostCenterId
                 and ACC1.ACS_ACCOUNT_ID(+) = FFA.ACS_FINANCIAL_ACCOUNT_ID
                 and ACC2.ACS_ACCOUNT_ID(+) = FFA.ACS_DIVISION_ACCOUNT_ID
                 and ACC3.ACS_ACCOUNT_ID(+) = FFA.ACS_CPN_ACCOUNT_ID
                 and ACC4.ACS_ACCOUNT_ID(+) = FFA.ACS_CDA_ACCOUNT_ID
                 and ACC5.ACS_ACCOUNT_ID(+) = FFA.ACS_PF_ACCOUNT_ID
                 and ACC6.ACS_ACCOUNT_ID(+) = FFA.ACS_PJ_ACCOUNT_ID
                 and ACC7.ACS_ACCOUNT_ID(+) = FFA.ACS_QTY_UNIT_ID;
            exception
              when no_data_found then
                null;
            end;
          end if;

          -- Recherche du centre d'analyse par défaut sur la ressource
          if     CDAAccountId is null
             and iFalFactoryFloorId is not null then
            select ACS_CDA_ACCOUNT_ID
                 , ACC.ACC_NUMBER
              into CDAAccountId
                 , lCPNAccountNumber
              from FAL_FACTORY_FLOOR FAC
                 , ACS_ACCOUNT ACC
             where FAC.FAL_FACTORY_FLOOR_ID = iFalFactoryFloorId
               and ACC.ACS_ACCOUNT_ID(+) = FAC.ACS_CDA_ACCOUNT_ID;
          end if;

          -- Recherche de la charge par nature et du centre d'analyse par défaut sur la nature analytique
          if     (   CPNAccountId is null
                  or CDAAccountId is null)
             and iGalCostCenterId is not null then
            select nvl(CPNAccountId, ACS_CPN_ACCOUNT_ID)
                 , nvl(CDAAccountId, ACS_CDA_ACCOUNT_ID)
                 , nvl(lCPNAccountNumber, ACC_CPN.ACC_NUMBER)
                 , nvl(lCDAAccountNumber, ACC_CDA.ACC_NUMBER)
              into CPNAccountId
                 , CDAAccountId
                 , lCPNAccountNumber
                 , lCDAAccountNumber
              from GAL_COST_CENTER GCC
                 , ACS_ACCOUNT ACC_CPN
                 , ACS_ACCOUNT ACC_CDA
             where GCC.GAL_COST_CENTER_ID = iGalCostCenterId
               and ACC_CPN.ACS_ACCOUNT_ID(+) = GCC.ACS_CPN_ACCOUNT_ID
               and ACC_CDA.ACS_ACCOUNT_ID(+) = GCC.ACS_CDA_ACCOUNT_ID;
          end if;

          /* Ajoute les informations de recherche des comptes */
          AddInformation('Imputations d''avancement' ||
                         CO.cLineBreak ||
                         CO.cLineBreak ||
                         'EntryType : ' ||
                         iEntryType ||
                         CO.cLineBreak ||
                         'EntrySign : ' ||
                         iEntrySign ||
                         CO.cLineBreak ||
                         'FactoryFloor : ' ||
                         iFalFactoryFloorId ||
                         CO.cLineBreak ||
                         'CostCenter : ' ||
                         iGalCostCenterId ||
                         CO.cLineBreak ||
                         '---' ||
                         CO.cLineBreak ||
                         'Financier : ' ||
                         lFinancialAccountNumber ||
                         CO.cLineBreak ||
                         'Division : ' ||
                         lDivisionAccountNumber ||
                         CO.cLineBreak ||
                         'CPN : ' ||
                         lCPNAccountNumber ||
                         CO.cLineBreak ||
                         'CDA : ' ||
                         lCDAAccountNumber ||
                         CO.cLineBreak ||
                         'PF : ' ||
                         lPFAccountNumber ||
                         CO.cLineBreak ||
                         'PJ : ' ||
                         lPJAccountNumber ||
                         CO.cLineBreak ||
                         'QTY : ' ||
                         lQtyAccountNumber
                        );
          ioFinancialAccountId  := nvl(ioFinancialAccountId, FinancialAccountId);
          ioDivisionAccountId   := nvl(ioDivisionAccountId, DivisionAccountId);
          ioCPNAccountId        := nvl(ioCPNAccountId, CPNAccountId);
          ioCDAAccountId        := nvl(ioCDAAccountId, CDAAccountId);
          ioPFAccountId         := nvl(ioPFAccountId, PFAccountId);
          ioPJAccountId         := nvl(ioPJAccountId, PJAccountId);
          ioQtyAccountId        := nvl(ioQtyAccountId, QtyAccountId);
        end if;
      end if;

      /* Si pas de gestion ou initialisation des comptes analytiques */
      if (lAnalytical = 0) then
        ioCPNAccountId  := null;
        ioCDAAccountId  := null;
        ioPFAccountId   := null;
        ioPJAccountId   := null;
      end if;
    else   /* Pas de gestion ou d'initialisation des comptes */
      ioFinancialAccountId  := null;
      ioDivisionAccountId   := null;
      ioCPNAccountId        := null;
      ioCDAAccountId        := null;
      ioPFAccountId         := null;
      ioPJAccountId         := null;
      ioQtyAccountId        := null;
    end if;   /* ( lFinancial = 1 ) or ( lAnalytical = 1 ) */
  end DefineFinancialImputation;

  /**
  * Description : Contrôle si les imputations (centre d'analyse, porteur et
  *               projet) avec la charge par nature sont autorisées.
  */
  procedure CheckAccountPermission(
    iFinancialAccountId in     number
  , ioDivisionAccountId in out number
  , ioCPNAccountId      in out number
  , ioCDAAccountId      in out number
  , ioPFAccountId       in out number
  , ioPJAccountId       in out number
  , iRefdate            in     date default sysdate
  )
  is
    cpnAccountId ACS_FINANCIAL_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
  begin
    -- vérifie les autorisations sur le compte division
    if ioDivisionAccountId is not null then
      if (ACS_FUNCTION.ExistDIVI = 0) then
        ioDivisionAccountId  := null;
      else
        ioDivisionAccountId  := ACS_FUNCTION.GetDivisionOfAccount(iFinancialAccountId, ioDivisionAccountId, iRefDate, GetDivisionUserId);
      end if;
    end if;

    if    (ioCPNAccountId is not null)
       or (iFinancialAccountId is not null) then
      -- Recherche le CPN du compte financier. Si aucun CPN sur le compte, l'analytique n'est pas géré. Dans le cas
      -- contraire, on prend le CPN passé en paramètre ou s'il est nulle, le CPN du compte financier.
      select max(ACS_CPN_ACCOUNT_ID)
        into cpnAccountId
        from ACS_FINANCIAL_ACCOUNT
       where ACS_FINANCIAL_ACCOUNT_ID = iFinancialAccountId;

      if cpnAccountId is null then
        ioCPNAccountId  := cpnAccountId;
      else
        ioCPNAccountId  := nvl(ioCPNAccountId, cpnAccountId);
      end if;

      if (ioCPNAccountId is not null) then
        begin
          -- Si l'imputation CDA,PF ou PJ n'est pas autorisée pour le CPN,
          -- il faut effacer le compte CDA,PF ou PJ correspondant
          select decode(C_CDA_IMPUTATION, '3', null, ioCDAAccountId) CDA_ACCOUNT
               , decode(C_PF_IMPUTATION, '3', null, ioPFAccountId) PF_ACCOUNT
               , decode(C_PJ_IMPUTATION, '3', null, ioPJAccountId) PJ_ACCOUNT
            into ioCDAAccountId
               , ioPFAccountId
               , ioPJAccountId
            from ACS_CPN_ACCOUNT
           where ACS_CPN_ACCOUNT_ID = ioCPNAccountId;
        exception
          when no_data_found then
            ioCDAAccountId  := null;
            ioPJAccountId   := null;
            ioPFAccountId   := null;
        end;
      else
        ioCDAAccountId  := null;
        ioPJAccountId   := null;
        ioPFAccountId   := null;
      end if;
    end if;
  end CheckAccountPermission;

  /**
  * Description : Recherche la personne hrm en fonction du numéro d'employé
  */
  function GetHrmPerson(iEmpNumber in varchar2)
    return number
  is
    lPersonId HRM_PERSON.HRM_PERSON_ID%type;
  begin
    if iEmpNumber is not null then
      begin
        select HRM_PERSON_ID
          into lPersonId
          from HRM_PERSON
         where PER_IS_EMPLOYEE = 1
           and EMP_NUMBER = iEmpNumber
           and (   EMP_STATUS = 'SUS'
                or EMP_STATUS = 'ACT');
      exception
        when no_data_found then
          lPersonId  := null;
      end;
    end if;

    return lPersonId;
  end GetHrmPerson;

  /**
  * Description : Recherche du numéro d'employé en fonction de la personne HRM
  */
  function GetEmpNumber(iHrmPersonId in number)
    return varchar2
  is
    lEmpNumber HRM_PERSON.EMP_NUMBER%type;
  begin
    if iHrmPersonId is not null then
      begin
        select EMP_NUMBER
          into lEmpNumber
          from HRM_PERSON
         where PER_IS_EMPLOYEE = 1
           and HRM_PERSON_ID = iHrmPersonId
           and (   EMP_STATUS = 'SUS'
                or EMP_STATUS = 'ACT');
      exception
        when no_data_found then
          lEmpNumber  := null;
      end;
    end if;

    return lEmpNumber;
  end GetEmpNumber;

  /**
  * Description : Recherche des comptes position et position valeur mais
  *               également avec contrôle des imputations.
  */
  procedure GetAccounts(
    iElementId       in     number
  , iElementType     in     varchar2
  , iAdminDomain     in     varchar2
  , iDateRef         in     date
  , iGoodId          in     number
  , iGaugeId         in     number
  , iDocumentId      in     number
  , iPositionId      in     number
  , iRecordId        in     number
  , iThirdId         in     number
  , iInFinancialId   in     number
  , iInDivisionId    in     number
  , iInCPNAccountId  in     number
  , iInCDAAccountId  in     number
  , iInPFAccountId   in     number
  , iInPJAccountId   in     number
  , ioFinancialId    in out number
  , ioDivisionId     in out number
  , iOutCPNAccountId in out number
  , iOutCDAAccountId in out number
  , iOutPFAccountId  in out number
  , iOutPJAccountId  in out number
  , iotAccountInfo   in out tAccountInfo
  )
  is
    accInFinancialId   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accInDivisionId    ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accInCPNAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accInCDAAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accInPFAccountId   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accInPJAccountId   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accOutFinancialId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accOutDivisionId   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accOutCPNAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accOutCDAAccountId ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accOutPFAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    accOutPJAccountId  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    /**
    * Garantit une valeur nulle si 0 est transmit.
    */
    accInFinancialId    := zvl(iInFinancialId, null);
    accInDivisionId     := zvl(iInDivisionId, null);
    accInCPNAccountId   := zvl(iInCPNAccountId, null);
    accInCDAAccountId   := zvl(iInCDAAccountId, null);
    accInPFAccountId    := zvl(iInPFAccountId, null);
    accInPJAccountId    := zvl(iInPJAccountId, null);
    accOutFinancialId   := zvl(ioFinancialId, null);
    accOutDivisionId    := zvl(ioDivisionId, null);
    accOutCPNAccountId  := zvl(iOutCPNAccountId, null);
    accOutCDAAccountId  := zvl(iOutCDAAccountId, null);
    accOutPFAccountId   := zvl(iOutPFAccountId, null);
    accOutPJAccountId   := zvl(iOutPJAccountId, null);

    if (iElementType = cgEtGoodsPosition) then   -- Position bien
      /**
      * Initialisation des comptes positions, positions valeurs
      */
      GetPosAccounts(iElementId
                   , iElementType
                   , iAdminDomain
                   , iDateRef
                   , iGoodId
                   , iGaugeId
                   , iDocumentId
                   , iPositionId
                   , iRecordId
                   , iThirdId
                   , accInFinancialId
                   , accInDivisionId
                   , accInCPNAccountId
                   , accInCDAAccountId
                   , accInPFAccountId
                   , accInPJAccountId
                   , accOutFinancialId
                   , accOutDivisionId
                   , accOutCPNAccountId
                   , accOutCDAAccountId
                   , accOutPFAccountId
                   , accOutPJAccountId
                   , iotAccountInfo
                    );
      /*
      raise_application_error(-20100,
                              iotAccountInfo.DEF_HRM_PERSON         || CO.cLineBreak ||
                              iotAccountInfo.FAM_FIXED_ASSETS_ID    || CO.cLineBreak ||
                              iotAccountInfo.C_FAM_TRANSACTION_TYP  || CO.cLineBreak ||
                              iotAccountInfo.DEF_NUMBER1            || CO.cLineBreak ||
                              iotAccountInfo.DEF_NUMBER2            || CO.cLineBreak ||
                              iotAccountInfo.DEF_NUMBER3            || CO.cLineBreak ||
                              iotAccountInfo.DEF_NUMBER4            || CO.cLineBreak ||
                              iotAccountInfo.DEF_NUMBER5            || CO.cLineBreak ||
                              iotAccountInfo.DEF_TEXT1              || CO.cLineBreak ||
                              iotAccountInfo.DEF_TEXT2              || CO.cLineBreak ||
                              iotAccountInfo.DEF_TEXT3              || CO.cLineBreak ||
                              iotAccountInfo.DEF_TEXT4              || CO.cLineBreak ||
                              iotAccountInfo.DEF_TEXT5              || CO.cLineBreak ||
                              iotAccountInfo.DEF_DIC_IMP_FREE1      || CO.cLineBreak ||
                              iotAccountInfo.DEF_DIC_IMP_FREE2      || CO.cLineBreak ||
                              iotAccountInfo.DEF_DIC_IMP_FREE3      || CO.cLineBreak ||
                              iotAccountInfo.DEF_DIC_IMP_FREE4      || CO.cLineBreak ||
                              iotAccountInfo.DEF_DIC_IMP_FREE5);
      */
      /*
      raise_application_error(-20100,
                              iElementId       || CO.cLineBreak ||
                              iElementType     || CO.cLineBreak ||
                              iAdminDomain     || CO.cLineBreak ||
                              iDateRef         || CO.cLineBreak ||
                              iGoodId          || CO.cLineBreak ||
                              iGaugeId         || CO.cLineBreak ||
                              iDocumentId      || CO.cLineBreak ||
                              iPositionId      || CO.cLineBreak ||
                              iRecordId        || CO.cLineBreak ||
                              iThirdId         || CO.cLineBreak ||
                              accInFinancialId   || CO.cLineBreak ||
                              accInDivisionId    || CO.cLineBreak ||
                              accInCPNAccountId  || CO.cLineBreak ||
                              accInCDAAccountId  || CO.cLineBreak ||
                              accInPFAccountId   || CO.cLineBreak ||
                              accInPJAccountId   || CO.cLineBreak ||
                              accOutFinancialId  || CO.cLineBreak ||
                              accOutDivisionId   || CO.cLineBreak ||
                              accOutCPNAccountId || CO.cLineBreak ||
                              accOutCDAAccountId || CO.cLineBreak ||
                              accOutPFAccountId  || CO.cLineBreak ||
                              accOutPJAccountId);
      */

      /**
      * Méthode de détermination du compte financier et du compte division pour
      * toutes les imputations gèrées dans un document.
      */
      DefineFinancialImputation(iCode                  => 2
                              , iGoodId                => iGoodId
                              , iChargeId              => 0
                              , iLocationId            => 0   -- Emplacement de stock logique. Utilisé uniquement avec iCode = 7.
                              , iStockId               => 0
                              , iMovementKindId        => 0
                              , iGaugeId               => iGaugeId
                              , iAdminDomain           => iAdminDomain
                              , iMovementType          => ''
                              , iChargeType            => ''
                              , ioFinancialAccountId   => accOutFinancialId
                              , ioDivisionAccountId    => accOutDivisionId
                              , ioCPNAccountId         => accOutCPNAccountId
                              , ioCDAAccountId         => accOutCDAAccountId
                              , ioPFAccountId          => accOutPFAccountId
                              , ioPJAccountId          => accOutPJAccountId
                               );
      /* Inscrit éventuellement le résultat de la recherche des comptes dans la
         table DOC_UPDATE_HISTORY */
      WriteInformation(iDocumentId, 'Position ' || iPositionId);
      /**
      * Contrôle si les imputations (centre d'analyse, porteur et projet) avec la
      * charge par nature sont autorisées.
      */
      CheckAccountPermission(accOutFinancialId, accOutDivisionId, accOutCPNAccountId, accOutCDAAccountId, accOutPFAccountId, accOutPJAccountId, iDateRef);
    elsif(iElementType = cgEtPositionValue) then   -- Position valeur
      /**
      * Initialisation des comptes positions, positions valeurs
      */
      GetPosAccounts(iElementId
                   , iElementType
                   , iAdminDomain
                   , iDateRef
                   , iGoodId
                   , iGaugeId
                   , iDocumentId
                   , iPositionId
                   , iRecordId
                   , iThirdId
                   , accInFinancialId
                   , accInDivisionId
                   , accInCPNAccountId
                   , accInCDAAccountId
                   , accInPFAccountId
                   , accInPJAccountId
                   , accOutFinancialId
                   , accOutDivisionId
                   , accOutCPNAccountId
                   , accOutCDAAccountId
                   , accOutPFAccountId
                   , accOutPJAccountId
                   , iotAccountInfo
                    );
      /**
      * Méthode de détermination du compte financier et du compte division pour
      * toutes les imputations gèrées dans un document.
      */
      DefineFinancialImputation(iCode                  => 3
                              , iGoodId                => 0
                              , iChargeId              => 0
                              , iLocationId            => 0   -- Emplacement de stock logique. Utilisé uniquement avec iCode = 7.
                              , iStockId               => 0
                              , iMovementKindId        => 0
                              , iGaugeId               => iGaugeId
                              , iAdminDomain           => iAdminDomain
                              , iMovementType          => ''
                              , iChargeType            => ''
                              , ioFinancialAccountId   => accOutFinancialId
                              , ioDivisionAccountId    => accOutDivisionId
                              , ioCPNAccountId         => accOutCPNAccountId
                              , ioCDAAccountId         => accOutCDAAccountId
                              , ioPFAccountId          => accOutPFAccountId
                              , ioPJAccountId          => accOutPJAccountId
                               );
      /* Inscrit éventuellement le résultat de la recherche des comptes dans la
         table DOC_UPDATE_HISTORY */
      WriteInformation(iDocumentId, 'Position valeur ' || iPositionId);
      /**
      * Contrôle si les imputations (centre d'analyse, porteur et projet) avec la
      * charge par nature sont autorisées.
      */
      CheckAccountPermission(accOutFinancialId, accOutDivisionId, accOutCPNAccountId, accOutCDAAccountId, accOutPFAccountId, accOutPJAccountId, iDateRef);
    else
      GetDCAccounts(iElementId
                  , iElementType
                  , iAdminDomain
                  , iDateRef
                  , iGaugeId
                  , iDocumentId
                  , iPositionId
                  , iRecordId
                  , iThirdId
                  , accInFinancialId
                  , accInDivisionId
                  , accInCPNAccountId
                  , accInCDAAccountId
                  , accInPFAccountId
                  , accInPJAccountId
                  , accOutFinancialId
                  , accOutDivisionId
                  , accOutCPNAccountId
                  , accOutCDAAccountId
                  , accOutPFAccountId
                  , accOutPJAccountId
                  , iotAccountInfo
                   );
    end if;

    ioFinancialId       := accOutFinancialId;
    ioDivisionId        := accOutDivisionId;
    iOutCPNAccountId    := accOutCPNAccountId;
    iOutCDAAccountId    := accOutCDAAccountId;
    iOutPFAccountId     := accOutPFAccountId;
    iOutPJAccountId     := accOutPJAccountId;
  end GetAccounts;

  procedure SetValue(iFromValue in number, iToValue in out number)
  is
  begin
    iToValue  := iFromValue;
  end SetValue;

  procedure SetValue(iFromValue in varchar2, iToValue in out varchar2)
  is
  begin
    iToValue  := iFromValue;
  end SetValue;

  procedure SetValue(iFromValue in date, iToValue in out date)
  is
  begin
    iToValue  := iFromValue;
  end SetValue;

  function GetInformation
    return varchar2
  is
  begin
    return gtAccountInfo;
  end GetInformation;

  procedure SetInformation(iInfo in varchar2)
  is
  begin
    gtAccountInfo  := substr(iInfo, 1, 2000);
  end SetInformation;

  procedure AddInformation(iInfo in varchar2)
  is
  begin
    if gtAccountInfo is null then
      gtAccountInfo  := substr(iInfo || CO.cLineBreak, 1, 2000);
    else
      gtAccountInfo  := substr(gtAccountInfo || CO.cLineBreak || iInfo || CO.cLineBreak, 1, 2000);
    end if;
  end AddInformation;

  procedure WriteInformation(iDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iType varchar2)
  is
    dmtNumber DOC_DOCUMENT.DMT_NUMBER%type;
  begin
    if     (PCS.PC_CONFIG.GetConfig('DOC_ACTIVATE_ACCOUNT_TRACE') = '1')
       and (GetInformation is not null) then
      if iDocumentId is not null then
        begin
          select DMT_NUMBER
            into dmtNumber
            from DOC_DOCUMENT
           where DOC_DOCUMENT_ID = iDocumentId;
        exception
          when no_data_found then
            dmtNumber  := 'NO_DATA_FOUND';
        end;
      end if;

      DOC_FUNCTIONS.CreateHistoryInformation(iDocumentId
                                           , null   -- DOC_POSITION_ID
                                           , dmtNumber   -- no de document
                                           , 'PLSQL'   -- DUH_TYPE
                                           , 'Getting account information : ' || iType
                                           , GetInformation   -- description libre
                                           , null   -- status document
                                           , null   -- status position
                                            );
    end if;

    /* Vide la variable global des informations */
    SetInformation(null);
  end WriteInformation;

  /**
  * Description
  *    retourne l'id de l'utilisateur connecté en fonction de la config FIN_CTRL_USER_DIV_ACCOUNT
  */
  function GetDivisionUserId
    return number
  is
  begin
    if PCS.PC_CONFIG.GetConfig('FIN_CTRL_USER_DIV_ACCOUNT') = '2' then
      return null;
    else
      return PCS.PC_I_LIB_SESSION.GetUserId;
    end if;
  end GetDivisionUserId;

  /**
  * Description
  *   retourne l'id de la division passée en paramètre si la configuration et les droits du user le permettent
  */
  function GetUserDivision(ioDivisionAccountId ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type)
    return number
  is
  begin
    if ACS_FUNCTION.IsDivisionAuthorized(ioDivisionAccountId, GetDivisionUserId) = 1 then
      return ioDivisionAccountId;
    else
      return null;
    end if;
  end GetUserDivision;

  /**
  * function GetFinancialReference
  * Description
  *   Retourne l'id de la référence financière d'un tiers pour la création de document
  */
  function GetFinancialReference(
    iThirdId       in PAC_THIRD.PAC_THIRD_ID%type
  , iAdminDomain   in DOC_GAUGE.C_ADMIN_DOMAIN%type
  , iDocCurrencyId in DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type
  , iPayMethodId   in ACS_PAYMENT_METHOD.ACS_PAYMENT_METHOD_ID%type
  )
    return PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%type
  is
    /* Monnaie document = Monnaie locale
    Recherche des références financières dont la méthode de paiement = la méthode de paiement du document ET
         dont la monnaie = la monnaie de base ou la monnaie est nulle
      Parmi les références financières identifiées, on appliquera dans l'ordre
        1. La référence financière 'valide' par défaut dans la monnaie de base ou sans monnaie
        2. La référece financière 'valide' avec le plus petit numéro de compte (MIN) dans la monnaie de base ou sans monnaie
    Recherche des références financières dont la méthode de paiement est null ET
         dont la monnaie = la monnaie de base ou la monnaie est nulle
      Parmi les références financières identifiées, on appliquera dans l'ordre
        1. La référence financière 'valide' par défaut dans la monnaie de base ou sans monnaie
        2. La référece financière 'valide' avec le plus petit numéro de compte (MIN) dans la monnaie de base ou sans monnaie
    */
    cursor crLocalCurrRef(cLocalCur in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type)
    is
      select   FRE.PAC_FINANCIAL_REFERENCE_ID
          from PAC_FINANCIAL_REFERENCE FRE
             , (select (case
                          when iAdminDomain in(gcAdPurchases, gcAdSubcontracting) then FRE_SUP.PAC_FINANCIAL_REFERENCE_ID
                          when iAdminDomain in(gcAdSales, gcAdAfterSalesService) then FRE_CUS.PAC_FINANCIAL_REFERENCE_ID
                          else nvl(FRE_CUS.PAC_FINANCIAL_REFERENCE_ID, FRE_SUP.PAC_FINANCIAL_REFERENCE_ID)
                        end
                       ) PAC_FINANCIAL_REFERENCE_ID
                  from PAC_THIRD THI
                     , PAC_FINANCIAL_REFERENCE FRE_CUS
                     , PAC_FINANCIAL_REFERENCE FRE_SUP
                 where THI.PAC_THIRD_ID = iThirdId
                   and FRE_CUS.C_PARTNER_STATUS(+) = '1'
                   and FRE_SUP.C_PARTNER_STATUS(+) = '1'
                   and THI.PAC_THIRD_ID = FRE_CUS.PAC_CUSTOM_PARTNER_ID(+)
                   and THI.PAC_THIRD_ID = FRE_SUP.PAC_SUPPLIER_PARTNER_ID(+)) FRE_THI
             , (select ACS_PAYMENT_METHOD_ID
                  from ACS_FIN_ACC_S_PAYMENT
                 where ACS_FIN_ACC_S_PAYMENT_ID = iPayMethodId) FAS
         where FRE.PAC_FINANCIAL_REFERENCE_ID = FRE_THI.PAC_FINANCIAL_REFERENCE_ID
           and (    (FRE.ACS_PAYMENT_METHOD_ID = FAS.ACS_PAYMENT_METHOD_ID)
                or (FRE.ACS_PAYMENT_METHOD_ID is null) )
           and nvl(FRE.ACS_FINANCIAL_CURRENCY_ID, cLocalCur) = cLocalCur
      order by FRE.ACS_PAYMENT_METHOD_ID desc nulls last
             , FRE.FRE_DEFAULT desc
             , FRE.FRE_ACCOUNT_NUMBER asc;

    /*  Document en monnaie étrangère
    Recherche des références financières dont la méthode de paiement = la méthode de paiement du document.
      Parmi les références financières identifiées, on appliquera dans l'ordre
        1. La référence financière 'valide' par défaut dans la monnaie du document
        2. La référence financière 'valide' avec le plus petit numéro de compte (MIN) dans la monnaie du document
        3. La référence financière 'valide' par défaut dans la monnaie de base ou sans monnaie
        4. La référence financière 'valide' avec le plus petit numéro de compte (MIN) dans la monnaie de base ou sans monnaie
    Recherche des références financières dont la méthode de paiement est null
      Parmi les références financières identifiées, on appliquera dans l'ordre
        1. La référence financière 'valide' par défaut dans la monnaie du document
        2. La référence financière 'valide' avec le plus petit numéro de compte (MIN) dans la monnaie du document
        3. La référence financière 'valide' par défaut dans la monnaie de base ou sans monnaie
        4. La référence financière 'valide' avec le plus petit numéro de compte (MIN) dans la monnaie de base ou sans monnaie
    */
    cursor crForeignCurrRef(cLocalCur in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type)
    is
      select   FRE.PAC_FINANCIAL_REFERENCE_ID
          from PAC_FINANCIAL_REFERENCE FRE
             , (select (case
                          when iAdminDomain in(gcAdPurchases, gcAdSubcontracting) then FRE_SUP.PAC_FINANCIAL_REFERENCE_ID
                          when iAdminDomain in(gcAdSales, gcAdAfterSalesService) then FRE_CUS.PAC_FINANCIAL_REFERENCE_ID
                          else nvl(FRE_CUS.PAC_FINANCIAL_REFERENCE_ID, FRE_SUP.PAC_FINANCIAL_REFERENCE_ID)
                        end
                       ) PAC_FINANCIAL_REFERENCE_ID
                  from PAC_THIRD THI
                     , PAC_FINANCIAL_REFERENCE FRE_CUS
                     , PAC_FINANCIAL_REFERENCE FRE_SUP
                 where THI.PAC_THIRD_ID = iThirdId
                   and FRE_CUS.C_PARTNER_STATUS(+) = '1'
                   and FRE_SUP.C_PARTNER_STATUS(+) = '1'
                   and THI.PAC_THIRD_ID = FRE_CUS.PAC_CUSTOM_PARTNER_ID(+)
                   and THI.PAC_THIRD_ID = FRE_SUP.PAC_SUPPLIER_PARTNER_ID(+)) FRE_THI
             , (select ACS_PAYMENT_METHOD_ID
                  from ACS_FIN_ACC_S_PAYMENT
                 where ACS_FIN_ACC_S_PAYMENT_ID = iPayMethodId) FAS
         where FRE.PAC_FINANCIAL_REFERENCE_ID = FRE_THI.PAC_FINANCIAL_REFERENCE_ID
           and (    (FRE.ACS_PAYMENT_METHOD_ID = FAS.ACS_PAYMENT_METHOD_ID)
                or (FRE.ACS_PAYMENT_METHOD_ID is null) )
           and nvl(FRE.ACS_FINANCIAL_CURRENCY_ID, iDocCurrencyId) in(iDocCurrencyId, cLocalCur)
      order by FRE.ACS_PAYMENT_METHOD_ID desc nulls last
             , decode(FRE.ACS_FINANCIAL_CURRENCY_ID, iDocCurrencyId, 1, 0) desc
             , FRE.FRE_DEFAULT desc
             , FRE.FRE_ACCOUNT_NUMBER asc;

    lFinRefId PAC_FINANCIAL_REFERENCE.PAC_FINANCIAL_REFERENCE_ID%type;
    lLocalCur ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    lLocalCur  := ACS_FUNCTION.GetLocalCurrencyId;

    -- Monnaie document = Monnaie locale
    if iDocCurrencyId = lLocalCur then
      open crLocalCurrRef(lLocalCur);

      fetch crLocalCurrRef
       into lFinRefId;

      close crLocalCurrRef;
    else
      -- Document en monnaie étrangère
      open crForeignCurrRef(lLocalCur);

      fetch crForeignCurrRef
       into lFinRefId;

      close crForeignCurrRef;
    end if;

    return lFinRefId;
  end GetFinancialReference;
end ACS_LIB_LOGISTIC_FINANCIAL;
