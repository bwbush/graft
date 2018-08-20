{
  mkDerivation, base, containers, heaps, raft, stringbuilder, stdenv,
  cabal-install, ghcid, hasktags, hdevtools, hlint, pointfree, pointful, threadscope
}:
mkDerivation {
  pname = "graft";
  version = "0.2.0.0";
  src = ./.;
  buildDepends = [ cabal-install ghcid hasktags hdevtools hlint pointfree pointful threadscope];
  libraryHaskellDepends = [ base containers heaps raft stringbuilder ];
  homepage = "https://bitbucket.org/functionally/graft";
  description = "Graph algorithms";
  license = stdenv.lib.licenses.mit;
}
