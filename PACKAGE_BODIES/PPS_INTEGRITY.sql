--------------------------------------------------------
--  DDL for Package Body PPS_INTEGRITY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_INTEGRITY" 
is
  gttPpsp ttPpsPath;   -- Table mémoire de résultat
  gttPpst ttPpsTest := ttPpsTest();   -- Table mémoire de test

  procedure ResetNom
  is
  begin
    gttPpsp.delete;   -- Table mémoire de résultat
  end ResetNom;

  procedure ResetGlobal
  is
  begin
    delete from PPS_PATH;

    gttPpst  := ttPpsTest();   -- Table mémoire de test
    ResetNom;
  end ResetGlobal;

--Procédure de test. Est appelée depuis les procédures différentes selon
--genre de sélection.
  procedure DoTest(iGoodId in number)
--***********************************
  is
    lIdx     binary_integer;   -- Tampon passé index
    i        binary_integer;   -- Tampon index ajout dans table
    lIsError boolean;   -- Est-ce qu'il y a une erreur dans la nomenclature du bien testé
    lIdxTest binary_integer;   -- Index de la table mémoire
  begin
    lIdx      := 0;   --Init de i à 0
    lIdxTest  := 0;   --On commence à 0
    --Test le bien en cours
    lIsError  := PPS_INTEGRITY.TestNomenclature(iGoodId, 1, 0, '', gttPpsp, gttPpst, lIdx, lIdxTest);

    if lIsError then
      --Il y a des erreurs, copier la table mémoire dans la vraie table
      for i in reverse gttPpsp.first .. gttPpsp.last loop
        --Contrôle de l'existence de l'élement dans la table mémoire, puisqu'il peut y avoir des 'trous'
        insert into PPS_PATH
                    (PPS_PATH_ID
                   , GCO_GOOD_ID
                   , PAT_LEVEL
                   , PAT_STATUS
                   , PPS_NOMENCLATURE_ID
                   , PAT_GOOD_REFERENCE
                   , PAT_NOM_TYPE
                   , PAT_NOM_VERSION
                   , PAT_NOM_DEFAULT
                   , PAT_COM_SEQ
                   , PAT_HAS_PROBLEM
                    )
             values   --Les valeurs sont reprises de la table mémoire
                    (Init_Id_Seq.nextval
                   , gttPpsp(i).GCO_GOOD_ID
                   , gttPpsp(i).PAT_LEVEL
                   , gttPpsp(i).PAT_STATUS
                   , gttPpsp(i).PPS_NOMENCLATURE_ID
                   , gttPpsp(i).PAT_GOOD_REFERENCE
                   , gttPpsp(i).PAT_NOM_TYPE
                   , gttPpsp(i).PAT_NOM_VERSION
                   , gttPpsp(i).PAT_NOM_DEFAULT
                   , gttPpsp(i).PAT_COM_SEQ
                   , gttPpsp(i).PAT_HAS_PROBLEM
                    );
      end loop;   --For i...
    end if;   --If lIsError...

    ResetNom;
  end;

--Procedure DoTest ***********************************************************************

  --Sélection de tous les biens et contrôle ****************************************************
  procedure Integrity_Nomenclature
  is
    a boolean;   -- Tampon de résultat
  begin
    ResetGlobal;

    --Tant qu'il y a des biens à contrôler....
    for ltplGood in (select   GCO_GOOD1.GCO_GOOD_ID
                         from GCO_GOOD GCO_GOOD1
                            , PPS_NOMENCLATURE P1
                        where GCO_GOOD1.GCO_GOOD_ID = P1.GCO_GOOD_ID
                     group by GCO_GOOD1.GCO_GOOD_ID) loop
      --Contrôle d'après GCO_GOOD_ID
      PPS_INTEGRITY.DoTest(ltplGood.GCO_GOOD_ID);
    end loop;
  end Integrity_Nomenclature;

