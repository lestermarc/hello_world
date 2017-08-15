--------------------------------------------------------
--  DDL for Package Body COM_VAR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_VAR" 
is

  /**
  * Description
  *    Création ou mise à jour d'une variable numérique
  */
  procedure setNumeric(aName in COM_VARIABLE.VAR_NAME%type,
                       aVariant in COM_VARIABLE.VAR_VARIANT%type,
                       aDescription in COM_VARIABLE.VAR_DESCRIPTION%type,
                       aValue in COM_VARIABLE.VAR_NUMERIC%type)
  is
  begin

    begin
      -- Insertion de la variable
      -- Si valeur déjà existante, gestion d'exception et mise à jour de l'existant
      insert into COM_VARIABLE(COM_VARIABLE_ID,
                               VAR_NAME,
                               VAR_VARIANT,
                               VAR_DESCRIPTION,
                               VAR_NUMERIC,
                               A_DATECRE,
                               A_IDCRE)
                        values(INIT_ID_SEQ.NEXTVAL,
                               aName,
                               aVariant,
                               aDescription,
                               aValue,
                               sysdate,
                               PCS.PC_I_LIB_SESSION.GetUserIni2);
    exception
      when DUP_VAL_ON_INDEX then
        -- Mise à jour de la variable
        update COM_VARIABLE
           set VAR_DESCRIPTION = NVL(aDescription, VAR_DESCRIPTION),
               VAR_NUMERIC = aValue,
               A_DATEMOD = sysdate,
               A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni2
         where VAR_NAME = aName and
               (VAR_VARIANT = aVariant or (aVariant is null and VAR_VARIANT is null));
    end;

  end setNumeric;

  /**
  * Description
  *    recherche et retourne la valeur d'une variable numérique
  */
  function getNumeric(aName in COM_VARIABLE.VAR_NAME%type,
                      aVariant in COM_VARIABLE.VAR_VARIANT%type)
       return COM_VARIABLE.VAR_NUMERIC%type
  is
    result COM_VARIABLE.VAR_NUMERIC%type;
  begin

    begin
      -- Mise à jour de la variable
      select VAR_NUMERIC into Result
        from COM_VARIABLE
       where VAR_NAME = aName and
             (VAR_VARIANT = aVariant or (aVariant is null and VAR_VARIANT is null));

    exception
      when NO_DATA_FOUND then
        Result := null;
    end;

    return Result;

  end getNumeric;

  /**
  * Description
  *    Création ou mise à jour d'une variable numérique
  */
  procedure setCharacter(aName in COM_VARIABLE.VAR_NAME%type,
                         aVariant in COM_VARIABLE.VAR_VARIANT%type,
                         aDescription in COM_VARIABLE.VAR_DESCRIPTION%type,
                         aValue in COM_VARIABLE.VAR_CHARACTER%type)
  is
  begin

    begin
      -- Insertion de la variable
      -- Si valeur déjà existante, gestion d'exception et mise à jour de l'existant
      insert into COM_VARIABLE(COM_VARIABLE_ID,
                               VAR_NAME,
                               VAR_VARIANT,
                               VAR_DESCRIPTION,
                               VAR_CHARACTER,
                               A_DATECRE,
                               A_IDCRE)
                        values(INIT_ID_SEQ.NEXTVAL,
                               aName,
                               aVariant,
                               aDescription,
                               aValue,
                               sysdate,
                               PCS.PC_I_LIB_SESSION.GetUserIni2);
    exception
      when DUP_VAL_ON_INDEX then
        -- Mise à jour de la variable
        update COM_VARIABLE
           set VAR_DESCRIPTION = NVL(aDescription, VAR_DESCRIPTION),
               VAR_CHARACTER = aValue,
               A_DATEMOD = sysdate,
               A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni2
         where VAR_NAME = aName and
               (VAR_VARIANT = aVariant or (aVariant is null and VAR_VARIANT is null));
    end;


  end setCharacter;

  /**
  * Description
  *    recherche et retourne la valeur d'une variable caractère
  */
  function getCharacter(aName in COM_VARIABLE.VAR_NAME%type,
                        aVariant in COM_VARIABLE.VAR_VARIANT%type)
       return COM_VARIABLE.VAR_CHARACTER%type
  is
    result COM_VARIABLE.VAR_CHARACTER%type;
  begin

    begin

      -- Mise à jour de la variable
      select VAR_CHARACTER into Result
        from COM_VARIABLE
       where VAR_NAME = aName and
             (VAR_VARIANT = aVariant or (aVariant is null and VAR_VARIANT is null));

    exception
      when NO_DATA_FOUND then
        Result := null;
    end;

    return Result;

  end getCharacter;


  /**
  * Description
  *    Création ou mise à jour d'une variable date
  */
  procedure setDate(aName in COM_VARIABLE.VAR_NAME%type,
                    aVariant in COM_VARIABLE.VAR_VARIANT%type,
                    aDescription in COM_VARIABLE.VAR_DESCRIPTION%type,
                    aValue in COM_VARIABLE.VAR_DATE%type)
  is
  begin

    begin
      -- Insertion de la variable
      -- Si valeur déjà existante, gestion d'exception et mise à jour de l'existant
      insert into COM_VARIABLE(COM_VARIABLE_ID,
                               VAR_NAME,
                               VAR_VARIANT,
                               VAR_DESCRIPTION,
                               VAR_DATE,
                               A_DATECRE,
                               A_IDCRE)
                        values(INIT_ID_SEQ.NEXTVAL,
                               aName,
                               aVariant,
                               aDescription,
                               aValue,
                               sysdate,
                               PCS.PC_I_LIB_SESSION.GetUserIni2);
    exception
      when DUP_VAL_ON_INDEX then
        -- Mise à jour de la variable
        update COM_VARIABLE
           set VAR_DESCRIPTION = NVL(aDescription, VAR_DESCRIPTION),
               VAR_DATE = aValue,
               A_DATEMOD = sysdate,
               A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni2
         where VAR_NAME = aName and
               (VAR_VARIANT = aVariant or (aVariant is null and VAR_VARIANT is null));
    end;

  end setDate;

  /**
  * Description
  *    recherche et retourne la valeur d'une variable date
  */
  function getDate(aName in COM_VARIABLE.VAR_NAME%type,
                   aVariant in COM_VARIABLE.VAR_VARIANT%type)
        return COM_VARIABLE.VAR_DATE%type
  is
    result COM_VARIABLE.VAR_DATE%type;
  begin

    begin
      -- Mise à jour de la variable
      select VAR_DATE into Result
        from COM_VARIABLE
       where VAR_NAME = aName and
             (VAR_VARIANT = aVariant or (aVariant is null and VAR_VARIANT is null));

    exception
      when NO_DATA_FOUND then
        Result := null;
    end;

    return Result;

  end getDate;

end COM_VAR;
