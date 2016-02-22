(:~
 : Component library tools
 : Install this in the BaseX respository
 : @since April 2015  
 : @author Andy Bunce
 : @copyright Quodatum Ltd  
 :)
module namespace  cmpx = 'quodatum.cmpx';


declare namespace pkg="http://expath.org/ns/pkg";

(:~ the database..
 : <components xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 :	xsi:noNamespaceSchemaLocation="components.xsd">
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
declare variable $cmpx:comps as element(cmp)* :=fn:doc("components.xml")/components/cmp;

(:~ web path :)
declare %private variable $cmpx:webpath:=db:system()/globaloptions/webpath/string()  || file:dir-separator();

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
 : anotate a pkg:dependency with a @status attribute
 :) 
declare function cmpx:status($cmp as element(pkg:dependency)) as element(pkg:dependency)
{
let $c:=cmpx:find($cmp/@name)
let $versions:=$c/release[@version=$cmp/@version]
let $value:=if(fn:empty($c)) 
        then "missing"
        else if($versions) 
             then  "ok"
             else  "noversion"
return copy $res := $cmp
modify  (insert  node attribute status {$value} into $res,
                insert node attribute offline {fn:boolean($versions[@offline])} into $res)
return $res
};

declare function cmpx:app($app as xs:string){
let   $deps:= cmpx:expath-pkg($app)//pkg:dependency
let $c:= $deps!cmpx:find(@name)
let $c2:=$c=>cmpx:closure()
let   $s:=  cmpx:topologic-sort($c2)
return cmpx:includes($s)
};
(:~
 : generate includes required for components
 :)
declare function cmpx:includes($cmps as element(cmp)*) as element(include)
{
let $css:=$cmps!(release[1]/*[@type="css"])
let $js:=$cmps!(release[1]/*[@type="js"])
return <include>
	<css>{$css!cmpx:css(.)}</css>
	<js>{$js!cmpx:js(.)}</js>
</include>
};

declare function cmpx:css($e as element()) 
as element(link)?
{
 <link href="{$e}" rel="stylesheet" type="text/css"/>
};

declare function cmpx:js($e as element())
 as element(script)
{
 <script src="{$e}"/>
};

declare function cmpx:find($name as xs:string) as element(cmp)?
{
  $cmpx:comps[@name=$name]
};

declare function cmpx:dependants($name as xs:string) as element(cmp)*
{
  let $c:=cmpx:find($name)
  let $d:=$c/depends!cmpx:find(.)
  return ($d)
};

(:~ names of components :)
declare function cmpx:names($cmps as element(cmp)*) as xs:string*
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
        let $nodes := $unordered [ every $id in depends satisfies $id = $ordered/@name]
		(: let $_:=fn:trace(fn:count($unordered),"LEFT") :)
        return 
          if ($nodes)
          then cmpx:topologic-sort( $unordered except $nodes, ($ordered, $nodes ))
          else ()  (: cycles so no order possible :)
};

(:~
 : extend component list by recursively adding dependants  
 :)
declare function cmpx:closure($cmps as element(cmp)*) as element(cmp)*
{ 
 cmpx:closure($cmps,())
};

declare function cmpx:closure($new as element(cmp)*,$current as element(cmp)*)
as element(cmp)*
{
let $n:=$new except $current
return if (fn:empty($n)) 
       then $current
       else let $x:=$n/depends!cmpx:find(.)
	        return cmpx:closure($x,($current,$n)) 
};

(:~ save files for release to local static library :)
declare %updating function cmpx:save-offline($release as element(release))
{
let $target:=function($name){fn:string-join(
($cmpx:libpath,$release/../@name,$release/@version,$name),file:dir-separator()
)}
return (
	if(fn:not(file:is-dir($target("")))) then file:create-dir($target("")) else (),
	for $f in $release/*
	let $name:=fn:tokenize($f,"/")[fn:last()]
	let $t:=fetch:text(cmpx:full-uri($f))
	return file:write($target($name),$t)
)
};

declare function cmpx:full-uri($n){
if(fn:starts-with($n,"//"))then "http:" ||$n
else if(fn:starts-with($n,"/"))then "http://localhost:8489" || $n
else $n
};