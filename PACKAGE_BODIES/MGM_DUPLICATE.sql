--------------------------------------------------------
--  DDL for Package Body MGM_DUPLICATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "MGM_DUPLICATE" 
is
  /**
  * Description  Fonction de copie d'unit� de mesure
  **/
  procedure DuplicateTransferUnit(pSourceTransferUnitId            MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type,        /*Unit� source            */
                                  pSourceKey                       MGM_TRANSFER_UNIT.MTU_KEY%type,                     /*Cl� source              */
                                  pDuplicatedTransferUnitId in out MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type         /*Param�tre de retour     */
                                  )

  is
    vDuplicatedTransferUnitId   MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type; /*R�ceptionne l'id de l'unit� cr��                                   */
    vDescrPosCpt                number;                                      /*Position du [ dans le descriptif indiquant la "version" duplifi�e  */
    vTransferUnitKey          MGM_TRANSFER_UNIT.MTU_DESCRIPTION%type;        /*Descriptif format� cible                                           */
  begin
    begin
      /** R�ception d'un nouvel Id **/
      select INIT_ID_SEQ.NEXTVAL  into vDuplicatedTransferUnitId from dual;
      /** R�ception de la position du car "[" indiquant la copie **/
      select instr(pSourceKey,''||' [#'||'') into vDescrPosCpt from dual;

      vTransferUnitKey := pSourceKey;
      /* Si l'�l�ment courant est un �l�ment d�j� issue de copie  -> R�ception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(pSourceKey,1, vDescrPosCpt - 1) into vTransferUnitKey from dual;
      end if;

      /** Recherche du nombre d'�l�ment dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1  into vDescrPosCpt from MGM_TRANSFER_UNIT  where MTU_KEY LIKE vTransferUnitKey||'%';
      -- Formatage du descriptif du nouveau type
      vTransferUnitKey := Substr(vTransferUnitKey,1,24);
      vTransferUnitKey := Substr((vTransferUnitKey ||' [#'||vDescrPosCpt||']'),1,30);


      /* Cr�ation de l'enregistrement sur la base de l'unit� de mesure � copier*/
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
      select vDuplicatedTransferUnitId      /* Unit� de mesure    -> Nouvel Id                      */
           , vTransferUnitKey               /* Cl�                -> format� en fct de la source    */
           , MTU_DESCRIPTION                /* Descriptif         -> Initialis� par param�tre       */
           , MTU_COMMENT                    /* Commentaire        -> Initialis� par param�tre       */
           , ACS_QTY_UNIT_ID                /* Quantit�           -> Initialis� par param�tre       */
           , PC_SQLST_ID                    /* SQL Effectif       -> Initialis� par param�tre       */
           , PC_BUD_SQLST_ID                /* SQL budgetis�      -> Initialis� par param�tre       */
           , C_MGM_UNIT_ORIGIN              /* Source             -> Initialis� par param�tre       */
           , C_MGM_UNIT_EXPLOITATION        /* Exploitation       -> Initialis� par param�tre       */
           , SYSDATE                        /* Date cr�ation      -> Date syst�me                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id cr�ation        -> user                           */
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
  * Description  Fonction de copie d'un �l�ment de r�partition
  **/
  procedure DuplicateDistributionElement(pSourceElementId            MGM_DISTRIBUTION_ELEMENT.MGM_DISTRIBUTION_ELEMENT_ID%type, /*El�ment de r�partition source            */
                                         pSourceKey                  MGM_DISTRIBUTION_ELEMENT.MDE_KEY%type,                     /*Cl� source              */
                                         pDuplicatedElementId in out MGM_DISTRIBUTION_ELEMENT.MGM_DISTRIBUTION_ELEMENT_ID%type  /*Param�tre de retour     */
                                         )
  is
    vDuplicatedElementId   MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type; /*R�ceptionne l'id de l'unit� cr��                                   */
    vDescrPosCpt                number;                                 /*Position du [ dans le descriptif indiquant la "version" duplifi�e  et compteur */
    vElementKey            MGM_TRANSFER_UNIT.MTU_DESCRIPTION%type;      /*Descriptif format� cible                                           */
  begin
    begin
      /** R�ception d'un nouvel Id **/
      select INIT_ID_SEQ.NEXTVAL  into vDuplicatedElementId from dual;
      /** R�ception de la position du car "[" indiquant la copie **/
      select instr(pSourceKey,''||' [#'||'') into vDescrPosCpt from dual;

      vElementKey := pSourceKey;
      /* Si l'�l�ment courant est un �l�ment d�j� issue de copie  -> R�ception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(pSourceKey,1, vDescrPosCpt - 1) into vElementKey from dual;
      end if;

      /** Recherche du nombre d'�l�ment dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1  into vDescrPosCpt from MGM_DISTRIBUTION_ELEMENT  where MDE_KEY LIKE vElementKey||'%';
      -- Formatage du descriptif du nouveau type
      vElementKey := Substr(vElementKey,1,24);
      vElementKey := Substr((vElementKey ||' [#'||vDescrPosCpt||']'),1,30);


      /* Cr�ation de l'enregistrement sur la base de l'unit� de mesure � copier*/
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
      select vDuplicatedElementId           /* Unit� de mesure           -> Nouvel Id                      */
           , MGM_USAGE_TYPE_ID              /* Cl� de r�partition unit�s -> Initialis� par param�tre       */
           , MGM_RATE_USAGE_TYPE_ID         /* Les bornes des diff�rent comptes sont toutes reprises de    */
           , ACS_CPN_ORIGIN_FROM_ID         /* l'�l�ment source          -> Initialis� par param�tre       */
           , ACS_CPN_ORIGIN_TO_ID
           , ACS_CPN_IMP_ORIGIN_ID
           , ACS_CPN_IMP_TARGET_ID
           , ACS_CDA_ORIGIN_FROM_ID
           , ACS_CDA_ORIGIN_TO_ID
           , ACS_PF_ORIGIN_FROM_ID
           , ACS_PF_ORIGIN_TO_ID
           , ACS_PJ_ORIGIN_FROM_ID
           , ACS_PJ_ORIGIN_TO_ID
           , vElementKey                    /* Cl�                -> format� en fct de la source    */
           , MDE_DESCRIPTION                /* Descriptif         -> Initialis� par param�tre       */
           , MDE_COMMENT                    /* Commentaire        -> Initialis� par param�tre       */
           , MDE_CPN_ORIGIN_CONDITION       /* Conditions SQL CPN -> Initialis� par param�tre       */
           , MDE_CDA_ORIGIN_CONDITION       /* Conditions SQL CDA -> Initialis� par param�tre       */
           , MDE_PF_ORIGIN_CONDITION        /* Conditions SQL PF  -> Initialis� par param�tre       */
           , MDE_PJ_ORIGIN_CONDITION        /* Conditions SQL PJ  -> Initialis� par param�tre       */
           , SYSDATE                        /* Date cr�ation      -> Date syst�me                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id cr�ation        -> user                           */
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
  * Description  Fonction de copie d'une m�thode de r�partition /  Formule de calcul taux
  **/
  procedure DuplicateUsageType(pSourceUsageTypeId        MGM_USAGE_TYPE.MGM_USAGE_TYPE_ID%type, /* M�thode de r�partition source  */
                               pSourceKey                MGM_USAGE_TYPE.MUT_KEY%type,           /*Cl� source                      */
                               pDuplicatedTypeId  in out MGM_USAGE_TYPE.MGM_USAGE_TYPE_ID%type  /* Id m�thode cr��e par copie     */
                               )
  is
    cursor TargetElementsCursor
    is
      select MGM_APPLIED_UNIT_ID
      from MGM_APPLIED_UNIT
      where MGM_USAGE_TYPE_ID = pSourceUsageTypeId;

    vDuplicatedTypeId   MGM_USAGE_TYPE.MGM_USAGE_TYPE_ID%type;     /*R�ceptionne l'id de l'unit� cr��                                           */
    vAppliedUnitId      MGM_APPLIED_UNIT.MGM_APPLIED_UNIT_ID%type; /*R�ceptionne id des cibles de r�partition / calcul de tauy                  */
    vDescrPosCpt        number;                                    /*Position du [ dans le descriptif indiquant la "version" duplifi�e  et compteur */
    vUsageTypeKey       MGM_USAGE_TYPE.MUT_DESCRIPTION%type;       /*Descriptif format� cible                                                       */
  begin
    begin
      /** R�ception d'un nouvel Id **/
      select INIT_ID_SEQ.NEXTVAL  into vDuplicatedTypeId from dual;
      /** R�ception de la position du car "[" indiquant la copie **/
      select instr(pSourceKey,''||' [#'||'') into vDescrPosCpt from dual;

      vUsageTypeKey := pSourceKey;
      /* Si l'�l�ment courant est un �l�ment d�j� issue de copie  -> R�ception de la "Racine" du descriptif  */
      if vDescrPosCpt > 0 then
        select substr(pSourceKey,1, vDescrPosCpt - 1) into vUsageTypeKey from dual;
      end if;

      /** Recherche du nombre d'�l�ment dont le descriptif = "Racine" du descriptif **/
      select count(*) + 1  into vDescrPosCpt from MGM_USAGE_TYPE  where MUT_KEY LIKE vUsageTypeKey||'%';
      -- Formatage du descriptif du nouveau type
      vUsageTypeKey := Substr(vUsageTypeKey,1,24);
      vUsageTypeKey := Substr((vUsageTypeKey ||' [#'||vDescrPosCpt||']'),1,30);


      /* Cr�ation de l'enregistrement sur la base de la m�thode source*/
      insert into MGM_USAGE_TYPE(
          MGM_USAGE_TYPE_ID
        , C_USAGE_TYPE
        , MGM_TRANSFER_UNIT_ID
        , MUT_KEY
        , MUT_DESCRIPTION
        , MUT_COMMENT
        , A_DATECRE
        , A_IDCRE)
      select vDuplicatedTypeId              /* M�thode            -> Nouvel Id                      */
           , C_USAGE_TYPE                   /* Type               -> Initialis� par param�tre       */
           , MGM_TRANSFER_UNIT_ID           /* Unit� de mesure    -> Initialis� par param�tre       */
           , vUsageTypeKey                  /* Cl�                -> format� en fct de la source    */
           , MUT_DESCRIPTION                /* Descriptif         -> Initialis� par param�tre       */
           , MUT_COMMENT                    /* Commentaire        -> Initialis� par param�tre       */
           , SYSDATE                        /* Date cr�ation      -> Date syst�me                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id cr�ation        -> user                           */
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
             , vDuplicatedTypeId              /* M�thode /  Formule -> Id position nouvelllement cr��e*/
             , ACS_PJ_ACCOUNT_ID              /* Comptes et axes    -> Initialis� par param�tre       */
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_ACS_CPN_ACCOUNT_ID
             , MAU_CPN_CONDITION
             , GCO_GOOD_ID
             , FAL_FACTORY_FLOOR_ID
             , SYSDATE                        /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni /* Id cr�ation        -> user                           */
        from  MGM_APPLIED_UNIT
        where MGM_APPLIED_UNIT_ID = vAppliedUnitId;

        fetch TargetElementsCursor into vAppliedUnitId;
      end loop;
      close TargetElementsCursor;
    end if;
    pDuplicatedTypeId := vDuplicatedTypeId;
  end DuplicateUsageType;

  /**
  * Description  Fonction de copie de mod�le de r�partition
  **/
  procedure DuplicateDistributionModel(pSourceModelId     MGM_DISTRIBUTION_MODEL.MGM_DISTRIBUTION_MODEL_ID%type,
                                       pSourceKey         MGM_DISTRIBUTION_MODEL.MDM_DESCRIPTION%type,
                                       pDuplicateAllChain number,
                                       pDuplicatedModelId in out MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type
                                       )
  is
    vDuplicatedModelId   MGM_DISTRIBUTION_MODEL.MGM_DISTRIBUTION_MODEL_ID%type;/*R�ceptionne l'id du mod�le cr��           */
    vVersionPosCpt       number;                                        /* Position du [ dans le descriptif indiquant la "version" duplifi�e */
    vTargetDescr         MGM_DISTRIBUTION_MODEL.MDM_DESCRIPTION%type;   /*Descriptif format� cible                  */
  begin
    begin
      --R�ception d'un nouvel Id de mod�le
      select INIT_ID_SEQ.NEXTVAL into vDuplicatedModelId from dual;

      select instr(pSourceKey,''||'['||'')                --R�ception du num�ro de version
      into vVersionPosCpt
      from dual;

      vTargetDescr := pSourceKey;
      if vVersionPosCpt > 0 then                          --Le mod�le courant est un mod�le d�j� duplifi�
        select substr(pSourceKey, 1, vVersionPosCpt + 1 ) --R�ception de la "Racine" du descriptif
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

      /* Cr�ation de l'enregistrement sur la base du mod�le � duplifier*/
      insert into MGM_DISTRIBUTION_MODEL (
          MGM_DISTRIBUTION_MODEL_ID
        , ACJ_JOB_TYPE_S_CATALOGUE_ID
        , MDM_AVAILABLE
        , MDM_DESCRIPTION
        , MDM_COMMENT
        , A_DATECRE
        , A_IDCRE)
      select vDuplicatedModelId             /* Type de lien       -> Nouvel Id                      */
           , ACJ_JOB_TYPE_S_CATALOGUE_ID    /* Transaction mod�le -> Initalis� par origine          */
           , MDM_AVAILABLE                  /* Disponibilit�      -> Initalis� par origine          */
           , vTargetDescr                   /* Descriptif         -> Initialis� par param�tre       */
           , MDM_COMMENT                    /* Commentaire        -> Initalis� par origine          */
           , SYSDATE                        /* Date cr�ation      -> Date syst�me                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id cr�ation        -> user                           */
      from  MGM_DISTRIBUTION_MODEL
      where MGM_DISTRIBUTION_MODEL_ID = pSourceModelId;
    exception
      when others then
        vDuplicatedModelId := null;
        Raise;
    end;

    if not vDuplicatedModelId is null then
      begin
        /*Duplification de toute la cha�ne parent- enfant */
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
            , vDuplicatedModelId               /* Mod�le            -> lien sur le nouveau mod�le cr�� */
            , MGM_DISTRIBUTION_STRUCTURE_ID
            , MMS_SEQUENCE
            , MMS_DESCRIPTION
            , MMS_COMMENT
            , SYSDATE                          /* Date cr�ation      -> Date syst�me                   */
            , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from MGM_MODEL_SEQUENCE
          where MGM_DISTRIBUTION_MODEL_ID = pSourceModelId;
        end if;
      exception
        when others then
          Raise;
      end;
    end if;
    pDuplicatedModelId := vDuplicatedModelId; /*Assignation du param�tre de retour*/
  end DuplicateDistributionModel;

  /**
  * Description  Fonction de copie de structure de r�partition
  **/
  procedure DuplicateDistStructure(pSourceStructureId     MGM_DISTRIBUTION_STRUCTURE.MGM_DISTRIBUTION_STRUCTURE_ID%type,
                                   pSourceKey             MGM_DISTRIBUTION_STRUCTURE.MDS_DESCRIPTION%type,
                                   pDuplicateAllChain     number,
                                   pDuplicatedStructureId in out MGM_TRANSFER_UNIT.MGM_TRANSFER_UNIT_ID%type
                                   )
  is
    vDuplicatedStructureId MGM_DISTRIBUTION_STRUCTURE.MGM_DISTRIBUTION_STRUCTURE_ID%type;/*R�ceptionne l'id du mod�le cr��           */
    vVersionPosCpt         number;                                        /* Position du [ dans le descriptif indiquant la "version" duplifi�e */
    vTargetDescr           MGM_DISTRIBUTION_STRUCTURE.MDS_DESCRIPTION%type;   /*Descriptif format� cible                  */
  begin
    begin
      --R�ception d'un nouvel Id de mod�le
      select INIT_ID_SEQ.NEXTVAL into vDuplicatedStructureId from dual;

      select instr(pSourceKey,''||'['||'')                --R�ception du num�ro de version
      into vVersionPosCpt
      from dual;

      vTargetDescr := pSourceKey;
      if vVersionPosCpt > 0 then                          --Le mod�le courant est un mod�le d�j� duplifi�
        select substr(pSourceKey, 1, vVersionPosCpt + 1 ) --R�ception de la "Racine" du descriptif
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

      /* Cr�ation de l'enregistrement sur la base du mod�le � duplifier*/
      insert into MGM_DISTRIBUTION_STRUCTURE (
          MGM_DISTRIBUTION_STRUCTURE_ID
        , MDS_DESCRIPTION
        , MDS_COMMENT
        , A_DATECRE
        , A_IDCRE)
      select vDuplicatedStructureId         /* Structure          -> Nouvel Id                      */
           , vTargetDescr                   /* Descriptif         -> Initialis� par param�tre       */
           , MDS_COMMENT                    /* Commentaire        -> Initalis� par origine          */
           , SYSDATE                        /* Date cr�ation      -> Date syst�me                   */
           , PCS.PC_I_LIB_SESSION.GetUserIni /* Id cr�ation        -> user                           */
      from  MGM_DISTRIBUTION_STRUCTURE
      where MGM_DISTRIBUTION_STRUCTURE_ID = pSourceStructureId;
    exception
      when others then
        vDuplicatedStructureId := null;
        Raise;
    end;

    if not vDuplicatedStructureId is null then
      begin
        /*Duplification de toute la cha�ne parent- enfant */
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
            , vDuplicatedStructureId           /* Structure         -> lien sur le nouveau mod�le cr�� */
            , MSE_SEQUENCE
            , MSE_DESCRIPTION
            , MSE_COMMENT
            , SYSDATE                          /* Date cr�ation      -> Date syst�me                   */
            , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from MGM_STRUCTURE_ELEMENT
          where MGM_DISTRIBUTION_STRUCTURE_ID = pSourceStructureId;
        end if;
      exception
        when others then
          Raise;
      end;
    end if;
    pDuplicatedStructureId := vDuplicatedStructureId; /*Assignation du param�tre de retour*/
  end DuplicateDistStructure;




end MGM_DUPLICATE;
