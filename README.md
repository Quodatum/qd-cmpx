# qd-cmpx
component database
## Example
````
import module namespace dotml="http://www.martin-loetzsch.de/DOTML";

<graph xmlns="http://www.martin-loetzsch.de/DOTML">
<node id="a"/>
<node id="b"/>
<edge from="a" to="b"/>
</graph>

!dotml:to-dot(.)
````