-- **************************************************************

  --Sélection d'après date de modification et création ************************************************
  procedure Integrity_Nomenclature_Date(iTestDate in date)
  is
  begin
    ResetGlobal;

    --Tant qu'il y a des biens à contrôler....
    for ltplGood in (select   GCO_GOOD1.GCO_GOOD_ID
                         from GCO_GOOD GCO_GOOD1
                            , PPS_NOMENCLATURE P1
                            , PPS_NOM_BOND D1
                        where P1.GCO_GOOD_ID = GCO_GOOD1.GCO_GOOD_ID   --Lien de Nomenclature à bien
                          and D1.PPS_NOMENCLATURE_ID = P1.PPS_NOMENCLATURE_ID   --Lien de nomenclature à détail nomenclature
                          and (   D1.A_DATECRE >= iTestDate
                               or D1.A_DATEMOD >= iTestDate)   --Test des dates.
                     group by GCO_GOOD1.GCO_GOOD_ID
                     order by GCO_GOOD1.GCO_GOOD_ID) loop
      --Contrôle d'après GCO_GOOD_ID
      PPS_INTEGRITY.DoTest(ltplGood.GCO_GOOD_ID);
    end loop;   --While AllGood_Id%Found
  end Integrity_Nomenclature_Date;

--******************************************************

  --Sélection d'après la table PPS_LIST_GOOD et contrôle *******************************************
  procedure Integrity_Nomenclature_Good
  is
  begin
    ResetGlobal;

    --Tant qu'il y a des biens à contrôler....
    for ltplGood in (select GCO_GOOD_ID
                       from PPS_LIST_GOOD) loop
      --Contrôle d'après GCO_GOOD_ID
      PPS_INTEGRITY.DoTest(ltplGood.GCO_GOOD_ID);
    end loop;
  end Integrity_Nomenclature_Good;

  function TestNomenclature(
    iGoodId      in     number
  , iLevel       in     integer
  , iSequence    in     integer
  , iParentGoods in     varchar2
  , ittPpsPath   in out ttPpsPath
  , ittPpsTest   in out ttPpsTest
  , iIdx         in out binary_integer
  , iIdxTest     in out binary_integer
  )
    return boolean
  is
    lResult          boolean;   --Tampon résultat niveau courant
    lErrorUnder      boolean;   --Tampon résultat niveau en dessous
    lOffsetIndex     binary_integer := 3;   --Offest index pour le niveau suivant
    lLastAddedGoodId number(12)     := 0;   --Id du dernier bien ajouté dans la table temp
  begin
    --writelog('to test : '||iGoodId||'/'||FWK_I_LIB_ENTITY.getvarchar2fieldfrompk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iGoodId));
    lResult      := false;   --Init, on espère qu'il n'y a pas d'erreur à ce niveau
    lErrorUnder  := false;   --Init, on espère qu'il n'y a pas d'erreur plus bas

    --writelog('iParentGoods '|| iParentGoods);
    --Ouvre le curseur des nomenclatures
    for ltplNomenclature in (select   PPS_NOMENCLATURE1.*
                                    , GCO_GOOD1.GOO_MAJOR_REFERENCE
                                 from PPS_NOMENCLATURE PPS_NOMENCLATURE1
                                    , GCO_GOOD GCO_GOOD1
                                where PPS_NOMENCLATURE1.GCO_GOOD_ID = iGoodId
                                  and GCO_GOOD1.GCO_GOOD_ID = PPS_NOMENCLATURE1.GCO_GOOD_ID
                             order by PPS_NOMENCLATURE1.C_TYPE_NOM
                                    , PPS_NOMENCLATURE1.NOM_DEFAULT
                                    , PPS_NOMENCLATURE1.NOM_VERSION) loop
      if instr(iParentGoods, ',' || iGoodID || ',') > 0 then
        iIdx                                  := iIdx + 1;
        ittPpsPath(iIdx).PPS_PATH_ID          := 0;
        ittPpsPath(iIdx).GCO_GOOD_ID          := iGoodID;
        ittPpsPath(iIdx).PAT_LEVEL            := iLevel;
        ittPpsPath(iIdx).PAT_STATUS           := 1;
        ittPpsPath(iIdx).PPS_NOMENCLATURE_ID  := 0;
        ittPpsPath(iIdx).PAT_GOOD_REFERENCE   := ltplNomenclature.GOO_MAJOR_REFERENCE;
        ittPpsPath(iIdx).PAT_NOM_TYPE         := '';
        ittPpsPath(iIdx).PAT_NOM_VERSION      := '';
        ittPpsPath(iIdx).PAT_NOM_DEFAULT      := 0;
        ittPpsPath(iIdx).PAT_COM_SEQ          := iSequence;
        ittPpsPath(iIdx).PAT_HAS_PROBLEM      := 1;
        return true;
      end if;

      --Pour chaque nomenclature
      for ltplNomBonds in (select   PPS_NOM_BOND.*
                                  , GOO_MAJOR_REFERENCE
                               from PPS_NOM_BOND
                                  , GCO_GOOD
                              where PPS_NOM_BOND.GCO_GOOD_ID = GCO_GOOD.GCO_GOOD_ID
                                and PPS_NOMENCLATURE_ID = ltplNomenclature.PPS_NOMENCLATURE_ID
                           order by COM_SEQ) loop
        --Si il y a un bien lié... -> tester
        if not(ltplNomBonds.GCO_GOOD_ID is null) then
          ittPpsTest := ittPpsTest multiset union distinct ttPpsTest(ltplNomBonds.GCO_GOOD_ID);
          --en cours et au produit en cours au cas ou il faut les rajouter.
          --Ceci permet de n'ajouter que les erreurs, et pas d'ajouter puis d'enlever ce qui est juste.
          --writelog('TestNomenclature : '||iGoodId||'/'||ltplNomBonds.GCO_GOOD_ID||'/'||FWK_I_LIB_ENTITY.getvarchar2fieldfrompk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', ltplNomBonds.GCO_GOOD_ID));
          lErrorUnder  :=
            PPS_INTEGRITY.TestNomenclature(ltplNomBonds.GCO_GOOD_ID
                                         , iLevel + 1
                                         , ltplNomBonds.COM_SEQ
                                         , iParentGoods || ',' || iGoodId || ','
                                         , ittPpsPath
                                         , ittPpsTest
                                         , iIdx
                                         , iIdxTest
                                          );

          --Si il y a une erreur plus bas, ...
          if lErrorUnder then
            --Writelog('ErrorUnder : '||ltplNomBonds.GCO_GOOD_ID||'/'||FWK_I_LIB_ENTITY.getvarchar2fieldfrompk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', ltplNomBonds.GCO_GOOD_ID));
            --Ajouter la nomenclature ou il y a l'erreur
            iIdx                                  := iIdx + 1;
            ittPpsPath(iIdx).PPS_PATH_ID          := 0;
            ittPpsPath(iIdx).GCO_GOOD_ID          := 0;
            ittPpsPath(iIdx).PAT_LEVEL            := iLevel;
            ittPpsPath(iIdx).PAT_STATUS           := 0;
            ittPpsPath(iIdx).PPS_NOMENCLATURE_ID  := ltplNomenclature.PPS_NOMENCLATURE_ID;
            ittPpsPath(iIdx).PAT_GOOD_REFERENCE   := '';
            ittPpsPath(iIdx).PAT_NOM_TYPE         := ltplNomenclature.C_TYPE_NOM;
            ittPpsPath(iIdx).PAT_NOM_VERSION      := ltplNomenclature.NOM_VERSION;
            ittPpsPath(iIdx).PAT_NOM_DEFAULT      := ltplNomenclature.NOM_DEFAULT;
            ittPpsPath(iIdx).PAT_COM_SEQ          := 0;
            ittPpsPath(iIdx).PAT_HAS_PROBLEM      := 1;

            --Ajouter le produit courant puisque il a une erreur plus bas (sous lui)
            if iGoodId <> lLastAddedGoodId then
              lLastAddedGoodId                      := iGoodId;   --Se souvenir du dernier bien ajouté
              iIdx                                  := iIdx + 1;
              ittPpsPath(iIdx).PPS_PATH_ID          := 0;
              ittPpsPath(iIdx).GCO_GOOD_ID          := iGoodId;
              ittPpsPath(iIdx).PAT_LEVEL            := iLevel;
              ittPpsPath(iIdx).PAT_STATUS           := 0;
              ittPpsPath(iIdx).PPS_NOMENCLATURE_ID  := 0;
              ittPpsPath(iIdx).PAT_GOOD_REFERENCE   := ltplNomenclature.GOO_MAJOR_REFERENCE;
              ittPpsPath(iIdx).PAT_NOM_TYPE         := '';
              ittPpsPath(iIdx).PAT_NOM_VERSION      := '';
              ittPpsPath(iIdx).PAT_NOM_DEFAULT      := 0;
              ittPpsPath(iIdx).PAT_COM_SEQ          := iSequence;
              ittPpsPath(iIdx).PAT_HAS_PROBLEM      := 1;
            end if;

            --Reporter l'erreur plus haut
            return true;
          end if;
        end if;
      end loop;
    end loop;

    --on passe le résultat de ce qu'il y a plus bas et à ce niveau en dessus
    return lResult;
  end TestNomenclature;
end PPS_INTEGRITY;   --PACKAGE
