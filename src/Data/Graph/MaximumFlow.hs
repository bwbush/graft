{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies     #-}


module Data.Graph.MaximumFlow (
  maximumFlow
, minimumCostFlow
) where


import Data.Graph.Types (Graph(..))
import Data.Graph.Types.Weight (CostFlow(CostFlow), Flow(..), Flows, Measure)
import Data.Monoid.Zero (zero)
import Debug.Trace (trace)

import qualified Data.Graph.MaximumFlow.Contextual as C (maximumFlow)
import qualified Data.Map.Strict as M ((!), empty, insert)


trace' :: (a -> String) -> a -> a
trace' = if True then (trace =<<) else const id


maximumFlow :: (Show v, Show e, Show w)
            => (Graph g, v ~ VertexLabel g, e ~ EdgeLabel g)
            => (Ord v, Ord e, Ord w, RealFloat w, Num w)
            => Measure e w
            -> g
            -> v
            -> v
            -> Flows e w
maximumFlow measure graph start finish =
  let
    measure' context edge =
      let
         flow = context M.! edge
      in
        (
          (
            Flow $ measure edge - flow
          , Flow flow
          )
        , context
        )
    set' forward flow context edge =
      let
        previous = context M.! edge
      in
        M.insert
          edge
          (
            if forward
              then previous + unFlow flow
              else previous - unFlow flow
          )
          context
  in
    C.maximumFlow
      measure'
      set'
      graph
      (foldr (`M.insert` 0) M.empty $ edgeLabels graph)
      start
      finish


minimumCostFlow :: (Show v, Show e, Show c, Show w)
                => (Graph g, v ~ VertexLabel g, e ~ EdgeLabel g)
                => (Ord v, Ord e, Ord c, RealFloat c, Num c, Ord w, RealFloat w, Num w)
                => Measure e (c, w)
                -> g
                -> v
                -> v
                -> Flows e w
minimumCostFlow measure graph start finish =
  let
    measure' context edge =
      let
         flow = context M.! edge
         (cost, capacity) = measure edge
      in
        (
          (
            if flow < capacity then CostFlow    cost  $ capacity - flow else zero 
          , if flow > 0        then CostFlow (- cost)              flow else zero
          )
        , context
        )
    set' forward (CostFlow _ flow) context edge =
      let
        previous = context M.! edge
      in
        M.insert
          edge
          (
            if forward
              then previous + flow
              else previous - flow
          )
          context
  in
    C.maximumFlow
        measure'
        set'
        graph
        (trace' (const $ unlines ["VERTICES\t" ++ show (vertexLabels graph), "EDGES\t" ++ show (edgeLabels graph)]) $ foldr (`M.insert` 0) M.empty $ edgeLabels graph)
        start
        finish
