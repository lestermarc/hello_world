--------------------------------------------------------
--  DDL for Package Body ACS_SUB_SET_ACC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_SUB_SET_ACC" 
is
  /**
   * Validation des comptes....
   * Procédure 'externe' à la validation des comptes
   * Canton du Jura (JU)
  **/
  procedure AccAccountJU(aACS_ACCOUNT_ID in ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
  is
    vACC_NUMBER              ACS_ACCOUNT.ACC_NUMBER%type;
    vACS_ACCOUNT_CATEG_ID    ACS_ACCOUNT_CATEG.ACS_ACCOUNT_CATEG_ID%type;
    vACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vACA_KEY                 ACS_ACCOUNT_CATEG.ACA_KEY%type;
  begin
    select max(ACC.ACC_NUMBER)
         , max(ACC.ACS_ACCOUNT_CATEG_ID)
         , max(CAT.ACA_KEY)
      into vACC_NUMBER
         , vACS_ACCOUNT_CATEG_ID
         , vACA_KEY
      from ACS_ACCOUNT_CATEG CAT
         , ACS_ACCOUNT ACC
     where ACC.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID
       and ACC.ACS_ACCOUNT_CATEG_ID = CAT.ACS_ACCOUNT_CATEG_ID;

    if     (vACC_NUMBER is not null)
       and (vACS_ACCOUNT_CATEG_ID > 0) then
      -- mise à jour de l'interaction avec la division (Tâche)
      if vACA_KEY <> 'Bilan' then
        select max(DIV.ACS_DIVISION_ACCOUNT_ID)
          into vACS_DIVISION_ACCOUNT_ID
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACC_NUMBER = substr(vACC_NUMBER, 0, 4);
      else
        select max(DIV.ACS_DIVISION_ACCOUNT_ID)
          into vACS_DIVISION_ACCOUNT_ID
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACC_NUMBER = '0000';
      end if;

      if vACS_DIVISION_ACCOUNT_ID is not null then
        -- Effacer toutes les interactions pour le compte passé en paramètre
        delete from ACS_INTERACTION
              where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

        --puis créer une nouvelle interaction
        insert into ACS_INTERACTION
                    (ACS_INTERACTION_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , INT_PAIR_DEFAULT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval
                   , aACS_ACCOUNT_ID
                   , vACS_DIVISION_ACCOUNT_ID
                   , '1'
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni2
                    );
      end if;
    end if;

    -- mise à jour des DICO
    if vACA_KEY <> 'Bilan' then
      -- 3 DICO pour les comptes <> Bilan
      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_1_ID = (select max(DIC_FIN_ACC_CODE_1_ID)
                                        from DIC_FIN_ACC_CODE_1
                                       where DIC_FIN_ACC_CODE_1_ID = substr(vACC_NUMBER, 6, 1) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_2_ID = (select max(DIC_FIN_ACC_CODE_2_ID)
                                        from DIC_FIN_ACC_CODE_2
                                       where DIC_FIN_ACC_CODE_2_ID = substr(vACC_NUMBER, 6, 2) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_3_ID = (select max(DIC_FIN_ACC_CODE_3_ID)
                                        from DIC_FIN_ACC_CODE_3
                                       where DIC_FIN_ACC_CODE_3_ID = substr(vACC_NUMBER, 6, 3) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      -- 3 DICO pour la structure des tâches (divisions)
      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_5_ID = (select max(DIC_FIN_ACC_CODE_5_ID)
                                        from DIC_FIN_ACC_CODE_5
                                       where DIC_FIN_ACC_CODE_5_ID = substr(vACC_NUMBER, 1, 1) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_6_ID = (select max(DIC_FIN_ACC_CODE_6_ID)
                                        from DIC_FIN_ACC_CODE_6
                                       where DIC_FIN_ACC_CODE_6_ID = substr(vACC_NUMBER, 1, 2) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_7_ID = (select max(DIC_FIN_ACC_CODE_7_ID)
                                        from DIC_FIN_ACC_CODE_7
                                       where DIC_FIN_ACC_CODE_7_ID = substr(vACC_NUMBER, 1, 3) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_8_ID = (select max(DIC_FIN_ACC_CODE_8_ID)
                                        from DIC_FIN_ACC_CODE_8
                                       where DIC_FIN_ACC_CODE_8_ID = substr(vACC_NUMBER, 1, 4) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_10_ID = '1'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and DIC_FIN_ACC_CODE_10_ID is null;
    else
      -- 4 DICO pour les comptes <> Bilan
      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_1_ID = (select max(DIC_FIN_ACC_CODE_1_ID)
                                        from DIC_FIN_ACC_CODE_1
                                       where DIC_FIN_ACC_CODE_1_ID = substr(vACC_NUMBER, 1, 1) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_2_ID = (select max(DIC_FIN_ACC_CODE_2_ID)
                                        from DIC_FIN_ACC_CODE_2
                                       where DIC_FIN_ACC_CODE_2_ID = substr(vACC_NUMBER, 1, 2) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_3_ID = (select max(DIC_FIN_ACC_CODE_3_ID)
                                        from DIC_FIN_ACC_CODE_3
                                       where DIC_FIN_ACC_CODE_3_ID = substr(vACC_NUMBER, 1, 3) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_4_ID = (select max(DIC_FIN_ACC_CODE_4_ID)
                                        from DIC_FIN_ACC_CODE_4
                                       where DIC_FIN_ACC_CODE_4_ID = substr(vACC_NUMBER, 1, 4) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_10_ID = '1'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and DIC_FIN_ACC_CODE_10_ID is null;
    end if;
  end AccAccountJU;

/**
* procedure AccAccountBE
* Description
*   Script exécuté à la validation d'un compte appartenant à une catégorie.
*/
  procedure AccAccountBE(aACS_ACCOUNT_ID in ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
  is
    vACC_NUMBER              ACS_ACCOUNT.ACC_NUMBER%type;
    vACS_ACCOUNT_CATEG_ID    ACS_ACCOUNT_CATEG.ACS_ACCOUNT_CATEG_ID%type;
    vACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vACA_KEY                 ACS_ACCOUNT_CATEG.ACA_KEY%type;
  begin
    select max(ACC.ACC_NUMBER)
         , max(ACC.ACS_ACCOUNT_CATEG_ID)
         , max(CAT.ACA_KEY)
      into vACC_NUMBER
         , vACS_ACCOUNT_CATEG_ID
         , vACA_KEY
      from ACS_ACCOUNT_CATEG CAT
         , ACS_ACCOUNT ACC
     where ACC.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID
       and ACC.ACS_ACCOUNT_CATEG_ID = CAT.ACS_ACCOUNT_CATEG_ID;

    if     (vACC_NUMBER is not null)
       and (vACS_ACCOUNT_CATEG_ID > 0) then
      -- mise à jour de l'interaction avec la division (Tâche)
      if vACA_KEY <> 'Bilan' then
        select max(DIV.ACS_DIVISION_ACCOUNT_ID)
          into vACS_DIVISION_ACCOUNT_ID
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACC_NUMBER = substr(vACC_NUMBER, 0, 3);
      else
        select max(DIV.ACS_DIVISION_ACCOUNT_ID)
          into vACS_DIVISION_ACCOUNT_ID
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACC_NUMBER = '000';
      end if;

      if vACS_DIVISION_ACCOUNT_ID is not null then
        -- Effacer toutes les interactions pour le compte passé en paramètre
        delete from ACS_INTERACTION
              where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

        --puis créer une nouvelle interaction
        insert into ACS_INTERACTION
                    (ACS_INTERACTION_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , INT_PAIR_DEFAULT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval
                   , aACS_ACCOUNT_ID
                   , vACS_DIVISION_ACCOUNT_ID
                   , '1'
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni2
                    );
      end if;
    end if;

    -- mise à jour des DICO
    if vACA_KEY <> 'Bilan' then
      -- 3 DICO pour les comptes <> Bilan
      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_1_ID = (select max(DIC_FIN_ACC_CODE_1_ID)
                                        from DIC_FIN_ACC_CODE_1
                                       where DIC_FIN_ACC_CODE_1_ID = substr(vACC_NUMBER, 5, 1) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_2_ID = (select max(DIC_FIN_ACC_CODE_2_ID)
                                        from DIC_FIN_ACC_CODE_2
                                       where DIC_FIN_ACC_CODE_2_ID = substr(vACC_NUMBER, 5, 2) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_3_ID = (select max(DIC_FIN_ACC_CODE_3_ID)
                                        from DIC_FIN_ACC_CODE_3
                                       where DIC_FIN_ACC_CODE_3_ID = substr(vACC_NUMBER, 5, 3) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      -- 3 DICO pour la structure des tâches (divisions)
      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_6_ID = (select max(DIC_FIN_ACC_CODE_6_ID)
                                        from DIC_FIN_ACC_CODE_6
                                       where DIC_FIN_ACC_CODE_6_ID = substr(vACC_NUMBER, 1, 1) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_7_ID = (select max(DIC_FIN_ACC_CODE_7_ID)
                                        from DIC_FIN_ACC_CODE_7
                                       where DIC_FIN_ACC_CODE_7_ID = substr(vACC_NUMBER, 1, 2) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_8_ID = (select max(DIC_FIN_ACC_CODE_8_ID)
                                        from DIC_FIN_ACC_CODE_8
                                       where DIC_FIN_ACC_CODE_8_ID = substr(vACC_NUMBER, 1, 3) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_10_ID = '1'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and DIC_FIN_ACC_CODE_10_ID is null;
    else
      -- 4 DICO pour les comptes <> Bilan
      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_1_ID = (select max(DIC_FIN_ACC_CODE_1_ID)
                                        from DIC_FIN_ACC_CODE_1
                                       where DIC_FIN_ACC_CODE_1_ID = substr(vACC_NUMBER, 1, 1) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_2_ID = (select max(DIC_FIN_ACC_CODE_2_ID)
                                        from DIC_FIN_ACC_CODE_2
                                       where DIC_FIN_ACC_CODE_2_ID = substr(vACC_NUMBER, 1, 2) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_3_ID = (select max(DIC_FIN_ACC_CODE_3_ID)
                                        from DIC_FIN_ACC_CODE_3
                                       where DIC_FIN_ACC_CODE_3_ID = substr(vACC_NUMBER, 1, 3) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_4_ID = (select max(DIC_FIN_ACC_CODE_4_ID)
                                        from DIC_FIN_ACC_CODE_4
                                       where DIC_FIN_ACC_CODE_4_ID = substr(vACC_NUMBER, 1, 4) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE_10_ID = '1'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and DIC_FIN_ACC_CODE_10_ID is null;
    end if;
  end AccAccountBE;

  /**
  * procedure AccAccountBEMCH2
  * Description
  *   Script exécuté à la validation d'un compte appartenant à une catégorie.
  */
  procedure AccAccountBEMCH2(aACS_ACCOUNT_ID in ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
  is
    vACC_NUMBER              ACS_ACCOUNT.ACC_NUMBER%type;
    vACS_ACCOUNT_CATEG_ID    ACS_ACCOUNT_CATEG.ACS_ACCOUNT_CATEG_ID%type;
    vACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vACA_KEY                 ACS_ACCOUNT_CATEG.ACA_KEY%type;
  begin
    select max(ACC.ACC_NUMBER)
         , max(ACC.ACS_ACCOUNT_CATEG_ID)
         , max(CAT.ACA_KEY)
      into vACC_NUMBER
         , vACS_ACCOUNT_CATEG_ID
         , vACA_KEY
      from ACS_ACCOUNT_CATEG CAT
         , ACS_ACCOUNT ACC
     where ACC.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID
       and ACC.ACS_ACCOUNT_CATEG_ID = CAT.ACS_ACCOUNT_CATEG_ID;

    if     (vACC_NUMBER is not null)
       and (vACS_ACCOUNT_CATEG_ID > 0) then
      -- mise à jour de l'interaction avec la division (Tâche)
      if vACA_KEY <> 'Bilan' then
        select max(DIV.ACS_DIVISION_ACCOUNT_ID)
          into vACS_DIVISION_ACCOUNT_ID
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACC_NUMBER = substr(vACC_NUMBER, 0, 4);
      else
        select max(DIV.ACS_DIVISION_ACCOUNT_ID)
          into vACS_DIVISION_ACCOUNT_ID
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACC_NUMBER = '0000';
      end if;

      if vACS_DIVISION_ACCOUNT_ID is not null then
        -- Effacer toutes les interactions pour le compte passé en paramètre
        delete from ACS_INTERACTION
              where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

        --puis créer une nouvelle interaction
        insert into ACS_INTERACTION
                    (ACS_INTERACTION_ID
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , INT_PAIR_DEFAULT
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval
                   , aACS_ACCOUNT_ID
                   , vACS_DIVISION_ACCOUNT_ID
                   , '1'
                   , sysdate
                   , PCS.PC_INIT_SESSION.GetUserIni2
                    );
      end if;
    end if;

    -- mise à jour des DICO
    if vACA_KEY <> 'Bilan' then
      -- 4 DICO pour les comptes <> Bilan
      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_1_ID = (select max(DIC_FIN_ACC_CODE2_1_ID)
                                        from DIC_FIN_ACC_CODE2_1
                                       where DIC_FIN_ACC_CODE2_1_ID = substr(vACC_NUMBER, 6, 1) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_2_ID = (select max(DIC_FIN_ACC_CODE2_2_ID)
                                        from DIC_FIN_ACC_CODE2_2
                                       where DIC_FIN_ACC_CODE2_2_ID = substr(vACC_NUMBER, 6, 2) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_3_ID = (select max(DIC_FIN_ACC_CODE2_3_ID)
                                        from DIC_FIN_ACC_CODE2_3
                                       where DIC_FIN_ACC_CODE2_3_ID = substr(vACC_NUMBER, 6, 3) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_4_ID = (select max(DIC_FIN_ACC_CODE2_4_ID)
                                        from DIC_FIN_ACC_CODE2_4
                                       where DIC_FIN_ACC_CODE2_4_ID = substr(vACC_NUMBER, 6, 4) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;


      -- 4 DICO pour la structure des fonctions (divisions)
      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_6_ID = (select max(DIC_FIN_ACC_CODE2_6_ID)
                                        from DIC_FIN_ACC_CODE2_6
                                       where DIC_FIN_ACC_CODE2_6_ID = substr(vACC_NUMBER, 1, 1) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_7_ID = (select max(DIC_FIN_ACC_CODE2_7_ID)
                                        from DIC_FIN_ACC_CODE2_7
                                       where DIC_FIN_ACC_CODE2_7_ID = substr(vACC_NUMBER, 1, 2) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_8_ID = (select max(DIC_FIN_ACC_CODE2_8_ID)
                                        from DIC_FIN_ACC_CODE2_8
                                       where DIC_FIN_ACC_CODE2_8_ID = substr(vACC_NUMBER, 1, 3) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_9_ID = (select max(DIC_FIN_ACC_CODE2_9_ID)
                                        from DIC_FIN_ACC_CODE2_9
                                       where DIC_FIN_ACC_CODE2_9_ID = substr(vACC_NUMBER, 1, 4) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;


      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_10_ID = '1'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and DIC_FIN_ACC_CODE2_10_ID is null;

       update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_15_ID = 'MCH2_OK'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and length(vACC_NUMBER) =12;

       update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_15_ID = 'MCH2_KO'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and length(vACC_NUMBER) <>12;


    else
      -- 5 DICO pour les comptes = Bilan
      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_1_ID = (select max(DIC_FIN_ACC_CODE2_1_ID)
                                        from DIC_FIN_ACC_CODE2_1
                                       where DIC_FIN_ACC_CODE2_1_ID = substr(vACC_NUMBER, 1, 1) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_2_ID = (select max(DIC_FIN_ACC_CODE2_2_ID)
                                        from DIC_FIN_ACC_CODE2_2
                                       where DIC_FIN_ACC_CODE2_2_ID = substr(vACC_NUMBER, 1, 2) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_3_ID = (select max(DIC_FIN_ACC_CODE2_3_ID)
                                        from DIC_FIN_ACC_CODE2_3
                                       where DIC_FIN_ACC_CODE2_3_ID = substr(vACC_NUMBER, 1, 3) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_4_ID = (select max(DIC_FIN_ACC_CODE2_4_ID)
                                        from DIC_FIN_ACC_CODE2_4
                                       where DIC_FIN_ACC_CODE2_4_ID = substr(vACC_NUMBER, 1, 4) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_5_ID = (select max(DIC_FIN_ACC_CODE2_5_ID)
                                        from DIC_FIN_ACC_CODE2_5
                                       where DIC_FIN_ACC_CODE2_5_ID = substr(vACC_NUMBER, 1, 5) )
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;


      update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_10_ID = '1'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and DIC_FIN_ACC_CODE2_10_ID is null;

       update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_15_ID = 'MCH2_OK'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and length(vACC_NUMBER) =8;

       update ACS_FINANCIAL_ACCOUNT
         set DIC_FIN_ACC_CODE2_15_ID = 'MCH2_KO'
       where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
         and length(vACC_NUMBER) <>8;



    end if;
  end AccAccountBEMCH2;

/**
* procedure AccAccountVD
* Description
*   Script exécuté à la validation d'un compte
*   Ce script peut être choisi depuis le lkup dans la gestion des sous-ensembles
*/
  procedure AccAccountVD(aACS_ACCOUNT_ID in ACS_ACCOUNT.ACS_ACCOUNT_ID%type)
  is
    vACC_NUMBER              ACS_ACCOUNT.ACC_NUMBER%type;
    vACS_ACCOUNT_CATEG_ID    ACS_ACCOUNT_CATEG.ACS_ACCOUNT_CATEG_ID%type;
    vACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vACA_KEY                 ACS_ACCOUNT_CATEG.ACA_KEY%type;
  begin
    select max(ACC.ACC_NUMBER)
         , max(ACC.ACS_ACCOUNT_CATEG_ID)
         , max(CAT.ACA_KEY)
      into vACC_NUMBER
         , vACS_ACCOUNT_CATEG_ID
         , vACA_KEY
      from ACS_ACCOUNT_CATEG CAT
         , ACS_ACCOUNT ACC
     where ACC.ACS_ACCOUNT_ID = aACS_ACCOUNT_ID
       and ACC.ACS_ACCOUNT_CATEG_ID = CAT.ACS_ACCOUNT_CATEG_ID;

    if     (vACC_NUMBER is not null)
       and (vACS_ACCOUNT_CATEG_ID > 0) then
      -- mise à jour de l'interaction avec la division (Dicastère)
      if     (vACA_KEY <> 'BILAN')
         and (vACA_KEY <> 'INV')
         and (vACA_KEY <> 'PLANIF') then
        select max(DIV.ACS_DIVISION_ACCOUNT_ID)
          into vACS_DIVISION_ACCOUNT_ID
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACC_NUMBER = substr(vACC_NUMBER, 0, 3);
      else
        select max(DIV.ACS_DIVISION_ACCOUNT_ID)
          into vACS_DIVISION_ACCOUNT_ID
          from ACS_ACCOUNT ACC
             , ACS_DIVISION_ACCOUNT DIV
         where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACC_NUMBER = '000';
      end if;

      if vACS_DIVISION_ACCOUNT_ID is not null then
-- Effacer toutes les interactions pour le compte passé en paramètre
        delete from ACS_INTERACTION
              where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID;

--puis créer une nouvelle interaction insert into ACS_INTERACTION (ACS_INTERACTION_ID, ACS_FINANCIAL_ACCOUNT_ID, ACS_DIVISION_ACCOUNT_ID, INT_PAIR_DEFAULT, A_DATECRE, A_IDCRE) values (INIT_ID_SEQ.NEXTVAL, aACS_ACCOUNT_ID, vACS_DIVISION_ACCOUNT_ID, '1', sysdate, PCS.PC_I_LIB_SESSION.GetUserIni2); end if; end if;

        -- mise à jour des DICO
        if VACA_KEY in('BILAN', 'INV', 'PLANIF') then
-- Si c'est la catégorie est BILAN, INVESTISSEMENT OU PLANIFICATION FINANCIERE on met à jour les codes libre 1, 2 et 3
          update ACS_FINANCIAL_ACCOUNT
             set DIC_FIN_ACC_CODE_1_ID = (select max(DIC_FIN_ACC_CODE_1_ID)
                                            from DIC_FIN_ACC_CODE_1
                                           where DIC_FIN_ACC_CODE_1_ID = substr(vACC_NUMBER, 1, 2) )
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
             and DIC_FIN_ACC_CODE_1_ID is null;

          update ACS_FINANCIAL_ACCOUNT
             set DIC_FIN_ACC_CODE_2_ID = (select max(DIC_FIN_ACC_CODE_2_ID)
                                            from DIC_FIN_ACC_CODE_2
                                           where DIC_FIN_ACC_CODE_2_ID = substr(vACC_NUMBER, 1, 3) )
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
             and DIC_FIN_ACC_CODE_2_ID is null;

          update ACS_FINANCIAL_ACCOUNT
             set DIC_FIN_ACC_CODE_3_ID = (select max(DIC_FIN_ACC_CODE_3_ID)
                                            from DIC_FIN_ACC_CODE_3
                                           where DIC_FIN_ACC_CODE_3_ID = substr(vACC_NUMBER, 1, 4) )
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
             and DIC_FIN_ACC_CODE_3_ID is null;
--Il n'y a pas de mise à jour automatique des codes libre pour la catégorie --Investissement car M. Thévoz ne vas plus créer de compte dans les 5 ans à venir --(selon visite du 31.05.2005)

        -- Sinon c'est un compte de fonctionnement et on met à jour les codes libres 1 à 4 + les
-- codes libres 6 à 8
        elsif VACA_KEY = 'FONCT' then
          update ACS_FINANCIAL_ACCOUNT
             set DIC_FIN_ACC_CODE_1_ID = (select max(DIC_FIN_ACC_CODE_1_ID)
                                            from DIC_FIN_ACC_CODE_1
                                           where DIC_FIN_ACC_CODE_1_ID = substr(vACC_NUMBER, 5, 1) )
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
             and DIC_FIN_ACC_CODE_1_ID is null;

          update ACS_FINANCIAL_ACCOUNT
             set DIC_FIN_ACC_CODE_2_ID = (select max(DIC_FIN_ACC_CODE_2_ID)
                                            from DIC_FIN_ACC_CODE_2
                                           where DIC_FIN_ACC_CODE_2_ID = substr(vACC_NUMBER, 5, 2) )
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
             and DIC_FIN_ACC_CODE_2_ID is null;

          update ACS_FINANCIAL_ACCOUNT
             set DIC_FIN_ACC_CODE_3_ID = (select max(DIC_FIN_ACC_CODE_3_ID)
                                            from DIC_FIN_ACC_CODE_3
                                           where DIC_FIN_ACC_CODE_3_ID = substr(vACC_NUMBER, 5, 3) )
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
             and DIC_FIN_ACC_CODE_3_ID is null;

          update ACS_FINANCIAL_ACCOUNT
             set DIC_FIN_ACC_CODE_4_ID = (select max(DIC_FIN_ACC_CODE_4_ID)
                                            from DIC_FIN_ACC_CODE_4
                                           where DIC_FIN_ACC_CODE_4_ID = substr(vACC_NUMBER, 5, 4) )
           where ACS_FINANCIAL_ACCOUNT_ID = aACS_ACCOUNT_ID
             and DIC_FIN_ACC_CODE_4_ID is null;
--         update ACS_DIVISION_ACCOUNT
--         set DIC_DIV_ACC_CODE_5_ID = (select max(DIC_DIV_ACC_CODE_5_ID) from DIC_DIV_ACC_CODE_5 where DIC_DIV_ACC_CODE_5_ID = substr(vACC_NUMBER, 1, 1)) where ACS_DIVISION_ACCOUNT_ID = aACS_ACCOUNT_ID and DIC_DIV_ACC_CODE_5_ID is null;
--
--         update ACS_DIVISION_ACCOUNT
--         set DIC_DIV_ACC_CODE_6_ID = (select max(DIC_DIV_ACC_CODE_6_ID) from DIC_DIV_ACC_CODE_6 where DIC_DIV_ACC_CODE_6_ID = substr(vACC_NUMBER, 1, 2)) where ACS_DIVISION_ACCOUNT_ID = aACS_ACCOUNT_ID and DIC_DIV_ACC_CODE_6_ID is null;
--
--         update ACS_DIVISION_ACCOUNT
--         set DIC_DIV_ACC_CODE_7_ID = (select max(DIC_DIV_ACC_CODE_7_ID) from DIC_DIV_ACC_CODE_7 where DIC_DIV_ACC_CODE_7_ID = substr(vACC_NUMBER, 1, 3)) where ACS_DIVISION_ACCOUNT_ID = aACS_ACCOUNT_ID and DIC_DIV_ACC_CODE_7_ID is null;
        end if;
      end if;
    end if;
  end AccAccountVD;
end ACS_SUB_SET_ACC;
