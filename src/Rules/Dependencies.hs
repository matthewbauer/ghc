module Rules.Dependencies (buildPackageDependencies) where

import Expression
import GHC
import Oracles
import Rules.Actions
import Rules.Resources
import Settings

buildPackageDependencies :: Resources -> PartialTarget -> Rules ()
buildPackageDependencies _ target @ (PartialTarget stage pkg) =
    let path      = targetPath stage pkg
        buildPath = path -/- "build"
        dropBuild = (pkgPath pkg ++) . drop (length buildPath)
        hDepFile  = buildPath -/- ".hs-dependencies"
        platformH = targetPath stage compiler -/- "ghc_boot_platform.h"
    in do
        (buildPath <//> "*.c.deps") %> \out -> do
            let srcFile = dropBuild . dropExtension $ out
            when (pkg == compiler) $ need [platformH]
            need [srcFile]
            build $ fullTarget target (GccM stage) [srcFile] [out]

        hDepFile %> \file -> do
            srcs <- interpretPartial target getPackageSources
            when (pkg == compiler) $ need [platformH]
            need srcs
            if srcs == []
            then writeFileChanged file ""
            else build $ fullTarget target (GhcM stage) srcs [file]
            removeFileIfExists $ file <.> "bak"

        (buildPath -/- ".dependencies") %> \file -> do
            cSrcs <- pkgDataList $ CSrcs path
            let cDepFiles = [ buildPath -/- src <.> "deps" | src <- cSrcs ]
            need $ hDepFile : cDepFiles -- need all for more parallelism
            cDeps <- fmap concat $ mapM readFile' cDepFiles
            hDeps <- readFile' hDepFile
            -- TODO: very ugly and fragile; use gcc -MM instead?
            let hsIncl hs incl = buildPath -/- hs <.> "o" ++ " : "
                              ++ buildPath -/- incl ++ "\n"
                extraDeps = if pkg /= compiler then [] else
                       hsIncl "PrelNames" "primop-vector-uniques.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-data-decl.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-tag.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-list.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-strictness.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-fixity.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-primop-info.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-out-of-line.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-has-side-effects.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-can-fail.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-code-size.hs-incl"
                    ++ hsIncl "PrimOp"    "primop-commutable.hs-incl"
                    ++ hsIncl "TysPrim"   "primop-vector-tys-exports.hs-incl"
                    ++ hsIncl "TysPrim"   "primop-vector-tycons.hs-incl"
                    ++ hsIncl "TysPrim"   "primop-vector-tys.hs-incl"
            writeFileChanged file $ cDeps ++ hDeps ++ extraDeps
