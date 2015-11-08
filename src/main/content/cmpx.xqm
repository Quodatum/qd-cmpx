(:~
 : Component library tools
 : Install this in the BaseX respository
 : @since April 2015  
 : @author Andy Bunce
 : @copyright Quodatum Ltd  
 :)
module namespace  cmpx = 'quodatum.cmpx';
declare default function namespace 'quodatum.cmpx';

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
declare variable $cmpx:comps as element(cmp)+ :=fn:doc("components.xml")/components/cmp;

(:~
 : anotate a pkg:dependency with a @status attribute
 :) 
declare function status($cmp as element(pkg:dependency)) as element(pkg:dependency)
{
let $c:=find($cmp/@name)
let $value:=if(fn:empty($c)) 
        then "missing"
        else if($c/release/@version=$cmp/@version) 
             then  "ok"
             else  "noversion"
return copy $res := $cmp
modify  insert  node attribute status {$value} into $res
return $res
};
(:~
 : generate includes required for components
 :)
declare function includes($cmps as element(cmp)*)
{
let $css:=$cmps/release[1]/cdn[@type="css"]
let $js:=$cmps/release[1]/cdn[@type="js"]
return <include><css>{$css}</css><js>{$js}</js></include>
};

declare function find($name as xs:string) as element(cmp)?
{
  $cmpx:comps[@name=$name]
};

declare function dependants($name as xs:string) as element(cmp)*
{
  let $c:=find($name)
  let $d:=$c/depends!find(.)
  return ($d)
};

(:~ names of components :)
declare function names($cmps as element(cmp)*) as xs:string*
{
  $cmps/@name
};


(:~ 
 : topologic sort 
 :)
declare function topologic-sort($unordered)   {
  topologic-sort($unordered,())
};

declare function topologic-sort($unordered, $ordered )   {
    if (fn:empty($unordered))
    then $ordered
    else
        let $nodes := $unordered [ every $id in depends satisfies $id = $ordered/@name]
		let $_:=fn:trace(fn:count($unordered),"LEFT")
        return 
          if ($nodes)
          then topologic-sort( $unordered except $nodes, ($ordered, $nodes ))
          else ()  (: cycles so no order possible :)
};

(:~
 : extend component list by recursively adding dependants  
 :)
declare function closure($cmps as element(cmp)*) as element(cmp)*
{ 
 closure($cmps,())
};

declare function closure($new as element(cmp)*,$current as element(cmp)*)
as element(cmp)*
{
let $n:=$new except $current
return if (fn:empty($n)) 
       then $current
       else let $x:=$n/depends!find(.)
	        return closure($x,($current,$n)) 
};