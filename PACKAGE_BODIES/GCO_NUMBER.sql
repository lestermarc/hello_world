--------------------------------------------------------
--  DDL for Package Body GCO_NUMBER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_NUMBER" 
is

  /**
  * Description
  *     Génération des checksum pour la numérotations d'article
  *     Bucherer
  */
  procedure FRML_1(aGoodId in GCO_GOOD.GCO_GOOD_ID%type,
                   aMajorReference in out GCO_GOOD.GOO_MAJOR_REFERENCE%type,
                   aReferenceMaxLength in number,
                   aReturnCode out number)
  is
    PZ number(15);
    tempReference GCO_GOOD.GOO_MAJOR_REFERENCE%type;
  begin

    -- formattage de la référence dans une variable
    tempReference := lpad(aMajorReference,aReferenceMaxLength-1,'0');

    -- Formule pour chercher le caractère à ajouter
    PZ := MOD(to_number(substr(tempReference,1,1))*3 +
              to_number(substr(tempReference,2,1))*8 +
              to_number(substr(tempReference,3,1))*7 +
              to_number(substr(tempReference,4,1))*4 +
              to_number(substr(tempReference,5,1))*3 +
              to_number(substr(tempReference,6,1))*2 +
              to_number(substr(tempReference,7,1))*1,10);

    -- Assignation de la référence de retour en y ajoutant le dernier caractère
    -- et en vérifiant la longueur maximum
    aMajorReference := substr(aMajorReference||to_char(PZ),1,aReferenceMaxLength);

    aReturnCode := 1;

  exception
    when others then
      aReturnCode := 0;
  end FRML_1;

end GCO_NUMBER;
