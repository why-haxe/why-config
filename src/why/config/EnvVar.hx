package why.config;

using tink.CoreApi;

class EnvVar implements Source {
	public static var inst(default, null):EnvVar = new EnvVar();
	function new() {}
	public function get(names:Array<String>):Promise<Array<String>> {
		return names.map(Sys.getEnv);
	}
}