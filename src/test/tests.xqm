(:~  cmpx unit tests :)
module namespace test = 'http://basex.org/modules/xqunit-tests';
import module namespace cmpx = "quodatum.cmpx" at "../main/content/cmpx.xqm";
declare namespace pkg="http://expath.org/ns/pkg"; 

   
(:~ return components. :)
declare %unit:test function test:comps() {
  unit:assert($cmpx:comps)
};

(:~ find a component by name. :)
declare %unit:test function test:find() {
  unit:assert("quodatum-directives"!cmpx:find(.))
}; 
  
(:~ find a closure on component by name. :)
declare %unit:test function test:closure() {
  unit:assert("quodatum-directives"!cmpx:find(.)!cmpx:closure(.))
};
 
(:~  app info map :)
declare %unit:test function test:app() {
  let $a:=cmpx:app("doc",map{})
  return unit:assert($a?css)
};
(:~  app info map :)
declare %unit:test function test:validate() {
  let $a:=cmpx:validate-info()
  return unit:assert-equals($a,"---")
};