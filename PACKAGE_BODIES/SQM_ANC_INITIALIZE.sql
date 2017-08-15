--------------------------------------------------------
--  DDL for Package Body SQM_ANC_INITIALIZE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_ANC_INITIALIZE" 
is

  /**
  * function GetUserInfo
  * Description :  Recherche d'informations à partir des initiales du User
  */
  procedure GetUserInfo(aA_IDCRE    in VARCHAR2
					  , aPC_USER_ID in out NUMBER)
  is
  begin
    SELECT PC_USER_ID
	  INTO aPC_USER_ID
	  FROM PCS.PC_USER
	 WHERE USE_INI = aA_IDCRE;
  end GetUserInfo;

  /**
  * function GetNumericConfig
  * Description :  Recherche des coûts forfaitaires de NC
  */
  Function GetNumericConfig(aConfigName VARCHAR2) Return NUMBER
  is
  begin
    Return TO_NUMBER(PCS.PC_CONFIG.GetConfig(aConfigName));
  exception
    When others then
      return 0;
  end GetNumericConfig;

    /**
  * Function CallIndivInitProc
  * Description : Procédure d'appel d'une procédure individualisée d'initialisation du Record ANC avant  son insertion
  *               dans la base
  * aIndivInitProc : Nom de la procedure à executer
  * aSQM_ANC_Rec   : Record de stockage (identique à la table SQM_ANC
  * ensuite, liste de paramètres d'exécution de la procédure individualisée.
  */
  procedure CallIndivInitProc(aIndivInitProc             in VARCHAR2 	     Default null  -- Procédure d'initialisation individualisée.
  							, aRecordName                in VARCHAR2         default null
   					        , aStringparam1              in VARCHAR2 	     Default null  -- Paramètres Utilisable Pour La Procedure Indiv D'initialisation
   					        , aStringParam2              in VARCHAR2 	     Default null  -- idem.
   					        , aStringParam3              in VARCHAR2 	     Default null  -- idem.
   					        , aStringParam4              in VARCHAR2 	     Default null  -- idem.
   					  		, aStringParam5              in VARCHAR2 	     Default null  -- idem.
   					  		, aCurrencyParam1            in NUMBER 	         Default null  -- idem.
   					  		, aCurrencyParam2            in NUMBER 	         Default null  -- idem.
   					  		, aCurrencyParam3            in NUMBER 	         Default null  -- idem.
   					  		, aCurrencyParam4            in NUMBER 	         Default null  -- idem.
   					  		, aCurrencyParam5            in NUMBER 	         Default null  -- idem.
   					  		, aIntegerParam1             in INTEGER	         Default null  -- idem.
   					  		, aIntegerParam2             in INTEGER	      	 Default null  -- idem.
   					  		, aIntegerParam3             in INTEGER	      	 Default null  -- idem.
   					  		, aIntegerParam4             in INTEGER	      	 Default null  -- idem.
   					  		, aIntegerParam5             in INTEGER	      	 Default null  -- idem.
   					  		, aDateParam1                in DATE	      	 Default null  -- idem.
   					  		, aDateParam2                in DATE	      	 Default null  -- idem.
   					  		, aDateParam3                in DATE	      	 Default null  -- idem.
   					 		, aDateParam4                in DATE	      	 Default null  -- idem.
   					  		, aDateParam5                in DATE	      	 Default null) -- idem.
  is
    BuffSQL 	   VARCHAR2(4000);
    Cursor_Handle  INTEGER;
    Execute_Cursor INTEGER;
  begin
    -- Construction dynamique
    BuffSQL := ' BEGIN '
             || aIndivInitProc   || '(' || aRecordName;
    if aStringparam1 is not null then
  	  BuffSQL := BuffSQL    || ',''' || aStringparam1 || '''';
	end if;
    if aStringParam2 is not null then
  	  BuffSQL := BuffSQL    || ',''' || aStringparam2 || '''';
	end if;
    if aStringParam3 is not null then
  	  BuffSQL := BuffSQL    || ',''' || aStringparam3 || '''';
	end if;
    if aStringParam4 is not null then
  	  BuffSQL := BuffSQL    || ',''' || aStringparam4 || '''';
	end if;
	if aStringParam5 is not null then
  	  BuffSQL := BuffSQL    || ',''' || aStringparam5 || '''';
	end if;
	if aCurrencyParam1 is not null then
  	  BuffSQL := BuffSQL    || ',' || aCurrencyparam1;
	end if;
	if aCurrencyParam2 is not null then
  	  BuffSQL := BuffSQL    || ',' || aCurrencyparam2;
	end if;
	if aCurrencyParam3 is not null then
  	  BuffSQL := BuffSQL    || ',' || aCurrencyparam3;
	end if;
	if aCurrencyParam4 is not null then
  	  BuffSQL := BuffSQL    || ',' || aCurrencyparam4;
	end if;
	if aCurrencyParam5 is not null then
  	  BuffSQL := BuffSQL    || ',' || aCurrencyparam5;
	end if;
	if aIntegerParam1 is not null then
  	  BuffSQL := BuffSQL    || ',' || aIntegerparam1;
	end if;
	if aIntegerParam2 is not null then
  	  BuffSQL := BuffSQL    || ',' || aIntegerparam2;
	end if;
	if aIntegerParam3 is not null then
  	  BuffSQL := BuffSQL    || ',' || aIntegerparam3;
	end if;
	if aIntegerParam4 is not null then
  	  BuffSQL := BuffSQL    || ',' || aIntegerparam4;
	end if;
	if aIntegerParam5 is not null then
  	  BuffSQL := BuffSQL    || ',' || aIntegerparam5;
	end if;
	if aDateParam1 is not null then
  	  BuffSQL := BuffSQL    || ',' || aDateparam1;
	end if;
	if aDateParam2 is not null then
  	  BuffSQL := BuffSQL    || ',' || aDateparam2;
	end if;
	if aDateParam3 is not null then
  	  BuffSQL := BuffSQL    || ',' || aDateparam3;
	end if;
    if aDateParam4 is not null then
  	  BuffSQL := BuffSQL    || ',' || aDateparam4;
	end if;
	if aDateParam5 is not null then
  	  BuffSQL := BuffSQL    || ',' || aDateparam5;
	end if;
	BuffSQL := BuffSQL || '); END;';

    Cursor_Handle   := DBMS_SQL.open_cursor;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
    DBMS_SQL.close_cursor(Cursor_Handle);
  exception
    when others then
      raise;
  end CallIndivInitProc;

  /**
  * Procedure   : ResetANCRecord
  * Description : Efface et réinitialise les données de création d'une ANC
  */
  procedure ResetANCRecord(aSQM_ANC_Rec in out TSQM_ANC_Rec)
  is
    tmpSQM_ANC_Rec           SQM_ANC_INITIALIZE.TSQM_ANC_Rec;
  begin
    -- Initialisation Entête ANC
    aSQM_ANC_Rec           := tmpSQM_ANC_Rec;
  end ResetANCRecord;

end SQM_ANC_INITIALIZE;
