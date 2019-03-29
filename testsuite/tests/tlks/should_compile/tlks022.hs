{-# LANGUAGE TopLevelKindSignatures #-}
{-# LANGUAGE ScopedTypeVariables, PolyKinds, ExplicitForAll #-}

module TLKS_022 where

import Data.Kind (Type)

data P w

-- j = k, x = a
type T :: forall k. forall (a :: k) -> Type
data T (x :: j) = MkT (P k) (P j) (P x)
