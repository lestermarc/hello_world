--------------------------------------------------------
--  DDL for Package Body ACI_ASCII_CTRL_PERSON
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_ASCII_CTRL_PERSON" 
is

  /**
  * Description
  *    Contr�le que les conditions requises au bon fonctionnement de
  *    l'interface de reprise de tiers soient remplies
  */
  procedure Ctrl_Global
  is
    dic_id varchar2(10);
  begin

    begin
      -- V�rifie que l'on ait un et un seul type d'adresse par defaut
      select DIC_ADDRESS_TYPE_ID into dic_id
        from DIC_ADDRESS_TYPE
        where DAD_DEFAULT = 1;
    exception
      when others then
        raise_application_error(-20020,'PCS - Probl�me with default address type');
    end;

    begin
      -- V�rifie que l'on ait un et un seul type de commmunication 1 par defaut
      select DIC_COMMUNICATION_TYPE_ID into dic_id
        from DIC_COMMUNICATION_TYPE
        where DCO_DEFAULT1 = 1;
    exception
      when others then
        raise_application_error(-20021,'PCS - Probl�me with default communication type 1');
    end;

    begin
      -- V�rifie que l'on ait un et un seul type de commmunication 2 par defaut
      select DIC_COMMUNICATION_TYPE_ID into dic_id
        from DIC_COMMUNICATION_TYPE
        where DCO_DEFAULT2 = 1;
    exception
      when others then
        raise_application_error(-20022,'PCS - Probl�me with default communication type 2');
    end;

  end Ctrl_Global;

  /**
  * Description
  *    pour un fichier d'int�gration, contr�le des donn�es "PAC_PERSON"
  */
  procedure Ctrl_Persons(conversion_id in number, control_flag IN OUT number)
  is
    cursor person(conversion_id number) is
      select * from v_aci_ascii_person
        where aci_conversion_id = conversion_id
          and c_ascii_fail_reason is null;
    person_tuple person%rowtype;
    person_id PAC_PERSON.PAC_PERSON_ID%type;
  begin

    -- ouverture du curseur
    open person(conversion_id);
    fetch person into person_tuple;

    -- Tant que tout les tuples n'ont pas �t� tra�t�s
    while person%found loop

      -- traitement suivant le type de mise � jour (effacer, modifier, ajouter)
      -- supression
      if person_tuple.update_mode = '9' then
        null;
      -- modification
      elsif person_tuple.update_mode = '1' then
        null;
      else
        -- cr�ation
        if person_tuple.per_name is null then
        -- Nom de la personne manquant
          update aci_conversion_source set c_ascii_fail_reason = '110'
          where aci_conversion_source_id = person_tuple.aci_conversion_source_id;
          control_flag := 0;

          if (person_id is not null) then
            -- Personne d�j� cr��e
            update aci_conversion_source set c_ascii_fail_reason = '120'
            where aci_conversion_source_id = person_tuple.aci_conversion_source_id;
            control_flag := 0;
          end if;
        end if;
      end if;
      fetch person into person_tuple;
    end loop;

    --fermeture du curseur
    close person;

  end Ctrl_Persons;


  /**
  * Description
  *    pour un fichier d'int�gration, contr�le des donn�es "PAC_ADDRESSE"
  */
  procedure Ctrl_Addresses(conversion_id in number, control_flag IN OUT number)
  is
    cursor Address(conversion_id number)
    is
      select *
      from v_aci_ascii_address
      where aci_conversion_id = conversion_id
        and c_ascii_fail_reason is null;

    address_tuple address%rowtype;
    add_type      DIC_ADDRESS_TYPE.DIC_ADDRESS_TYPE_ID%type;
  begin
    -- Ouverture et parcours du curseur
    open address(conversion_id);
    fetch address into address_tuple;
    while address%found
    loop
      if not address_tuple.DIC_ADDRESS_TYPE_ID is null then                         -- Type d'adresse renseign�
        select max(DIC_ADDRESS_TYPE_ID)                                             --Cont�le existence du type d'adresse donn�
        into add_type
        from DIC_ADDRESS_TYPE
        where DIC_ADDRESS_TYPE_ID = address_tuple.DIC_ADDRESS_TYPE_ID;
      end if;

      if address_tuple.update_mode = '9' then                                      -- Supression
        Null;
      elsif add_type is null then                                                  --Type d'adresse inexistante
        update ACI_CONVERSION_SOURCE
        set C_ASCII_FAIL_REASON = '200'
        where ACI_CONVERSION_SOURCE_ID = address_tuple.ACI_CONVERSION_SOURCE_ID;
        control_flag := 0;
      elsif address_tuple.PC_CNTRY_ID is null then                                 -- Code pays absent ou mauvais
        update ACI_CONVERSION_SOURCE
        set C_ASCII_FAIL_REASON = '210'
        where ACI_CONVERSION_SOURCE_ID = address_tuple.ACI_CONVERSION_SOURCE_ID;
        control_flag := 0;
      elsif address_tuple.PC_LANG_ID is null then                                  -- Code langue absent ou mauvais
        update ACI_CONVERSION_SOURCE
        set C_ASCII_FAIL_REASON = '220'
        where ACI_CONVERSION_SOURCE_ID = address_tuple.ACI_CONVERSION_SOURCE_ID;
        control_flag := 0;
      elsif address_tuple.ADD_CITY is null then                                    -- Localit� absente ou mauvaise
        update ACI_CONVERSION_SOURCE
        set C_ASCII_FAIL_REASON = '230'
        where ACI_CONVERSION_SOURCE_ID = address_tuple.ACI_CONVERSION_SOURCE_ID;
        control_flag := 0;
      else                                                                         -- traitement suivant le type de mise � jour
        if address_tuple.update_mode = '0' then                                    -- cr�ation
          Null;
        elsif address_tuple.update_mode = '1' then                                 -- modification
          Null;
        end if;
      end if;

      fetch address into address_tuple;
    end loop;
    close address;
  end Ctrl_Addresses;


  /**
  * Description
  *    pour un fichier d'int�gration, contr�le des donn�es "PAC_COMMUNICATION"
  */
  procedure Ctrl_Communications(conversion_id in number, control_flag IN OUT number)
  is
    cursor communication(conversion_id number) is
      select * from v_aci_ascii_communication
        where aci_conversion_id = conversion_id
          and c_ascii_fail_reason is null;
    communication_tuple communication%rowtype;
    person_id PAC_PERSON.PAC_PERSON_ID%type;
    address_id PAC_ADDRESS.PAC_ADDRESS_ID%type;
  begin

    null;

    /*

    -- ouverture du curseur
    open communication(conversion_id);
    fetch communication into communication_tuple;

    -- Tant que tout les tuples n'ont pas �t� tra�t�s
    while communication%found loop

      -- traitement suivant le type de mise � jour
      -- cr�ation
      if communication_tuple.update_mode = '0' then

          Null;

      -- modification
      elsif communication_tuple.update_mode = '1' then

          Null;

      -- supression
      elsif communication_tuple.update_mode = '9' then

          Null;

      end if;

      fetch communication into communication_tuple;

    end loop;

    --fermeture du curseur
    close communication;

    */

  end Ctrl_Communications;


  /**
  * Description
  *    pour un fichier d'int�gration, contr�le des donn�es "PAC_THIRD"
  */
  procedure Ctrl_Thirds(conversion_id in number, control_flag IN OUT number)
  is
    cursor third(conversion_id number) is
      select * from v_aci_ascii_third
        where aci_conversion_id = conversion_id
          and c_ascii_fail_reason is null;
    third_tuple third%rowtype;
    person_id PAC_PERSON.PAC_PERSON_ID%type;
  begin


    -- ouverture du curseur
    open third(conversion_id);
    fetch third into third_tuple;

    -- Tant que tout les tuples n'ont pas �t� tra�t�s
    while third%found loop

      -- traitement suivant le type de mise � jour
      -- cr�ation
      if third_tuple.update_mode = '0' then

          Null;

      -- modification
      elsif third_tuple.update_mode = '1' then

          Null;

      -- supression
      elsif third_tuple.update_mode = '9' then

          Null;

      end if;

      fetch third into third_tuple;

    end loop;

    --fermeture du curseur
    close third;

  end Ctrl_Thirds;


  /**
  * Description
  *    pour un fichier d'int�gration, contr�le des donn�es "PAC_CUSTOM_PARTNER"
  */
  procedure Ctrl_Customers(conversion_id in number, control_flag IN OUT number)
  is
    cursor customer(conversion_id number) is
      select * from v_aci_ascii_customer
        where aci_conversion_id = conversion_id
          and c_ascii_fail_reason is null;
    customer_tuple customer%rowtype;
    sub_set ACS_SUB_SET.C_SUB_SET%type;
    vPersonId PAC_PERSON.PAC_PERSON_ID%type;
  begin

    -- ouverture du curseur
    open customer(conversion_id);
    fetch customer into customer_tuple;

    -- Tant que tout les tuples n'ont pas �t� tra�t�s
    while customer%found loop

      -- traitement suivant le type de mise � jour
      -- supression
      if customer_tuple.update_mode = '9' then
        Null;
      -- modification
      elsif customer_tuple.update_mode = '1' then
        Null;
      -- cr�ation
      else
        if customer_tuple.acs_sub_set_id is not null then
        -- mauvais sub_set
          select MAX(C_SUB_SET) into sub_set
          from ACS_SUB_SET
          where ACS_SUB_SET_ID = customer_tuple.acs_sub_set_id
            and C_SUB_SET = 'REC';
        end if;

        if customer_tuple.acs_sub_set_id is not null and sub_set is null then
          update aci_conversion_source set c_ascii_fail_reason = '590'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif customer_tuple.pac_payment_condition_id is null then
        -- condition de paiement erron�e
          update aci_conversion_source set c_ascii_fail_reason = '510'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif customer_tuple.c_remainder_launching is null then
        -- C_REMAINDER_LAUNCHING manquant
          update aci_conversion_source set c_ascii_fail_reason = '520'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif not customer_tuple.c_remainder_launching in ('AUTO','MAN','NONE') then
        -- C_REMAINDER_LAUNCHING mauvais
          update aci_conversion_source set c_ascii_fail_reason = '521'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif customer_tuple.acs_vat_det_account_id is null then
        -- D�compte TVA manquant manquant
          update aci_conversion_source set c_ascii_fail_reason = '530'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif customer_tuple.c_partner_category is null then
        -- C_PARTNER_CATEGORY manquant
          update aci_conversion_source set c_ascii_fail_reason = '540'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif not customer_tuple.c_partner_category in ('1','2','3','4') then
        -- C_PARTNER_CATEGORY mauvais
          update aci_conversion_source set c_ascii_fail_reason = '541'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif customer_tuple.c_type_edi is null then
        -- C_TYPE_EDI manquant
          update aci_conversion_source set c_ascii_fail_reason = '550'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif not customer_tuple.c_type_edi in ('0','1') then
        -- C_TYPE_EDI mauvais
          update aci_conversion_source set c_ascii_fail_reason = '551'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif customer_tuple.c_partner_status is null then
        -- C_PARTNER_STATUS manquant
          update aci_conversion_source set c_ascii_fail_reason = '560'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif not customer_tuple.c_partner_status in ('0','1','2') then
        -- C_PARTNER_STATUS mauvais
          update aci_conversion_source set c_ascii_fail_reason = '561'
          where aci_conversion_source_id = customer_tuple.aci_conversion_source_id;
          control_flag := 0;
        end if;
      end if;
      fetch customer into customer_tuple;
    end loop;
    --fermeture du curseur
    close customer;

  end Ctrl_Customers;


  /**
  * Description
  *    pour un fichier d'int�gration, contr�le des donn�es "PAC_SUPPLIER_PARTNER"
  */
  procedure Ctrl_Suppliers(conversion_id in number, control_flag IN OUT number)
  is
    cursor supplier(conversion_id number) is
      select * from v_aci_ascii_supplier
        where aci_conversion_id = conversion_id
          and c_ascii_fail_reason is null;
    supplier_tuple supplier%rowtype;
    sub_set ACS_SUB_SET.C_SUB_SET%type;
    vPersonId PAC_PERSON.PAC_PERSON_ID%type;
  begin

    -- ouverture du curseur
    open supplier(conversion_id);
    fetch supplier into supplier_tuple;

    -- Tant que tout les tuples n'ont pas �t� tra�t�s
    while supplier%found loop
      -- traitement suivant le type de mise � jour
      if supplier_tuple.update_mode = '9' then
        Null;
      -- modification
      elsif supplier_tuple.update_mode = '1' then
        Null;
      -- cr�ation
      else
        if supplier_tuple.acs_sub_set_id is not null then
        -- mauvais sub_set
          select MAX(C_SUB_SET) into sub_set
          from ACS_SUB_SET
          where ACS_SUB_SET_ID = supplier_tuple.acs_sub_set_id
            and C_SUB_SET = 'PAY';
        end if;

        if supplier_tuple.acs_sub_set_id is not null and sub_set is null then
          update aci_conversion_source set c_ascii_fail_reason = '690'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif supplier_tuple.pac_payment_condition_id is null then
        -- condition de paiement erron�e
          update aci_conversion_source set c_ascii_fail_reason = '610'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif supplier_tuple.c_remainder_launching is null then
        -- C_REMAINDER_LAUNCHING manquant
          update aci_conversion_source set c_ascii_fail_reason = '620'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif not supplier_tuple.c_remainder_launching in ('AUTO','MAN','NONE') then
        -- C_REMAINDER_LAUNCHING mauvais
          update aci_conversion_source set c_ascii_fail_reason = '621'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif supplier_tuple.acs_vat_det_account_id is null then
        -- D�compte TVA manquant manquant
          update aci_conversion_source set c_ascii_fail_reason = '630'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif supplier_tuple.c_partner_category is null then
        -- C_PARTNER_CATEGORY manquant
          update aci_conversion_source set c_ascii_fail_reason = '640'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif not supplier_tuple.c_partner_category in ('1','2','3','4') then
        -- C_PARTNER_CATEGORY mauvais
          update aci_conversion_source set c_ascii_fail_reason = '641'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif supplier_tuple.c_type_edi is null then
        -- C_TYPE_EDI manquant
          update aci_conversion_source set c_ascii_fail_reason = '650'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif not supplier_tuple.c_type_edi in ('0','1') then
        -- C_TYPE_EDI mauvais
          update aci_conversion_source set c_ascii_fail_reason = '651'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif supplier_tuple.c_partner_status is null then
        -- C_PARTNER_STATUS manquant
          update aci_conversion_source set c_ascii_fail_reason = '660'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        elsif not supplier_tuple.c_partner_status in ('0','1','2') then
        -- C_PARTNER_STATUS mauvais
          update aci_conversion_source set c_ascii_fail_reason = '661'
          where aci_conversion_source_id = supplier_tuple.aci_conversion_source_id;
          control_flag := 0;
        end if;
      end if;
      fetch supplier into supplier_tuple;
    end loop;

    --fermeture du curseur
    close supplier;

  end Ctrl_Suppliers;


  /**
  * Description
  *    pour un fichier d'int�gration, contr�le des donn�es "PAC_FINANCIAL_REFERENCE"
  */
  procedure Ctrl_References(conversion_id in number, control_flag IN OUT number)
  is
    cursor reference(conversion_id number) is
      select * from v_aci_ascii_fin_reference
        where aci_conversion_id = conversion_id
          and c_ascii_fail_reason is null;
    reference_tuple reference%rowtype;
  begin

    -- ouverture du curseur
    open reference(conversion_id);
    fetch reference into reference_tuple;

    -- Tant que tout les tuples n'ont pas �t� tra�t�s
    while reference%found loop

      if reference_tuple.fre_default is null then
        -- Reference financi�re : flag par d�faut non d�fini
        update aci_conversion_source set c_ascii_fail_reason = '710'
          where aci_conversion_source_id = reference_tuple.aci_conversion_source_id;
        control_flag := 0;
      else

        -- traitement suivant le type de mise � jour
        -- cr�ation
        if reference_tuple.update_mode = '0' then

          Null;

        -- modification
        elsif reference_tuple.update_mode = '1' then

          Null;

        -- supression
        elsif reference_tuple.update_mode = '9' then

          Null;

        end if;

      end if;

      fetch reference into reference_tuple;

    end loop;

    --fermeture du curseur
    close reference;

  end Ctrl_References;

end ACI_ASCII_CTRL_PERSON;
