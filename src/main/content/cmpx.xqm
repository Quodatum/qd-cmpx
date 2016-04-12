(:~
 : Component library tools
 : Install this in the BaseX respository
 : @since April 2015  
 : @author Andy Bunce
 : @copyright Quodatum Ltd  
 :)
module namespace  cmpx = 'quodatum.cmpx';

declare namespace pkg="http://expath.org/ns/pkg";
declare namespace comp="urn:quodatum:qd-cmpx:component";
declare variable $cmpx:_ver:="0.4.1";

(:~ the database..
 : <components xmlns="urn:quodatum:qd-cmpx:component" version="1.0">
 :	<cmp name="angular-tree-control">
 :		...
 :		<release version="0.2.0">
 :
 : Package format:
 : <package abbrev="doc" name="urn:quodatum.basex.doc" version="0.5.11"
 :	spec="1.0" xmlns="http://expath.org/ns/pkg">
 :	<title>Web app Documentation</title>
 :	<dependency name="twitter-bootstrap-css" version="3.3.4" />
 :)		
declare variable $cmpx:comps as element(comp:cmp)* :=fn:doc("components.xml")/comp:components/comp:cmp;

(:~ web path :)
declare %private variable $cmpx:webpath:=db:system()/globaloptions/webpath  || file:dir-separator();

(:~ location of static lib :)
declare variable $cmpx:libpath:=$cmpx:webpath  || "static/lib" ;

(:~
 : @return expath-pkg doc for app $name
 :)
declare function cmpx:expath-pkg($name as xs:string){
	let $f:=  file:resolve-path($name ||"/expath-pkg.xml",$cmpx:webpath)
	return fn:doc($f)
};

(:~
 : @return expath-pkg doc for app $name
 :)
declare function cmpx:app-dependants($name as xs:string) 
as element(pkg:dependency)*{
    let $f:=  file:resolve-path($name ||"/expath-pkg.xml",$cmpx:webpath)
    return fn:doc($f)/*/pkg:dependency
};
(:~
 : anotate a pkg:dependency with info about availability 
 : adds a @status attribute
 :) 
declare function cmpx:status($cmp as element(pkg:dependency)) as element(pkg:dependency)
{
let $c:=cmpx:find($cmp/@name)
let $releases:=$c/comp:release[@version=$cmp/@version]
let $value:=if(fn:empty($c)) 
        then "missing"
        else if($releases) 
             then  "ok"
             else  "noversion"
return copy $res := $cmp
modify  (insert  node attribute status {$value} into $res,
                insert node attribute offline {fn:boolean($releases/comp:location[@offline])} into $res)
return $res
};

(:~ 
 : @param $app name of app
 : @return map of dependant resources
 :)
declare function cmpx:app($app as xs:string,$opts as map(*)){
let $pkg:=cmpx:expath-pkg($app)
let $c:= $pkg//pkg:dependency!cmpx:find(@name)
let $c2:=$c=>cmpx:closure()
let   $s:=  cmpx:topologic-sort($c2)
let $base:="/" || $app || "/"
return map:merge((		
			map{  "name":$app,
						"version":$pkg/pkg:package/@version/fn:string(),
  					  "static":"/static" || $base,
  					  "base":$base
					},
      	cmpx:includes($s,$opts)    
  		))
};

(:~
 : generate includes required for components
 :)
declare function cmpx:includes($cmps as element(comp:cmp)*,$opts as map(*)) as map(*)
{
let $opts:=map:merge((map{"offline":fn:false()},$opts))
let $offline:=$opts?offline

let $css:=$cmps!(fn:head(comp:release/comp:location[if($offline)then @offline else fn:true()])/*[@type="css"])
let $js:=$cmps!(fn:head(comp:release/comp:location[if($offline)then @offline else fn:true()])/*[@type="js"])
return map{
	"css":$css!cmpx:css(.),
	"js":$js!cmpx:js(.)
}
};

declare function cmpx:css($e as element()) 
as element(link)?
{
 <link href="{$e/../@base || $e}" rel="stylesheet" type="text/css"/>
};

declare function cmpx:js($e as element())
 as element(script)
{
 <script src="{$e/../@base || $e}"/>
};

(:~ sequence of all referenced uris 
  : @param $port http port 
 :)
declare function cmpx:app-resolve($includes as element(include),$port)
{
	let $uri:=($includes/js/script/@src,$includes/css/link/@href)
	return $uri!cmpx:full-uri(.,$port)
};
(:~ referenced uri for default port :)
declare function cmpx:app-resolve($includes as element(include))
{
	cmpx:app-resolve($includes,"8984")
};

(:~ full uri from component path :)
declare function cmpx:full-uri($uri,$port) as xs:string{
	if(fn:starts-with($uri,"//"))then "http:" ||$uri
	else if(fn:starts-with($uri,"/"))then "http://localhost:" || $port || $uri
	else $uri
};

declare function cmpx:find($name as xs:string) as element(comp:cmp)?
{
  $cmpx:comps[@name=$name]
};

declare function cmpx:dependants($name as xs:string) as element(comp:cmp)*
{
  let $c:=cmpx:find($name)
  let $d:=$c/comp:depends!cmpx:find(.)
  return ($d)
};

(:~ names of components :)
declare function cmpx:names($cmps as element(comp:cmp)*) as xs:string*
{
  $cmps/@name
};


(:~ 
 : topologic sort 
 :)
declare function cmpx:topologic-sort($unordered)   {
  cmpx:topologic-sort($unordered,())
};

declare function cmpx:topologic-sort($unordered, $ordered )   {
    if (fn:empty($unordered))
    then $ordered
    else
        let $nodes := $unordered [ every $id in comp:depends satisfies $id = $ordered/@name]
		(: let $_:=fn:trace(fn:count($unordered),"LEFT") :)
        return 
          if ($nodes)
          then cmpx:topologic-sort( $unordered except $nodes, ($ordered, $nodes ))
          else ()  (: cycles so no order possible :)
};

(:~
 : extend component list by recursively adding dependants  
 :)
declare function cmpx:closure($cmps as element(comp:cmp)*) as element(comp:cmp)*
{ 
 cmpx:closure($cmps,())
};

declare function cmpx:closure($new as element(comp:cmp)*,$current as element(comp:cmp)*)
as element(comp:cmp)*
{
let $n:=$new except $current
return if (fn:empty($n)) 
       then $current
       else let $x:=$n/comp:depends!cmpx:find(.)
	        return cmpx:closure($x,($current,$n)) 
};

(:~ save files for release to local static library :)
declare %updating function cmpx:save-offline($location as element(comp:location))
{
let $target:=function($name){fn:string-join(
($cmpx:libpath,$location/ancestor::comp:cmp/@name,$location/ancestor::comp/release/@version,$name),file:dir-separator()
)}
return (
	if(fn:not(file:is-dir($target("")))) then file:create-dir($target("")) else (),
	for $f in $location/*
	let $name:=fn:tokenize($f,"/")[fn:last()]
	let $t:=fetch:binary(cmpx:full-uri($f,"80"))
	return file:write-binary($target($name),$t)
)
};

