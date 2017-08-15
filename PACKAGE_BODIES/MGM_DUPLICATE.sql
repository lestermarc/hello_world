--------------------------------------------------------
--  DDL for Package Body MGM_DUPLICATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MGM_DUPLICATE" 
is
  /**
  * Description  Fonction de copie d'unité de mesure
  **/
  procedure DuplicateTransferUnit(pSourceTransferUnitId            MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type,        /*Unité source            */
                                  pSourceKey                       MGM_TRANSFER_UNIT.MTU_KEY%type,                     /*Clé source              */
                                  pDuplicatedTransferUnitId in out MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type         /*Paramètre de retour     */
                                  )

  is
    vDuplicatedTransferUnitId   MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type; /*Réceptionne l'id de l'unité créé                                   */
    vDescrPosCpt                number;                                      /*Position du [ dans le descriptif indiquant la "version" duplifiée  */
    vTransferUnitKey          MGM_TRANSFER_UNIT.MTU_DESCRIPTION%type;        /*Descriptif formaté cible                                           */
  begin
    begin
      /** Réception d'un nouvel Id **/
      select INIT_ID_SEQ.NEXTVAL  into vDuplicatedTransferUnitId from dual;
      /** Réception de la position du car "[" indiquant la copie **/
      select instr(pSourceKey,''||' [#'||'') into vDescrPosCpt from dual;

      vTransferUnitKey := pSourceKey;
      /* Si l'élément courant est un élément déjà issue de copie  -> Réception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(pSourceKey,1, vDescrPosCpt - 1) into vTransferUnitKey from dual;
      end if;

      /** Recherche du nombre d'élément dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1  into vDescrPosCpt from MGM_TRANSFER_UNIT  where MTU_KEY LIKE vTransferUnitKey||'%';
      -- Formatage du descriptif du nouveau type
      vTransferUnitKey := Substr(vTransferUnitKey,1,24);
      vTransferUnitKey := Substr((vTransferUnitKey ||' [#'||vDescrPosCpt||']'),1,30);


      /* Création de l'enregistrement sur la base de l'unité de mesure à copier*/
      insert into MGM_TRANSFER_UNIT(
          MGM_TRANSFER_UNIT_ID
        , MTU_KEY
        , MTU_DESCRIPTION
        , MTU_COMMENT
        , ACS_QTY_UNIT_ID
        , PC_SQLST_ID
        , PC_BUD_SQLST_ID
        , C_MGM_UNIT_ORIGIN
        , C_MGM_UNIT_EXPLOITATION
        , A_DATECRE
        , A_IDCRE)
      select vDuplicatedTransferUnitId      /* Unité de mesure    -> Nouvel Id                      */
           , vTransferUnitKey               /* Clé                -> formaté en fct de la source    */
           , MTU_DESCRIPTION                /* Descriptif         -> Initialisé par paramètre       */
           , MTU_COMMENT                    /* Commentaire        -> Initialisé par paramètre       */
           , ACS_QTY_UNIT_ID                /* Quantité           -> Initialisé par paramètre       */
           , PC_SQLST_ID                    /* SQL Effectif       -> Initialisé par paramètre       */
           , PC_BUD_SQLST_ID                /* SQL budgetisé      -> Initialisé par paramètre       */
           , C_MGM_UNIT_ORIGIN              /* Source             -> Initialisé par paramètre       */
           , C_MGM_UNIT_EXPLOITATION        /* Exploitation       -> Initialisé par paramètre       */
           , SYSDATE                        /* Date création      -> Date système                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id création        -> user                           */
      from  MGM_TRANSFER_UNIT
      where MGM_TRANSFER_UNIT_ID = pSourceTransferUnitId;
    exception
      when others then
        vDuplicatedTransferUnitId := 0;
        Raise;
    end;
    pDuplicatedTransferUnitId := vDuplicatedTransferUnitId;
  end DuplicateTransferUnit;

  /**
  * Description  Fonction de copie d'un élément de répartition
  **/
  procedure DuplicateDistributionElement(pSourceElementId            MGM_DISTRIBUTION_ELEMENT.MGM_DISTRIBUTION_ELEMENT_ID%type, /*Elément de répartition source            */
                                         pSourceKey                  MGM_DISTRIBUTION_ELEMENT.MDE_KEY%type,                     /*Clé source              */
                                         pDuplicatedElementId in out MGM_DISTRIBUTION_ELEMENT.MGM_DISTRIBUTION_ELEMENT_ID%type  /*Paramètre de retour     */
                                         )
  is
    vDuplicatedElementId   MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type; /*Réceptionne l'id de l'unité créé                                   */
    vDescrPosCpt                number;                                 /*Position du [ dans le descriptif indiquant la "version" duplifiée  et compteur */
    vElementKey            MGM_TRANSFER_UNIT.MTU_DESCRIPTION%type;      /*Descriptif formaté cible                                           */
  begin
    begin
      /** Réception d'un nouvel Id **/
      select INIT_ID_SEQ.NEXTVAL  into vDuplicatedElementId from dual;
      /** Réception de la position du car "[" indiquant la copie **/
      select instr(pSourceKey,''||' [#'||'') into vDescrPosCpt from dual;

      vElementKey := pSourceKey;
      /* Si l'élément courant est un élément déjà issue de copie  -> Réception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(pSourceKey,1, vDescrPosCpt - 1) into vElementKey from dual;
      end if;

      /** Recherche du nombre d'élément dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1  into vDescrPosCpt from MGM_DISTRIBUTION_ELEMENT  where MDE_KEY LIKE vElementKey||'%';
      -- Formatage du descriptif du nouveau type
      vElementKey := Substr(vElementKey,1,24);
      vElementKey := Substr((vElementKey ||' [#'||vDescrPosCpt||']'),1,30);


      /* Création de l'enregistrement sur la base de l'unité de mesure à copier*/
      insert into MGM_DISTRIBUTION_ELEMENT(
          MGM_DISTRIBUTION_ELEMENT_ID
        , MGM_USAGE_TYPE_ID
        , MGM_RATE_USAGE_TYPE_ID
        , ACS_CPN_ORIGIN_FROM_ID
        , ACS_CPN_ORIGIN_TO_ID
        , ACS_CPN_IMP_ORIGIN_ID
        , ACS_CPN_IMP_TARGET_ID
        , ACS_CDA_ORIGIN_FROM_ID
        , ACS_CDA_ORIGIN_TO_ID
        , ACS_PF_ORIGIN_FROM_ID
        , ACS_PF_ORIGIN_TO_ID
        , ACS_PJ_ORIGIN_FROM_ID
        , ACS_PJ_ORIGIN_TO_ID
        , MDE_KEY
        , MDE_DESCRIPTION
        , MDE_COMMENT
        , MDE_CPN_ORIGIN_CONDITION
        , MDE_CDA_ORIGIN_CONDITION
        , MDE_PF_ORIGIN_CONDITION
        , MDE_PJ_ORIGIN_CONDITION
        , A_DATECRE
        , A_IDCRE)
      select vDuplicatedElementId           /* Unité de mesure           -> Nouvel Id                      */
           , MGM_USAGE_TYPE_ID              /* Clé de répartition unités -> Initialisé par paramètre       */
           , MGM_RATE_USAGE_TYPE_ID         /* Les bornes des différent comptes sont toutes reprises de    */
           , ACS_CPN_ORIGIN_FROM_ID         /* l'élément source          -> Initialisé par paramètre       */
           , ACS_CPN_ORIGIN_TO_ID
           , ACS_CPN_IMP_ORIGIN_ID
           , ACS_CPN_IMP_TARGET_ID
           , ACS_CDA_ORIGIN_FROM_ID
           , ACS_CDA_ORIGIN_TO_ID
           , ACS_PF_ORIGIN_FROM_ID
           , ACS_PF_ORIGIN_TO_ID
           , ACS_PJ_ORIGIN_FROM_ID
           , ACS_PJ_ORIGIN_TO_ID
           , vElementKey                    /* Clé                -> formaté en fct de la source    */
           , MDE_DESCRIPTION                /* Descriptif         -> Initialisé par paramètre       */
           , MDE_COMMENT                    /* Commentaire        -> Initialisé par paramètre       */
           , MDE_CPN_ORIGIN_CONDITION       /* Conditions SQL CPN -> Initialisé par paramètre       */
           , MDE_CDA_ORIGIN_CONDITION       /* Conditions SQL CDA -> Initialisé par paramètre       */
           , MDE_PF_ORIGIN_CONDITION        /* Conditions SQL PF  -> Initialisé par paramètre       */
           , MDE_PJ_ORIGIN_CONDITION        /* Conditions SQL PJ  -> Initialisé par paramètre       */
           , SYSDATE                        /* Date création      -> Date système                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id création        -> user                           */
      from  MGM_DISTRIBUTION_ELEMENT
      where MGM_DISTRIBUTION_ELEMENT_ID = pSourceElementId;
    exception
      when others then
        vDuplicatedElementId := 0;
        Raise;
    end;
    pDuplicatedElementId := vDuplicatedElementId;
  end DuplicateDistributionElement;


  /**
  * Description  Fonction de copie d'une méthode de répartition /  Formule de calcul taux
  **/
  procedure DuplicateUsageType(pSourceUsageTypeId        MGM_USAGE_TYPE.MGM_USAGE_TYPE_ID%type, /* Méthode de répartition source  */
                               pSourceKey                MGM_USAGE_TYPE.MUT_KEY%type,           /*Clé source                      */
                               pDuplicatedTypeId  in out MGM_USAGE_TYPE.MGM_USAGE_TYPE_ID%type  /* Id méthode créée par copie     */
                               )
  is
    cursor TargetElementsCursor
    is
      select MGM_APPLIED_UNIT_ID
      from MGM_APPLIED_UNIT
      where MGM_USAGE_TYPE_ID = pSourceUsageTypeId;

    vDuplicatedTypeId   MGM_USAGE_TYPE.MGM_USAGE_TYPE_ID%type;     /*Réceptionne l'id de l'unité créé                                           */
    vAppliedUnitId      MGM_APPLIED_UNIT.MGM_APPLIED_UNIT_ID%type; /*Réceptionne id des cibles de répartition / calcul de tauy                  */
    vDescrPosCpt        number;                                    /*Position du [ dans le descriptif indiquant la "version" duplifiée  et compteur */
    vUsageTypeKey       MGM_USAGE_TYPE.MUT_DESCRIPTION%type;       /*Descriptif formaté cible                                                       */
  begin
    begin
      /** Réception d'un nouvel Id **/
      select INIT_ID_SEQ.NEXTVAL  into vDuplicatedTypeId from dual;
      /** Réception de la position du car "[" indiquant la copie **/
      select instr(pSourceKey,''||' [#'||'') into vDescrPosCpt from dual;

      vUsageTypeKey := pSourceKey;
      /* Si l'élément courant est un élément déjà issue de copie  -> Réception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(pSourceKey,1, vDescrPosCpt - 1) into vUsageTypeKey from dual;
      end if;

      /** Recherche du nombre d'élément dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1  into vDescrPosCpt from MGM_USAGE_TYPE  where MUT_KEY LIKE vUsageTypeKey||'%';
      -- Formatage du descriptif du nouveau type
      vUsageTypeKey := Substr(vUsageTypeKey,1,24);
      vUsageTypeKey := Substr((vUsageTypeKey ||' [#'||vDescrPosCpt||']'),1,30);


      /* Création de l'enregistrement sur la base de la méthode source*/
      insert into MGM_USAGE_TYPE(
          MGM_USAGE_TYPE_ID
        , C_USAGE_TYPE
        , MGM_TRANSFER_UNIT_ID
        , MUT_KEY
        , MUT_DESCRIPTION
        , MUT_COMMENT
        , A_DATECRE
        , A_IDCRE)
      select vDuplicatedTypeId              /* Méthode            -> Nouvel Id                      */
           , C_USAGE_TYPE                   /* Type               -> Initialisé par paramètre       */
           , MGM_TRANSFER_UNIT_ID           /* Unité de mesure    -> Initialisé par paramètre       */
           , vUsageTypeKey                  /* Clé                -> formaté en fct de la source    */
           , MUT_DESCRIPTION                /* Descriptif         -> Initialisé par paramètre       */
           , MUT_COMMENT                    /* Commentaire        -> Initialisé par paramètre       */
           , SYSDATE                        /* Date création      -> Date système                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id création        -> user                           */
      from  MGM_USAGE_TYPE
      where MGM_USAGE_TYPE_ID = pSourceUsageTypeId;
    exception
      when others then
        vDuplicatedTypeId := 0;
        Raise;
    end;
    if vDuplicatedTypeId <> 0 then
      open TargetElementsCursor;
      fetch TargetElementsCursor into vAppliedUnitId;
      while TargetElementsCursor%found
      loop
        insert into MGM_APPLIED_UNIT(
            MGM_APPLIED_UNIT_ID
          , MGM_USAGE_TYPE_ID
          , ACS_PJ_ACCOUNT_ID
          , ACS_CDA_ACCOUNT_ID
          , ACS_PF_ACCOUNT_ID
          , ACS_CPN_ACCOUNT_ID
          , ACS_ACS_CPN_ACCOUNT_ID
          , MAU_CPN_CONDITION
          , GCO_GOOD_ID
          , FAL_FACTORY_FLOOR_ID
          , A_DATECRE
          , A_IDCRE)
        select INIT_ID_SEQ.NEXTVAL            /* Cible              -> Nouvel Id                      */
             , vDuplicatedTypeId              /* Méthode /  Formule -> Id position nouvelllement créée*/
             , ACS_PJ_ACCOUNT_ID              /* Comptes et axes    -> Initialisé par paramètre       */
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_ACS_CPN_ACCOUNT_ID
             , MAU_CPN_CONDITION
             , GCO_GOOD_ID
             , FAL_FACTORY_FLOOR_ID
             , SYSDATE                        /* Date création      -> Date système                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni /* Id création        -> user                           */
        from  MGM_APPLIED_UNIT
        where MGM_APPLIED_UNIT_ID = vAppliedUnitId;

        fetch TargetElementsCursor into vAppliedUnitId;
      end loop;
      close TargetElementsCursor;
    end if;
    pDuplicatedTypeId := vDuplicatedTypeId;
  end DuplicateUsageType;

  /**
  * Description  Fonction de copie de modèle de répartition
  **/
  procedure DuplicateDistributionModel(pSourceModelId     MGM_DISTRIBUTION_MODEL.MGM_DISTRIBUTION_MODEL_ID%type,
                                       pSourceKey         MGM_DISTRIBUTION_MODEL.MDM_DESCRIPTION%type,
                                       pDuplicateAllChain number,
                                       pDuplicatedModelId in out MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type
                                       )
  is
    vDuplicatedModelId   MGM_DISTRIBUTION_MODEL.MGM_DISTRIBUTION_MODEL_ID%type;/*Réceptionne l'id du modèle créé           */
    vVersionPosCpt       number;                                        /* Position du [ dans le descriptif indiquant la "version" duplifiée */
    vTargetDescr         MGM_DISTRIBUTION_MODEL.MDM_DESCRIPTION%type;   /*Descriptif formaté cible                  */
  begin
    begin
      --Réception d'un nouvel Id de modèle
      select INIT_ID_SEQ.NEXTVAL into vDuplicatedModelId from dual;

      select instr(pSourceKey,''||'['||'')                --Réception du numéro de version
      into vVersionPosCpt
      from dual;

      vTargetDescr := pSourceKey;
      if vVersionPosCpt > 0 then                          --Le modèle courant est un modèle déjà duplifié
        select substr(pSourceKey, 1, vVersionPosCpt + 1 ) --Réception de la "Racine" du descriptif
        into vTargetDescr
        from dual;
      else
        vTargetDescr := vTargetDescr || ' [ ';
      end if;

      select count(*) + 1                                   --Recherche dz nombre de version dont le descriptif = "Racine" du descriptif
      into vVersionPosCpt
      from MGM_DISTRIBUTION_MODEL
      where MDM_DESCRIPTION LIKE vTargetDescr||'%';
      -- Formatage du descriptif du nouveau type
      vTargetDescr := Substr((vTargetDescr ||To_Char(Trunc(SYSDATE),'DD.MM.YYYY')||' - ' || vVersionPosCpt||' ]'),1,250);

      /* Création de l'enregistrement sur la base du modèle à duplifier*/
      insert into MGM_DISTRIBUTION_MODEL (
          MGM_DISTRIBUTION_MODEL_ID
        , ACJ_JOB_TYPE_S_CATALOGUE_ID
        , MDM_AVAILABLE
        , MDM_DESCRIPTION
        , MDM_COMMENT
        , A_DATECRE
        , A_IDCRE)
      select vDuplicatedModelId             /* Type de lien       -> Nouvel Id                      */
           , ACJ_JOB_TYPE_S_CATALOGUE_ID    /* Transaction modèle -> Initalisé par origine          */
           , MDM_AVAILABLE                  /* Disponibilité      -> Initalisé par origine          */
           , vTargetDescr                   /* Descriptif         -> Initialisé par paramètre       */
           , MDM_COMMENT                    /* Commentaire        -> Initalisé par origine          */
           , SYSDATE                        /* Date création      -> Date système                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id création        -> user                           */
      from  MGM_DISTRIBUTION_MODEL
      where MGM_DISTRIBUTION_MODEL_ID = pSourceModelId;
    exception
      when others then
        vDuplicatedModelId := null;
        Raise;
    end;

    if not vDuplicatedModelId is null then
      begin
        /*Duplification de toute la chaîne parent- enfant */
        if pDuplicateAllChain = 1 then
          insert into MGM_MODEL_SEQUENCE(
              MGM_MODEL_SEQUENCE_ID
            , MGM_DISTRIBUTION_MODEL_ID
            , MGM_DISTRIBUTION_STRUCTURE_ID
            , MMS_SEQUENCE
            , MMS_DESCRIPTION
            , MMS_COMMENT
            , A_DATECRE
            , A_IDCRE)
          select INIT_ID_SEQ.NEXTVAL
            , vDuplicatedModelId               /* Modèle            -> lien sur le nouveau modèle créé */
            , MGM_DISTRIBUTION_STRUCTURE_ID
            , MMS_SEQUENCE
            , MMS_DESCRIPTION
            , MMS_COMMENT
            , SYSDATE                          /* Date création      -> Date système                   */
            , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création        -> user                           */
          from MGM_MODEL_SEQUENCE
          where MGM_DISTRIBUTION_MODEL_ID = pSourceModelId;
        end if;
      exception
        when others then
          Raise;
      end;
    end if;
    pDuplicatedModelId := vDuplicatedModelId; /*Assignation du paramètre de retour*/
  end DuplicateDistributionModel;

  /**
  * Description  Fonction de copie de structure de répartition
  **/
  procedure DuplicateDistStructure(pSourceStructureId     MGM_DISTRIBUTION_STRUCTURE.MGM_DISTRIBUTION_STRUCTURE_ID%type,
                                   pSourceKey             MGM_DISTRIBUTION_STRUCTURE.MDS_DESCRIPTION%type,
                                   pDuplicateAllChain     number,
                                   pDuplicatedStructureId in out MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type
                                   )
  is
    vDuplicatedStructureId MGM_DISTRIBUTION_STRUCTURE.MGM_DISTRIBUTION_STRUCTURE_ID%type;/*Réceptionne l'id du modèle créé           */
    vVersionPosCpt         number;                                        /* Position du [ dans le descriptif indiquant la "version" duplifiée */
    vTargetDescr           MGM_DISTRIBUTION_STRUCTURE.MDS_DESCRIPTION%type;   /*Descriptif formaté cible                  */
  begin
    begin
      --Réception d'un nouvel Id de modèle
      select INIT_ID_SEQ.NEXTVAL into vDuplicatedStructureId from dual;

      select instr(pSourceKey,''||'['||'')                --Réception du numéro de version
      into vVersionPosCpt
      from dual;

      vTargetDescr := pSourceKey;
      if vVersionPosCpt > 0 then                          --Le modèle courant est un modèle déjà duplifié
        select substr(pSourceKey, 1, vVersionPosCpt + 1 ) --Réception de la "Racine" du descriptif
        into vTargetDescr
        from dual;
      else
        vTargetDescr := vTargetDescr || ' [ ';
      end if;

      select count(*) + 1                                   --Recherche dz nombre de version dont le descriptif = "Racine" du descriptif
      into vVersionPosCpt
      from MGM_DISTRIBUTION_STRUCTURE
      where MDS_DESCRIPTION LIKE vTargetDescr||'%';
      -- Formatage du descriptif du nouveau type
      vTargetDescr := Substr((vTargetDescr ||To_Char(Trunc(SYSDATE),'DD.MM.YYYY')||' - ' || vVersionPosCpt||' ]'),1,250);

      /* Création de l'enregistrement sur la base du modèle à duplifier*/
      insert into MGM_DISTRIBUTION_STRUCTURE (
          MGM_DISTRIBUTION_STRUCTURE_ID
        , MDS_DESCRIPTION
        , MDS_COMMENT
        , A_DATECRE
        , A_IDCRE)
      select vDuplicatedStructureId         /* Structure          -> Nouvel Id                      */
           , vTargetDescr                   /* Descriptif         -> Initialisé par paramètre       */
           , MDS_COMMENT                    /* Commentaire        -> Initalisé par origine          */
           , SYSDATE                        /* Date création      -> Date système                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id création        -> user                           */
      from  MGM_DISTRIBUTION_STRUCTURE
      where MGM_DISTRIBUTION_STRUCTURE_ID = pSourceStructureId;
    exception
      when others then
        vDuplicatedStructureId := null;
        Raise;
    end;

    if not vDuplicatedStructureId is null then
      begin
        /*Duplification de toute la chaîne parent- enfant */
        if pDuplicateAllChain = 1 then
          insert into MGM_STRUCTURE_ELEMENT(
              MGM_STRUCTURE_ELEMENT_ID
            , MGM_DISTRIBUTION_ELEMENT_ID
            , MGM_DISTRIBUTION_STRUCTURE_ID
            , MSE_SEQUENCE
            , MSE_DESCRIPTION
            , MSE_COMMENT
            , A_DATECRE
            , A_IDCRE)
          select INIT_ID_SEQ.NEXTVAL
            , MGM_DISTRIBUTION_ELEMENT_ID
            , vDuplicatedStructureId           /* Structure         -> lien sur le nouveau modèle créé */
            , MSE_SEQUENCE
            , MSE_DESCRIPTION
            , MSE_COMMENT
            , SYSDATE                          /* Date création      -> Date système                   */
            , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création        -> user                           */
          from MGM_STRUCTURE_ELEMENT
          where MGM_DISTRIBUTION_STRUCTURE_ID = pSourceStructureId;
        end if;
      exception
        when others then
          Raise;
      end;
    end if;
    pDuplicatedStructureId := vDuplicatedStructureId; /*Assignation du paramètre de retour*/
  end DuplicateDistStructure;




end MGM_DUPLICATE;
