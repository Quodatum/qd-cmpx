(: find status for dependancies in package.json :)
import module namespace  cmpx = 'quodatum.cmpx';
declare namespace comp="urn:quodatum:qd-cmpx:component";
declare variable $src:="C:\Users\andy\git\vue-poc\src\vue-poc\package.json";
let $file := file:read-text($src)
let $json := json:parse($file,map { 'format': 'xquery' })
let $deps:= $json?dependencies=>map:for-each(function($k,$v){map{"name":$k,"version":$v}})
return  $deps!cmpx:status-enrich(.,cmpx:comps())=>filter(function($a){empty($a?found)})