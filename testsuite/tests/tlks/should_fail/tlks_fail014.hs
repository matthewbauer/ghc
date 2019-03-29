{-# LANGUAGE TopLevelKindSignatures #-}
{-# LANGUAGE TypeFamilies, PolyKinds, ExplicitForAll #-}

module TLKS_014 where

import Data.Kind (Type)

type T :: forall k. k
type family T :: forall j. j where
  T = Maybe
  T = Integer
