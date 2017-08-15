--------------------------------------------------------
--  DDL for Package Body PAC_PUBLIC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_PUBLIC" 
is

  /**
  * Description
  *      Cette fonction retourne le montant total (Monnaie de base, monnaie �trang�re
  *      ou EURO) des �ch�ances d'un document partenaire
  */
  function GetAmountOfPartImputation(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type,
                                     aLC number) return number
  is
  begin

    return ACT_FUNCTIONS.GetAmountOfPartImputation(aACT_PART_IMPUTATION_ID, aLC);

  end GetAmountOfPartImputation;

  /**
  * Description
  *    Cette fonction retourne le montant total des paiements effectu�s (Monnaie
  *    de base, monnaie �trang�re ou EURO) des �ch�ances d'un document partenaire
  */
  function GetTotalAmountOfPartImputation(aACT_PART_IMPUTATION_ID ACT_PART_IMPUTATION.ACT_PART_IMPUTATION_ID%type,
                                          aLC number) return number
  is
  begin

    return ACT_FUNCTIONS.GetTotalAmountOfPartImputation(aACT_PART_IMPUTATION_ID, aLC);

  end GetTotalAmountOfPartImputation;


  /**
  * Description :
  *    Cette fonction retourne, sur la base d'un Id document un �ventuel autre Id
  *    document, avec le m�me partenaire et le m�me num�ro document partenaire,
  *    dans le cadre d'un m�me exercice comptable.
  */
  function GetDuplicateParDocument(aACT_DOCUMENT_ID ACT_DOCUMENT.ACT_DOCUMENT_ID%type) return ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  is
  begin

    return ACT_FUNCTIONS.GetDuplicateParDocument(aACT_DOCUMENT_ID);

  end GetDuplicateParDocument;

end PAC_PUBLIC;
