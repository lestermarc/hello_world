--------------------------------------------------------
--  DDL for Package Body IND_ACT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_ACT_FUNCTIONS" 
   IS

function getExpAdapted(vDocumentid number) return date
  -- Retourne la date d'échéance d'un document
  -- Utilisé dans "Travaux comptables" => "FO - Pré-saisie créanciers" => "Etat => "Autres états" => "Documents pré-saisis à valider"
  is
  --retour varchar2(200);
  retour date;
begin

  select exp_adapted into retour
    from ACT_EXPIRY 
   where act_document_id = vDocumentid;
   
   return retour;
     
end getExpAdapted;

end IND_ACT_FUNCTIONS;
