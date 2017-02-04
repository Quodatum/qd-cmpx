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
declare variable $cmpx:_ver:="0.6.1";

(:~ the database..
 :)
declare  %private variable $cmpx:database:="~qd-cmpx";		

declare  %private variable $cmpx:comps as element(comp:cmp)* :=
                      if(db:exists($cmpx:database)) then
                              collection($cmpx:database)/comp:cmp
                      else 
                               ();

(:~ web path :)
declare %private variable $cmpx:webpath:=db:system()/globaloptions/webpath  || file:dir-separator();

(:~ location of static lib :)
declare variable $cmpx:libpath:=$cmpx:webpath  || "static/lib" ;

(:~ 
 : return all known components as sequence
 :)
declare function cmpx:comps() 
as element(comp:cmp)*
{
    $cmpx:comps
};

(:~
 : @return expath-pkg doc for app $name
 :)
declare function cmpx:expath-pkg($name as xs:string){
	let $f:=  file:resolve-path($name ||"/expath-pkg.xml",$cmpx:webpath)
	return fn:doc($f)
};

(:~
 : @return dependents for app $name
 :)
declare function cmpx:app-dependents($name as xs:string) 
as element(pkg:dependency)*{
    let $f:=  file:resolve-path($name ||"/expath-pkg.xml",$cmpx:webpath)
    return if(fn:doc-available($f)) then fn:doc($f)/*/pkg:dependency else ()
};
(:~
 : anotate a pkg:dependency with info about availability 
 : adds a @status attribute
 :) 
declare function cmpx:status($cmp as element(pkg:dependency)) as element(pkg:dependency)
{
let $c:=cmpx:get($cmp/@name)
let $releases:=$c/comp:release[@version=$cmp/@version]
let $value:=if(fn:empty($c)) 
        then "missing"
        else if($releases) 
             then  "ok"
             else  "noversion"
return copy $res := $cmp
modify  (insert node attribute status {$value} into $res,
         insert node attribute offline {fn:boolean($releases/comp:location[@offline])} into $res,
         insert node attribute found {$value="ok"} into $res)
return $res
};

(:~ 
 : @param $app name of app
 : @return map of dependant resources
 :)
declare function cmpx:app($app as xs:string,$opts as map(*)){
let $pkg:=cmpx:expath-pkg($app)
let $c:= $pkg//pkg:dependency!cmpx:get(@name)
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

declare function cmpx:get($name as xs:string) as element(comp:cmp)?
{
  $cmpx:comps[@name=$name]
};

declare function cmpx:dependants($name as xs:string) as element(comp:cmp)*
{
  let $c:=cmpx:get($name)
  let $d:=$c/comp:dependency/@name!cmpx:get(.)
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
        let $nodes := $unordered [ every $id in comp:dependency/@name satisfies $id = $ordered/@name]
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
       else let $x:=$n/comp:dependency/@name!cmpx:get(.)
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
 
(:~ validate catalog :)
declare function cmpx:validate-info()as xs:string*
{
  for $doc in collection($cmpx:database)
  return (validate:xsd-info( $doc,resolve-uri("components.xsd")),
          "---",
           validate:rng-info( $doc,resolve-uri("components.rnc"),fn:true())
         )
};

(:~ get a release 
 : @param $ver map keys 
:)
declare function cmpx:release($ver as map(*))as element(comp:release)*
{
    $cmpx:comps[@name=$ver?name]
    /comp:release[if ($ver?version) then $ver?version=@version else fn:true()]
};

(:~ missing dependances :)
declare function cmpx:missing() as xs:string*
{
   cmpx:value-except(cmpx:comps()/comp:dependency/@name , cmpx:names(cmpx:comps()))
};

(:~ missing dependances :)
declare %updating function cmpx:load() 
{
  cmpx:sync-from-path($cmpx:database,resolve-uri("data") )
};
(:~
: update or create database from file path
: @param $dbname name of database
: @param $path file path contain files
:)
declare %updating %private function cmpx:sync-from-path($dbname as xs:string,$path as xs:string){
   cmpx:sync-from-files($dbname,
                  $path,
                  file:list($path,fn:true()),
                  hof:id#1)
};

(:~
: update or create database from file list. After this the database will have a
: matching copy of the files on the file system
: @param $dbname name of database
: @param $path  base file path where files are relative to en
: @param $files file names from base
: @param fn function to apply f(fullsrcpath)->anotherpath
:)
declare %updating  %private function cmpx:sync-from-files($dbname as xs:string,
                                           $path as xs:string,
                                           $files as xs:string*,
                                         $ingest  )
{
let $path:=$path ||"/"
let $files:=$files!fn:translate(.,"\","/")
let $files:=fn:filter($files,function($f){file:is-file(fn:concat($path,$f))})
return if(db:exists($dbname)) then
       (for $d in db:list($dbname) 
       where fn:not($d=$files) 
       return db:delete($dbname,$d),
       for $f in $files
       let $_:=fn:trace($path || $f,"file:") 
       let $content:=$ingest($path || $f) 
       return db:replace($dbname,$f,$content),
       db:optimize($dbname))
       else
        let $full:=$files!fn:concat($path,.)
        let $content:=$full!$ingest(.) 
       return (db:create($dbname,$content,$files))
};
(: from functx :)
declare function cmpx:value-except
  ( $arg1 as xs:anyAtomicType* ,
    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values($arg1[not(.=$arg2)])
 } ;