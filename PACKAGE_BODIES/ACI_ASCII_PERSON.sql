--------------------------------------------------------
--  DDL for Package Body ACI_ASCII_PERSON
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_ASCII_PERSON" 
is

  --------
  function GetDIC_TYPE_SUBMISSION_ID(aDIC_TYPE_SUBMISSION_ID DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type,
                                     aNVL                    boolean) return DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type
  is
    Id        DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type default null;
    CodeFound boolean                                         default false;
  begin
    if aDIC_TYPE_SUBMISSION_ID is not null then
      begin
      select DIC_TYPE_SUBMISSION_ID into Id
        from DIC_TYPE_SUBMISSION
        where DIC_TYPE_SUBMISSION_ID = aDIC_TYPE_SUBMISSION_ID;
        CodeFound := true;
      exception
        when OTHERS then
          CodeFound := false;
      end;
    end if;
    if not CodeFound and not aNVL then
      select min(DIC_TYPE_SUBMISSION_ID) into Id
        from DIC_TYPE_SUBMISSION;
    end if;
    return Id;
  end;


  /**
  * Description
  *   reprise d'un fichier d'importation
  */
  procedure Recover_file(conversion_id in number, control_flag IN OUT number)
  is
    cursor conv_source(conversion_id in number) is
       select ACI_CONVERSION_SOURCE_ID,
              rtrim(substr(cso_data1,1,1)) line_type
       from ACI_CONVERSION_SOURCE
       where ACI_CONVERSION_ID = conversion_id
       order by ACI_CONVERSION_SOURCE_ID;
    conv_source_tuple conv_source%rowtype;
    conv_id ACI_CONVERSION.ACI_CONVERSION_ID%type;
    tuple_control_flag number(1);
  begin

    -- contrôle si le fichier n'est pas déjà traîté
    select MAX(ACI_CONVERSION_ID) into conv_id
      from ACI_CONVERSION
      where ACI_CONVERSION_ID = conversion_id
        and CNV_TRANSFERT_DATE is not null;

    -- Erreur fatale si le fichier a déjà été repris précédement
    if conv_id is not null then
      raise_application_error(-20010,'PCS - File already converted');
    end if;
    /**
    * Suppression des éventuels codes erreurs
    **/
    update ACI_CONVERSION_SOURCE
    set C_ASCII_FAIL_REASON = null
    where ACI_CONVERSION_SOURCE_ID = conversion_id;

    control_flag := 1;
    tuple_control_flag := 1;

    -- controle préalable
    ACI_ASCII_CTRL_PERSON.Ctrl_Global; -- provoque une erreur fatale en cas d'échec

    ACI_ASCII_CTRL_PERSON.Ctrl_Persons(conversion_id,control_flag);
    ACI_ASCII_CTRL_PERSON.Ctrl_Addresses(conversion_id,control_flag);
    ACI_ASCII_CTRL_PERSON.Ctrl_Communications(conversion_id,control_flag);
    ACI_ASCII_CTRL_PERSON.Ctrl_Thirds(conversion_id,control_flag);
    ACI_ASCII_CTRL_PERSON.Ctrl_Customers(conversion_id,control_flag);
    ACI_ASCII_CTRL_PERSON.Ctrl_Suppliers(conversion_id,control_flag);
    ACI_ASCII_CTRL_PERSON.Ctrl_References(conversion_id,control_flag);

    if control_flag = 1 then

      -- On lit les lignes l'une après l'autre, dans l'ordre de leur création
      open conv_source(conversion_id);
      fetch conv_source into conv_source_tuple;

      while conv_source%found loop

        if conv_source_tuple.line_type = '1' then

          Recover_Persons(conv_source_tuple.aci_conversion_source_id,
                          tuple_control_flag);
          Recover_Addresses(conv_source_tuple.aci_conversion_source_id,
                            tuple_control_flag);
          Recover_Communications(conv_source_tuple.aci_conversion_source_id,
                                 tuple_control_flag);
        elsif conv_source_tuple.line_type = '2' then

          Recover_Thirds(conv_source_tuple.aci_conversion_source_id,
                         tuple_control_flag);
          Recover_Customers(conv_source_tuple.aci_conversion_source_id,
                            tuple_control_flag);
          Recover_Suppliers(conv_source_tuple.aci_conversion_source_id,
                            tuple_control_flag);

        elsif conv_source_tuple.line_type = '3' then
          Recover_References(conv_source_tuple.aci_conversion_source_id,
                             tuple_control_flag);
        end if;


        -- si on a pas de problème sur le tuple, on peut mettre la date d'intégration à jour
        if tuple_control_flag = 1 then
          -- mise à jour du flag d'imputation financière du document
          update ACI_CONVERSION_SOURCE
             set CSO_TRANSFERT_DATE = SYSDATE
           where ACI_CONVERSION_SOURCE_ID = conv_source_tuple.ACI_CONVERSION_SOURCE_ID;
        -- sinon le flag de controle général est mis à 0
        else
          control_flag := 0;
          tuple_control_flag := 1;
        end if;

        fetch conv_source into conv_source_tuple;

      end loop;

    end if;

    -- Met à jour la date de transfert, qui indique que le fichier à été repris dans l'interface
    update ACI_CONVERSION set CNV_TRANSFERT_DATE = sysdate
      where ACI_CONVERSION_ID = conversion_id
        and control_flag = 1;

  end Recover_file;


  /**
  * Description
  *   reprise d'une personne depuis un fichier d'importation
  */
  procedure Recover_Persons(conversion_source_id in number, control_flag IN OUT number)
  is
    cursor person(conversion_source_id number) is
      select * from v_aci_ascii_person
        where aci_conversion_source_id = conversion_source_id;
    person_tuple person%rowtype;
    person_id PAC_PERSON.PAC_PERSON_ID%type;
  begin

    -- ouverture du curseur
    open person(conversion_source_id);
    fetch person into person_tuple;

    -- Tant que tout les tuples n'ont pas été traîtés
    if person_tuple.cso_transfert_date is null and
       person_tuple.c_ascii_fail_reason is null then

      -- recherche de l'id de la person en fonction de PER_KEY1
      select MAX(PAC_PERSON_ID) into person_id
        from PAC_PERSON
        where PER_KEY1 = person_tuple.PER_KEY1;
      -- traitement suivant le type de mise à jour
      -- création
      if person_tuple.update_mode = '0' then
        if person_id is not null then
          -- Personne déjà créée
          update aci_conversion_source set c_ascii_fail_reason = '120'
          where aci_conversion_source_id = person_tuple.aci_conversion_source_id;
          control_flag := 0;
        else

          insert into PAC_PERSON(
            PAC_PERSON_ID,
            DIC_PERSON_POLITNESS_ID,
            PER_NAME,
            PER_FORENAME,
            PER_ACTIVITY,
            PER_KEY1,
            PER_SHORT_NAME,
            A_DATECRE,
            A_IDCRE)
          values(
            init_id_seq.nextval,
            person_tuple.DIC_PERSON_POLITNESS_ID,
            person_tuple.PER_NAME,
            person_tuple.PER_FORENAME,
            person_tuple.PER_ACTIVITY,
            person_tuple.PER_KEY1,
            person_tuple.PER_SHORT_NAME,
            SYSDATE,
            PCS.PC_I_LIB_SESSION.GetUserIni);

        end if;

      -- modification
      elsif person_tuple.update_mode = '1' then
        if (person_id is null) then
          -- Personne inexistante
          update aci_conversion_source set c_ascii_fail_reason = '150'
          where aci_conversion_source_id = person_tuple.aci_conversion_source_id;
          control_flag := 0;
        else
          update PAC_PERSON set
            DIC_PERSON_POLITNESS_ID = person_tuple.DIC_PERSON_POLITNESS_ID,
            PER_NAME                = nvl(person_tuple.PER_NAME,PER_NAME),
            PER_FORENAME            = person_tuple.PER_FORENAME,
            PER_ACTIVITY            = person_tuple.PER_ACTIVITY,
            PER_SHORT_NAME          = person_tuple.PER_SHORT_NAME,
            A_DATEMOD               = SYSDATE,
            A_IDMOD                 = PCS.PC_I_LIB_SESSION.GetUserIni
          where PER_KEY1            = person_tuple.PER_KEY1;
        end if;
      -- supression
      elsif person_tuple.update_mode = '9' then
        if person_id is null then
        -- Personne inexistante
          update aci_conversion_source set c_ascii_fail_reason = '150'
          where aci_conversion_source_id = person_tuple.aci_conversion_source_id;
          control_flag := 0;
        else
          -- effacement du tiers et de la personne
          -- si des clients/fournisseurs sont créés, il est impossible de les
          -- effacer depuis l'interface. Cependant aucune erreur n'est générée
          -- mais l'effacement n'aura pas lieu.
          begin
            delete from PAC_THIRD where PAC_THIRD_ID = person_id;
            delete from PAC_PERSON where PER_KEY1 = person_tuple.PER_KEY1;
          exception
            when ex.CHILD_RECORD_FOUND then
              -- en cas de non effacement, on met à jour le status des adresses
              update PAC_ADDRESS
                set C_PARTNER_STATUS = '0'
                where PAC_PERSON_ID       = person_id;
          end;
        end if;
      end if;
    elsif person_tuple.c_ascii_fail_reason is not null then
      control_flag := 0;
    end if;

    --fermeture du curseur
    close person;

  end Recover_Persons;


  /**
  * Description
  *   reprise d'une adresse depuis un fichier d'importation
  */
  procedure Recover_Addresses(conversion_source_id in number, control_flag IN OUT number)
  is
    cursor Address(conversion_source_id number)
    is
      select *
      from v_aci_ascii_address
      where aci_conversion_source_id = conversion_source_id;

    address_tuple address%rowtype;
    person_id     PAC_PERSON.PAC_PERSON_ID%type;
    adress_id     PAC_ADDRESS.PAC_ADDRESS_ID%type;
  begin
    -- ouverture du curseur
    open address(conversion_source_id);
    fetch address into address_tuple;

    -- Tant que tout les tuples n'ont pas été traîtés
    if address_tuple.cso_transfert_date is null and
       address_tuple.c_ascii_fail_reason is null then

      -- recherche de l'id de la person en fonction de PER_KEY1
      select MAX(PAC_PERSON_ID) into person_id
        from PAC_PERSON
        where PER_KEY1 = address_tuple.PER_KEY1;

      -- traitement suivant le type de mise à jour
      -- création
      if address_tuple.update_mode = '0' then

        if person_id is null then
          -- Personne n'existe pas
          update aci_conversion_source set c_ascii_fail_reason = '260'
            where aci_conversion_source_id = address_tuple.aci_conversion_source_id;
          control_flag := 0;
        else

          insert into PAC_ADDRESS(
            PAC_ADDRESS_ID,
            PAC_PERSON_ID,
            ADD_PRINCIPAL,
            ADD_ADDRESS1,
            ADD_ZIPCODE,
            ADD_CITY,
            ADD_STATE,
            PC_CNTRY_ID,
            PC_LANG_ID,
            DIC_ADDRESS_TYPE_ID,
            A_DATECRE,
            A_IDCRE)
          values(
            init_id_seq.nextval,
            person_id,
            1,
            address_tuple.ADD_ADDRESS1,
            address_tuple.ADD_ZIPCODE,
            address_tuple.ADD_CITY,
            address_tuple.ADD_STATE,
            address_tuple.PC_CNTRY_ID,
            address_tuple.PC_LANG_ID,
            address_tuple.DIC_ADDRESS_TYPE_ID,
            SYSDATE,
            PCS.PC_I_LIB_SESSION.GetUserIni);

        end if;

      -- modification
      elsif address_tuple.update_mode = '1' then
        select max(PAC_ADDRESS_ID)
        into adress_id
        from PAC_ADDRESS
        where PAC_PERSON_ID       = person_id
          and DIC_ADDRESS_TYPE_ID = address_tuple.DIC_ADDRESS_TYPE_ID;

        update PAC_ADDRESS set
          ADD_ADDRESS1 = address_tuple.ADD_ADDRESS1,
          ADD_ZIPCODE  = address_tuple.ADD_ZIPCODE,
          ADD_CITY     = address_tuple.ADD_CITY,
          ADD_STATE    = address_tuple.ADD_STATE,
          PC_LANG_ID   = nvl(address_tuple.PC_LANG_ID,   PC_LANG_ID),
          PC_CNTRY_ID  = nvl(address_tuple.PC_CNTRY_ID,  PC_CNTRY_ID),
          A_DATEMOD    = SYSDATE,
          A_IDMOD      = PCS.PC_I_LIB_SESSION.GetUserIni
        where PAC_ADDRESS_ID = adress_id;

      -- supression
      elsif address_tuple.update_mode = '9' then
        -- effacement en cascade sur PAC_PERSON
        null;
      end if;
    elsif address_tuple.c_ascii_fail_reason is not null then
      control_flag := 0;
    end if;
    close address;
  end Recover_Addresses;


  /**
  * Description
  *   reprise d'une communication depuis un fichier d'importation
  */
  procedure Recover_Communications(conversion_source_id in number, control_flag IN OUT number)
  is
    cursor communication(conversion_source_id number) is
      select * from v_aci_ascii_communication
        where aci_conversion_source_id = conversion_source_id;
    communication_tuple communication%rowtype;
    person_id PAC_PERSON.PAC_PERSON_ID%type;
    address_id PAC_ADDRESS.PAC_ADDRESS_ID%type;
    comId1 PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type;
    comId2 PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type;
    comId3 PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type;
  begin

    -- ouverture du curseur
    open communication(conversion_source_id);
    fetch communication into communication_tuple;

    -- Tant que tout les tuples n'ont pas été traîtés
    if communication_tuple.cso_transfert_date is null and
       communication_tuple.c_ascii_fail_reason is null then

      -- recherche de l'id de la person en fonction de PER_KEY1
      select MAX(PAC_PERSON_ID) into person_id
        from PAC_PERSON
        where PER_KEY1 = communication_tuple.PER_KEY1;

      -- recherche de l'id de l'adresse par défaut
      SELECT MAX(PAC_ADDRESS_ID) into address_id
        from PAC_ADDRESS, DIC_ADDRESS_TYPE
        where PAC_PERSON_ID = person_id
          and PAC_ADDRESS.DIC_ADDRESS_TYPE_ID = DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID
          and DIC_ADDRESS_TYPE.DAD_DEFAULT = 1;


      -- modification
      if communication_tuple.update_mode in ('1') then

        if communication_tuple.DIC_COMMUNICATION_TYPE_ID1 is not null then
          select max(PAC_COMMUNICATION_ID)
          into comId1
          from PAC_COMMUNICATION
          where PAC_PERSON_ID = person_id
            and PAC_ADDRESS_ID = address_id
            and DIC_COMMUNICATION_TYPE_ID = communication_tuple.DIC_COMMUNICATION_TYPE_ID1;

          update PAC_COMMUNICATION set
            COM_EXT_NUMBER = communication_tuple.COM_EXT_NUMBER1,
            COM_INT_NUMBER = communication_tuple.COM_INT_NUMBER1,
            COM_AREA_CODE  = communication_tuple.COM_AREA_CODE1,
            A_DATEMOD      = SYSDATE,
            A_IDMOD        = PCS.PC_I_LIB_SESSION.GetUserIni
          where PAC_COMMUNICATION_ID = comId1;
        end if;

        if communication_tuple.DIC_COMMUNICATION_TYPE_ID2 is not null then
          select max(PAC_COMMUNICATION_ID)
          into comId2
          from PAC_COMMUNICATION
          where PAC_PERSON_ID = person_id
            and PAC_ADDRESS_ID = address_id
            and DIC_COMMUNICATION_TYPE_ID = communication_tuple.DIC_COMMUNICATION_TYPE_ID2;

          update PAC_COMMUNICATION set
            COM_EXT_NUMBER = communication_tuple.COM_EXT_NUMBER2,
            COM_INT_NUMBER = communication_tuple.COM_INT_NUMBER2,
            COM_AREA_CODE  = communication_tuple.COM_AREA_CODE2,
            A_DATEMOD      = SYSDATE,
            A_IDMOD        = PCS.PC_I_LIB_SESSION.GetUserIni
          where PAC_COMMUNICATION_ID = comId2;
        end if;

        if communication_tuple.DIC_COMMUNICATION_TYPE_ID3 is not null then
          select max(PAC_COMMUNICATION_ID)
          into comId3
          from PAC_COMMUNICATION
          where PAC_PERSON_ID = person_id
            and PAC_ADDRESS_ID = address_id
            and DIC_COMMUNICATION_TYPE_ID = communication_tuple.DIC_COMMUNICATION_TYPE_ID3;

          update PAC_COMMUNICATION set
            COM_EXT_NUMBER = communication_tuple.COM_EXT_NUMBER3,
            COM_INT_NUMBER = communication_tuple.COM_INT_NUMBER3,
            COM_AREA_CODE  = communication_tuple.COM_AREA_CODE3,
            A_DATEMOD      = SYSDATE,
            A_IDMOD        = PCS.PC_I_LIB_SESSION.GetUserIni
          where PAC_COMMUNICATION_ID = comId3;
        end if;

      end if;

      -- traitement suivant le type de mise à jour
      -- création ou modification (nouveau tuple communication)
      if communication_tuple.update_mode in ('0','1') then


        if person_id is null then
          -- Personne n'existe pas
          update aci_conversion_source set c_ascii_fail_reason = '310'
            where aci_conversion_source_id = communication_tuple.aci_conversion_source_id;
          control_flag := 0;
        else

          if  comId1 is null and
              communication_tuple.DIC_COMMUNICATION_TYPE_ID1 is not null and
             (communication_tuple.COM_EXT_NUMBER1 is not null or
              communication_tuple.COM_INT_NUMBER1 is not null or
              communication_tuple.COM_AREA_CODE1 is not null) then
            insert into PAC_COMMUNICATION(
              PAC_COMMUNICATION_ID,
              PAC_PERSON_ID,
              PAC_ADDRESS_ID,
              DIC_COMMUNICATION_TYPE_ID,
              COM_EXT_NUMBER,
              COM_INT_NUMBER,
              COM_AREA_CODE,
              A_DATECRE,
              A_IDCRE)
            values(
              init_id_seq.nextval,
              person_id,
              address_id,
              communication_tuple.DIC_COMMUNICATION_TYPE_ID1,
              communication_tuple.COM_EXT_NUMBER1,
              communication_tuple.COM_INT_NUMBER1,
              communication_tuple.COM_AREA_CODE1,
              SYSDATE,
              PCS.PC_I_LIB_SESSION.GetUserIni);
          end if;

          if comId2 is null and
             communication_tuple.DIC_COMMUNICATION_TYPE_ID2 is not null and
             (communication_tuple.COM_EXT_NUMBER2 is not null or
              communication_tuple.COM_INT_NUMBER2 is not null or
              communication_tuple.COM_AREA_CODE2 is not null) then
            insert into PAC_COMMUNICATION(
              PAC_COMMUNICATION_ID,
              PAC_PERSON_ID,
              PAC_ADDRESS_ID,
              DIC_COMMUNICATION_TYPE_ID,
              COM_EXT_NUMBER,
              COM_INT_NUMBER,
              COM_AREA_CODE,
              A_DATECRE,
              A_IDCRE)
            values(
              init_id_seq.nextval,
              person_id,
              address_id,
              communication_tuple.DIC_COMMUNICATION_TYPE_ID2,
              communication_tuple.COM_EXT_NUMBER2,
              communication_tuple.COM_INT_NUMBER2,
              communication_tuple.COM_AREA_CODE2,
              SYSDATE,
              PCS.PC_I_LIB_SESSION.GetUserIni);
          end if;

          if comId3 is null and
             communication_tuple.DIC_COMMUNICATION_TYPE_ID3 is not null and
             (communication_tuple.COM_EXT_NUMBER3 is not null or
              communication_tuple.COM_INT_NUMBER3 is not null or
              communication_tuple.COM_AREA_CODE3 is not null) then
            insert into PAC_COMMUNICATION(
              PAC_COMMUNICATION_ID,
              PAC_PERSON_ID,
              PAC_ADDRESS_ID,
              DIC_COMMUNICATION_TYPE_ID,
              COM_EXT_NUMBER,
              COM_INT_NUMBER,
              COM_AREA_CODE,
              A_DATECRE,
              A_IDCRE)
            values(
              init_id_seq.nextval,
              person_id,
              address_id,
              communication_tuple.DIC_COMMUNICATION_TYPE_ID3,
              communication_tuple.COM_EXT_NUMBER3,
              communication_tuple.COM_INT_NUMBER3,
              communication_tuple.COM_AREA_CODE3,
              SYSDATE,
              PCS.PC_I_LIB_SESSION.GetUserIni);
          end if;

        end if;

      end if;

      -- supression
      if communication_tuple.update_mode = '9' then

        if communication_tuple.DIC_COMMUNICATION_TYPE_ID1 is not null then
          begin
            delete from PAC_COMMUNICATION
              where PAC_PERSON_ID             = person_id
                and PAC_ADDRESS_ID            = address_id
                and DIC_COMMUNICATION_TYPE_ID = communication_tuple.DIC_COMMUNICATION_TYPE_ID1;
          exception
            when ex.CHILD_RECORD_FOUND then
              null;
          end;
        end if;

        if communication_tuple.DIC_COMMUNICATION_TYPE_ID2 is not null then
          begin
            delete from PAC_COMMUNICATION
              where PAC_PERSON_ID             = person_id
                and PAC_ADDRESS_ID            = address_id
                and DIC_COMMUNICATION_TYPE_ID = communication_tuple.DIC_COMMUNICATION_TYPE_ID2;
          exception
            when ex.CHILD_RECORD_FOUND then
              null;
          end;
        end if;

        if communication_tuple.DIC_COMMUNICATION_TYPE_ID3 is not null then
          begin
            delete from PAC_COMMUNICATION
              where PAC_PERSON_ID             = person_id
                and PAC_ADDRESS_ID            = address_id
                and DIC_COMMUNICATION_TYPE_ID = communication_tuple.DIC_COMMUNICATION_TYPE_ID3;
          exception
            when ex.CHILD_RECORD_FOUND then
              null;
          end;
        end if;

      end if;

    elsif communication_tuple.c_ascii_fail_reason is not null then
      control_flag := 0;
    end if;

    --fermeture du curseur
    close communication;

  end Recover_Communications;


  /**
  * Description
  *   reprise d'un tiers depuis un fichier d'importation
  */
  procedure Recover_Thirds(conversion_source_id in number, control_flag IN OUT number)
  is
    cursor third(conversion_source_id number) is
      select * from v_aci_ascii_third
        where aci_conversion_source_id = conversion_source_id;
    third_tuple third%rowtype;
    person_id PAC_PERSON.PAC_PERSON_ID%type;
  begin

    -- ouverture du curseur
    open third(conversion_source_id);
    fetch third into third_tuple;

    -- Tant que tout les tuples n'ont pas été traîtés
    if third%found then

      -- recherche de l'id de la person en fonction de PER_KEY1
      select MAX(PAC_PERSON_ID) into person_id
        from PAC_PERSON
        where PER_KEY1 = third_tuple.PER_KEY1;

      -- traitement suivant le type de mise à jour
      -- création
      if third_tuple.update_mode = '0' then

        if person_id is null then
          -- Personne n'existe pas
          update aci_conversion_source set c_ascii_fail_reason = '410'
            where aci_conversion_source_id = third_tuple.aci_conversion_source_id;
          control_flag := 0;
        else

          begin
            insert into PAC_THIRD(
              PAC_THIRD_ID,
              THI_NO_TVA,
              THI_NO_INTRA,
              THI_NO_SIREN,
              THI_NO_SIRET,
              A_DATECRE,
              A_IDCRE)
            values(
              person_id,
              third_tuple.THI_NO_TVA,
              third_tuple.THI_NO_INTRA,
              third_tuple.THI_NO_SIREN,
              third_tuple.THI_NO_SIRET,
              SYSDATE,
              PCS.PC_I_LIB_SESSION.GetUserIni);
          exception
            when DUP_VAL_ON_INDEX then
              null;
          end;


        end if;

      -- modification
      elsif third_tuple.update_mode = '1' then

        update PAC_THIRD set
          THI_NO_TVA   = third_tuple.THI_NO_TVA,
          THI_NO_INTRA = third_tuple.THI_NO_INTRA,
          THI_NO_SIREN = third_tuple.THI_NO_SIREN,
          THI_NO_SIRET = third_tuple.THI_NO_SIRET,
          A_DATEMOD    = SYSDATE,
          A_IDMOD      = PCS.PC_I_LIB_SESSION.GetUserIni
        where PAC_THIRD_ID = person_id;

      -- supression
      elsif third_tuple.update_mode = '9' then

        begin
          delete from PAC_THIRD where PAC_THIRD_ID = person_id;
        exception
          when ex.CHILD_RECORD_FOUND then
            null;
        end;

      end if;

    elsif third_tuple.c_ascii_fail_reason is not null then
      control_flag := 0;
    end if;

    --fermeture du curseur
    close third;

  end Recover_Thirds;


  /**
  * Description
  *   reprise d'un client depuis un fichier d'importation
  */
  procedure Recover_Customers(conversion_source_id in number, control_flag IN OUT number)
  is
    cursor customer(conversion_source_id number) is
      select * from v_aci_ascii_customer
        where aci_conversion_source_id = conversion_source_id;
    customer_tuple customer%rowtype;
    person_id PAC_PERSON.PAC_PERSON_ID%type;
    auxiliary_account_id ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
    sub_set_id ACS_SUB_SET.ACS_SUB_SET_ID%type;
    submission_id DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type;
    parent_not_exist EXCEPTION;
    pragma EXCEPTION_INIT(parent_not_exist,-2291);
  -----
  begin

    -- ouverture du curseur
    open customer(conversion_source_id);
    fetch customer into customer_tuple;

    -- Tant que tout les tuples n'ont pas été traîtés
    if customer_tuple.cso_transfert_date is null and
       customer_tuple.c_ascii_fail_reason is null then

      -- recherche de l'id de la person en fonction de PER_KEY1
      select MAX(PAC_PERSON_ID) into person_id
      from PAC_PERSON, PAC_THIRD
      where PER_KEY1 = customer_tuple.PER_KEY1;

      -- traitement suivant le type de mise à jour
      -- création
      if customer_tuple.update_mode = '0' then

        if person_id is null then
          -- Personne n'existe pas
          update aci_conversion_source set c_ascii_fail_reason = '570'
            where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        else

          -- compte individuel  / compte groupe
          if customer_tuple.C_PARTNER_CATEGORY in ('1','2') then

            -- recherche de l'id du sous ensemble pour les clients
            if customer_tuple.ACS_SUB_SET_ID is null then
              select MIN(ACS_SUB_SET_ID) into sub_set_id
                from ACS_SUB_SET where C_SUB_SET = 'REC';
            else
              sub_set_id := customer_tuple.ACS_SUB_SET_ID;
            end if;

            -- création du compte auxiliaire
            PAC_PARTNER_MANAGEMENT.CreateAuxiliaryAccount(person_id,
                                                          sub_set_id,
                                                          customer_tuple.C_PARTNER_CATEGORY,
                                                          customer_tuple.ACS_FINANCIAL_CURRENCY_ID,
                                                          null,
                                                          auxiliary_account_id);

            -- mise à jour des compte INVOICE et PREP selon les données de la vue
            update ACS_AUXILIARY_ACCOUNT
               set ACS_INVOICE_COLL_ID = nvl(customer_tuple.ACS_INVOICE_COLL_ID, ACS_INVOICE_COLL_ID),
                   ACS_PREP_COLL_ID    = nvl(customer_tuple.ACS_PREP_COLL_ID, ACS_PREP_COLL_ID)
               where ACS_AUXILIARY_ACCOUNT_ID = auxiliary_account_id;

          -- membre de groupe / membre de divers
          elsif customer_tuple.C_PARTNER_CATEGORY in ('3','4') then
            auxiliary_account_id := customer_tuple.ACS_AUXILIARY_ACCOUNT_ID;
          end if;

          if auxiliary_account_id is null then
            -- Problème avec compte auxiliaire
            if customer_tuple.C_PARTNER_CATEGORY in ('1','2') then
              update aci_conversion_source set c_ascii_fail_reason = '581'
                where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
            elsif customer_tuple.C_PARTNER_CATEGORY in ('3','4') then
              update aci_conversion_source set c_ascii_fail_reason = '582'
                where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
            end if;
            control_flag := 0;
          else

            submission_id := GetDIC_TYPE_SUBMISSION_ID(customer_tuple.DIC_TYPE_SUBMISSION_ID, false);
            -- Retourne min(DIC_TYPE_SUBMISSION_ID) si customer_tuple.DIC_TYPE_SUBMISSION_ID non valable !

            begin

              insert into PAC_CUSTOM_PARTNER(
                PAC_CUSTOM_PARTNER_ID,
                C_PARTNER_CATEGORY,
                PAC_PAYMENT_CONDITION_ID,
                ACS_VAT_DET_ACCOUNT_ID,
                ACS_AUXILIARY_ACCOUNT_ID,
                PAC_REPRESENTATIVE_ID,
                C_PARTNER_STATUS,
                C_TYPE_EDI,
                C_REMAINDER_LAUNCHING,
                DIC_TYPE_SUBMISSION_ID,
                PAC_REMAINDER_CATEGORY_ID,
                A_DATECRE,
                A_IDCRE)
              values(
                person_id,
                customer_tuple.C_PARTNER_CATEGORY,
                customer_tuple.PAC_PAYMENT_CONDITION_ID,
                customer_tuple.ACS_VAT_DET_ACCOUNT_ID,
                auxiliary_account_id,
                customer_tuple.PAC_REPRESENTATIVE_ID,
                customer_tuple.C_PARTNER_STATUS,
                customer_tuple.C_TYPE_EDI,
                customer_tuple.C_REMAINDER_LAUNCHING,
                submission_id,
                customer_tuple.PAC_REMAINDER_CATEGORY_ID,
                SYSDATE,
                PCS.PC_I_LIB_SESSION.GetUserIni);

            exception
              -- problème d'insertion dans la table PAC_CUSTOM_PARTNER
              when DUP_VAL_ON_INDEX then
                null;
              when others then
                update aci_conversion_source set c_ascii_fail_reason = to_char(auxiliary_account_id)
                  where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
                control_flag := 0;
            end;

          end if;

        end if;

      -- modification
      elsif customer_tuple.update_mode = '1' then
        if person_id is null then
          -- Personne n'existe pas
          update aci_conversion_source set c_ascii_fail_reason = '570'
            where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        else
          submission_id := GetDIC_TYPE_SUBMISSION_ID(customer_tuple.DIC_TYPE_SUBMISSION_ID, true);
          -- Retourne NULL si customer_tuple.DIC_TYPE_SUBMISSION_ID non valable !
          update PAC_CUSTOM_PARTNER set
            C_PARTNER_CATEGORY       = nvl(customer_tuple.C_PARTNER_CATEGORY,C_PARTNER_CATEGORY),
            PAC_PAYMENT_CONDITION_ID = nvl(customer_tuple.PAC_PAYMENT_CONDITION_ID,PAC_PAYMENT_CONDITION_ID),
            ACS_VAT_DET_ACCOUNT_ID   = nvl(customer_tuple.ACS_VAT_DET_ACCOUNT_ID,ACS_VAT_DET_ACCOUNT_ID),
            ACS_AUXILIARY_ACCOUNT_ID = nvl(customer_tuple.ACS_AUXILIARY_ACCOUNT_ID,ACS_AUXILIARY_ACCOUNT_ID),
            PAC_REPRESENTATIVE_ID    = nvl(customer_tuple.PAC_REPRESENTATIVE_ID,PAC_REPRESENTATIVE_ID),
            C_PARTNER_STATUS         = nvl(customer_tuple.C_PARTNER_STATUS,C_PARTNER_STATUS),
            C_TYPE_EDI               = nvl(customer_tuple.C_TYPE_EDI,C_TYPE_EDI),
            C_REMAINDER_LAUNCHING    = nvl(customer_tuple.C_REMAINDER_LAUNCHING,C_REMAINDER_LAUNCHING),
            DIC_TYPE_SUBMISSION_ID   = nvl(submission_id, DIC_TYPE_SUBMISSION_ID),
            A_DATEMOD                = sysdate,
            A_IDMOD                  = PCS.PC_I_LIB_SESSION.GetUserIni
          where PAC_CUSTOM_PARTNER_ID = person_id;
        end if;
      -- supression
      elsif customer_tuple.update_mode = '9' then
        if person_id is null then
          -- Personne n'existe pas
          update aci_conversion_source set c_ascii_fail_reason = '570'
            where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        else
          begin
            delete from PAC_CUSTOM_PARTNER where PAC_CUSTOM_PARTNER_ID = person_id;
          exception
            when ex.CHILD_RECORD_FOUND then
              update PAC_CUSTOM_PARTNER
                set C_PARTNER_STATUS = '0'
                where PAC_CUSTOM_PARTNER_ID = person_id;
          end;
        end if;
      end if;
      auxiliary_account_id := null;
    elsif customer_tuple.c_ascii_fail_reason is not null then
      control_flag := 0;
    end if;

    --fermeture du curseur
    close customer;

  end Recover_Customers;


  /**
  * Description
  *   reprise d'un client depuis un fichier d'importation
  */
  procedure Recover_Suppliers(conversion_source_id in number, control_flag IN OUT number)
  is
    cursor supplier(conversion_source_id number) is
      select * from v_aci_ascii_supplier
        where aci_conversion_source_id = conversion_source_id;
    supplier_tuple supplier%rowtype;
    person_id PAC_PERSON.PAC_PERSON_ID%type;
    auxiliary_account_id ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
    sub_set_id ACS_SUB_SET.ACS_SUB_SET_ID%type;
    submission_id DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type;
  begin

    -- ouverture du curseur
    open supplier(conversion_source_id);
    fetch supplier into supplier_tuple;

    -- Tant que tout les tuples n'ont pas été traîtés
    if supplier_tuple.cso_transfert_date is null and
       supplier_tuple.c_ascii_fail_reason is null then

      -- recherche de l'id de la person en fonction de PER_KEY1
      select MAX(PAC_PERSON_ID) into person_id
        from PAC_PERSON
        where PER_KEY1 = supplier_tuple.PER_KEY1;

      -- traitement suivant le type de mise à jour
      -- création
      if supplier_tuple.update_mode = '0' then

        if person_id is null then
          -- Personne n'existe pas
          update aci_conversion_source set c_ascii_fail_reason = '670'
            where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        else

          -- compte individuel  / compte groupe
          if supplier_tuple.C_PARTNER_CATEGORY in ('1','2') then

            -- recherche de l'id du sous ensemble pour les fournisseurs
            if supplier_tuple.ACS_SUB_SET_ID is null then
              select MIN(ACS_SUB_SET_ID) into sub_set_id
                from ACS_SUB_SET where C_SUB_SET = 'PAY';
            else
              sub_set_id := supplier_tuple.ACS_SUB_SET_ID;
            end if;

            -- création du compte auxiliaire
            PAC_PARTNER_MANAGEMENT.CreateAuxiliaryAccount(person_id,
                                                          sub_set_id,
                                                          supplier_tuple.C_PARTNER_CATEGORY,
                                                          supplier_tuple.ACS_FINANCIAL_CURRENCY_ID,
                                                          null,
                                                          auxiliary_account_id);

            -- mise à jour des compte INVOICE et PREP selon les données de la vue
            update ACS_AUXILIARY_ACCOUNT
               set ACS_INVOICE_COLL_ID = nvl(supplier_tuple.ACS_INVOICE_COLL_ID, ACS_INVOICE_COLL_ID),
                   ACS_PREP_COLL_ID = nvl(supplier_tuple.ACS_PREP_COLL_ID, ACS_PREP_COLL_ID)
               where ACS_AUXILIARY_ACCOUNT_ID = auxiliary_account_id;

          -- membre de groupe / membre de divers
          elsif supplier_tuple.C_PARTNER_CATEGORY in ('3','4') then
            auxiliary_account_id := supplier_tuple.ACS_AUXILIARY_ACCOUNT_ID;
          end if;

          if auxiliary_account_id is null then
            -- Problème avec compte auxiliaire
            if supplier_tuple.C_PARTNER_CATEGORY in ('1','2') then
              update aci_conversion_source set c_ascii_fail_reason = '581'
                where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
            elsif supplier_tuple.C_PARTNER_CATEGORY in ('3','4') then
              update aci_conversion_source set c_ascii_fail_reason = '582'
                where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
            end if;
            control_flag := 0;
          else

            submission_id := GetDIC_TYPE_SUBMISSION_ID(supplier_tuple.DIC_TYPE_SUBMISSION_ID, false);
            -- Retourne min(DIC_TYPE_SUBMISSION_ID) si supplier_tuple.DIC_TYPE_SUBMISSION_ID non valable !

            begin
              insert into PAC_SUPPLIER_PARTNER(
                PAC_SUPPLIER_PARTNER_ID,
                C_PARTNER_CATEGORY,
                PAC_PAYMENT_CONDITION_ID,
                ACS_VAT_DET_ACCOUNT_ID,
                ACS_AUXILIARY_ACCOUNT_ID,
                C_PARTNER_STATUS,
                C_TYPE_EDI,
                C_REMAINDER_LAUNCHING,
                DIC_TYPE_SUBMISSION_ID,
                PAC_REMAINDER_CATEGORY_ID,
                A_DATECRE,
                A_IDCRE)
              values(
                person_id,
                supplier_tuple.C_PARTNER_CATEGORY,
                supplier_tuple.PAC_PAYMENT_CONDITION_ID,
                supplier_tuple.ACS_VAT_DET_ACCOUNT_ID,
                auxiliary_account_id,
                supplier_tuple.C_PARTNER_STATUS,
                supplier_tuple.C_TYPE_EDI,
                supplier_tuple.C_REMAINDER_LAUNCHING,
                submission_id,
                supplier_tuple.PAC_REMAINDER_CATEGORY_ID,
                SYSDATE,
                PCS.PC_I_LIB_SESSION.GetUserIni);
            exception
              -- problème d'insertion dans la table PAC_SUPPLIER_PARTNER
              when DUP_VAL_ON_INDEX then
                null;
              when others then
                update aci_conversion_source set c_ascii_fail_reason = to_char(auxiliary_account_id)
                  where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
                control_flag := 0;
            end;

          end if;

        end if;

      -- modification
      elsif supplier_tuple.update_mode = '1' then
        if person_id is null then
          -- Personne n'existe pas
          update aci_conversion_source set c_ascii_fail_reason = '670'
            where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        else
          submission_id := GetDIC_TYPE_SUBMISSION_ID(supplier_tuple.DIC_TYPE_SUBMISSION_ID, true);
          -- Retourne NULL si supplier_tuple.DIC_TYPE_SUBMISSION_ID non valable !
          update PAC_SUPPLIER_PARTNER set
            C_PARTNER_CATEGORY       = nvl(supplier_tuple.C_PARTNER_CATEGORY,C_PARTNER_CATEGORY),
            PAC_PAYMENT_CONDITION_ID = nvl(supplier_tuple.PAC_PAYMENT_CONDITION_ID,PAC_PAYMENT_CONDITION_ID),
            ACS_VAT_DET_ACCOUNT_ID   = nvl(supplier_tuple.ACS_VAT_DET_ACCOUNT_ID,ACS_VAT_DET_ACCOUNT_ID),
            C_PARTNER_STATUS         = nvl(supplier_tuple.C_PARTNER_STATUS,C_PARTNER_STATUS),
            C_TYPE_EDI               = nvl(supplier_tuple.C_TYPE_EDI,C_TYPE_EDI),
            C_REMAINDER_LAUNCHING    = nvl(supplier_tuple.C_REMAINDER_LAUNCHING,C_REMAINDER_LAUNCHING),
            DIC_TYPE_SUBMISSION_ID   = nvl(submission_id, DIC_TYPE_SUBMISSION_ID),
            A_DATEMOD                = sysdate,
            A_IDMOD                  = PCS.PC_I_LIB_SESSION.GetUserIni
          where PAC_SUPPLIER_PARTNER_ID = person_id;
        end if;
      -- supression
      elsif supplier_tuple.update_mode = '9' then
        if person_id is null then
          -- Personne n'existe pas
          update aci_conversion_source set c_ascii_fail_reason = '670'
            where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        else
          begin
            delete from PAC_SUPPLIER_PARTNER where PAC_SUPPLIER_PARTNER_ID = person_id;
          exception
            when ex.CHILD_RECORD_FOUND then
              update PAC_SUPPLIER_PARTNER
                set C_PARTNER_STATUS = '0'
                where PAC_SUPPLIER_PARTNER_ID = person_id;
          end;
        end if;
      end if;
    elsif supplier_tuple.c_ascii_fail_reason is not null then
      control_flag := 0;
    end if;

    --fermeture du curseur
    close supplier;

  end Recover_Suppliers;


  /**
  * Description
  *   reprise d'un client depuis un fichier d'importation
  */
  procedure Recover_References(conversion_source_id in number, control_flag IN OUT number)
  is
    cursor reference(conversion_source_id number) is
      select * from v_aci_ascii_fin_reference
        where aci_conversion_source_id = conversion_source_id
          and cso_transfert_date is null
          and c_ascii_fail_reason is null;
    reference_tuple reference%rowtype;
    person_id PAC_PERSON.PAC_PERSON_ID%type;
  begin


    -- ouverture du curseur
    open reference(conversion_source_id);
    fetch reference into reference_tuple;

    -- Tant que tout les tuples n'ont pas été traîtés
    if reference_tuple.cso_transfert_date is null and
       reference_tuple.c_ascii_fail_reason is null then

      -- recherche de l'id de la person en fonction de PER_KEY1
      if reference_tuple.C_TYPE_PARTNER = '1' then
        select MAX(PAC_PERSON_ID) into person_id
          from PAC_PERSON, PAC_CUSTOM_PARTNER
          where PER_KEY1 = reference_tuple.PER_KEY1
            and PAC_CUSTOM_PARTNER_ID = PAC_PERSON_ID;
      elsif reference_tuple.C_TYPE_PARTNER = '2' then
        select MAX(PAC_PERSON_ID) into person_id
          from PAC_PERSON, PAC_SUPPLIER_PARTNER
          where PER_KEY1 = reference_tuple.PER_KEY1
            and PAC_SUPPLIER_PARTNER_ID = PAC_PERSON_ID;
      end if;

      -- traitement suivant le type de mise à jour
      -- création
      if reference_tuple.update_mode = '0' then

        if person_id is null then
          if reference_tuple.C_TYPE_PARTNER = '1' then
            -- Client n'existe pas
            update aci_conversion_source set c_ascii_fail_reason = '720'
              where aci_conversion_source_id = reference_tuple.aci_conversion_source_id;
            control_flag := 0;
          elsif reference_tuple.C_TYPE_PARTNER = '2' then
            -- Fournisseur n'existe pas
            update aci_conversion_source set c_ascii_fail_reason = '730'
              where aci_conversion_source_id = reference_tuple.aci_conversion_source_id;
            control_flag := 0;
          end if;
        else

          begin
            insert into PAC_FINANCIAL_REFERENCE(
              PAC_FINANCIAL_REFERENCE_ID,
              PAC_SUPPLIER_PARTNER_ID,
              PAC_CUSTOM_PARTNER_ID,
              C_TYPE_REFERENCE,
              PC_CNTRY_ID,
              PC_BANK_ID,
              FRE_DEFAULT,
              FRE_ACCOUNT_NUMBER,
              FRE_ACCOUNT_CONTROL,
              FRE_DOM_NAME,
              FRE_DOM_CITY,
              FRE_ESTAB,
              FRE_POSITION,
              A_DATECRE,
              A_IDCRE)
            values(
              init_id_seq.nextval,
              DECODE(reference_tuple.C_TYPE_PARTNER,'2',person_id),
              DECODE(reference_tuple.C_TYPE_PARTNER,'1',person_id),
              reference_tuple.C_TYPE_REFERENCE,
              reference_tuple.PC_CNTRY_ID,
              DECODE(reference_tuple.C_TYPE_REFERENCE,'1',reference_tuple.PC_BANK_ID,null),
              reference_tuple.FRE_DEFAULT,
              reference_tuple.FRE_ACCOUNT_NUMBER,
              reference_tuple.FRE_ACCOUNT_CONTROL,
              reference_tuple.FRE_DOM_NAME,
              reference_tuple.FRE_DOM_CITY,
              reference_tuple.BAN_ETAB,
              reference_tuple.BAN_GUICH,
              SYSDATE,
              PCS.PC_I_LIB_SESSION.GetUserIni);
          exception
            when DUP_VAL_ON_INDEX then
              null;
          end;

        end if;

      -- modification
      elsif reference_tuple.update_mode = '1' then

        update PAC_FINANCIAL_REFERENCE set
          PC_CNTRY_ID         = NVL(reference_tuple.PC_CNTRY_ID,PC_CNTRY_ID),
          PC_BANK_ID          = NVL(reference_tuple.PC_BANK_ID,PC_BANK_ID),
          FRE_DEFAULT         = NVL(reference_tuple.FRE_DEFAULT,FRE_DEFAULT),
          FRE_ACCOUNT_CONTROL = NVL(reference_tuple.FRE_ACCOUNT_CONTROL,FRE_ACCOUNT_CONTROL),
          FRE_DOM_NAME        = NVL(reference_tuple.FRE_DOM_NAME,FRE_DOM_NAME),
          FRE_DOM_CITY        = NVL(reference_tuple.FRE_DOM_CITY,FRE_DOM_CITY),
          FRE_ESTAB           = NVL(reference_tuple.BAN_ETAB,FRE_ESTAB),
          FRE_POSITION        = NVL(reference_tuple.BAN_GUICH,FRE_POSITION),
          A_DATEMOD           = SYSDATE,
          A_IDMOD             = PCS.PC_I_LIB_SESSION.GetUserIni
        where
          ((PAC_SUPPLIER_PARTNER_ID = DECODE(reference_tuple.C_TYPE_PARTNER,'2',person_id) and PAC_CUSTOM_PARTNER_ID IS NULL) or
          (PAC_CUSTOM_PARTNER_ID   = DECODE(reference_tuple.C_TYPE_PARTNER,'1',person_id) and PAC_SUPPLIER_PARTNER_ID IS NULL)) and
          C_TYPE_REFERENCE    = reference_tuple.C_TYPE_REFERENCE and
          FRE_ACCOUNT_NUMBER  = reference_tuple.FRE_ACCOUNT_NUMBER;

      -- supression
      elsif reference_tuple.update_mode = '9' then

        begin
          delete from PAC_FINANCIAL_REFERENCE
          where
            ((PAC_SUPPLIER_PARTNER_ID = DECODE(reference_tuple.C_TYPE_PARTNER,'2',person_id) and PAC_CUSTOM_PARTNER_ID IS NULL) or
            (PAC_CUSTOM_PARTNER_ID   = DECODE(reference_tuple.C_TYPE_PARTNER,'1',person_id) and PAC_SUPPLIER_PARTNER_ID IS NULL)) and
            C_TYPE_REFERENCE    = reference_tuple.C_TYPE_REFERENCE and
            FRE_ACCOUNT_NUMBER  = reference_tuple.FRE_ACCOUNT_NUMBER;
        exception
          when ex.CHILD_RECORD_FOUND then
            update PAC_FINANCIAL_REFERENCE
              set C_PARTNER_STATUS = '0'
              where
                ((PAC_SUPPLIER_PARTNER_ID = DECODE(reference_tuple.C_TYPE_PARTNER,'2',person_id) and PAC_CUSTOM_PARTNER_ID IS NULL) or
                (PAC_CUSTOM_PARTNER_ID   = DECODE(reference_tuple.C_TYPE_PARTNER,'1',person_id) and PAC_SUPPLIER_PARTNER_ID IS NULL)) and
                C_TYPE_REFERENCE    = reference_tuple.C_TYPE_REFERENCE and
                FRE_ACCOUNT_NUMBER  = reference_tuple.FRE_ACCOUNT_NUMBER;
        end;

      end if;

    elsif reference_tuple.c_ascii_fail_reason is not null then
      control_flag := 0;
    end if;

    --fermeture du curseur
    close reference;

  end Recover_References;

  /**
  * Description
  *   retourne le code de la première erreur trouvée
  */
  function getErrorMessage(aConversionId in number)
     return varchar2
  is
    result ACI_CONVERSION_SOURCE.C_ASCII_FAIL_REASON%type;
  begin
    select C_ASCII_FAIL_REASON into result
      from ACI_CONVERSION_SOURCE
     where  ACI_CONVERSION_SOURCE_ID = (select min(ACI_CONVERSION_SOURCE_ID)
                                          from ACI_CONVERSION_SOURCE
                                         where ACI_CONVERSION_ID = aConversionId
                                           and C_ASCII_FAIL_REASON is not null);
    return result;
  exception
    when no_data_found then
      return null;
  end getErrorMessage;

end ACI_ASCII_PERSON;
