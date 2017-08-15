--------------------------------------------------------
--  DDL for Package Body PPS_INTERRO_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_INTERRO_FUNCTIONS" 
is
  /**
  * procedure PrepareNomenclatureInterro
  * Description
  *   Remplir la table de l'interrogation nomenclature avec les données concernant
  *     l'interrogation de type : "Interrogation nomenclature"
  */
  procedure PrepareNomenclatureInterro(aNomenclatureID in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
  is
  begin
    PPS_PRC_INTERRO.PrepareNomenclatureInterro(aNomenclatureID);
  end PrepareNomenclatureInterro;

  /**
  * procedure PrepareGoodInterro
  * Description
  *   Remplir la table de l'interrogation nomenclature avec les données concernant
  *     l'interrogation de type : "Interrogation cas d'emploi produit"
  */
  procedure PrepareGoodInterro(aGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    PPS_PRC_INTERRO.PrepareGoodInterro(aGoodID);
  end PrepareGoodInterro;

  /**
  * procedure PrepareGoodNomInterro
  * Description
  *   Remplir la table de l'interrogation nomenclature avec les données concernant
  *     l'interrogation de type : "Interrogation cas d'emploi version nomenclature"
  */
  procedure PrepareGoodNomInterro(
    aNomenclatureID in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , aSequence       in number default 10000
  , aClearTable     in integer default 1
  )
  is
  begin
    PPS_PRC_INTERRO.PrepareGoodNomInterro(aNomenclatureID => aNomenclatureID, aClearTable => aClearTable);
  end PrepareGoodNomInterro;

  /**
  * procedure PrepareGoodNoLinkNomInterro
  * Description
  *   Remplir la table de l'interrogation nomenclature avec les données concernant
  *     l'interrogation de type : "Interrogation cas d'emploi produit"
  *     mais dont le composant n'a pas de lien de version nomenclature
  */
  procedure PrepareGoodNoLinkNomInterro(aGoodID in GCO_GOOD.GCO_GOOD_ID%type, aSequence in number default 10000, aClearTable in integer default 1)
  is
  begin
    PPS_PRC_INTERRO.PrepareGoodNoLinkNomInterro(aGoodID, aSequence, aClearTable);
  end PrepareGoodNoLinkNomInterro;
end PPS_INTERRO_FUNCTIONS;
