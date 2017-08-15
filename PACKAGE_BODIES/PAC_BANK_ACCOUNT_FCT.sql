--------------------------------------------------------
--  DDL for Package Body PAC_BANK_ACCOUNT_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_BANK_ACCOUNT_FCT" 
is
	function IsSwissPostIBAN(aAccount in PAC_FINANCIAL_REFERENCE.FRE_ACCOUNT_NUMBER%Type)
	 	return number DETERMINISTIC
	is
	begin
		if substr(aAccount, 1, 2) = 'CH' and
				substr(aAccount, 5, 5) = '09000' then
			return 1;
		else
			return 0;
		end if;
	end IsSwissPostIBAN;

end PAC_BANK_ACCOUNT_FCT;
