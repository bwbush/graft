module Data.Graph.Types.Util (
  Tagged(..)
, HyperVertex(..)
, HyperEdge(..)
) where


data Tagged a b =
  Tagged
  {
    item :: a
  , tag  :: b
  }
    deriving (Read, Show)

instance Eq a => Eq (Tagged a b) where
  Tagged x _ == Tagged y _ = x == y

instance Ord a => Ord (Tagged a b) where
  Tagged x _ `compare` Tagged y _ = x `compare` y


data HyperVertex a =
    HyperSource
  | HyperSink
  | HyperVertex a
    deriving (Eq, Ord, Read, Show)


data HyperEdge a =
    ForwardEdge a
  | ReversedEdge a
    deriving (Eq, Ord, Read, Show)
