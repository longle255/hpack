{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE LambdaCase #-}
module Hpack.Yaml (
-- | /__NOTE:__/ This module is exposed to allow integration of Hpack into
-- other tools.  It is not meant for general use by end users.  The following
-- caveats apply:
--
-- * The API is undocumented, consult the source instead.
--
-- * The exposed types and functions primarily serve Hpack's own needs, not
-- that of a public API.  Breaking changes can happen as Hpack evolves.
--
-- As an Hpack user you either want to use the @hpack@ executable or a build
-- tool that supports Hpack (e.g. @stack@ or @cabal2nix@).

  decodeYaml
, module Data.Aeson.Config.FromValue
) where

import           Data.Bifunctor
import           Data.Yaml hiding (decodeFile, decodeFileWithWarnings)
import           Data.Yaml.Include
import qualified Data.Yaml.Internal as Yaml
import           Data.Aeson.Config.FromValue
import           Data.Aeson.Config.Parser (fromAesonPath, formatPath)

formatWarning :: FilePath -> Yaml.Warning -> String
formatWarning file = \ case
  Yaml.DuplicateKey path -> file ++ ": Duplicate field " ++ formatPath (fromAesonPath path)

decodeYaml :: FilePath -> IO (Either String ([String], Value))
decodeYaml file = do
  result <- decodeFileWithWarnings file
  return $ either (Left . errToString) (Right . first (map $ formatWarning file)) result
  where
    errToString err = file ++ case err of
      AesonException e -> ": " ++ e
      InvalidYaml (Just (YamlException s)) -> ": " ++ s
      InvalidYaml (Just (YamlParseException{..})) -> ":" ++ show yamlLine ++ ":" ++ show yamlColumn ++ ": " ++ yamlProblem ++ " " ++ yamlContext
        where YamlMark{..} = yamlProblemMark
      _ -> ": " ++ show err
