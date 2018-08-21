{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies     #-}


module Data.Graph.ShortestPath (
  shortestPathTree
, shortestPath
, TaggedGraph
) where


import Control.Arrow (first)
import Data.Foldable (toList)
import Data.Graph.Types (Graph(..), MutableGraph(..), Path)
import Data.Graph.Types.MapGraph (MapGraph)
import Data.Graph.Types.Util (Halt, Measure, Tagged(..))
import Data.Maybe (catMaybes, fromJust)
import Data.Monoid ((<>))
import Data.Heap (Heap)

import qualified Data.Heap as H (Entry(..), insert, null, singleton, uncons)
import qualified Data.Set as S (findMin, lookupLE, member, notMember)


type TaggedGraph v e t = MapGraph (Tagged v t) e


shortestPath :: (Graph g, v ~ VertexLabel g, e ~ EdgeLabel g)
             => (Ord v, Ord e, Ord w, Monoid w)
             => Measure c e w
             -> g
             -> c
             -> v
             -> v
             -> (Path (MapGraph v e), c)
shortestPath measure graph context start finish =
  let
    tree = shortestPathTree measure (const $ const . (== finish)) graph context start
    f [] = []
    f path@((to, _, _) : _) =
      let
        ((_, Tagged from _), edge) = S.findMin $ edgesTo tree (Tagged to undefined)
        path' = (from, to, edge) : path
      in
        if from == start
          then path'
          else f path'
    finish' = Tagged finish undefined
  in
    if finish' `S.member` vertices tree
      then (init $ f [(finish, undefined, undefined)], snd . tag . fromJust $ finish' `S.lookupLE` vertices tree)
      else ([], context)


shortestPathTree :: (Graph g, v ~ VertexLabel g, e ~ EdgeLabel g)
                 => (Ord v, Ord e, Ord w, Monoid w)
                 => Measure c e w
                 -> Halt c v w
                 -> g
                 -> c
                 -> v
                 -> TaggedGraph v e (w, c)
shortestPathTree measure halt graph context start =
  let
    tree = mempty
    fringe = H.singleton . H.Entry mempty $ Tagged (fromJust $ vertexLabeled graph start) (mempty, context, id)
  in
    shortestPathTree' measure halt graph fringe tree


shortestPathTree' :: (Graph g, v' ~ Vertex g, v ~ VertexLabel g, e ~ EdgeLabel g)
                  => (Ord v, Ord e, Ord w, Monoid w)
                  => Measure c e w
                  -> Halt c v w
                  -> g
                  -> Heap (H.Entry w (Tagged v' (w, c, TaggedGraph v e (w, c) -> TaggedGraph v e (w, c))))
                  -> TaggedGraph v e (w, c)
                  -> TaggedGraph v e (w, c)
shortestPathTree' measure halt graph fringe tree
  | H.null fringe = tree
  | otherwise     =
      let
        Just (H.Entry distance (Tagged from (_, context, append)), fringe'') = H.uncons fringe
        from' = vertexLabel graph from
        tree' = append tree
        fringe' = 
          foldr H.insert
            fringe''
            $ catMaybes
            [
              do
                (distance', context') <- first (distance <>) <$> measure context edge'
                return
                  . H.Entry distance'
                  $ Tagged to
                  (
                    distance'
                  , context'
                  , addEdge (Tagged from' (distance, context)) (Tagged to' (distance', context')) edge'
                  )
            |
              edge <- toList $ edgesFrom graph from
            , let edge' = edgeLabel graph edge
                  to = vertexTo graph edge
                  to' = vertexLabel graph to
            , Tagged to' undefined `S.notMember` vertices tree
            ]
      in
        case (Tagged from' undefined `S.member` vertices tree, halt context from' distance) of
          (True, _   ) -> shortestPathTree' measure halt graph fringe'' tree 
          (_   , True) -> tree'
          _            -> shortestPathTree' measure halt graph fringe'  tree'