{-# LANGUAGE TupleSections    #-}
{-# LANGUAGE TypeFamilies     #-}


module Data.Graph.ShortestPath (
  shortestPathTree
, shortestPath
, measurePath
, TaggedGraph
) where


import Data.Graph.Types (Graph(..), Path)
import Data.Graph.Types.MapGraph (mapVertices)
import Data.Graph.Types.Util (Halt, Measure, MeasureC, Tagged(..), TaggedGraph)

import qualified Data.Graph.ShortestPath.Contextual as C (measurePath, shortestPath, shortestPathTree)


strip :: Measure e w -> MeasureC () e w
strip = const . (fmap (, ()) .)


measurePath :: Monoid w
            => Measure e w
            -> Path v e
            -> Maybe w
measurePath measure = fmap fst . C.measurePath (strip measure) ()


shortestPath :: (Graph g, v ~ VertexLabel g, e ~ EdgeLabel g)
             => (Ord v, Ord e, Ord w, Monoid w)
             => Measure e w
             -> g
             -> v
             -> v
             -> Path v e
shortestPath measure graph = (fst .) . C.shortestPath (strip measure) graph ()


shortestPathTree :: (Graph g, v ~ VertexLabel g, e ~ EdgeLabel g)
                 => (Ord v, Ord e, Ord w, Monoid w)
                 => Measure e w
                 -> Halt v w
                 -> g
                 -> v
                 -> TaggedGraph v e w
shortestPathTree measure halt graph =
  mapVertices (\(Tagged vertex (weight, ())) -> Tagged vertex weight)
    . C.shortestPathTree (strip measure) (const halt) graph ()
