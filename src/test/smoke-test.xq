(:~  
 : simple cmpx usage 
:)
import module namespace cmpx = "quodatum.cmpx" at "../main/content/cmpx.xqm";
declare namespace pkg="http://expath.org/ns/pkg";
declare variable $cmpx:src:="C:\Users\andy\workspace\app-doc\src\doc\expath-pkg.xml";

"quodatum-directives"
!cmpx:find(.)
!(.,cmpx:closure(.)/@name)

(:,doc( $cmpx:src)/pkg:package/pkg:dependency :)