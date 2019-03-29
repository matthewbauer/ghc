{-# LANGUAGE TopLevelKindSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE PolyKinds #-}

module TLKS_013 where

import Data.Kind (Type)

type T :: forall (k :: Type) -> Type
data T j = MkT (j -> k)
