--------------------------------------------------------
--  DDL for Package Body DOC_DOCUMENT_DEMAT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DOCUMENT_DEMAT" 
is
  /**
  * procedure MatchRefresh
  * Description
  *   Méthode pour effectuer le rapprochement d'un document DOC_INTERFACE
  *     en complétant les liens de match déjà existants
  */
  procedure MatchRefresh(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
  begin
    DOC_INTERFACE_MATCHING.AutomaticMatch(aInterfaceID => aInterfaceID, aIntPositionID => null, aMode => '01');
  end MatchRefresh;

  /**
  * procedure MatchRedo
  * Description
  *   Méthode pour effectuer le rapprochement d'un document DOC_INTERFACE avec une
  *     reconstruction totale des rapprochements (effacement des rapprochements existants)
  */
  procedure MatchRedo(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
  begin
    DOC_INTERFACE_MATCHING.AutomaticMatch(aInterfaceID => aInterfaceID, aIntPositionID => null, aMode => '02');
  end MatchRedo;

  /**
  * function CtrlValidatePartial
  * Description
  *   Méthode pour controler et valider les rapprochements
  *     même s'il n'y a eu qu'un rapprochement partiel.
  */
  function CtrlValidatePartial(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    return integer
  is
    vControl  varchar2(10);
    vValidate integer      default 0;
  begin
    -- Effectuer le controle du rapprochement du document
    vControl  :=
         DOC_INTERFACE_MATCHING.ControlMatch(aInterfaceID     => aInterfaceID, aIntPositionID => null
                                           , aIntMatchID      => null);

    -- Résultat du controle
    -- 00 - rapprochement complet et correct
    -- 99 - Pas d'erreur mais au moins une position n'est pas totalement rapprochée
    if vControl in('00', '99') then
      -- Validation du rapprochement
      vValidate  := DOC_INTERFACE_MATCHING.ValidateMatch(aInterfaceID => aInterfaceID);
    end if;

    return vValidate;
  end CtrlValidatePartial;

  /**
  * function MatchValidatePartial
  * Description
  *   Méthode pour effectuer le rapprochement, controler et valider les rapprochements
  *     même s'il n'y a eu qu'un rapprochement partiel.
  */
  function MatchValidatePartial(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    return integer
  is
    vValidate integer default 0;
  begin
    -- Rapprochement du document en mode reconstruction du rapprochement
    MatchRedo(aInterfaceID => aInterfaceID);
    -- Effectuer le controle et la validation du rapprochement du document
    vValidate  := CtrlValidatePartial(aInterfaceID => aInterfaceID);
    return vValidate;
  end MatchValidatePartial;

  /**
  * function MatchValidateFull
  * Description
  *   Méthode pour effectuer le rapprochement, controler et valider les rapprochements
  *     avec un rapprochement complet uniquement.
  */
  function MatchValidateFull(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    return integer
  is
    vValidate integer default 0;
  begin
    -- Rapprochement du document en mode reconstruction du rapprochement
    MatchRedo(aInterfaceID => aInterfaceID);
    -- Effectuer le controle et la validation du rapprochement du document
    vValidate  := CtrlValidateFull(aInterfaceID => aInterfaceID);
    return vValidate;
  end MatchValidateFull;

  /**
  * function CtrlValidateFull
  * Description
  *   Méthode pour controler et valider les rapprochements
  *     avec un rapprochement complet uniquement.
  */
  function CtrlValidateFull(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    return integer
  is
    vControl  varchar2(10);
    vValidate integer      default 0;
  begin
    -- Effectuer le controle du rapprochement du document
    vControl  :=
         DOC_INTERFACE_MATCHING.ControlMatch(aInterfaceID     => aInterfaceID, aIntPositionID => null
                                           , aIntMatchID      => null);

    -- Résultat du controle
    -- 00 - rapprochement complet et correct
    if vControl = '00' then
      -- Validation du rapprochement
      vValidate  := DOC_INTERFACE_MATCHING.ValidateMatch(aInterfaceID => aInterfaceID);
    end if;

    return vValidate;
  end CtrlValidateFull;

  /**
  * procedure MatchAndGenerate
  * Description
  *   Méthode pour effectuer le rapprochement complet ou partiel et génération directe du document
  */
  procedure MatchGeneratePartial(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
    vCtrl     integer;
    vErrorMsg varchar2(4000);
    vDocList  varchar2(4000);
  begin
    -- Effectuer le rapprochement, controle et validation avec rapprochement complet ou partiel
    vCtrl  := MatchValidatePartial(aInterfaceID => aInterfaceID);
    commit;

    -- Si la validation du rapprochement s'est effectuée sans erreur, alors génération du document
    if vCtrl = 1 then
      DOC_DOCUMENT_GENERATOR.GenerateDocument(aInterfaceId          => aInterfaceID
                                            , aErrorMsg             => vErrorMsg
                                            , aNewDocumentsIdList   => vDocList
                                             );
    end if;
  end MatchGeneratePartial;

  /**
  * procedure MatchGenerateFull
  * Description
  *   Méthode pour effectuer le rapprochement complet et génération directe du document
  */
  procedure MatchGenerateFull(aInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
  is
    vCtrl     integer;
    vErrorMsg varchar2(4000);
    vDocList  varchar2(4000);
  begin
    -- Effectuer le rapprochement, controle et validation avec rapprochement complet ou partiel
    vCtrl  := MatchValidateFull(aInterfaceID => aInterfaceID);
    commit;

    -- Si la validation du rapprochement s'est effectuée sans erreur, alors génération du document
    if vCtrl = 1 then
      DOC_DOCUMENT_GENERATOR.GenerateDocument(aInterfaceId          => aInterfaceID
                                            , aErrorMsg             => vErrorMsg
                                            , aNewDocumentsIdList   => vDocList
                                             );
    end if;
  end MatchGenerateFull;
end DOC_DOCUMENT_DEMAT;
