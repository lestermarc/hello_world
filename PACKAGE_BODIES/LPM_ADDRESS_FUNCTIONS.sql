--------------------------------------------------------
--  DDL for Package Body LPM_ADDRESS_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LPM_ADDRESS_FUNCTIONS" 
is
  /**
  * function CheckAddress
  * Description
  *    Fonction permettant d'éxécuter une fonction d'individualisation si elle est spécifié dans la config LPM_CHECK_ADDRESS_FUNCTION
  *    Cette fonction devra permettre de définir les règles pour remonter oui ou non les addresses dans le projet de vie.
  * @author JFR
  * @param   aPacPersonId     Id de l'adresse (pac_person)
  * @return  Renvoie 1 si aucune fonction d'individualisation n'était spécifié dans la config LPM_CHECK_ADDRESS_FUNCTION
  *          Renvoie la de retour de la fonction si elle est spécifiée dans la config
  */
  function CheckAddress(
    aPacPersonId in PAC_PERSON.PAC_PERSON_ID%type
  )
    return integer
  is
    sqlStatement VARCHAR2(256);
    ReturnValue number;
  begin
    if PCS.PC_CONFIG.GetConfig('LPM_CHECK_ADDRESS_FUNCTION', LPM_LIB_VIEW_HRM.GetCompanyID, LPM_LIB_VIEW_HRM.GetConliID) is null then
      return 1;
    else
      sqlStatement := 'BEGIN :ReturnValue := ' || PCS.PC_CONFIG.GetConfig('LPM_CHECK_ADDRESS_FUNCTION', LPM_LIB_VIEW_HRM.GetCompanyID, LPM_LIB_VIEW_HRM.GetConliID) || '(:PAC_PERSON_ID); END;';

      -- execution de la commande
      EXECUTE IMMEDIATE
        sqlStatement
        USING out ReturnValue
            , aPacPersonId;

      return ReturnValue;
    end if;

  end CheckAddress;

end LPM_ADDRESS_FUNCTIONS;
