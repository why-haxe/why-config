package why.config;

using tink.CoreApi;

interface Source {
	function get(names:Array<String>):Promise<Array<String>>;
}