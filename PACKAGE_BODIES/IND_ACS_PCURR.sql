--------------------------------------------------------
--  DDL for Package Body IND_ACS_PCURR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IND_ACS_PCURR" 
is
 gUserIni varchar2(5) := nvl(pcs.pc_init_session.GetUserini,'AUTO');
 
 procedure load_cpy
 -- chargement de la table paramètre: sociétés 
 is
 
  cursor CurComp is
  select
  (select nvl(count(*),0)
   from ind_acs_pcurr_cpy_param c
   where a.pc_comp_id=c.pc_comp_id) CompExists,
  a.pc_comp_id,
  a.com_name,
  b.SCRDBOWNER
  from
  pcs.pc_comp a,
  pcs.pc_scrip b
  where
  a.pc_scrip_id=b.pc_scrip_id
  and a.pc_comp_id<>PCS.PC_INIT_SESSION.GETCOMPANYID;
  
 begin
 
  for RowComp In CurComp
  loop
  
   -- si la société n'esiste pas -> insert
   if RowComp.CompExists = 0
   then 
        insert into ind_acs_pcurr_cpy_param (EMC_ACTIVE,PC_COMP_ID,COM_NAME,SCRDBOWNER)
        values (0, RowComp.PC_COMP_ID,RowComp.COM_NAME,RowComp.SCRDBOWNER);
   else -- sinon update
        update ind_acs_pcurr_cpy_param
        set COM_NAME=RowComp.COM_NAME,
            SCRDBOWNER=RowComp.SCRDBOWNER
        where pc_comp_id=RowComp.pc_comp_id;
   end if;     
  
  end loop;
 
 end load_cpy;
 
 procedure copy_rate(vDate ACS_PRICE_CURRENCY.PCU_START_VALIDITY%type)
 -- transfert des cours dans les sociétés définies dans la table de paramètre
 is 
  cursor CurComp is
  select
  pc_comp_id,
  com_name,
  SCRDBOWNER
  from
  ind_acs_pcurr_cpy_param
  where
  nvl(emc_active,0)=1;
  
  cursor CurCurr is
  select
  PCU_START_VALIDITY,
  ACS_BETWEEN_CURR_ID,
  acs_function.GetCurrencyName(ACS_BETWEEN_CURR_ID) currency,
  PCU_BASE_PRICE,
  PCU_DAYLY_PRICE,
  PCU_VALUATION_PRICE,
  PCU_INVENTORY_PRICE,
  PCU_CLOSING_PRICE,
  PCU_INVOICE_PRICE,
  PCU_VAT_PRICE
  from 
  ACS_PRICE_CURRENCY
  where
  PCU_START_VALIDITY=vDate;
  
  NewHeaderId ind_acs_pcurr_header.ind_acs_pcurr_header_id%type;
  NewPosId ind_acs_pcurr_position.ind_acs_pcurr_position_id%type;
  FCurrId acs_financial_currency.acs_financial_currency_id%type;
  vCountPCurr number;
  BaseCurrName varchar2(5);
  vMsg varchar2(2000);
  MsgError varchar2(4000);
  
  sql_stmt1 varchar2(2000);
  sql_stmt2 varchar2(2000);
  sql_stmt3 varchar2(2000);
 begin
  -- recherche id table d'en-tête
  select nvl(max(ind_acs_pcurr_header_id),0)+1 into NewHeaderId
  from ind_acs_pcurr_header;
  
  -- insert de l'en-tête
  insert into ind_acs_pcurr_header 
  values (NewHeaderId, vDate, sysdate, gUserIni);
  
  vMsg:='';
  
  for RowComp in CurComp -- boucle Company
  loop
  
      for RowCurr in CurCurr -- boucle Currency
      loop
         -- recherche id table de position
        select init_id_seq.nextval into NewPosId
        from dual;
       
       -- insert du record de position
       insert into ind_acs_pcurr_position (IND_ACS_PCURR_POSITION_ID
                                          ,IND_ACS_PCURR_HEADER_ID
                                          ,CURRENCY
                                          ,PCU_BASE_PRICE
                                          ,PCU_DAYLY_PRICE
                                          ,PCU_VALUATION_PRICE
                                          ,PCU_INVENTORY_PRICE
                                          ,PCU_CLOSING_PRICE
                                          ,PCU_INVOICE_PRICE
                                          ,PCU_VAT_PRICE
                                          ,COM_NAME
                                          ,A_DATECRE
                                          ,A_IDCRE)
               values (NewPosId
                      ,NewHeaderId
                      ,RowCurr.CURRENCY
                      ,RowCurr.PCU_BASE_PRICE
                      ,RowCurr.PCU_DAYLY_PRICE
                      ,RowCurr.PCU_VALUATION_PRICE
                      ,RowCurr.PCU_INVENTORY_PRICE
                      ,RowCurr.PCU_CLOSING_PRICE
                      ,RowCurr.PCU_INVOICE_PRICE
                      ,RowCurr.PCU_VAT_PRICE
                      ,RowComp.COM_NAME
                      ,sysdate
                      ,gUserIni);
       
       -- recherche id de la monnaie dans la société de destination
       sql_stmt1 := 'update ind_acs_pcurr_position a
                    set FCURR_DESTINATION_ID = (select acs_financial_currency_id
                                                from '||RowComp.SCRDBOWNER||'.acs_financial_currency b, pcs.pc_curr c
                                                where b.pc_curr_id=c.pc_curr_id
                                                and c.currency=:1),
                        basecurr_destination_id = (select ACS_FINANCIAL_CURRENCY_ID
                                                  from '||RowComp.SCRDBOWNER||'.ACS_FINANCIAL_CURRENCY
                                                  where FIN_LOCAL_CURRENCY=1),
                        basecurr_destination_name = (select curr.currency
                                                  from '||RowComp.SCRDBOWNER||'.ACS_FINANCIAL_CURRENCY fcur, pcs.pc_curr curr
                                                  where fcur.pc_curr_id=curr.pc_curr_id
                                                  and fcur.FIN_LOCAL_CURRENCY=1)                         
                    where ind_acs_pcurr_position_id=:2' ;
       EXECUTE IMMEDIATE sql_stmt1 USING RowCurr.Currency, NewPosId ;
       
       select max(FCURR_DESTINATION_ID) into FCurrId
       from ind_acs_pcurr_position
       where ind_acs_pcurr_position_id=NewPosId;
       
          -- si la monnaie n'existe pas -> message d'erreur
          if FCurrId is null
           then vMsg:='La devise n''existe pas dans la société de destination';
                update ind_acs_pcurr_position
                set ERROR_MSG=vMsg
                where ind_acs_pcurr_position_id=NewPosId;
          end if;
      
      -- si la monnaie de base n'est pas la même dans la société source et société de destination -> message d'erreur    
      select max(basecurr_destination_name) into BaseCurrName
       from ind_acs_pcurr_position
       where ind_acs_pcurr_position_id=NewPosId;
       
          -- si la monnaie n'existe pas -> message d'erreur
          if BaseCurrName<>acs_function.GetLocalCurrencyName
           then vMsg:='La devise de base ('||acs_function.GetLocalCurrencyName||') diffère de la devise de base de la société de destination ('||BaseCurrName||')';
                update ind_acs_pcurr_position
                set ERROR_MSG=vMsg
                where ind_acs_pcurr_position_id=NewPosId;
          end if; 
        
        -- recherche s'il existe déjà un cours pour cette devise à cette date
        sql_stmt2 := 'update ind_acs_pcurr_position a
                    set RATE_DESTINATION_EXISTS = (select nvl(count(*),0)
                                                from '||RowComp.SCRDBOWNER||'.acs_price_currency b
                                                where b.PCU_START_VALIDITY=:1
                                                and b.ACS_BETWEEN_CURR_ID=a.FCURR_DESTINATION_ID)
                    where ind_acs_pcurr_position_id=:2' ;
       EXECUTE IMMEDIATE sql_stmt2 USING vDate,NewPosId ;
        
       select max(RATE_DESTINATION_EXISTS) into vCountPCurr
       from ind_acs_pcurr_position
       where ind_acs_pcurr_position_id=NewPosId;
        
          -- le cours existe déjà -> message d'erreur
          if vCountPCurr > 0
           then vMsg:='Un cours a déjà été saisi à cette date dans la société de destination';
                update ind_acs_pcurr_position
                set ERROR_MSG=vMsg
                where ind_acs_pcurr_position_id=NewPosId;
          end if;        
        
        -- insert du cours dans la société destination
        if vMsg='' or vMsg is null
        then sql_stmt3 := 'insert into '||RowComp.SCRDBOWNER||'.acs_price_currency a (ACS_PRICE_CURRENCY_ID,ACS_BETWEEN_CURR_ID,ACS_AND_CURR_ID,PCU_START_VALIDITY,PCU_BASE_PRICE,PCU_DAYLY_PRICE,PCU_VALUATION_PRICE,PCU_INVENTORY_PRICE,PCU_CLOSING_PRICE,PCU_INVOICE_PRICE,PCU_VAT_PRICE,A_DATECRE,A_IDCRE)
                          select init_id_seq.nextval,fcurr_destination_id,basecurr_destination_id,:1,PCU_BASE_PRICE,PCU_DAYLY_PRICE,PCU_VALUATION_PRICE,PCU_INVENTORY_PRICE,PCU_CLOSING_PRICE,PCU_INVOICE_PRICE,PCU_VAT_PRICE,sysdate,:2
                          from ind_acs_pcurr_position
                          where ind_acs_pcurr_position_id=:3' ;
             EXECUTE IMMEDIATE sql_stmt3 USING vDate, gUserIni, NewPosId ;
        end if;

       
      end loop; -- boucle Currency
  
  
  end loop; -- boucle Company
  
   Exception
   when others then
   MsgError:='Erreur non prévue - Message original :'||chr(10)||sqlerrm;
  
    update ind_acs_pcurr_position
    set ERROR_MSG=ERROR_MSG||MsgError
    where ind_acs_pcurr_position_id=NewPosId;
  
  
 end copy_rate;

end ind_acs_pcurr;
