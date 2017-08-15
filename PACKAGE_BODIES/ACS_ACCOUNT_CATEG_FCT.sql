--------------------------------------------------------
--  DDL for Package Body ACS_ACCOUNT_CATEG_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_ACCOUNT_CATEG_FCT" 
As
  /**
  * function IsSubAccountAuthorized
  * Description
  *  Permet de filtrer le lkup des comptes lors du choix d'un sous-compte
  *  selon les paramètres de la catégorie de compte liée au compte
  **/

  function IsSubAccountAuthorized(pACS_ACCOUNT_CATEG_ID     ACS_ACCOUNT_CATEG.ACS_ACCOUNT_CATEG_ID%type,
                                  pACS_TESTED_ACCOUNT_ID    ACS_ACCOUNT.ACS_ACCOUNT_ID%type) return number
  is
    vACA_NO_SUB_ACCOUNT           ACS_ACCOUNT_CATEG.ACA_NO_SUB_ACCOUNT%type;
    vACS_PARENT_ACCOUNT_CATEG_ID  ACS_ACCOUNT_CATEG.ACS_ACCOUNT_CATEG_ID%type;
    vResult                       number default 1;
  begin
    if pACS_ACCOUNT_CATEG_ID = 0 then
    --pas de catégorie liée au compte => tous les comptes sont acceptés
      vResult := 1;
    else
      select
        nvl(max(cat.acs_sub_account_categ_id), 0),
        nvl(max(cat.aca_no_sub_account), 0)
      into
        vACS_PARENT_ACCOUNT_CATEG_ID,
        vACA_NO_SUB_ACCOUNT
      from
        acs_account_categ cat
      where
        cAT.acs_account_categ_id = Pacs_account_categ_id;
      if (vACS_PARENT_ACCOUNT_CATEG_ID > 0) and (vACA_NO_SUB_ACCOUNT = 1) then
      --contrôle que le compte pACS_TESTED_ACCOUNT_ID  n'appartient qu'à la catégorie parent liée
        select
          decode(acc.acs_account_categ_id,
                   vACS_PARENT_ACCOUNT_CATEG_ID, 1,
                   0)
        into vResult
        from
          acs_account acc
        where
          acc.acs_account_id = pACS_TESTED_ACCOUNT_ID;
      elsif (vACS_PARENT_ACCOUNT_CATEG_ID > 0) and (vACA_NO_SUB_ACCOUNT = 0) then
      --contrôle que le compte pACS_TESTED_ACCOUNT_ID  appartient à la catégorie parent liée ou à la catégorie liée
        select
          decode(acs_account_categ_id,
                   vACS_PARENT_ACCOUNT_CATEG_ID, 1,
                   pACS_ACCOUNT_CATEG_ID,        1,
                   0)
        into vResult
        from
          acs_account acc
        where
          acc.acs_account_id = pACS_TESTED_ACCOUNT_ID;
      elsif vACA_NO_SUB_ACCOUNT = 1 then
      --controle que le compte pACS_TESTED_ACCOUNT_ID n'appartient pas à la catégorie liée
        select
          decode(acs_account_categ_id,
                   pACS_ACCOUNT_CATEG_ID, 0,
                   1)
        into vResult
        from
          acs_account acc
        where
          acc.acs_account_id = pACS_TESTED_ACCOUNT_ID;
      end if;
    end if;
    return vResult;
  end IsSubAccountAuthorized;

  /**
  * function GetChildrenAccounts
  * Description
  *  Retourne les enfants du compte pACS_PARENT_ACCOUNT_ID jusqu'au niveau pMAX_LEVEL
  *  Exemple d'utilisation dans une commande SQL:
  *  select acc.*
  *  from  table(ACS_ACCOUNT_CATEG_FCT.GetChildrenAccounts(:pACS_PARENT_ACCOUNT_ID, :PMAX_LEVEL)) ChildrenAccount,
  *        acs_account acc
  *  where
  *        ChildrenAccount.column_VALUE = acc.acs_account_id
  *  order by
  *    acc.acc_number
  **/
  function GetChildrenAccounts(pACS_PARENT_ACCOUNT_ID     ACS_ACCOUNT.ACS_ACCOUNT_ID%type,
                               pMAX_LEVEL                 number,
                               pSHOW_PARENT               number := 1) return ID_TABLE_TYPE
  is
    vMAX_LEVEL number;
    vResult ID_TABLE_TYPE;
  begin
    --Niveau 1 = Parent  => Pour connaitre le niveau voulu, il faut ajouter 1 à pMAX_LEVEL
    --Ex: pMAX_LEVEL = 0 => recherche de tous les enfants
    --    pMAX_LEVEL = 1 => recherche du premier niveau enfants, etc...
    vMAX_LEVEL := pMAX_LEVEL + 1;
    select cast(multiset(
                        	select acc.acs_account_id
                          from   acs_account acc
                          where  level <= DECODE(vMAX_LEVEL, 1, LEVEL, vMAX_LEVEL) and --si parametre pMAX_LEVEL = 0 => afficher tous les niveaux
                                 level > decode(pSHOW_PARENT, 1, 0, 1) --Niveau parent = 1, donc premier enfant = 2
                          start with acc.acs_account_id =  pACS_PARENT_ACCOUNT_ID
                          connect by prior acs_account_id = acs_SUB_account_id
                        ) as ID_TABLE_TYPE
                )
              	into vResult
              	from dual;
    return vResult;
  end GetChildrenAccounts;

end ACS_ACCOUNT_CATEG_FCT;
